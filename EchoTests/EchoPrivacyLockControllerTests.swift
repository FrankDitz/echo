import Foundation
import Testing
@testable import Echo

@MainActor
struct EchoPrivacyLockControllerTests {
  @Test("Enabling Echo Lock authenticates before persisting the preference")
  func enablingLock() async throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let authenticator = StubDeviceAuthenticator()
    let controller = EchoPrivacyLockController(
      authenticator: authenticator,
      preferenceStore: UserDefaultsEchoPrivacyLockPreferenceStore(userDefaults: defaults)
    )

    await controller.setEnabled(true)

    #expect(controller.isEnabled)
    #expect(!controller.isLocked)
    #expect(authenticator.authenticationCount == 1)
    #expect(defaults.bool(forKey: UserDefaultsEchoPrivacyLockPreferenceStore.isEnabledKey))
  }

  @Test("A stored lock begins secured and unlocks only after authentication")
  func restoringAndUnlocking() async throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(true, forKey: UserDefaultsEchoPrivacyLockPreferenceStore.isEnabledKey)
    let authenticator = StubDeviceAuthenticator()
    let controller = EchoPrivacyLockController(
      authenticator: authenticator,
      preferenceStore: UserDefaultsEchoPrivacyLockPreferenceStore(userDefaults: defaults)
    )

    #expect(controller.isLocked)
    await controller.unlockIfNeeded()
    #expect(!controller.isLocked)
    controller.lock()
    #expect(controller.isLocked)
  }

  @Test("Unavailable authentication leaves Echo Lock disabled")
  func unavailableAuthentication() async throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let authenticator = StubDeviceAuthenticator(canAuthenticate: false)
    let controller = EchoPrivacyLockController(
      authenticator: authenticator,
      preferenceStore: UserDefaultsEchoPrivacyLockPreferenceStore(userDefaults: defaults)
    )

    await controller.setEnabled(true)

    #expect(!controller.isEnabled)
    #expect(controller.noticeMessage != nil)
    #expect(!defaults.bool(forKey: UserDefaultsEchoPrivacyLockPreferenceStore.isEnabledKey))
  }

  @Test("Failed unlock never reveals journal content")
  func failedUnlock() async throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(true, forKey: UserDefaultsEchoPrivacyLockPreferenceStore.isEnabledKey)
    let authenticator = StubDeviceAuthenticator(error: EchoPrivacyLockError.authenticationFailed)
    let controller = EchoPrivacyLockController(
      authenticator: authenticator,
      preferenceStore: UserDefaultsEchoPrivacyLockPreferenceStore(userDefaults: defaults)
    )

    await controller.unlockIfNeeded()

    #expect(controller.isLocked)
    #expect(controller.noticeMessage != nil)
  }

  @Test("Disabling Echo Lock clears the persisted preference")
  func disablingLock() async throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(true, forKey: UserDefaultsEchoPrivacyLockPreferenceStore.isEnabledKey)
    let controller = EchoPrivacyLockController(
      authenticator: StubDeviceAuthenticator(),
      preferenceStore: UserDefaultsEchoPrivacyLockPreferenceStore(userDefaults: defaults)
    )

    await controller.setEnabled(false)

    #expect(!controller.isEnabled)
    #expect(!controller.isLocked)
    #expect(!defaults.bool(forKey: UserDefaultsEchoPrivacyLockPreferenceStore.isEnabledKey))
  }

  @Test("Dismissing settings cancels a pending authentication request")
  func cancelingAuthentication() async throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let authenticator = StubDeviceAuthenticator(waitsForCancellation: true)
    let controller = EchoPrivacyLockController(
      authenticator: authenticator,
      preferenceStore: UserDefaultsEchoPrivacyLockPreferenceStore(userDefaults: defaults)
    )

    let enablingTask = Task { await controller.setEnabled(true) }
    while authenticator.authenticationCount == 0 {
      await Task.yield()
    }

    controller.cancelAuthentication()
    await enablingTask.value

    #expect(authenticator.cancellationCount == 1)
    #expect(!controller.isAuthenticating)
    #expect(!controller.isEnabled)
    #expect(controller.noticeMessage == "Echo Lock was not enabled.")
    #expect(!defaults.bool(forKey: UserDefaultsEchoPrivacyLockPreferenceStore.isEnabledKey))
  }

  @Test("Leaving Echo hides content and secures an enabled lock")
  func applicationActivity() async throws {
    let suiteName = UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(true, forKey: UserDefaultsEchoPrivacyLockPreferenceStore.isEnabledKey)
    let controller = EchoPrivacyLockController(
      authenticator: StubDeviceAuthenticator(),
      preferenceStore: UserDefaultsEchoPrivacyLockPreferenceStore(userDefaults: defaults)
    )

    controller.applicationDidBecomeActive()
    await controller.unlockIfNeeded()
    #expect(!controller.isLocked)

    controller.applicationWillResignActive()
    #expect(!controller.isApplicationActive)
    #expect(controller.isLocked)

    controller.applicationDidBecomeActive()
    #expect(controller.isApplicationActive)
    #expect(controller.isLocked)
  }
}

@MainActor
private final class StubDeviceAuthenticator: EchoDeviceAuthenticating {
  let method = EchoAuthenticationMethod.faceID
  var authenticationCount = 0
  var cancellationCount = 0

  private let authenticationAvailable: Bool
  private let error: (any Error)?
  private let waitsForCancellation: Bool
  private var continuation: CheckedContinuation<Void, any Error>?

  init(
    canAuthenticate: Bool = true,
    error: (any Error)? = nil,
    waitsForCancellation: Bool = false
  ) {
    authenticationAvailable = canAuthenticate
    self.error = error
    self.waitsForCancellation = waitsForCancellation
  }

  func canAuthenticate() -> Bool {
    authenticationAvailable
  }

  func authenticate(reason: String) async throws {
    authenticationCount += 1
    if let error { throw error }
    if waitsForCancellation {
      try await withCheckedThrowingContinuation { continuation in
        self.continuation = continuation
      }
    }
  }

  func cancelAuthentication() {
    cancellationCount += 1
    continuation?.resume(throwing: CancellationError())
    continuation = nil
  }
}
