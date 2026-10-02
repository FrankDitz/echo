import Foundation
import Testing

@testable import Echo

@MainActor
@Suite("Timeline browsing workflow")
struct TimelineViewModelTests {
  @Test("The empty timeline still exposes the latest browsable date")
  func latestBrowsableDate() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let currentDate = try makeDate("2026-10-03T12:00:00Z")
    let viewModel = TimelineViewModel(
      repository: TimelineEntryRepositoryStub(entries: []),
      calendar: calendar,
      now: { currentDate }
    )
    let expectedDate = try makeDate("2026-10-02T12:00:00Z")

    #expect(viewModel.mostRecentTimelineDate == expectedDate)
  }

  @Test("Timeline groups previous days newest first")
  func groupingPreviousDays() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let firstDayEarly = try makeEntry(
      id: "00000000-0000-0000-0000-000000000601",
      date: "2026-10-01T08:00:00Z",
      text: "A fictional early note.",
      calendar: calendar
    )
    let firstDayLate = try makeEntry(
      id: "00000000-0000-0000-0000-000000000602",
      date: "2026-10-01T18:00:00Z",
      text: "A fictional later note.",
      calendar: calendar
    )
    let secondDay = try makeEntry(
      id: "00000000-0000-0000-0000-000000000603",
      date: "2026-10-02T09:00:00Z",
      text: "A fictional second-day note.",
      calendar: calendar
    )
    let today = try makeEntry(
      id: "00000000-0000-0000-0000-000000000604",
      date: "2026-10-03T09:00:00Z",
      text: "A fictional current-day note.",
      calendar: calendar
    )
    let future = try makeEntry(
      id: "00000000-0000-0000-0000-000000000605",
      date: "2026-10-04T09:00:00Z",
      text: "A fictional future note.",
      calendar: calendar
    )
    let entries = [future, firstDayLate, today, secondDay, firstDayEarly]
    let repository = TimelineEntryRepositoryStub(entries: entries)
    let currentDate = try makeDate("2026-10-03T12:00:00Z")
    let viewModel = TimelineViewModel(
      repository: repository,
      calendar: calendar,
      now: { currentDate }
    )

    await viewModel.load()

    #expect(viewModel.days.map(\.id) == [entries[3].day, entries[4].day])
    #expect(viewModel.days[1].entries == [entries[4], entries[1]])
    #expect(viewModel.failure == nil)
  }

  @Test("A timeline day can be resolved for Day Detail navigation")
  func resolvingDay() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = try makeEntry(
      id: "00000000-0000-0000-0000-000000000606",
      date: "2026-10-01T09:00:00Z",
      text: "A fictional detail note.",
      calendar: calendar
    )
    let repository = TimelineEntryRepositoryStub(entries: [entry])
    let currentDate = try makeDate("2026-10-03T12:00:00Z")
    let viewModel = TimelineViewModel(
      repository: repository,
      calendar: calendar,
      now: { currentDate }
    )

    await viewModel.load()

    let day = try #require(viewModel.day(id: entry.day))
    #expect(day.entries == [entry])
  }

  @Test("A failed refresh retains already loaded days")
  func retainingDaysAfterFailure() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = try makeEntry(
      id: "00000000-0000-0000-0000-000000000607",
      date: "2026-10-01T09:00:00Z",
      text: "A fictional retained timeline note.",
      calendar: calendar
    )
    let repository = TimelineEntryRepositoryStub(entries: [entry])
    let currentDate = try makeDate("2026-10-03T12:00:00Z")
    let viewModel = TimelineViewModel(
      repository: repository,
      calendar: calendar,
      now: { currentDate }
    )
    await viewModel.load()
    await repository.setShouldFail(true)

    await viewModel.load()

    #expect(viewModel.days.count == 1)
    #expect(viewModel.days.first?.entries == [entry])
    #expect(viewModel.failure == .loadDays)
  }

  @Test("Search returns dated entries with their complete source days")
  func searching() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let matching = try makeEntry(
      id: "00000000-0000-0000-0000-000000000608",
      date: "2026-10-01T08:00:00Z",
      text: "A fictional bridge appeared through the fog.",
      calendar: calendar
    )
    let sameDay = try makeEntry(
      id: "00000000-0000-0000-0000-000000000609",
      date: "2026-10-01T18:00:00Z",
      text: "A fictional train arrived later.",
      calendar: calendar
    )
    let currentDate = try makeDate("2026-10-03T12:00:00Z")
    let viewModel = TimelineViewModel(
      repository: TimelineEntryRepositoryStub(entries: [sameDay, matching]),
      calendar: calendar,
      now: { currentDate }
    )

    await viewModel.search("BRIDGE fog")

    #expect(viewModel.searchResults.map(\.entry) == [matching])
    #expect(viewModel.searchResults.first?.sourceDay.entries == [matching, sameDay])
    #expect(!viewModel.searchFailed)
  }

  @Test("Blank search clears results and a failed search retains privacy-safe state")
  func searchStates() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = try makeEntry(
      id: "00000000-0000-0000-0000-000000000610",
      date: "2026-10-01T08:00:00Z",
      text: "A fictional search result.",
      calendar: calendar
    )
    let repository = TimelineEntryRepositoryStub(entries: [entry])
    let viewModel = TimelineViewModel(repository: repository, calendar: calendar)
    await viewModel.search("fictional")
    await viewModel.search("   ")
    #expect(viewModel.searchResults.isEmpty)

    await repository.setShouldFail(true)
    await viewModel.search("fictional")
    #expect(viewModel.searchFailed)
  }

  private func makeEntry(
    id: String,
    date: String,
    text: String,
    calendar: Calendar
  ) throws -> EchoEntry {
    EchoEntry(
      id: try makeUUID(id),
      createdAt: try makeDate(date),
      calendar: calendar,
      rawText: text
    )
  }
}

private actor TimelineEntryRepositoryStub: EchoEntryRepository {
  private let storedEntries: [EchoEntry]
  private var shouldFail = false

  init(entries: [EchoEntry]) {
    storedEntries = entries
  }

  func setShouldFail(_ shouldFail: Bool) {
    self.shouldFail = shouldFail
  }

  func create(_ entry: EchoEntry) throws {}

  func entry(id: UUID) -> EchoEntry? {
    storedEntries.first(where: { $0.id == id })
  }

  func entries(for day: EchoDayIdentifier) -> [EchoEntry] {
    storedEntries.filter { $0.day == day }
  }

  func allEntries() throws -> [EchoEntry] {
    if shouldFail { throw StubError.requestedFailure }
    return storedEntries
  }

  func update(_ entry: EchoEntry) throws {}

  func delete(id: UUID) throws {}

  private enum StubError: Error {
    case requestedFailure
  }
}
