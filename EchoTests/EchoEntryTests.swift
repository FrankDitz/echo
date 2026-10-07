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
    #expect(entry.originalText == "A fictional note about a paper moon.")
    #expect(entry.rawText == "A fictional note about a paper moon.")
    #expect(entry.polishedText == nil)
    #expect(entry.preferredText == entry.rawText)
    #expect(entry.refinementStatus == .notRequested)
    #expect(entry.refinementProvenance == nil)
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
    #expect(entry.originalText == "A fictional first draft.")
    #expect(entry.modifiedAt == editedAt)
    #expect(entry.id == id)
    #expect(entry.createdAt == createdAt)
    #expect(entry.day == originalDay)
  }

  @Test("Refinement preserves the original capture and becomes preferred reading text")
  func refinementLifecycle() throws {
    let createdAt = try makeDate("2026-09-29T14:15:00Z")
    let refinedAt = try makeDate("2026-09-29T14:15:03Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let provenance = EchoEntryRefinementProvenance(
      processorIdentifier: "echo.test.refiner",
      modelIdentifier: "fictional-model",
      generatedAt: refinedAt
    )
    var entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "fictional meeting went good"
    )

    entry.beginRefinement(at: createdAt.addingTimeInterval(1))
    #expect(entry.refinementStatus == .processing)
    #expect(entry.preferredText == "fictional meeting went good")

    entry.completeRefinement(
      text: "The fictional meeting went well.",
      provenance: provenance,
      requiresReview: false,
      at: refinedAt
    )

    #expect(entry.originalText == "fictional meeting went good")
    #expect(entry.rawText == "fictional meeting went good")
    #expect(entry.polishedText == "The fictional meeting went well.")
    #expect(entry.preferredText == "The fictional meeting went well.")
    #expect(entry.refinementStatus == .refined)
    #expect(entry.refinementProvenance == provenance)

    entry.editRawText(
      "fictional meeting became clearer",
      at: refinedAt.addingTimeInterval(1)
    )
    #expect(entry.originalText == "fictional meeting went good")
    #expect(entry.preferredText == "fictional meeting became clearer")
    #expect(entry.refinementStatus == .notRequested)
    #expect(entry.refinementProvenance == nil)
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

  @Test("Older serialized entries receive safe refinement defaults")
  func legacyCodableDefaults() throws {
    let createdAt = try makeDate("2026-09-29T14:15:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional legacy note.",
      polishedText: "A fictional legacy note."
    )
    let encoded = try JSONEncoder().encode(entry)
    var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    object.removeValue(forKey: "originalText")
    object.removeValue(forKey: "refinementStatus")
    object.removeValue(forKey: "refinementProvenance")

    let decoded = try JSONDecoder().decode(
      EchoEntry.self,
      from: JSONSerialization.data(withJSONObject: object)
    )

    #expect(decoded.originalText == entry.rawText)
    #expect(decoded.preferredText == entry.polishedText)
    #expect(decoded.refinementStatus == .refined)
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
