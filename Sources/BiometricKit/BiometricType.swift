import Foundation
import LocalAuthentication

/// The kind of biometry available on the device.
public enum BiometricType: Equatable {
    case none
    case touchID
    case faceID

    /// Brand name for display, e.g. "Face ID".
    public var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Passcode"
        }
    }

    /// SF Symbol matching the biometry type.
    public var systemImageName: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.shield"
        }
    }

    init(_ type: LABiometryType) {
        switch type {
        case .faceID: self = .faceID
        case .touchID: self = .touchID
        default: self = .none
        }
    }
}
