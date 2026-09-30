import Foundation
import Observation

struct HighlightedEntry: Identifiable, Hashable, Sendable {
  let highlight: EchoHighlight
  let entry: EchoEntry
  let sourceDay: EchoDay

  var id: UUID { highlight.id }
}

enum HighlightsFailure: Equatable {
  case load
  case remove
}

@MainActor
@Observable
final class HighlightsViewModel {
  private let entryRepository: any EchoEntryRepository
  private let highlightRepository: any EchoHighlightRepository
  private let entryHighlightViewModel: EntryHighlightViewModel

  private(set) var items: [HighlightedEntry] = []
  private(set) var isLoading = false
  private(set) var failure: HighlightsFailure?

  init(
    entryRepository: any EchoEntryRepository,
    highlightRepository: any EchoHighlightRepository,
    entryHighlightViewModel: EntryHighlightViewModel
  ) {
    self.entryRepository = entryRepository
    self.highlightRepository = highlightRepository
    self.entryHighlightViewModel = entryHighlightViewModel
  }

  func load() async {
    isLoading = true
    defer { isLoading = false }

    await entryHighlightViewModel.load()
    guard entryHighlightViewModel.failure == nil else {
      failure = .load
      return
    }

    do {
      async let entriesRequest = entryRepository.allEntries()
      async let highlightsRequest = highlightRepository.allHighlights()
      let (entries, highlights) = try await (entriesRequest, highlightsRequest)
      let entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
      let daysByID = Dictionary(
        uniqueKeysWithValues: EchoDay.grouping(entries).map { ($0.id, $0) }
      )

      items = highlights.compactMap { highlight in
        guard highlight.target.kind == .entry,
          let entry = entriesByID[highlight.target.entityID],
          let sourceDay = daysByID[entry.day]
        else {
          return nil
        }
        return HighlightedEntry(
          highlight: highlight,
          entry: entry,
          sourceDay: sourceDay
        )
      }
      .sorted(by: newestFirst)
      failure = nil
    } catch {
      failure = .load
    }
  }

  @discardableResult
  func remove(entryID: UUID) async -> Bool {
    guard items.contains(where: { $0.entry.id == entryID }) else { return false }

    if await entryHighlightViewModel.toggle(entryID: entryID) {
      items.removeAll(where: { $0.entry.id == entryID })
      failure = nil
      return true
    }

    failure = .remove
    return false
  }

  private func newestFirst(_ lhs: HighlightedEntry, _ rhs: HighlightedEntry) -> Bool {
    if lhs.highlight.createdAt != rhs.highlight.createdAt {
      return lhs.highlight.createdAt > rhs.highlight.createdAt
    }
    return lhs.highlight.id.uuidString < rhs.highlight.id.uuidString
  }
}
