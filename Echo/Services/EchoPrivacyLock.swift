import Foundation
import LocalAuthentication
import Observation

enum EchoAuthenticationMethod: String, Sendable {
  case faceID = "Face ID"
  case touchID = "Touch ID"
  case deviceAuthentication = "device authentication"
}

enum EchoPrivacyLockError: LocalizedError {
  case unavailable
  case authenticationFailed

  var errorDescription: String? {
    switch self {
    case .unavailable:
      "Set up Face ID, Touch ID, or a device passcode before enabling Echo Lock."
    case .authenticationFailed:
      "Echo could not verify your identity. Your journal remains locked."
    }
  }
}

@MainActor
protocol EchoDeviceAuthenticating {
  var method: EchoAuthenticationMethod { get }
  func canAuthenticate() -> Bool
  func authenticate(reason: String) async throws
  func cancelAuthentication()
}

@MainActor
final class SystemEchoDeviceAuthenticator: EchoDeviceAuthenticating {
  private var activeContext: LAContext?

  var method: EchoAuthenticationMethod {
    let context = LAContext()
    var error: NSError?
    _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    switch context.biometryType {
    case .faceID:
      return .faceID
    case .touchID:
      return .touchID
    default:
      return .deviceAuthentication
    }
  }

  func canAuthenticate() -> Bool {
    let context = LAContext()
    var error: NSError?
    return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
  }

  func authenticate(reason: String) async throws {
    let context = LAContext()
    context.localizedCancelTitle = "Keep Locked"
    context.localizedFallbackTitle = "Use Device Passcode"

    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      throw EchoPrivacyLockError.unavailable
    }
    activeContext = context
    defer {
      if activeContext === context {
        activeContext = nil
      }
    }
    guard try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) else {
      throw EchoPrivacyLockError.authenticationFailed
    }
  }

  func cancelAuthentication() {
    activeContext?.invalidate()
    activeContext = nil
  }
}

protocol EchoPrivacyLockPreferenceStore {
  func loadIsEnabled() -> Bool
  func saveIsEnabled(_ isEnabled: Bool)
}

struct UserDefaultsEchoPrivacyLockPreferenceStore: EchoPrivacyLockPreferenceStore {
  static let isEnabledKey = "privacyLock.isEnabled"

  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  func loadIsEnabled() -> Bool {
    userDefaults.bool(forKey: Self.isEnabledKey)
  }

  func saveIsEnabled(_ isEnabled: Bool) {
    userDefaults.set(isEnabled, forKey: Self.isEnabledKey)
  }
}

@Observable
@MainActor
final class EchoPrivacyLockController {
  private(set) var isEnabled: Bool
  private(set) var isLocked: Bool
  private(set) var isAuthenticating = false
  private(set) var isApplicationActive = true
  private(set) var noticeMessage: String?

  private let authenticator: any EchoDeviceAuthenticating
  private let preferenceStore: any EchoPrivacyLockPreferenceStore

  var authenticationMethodName: String {
    authenticator.method.rawValue
  }

  init(
    authenticator: any EchoDeviceAuthenticating = SystemEchoDeviceAuthenticator(),
    preferenceStore: any EchoPrivacyLockPreferenceStore =
      UserDefaultsEchoPrivacyLockPreferenceStore()
  ) {
    self.authenticator = authenticator
    self.preferenceStore = preferenceStore
    let isEnabled = preferenceStore.loadIsEnabled()
    self.isEnabled = isEnabled
    isLocked = isEnabled
  }

  func setEnabled(_ shouldEnable: Bool) async {
    noticeMessage = nil
    guard shouldEnable else {
      preferenceStore.saveIsEnabled(false)
      isEnabled = false
      isLocked = false
      return
    }
    guard !isEnabled else { return }
    guard authenticator.canAuthenticate() else {
      noticeMessage = EchoPrivacyLockError.unavailable.localizedDescription
      return
    }

    isAuthenticating = true
    defer { isAuthenticating = false }
    do {
      try await authenticator.authenticate(
        reason: "Protect your private Echo journal."
      )
      preferenceStore.saveIsEnabled(true)
      isEnabled = true
      isLocked = false
    } catch {
      noticeMessage = privacyMessage(
        for: error,
        cancellationMessage: "Echo Lock was not enabled."
      )
    }
  }

  func lock() {
    guard isEnabled else { return }
    isLocked = true
  }

  func applicationDidBecomeActive() {
    isApplicationActive = true
  }

  func applicationWillResignActive() {
    isApplicationActive = false
    lock()
  }

  func unlockIfNeeded() async {
    guard isEnabled, isLocked, !isAuthenticating else { return }
    noticeMessage = nil
    isAuthenticating = true
    defer { isAuthenticating = false }
    do {
      try await authenticator.authenticate(
        reason: "Unlock your private Echo journal."
      )
      isLocked = false
    } catch {
      isLocked = true
      noticeMessage = privacyMessage(
        for: error,
        cancellationMessage: "Echo stayed locked. Unlock whenever you are ready."
      )
    }
  }

  func clearNotice() {
    noticeMessage = nil
  }

  func cancelAuthentication() {
    guard isAuthenticating else { return }
    authenticator.cancelAuthentication()
  }

  private func privacyMessage(
    for error: any Error,
    cancellationMessage: String
  ) -> String {
    if let privacyError = error as? EchoPrivacyLockError {
      return privacyError.localizedDescription
    }
    if error is CancellationError {
      return cancellationMessage
    }
    if let localAuthenticationError = error as? LAError,
      localAuthenticationError.code == .userCancel
        || localAuthenticationError.code == .appCancel
        || localAuthenticationError.code == .systemCancel
    {
      return cancellationMessage
    }
    return "Echo could not verify your identity. Your journal remains locked."
  }
}
