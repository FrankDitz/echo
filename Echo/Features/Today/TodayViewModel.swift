import Foundation
import Observation

enum TodayEntrySaveState: Equatable {
  case idle
  case saving
  case saved
  case failed
}

enum TodayJournalFailure: Equatable {
  case loadEntries
  case createEntry
  case updateEntry
  case deleteEntry
}

@MainActor
@Observable
final class TodayViewModel {
  private let repository: any EchoEntryRepository
  private let calendar: Calendar
  private let now: () -> Date

  private(set) var displayedDate: Date
  private(set) var entries: [EchoEntry] = []
  private(set) var isLoading = false
  private(set) var saveState: TodayEntrySaveState = .idle
  private(set) var failure: TodayJournalFailure?

  init(
    repository: any EchoEntryRepository,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping () -> Date = Date.init
  ) {
    self.repository = repository
    self.calendar = calendar
    self.now = now
    self.displayedDate = now()
  }

  func load() async {
    let currentDate = now()
    let day = EchoDayIdentifier(containing: currentDate, calendar: calendar)

    displayedDate = currentDate
    isLoading = true
    defer { isLoading = false }

    do {
      entries = try await repository.entries(for: day)
      failure = nil
    } catch {
      failure = .loadEntries
    }
  }

  @discardableResult
  func createEntry(rawText: String) async -> Bool {
    guard containsWriting(rawText) else { return false }

    let timestamp = now()
    let entry = EchoEntry(
      createdAt: timestamp,
      calendar: calendar,
      rawText: rawText
    )

    saveState = .saving
    do {
      try await repository.create(entry)
      entries = EchoEntryOrdering.chronological(entries + [entry])
      displayedDate = timestamp
      saveState = .saved
      failure = nil
      return true
    } catch {
      saveState = .failed
      failure = .createEntry
      return false
    }
  }

  @discardableResult
  func updateEntry(id: UUID, rawText: String) async -> Bool {
    guard containsWriting(rawText),
      let index = entries.firstIndex(where: { $0.id == id })
    else {
      return false
    }

    var entry = entries[index]
    entry.editRawText(rawText, at: now())

    saveState = .saving
    do {
      try await repository.update(entry)
      entries[index] = entry
      entries = EchoEntryOrdering.chronological(entries)
      saveState = .saved
      failure = nil
      return true
    } catch {
      saveState = .failed
      failure = .updateEntry
      return false
    }
  }

  @discardableResult
  func deleteEntry(id: UUID) async -> Bool {
    guard entries.contains(where: { $0.id == id }) else { return false }

    do {
      try await repository.delete(id: id)
      entries.removeAll(where: { $0.id == id })
      failure = nil
      return true
    } catch {
      failure = .deleteEntry
      return false
    }
  }

  func resetSaveState() {
    saveState = .idle
  }

  @discardableResult
  func saveAssistedText(entryID: UUID, text: String) async -> Bool {
    guard containsWriting(text),
      let index = entries.firstIndex(where: { $0.id == entryID })
    else {
      return false
    }

    var entry = entries[index]
    entry.setPolishedText(text, at: now())

    do {
      try await repository.update(entry)
      entries[index] = entry
      failure = nil
      return true
    } catch {
      failure = .updateEntry
      return false
    }
  }

  private func containsWriting(_ text: String) -> Bool {
    text.contains(where: { !$0.isWhitespace })
  }
}
