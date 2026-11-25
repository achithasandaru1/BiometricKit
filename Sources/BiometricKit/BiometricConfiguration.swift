import Foundation

public struct BiometricConfiguration {

    /// Keychain service name, e.g. "biometric_credentials".
    public var service: String
    /// Keychain account name, usually the bundle identifier.
    public var account: String
    /// Optional keychain access group, to share the item between apps.
    public var accessGroup: String?
    /// Where the non-secret preferences (enabled / prompted / scope) are stored.
    public var defaults: UserDefaults
    /// Prefix of the preference keys. Change it to keep several vaults apart.
    public var keyPrefix: String
    /// `true`: Face ID / Touch ID with device passcode fallback (`.userPresence`).
    /// `false`: biometrics only, and the item is invalidated when enrolment changes (`.biometryCurrentSet`).
    public var allowsPasscodeFallback: Bool

    public init(
        service: String,
        account: String,
        accessGroup: String? = nil,
        defaults: UserDefaults = .standard,
        keyPrefix: String = "biometric_kit",
        allowsPasscodeFallback: Bool = true
    ) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
        self.defaults = defaults
        self.keyPrefix = keyPrefix
        self.allowsPasscodeFallback = allowsPasscodeFallback
    }
}
