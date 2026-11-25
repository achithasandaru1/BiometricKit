// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BiometricKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        // Core logic: LocalAuthentication + Keychain. No UI.
        .library(name: "BiometricKit", targets: ["BiometricKit"]),
        // Optional SwiftUI components (icon button, "Enable biometric login?" alert).
        .library(name: "BiometricKitUI", targets: ["BiometricKitUI"])
    ],
    targets: [
        .target(name: "BiometricKit"),
        .target(
            name: "BiometricKitUI",
            dependencies: ["BiometricKit"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "BiometricKitTests",
            dependencies: ["BiometricKit", "BiometricKitUI"]
        )
    ]
)
