# Roadmap

Each phase is implemented, built, tested where behavior exists, reviewed, committed, and reported before the next begins.

## MVP phases

- **Phase 0 — Foundation (complete):** shared iPhone/Mac SwiftUI project, app shell, public-repository privacy safeguards, and core documentation.
- **Phase 1 — Journal domain (complete):** entry and day models, extensible source and type values, independent highlight relationships, async repository contracts, calendar-aware grouping, deterministic ordering, and fictional-data tests.
- **Phase 2 — Local persistence (complete):** versioned SwiftData records, mapping, and repository actors with durable entry and highlight CRUD. Production storage uses the application container with CloudKit disabled; tests use in-memory or disposable stores and prove no data is written beneath the source checkout.
- **Phase 3 — Today (complete):** fast text capture, current-date loading, chronological entries, calm loading and empty states, focused editing with explicit save feedback, and confirmed deletion.
- **Phase 4 — Timeline (complete):** previous-day filtering and newest-first summaries, entry counts and previews, captured-date presentation, refresh states, native Day Detail navigation, and readable chronological entries.
- **Phase 5 — Highlights (complete):** highlight and unhighlight entries, browse a newest-highlighted-first curated collection, remove highlights, and navigate to the emphasized source entry within its complete day context.
- **Phase 6 — AI architecture (complete):** provider-neutral cleanup, polish, and day-organization contracts; a deterministic offline implementation; separately persisted assisted text; versioned organized-journal storage; Day Detail generation and regeneration; and provenance, durability, failure, and immutability tests. No provider credential, network call, or real journal content enters the app bundle, fixtures, logs, or Git.
- **Phase 7 — Visual worlds and presentation system (in progress):** build a mature, reusable presentation architecture around the approved Mirror City direction, with Teal Immersion as the default visual world and optional Crimson Static, Sodium Fog, and Electric Blue Hour worlds. Theme choice changes presentation only; journal data and application behavior remain unchanged.
- **Phase 8 — MVP review:** full builds and tests, architecture and privacy review, naming cleanup, documentation refresh, staged-data scan, and full reachable-history scan.

## Phase 7 deliverables

Each deliverable uses its own short-lived branch and pull request. A deliverable is built, tested in proportion to its behavior, reviewed, and merged before the next begins.

1. **Presentation architecture (complete):** document UI ownership, shared-component boundaries, visual-world constraints, privacy rules, and the source layout that later deliverables will fill. Do not add placeholder production types or move feature files without a concrete ownership improvement.
2. **Theme-neutral UI foundation (complete):** add semantic typography, spacing, shape, material, and motion tokens without encoding a particular visual world in feature screens.
3. **Reusable presentation components (complete):** extract the page scaffold, navigation, capture control, entry presentation, date navigation, reflection sections, and shared loading, empty, and error states as their first real consumers are migrated.
4. **Teal Immersion default world (complete):** create production background artwork, define its presentation values, and apply the approved Mirror City composition across Today, Timeline, Day Detail, Highlights, Entry Editor, and assisted-writing states.
5. **Theme selection (complete):** add an accessible visual-world selector and persist only the stable selected-world identifier in application preferences. Selection must not touch SwiftData journal records.
6. **Additional visual worlds:** add Crimson Static, Sodium Fog, and Electric Blue Hour independently, validating each background crop, contrast, and component treatment before the next world is introduced.
7. **Motion and icon polish:** add purposeful transitions, feedback, and an Echo icon vocabulary while honoring Reduce Motion and avoiding ornamental animation.
8. **Platform and accessibility review:** validate supported iPhone, iPad, and Mac layouts; Dynamic Type; VoiceOver labels and order; contrast; keyboard behavior; reduced transparency; and light-sensitive presentation.
9. **Phase closeout:** run full builds and tests, simulator review, repository-safety scans, documentation refresh, and a final comparison against the approved visual specification.

## Near-term improvements

- Search and calendar browsing
- Optional broad writing prompts
- Passage-level highlights
- Photos and video attachments
- Voice notes, playback, and transcription
- People, places, and custom tags
- Editable organized journals
- Export to Markdown and PDF
- iCloud synchronization
- Face ID or Touch ID app locking

## Future experiences

- AI-assisted reflections and weekly summaries
- Trips, stories, and life chapters
- Semantic search across personal writing
- “On This Day” and gentle memory resurfacing
- Yearly retrospectives
- Richer media and attachment management

## Long-term personal Hub

- Versioned, serialization-friendly Echo event contracts
- Cross-app life timeline
- Ambition focus-session context without direct app coupling
- Cross-app summaries, search, and analytics
- Explicit per-data-type privacy and sharing controls

The Hub, real AI providers, sync, media, and long-term features are documented here but are not authorized by the current phase.
