import Foundation
import BiometricKit

/// All user-facing strings of `BiometricKitUI`. The defaults are localized (English, Arabic).
/// Apps with their own language switching can pass their own values.
public struct BiometricStrings {

    public var enableTitle: String
    public var enableMessage: String
    public var enableConfirm: String
    public var enableDecline: String
    /// Contains one `%@` placeholder for the biometry name, e.g. "Sign in with %@".
    public var loginButtonFormat: String

    public init(
        enableTitle: String,
        enableMessage: String,
        enableConfirm: String,
        enableDecline: String,
        loginButtonFormat: String
    ) {
        self.enableTitle = enableTitle
        self.enableMessage = enableMessage
        self.enableConfirm = enableConfirm
        self.enableDecline = enableDecline
        self.loginButtonFormat = loginButtonFormat
    }

    public static var `default`: BiometricStrings {
        BiometricStrings(
            enableTitle: localized("biometric_enable_title"),
            enableMessage: localized("biometric_enable_message"),
            enableConfirm: localized("biometric_enable_confirm"),
            enableDecline: localized("biometric_enable_decline"),
            loginButtonFormat: localized("biometric_login_button")
        )
    }

    public func loginButtonTitle(for type: BiometricType) -> String {
        String(format: loginButtonFormat, type.displayName)
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .module, value: key, comment: "")
    }
}
