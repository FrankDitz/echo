import Foundation
import Testing

@testable import Echo

@Suite("Organized journal domain")
struct EchoOrganizedJournalTests {
  @Test("Regeneration preserves identity and day while advancing content")
  func regeneration() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let day = EchoDayIdentifier(
      containing: try makeDate("2026-10-06T12:00:00Z"),
      calendar: calendar
    )
    let createdAt = try makeDate("2026-10-06T20:00:00Z")
    let regeneratedAt = try makeDate("2026-10-06T21:00:00Z")
    let firstSource = try makeUUID("00000000-0000-0000-0000-000000000901")
    let secondSource = try makeUUID("00000000-0000-0000-0000-000000000902")
    var journal = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000903"),
      day: day,
      createdAt: createdAt,
      body: "A fictional first organization.",
      sourceEntryIDs: [firstSource],
      generator: .deterministicLocal
    )

    journal.regenerate(
      body: "A fictional regenerated organization.",
      sourceEntryIDs: [firstSource, secondSource],
      at: regeneratedAt
    )

    #expect(journal.day == day)
    #expect(journal.createdAt == createdAt)
    #expect(journal.modifiedAt == regeneratedAt)
    #expect(journal.body == "A fictional regenerated organization.")
    #expect(journal.sourceEntryIDs == [firstSource, secondSource])
    #expect(journal.generator == .deterministicLocal)
  }

  @Test("Organized journals round-trip through Codable")
  func codableRoundTrip() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let journal = EchoOrganizedJournal(
      day: EchoDayIdentifier(
        containing: try makeDate("2026-10-06T12:00:00Z"),
        calendar: calendar
      ),
      createdAt: try makeDate("2026-10-06T20:00:00Z"),
      body: "A fictional organized journal.",
      sourceEntryIDs: [try makeUUID("00000000-0000-0000-0000-000000000904")],
      generator: .deterministicLocal
    )

    let decoded = try JSONDecoder().decode(
      EchoOrganizedJournal.self,
      from: JSONEncoder().encode(journal)
    )

    #expect(decoded == journal)
  }
}
