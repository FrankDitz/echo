import Foundation
import Observation

enum EntryHighlightFailure: Equatable {
  case load
  case update
}

@MainActor
@Observable
final class EntryHighlightViewModel {
  private let repository: any EchoHighlightRepository
  private let now: () -> Date

  private var highlightsByEntryID: [UUID: EchoHighlight] = [:]
  private(set) var updatingEntryIDs: Set<UUID> = []
  private(set) var failure: EntryHighlightFailure?

  init(
    repository: any EchoHighlightRepository,
    now: @escaping () -> Date = Date.init
  ) {
    self.repository = repository
    self.now = now
  }

  func load() async {
    do {
      highlightsByEntryID = Dictionary(
        uniqueKeysWithValues: try await repository.allHighlights().compactMap { highlight in
          guard highlight.target.kind == .entry else { return nil }
          return (highlight.target.entityID, highlight)
        }
      )
      failure = nil
    } catch {
      failure = .load
    }
  }

  func isHighlighted(_ entryID: UUID) -> Bool {
    highlightsByEntryID[entryID] != nil
  }

  @discardableResult
  func toggle(entryID: UUID) async -> Bool {
    guard !updatingEntryIDs.contains(entryID) else { return false }

    updatingEntryIDs.insert(entryID)
    defer { updatingEntryIDs.remove(entryID) }

    do {
      if let highlight = highlightsByEntryID[entryID] {
        try await repository.delete(id: highlight.id)
        highlightsByEntryID[entryID] = nil
      } else {
        let highlight = EchoHighlight(
          target: .entry(entryID),
          createdAt: now()
        )
        try await repository.create(highlight)
        highlightsByEntryID[entryID] = highlight
      }
      failure = nil
      return true
    } catch {
      failure = .update
      return false
    }
  }
}
