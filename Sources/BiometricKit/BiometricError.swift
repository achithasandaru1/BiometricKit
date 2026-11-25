import Foundation
import Security

public enum BiometricError: Error, Equatable {
    /// Biometrics / passcode are not available (not enrolled, no passcode set, ...).
    case notAvailable
    /// The user (or the system) cancelled the prompt.
    case cancelled
    /// Too many failed attempts; the system locked biometrics.
    case lockedOut
    /// Authentication failed.
    case authenticationFailed
    /// No stored item (never saved, or invalidated by the system, e.g. passcode removed).
    case itemNotFound
    /// The secret could not be encoded or decoded.
    case invalidData
    /// Unexpected Keychain status.
    case keychain(OSStatus)

    init(status: OSStatus) {
        switch status {
        case errSecUserCanceled: self = .cancelled
        case errSecItemNotFound: self = .itemNotFound
        case errSecAuthFailed: self = .authenticationFailed
        default: self = .keychain(status)
        }
    }
}

extension BiometricError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notAvailable: return "Biometric authentication is not available."
        case .cancelled: return "Authentication was cancelled."
        case .lockedOut: return "Biometric authentication is locked. Use your passcode."
        case .authenticationFailed: return "Authentication failed."
        case .itemNotFound: return "No stored credentials were found."
        case .invalidData: return "The stored data could not be read."
        case .keychain(let status): return "Keychain error (\(status))."
        }
    }
}
