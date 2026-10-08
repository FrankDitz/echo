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
    #expect(markdown.contains("fictional walk thru rain"))
    #expect(markdown.contains("**Original capture**"))
    let preferredIndex = try #require(
      markdown.range(of: "A fictional walk through the rain.")?.lowerBound)
    let originalIndex = try #require(markdown.range(of: "fictional walk thru rain")?.lowerBound)
    #expect(preferredIndex < originalIndex)
    #expect(markdown.contains("A Fictional Clearer Evening"))
    #expect(markdown.contains("Saved"))
    #expect(markdown.contains("# Weekly reflections"))
    #expect(markdown.contains("# Carried forward"))
    #expect(markdown.contains("What fictional idea is worth carrying?"))
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

  @Test("Recovery archive restores missing records and never replaces existing records")
  func recoveryRoundTrip() async throws {
    let sourceContainer = try EchoModelContainerFactory.makeInMemory()
    let sourceEntries = SwiftDataEchoEntryRepository(modelContainer: sourceContainer)
    let sourceHighlights = SwiftDataEchoHighlightRepository(modelContainer: sourceContainer)
    let sourceJournals = SwiftDataEchoOrganizedJournalRepository(modelContainer: sourceContainer)
    let sourceWeeks = SwiftDataEchoWeeklyReflectionRepository(modelContainer: sourceContainer)
    let sourceAttachments = SwiftDataEchoVoiceAttachmentRepository(
      modelContainer: sourceContainer
    )
    let sourceCarryForwards = SwiftDataEchoCarryForwardRepository(
      modelContainer: sourceContainer
    )
    let sourceDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("EchoRecoverySource-\(UUID().uuidString)", isDirectory: true)
    let destinationDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("EchoRecoveryDestination-\(UUID().uuidString)", isDirectory: true)
    defer {
      try? FileManager.default.removeItem(at: sourceDirectory)
      try? FileManager.default.removeItem(at: destinationDirectory)
    }
    let sourceFiles = EchoVoiceFileStore(rootDirectory: sourceDirectory)
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let createdAt = try makeDate("2026-10-02T18:00:00Z")
    let entry = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000511"),
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional recovery entry."
    )
    let highlight = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000512"),
      target: .entry(entry.id),
      createdAt: createdAt
    )
    let journal = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000513"),
      day: entry.day,
      createdAt: createdAt,
      body: "A fictional recovered reflection.",
      sourceEntryIDs: [entry.id],
      generator: .deterministicLocal
    )
    let week = EchoWeeklyReflection(
      id: try makeUUID("00000000-0000-0000-0000-000000000514"),
      week: EchoWeekIdentifier(containing: createdAt, calendar: calendar),
      createdAt: createdAt,
      body: "A fictional recovered week.",
      themes: ["Recovery"],
      notableEntryIDs: [entry.id],
      sourceEntryIDs: [entry.id],
      question: nil,
      generator: .deterministicLocal
    )
    let attachmentID = try makeUUID("00000000-0000-0000-0000-000000000515")
    let audioURL = try sourceFiles.destinationURL(for: attachmentID)
    let audio = Data("fictional recovery audio".utf8)
    try audio.write(to: audioURL, options: .atomic)
    let attachment = EchoVoiceAttachment(
      id: attachmentID,
      entryID: entry.id,
      createdAt: createdAt,
      relativeFileName: audioURL.lastPathComponent,
      duration: 4.5,
      transcript: "A fictional recovery transcript."
    )
    let carryForward = EchoCarryForward(
      id: try makeUUID("00000000-0000-0000-0000-000000000516"),
      text: "A fictional thought carried into tomorrow.",
      sourceKind: .entry,
      sourceDay: entry.day,
      sourceEntryID: entry.id,
      targetDay: EchoDayIdentifier(
        containing: try makeDate("2026-10-03T12:00:00Z"),
        calendar: calendar
      ),
      createdAt: createdAt
    )
    try await sourceEntries.create(entry)
    try await sourceHighlights.create(highlight)
    try await sourceJournals.create(journal)
    try await sourceWeeks.create(week)
    try await sourceAttachments.create(attachment)
    try await sourceCarryForwards.create(carryForward)

    let sourceService = EchoDataRecoveryService(
      entryRepository: sourceEntries,
      highlightRepository: sourceHighlights,
      journalRepository: sourceJournals,
      weeklyRepository: sourceWeeks,
      voiceAttachmentRepository: sourceAttachments,
      carryForwardRepository: sourceCarryForwards,
      voiceFileStore: sourceFiles
    )
    let archive = try await sourceService.makeRecoveryArchive(generatedAt: createdAt)
    #expect(archive.suggestedFileName == "Echo Recovery 2026-10-02.echobackup")

    let destinationContainer = try EchoModelContainerFactory.makeInMemory()
    let destinationEntries = SwiftDataEchoEntryRepository(modelContainer: destinationContainer)
    let destinationHighlights = SwiftDataEchoHighlightRepository(
      modelContainer: destinationContainer
    )
    let destinationJournals = SwiftDataEchoOrganizedJournalRepository(
      modelContainer: destinationContainer
    )
    let destinationWeeks = SwiftDataEchoWeeklyReflectionRepository(
      modelContainer: destinationContainer
    )
    let destinationAttachments = SwiftDataEchoVoiceAttachmentRepository(
      modelContainer: destinationContainer
    )
    let destinationCarryForwards = SwiftDataEchoCarryForwardRepository(
      modelContainer: destinationContainer
    )
    let destinationFiles = EchoVoiceFileStore(rootDirectory: destinationDirectory)
    let destinationService = EchoDataRecoveryService(
      entryRepository: destinationEntries,
      highlightRepository: destinationHighlights,
      journalRepository: destinationJournals,
      weeklyRepository: destinationWeeks,
      voiceAttachmentRepository: destinationAttachments,
      carryForwardRepository: destinationCarryForwards,
      voiceFileStore: destinationFiles
    )

    let firstRestore = try await destinationService.restore(from: archive.data)
    #expect(firstRestore.addedEntries == 1)
    #expect(firstRestore.addedHighlights == 1)
    #expect(firstRestore.addedJournals == 1)
    #expect(firstRestore.addedWeeklyReflections == 1)
    #expect(firstRestore.addedVoiceAttachments == 1)
    #expect(firstRestore.addedCarryForwards == 1)
    #expect(firstRestore.skippedExistingItems == 0)
    #expect(try await destinationEntries.entry(id: entry.id) == entry)
    #expect(try await destinationHighlights.highlight(for: highlight.target) == highlight)
    #expect(try await destinationJournals.journal(for: journal.day) == journal)
    #expect(try await destinationWeeks.reflection(for: week.week) == week)
    #expect(
      try await destinationCarryForwards.carryForward(for: carryForward.targetDay)
        == carryForward
    )
    let restoredAttachment = try #require(
      try await destinationAttachments.attachment(for: entry.id)
    )
    #expect(restoredAttachment == attachment)
    #expect(try Data(contentsOf: destinationFiles.url(for: restoredAttachment)) == audio)

    let secondRestore = try await destinationService.restore(from: archive.data)
    #expect(secondRestore.skippedExistingItems == 6)
    #expect(secondRestore.addedEntries == 0)
    #expect(try await destinationEntries.allEntries().count == 1)

    var legacyObject = try #require(
      try JSONSerialization.jsonObject(with: archive.data) as? [String: Any]
    )
    legacyObject["carryForwards"] = nil
    let legacyArchive = try JSONSerialization.data(withJSONObject: legacyObject)
    let legacyRestore = try await destinationService.restore(from: legacyArchive)
    #expect(legacyRestore.skippedExistingItems == 5)
  }

  private func makeFixture() async throws -> ExportFixture {
    let container = try EchoModelContainerFactory.makeInMemory()
    let entryRepository = SwiftDataEchoEntryRepository(modelContainer: container)
    let highlightRepository = SwiftDataEchoHighlightRepository(modelContainer: container)
    let journalRepository = SwiftDataEchoOrganizedJournalRepository(modelContainer: container)
    let weeklyRepository = SwiftDataEchoWeeklyReflectionRepository(modelContainer: container)
    let carryForwardRepository = SwiftDataEchoCarryForwardRepository(modelContainer: container)
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let createdAt = try makeDate("2026-10-01T21:00:00Z")
    let entry = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000501"),
      createdAt: createdAt,
      calendar: calendar,
      rawText: "fictional walk thru rain",
      polishedText: "A fictional walk through the rain."
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
    let carryForward = EchoCarryForward(
      id: try makeUUID("00000000-0000-0000-0000-000000000505"),
      text: "What fictional idea is worth carrying?",
      sourceKind: .dayReflectionQuestion,
      sourceDay: entry.day,
      targetDay: EchoDayIdentifier(
        containing: try makeDate("2026-10-02T12:00:00Z"),
        calendar: calendar
      ),
      createdAt: createdAt
    )

    try await entryRepository.create(entry)
    try await highlightRepository.create(highlight)
    try await journalRepository.create(journal)
    try await weeklyRepository.create(reflection)
    try await carryForwardRepository.create(carryForward)

    return ExportFixture(
      service: EchoDataExportService(
        entryRepository: entryRepository,
        highlightRepository: highlightRepository,
        journalRepository: journalRepository,
        weeklyRepository: weeklyRepository,
        carryForwardRepository: carryForwardRepository
      ),
      entryRepository: entryRepository
    )
  }
}

private struct ExportFixture {
  let service: EchoDataExportService
  let entryRepository: SwiftDataEchoEntryRepository
}
