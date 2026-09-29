# Future Hub Integration

Echo will eventually participate in a personal Hub alongside Ambition and other applications. The MVP does not implement a Hub client, backend, event bus, networking layer, or dependency on another app.

## Design principles

- Echo owns its journal data and decides what may leave the app.
- Entity identifiers are stable UUIDs.
- Timestamps are explicit and serialize in an unambiguous standard such as ISO 8601.
- Contracts are versioned and additive where possible.
- Event payloads contain the minimum data needed by the consumer.
- Private journal text is not included by default merely because an event occurred.
- Delivery is replaceable; the domain does not depend on a transport.

## Conceptual event envelope

```text
HubEvent
  id: UUID
  schemaVersion: Int
  sourceApp: String
  eventType: String
  timestamp: Date
  entityID: UUID
  metadata: [String: serialization-safe value]
```

Potential Echo event types:

- `echo.entry.created`
- `echo.entry.updated`
- `echo.entry.deleted`
- `echo.highlight.created`
- `echo.highlight.removed`
- `echo.day.organized`

An event describes a change; it is not automatically permission to copy full journal content. A future integration policy should decide whether metadata, previews, or content can be shared for each consumer and use case.

## Ambition relationship

Echo must not import or link directly against Ambition. A future Hub may project an Ambition focus session into a combined life timeline using a shared contract. Echo can render external timeline items through a generic representation when that feature is intentionally designed.

## Evolution path

1. Define stable Echo domain identifiers and timestamps.
2. Define `Codable`, versioned transfer representations separate from persistence models.
3. Add an in-process event mapping boundary with tests.
4. Add an explicit permission and redaction policy.
5. Choose transport and delivery semantics only when a real Hub exists.

This sequence avoids speculative networking while keeping future integration possible.

