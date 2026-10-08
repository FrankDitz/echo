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

## Implemented event boundary

`EchoHubEvent` is a versioned, `Codable`, transport-neutral envelope. It includes a stable event
UUID, source application, event type, ISO-8601 timestamp, entity UUID, and a typed payload. The
boundary currently maps entry and highlight lifecycle events but does not publish or transport
them.

Potential Echo event types:

- `echo.entry.created`
- `echo.entry.updated`
- `echo.entry.deleted`
- `echo.highlight.created`
- `echo.highlight.removed`
- `echo.day.organized`

An event describes a change; it is not permission to copy journal content. Mapping without an
`EchoHubSharingPermission` always produces a metadata-only payload whose `journalText` is absent.
A future consumer must present a purpose-specific permission containing the
`preferredJournalText` scope before Echo includes the preferred reading text. Original capture
text is never part of this contract.

The encoder uses sorted JSON keys and ISO-8601 dates for reproducible, unambiguous payloads. Tests
assert that fictional raw and refined journal text cannot appear in default entry, highlight, or
deletion events.

## Ambition relationship

Echo must not import or link directly against Ambition. A future Hub may project an Ambition focus session into a combined life timeline using a shared contract. Echo can render external timeline items through a generic representation when that feature is intentionally designed.

## Evolution path

1. Stable Echo domain identifiers and timestamps. **Complete.**
2. `Codable`, versioned transfer representations separate from persistence models. **Complete.**
3. In-process event mapping boundary with tests. **Complete.**
4. Explicit permission and redaction policy. **Complete.**
5. Choose transport and delivery semantics only when a real Hub exists. **Deferred.**

This sequence avoids speculative networking while keeping future integration possible.
