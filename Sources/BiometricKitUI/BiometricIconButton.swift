import SwiftUI
import BiometricKit

/// Round, outlined Face ID / Touch ID button, like most apps use on a login screen.
public struct BiometricIconButton: View {

    private let biometryType: BiometricType
    private let tint: Color
    private let size: CGFloat
    private let accessibilityTitle: String
    private let action: () -> Void

    /// - Parameters:
    ///   - biometryType: decides the icon (`faceid` / `touchid` / `lock.shield`).
    ///   - accessibilityTitle: VoiceOver label. Defaults to "Sign in with Face ID".
    public init(
        biometryType: BiometricType,
        tint: Color = .accentColor,
        size: CGFloat = 64,
        accessibilityTitle: String? = nil,
        strings: BiometricStrings = .default,
        action: @escaping () -> Void
    ) {
        self.biometryType = biometryType
        self.tint = tint
        self.size = size
        self.accessibilityTitle = accessibilityTitle ?? strings.loginButtonTitle(for: biometryType)
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: biometryType.systemImageName)
                .font(.system(size: size * 0.5, weight: .regular))
                .foregroundColor(tint)
                .frame(width: size, height: size)
                .background(Circle().stroke(tint, lineWidth: 1))
        }
        .accessibilityLabel(Text(accessibilityTitle))
    }
}

#if DEBUG
struct BiometricIconButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 24) {
            BiometricIconButton(biometryType: .faceID) {}
            BiometricIconButton(biometryType: .touchID) {}
        }
        .padding()
    }
}
#endif
