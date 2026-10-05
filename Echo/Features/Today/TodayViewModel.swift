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

struct TodayMemorySnapshot: Equatable, Sendable {
  var onThisDay: [EchoEntry] = []
  var unfinished: [EchoEntry] = []
  var saved: [EchoEntry] = []
}

@MainActor
@Observable
final class TodayViewModel {
  private let repository: any EchoEntryRepository
  private let highlightRepository: (any EchoHighlightRepository)?
  private let calendar: Calendar
  private let now: () -> Date

  private(set) var displayedDate: Date
  private(set) var entries: [EchoEntry] = []
  private(set) var isLoading = false
  private(set) var saveState: TodayEntrySaveState = .idle
  private(set) var failure: TodayJournalFailure?
  private(set) var memories = TodayMemorySnapshot()
  private(set) var isLoadingMemories = false

  init(
    repository: any EchoEntryRepository,
    highlightRepository: (any EchoHighlightRepository)? = nil,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping () -> Date = Date.init
  ) {
    self.repository = repository
    self.highlightRepository = highlightRepository
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

    await loadMemories(relativeTo: currentDate)
  }

  private func loadMemories(relativeTo currentDate: Date) async {
    isLoadingMemories = true
    defer { isLoadingMemories = false }

    do {
      async let allEntriesRequest = repository.allEntries()
      async let highlightsRequest = highlightRepository?.allHighlights() ?? []
      let (allEntries, highlights) = try await (allEntriesRequest, highlightsRequest)
      let historicalEntries = allEntries.filter {
        $0.createdAt < currentDate
          && !calendar.isDate($0.createdAt, inSameDayAs: currentDate)
      }
      let recentCutoff = calendar.date(
        byAdding: .day,
        value: -90,
        to: currentDate
      ) ?? .distantPast
      let currentComponents = calendar.dateComponents([.month, .day], from: currentDate)
      let highlightedEntryIDs = Set(
        highlights.compactMap { highlight in
          highlight.target.kind == .entry ? highlight.target.entityID : nil
        }
      )

      memories = TodayMemorySnapshot(
        onThisDay: newestFirst(
          historicalEntries.filter { entry in
            let components = calendar.dateComponents([.month, .day], from: entry.createdAt)
            return components.month == currentComponents.month
              && components.day == currentComponents.day
          }
        ),
        unfinished: newestFirst(
          historicalEntries.filter { $0.createdAt >= recentCutoff && isUnfinished($0) }
        ),
        saved: newestFirst(
          historicalEntries.filter { highlightedEntryIDs.contains($0.id) }
        )
      )
    } catch {
      memories = TodayMemorySnapshot()
    }
  }

  private func isUnfinished(_ entry: EchoEntry) -> Bool {
    let text = entry.rawText.lowercased()
    return text.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?")
      || ["still thinking", "need to", "want to", "come back", "later"]
        .contains(where: text.contains)
  }

  private func newestFirst(_ entries: [EchoEntry]) -> [EchoEntry] {
    Array(entries.sorted { lhs, rhs in
      if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
      return lhs.id.uuidString < rhs.id.uuidString
    }.prefix(3))
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
