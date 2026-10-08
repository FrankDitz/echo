import Foundation
import Observation

protocol EchoVisualWorldPreferenceStore {
  func loadSelectedWorldID() -> EchoVisualWorldID?
  func saveSelectedWorldID(_ id: EchoVisualWorldID)
}

struct UserDefaultsEchoVisualWorldPreferenceStore: EchoVisualWorldPreferenceStore {
  static let selectedWorldKey = "appearance.selected-visual-world"

  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  func loadSelectedWorldID() -> EchoVisualWorldID? {
    guard let rawValue = userDefaults.string(forKey: Self.selectedWorldKey) else {
      return nil
    }

    return EchoVisualWorldID(rawValue: rawValue)
  }

  func saveSelectedWorldID(_ id: EchoVisualWorldID) {
    userDefaults.set(id.rawValue, forKey: Self.selectedWorldKey)
  }
}

@MainActor
@Observable
final class EchoVisualWorldSelection {
  private let preferenceStore: any EchoVisualWorldPreferenceStore

  private(set) var selectedID: EchoVisualWorldID

  var selectedWorld: EchoVisualWorld {
    EchoVisualWorld.resolve(selectedID)
  }

  init(
    preferenceStore: any EchoVisualWorldPreferenceStore =
      UserDefaultsEchoVisualWorldPreferenceStore(),
    defaultID: EchoVisualWorldID = .cornerstoneSignal
  ) {
    self.preferenceStore = preferenceStore
    selectedID = preferenceStore.loadSelectedWorldID() ?? defaultID
  }

  func select(_ id: EchoVisualWorldID) {
    guard selectedID != id else { return }

    selectedID = id
    preferenceStore.saveSelectedWorldID(id)
  }
}
