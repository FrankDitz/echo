import Foundation
import Testing

@testable import Echo

@MainActor
@Suite("Today entry workflow")
struct TodayViewModelTests {
  @Test("Loading requests the current calendar day")
  func loadingCurrentDay() async throws {
    let date = try makeDate("2026-10-03T12:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: try makeDate("2026-10-03T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional morning note."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { date }
    )

    await viewModel.load()

    #expect(viewModel.entries == [entry])
    #expect(viewModel.displayedDate == date)
    #expect(viewModel.failure == nil)
    #expect(
      await repository.lastRequestedDay()
        == EchoDayIdentifier(containing: date, calendar: calendar)
    )
  }

  @Test("Creating preserves the writing and reports a saved state")
  func creatingEntry() async throws {
    let date = try makeDate("2026-10-03T15:30:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let repository = TodayEntryRepositoryStub()
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { date }
    )
    let rawText = "  A fictional note with intentional spacing.  "

    let created = await viewModel.createEntry(rawText: rawText)

    let stored = try #require(await repository.allEntries().first)
    #expect(created)
    #expect(stored.rawText == rawText)
    #expect(stored.createdAt == date)
    #expect(stored.modifiedAt == date)
    #expect(viewModel.entries == [stored])
    #expect(viewModel.saveState == .saved)
  }

  @Test("Blank writing is not persisted")
  func rejectingBlankEntry() async {
    let repository = TodayEntryRepositoryStub()
    let viewModel = TodayViewModel(repository: repository)

    let created = await viewModel.createEntry(rawText: " \n\t ")

    #expect(!created)
    #expect(await repository.allEntries().isEmpty)
    #expect(viewModel.saveState == .idle)
  }

  @Test("Editing preserves creation time and advances modification time")
  func editingEntry() async throws {
    let createdAt = try makeDate("2026-10-03T09:00:00Z")
    let modifiedAt = try makeDate("2026-10-03T11:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional first draft."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { modifiedAt }
    )
    await viewModel.load()

    let updated = await viewModel.updateEntry(
      id: entry.id,
      rawText: "A fictional revised draft."
    )

    let stored = try #require(await repository.entry(id: entry.id))
    #expect(updated)
    #expect(stored.createdAt == createdAt)
    #expect(stored.modifiedAt == modifiedAt)
    #expect(stored.rawText == "A fictional revised draft.")
    #expect(viewModel.saveState == .saved)
  }

  @Test("Deleting removes an entry only after persistence succeeds")
  func deletingEntry() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let createdAt = try makeDate("2026-10-03T09:00:00Z")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional disposable note."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { createdAt }
    )
    await viewModel.load()

    let deleted = await viewModel.deleteEntry(id: entry.id)

    #expect(deleted)
    #expect(viewModel.entries.isEmpty)
    #expect(await repository.allEntries().isEmpty)
  }

  @Test("Persistence failures retain the current entry list")
  func persistenceFailure() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let createdAt = try makeDate("2026-10-03T09:00:00Z")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional retained note."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { createdAt }
    )
    await viewModel.load()
    await repository.setFailure(.delete)

    let deleted = await viewModel.deleteEntry(id: entry.id)

    #expect(!deleted)
    #expect(viewModel.entries == [entry])
    #expect(viewModel.failure == .deleteEntry)
  }
}

private actor TodayEntryRepositoryStub: EchoEntryRepository {
  enum Operation {
    case create
    case update
    case delete
  }

  private var entriesByID: [UUID: EchoEntry]
  private var failure: Operation?
  private var requestedDay: EchoDayIdentifier?

  init(entries: [EchoEntry] = []) {
    entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
  }

  func setFailure(_ operation: Operation?) {
    failure = operation
  }

  func lastRequestedDay() -> EchoDayIdentifier? {
    requestedDay
  }

  func create(_ entry: EchoEntry) throws {
    if failure == .create { throw StubError.requestedFailure }
    entriesByID[entry.id] = entry
  }

  func entry(id: UUID) -> EchoEntry? {
    entriesByID[id]
  }

  func entries(for day: EchoDayIdentifier) -> [EchoEntry] {
    requestedDay = day
    return EchoEntryOrdering.chronological(
      entriesByID.values.filter { $0.day == day }
    )
  }

  func allEntries() -> [EchoEntry] {
    EchoEntryOrdering.chronological(Array(entriesByID.values))
  }

  func update(_ entry: EchoEntry) throws {
    if failure == .update { throw StubError.requestedFailure }
    entriesByID[entry.id] = entry
  }

  func delete(id: UUID) throws {
    if failure == .delete { throw StubError.requestedFailure }
    entriesByID[id] = nil
  }

  private enum StubError: Error {
    case requestedFailure
  }
}
