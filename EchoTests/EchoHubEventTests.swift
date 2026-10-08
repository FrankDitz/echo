import Foundation
import Testing

@testable import Echo

@Suite("Private Hub event boundary")
struct EchoHubEventTests {
  @Test("Entry events omit all journal text without an explicit grant")
  func privateEntryEvent() throws {
    let entry = try refinedEntry()
    let event = EchoHubEventMapper.entryEvent(
      .entryCreated,
      entry: entry,
      eventID: try makeUUID("00000000-0000-0000-0000-000000000901"),
      occurredAt: try makeDate("2026-10-08T12:00:00Z")
    )

    let data = try EchoHubEventCodec.encoder().encode(event)
    let json = try #require(String(data: data, encoding: .utf8))

    #expect(event.schemaVersion == 1)
    #expect(event.sourceApp == "echo")
    #expect(event.payload.redaction == .journalTextOmitted)
    #expect(event.payload.journalText == nil)
    #expect(!json.contains("fictional rough private thought"))
    #expect(!json.contains("Fictional private thought."))
    #expect(try EchoHubEventCodec.decoder().decode(EchoHubEvent.self, from: data) == event)
  }

  @Test("A scoped consumer grant includes only preferred journal text")
  func explicitlyAuthorizedEntryEvent() throws {
    let entry = try refinedEntry()
    let permission = EchoHubSharingPermission(
      consumerID: "personal-hub.timeline",
      scopes: [.preferredJournalText]
    )
    let event = EchoHubEventMapper.entryEvent(
      .entryUpdated,
      entry: entry,
      eventID: try makeUUID("00000000-0000-0000-0000-000000000902"),
      occurredAt: try makeDate("2026-10-08T12:05:00Z"),
      permission: permission
    )

    let data = try EchoHubEventCodec.encoder().encode(event)
    let json = try #require(String(data: data, encoding: .utf8))

    #expect(event.payload.redaction == .journalTextExplicitlyAuthorized)
    #expect(event.payload.journalText == "Fictional private thought.")
    #expect(event.payload.authorizedConsumerID == "personal-hub.timeline")
    #expect(json.contains("Fictional private thought."))
    #expect(!json.contains("fictional rough private thought"))
  }

  @Test("Highlight and deletion events remain redacted by default")
  func redactedRelationshipEvents() throws {
    let entry = try refinedEntry()
    let highlight = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000903"),
      target: .entry(entry.id),
      createdAt: try makeDate("2026-10-08T12:10:00Z")
    )
    let highlightEvent = EchoHubEventMapper.highlightEvent(
      .highlightCreated,
      highlight: highlight,
      eventID: try makeUUID("00000000-0000-0000-0000-000000000904"),
      occurredAt: highlight.createdAt,
      entry: entry
    )
    let deletionEvent = EchoHubEventMapper.deletedEntryEvent(
      entryID: entry.id,
      eventID: try makeUUID("00000000-0000-0000-0000-000000000905"),
      occurredAt: try makeDate("2026-10-08T12:15:00Z")
    )

    let data = try EchoHubEventCodec.encoder().encode([highlightEvent, deletionEvent])
    let json = try #require(String(data: data, encoding: .utf8))

    #expect(highlightEvent.payload.targetKind == "entry")
    #expect(highlightEvent.payload.journalText == nil)
    #expect(deletionEvent.payload.journalText == nil)
    #expect(!json.contains("fictional rough private thought"))
    #expect(!json.contains("Fictional private thought."))
  }

  private func refinedEntry() throws -> EchoEntry {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    return EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000900"),
      createdAt: try makeDate("2026-10-08T11:55:00Z"),
      calendar: calendar,
      rawText: "fictional rough private thought",
      polishedText: "Fictional private thought."
    )
  }
}
