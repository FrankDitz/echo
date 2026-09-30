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
