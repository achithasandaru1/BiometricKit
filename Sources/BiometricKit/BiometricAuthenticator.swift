import Foundation
import LocalAuthentication

/// Stateless helpers around `LocalAuthentication`.
/// Use directly for a simple "unlock" gate (app lock, confirming a sensitive action).
/// For credential storage use `BiometricVault`.
public enum BiometricAuthenticator {

    /// The biometry type the device supports (`.none` when not enrolled / unsupported).
    public static var biometryType: BiometricType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return BiometricType(context.biometryType)
    }

    /// Whether authentication can be performed right now.
    /// - Parameter allowsPasscodeFallback: when true, a device passcode alone is enough.
    public static func canAuthenticate(allowsPasscodeFallback: Bool = true) -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(policy(allowsPasscodeFallback), error: &error)
    }

    /// Presents the system Face ID / Touch ID (or passcode) prompt.
    /// - Throws: `BiometricError`.
    public static func authenticate(reason: String, allowsPasscodeFallback: Bool = true) async throws {
        let context = LAContext()
        let policy = policy(allowsPasscodeFallback)
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            throw map(error)
        }
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            if !success { throw BiometricError.authenticationFailed }
        } catch let error as BiometricError {
            throw error
        } catch {
            throw map(error)
        }
    }

    // MARK: - Private

    private static func policy(_ allowsPasscodeFallback: Bool) -> LAPolicy {
        allowsPasscodeFallback ? .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics
    }

    private static func map(_ error: Error?) -> BiometricError {
        guard let laError = error as? LAError else { return .authenticationFailed }
        switch laError.code {
        case .userCancel, .systemCancel, .appCancel:
            return .cancelled
        case .biometryLockout:
            return .lockedOut
        case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet:
            return .notAvailable
        default:
            return .authenticationFailed
        }
    }
}
