import Foundation
import Testing

@testable import Echo

@MainActor
@Suite("Highlights collection")
struct HighlightsViewModelTests {
  @Test("Loading joins highlights to entries newest highlight first")
  func loadingCollection() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let firstEntry = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000701"),
      createdAt: try makeDate("2026-10-01T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional first highlight."
    )
    let secondEntry = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000702"),
      createdAt: try makeDate("2026-10-02T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional second highlight."
    )
    let firstHighlight = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000703"),
      target: .entry(firstEntry.id),
      createdAt: try makeDate("2026-10-03T09:00:00Z")
    )
    let secondHighlight = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000704"),
      target: .entry(secondEntry.id),
      createdAt: try makeDate("2026-10-04T09:00:00Z")
    )
    let entryRepository = HighlightsEntryRepositoryStub(entries: [firstEntry, secondEntry])
    let highlightRepository = HighlightsRepositoryStub(
      highlights: [firstHighlight, secondHighlight]
    )
    let interactionViewModel = EntryHighlightViewModel(repository: highlightRepository)
    let viewModel = HighlightsViewModel(
      entryRepository: entryRepository,
      highlightRepository: highlightRepository,
      entryHighlightViewModel: interactionViewModel
    )

    await viewModel.load()

    #expect(viewModel.items.map(\.entry) == [secondEntry, firstEntry])
    #expect(viewModel.items[0].sourceDay.entries == [secondEntry])
    #expect(viewModel.failure == nil)
  }

  @Test("A highlight retains every entry from its source day")
  func sourceDayContext() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let first = EchoEntry(
      createdAt: try makeDate("2026-10-02T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional morning entry."
    )
    let highlighted = EchoEntry(
      createdAt: try makeDate("2026-10-02T17:00:00Z"),
      calendar: calendar,
      rawText: "A fictional evening entry."
    )
    let highlight = EchoHighlight(
      target: .entry(highlighted.id),
      createdAt: try makeDate("2026-10-04T09:00:00Z")
    )
    let entryRepository = HighlightsEntryRepositoryStub(entries: [highlighted, first])
    let highlightRepository = HighlightsRepositoryStub(highlights: [highlight])
    let interactionViewModel = EntryHighlightViewModel(repository: highlightRepository)
    let viewModel = HighlightsViewModel(
      entryRepository: entryRepository,
      highlightRepository: highlightRepository,
      entryHighlightViewModel: interactionViewModel
    )

    await viewModel.load()

    let item = try #require(viewModel.items.first)
    #expect(item.entry == highlighted)
    #expect(item.sourceDay.entries == [first, highlighted])
  }

  @Test("Removing a highlight updates persistence and the collection")
  func removingHighlight() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: try makeDate("2026-10-02T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional removable highlight."
    )
    let highlight = EchoHighlight(
      target: .entry(entry.id),
      createdAt: try makeDate("2026-10-04T09:00:00Z")
    )
    let entryRepository = HighlightsEntryRepositoryStub(entries: [entry])
    let highlightRepository = HighlightsRepositoryStub(highlights: [highlight])
    let interactionViewModel = EntryHighlightViewModel(repository: highlightRepository)
    let viewModel = HighlightsViewModel(
      entryRepository: entryRepository,
      highlightRepository: highlightRepository,
      entryHighlightViewModel: interactionViewModel
    )
    await interactionViewModel.load()
    await viewModel.load()

    #expect(await viewModel.remove(entryID: entry.id))
    #expect(viewModel.items.isEmpty)
    #expect(await highlightRepository.allHighlights().isEmpty)
  }

  @Test("Highlights whose source entry no longer exists are omitted")
  func omittingOrphans() async throws {
    let highlightRepository = HighlightsRepositoryStub(
      highlights: [
        EchoHighlight(
          target: .entry(try makeUUID("00000000-0000-0000-0000-000000000705")),
          createdAt: try makeDate("2026-10-04T09:00:00Z")
        )
      ]
    )
    let interactionViewModel = EntryHighlightViewModel(repository: highlightRepository)
    let viewModel = HighlightsViewModel(
      entryRepository: HighlightsEntryRepositoryStub(),
      highlightRepository: highlightRepository,
      entryHighlightViewModel: interactionViewModel
    )

    await viewModel.load()

    #expect(viewModel.items.isEmpty)
    #expect(viewModel.failure == nil)
  }
}

private actor HighlightsEntryRepositoryStub: EchoEntryRepository {
  private var entries: [EchoEntry]

  init(entries: [EchoEntry] = []) {
    self.entries = entries
  }

  func create(_ entry: EchoEntry) { entries.append(entry) }
  func entry(id: UUID) -> EchoEntry? { entries.first(where: { $0.id == id }) }
  func entries(for day: EchoDayIdentifier) -> [EchoEntry] {
    entries.filter { $0.day == day }
  }
  func allEntries() -> [EchoEntry] { entries }
  func update(_ entry: EchoEntry) {}
  func delete(id: UUID) { entries.removeAll(where: { $0.id == id }) }
}

private actor HighlightsRepositoryStub: EchoHighlightRepository {
  private var highlights: [EchoHighlight]

  init(highlights: [EchoHighlight] = []) {
    self.highlights = highlights
  }

  func create(_ highlight: EchoHighlight) { highlights.append(highlight) }
  func highlight(for target: EchoHighlightTarget) -> EchoHighlight? {
    highlights.first(where: { $0.target == target })
  }
  func allHighlights() -> [EchoHighlight] { highlights }
  func delete(id: UUID) { highlights.removeAll(where: { $0.id == id }) }
}
