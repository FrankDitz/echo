import Foundation

/// A transport-neutral event contract for a future personal Hub.
///
/// Creating an event does not send it anywhere. Echo deliberately keeps transport outside this
/// boundary so the journal remains useful and private without a Hub.
struct EchoHubEvent: Codable, Equatable, Sendable {
  static let currentSchemaVersion = 1

  let id: UUID
  let schemaVersion: Int
  let sourceApp: String
  let type: EchoHubEventType
  let occurredAt: Date
  let entityID: UUID
  let payload: EchoHubEventPayload

  init(
    id: UUID,
    type: EchoHubEventType,
    occurredAt: Date,
    entityID: UUID,
    payload: EchoHubEventPayload
  ) {
    self.id = id
    self.schemaVersion = Self.currentSchemaVersion
    self.sourceApp = "echo"
    self.type = type
    self.occurredAt = occurredAt
    self.entityID = entityID
    self.payload = payload
  }
}

/// Extensible rather than a closed enum so future event types remain forward-compatible.
struct EchoHubEventType: RawRepresentable, Codable, Equatable, Hashable, Sendable {
  let rawValue: String

  static let entryCreated = EchoHubEventType(rawValue: "echo.entry.created")
  static let entryUpdated = EchoHubEventType(rawValue: "echo.entry.updated")
  static let entryDeleted = EchoHubEventType(rawValue: "echo.entry.deleted")
  static let highlightCreated = EchoHubEventType(rawValue: "echo.highlight.created")
  static let highlightRemoved = EchoHubEventType(rawValue: "echo.highlight.removed")
}

struct EchoHubEventPayload: Codable, Equatable, Sendable {
  let day: EchoDayIdentifier?
  let entryType: String?
  let entrySource: String?
  let targetKind: String?
  let redaction: EchoHubRedaction
  let journalText: String?
  let authorizedConsumerID: String?
}

enum EchoHubRedaction: String, Codable, Equatable, Sendable {
  case journalTextOmitted
  case journalTextExplicitlyAuthorized
}

/// A purpose-limited grant supplied by a future Hub integration.
///
/// There is intentionally no global "share everything" switch. Each consumer must receive an
/// explicit grant for the journal-text scope, and callers may omit the permission entirely to get
/// the private metadata-only behavior.
struct EchoHubSharingPermission: Codable, Equatable, Sendable {
  enum Scope: String, Codable, Equatable, Sendable {
    case preferredJournalText
  }

  let consumerID: String
  let scopes: [Scope]

  init(consumerID: String, scopes: [Scope]) {
    self.consumerID = consumerID
    self.scopes = Array(Set(scopes.map(\.rawValue))).sorted().compactMap(Scope.init(rawValue:))
  }

  var permitsJournalText: Bool {
    scopes.contains(.preferredJournalText)
  }
}

enum EchoHubEventMapper {
  static func entryEvent(
    _ type: EchoHubEventType,
    entry: EchoEntry,
    eventID: UUID,
    occurredAt: Date,
    permission: EchoHubSharingPermission? = nil
  ) -> EchoHubEvent {
    let sharedContent = sharedContent(for: entry, permission: permission)
    return EchoHubEvent(
      id: eventID,
      type: type,
      occurredAt: occurredAt,
      entityID: entry.id,
      payload: EchoHubEventPayload(
        day: entry.day,
        entryType: entry.type.rawValue,
        entrySource: entry.source.rawValue,
        targetKind: nil,
        redaction: sharedContent.redaction,
        journalText: sharedContent.text,
        authorizedConsumerID: sharedContent.consumerID
      )
    )
  }

  static func deletedEntryEvent(
    entryID: UUID,
    eventID: UUID,
    occurredAt: Date
  ) -> EchoHubEvent {
    EchoHubEvent(
      id: eventID,
      type: .entryDeleted,
      occurredAt: occurredAt,
      entityID: entryID,
      payload: metadataOnlyPayload()
    )
  }

  static func highlightEvent(
    _ type: EchoHubEventType,
    highlight: EchoHighlight,
    eventID: UUID,
    occurredAt: Date,
    entry: EchoEntry? = nil,
    permission: EchoHubSharingPermission? = nil
  ) -> EchoHubEvent {
    let sharedContent = entry.map { sharedContent(for: $0, permission: permission) }
    return EchoHubEvent(
      id: eventID,
      type: type,
      occurredAt: occurredAt,
      entityID: highlight.id,
      payload: EchoHubEventPayload(
        day: entry?.day,
        entryType: entry?.type.rawValue,
        entrySource: entry?.source.rawValue,
        targetKind: highlight.target.kind.rawValue,
        redaction: sharedContent?.redaction ?? .journalTextOmitted,
        journalText: sharedContent?.text,
        authorizedConsumerID: sharedContent?.consumerID
      )
    )
  }

  private static func sharedContent(
    for entry: EchoEntry,
    permission: EchoHubSharingPermission?
  ) -> (redaction: EchoHubRedaction, text: String?, consumerID: String?) {
    guard let permission, permission.permitsJournalText else {
      return (.journalTextOmitted, nil, nil)
    }
    return (
      .journalTextExplicitlyAuthorized,
      entry.preferredText,
      permission.consumerID
    )
  }

  private static func metadataOnlyPayload() -> EchoHubEventPayload {
    EchoHubEventPayload(
      day: nil,
      entryType: nil,
      entrySource: nil,
      targetKind: nil,
      redaction: .journalTextOmitted,
      journalText: nil,
      authorizedConsumerID: nil
    )
  }
}

enum EchoHubEventCodec {
  static func encoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    return encoder
  }

  static func decoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
