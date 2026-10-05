import Foundation
import Testing

@testable import Echo

@Suite("Model container privacy")
struct EchoModelContainerFactoryTests {
  @Test("Production storage resolves outside the source checkout")
  func productionStoreLocation() {
    let configuration = EchoModelContainerFactory.productionConfiguration()
    let checkoutPath = repositoryRoot().path + "/"

    #expect(configuration.url.isFileURL)
    #expect(!configuration.isStoredInMemoryOnly)
    #expect(!configuration.url.standardizedFileURL.path.hasPrefix(checkoutPath))
  }

  @Test("Repository tests can use storage with no filesystem backing")
  func inMemoryStorage() throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let configuration = try #require(container.configurations.first)

    #expect(configuration.isStoredInMemoryOnly)
  }
}

@Suite("Private journal export")
struct EchoDataExportServiceTests {
  @Test("Markdown export includes journal content and saved-memory context")
  func markdownExport() async throws {
    let fixture = try await makeFixture()

    let export = try await fixture.service.makeExport(
      format: .markdown,
      generatedAt: try makeDate("2026-10-05T15:00:00Z"),
      timeZone: try #require(TimeZone(identifier: "UTC"))
    )
    let markdown = try #require(String(data: export.data, encoding: .utf8))

    #expect(export.suggestedFileName == "Echo Journal 2026-10-05")
    #expect(markdown.contains("# Echo Journal"))
    #expect(markdown.contains("A fictional walk through the rain."))
    #expect(markdown.contains("A Fictional Clearer Evening"))
    #expect(markdown.contains("Saved"))
    #expect(markdown.contains("# Weekly reflections"))
    #expect(try await fixture.entryRepository.allEntries().count == 1)
  }

  @Test("PDF export produces a portable PDF without writing a file")
  func pdfExport() async throws {
    let fixture = try await makeFixture()
    let export = try await fixture.service.makeExport(
      format: .pdf,
      generatedAt: try makeDate("2026-10-05T15:00:00Z"),
      timeZone: try #require(TimeZone(identifier: "UTC"))
    )

    #expect(export.data.count > 100)
    #expect(export.data.prefix(4) == Data("%PDF".utf8))
    #expect(export.suggestedFileName == "Echo Journal 2026-10-05")
  }

  private func makeFixture() async throws -> ExportFixture {
    let container = try EchoModelContainerFactory.makeInMemory()
    let entryRepository = SwiftDataEchoEntryRepository(modelContainer: container)
    let highlightRepository = SwiftDataEchoHighlightRepository(modelContainer: container)
    let journalRepository = SwiftDataEchoOrganizedJournalRepository(modelContainer: container)
    let weeklyRepository = SwiftDataEchoWeeklyReflectionRepository(modelContainer: container)
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let createdAt = try makeDate("2026-10-01T21:00:00Z")
    let entry = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000501"),
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional walk through the rain."
    )
    let highlight = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000502"),
      target: .entry(entry.id),
      createdAt: createdAt
    )
    let journal = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000503"),
      day: entry.day,
      createdAt: createdAt,
      body: "The fictional city felt calm after the storm.",
      title: "A Fictional Clearer Evening",
      themes: ["Clarity"],
      keyMoments: ["Walking beside the fictional river"],
      reflectionQuestions: ["What fictional idea is worth keeping?"],
      sourceEntryIDs: [entry.id],
      generator: .deterministicLocal
    )
    let reflection = EchoWeeklyReflection(
      id: try makeUUID("00000000-0000-0000-0000-000000000504"),
      week: EchoWeekIdentifier(containing: createdAt, calendar: calendar),
      createdAt: createdAt,
      body: "A fictional week of deliberate progress.",
      themes: ["Momentum"],
      notableEntryIDs: [entry.id],
      sourceEntryIDs: [entry.id],
      question: "What fictional step comes next?",
      generator: .deterministicLocal
    )

    try await entryRepository.create(entry)
    try await highlightRepository.create(highlight)
    try await journalRepository.create(journal)
    try await weeklyRepository.create(reflection)

    return ExportFixture(
      service: EchoDataExportService(
        entryRepository: entryRepository,
        highlightRepository: highlightRepository,
        journalRepository: journalRepository,
        weeklyRepository: weeklyRepository
      ),
      entryRepository: entryRepository
    )
  }
}

private struct ExportFixture {
  let service: EchoDataExportService
  let entryRepository: SwiftDataEchoEntryRepository
}
