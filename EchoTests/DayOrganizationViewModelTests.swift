import Foundation
import Testing

@testable import Echo

@MainActor
@Suite("Day organization workflow")
struct DayOrganizationViewModelTests {
  @Test("Generating persists a separate journal without changing raw entries")
  func generatingJournal() async throws {
    let fixture = try makeFixture()
    let repository = OrganizedJournalRepositoryStub()
    let timestamp = try makeDate("2026-10-07T20:00:00Z")
    let viewModel = DayOrganizationViewModel(
      day: fixture.day,
      aiService: DeterministicLocalAIService(),
      repository: repository,
      now: { timestamp }
    )

    #expect(await viewModel.generate())

    let journal = try #require(viewModel.journal)
    #expect(journal.day == fixture.day.id)
    #expect(journal.body == "A fictional morning.\n\nA fictional evening.")
    #expect(journal.title == "Fictional in Focus")
    #expect(journal.themes == ["Fictional", "Morning", "Evening"])
    #expect(journal.keyMoments == ["A fictional morning", "A fictional evening"])
    #expect(journal.reflectionQuestions == [
      "What about fictional would you like to carry forward?"
    ])
    #expect(journal.sourceEntryIDs == fixture.day.entries.map(\.id))
    #expect(journal.generator == .deterministicLocal)
    #expect(fixture.day.entries == fixture.originalEntries)
    #expect(try await repository.journal(for: fixture.day.id) == journal)
  }

  @Test("Regeneration updates the existing journal identity")
  func regeneratingJournal() async throws {
    let fixture = try makeFixture()
    let createdAt = try makeDate("2026-10-07T20:00:00Z")
    let regeneratedAt = try makeDate("2026-10-07T21:00:00Z")
    let existing = EchoOrganizedJournal(
      day: fixture.day.id,
      createdAt: createdAt,
      body: "An older fictional organization.",
      sourceEntryIDs: [fixture.day.entries[0].id],
      generator: .deterministicLocal
    )
    let repository = OrganizedJournalRepositoryStub(journal: existing)
    let viewModel = DayOrganizationViewModel(
      day: fixture.day,
      aiService: DeterministicLocalAIService(),
      repository: repository,
      now: { regeneratedAt }
    )
    await viewModel.load()

    #expect(await viewModel.generate())

    let regenerated = try #require(viewModel.journal)
    #expect(regenerated.id == existing.id)
    #expect(regenerated.createdAt == createdAt)
    #expect(regenerated.modifiedAt == regeneratedAt)
    #expect(regenerated.title == "Fictional in Focus")
    #expect(!regenerated.themes.isEmpty)
    #expect(regenerated.sourceEntryIDs == fixture.day.entries.map(\.id))
  }

  @Test("Persistence failure retains the previously visible journal")
  func persistenceFailure() async throws {
    let fixture = try makeFixture()
    let existing = EchoOrganizedJournal(
      day: fixture.day.id,
      createdAt: try makeDate("2026-10-07T20:00:00Z"),
      body: "A visible fictional organization.",
      sourceEntryIDs: fixture.day.entries.map(\.id),
      generator: .deterministicLocal
    )
    let repository = OrganizedJournalRepositoryStub(journal: existing)
    let viewModel = DayOrganizationViewModel(
      day: fixture.day,
      aiService: DeterministicLocalAIService(),
      repository: repository
    )
    await viewModel.load()
    await repository.setShouldFail(true)

    #expect(!(await viewModel.generate()))
    #expect(viewModel.journal == existing)
    #expect(viewModel.failure == .generate)
  }

  private func makeFixture() throws -> (day: EchoDay, originalEntries: [EchoEntry]) {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let morning = EchoEntry(
      createdAt: try makeDate("2026-10-07T08:00:00Z"),
      calendar: calendar,
      rawText: "A fictional morning."
    )
    let evening = EchoEntry(
      createdAt: try makeDate("2026-10-07T18:00:00Z"),
      calendar: calendar,
      rawText: "A fictional evening."
    )
    return (
      try #require(EchoDay.grouping([evening, morning]).first),
      [morning, evening]
    )
  }
}

private actor OrganizedJournalRepositoryStub: EchoOrganizedJournalRepository {
  private var storedJournal: EchoOrganizedJournal?
  private var shouldFail = false

  init(journal: EchoOrganizedJournal? = nil) {
    storedJournal = journal
  }

  func setShouldFail(_ value: Bool) {
    shouldFail = value
  }

  func create(_ journal: EchoOrganizedJournal) throws {
    if shouldFail { throw StubError.requestedFailure }
    storedJournal = journal
  }

  func journal(for day: EchoDayIdentifier) throws -> EchoOrganizedJournal? {
    if shouldFail { throw StubError.requestedFailure }
    return storedJournal?.day == day ? storedJournal : nil
  }

  func allJournals() -> [EchoOrganizedJournal] {
    storedJournal.map { [$0] } ?? []
  }

  func update(_ journal: EchoOrganizedJournal) throws {
    if shouldFail { throw StubError.requestedFailure }
    storedJournal = journal
  }

  func delete(id: UUID) throws {
    if shouldFail { throw StubError.requestedFailure }
    if storedJournal?.id == id { storedJournal = nil }
  }

  private enum StubError: Error {
    case requestedFailure
  }
}
