import Foundation

/// An extensible target kind allows highlights to reference more than entries later.
struct EchoHighlightTargetKind: RawRepresentable, Codable, Hashable, Sendable {
  let rawValue: String

  static let entry = EchoHighlightTargetKind(rawValue: "entry")
}

struct EchoHighlightTarget: Codable, Hashable, Sendable {
  let kind: EchoHighlightTargetKind
  let entityID: UUID

  static func entry(_ entryID: UUID) -> EchoHighlightTarget {
    EchoHighlightTarget(kind: .entry, entityID: entryID)
  }
}

struct EchoHighlight: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  let target: EchoHighlightTarget
  let createdAt: Date

  init(
    id: UUID = UUID(),
    target: EchoHighlightTarget,
    createdAt: Date
  ) {
    self.id = id
    self.target = target
    self.createdAt = createdAt
  }
}

struct EchoHighlightCollection: Hashable, Sendable {
  private(set) var highlights: [EchoHighlight] = []

  init() {}

  func highlight(for target: EchoHighlightTarget) -> EchoHighlight? {
    highlights.first { $0.target == target }
  }

  func contains(_ target: EchoHighlightTarget) -> Bool {
    highlight(for: target) != nil
  }

  @discardableResult
  mutating func insert(_ highlight: EchoHighlight) -> Bool {
    guard !contains(highlight.target) else { return false }

    highlights.append(highlight)
    highlights.sort { lhs, rhs in
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt < rhs.createdAt
      }

      return lhs.id.uuidString < rhs.id.uuidString
    }
    return true
  }

  @discardableResult
  mutating func removeHighlight(for target: EchoHighlightTarget) -> EchoHighlight? {
    guard let index = highlights.firstIndex(where: { $0.target == target }) else {
      return nil
    }

    return highlights.remove(at: index)
  }
}
