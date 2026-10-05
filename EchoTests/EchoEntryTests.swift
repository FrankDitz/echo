import Foundation
import Testing

@testable import Echo

@Suite("Journal entry domain")
struct EchoEntryTests {
  @Test("Creation preserves identity, timestamps, classification, and original text")
  func creation() throws {
    let id = try makeUUID("00000000-0000-0000-0000-000000000101")
    let createdAt = try makeDate("2026-09-29T14:15:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "America/New_York")

    let entry = EchoEntry(
      id: id,
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional note about a paper moon."
    )

    #expect(entry.id == id)
    #expect(entry.createdAt == createdAt)
    #expect(entry.modifiedAt == createdAt)
    #expect(entry.day == EchoDayIdentifier(containing: createdAt, calendar: calendar))
    #expect(entry.rawText == "A fictional note about a paper moon.")
    #expect(entry.polishedText == nil)
    #expect(entry.type == .text)
    #expect(entry.source == .user)
  }

  @Test("Editing changes original text and modification time without changing creation metadata")
  func editing() throws {
    let id = try makeUUID("00000000-0000-0000-0000-000000000102")
    let createdAt = try makeDate("2026-09-29T14:15:00Z")
    let editedAt = try makeDate("2026-09-29T16:45:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "America/New_York")
    var entry = EchoEntry(
      id: id,
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional first draft."
    )
    let originalDay = entry.day

    entry.editRawText("A fictional revised draft.", at: editedAt)

    #expect(entry.rawText == "A fictional revised draft.")
    #expect(entry.modifiedAt == editedAt)
    #expect(entry.id == id)
    #expect(entry.createdAt == createdAt)
    #expect(entry.day == originalDay)
  }

  @Test("Modification time never moves backward")
  func modificationTimeIsMonotonic() throws {
    let createdAt = try makeDate("2026-09-29T14:15:00Z")
    let editedAt = try makeDate("2026-09-29T16:45:00Z")
    let staleTimestamp = try makeDate("2026-09-29T15:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    var entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional clock test."
    )

    entry.editRawText("A fictional current revision.", at: editedAt)
    entry.editRawText("A fictional revision from a stale clock.", at: staleTimestamp)

    #expect(entry.modifiedAt == editedAt)
  }

  @Test("Polished text remains separate from original text")
  func polishedTextDoesNotReplaceOriginal() throws {
    let createdAt = try makeDate("2026-09-29T14:15:00Z")
    let polishedAt = try makeDate("2026-09-29T17:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    var entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "fictional rough wording"
    )

    entry.setPolishedText("Fictional rough wording.", at: polishedAt)

    #expect(entry.rawText == "fictional rough wording")
    #expect(entry.polishedText == "Fictional rough wording.")
    #expect(entry.modifiedAt == polishedAt)
  }

  @Test("Entries round-trip through Codable without losing domain data")
  func codableRoundTrip() throws {
    let createdAt = try makeDate("2026-09-29T14:15:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000103"),
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional serialization note.",
      polishedText: "A fictional serialization note."
    )

    let encoded = try JSONEncoder().encode(entry)
    let decoded = try JSONDecoder().decode(EchoEntry.self, from: encoded)

    #expect(decoded == entry)
  }
}

@Suite("Voice attachment domain")
struct EchoVoiceAttachmentTests {
  @Test("Voice metadata is portable and transcript updates stay separate")
  func metadata() throws {
    var attachment = EchoVoiceAttachment(
      id: try makeUUID("00000000-0000-0000-0000-000000000191"),
      entryID: try makeUUID("00000000-0000-0000-0000-000000000192"),
      createdAt: try makeDate("2026-10-05T12:00:00Z"),
      relativeFileName: "00000000-0000-0000-0000-000000000191.m4a",
      duration: -1
    )

    #expect(attachment.duration == 0)
    #expect(!attachment.relativeFileName.hasPrefix("/"))
    attachment.setTranscript("A fictional on-device transcript.")
    #expect(attachment.transcript == "A fictional on-device transcript.")
  }
}
