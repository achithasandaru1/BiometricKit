import SwiftUI

@main
struct BiometricKitExampleApp: App {

    init() {
        // Keychain items can survive an uninstall, so start clean on the first launch
        // after a (re)install. Without this, an old saved login could show up again.
        if !UserDefaults.standard.bool(forKey: "has_run_before") {
            AppBiometric.vault.reset()
            UserDefaults.standard.set(true, forKey: "has_run_before")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
