# Privacy

Journal content can be among the most sensitive data a person keeps. Echo treats privacy as a product constraint, not a later preference.

## Current behavior

Journal data and assisted output remain in the application's local sandbox. The application has no account system, networking, analytics, advertising, external AI provider, cloud sync, or third-party dependency. Phase 6 uses a deterministic in-process stand-in that performs no inference, credential lookup, network request, or content logging. SwiftData explicitly disables CloudKit and the application requests no protected-system permissions.

The source repository is public. It must never contain real journal content, credentials, API keys, tokens, private exports, local database files, personal media, or screenshots of personal entries. Application code must not log entry text. Tests, previews, demos, and documentation use fictional data only.

## Local persistence

Phase 2 keeps entries and highlights in the system-provided application container through versioned SwiftData records and repository adapters. Production code does not derive a store location from the repository, current working directory, application bundle, or a relative path. Tests use in-memory or unique disposable stores and never copy the developer's personal container.

The initial schema establishes an explicit migration boundary, and CRUD plus persistence across container recreation are tested with fictional data. Backups, deletion semantics, and file protection need explicit verification before claiming stronger guarantees. Database files, sidecars, exports, backups, and runtime-media directories are ignored and rejected by repository safety checks.

## AI processing

The first AI service is local and deterministic. Before any remote provider is introduced, Echo must document:

- what content is sent and for which user-initiated operation
- provider retention and training policies
- transport security and regional processing considerations
- redaction or on-device alternatives
- cancellation, failure, and deletion behavior
- clear consent and an option to keep AI fully disabled

Raw text remains stored separately from assisted output and is never overwritten by it.

An app-owned provider key must never be compiled into or packaged with Echo; values placed in source, plist files, asset files, or build settings are extractable from a distributed client. A future user-supplied key belongs in Keychain. Alternatively, an authenticated service may hold its own provider credential outside the app. Local development secret files remain untracked.

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

## Public repository safeguards

The repository includes layered controls:

- ignore rules for databases, exports, private-data directories, signing material, and local secret configuration
- a pre-commit check for forbidden paths, unreviewed media, and common credential patterns
- a full-history CI scan on every push and pull request
- a fictional-data-only policy for fixtures, previews, screenshots, and bug reports
- a documented incident process because removing a later commit cannot recall public clones

These controls are guardrails, not permission to place private data near the repository. Personal content should remain in the application container and user-selected private export locations.
