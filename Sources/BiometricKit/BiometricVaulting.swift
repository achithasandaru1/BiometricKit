import Foundation

/// Abstraction over `BiometricVault`, so view models can be unit tested with `MockBiometricVault`.
public protocol BiometricVaulting: AnyObject {
    associatedtype Secret: Codable

    var isAvailable: Bool { get }
    var biometryType: BiometricType { get }
    /// True when the user opted in and a secret is stored.
    var isEnabled: Bool { get }
    /// True once the user has answered the "Enable biometric login?" question (Yes or No).
    var hasBeenPrompted: Bool { get }
    /// App-defined scope the secret belongs to (e.g. subdomain, user id).
    var storedScope: String? { get }
    /// Available, not yet enabled and not yet asked.
    var shouldOfferEnrollment: Bool { get }

    func markPrompted()
    func save(_ secret: Secret, scope: String?) throws
    func load(reason: String) async throws -> Secret
    /// User opt-out. Removes the secret but remembers the user was already asked.
    func disable()
    /// Removes everything, including the "already asked" state.
    func reset()
}

public extension BiometricVaulting {
    var shouldOfferEnrollment: Bool { isAvailable && !isEnabled && !hasBeenPrompted }
}

/// In-memory implementation for unit tests and SwiftUI previews.
public final class MockBiometricVault<Secret: Codable>: BiometricVaulting {

    public var isAvailable = true
    public var biometryType: BiometricType = .faceID
    public var isEnabled = false
    public var hasBeenPrompted = false
    public var storedScope: String?
    public var storedSecret: Secret?
    /// When set, `load` throws this error.
    public var loadError: BiometricError?

    public init() {}

    public func markPrompted() { hasBeenPrompted = true }

    public func save(_ secret: Secret, scope: String? = nil) throws {
        storedSecret = secret
        storedScope = scope
        isEnabled = true
        hasBeenPrompted = true
    }

    public func load(reason: String) async throws -> Secret {
        if let loadError { throw loadError }
        guard let storedSecret else { throw BiometricError.itemNotFound }
        return storedSecret
    }

    public func disable() {
        storedSecret = nil
        storedScope = nil
        isEnabled = false
    }

    public func reset() {
        disable()
        hasBeenPrompted = false
    }
}
