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
- **Phase 7 — Visual worlds and presentation system (complete):** build a mature, reusable presentation architecture around the approved Mirror City direction, with Teal Immersion as the default visual world and optional Crimson Static, Sodium Fog, and Electric Blue Hour worlds. Theme choice changes presentation only; journal data and application behavior remain unchanged.
- **Phase 8 — Memory, reflection, and continuity (in progress):** turn the functional journal into a product worth returning to through honest retrieval, richer private reflection, memory resurfacing, faster capture, and explicit personal-data controls. Each capability remains local-first, optional where appropriate, and independently reviewable.
- **Phase 9 — MVP review:** full builds and tests, architecture and privacy review, naming cleanup, documentation refresh, staged-data scan, and full reachable-history scan.

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
16. **Entry Editor product UI (complete):** replace the generic editing sheet with a focused Echo writing surface, explicit save feedback, and a clear visual separation between original and assisted text without changing persistence behavior.
17. **Interaction honesty and control polish (complete):** remove or restyle affordances that imply unavailable voice, media, filtering, or calendar behavior; every enabled control must perform the action it communicates.
18. **Motion and icon language (complete):** add purposeful capture, selection, navigation, and theme transitions plus a consistent Echo icon vocabulary while honoring Reduce Motion and avoiding ornamental animation.
19. **Mac workspace composition (complete):** make productive use of wide windows, add appropriate keyboard commands and focus behavior, and avoid presenting a stretched phone composition on macOS.
20. **Platform and accessibility review (complete):** validate supported iPhone, iPad, and Mac layouts; Dynamic Type; VoiceOver labels and order; contrast; keyboard behavior; reduced transparency; and light-sensitive presentation.
21. **Phase closeout (complete):** run full builds and tests, simulator review, repository-safety scans, documentation refresh, and a final comparison against the approved visual specification.

## Phase 8 deliverables

Phase 8 begins only after the completed Phase 7 application has been reviewed together. Every deliverable uses its own short-lived branch and pull request and must preserve the public-source/private-journal boundary.

1. **Search contracts and indexing (complete):** add testable repository queries for private full-text retrieval without copying journal content into logs, fixtures, Spotlight, or a second unprotected store.
2. **Search experience (complete):** add a responsive search surface with useful snippets, dates, keyboard focus, empty states, and navigation back to the complete source day.
3. **Calendar browsing (complete):** replace decorative calendar affordances with a real month browser, day indicators, date selection, and direct navigation to days containing entries.
4. **Reflection structure domain (complete):** extend organized journals with optional generated title, themes, key moments, and reflection questions through a versioned migration that preserves existing journals and raw entries.
5. **Richer reflection generation and UI:** produce and present the new reflection structure with the deterministic local provider first, keeping regeneration explicit and original-source provenance visible.
6. **Memory resurfacing:** add private “On This Day,” recent unfinished thoughts, and saved-memory resurfacing with neutral empty states and no streaks, guilt, or engagement pressure.
7. **Weekly Echo foundation:** define, persist, and test a weekly reflection containing source provenance, recurring themes, notable entries, and an optional question for the coming week.
8. **Weekly Echo experience:** add browsing, generation, regeneration, and source navigation for weekly reflections without replacing daily reflections.
9. **Voice entry foundation:** add versioned local attachment metadata and lifecycle rules for voice entries, including safe file placement, deletion, migration, and repository-safety tests.
10. **Voice capture, playback, and transcription:** add permission-aware recording, playback, and on-device transcription where supported, with clear failure and privacy states on iPhone, iPad, and Mac.
11. **Export and recovery:** add user-initiated Markdown and PDF export plus an explicit local recovery workflow; exports never enter Git or silently leave the selected destination.
12. **App privacy lock:** add optional Face ID or Touch ID protection, app-switcher privacy shielding, and careful fallback and accessibility behavior.
13. **Private synchronization design:** document encryption, CloudKit ownership, conflict resolution, deletion propagation, account changes, recovery, and opt-in consent before enabling any synchronization.
14. **Optional iCloud synchronization:** implement the approved design behind an explicit setting, preserve a fully local mode, and test migration and conflict behavior before enabling it by default anywhere.
15. **Phase closeout:** validate daily and weekly value loops, privacy boundaries, cross-platform behavior, migration safety, exports, synchronization opt-in, full builds and tests, and reachable Git history.

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
