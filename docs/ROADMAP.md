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
6. **Additional visual worlds (complete):** add Crimson Static, Sodium Fog, and Electric Blue Hour independently, validating each background crop, contrast, and component treatment before the next world is introduced.
7. **Editorial app shell (complete):** replace generic system tab and toolbar presentation with an Echo wordmark, custom theme-aware primary navigation, responsive iPhone, iPad, and Mac chrome, and reusable navigation styling. Preserve the existing Today, Timeline, Highlights, and Settings behavior.
8. **Today product UI (complete):** realize the approved prompt-led capture composition, a clear text-entry action, and a compact timestamped raw-entry list while preserving loading, empty, error, edit, and deletion behavior. Do not show microphone or media controls before those capabilities exist.
9. **Timeline product UI (complete):** realize the approved date-browsing composition and vertical entry rail while preserving previous-day filtering, refresh states, and native Day Detail navigation.
10. **Day Detail and Reflection product UI (complete):** realize the editorial reflection hierarchy, provenance, original-source rows, and organize/regenerate actions. Show titles, themes, or other generated structure only when the domain model actually provides it.
11. **Highlights product UI (complete):** realize the compact saved-writing and bookmark composition with source navigation and removal behavior. Add filters only for content types the product supports.
12. **Approved-composition fidelity — shared shell and Today (complete):** match the reference hierarchy, translucency, typography, prompt placement, capture silhouette, raw-entry density, and mobile proportions while keeping text capture honest and fully functional.
13. **Approved-composition fidelity — Timeline (complete):** match the reference calendar ribbon, month treatment, chronology rail, timestamps, spacing, and transparent layering without introducing unsupported media controls.
14. **Approved-composition fidelity — Day Reflection (complete):** match the reference editorial scale, narrative flow, source-entry density, action placement, and transparent layering using only generated fields the domain model actually provides.
15. **Approved-composition fidelity — Highlights (complete):** match the reference saved-writing rhythm, filtering silhouette, bookmark placement, row density, and transparent layering while exposing only supported text content.
16. **Entry Editor and assisted-writing product UI:** realize a focused writing surface, explicit save feedback, and a clear visual separation between original and assisted text without changing persistence behavior.
17. **Motion and icon polish:** add purposeful transitions, feedback, and an Echo icon vocabulary while honoring Reduce Motion and avoiding ornamental animation.
18. **Platform and accessibility review:** validate supported iPhone, iPad, and Mac layouts; Dynamic Type; VoiceOver labels and order; contrast; keyboard behavior; reduced transparency; and light-sensitive presentation.
19. **Phase closeout:** run full builds and tests, simulator review, repository-safety scans, documentation refresh, and a final comparison against the approved visual specification.

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
