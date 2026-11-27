import SwiftUI
import BiometricKit
import BiometricKitUI

struct ContentView: View {

    // With the Observation framework the view owns the model with @State.
    @State private var viewModel = LoginViewModel()

    var body: some View {
        if viewModel.isLoggedIn {
            HomeScreen(viewModel: viewModel)
        } else {
            LoginScreen(viewModel: viewModel)
        }
    }
}

// MARK: - Login screen

struct LoginScreen: View {

    // @Bindable lets us create bindings ($viewModel.x) to an @Observable model.
    @Bindable var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("BiometricKit Example")
                .font(.title.bold())

            Text("Any username. Password: 1234")
                .font(.footnote)
                .foregroundStyle(.secondary)

            TextField("Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                viewModel.loginTapped()
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Login")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            // Face ID / Touch ID icon button from BiometricKitUI.
            if viewModel.canUseBiometricLogin {
                BiometricIconButton(biometryType: viewModel.biometricType) {
                    viewModel.loginWithBiometrics()
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        // "Enable biometric login?" alert from BiometricKitUI.
        .enableBiometricAlert(
            isPresented: $viewModel.presentEnableBiometricAlert,
            onEnable: { viewModel.enableBiometric() },
            onDecline: { viewModel.declineBiometric() }
        )
    }
}

// MARK: - Home screen

struct HomeScreen: View {

    var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Welcome, \(viewModel.username)")
                .font(.title2)
            Button("Log out") {
                viewModel.logout()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
