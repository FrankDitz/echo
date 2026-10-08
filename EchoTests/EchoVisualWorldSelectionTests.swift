import Foundation
import Testing

@testable import Echo

@MainActor
@Suite("Visual world selection")
struct EchoVisualWorldSelectionTests {
  @Test("The default world is used when no preference exists")
  func defaultSelection() {
    let store = InMemoryVisualWorldPreferenceStore()
    let selection = EchoVisualWorldSelection(preferenceStore: store)

    #expect(selection.selectedID == .cornerstoneSignal)
    #expect(selection.selectedWorld.id == .cornerstoneSignal)
    #expect(store.savedIDs.isEmpty)
  }

  @Test("A stable identifier is restored from application preferences")
  func restoringSelection() {
    let store = InMemoryVisualWorldPreferenceStore(selectedID: .crimsonStatic)
    let selection = EchoVisualWorldSelection(preferenceStore: store)

    #expect(selection.selectedID == .crimsonStatic)
    #expect(selection.selectedWorld.id == .crimsonStatic)
  }

  @Test("Selecting a world updates presentation and persists its stable identifier")
  func selectingWorld() {
    let store = InMemoryVisualWorldPreferenceStore(selectedID: .cornerstoneSignal)
    let selection = EchoVisualWorldSelection(preferenceStore: store)

    selection.select(.electricBlueHour)

    #expect(selection.selectedID == .electricBlueHour)
    #expect(selection.selectedWorld.id == .electricBlueHour)
    #expect(store.savedIDs == [.electricBlueHour])
  }

  @Test("Every shipped identifier resolves to its matching visual world")
  func resolvingShippedWorlds() {
    #expect(EchoVisualWorldID.allCases.count == 4)

    for id in EchoVisualWorldID.allCases {
      #expect(EchoVisualWorld.resolve(id).id == id)
    }
  }

  @Test("UserDefaults stores only the selected world's stable identifier")
  func userDefaultsPersistence() throws {
    let suiteName = "EchoVisualWorldSelectionTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = UserDefaultsEchoVisualWorldPreferenceStore(userDefaults: defaults)

    store.saveSelectedWorldID(.electricBlueHour)

    #expect(
      defaults.string(
        forKey: UserDefaultsEchoVisualWorldPreferenceStore.selectedWorldKey
      ) == EchoVisualWorldID.electricBlueHour.rawValue
    )
    let persistedValues = try #require(
      defaults.persistentDomain(forName: suiteName)
    )
    #expect(
      Set(persistedValues.keys)
        == [UserDefaultsEchoVisualWorldPreferenceStore.selectedWorldKey]
    )
  }

  @Test("Unknown identifiers safely fall back without modifying preferences")
  func unknownIdentifier() throws {
    let suiteName = "EchoVisualWorldSelectionTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(
      "retired-world",
      forKey: UserDefaultsEchoVisualWorldPreferenceStore.selectedWorldKey
    )

    let selection = EchoVisualWorldSelection(
      preferenceStore: UserDefaultsEchoVisualWorldPreferenceStore(
        userDefaults: defaults
      )
    )

    #expect(selection.selectedID == .cornerstoneSignal)
    #expect(
      defaults.string(
        forKey: UserDefaultsEchoVisualWorldPreferenceStore.selectedWorldKey
      ) == "retired-world"
    )
  }
}

private final class InMemoryVisualWorldPreferenceStore:
  EchoVisualWorldPreferenceStore
{
  private let selectedID: EchoVisualWorldID?
  private(set) var savedIDs: [EchoVisualWorldID] = []

  init(selectedID: EchoVisualWorldID? = nil) {
    self.selectedID = selectedID
  }

  func loadSelectedWorldID() -> EchoVisualWorldID? {
    selectedID
  }

  func saveSelectedWorldID(_ id: EchoVisualWorldID) {
    savedIDs.append(id)
  }
}
