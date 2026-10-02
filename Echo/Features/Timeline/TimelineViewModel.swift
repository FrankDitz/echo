import Foundation
import Observation

enum TimelineFailure: Equatable {
  case loadDays
}

struct TimelineSearchResult: Identifiable, Hashable, Sendable {
  let entry: EchoEntry
  let sourceDay: EchoDay

  var id: UUID { entry.id }
}

@MainActor
@Observable
final class TimelineViewModel {
  private let repository: any EchoEntryRepository
  private let calendar: Calendar
  private let now: () -> Date

  private(set) var days: [EchoDay] = []
  private(set) var searchResults: [TimelineSearchResult] = []
  private(set) var isLoading = false
  private(set) var isSearching = false
  private(set) var failure: TimelineFailure?
  private(set) var searchFailed = false

  var mostRecentTimelineDate: Date {
    calendar.date(byAdding: .day, value: -1, to: now()) ?? now()
  }

  init(
    repository: any EchoEntryRepository,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping () -> Date = Date.init
  ) {
    self.repository = repository
    self.calendar = calendar
    self.now = now
  }

  func load() async {
    let today = EchoDayIdentifier(containing: now(), calendar: calendar)

    isLoading = true
    defer { isLoading = false }

    do {
      let entries = try await repository.allEntries()
      days = EchoDay.grouping(entries)
        .filter { $0.id < today }
        .reversed()
      failure = nil
    } catch {
      failure = .loadDays
    }
  }

  func day(id: EchoDayIdentifier) -> EchoDay? {
    days.first(where: { $0.id == id })
  }

  func search(_ text: String) async {
    let query = EchoEntrySearchQuery(text)
    guard !query.isEmpty else {
      searchResults = []
      searchFailed = false
      isSearching = false
      return
    }

    isSearching = true
    defer { isSearching = false }

    do {
      async let matchingEntriesRequest = repository.searchEntries(matching: query)
      async let allEntriesRequest = repository.allEntries()
      let (matchingEntries, allEntries) = try await (
        matchingEntriesRequest,
        allEntriesRequest
      )
      let daysByID = Dictionary(
        uniqueKeysWithValues: EchoDay.grouping(allEntries).map { ($0.id, $0) }
      )
      searchResults = matchingEntries.compactMap { entry in
        guard let sourceDay = daysByID[entry.day] else { return nil }
        return TimelineSearchResult(entry: entry, sourceDay: sourceDay)
      }
      searchFailed = false
    } catch {
      searchFailed = true
    }
  }
}
