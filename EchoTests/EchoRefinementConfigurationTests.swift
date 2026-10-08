import Foundation
import Testing

@testable import Echo

@Suite("Private refinement configuration")
struct EchoRefinementConfigurationTests {
  @Test("Provider choice persists without storing journal content")
  func persistence() throws {
    let suiteName = "EchoRefinementConfigurationTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let preferences = EchoRefinementPreferences(defaults: defaults)
    #expect(preferences.provider == .onDevice)
    preferences.provider = .disabled
    preferences.reviewBeforeUsing = true

    let restored = EchoRefinementPreferences(defaults: defaults)
    #expect(restored.provider == .disabled)
    #expect(restored.reviewBeforeUsing)
    #expect(
      defaults.dictionaryRepresentation().values.allSatisfy { value in
        (value as? String) != "A fictional private journal entry."
      })
  }

  @Test("Disabled refinement leaves a safely preserved entry untouched")
  func disabledRefinement() async throws {
    let suiteName = "EchoDisabledRefinementTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let preferences = EchoRefinementPreferences(defaults: defaults)
    preferences.provider = .disabled
    let repository = RefinementConfigurationEntryRepositoryStub()
    let timestamp = try makeDate("2026-10-07T12:00:00Z")
    let pipeline = EchoEntryCapturePipeline(
      repository: repository,
      refiner: ConfiguredEchoWritingRefiner(preferences: preferences),
      calendar: try makeGregorianCalendar(timeZone: "UTC"),
      now: { timestamp }
    )
    let entry = try await pipeline.preserve(
      "A fictional private journal entry.",
      id: UUID(),
      createdAt: timestamp,
      type: .text,
      source: .user
    )

    let result = await pipeline.refine(entry)

    #expect(result == entry)
    #expect(result.refinementStatus == .notRequested)
    #expect(await repository.entry(id: entry.id) == entry)
  }

  @Test("Known model prompt delimiters never enter the saved reading text")
  func outputSanitization() throws {
    #expect(
      EchoRefinementOutputSanitizer.clean(
        "<entry>\nA fictional corrected thought.\n</entry>"
      ) == "A fictional corrected thought."
    )
    #expect(
      EchoRefinementOutputSanitizer.clean(
        "<entry>\nA fictional corrected thought."
      ) == "A fictional corrected thought."
    )
    #expect(
      EchoRefinementOutputSanitizer.clean("A fictional <entry> reference remains.")
        == "A fictional <entry> reference remains."
    )

    let timestamp = Date(timeIntervalSince1970: 1_791_438_000)
    var persistedEntry = EchoEntry(
      createdAt: timestamp,
      calendar: Calendar(identifier: .gregorian),
      rawText: "A fictional original thought.",
    )
    persistedEntry.completeRefinement(
      text: "<entry>\nA fictional corrected thought.\n</entry>",
      provenance: EchoEntryRefinementProvenance(
        processorIdentifier: "echo.test.refiner",
        modelIdentifier: "fictional-model",
        generatedAt: timestamp
      ),
      requiresReview: false,
      at: timestamp
    )
    #expect(persistedEntry.preferredText == "A fictional corrected thought.")
  }
}

private actor RefinementConfigurationEntryRepositoryStub: EchoEntryRepository {
  private var stored: [UUID: EchoEntry] = [:]

  func create(_ entry: EchoEntry) { stored[entry.id] = entry }
  func entry(id: UUID) -> EchoEntry? { stored[id] }
  func entries(for day: EchoDayIdentifier) -> [EchoEntry] {
    EchoEntryOrdering.chronological(stored.values.filter { $0.day == day })
  }
  func allEntries() -> [EchoEntry] { EchoEntryOrdering.chronological(Array(stored.values)) }
  func update(_ entry: EchoEntry) { stored[entry.id] = entry }
  func delete(id: UUID) { stored[id] = nil }
}
