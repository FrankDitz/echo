import Foundation
import Testing

@testable import Echo

@Suite("Entry highlights")
struct EchoHighlightTests {
  @Test("An entry can be highlighted only once")
  func highlightingEntry() throws {
    let entryID = try makeUUID("00000000-0000-0000-0000-000000000301")
    let target = EchoHighlightTarget.entry(entryID)
    let first = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000302"),
      target: target,
      createdAt: try makeDate("2026-09-29T10:00:00Z")
    )
    let duplicate = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000303"),
      target: target,
      createdAt: try makeDate("2026-09-29T11:00:00Z")
    )
    var collection = EchoHighlightCollection()

    let insertedFirst = collection.insert(first)
    let insertedDuplicate = collection.insert(duplicate)

    #expect(insertedFirst)
    #expect(!insertedDuplicate)
    #expect(collection.contains(target))
    #expect(collection.highlight(for: target) == first)
    #expect(collection.highlights == [first])
  }

  @Test("Removing a highlight preserves the entry identity for future navigation")
  func removingHighlight() throws {
    let entryID = try makeUUID("00000000-0000-0000-0000-000000000304")
    let target = EchoHighlightTarget.entry(entryID)
    let highlight = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000305"),
      target: target,
      createdAt: try makeDate("2026-09-29T10:00:00Z")
    )
    var collection = EchoHighlightCollection()
    collection.insert(highlight)

    let removed = collection.removeHighlight(for: target)

    #expect(removed == highlight)
    #expect(removed?.target.entityID == entryID)
    #expect(!collection.contains(target))
    #expect(collection.removeHighlight(for: target) == nil)
  }

  @Test("Highlight targets use an extensible serialized kind")
  func extensibleTargetKind() throws {
    let futureKind = EchoHighlightTargetKind(rawValue: "organizedJournal")
    let target = EchoHighlightTarget(
      kind: futureKind,
      entityID: try makeUUID("00000000-0000-0000-0000-000000000306")
    )
    let encoded = try JSONEncoder().encode(target)
    let decoded = try JSONDecoder().decode(EchoHighlightTarget.self, from: encoded)

    #expect(decoded == target)
    #expect(decoded.kind.rawValue == "organizedJournal")
  }
}
