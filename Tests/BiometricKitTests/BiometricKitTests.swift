import XCTest
import Security
@testable import BiometricKit
import BiometricKitUI

final class BiometricKitTests: XCTestCase {

    private struct Credentials: Codable, Equatable {
        var username: String
        var password: String
    }

    func testBiometricTypeIconsAndNames() {
        XCTAssertEqual(BiometricType.faceID.systemImageName, "faceid")
        XCTAssertEqual(BiometricType.touchID.systemImageName, "touchid")
        XCTAssertEqual(BiometricType.none.systemImageName, "lock.shield")
        XCTAssertEqual(BiometricType.faceID.displayName, "Face ID")
    }

    func testErrorMappingFromKeychainStatus() {
        XCTAssertEqual(BiometricError(status: errSecUserCanceled), .cancelled)
        XCTAssertEqual(BiometricError(status: errSecItemNotFound), .itemNotFound)
        XCTAssertEqual(BiometricError(status: errSecAuthFailed), .authenticationFailed)
        XCTAssertEqual(BiometricError(status: errSecParam), .keychain(errSecParam))
    }

    func testMockVaultFlow() async throws {
        let vault = MockBiometricVault<Credentials>()
        XCTAssertTrue(vault.shouldOfferEnrollment)

        try vault.save(Credentials(username: "a", password: "b"), scope: "tenant")
        XCTAssertTrue(vault.isEnabled)
        XCTAssertFalse(vault.shouldOfferEnrollment)
        XCTAssertEqual(vault.storedScope, "tenant")
        let loaded = try await vault.load(reason: "test")
        XCTAssertEqual(loaded, Credentials(username: "a", password: "b"))

        vault.disable()
        XCTAssertFalse(vault.isEnabled)
        XCTAssertTrue(vault.hasBeenPrompted)   // user opt-out is remembered

        vault.reset()
        XCTAssertFalse(vault.hasBeenPrompted)
    }

    func testMockVaultLoadError() async {
        let vault = MockBiometricVault<Credentials>()
        vault.loadError = .cancelled
        do {
            _ = try await vault.load(reason: "test")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? BiometricError, .cancelled)
        }
    }

    func testVaultPreferencesAreScopedByKeyPrefix() {
        let defaults = UserDefaults(suiteName: "BiometricKitTests")!
        defaults.removePersistentDomain(forName: "BiometricKitTests")
        let vault = BiometricVault<Credentials>(
            configuration: .init(service: "svc", account: "acc", defaults: defaults, keyPrefix: "t")
        )
        XCTAssertFalse(vault.isEnabled)
        XCTAssertFalse(vault.hasBeenPrompted)
        vault.markPrompted()
        XCTAssertTrue(vault.hasBeenPrompted)
        vault.reset()
        XCTAssertFalse(vault.hasBeenPrompted)
    }

    func testDefaultStringsAreLocalized() {
        let strings = BiometricStrings.default
        XCTAssertFalse(strings.enableTitle.hasPrefix("biometric_"))
        XCTAssertEqual(strings.loginButtonTitle(for: .faceID), "Sign in with Face ID")
    }
}
