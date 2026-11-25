# BiometricKit

Face ID / Touch ID login for iOS apps (iOS 16+), as a Swift package.

- `BiometricKit`: core logic, no UI. `BiometricVault`, `BiometricAuthenticator`.
- `BiometricKitUI`: optional SwiftUI pieces. `BiometricIconButton`, `.enableBiometricAlert(...)`. English and Arabic included.

Secrets are stored in a Keychain item protected by `SecAccessControl` (`.userPresence`: biometrics with passcode fallback), `ThisDeviceOnly`. The OS enforces authentication when the secret is read.

## Install

Xcode: File > Add Package Dependencies > enter the repository URL (or "Add Local..." for a folder), then add `BiometricKit` and, if wanted, `BiometricKitUI`.

```swift
.package(url: "https://github.com/achithasandaru1/BiometricKit.git", from: "1.0.0")
```

**Required:** add `NSFaceIDUsageDescription` to the app's Info.plist. A package cannot provide it.

## Usage

```swift
import BiometricKit

struct LoginSecret: Codable { var username: String; var password: String }

let vault = BiometricVault<LoginSecret>(
    configuration: .init(service: "biometric_credentials", account: Bundle.main.bundleIdentifier!)
)
```

1. After the first successful password login, ask once:

```swift
if vault.shouldOfferEnrollment { showEnableAlert = true }   // available, not enabled, not asked yet
```

```swift
import BiometricKitUI

content.enableBiometricAlert(isPresented: $showEnableAlert) {
    try? vault.save(LoginSecret(username: u, password: p), scope: subdomain)   // Yes
} onDecline: {
    vault.markPrompted()                                                       // No
}
```

2. On the login screen, when `vault.isEnabled && vault.storedScope == currentSubdomain`:

```swift
BiometricIconButton(biometryType: vault.biometryType, tint: .accentColor) {
    Task {
        do {
            let secret = try await vault.load(reason: "Sign in")   // shows Face ID
            login(secret.username, secret.password)
        } catch BiometricError.cancelled {
            // user cancelled: do nothing
        } catch {
            // show error
        }
    }
}
```

3. Housekeeping:
- Wrong credentials (HTTP 401) on a biometric login: `vault.reset()`.
- User opt-out (settings / menu): `vault.disable()`. The user is not asked again.
- Keep the stored password in sync after a manual login: call `vault.save(...)` again when `vault.isEnabled`.
- First launch after reinstall (Keychain survives uninstall): `vault.reset()`.

## Simple unlock gate (no stored secret)

```swift
try await BiometricAuthenticator.authenticate(reason: "Unlock")
```

## Configuration

| Option | Default | Notes |
|---|---|---|
| `service`, `account` | required | Keychain identity |
| `accessGroup` | `nil` | share between apps |
| `defaults` | `.standard` | where enabled/prompted/scope flags live |
| `keyPrefix` | `"biometric_kit"` | use different prefixes for several vaults |
| `allowsPasscodeFallback` | `true` | `false` = biometrics only, invalidated when enrolment changes |

## Custom strings (e.g. in-app language switching)

```swift
var strings = BiometricStrings.default
strings.enableTitle = "..."
content.enableBiometricAlert(isPresented: $show, strings: strings, onEnable: {...})
```

## Testing

Use `MockBiometricVault<Secret>` (conforms to `BiometricVaulting`) in view model tests and previews. Make your view model generic over `V: BiometricVaulting where V.Secret == LoginSecret`, or hold the concrete `BiometricVault`/`MockBiometricVault` type.
