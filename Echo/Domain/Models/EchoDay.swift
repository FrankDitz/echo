import Foundation

struct EchoDay: Identifiable, Hashable, Sendable {
  let id: EchoDayIdentifier
  let entries: [EchoEntry]

  private init(id: EchoDayIdentifier, entries: [EchoEntry]) {
    self.id = id
    self.entries = entries
  }

  var entryCount: Int {
    entries.count
  }

  static func grouping(_ entries: [EchoEntry]) -> [EchoDay] {
    Dictionary(grouping: entries, by: \.day)
      .map { day, entries in
        EchoDay(id: day, entries: EchoEntryOrdering.chronological(entries))
      }
      .sorted { $0.id < $1.id }
  }
}
