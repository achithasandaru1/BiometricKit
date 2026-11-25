import SwiftUI

public extension View {

    /// Shows the "Enable biometric login?" Yes / No alert.
    ///
    /// Present it once, after the first successful password login.
    /// `onEnable` is called for Yes, `onDecline` for No.
    func enableBiometricAlert(
        isPresented: Binding<Bool>,
        strings: BiometricStrings = .default,
        onEnable: @escaping () -> Void,
        onDecline: @escaping () -> Void = {}
    ) -> some View {
        alert(strings.enableTitle, isPresented: isPresented) {
            Button(strings.enableConfirm) { onEnable() }
            Button(strings.enableDecline, role: .cancel) { onDecline() }
        } message: {
            Text(strings.enableMessage)
        }
    }
}
