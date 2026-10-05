import Foundation
import Observation

enum DayOrganizationFailure: Equatable {
  case load
  case generate
}

@MainActor
@Observable
final class DayOrganizationViewModel {
  private let day: EchoDay
  private let aiService: any EchoAIService
  private let repository: any EchoOrganizedJournalRepository
  private let now: () -> Date

  private(set) var journal: EchoOrganizedJournal?
  private(set) var isLoading = false
  private(set) var isGenerating = false
  private(set) var failure: DayOrganizationFailure?

  init(
    day: EchoDay,
    aiService: any EchoAIService,
    repository: any EchoOrganizedJournalRepository,
    now: @escaping () -> Date = Date.init
  ) {
    self.day = day
    self.aiService = aiService
    self.repository = repository
    self.now = now
  }

  func load() async {
    isLoading = true
    defer { isLoading = false }

    do {
      journal = try await repository.journal(for: day.id)
      failure = nil
    } catch {
      failure = .load
    }
  }

  @discardableResult
  func generate() async -> Bool {
    guard !isGenerating else { return false }
    isGenerating = true
    defer { isGenerating = false }

    do {
      let draft = try await aiService.organize(day)
      let timestamp = now()
      let saved: EchoOrganizedJournal

      if var existing = journal {
        existing.regenerate(
          body: draft.body,
          title: draft.title,
          themes: draft.themes,
          keyMoments: draft.keyMoments,
          reflectionQuestions: draft.reflectionQuestions,
          sourceEntryIDs: draft.sourceEntryIDs,
          at: timestamp
        )
        try await repository.update(existing)
        saved = existing
      } else {
        let created = EchoOrganizedJournal(
          day: draft.day,
          createdAt: timestamp,
          body: draft.body,
          title: draft.title,
          themes: draft.themes,
          keyMoments: draft.keyMoments,
          reflectionQuestions: draft.reflectionQuestions,
          sourceEntryIDs: draft.sourceEntryIDs,
          generator: .deterministicLocal
        )
        try await repository.create(created)
        saved = created
      }

      journal = saved
      failure = nil
      return true
    } catch {
      failure = .generate
      return false
    }
  }
}

enum WeeklyReflectionFailure: Equatable {
  case load
  case generate
}

@MainActor
@Observable
final class WeeklyReflectionViewModel {
  private let entryRepository: any EchoEntryRepository
  private let reflectionRepository: any EchoWeeklyReflectionRepository
  private let aiService: any EchoAIService
  private let calendar: Calendar
  private let now: () -> Date
  private var allEntries: [EchoEntry] = []

  private(set) var selectedWeek: EchoWeekIdentifier
  private(set) var entries: [EchoEntry] = []
  private(set) var reflection: EchoWeeklyReflection?
  private(set) var isLoading = false
  private(set) var isGenerating = false
  private(set) var failure: WeeklyReflectionFailure?

  init(
    entryRepository: any EchoEntryRepository,
    reflectionRepository: any EchoWeeklyReflectionRepository,
    aiService: any EchoAIService,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping () -> Date = Date.init
  ) {
    self.entryRepository = entryRepository
    self.reflectionRepository = reflectionRepository
    self.aiService = aiService
    self.calendar = calendar
    self.now = now
    selectedWeek = EchoWeekIdentifier(containing: now(), calendar: calendar)
  }

  var sourceDays: [EchoDay] { Array(EchoDay.grouping(entries).reversed()) }

  var canMoveForward: Bool {
    selectedWeek < EchoWeekIdentifier(containing: now(), calendar: calendar)
  }

  func load() async {
    isLoading = true
    defer { isLoading = false }

    do {
      allEntries = try await entryRepository.allEntries()
      try await loadSelectedWeek()
      failure = nil
    } catch {
      failure = .load
    }
  }

  func moveWeek(by offset: Int) async {
    guard offset != 0,
      let start = selectedWeek.startDate(in: calendar.timeZone),
      let date = calendar.date(byAdding: .weekOfYear, value: offset, to: start)
    else { return }

    let candidate = EchoWeekIdentifier(containing: date, calendar: calendar)
    let current = EchoWeekIdentifier(containing: now(), calendar: calendar)
    guard candidate <= current else { return }
    selectedWeek = candidate

    isLoading = true
    defer { isLoading = false }
    do {
      try await loadSelectedWeek()
      failure = nil
    } catch {
      failure = .load
    }
  }

  @discardableResult
  func generate() async -> Bool {
    guard !isGenerating, !entries.isEmpty else { return false }
    isGenerating = true
    defer { isGenerating = false }

    do {
      let draft = try await aiService.organizeWeek(entries: entries, week: selectedWeek)
      let timestamp = now()
      let saved: EchoWeeklyReflection
      if var existing = reflection {
        existing.regenerate(
          body: draft.body,
          themes: draft.themes,
          notableEntryIDs: draft.notableEntryIDs,
          sourceEntryIDs: draft.sourceEntryIDs,
          question: draft.question,
          at: timestamp
        )
        try await reflectionRepository.update(existing)
        saved = existing
      } else {
        let created = EchoWeeklyReflection(
          week: draft.week,
          createdAt: timestamp,
          body: draft.body,
          themes: draft.themes,
          notableEntryIDs: draft.notableEntryIDs,
          sourceEntryIDs: draft.sourceEntryIDs,
          question: draft.question,
          generator: .deterministicLocal
        )
        try await reflectionRepository.create(created)
        saved = created
      }
      reflection = saved
      failure = nil
      return true
    } catch {
      failure = .generate
      return false
    }
  }

  private func loadSelectedWeek() async throws {
    entries = EchoEntryOrdering.chronological(
      allEntries.filter {
        EchoWeekIdentifier(containing: $0.createdAt, calendar: calendar) == selectedWeek
      }
    )
    reflection = try await reflectionRepository.reflection(for: selectedWeek)
  }
}
