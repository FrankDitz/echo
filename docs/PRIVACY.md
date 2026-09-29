# Privacy

Journal content can be among the most sensitive data a person keeps. Echo treats privacy as a product constraint, not a later preference.

## Current behavior

Phase 0 stores no journal data. The application has no account system, networking, analytics, advertising, external AI provider, cloud sync, or third-party dependency. It requests no protected-system permissions.

The project must never commit real journal content, credentials, API keys, tokens, private exports, or local database files. Application code should not log entry text.

## Local persistence

Phase 2 will keep entries in the app's local sandbox through a persistence adapter. Persistence models and migration behavior will be reviewed separately. Backups, deletion semantics, and file protection need explicit verification before claiming stronger guarantees.

## AI processing

The first AI service is local and deterministic. Before any remote provider is introduced, Echo must document:

- what content is sent and for which user-initiated operation
- provider retention and training policies
- transport security and regional processing considerations
- redaction or on-device alternatives
- cancellation, failure, and deletion behavior
- clear consent and an option to keep AI fully disabled

Raw text remains stored separately from assisted output and is never overwritten by it.

## Cloud synchronization and backups

iCloud or other synchronization is out of MVP scope. A future design must cover encryption, conflict resolution, account changes, deletion propagation, recovery, and the distinction between synchronization and backup. Users should understand which copies exist and how to remove them.

## Media

Photos, video, and audio can expose faces, voices, locations, and embedded metadata. Future media work must define permission prompts, metadata handling, storage protection, deletion, export, and whether processing occurs on-device or remotely.

## App locking

Face ID or Touch ID locking is a future defense-in-depth feature. Its design must account for fallback authentication, app-switcher snapshots, notifications, widgets, Spotlight, and accessibility—not just the unlock screen.

## Hub integration

Hub access must be opt-in and purpose-limited. Events should omit journal text by default, expose the smallest useful metadata, and support per-consumer authorization and revocation. Cross-app summaries must clearly identify which private sources are being used.

## Export and diagnostics

Exports require clear destination and deletion behavior. Diagnostic logs and crash reports must avoid journal text, generated journals, media content, search terms, and stable identifiers where they are unnecessary.

