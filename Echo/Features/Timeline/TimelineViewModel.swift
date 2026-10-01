import Foundation
import Observation

enum TimelineFailure: Equatable {
  case loadDays
}

@MainActor
@Observable
final class TimelineViewModel {
  private let repository: any EchoEntryRepository
  private let calendar: Calendar
  private let now: () -> Date

  private(set) var days: [EchoDay] = []
  private(set) var isLoading = false
  private(set) var failure: TimelineFailure?

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
}
