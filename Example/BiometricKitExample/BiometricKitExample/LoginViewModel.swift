import SwiftUI
import BiometricKit

// MARK: - What is stored behind Face ID / Touch ID

/// Any Codable type works. Here: the username and password.
struct LoginSecret: Codable {
    var username: String
    var password: String
}

// MARK: - One shared vault for the whole app

enum AppBiometric {
    /// "service" and "account" name the Keychain item. Keep them unique to your app.
    static let vault = BiometricVault<LoginSecret>(
        configuration: .init(
            service: "biometric_credentials",
            account: Bundle.main.bundleIdentifier ?? "com.test.BiometricKitExample"
        )
    )
}

// MARK: - Login logic (Observation framework)

@MainActor
@Observable
final class LoginViewModel {

    var username = ""
    var password = ""
    var isLoggedIn = false
    var isLoading = false
    var presentEnableBiometricAlert = false
    var errorMessage: String?

    /// True when the current login came from the Face ID button (not typed).
    @ObservationIgnored private var isBiometricLoginAttempt = false

    /// Identifies the account the saved login belongs to (e.g. a company subdomain).
    @ObservationIgnored private let accountScope = "example"

    private var vault: BiometricVault<LoginSecret> { AppBiometric.vault }

    // MARK: Values for the screen

    /// The Face ID button is shown only when biometric login is on,
    /// supported right now, and the saved login belongs to this account.
    var canUseBiometricLogin: Bool {
        vault.isEnabled && vault.isAvailable && vault.storedScope == accountScope
    }

    var biometricType: BiometricType { vault.biometryType }

    // MARK: Normal login

    func loginTapped() {
        isBiometricLoginAttempt = false
        login()
    }

    /// Fake server call. The password "1234" is correct, anything else is a 401.
    private func login() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Enter a username and a password."
            return
        }
        errorMessage = nil
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
            if password == "1234" {
                handleBiometricAfterLogin()
            } else {
                loginFailed(statusCode: 401)
            }
        }
    }

    private func loginFailed(statusCode: Int) {
        if statusCode == 401 && isBiometricLoginAttempt {
            // The saved password no longer works, so forget it.
            vault.reset()
        }
        isBiometricLoginAttempt = false
        errorMessage = "Wrong username or password."
    }

    // MARK: Biometric

    /// Called after a successful login.
    private func handleBiometricAfterLogin() {
        if vault.isEnabled {
            saveBiometricSecret()            // keep the saved password in sync
            isLoggedIn = true
        } else if vault.shouldOfferEnrollment {
            presentEnableBiometricAlert = true   // ask once: "Enable biometric login?"
        } else {
            isLoggedIn = true
        }
    }

    private func saveBiometricSecret() {
        try? vault.save(
            LoginSecret(username: username, password: password),
            scope: accountScope
        )
    }

    /// The user tapped "Yes".
    func enableBiometric() {
        saveBiometricSecret()
        vault.markPrompted()
        isLoggedIn = true
    }

    /// The user tapped "No".
    func declineBiometric() {
        vault.markPrompted()
        isLoggedIn = true
    }

    /// The user tapped the Face ID button.
    func loginWithBiometrics() {
        guard canUseBiometricLogin else { return }
        errorMessage = nil
        Task {
            do {
                // Shows the Face ID prompt and waits for the result.
                let secret = try await vault.load(reason: "Sign in to BiometricKitExample")
                username = secret.username
                password = secret.password
                isBiometricLoginAttempt = true
                login()
            } catch BiometricError.cancelled {
                // The user closed the prompt: stay on the form, show nothing.
            } catch {
                errorMessage = "Biometric login failed. Please use your password."
            }
        }
    }

    // MARK: Logout

    func logout() {
        isLoggedIn = false
        password = ""
        // The saved login is kept on purpose, so Face ID works on the next login.
    }
}
