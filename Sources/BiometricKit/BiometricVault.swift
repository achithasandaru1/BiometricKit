import Foundation
import LocalAuthentication
import Security

/// Stores a `Codable` secret (e.g. username + password) in a Keychain item protected by
/// `SecAccessControl`. The OS enforces Face ID / Touch ID (and optionally the passcode)
/// when the secret is read; `load(reason:)` is what shows the system prompt.
///
/// The item is `ThisDeviceOnly`: it is not synced or backed up.
public final class BiometricVault<Secret: Codable>: BiometricVaulting {

    public let configuration: BiometricConfiguration

    public init(configuration: BiometricConfiguration) {
        self.configuration = configuration
    }

    // MARK: - State

    public var isAvailable: Bool {
        BiometricAuthenticator.canAuthenticate(allowsPasscodeFallback: configuration.allowsPasscodeFallback)
    }

    public var biometryType: BiometricType {
        BiometricAuthenticator.biometryType
    }

    public var isEnabled: Bool {
        configuration.defaults.bool(forKey: key("enabled"))
    }

    public var hasBeenPrompted: Bool {
        configuration.defaults.bool(forKey: key("prompted"))
    }

    public var storedScope: String? {
        configuration.defaults.string(forKey: key("scope"))
    }

    public func markPrompted() {
        configuration.defaults.set(true, forKey: key("prompted"))
    }

    // MARK: - Storage

    /// Saves (replaces) the secret and marks biometric login as enabled.
    /// Delete + add is used so that updating never triggers an authentication prompt.
    public func save(_ secret: Secret, scope: String? = nil) throws {
        guard let data = try? JSONEncoder().encode(secret) else {
            throw BiometricError.invalidData
        }
        let flags: SecAccessControlCreateFlags = configuration.allowsPasscodeFallback ? .userPresence : .biometryCurrentSet
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            flags,
            nil
        ) else {
            throw BiometricError.notAvailable
        }

        deleteItem()

        var query = baseQuery()
        query[kSecAttrAccessControl as String] = accessControl
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BiometricError(status: status)
        }

        let defaults = configuration.defaults
        defaults.set(true, forKey: key("enabled"))
        defaults.set(true, forKey: key("prompted"))
        if let scope {
            defaults.set(scope, forKey: key("scope"))
        } else {
            defaults.removeObject(forKey: key("scope"))
        }
    }

    /// Reads the secret. Presents the standard system Face ID / Touch ID (or passcode) prompt.
    ///
    /// The prompt is shown through `LAContext` first, so users get the usual Face ID animation
    /// and checkmark. The authenticated context is then reused for the Keychain read, so the
    /// user is not asked twice.
    /// - Throws: `BiometricError`. `.itemNotFound` also clears the stored state.
    public func load(reason: String) async throws -> Secret {
        let context = LAContext()
        context.localizedReason = reason

        try await BiometricAuthenticator.authenticate(
            using: context,
            reason: reason,
            allowsPasscodeFallback: configuration.allowsPasscodeFallback
        )

        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationContext as String] = context
        let finalQuery = query

        let data: Data
        do {
            data = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    var result: AnyObject?
                    let status = SecItemCopyMatching(finalQuery as CFDictionary, &result)
                    if status == errSecSuccess, let data = result as? Data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: BiometricError(status: status))
                    }
                }
            }
        } catch BiometricError.itemNotFound {
            // The item was invalidated (e.g. passcode removed): stop offering biometric login.
            disable()
            throw BiometricError.itemNotFound
        }

        do {
            return try JSONDecoder().decode(Secret.self, from: data)
        } catch {
            throw BiometricError.invalidData
        }
    }

    public func disable() {
        deleteItem()
        let defaults = configuration.defaults
        defaults.set(false, forKey: key("enabled"))
        defaults.removeObject(forKey: key("scope"))
    }

    public func reset() {
        disable()
        configuration.defaults.set(false, forKey: key("prompted"))
    }

    // MARK: - Private

    private func key(_ name: String) -> String {
        "\(configuration.keyPrefix).\(name)"
    }

    private func baseQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: configuration.service,
            kSecAttrAccount as String: configuration.account
        ]
        if let group = configuration.accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    private func deleteItem() {
        SecItemDelete(baseQuery() as CFDictionary)
    }
}
