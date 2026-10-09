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
- **Phase 8 — Memory, reflection, and continuity (complete):** turn the functional journal into a product worth returning to through honest retrieval, richer private reflection, memory resurfacing, faster capture, and explicit personal-data controls. Each capability remains local-first, optional where appropriate, and independently reviewable.
- **Phase 9 — Frictionless intelligent capture (complete):** make writing or speaking a thought the shortest path through Echo, preserve every original capture, refine grammar and spoken cadence without changing meaning, and make important entries immediately recognizable.
- **Phase 10 — Urban Christian visual system (complete):** replaced the original city worlds with the approved Cornerstone Signal, Kingdom Green, Gold Standard, and Covenant Blue directions, including screen-specific artwork and concept-faithful components, while preserving private journal data, stable theme preferences, accessibility, and cross-platform behavior.
- **Phase 11 — iPhone concept fidelity (complete):** rebuilt the compact iPhone experience one screen at a time against the approved urban Christian concepts, correcting hierarchy, density, navigation, surface treatment, and populated-state behavior without altering private journal data.
- **Phase 12 — Mac concept fidelity:** translate the approved system into a purpose-built desktop workspace after the iPhone composition is reviewed and accepted.
- **Phase 13 — MVP review:** full builds and tests, architecture and privacy review, naming cleanup, documentation refresh, staged-data scan, and full reachable-history scan.

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
5. **Richer reflection generation and UI (complete):** produce and present the new reflection structure with the deterministic local provider first, keeping regeneration explicit and original-source provenance visible.
6. **Memory resurfacing (complete):** add private “On This Day,” recent unfinished thoughts, and saved-memory resurfacing with neutral empty states and no streaks, guilt, or engagement pressure.
7. **Weekly Echo foundation (complete):** define, persist, and test a weekly reflection containing source provenance, recurring themes, notable entries, and an optional question for the coming week.
8. **Weekly Echo experience (complete):** add browsing, generation, regeneration, and source navigation for weekly reflections without replacing daily reflections.
9. **Voice entry foundation (complete):** add versioned local attachment metadata and lifecycle rules for voice entries, including safe file placement, deletion, migration, and repository-safety tests.
10. **Voice capture, playback, and transcription (complete):** add permission-aware recording, playback, and on-device transcription where supported, with clear failure and privacy states on iPhone, iPad, and Mac.
11. **Export and recovery (complete):** add user-initiated Markdown and PDF export plus an explicit local recovery workflow; exports never enter Git or silently leave the selected destination.
12. **App privacy lock (complete):** add optional Face ID or Touch ID protection, app-switcher privacy shielding, and careful fallback and accessibility behavior.
13. **Populated-state correctness and clarity (complete):** fix defects and misleading presentation exposed by realistic local data, including current-day Timeline access, calendar labels, contrast, and controls that imply unsupported filtering.
14. **Populated-state density and responsive layout (complete):** keep capture, memory resurfacing, Timeline entries, Highlights, and reflection content useful when the journal contains realistic amounts of writing; give Mac purpose-built wide layouts instead of stretched mobile compositions.
15. **Carry Forward (complete):** let the user intentionally carry one meaningful reflection question, key moment, or thought into the next day without creating a streak, task manager, or engagement pressure.
    - **Foundation (complete):** versioned local model, explicit provenance, one-item-per-day persistence, migration coverage, and repository behavior.
    - **Interaction (complete):** reflection and source-entry actions, next-day Today presentation, visible success feedback, and release/replace behavior on iPhone and Mac.
    - **Portability (complete):** include carried thoughts in explicit local recovery archives and human-readable exports without adding any automatic sharing, while retaining compatibility with older recovery archives.
16. **Journaling and reflection UX optimization (complete):** review the complete capture → revisit → reflect → carry-forward loop on iPhone and Mac, reduce unnecessary navigation and scrolling, and prioritize the writing and memories that help the user make sense of their life.
    - **Capture-first Today (complete):** keep newly written entries next to the composer on compact layouts, present the newest writing first, and make saving an important thought a one-tap action.
    - **Reachable reflection actions (complete):** keep organization, regeneration, and carry-forward controls available without forcing long scrolls through source material.
    - **Populated cross-platform closeout (complete):** exercised capture, highlighting, Timeline, daily and weekly reflection, and Carry Forward against fictional populated journals on iPhone and Mac. Full platform test suites and tracked-history safety scanning pass; capture remains adjacent to current writing and reflection actions remain reachable outside long scrolling content.
17. **Phase closeout (complete):** validated daily and weekly value loops, privacy boundaries, cross-platform behavior, migration safety, exports, full builds and tests, and reachable Git history.

## Phase 9 deliverables

Every deliverable uses its own short-lived branch and pull request. Raw text, transcripts, recordings, refined writing, and provider credentials remain private runtime data and must never enter Git, fixtures, screenshots, or diagnostic logs.

1. **Entry refinement foundation (complete):** formally model an entry's immutable original capture, optional refined text, processing status, refinement provenance, and preferred reading text. Persist the new metadata through a versioned migration while keeping existing entries readable.
2. **Unified capture pipeline (complete):** route text and voice through one testable workflow that saves the original locally first, performs refinement second, and never loses a thought when transcription or refinement fails.
3. **Private provider configuration (complete):** add an explicit off/on choice, conservative cleanup instructions, cancellation and failure handling, and a provider boundary that supports on-device processing or a user-authorized remote provider without embedding credentials.
4. **Automatic cleanup experience (complete):** show Captured, Refining, Saved, Needs Review, and Retry states without blocking the next entry; allow automatic acceptance or review according to the user's setting.
5. **Refined-text presentation (complete):** use the preferred reading text consistently across Today, Timeline, Day Reflection, Highlights, search, and exports while keeping the original capture one action away.
6. **Important-at-capture workflow (complete):** allow a text or voice entry to be highlighted as it is captured, give highlighted entries a consistent visual signal, and keep the dedicated Highlights collection fast to scan.
7. **Hub-ready event boundary (complete):** define versioned, serialization-safe entry and highlight events with explicit redaction so journal text is excluded unless a future Hub permission grants it.
8. **Real-use closeout (complete):** validated rapid text and voice capture, offline and failed refinement, review and undo, highlighting, export, accessibility, and fictional populated-state layouts on iPhone and Mac. Full platform test suites and tracked-history safety scanning pass; visual inspection also caught and corrected model prompt delimiters in new and previously persisted refined text.

## Phase 10 deliverables

Every deliverable uses its own short-lived branch and pull request. Theme changes are presentation-only: they must not alter, derive artwork from, log, export, or otherwise expose private journal content. Existing visual-world preferences migrate without touching SwiftData.

1. **Approved direction and migration plan (complete):** preserve the four approved concept boards, document the shared urban Christian design principles, and define how legacy visual-world identifiers will resolve to the replacement themes without touching journal storage.
2. **Cornerstone Signal default world (complete):** replace Teal Immersion with the primary warm-newsprint, carbon, teal, vermilion, and gold editorial system; add original iPhone and Mac artwork; and validate Today, Timeline, Day Reflection, Highlights, Life Calendar, entry editing, and Settings.
3. **Kingdom Green world (complete):** replace Sodium Fog with the emerald, ivory, and near-black quiet-strength system; use journaling, worship, reflection, and growth imagery; and avoid oversized slogan typography in the product UI.
4. **Gold Standard world (complete):** replace Crimson Static with the mustard-gold, charcoal, and cream worship-notes system; apply the palette to substantial surfaces rather than edge accents; and keep long-form writing calm and readable.
5. **Covenant Blue world (complete):** replace Electric Blue Hour with the cobalt, midnight, and warm-white clarity system; use journaling, worship-stage, scripture, studio, and architectural imagery without reverting to a generic city background.
6. **Screen-specific theme architecture (complete):** give Today, Timeline, Day Reflection, Highlights, Life Calendar, and focused utility screens explicit visual roles; replace the shared top tab strip with concept-faithful brand and bottom navigation; and expose reusable layout, typography, surface, and artwork contracts without changing journal data.
7. **Cornerstone Signal screen system (complete):** create distinct iPhone and Mac artwork for each primary screen and rebuild its headers, capture controls, date rail, reflection presentation, saved-writing cards, calendar, and responsive surfaces to match the approved concept.
8. **Kingdom Green screen system (complete):** create distinct iPhone and Mac artwork for each primary screen and apply the emerald, ivory, near-black, and antique-gold component treatment throughout the complete product flow.
9. **Gold Standard screen system (complete):** create distinct iPhone and Mac artwork for each primary screen and apply the bold mustard-gold, charcoal, and cream hierarchy throughout the complete product flow.
10. **Covenant Blue screen system (complete):** create distinct iPhone and Mac artwork for each primary screen and apply the cobalt, midnight, warm-white, and pale-silver hierarchy throughout the complete product flow.
11. **Cross-platform closeout (complete):** exercised all four complete screen systems with deterministic fictional populated data on supported iPhone and Mac layouts; corrected dense-state contrast, Highlights card separation, Life Calendar hierarchy, and Dynamic Type behavior; verified legacy selection migration, reduced-transparency fallbacks, repository safety, full builds, and tests; and refreshed the final design and safety documentation.

## Phase 11 deliverables

Every deliverable uses a short-lived enterprise-named branch, is built and visually inspected with private in-memory fictional data, and is merged before the next begins. This phase changes the compact iPhone composition only; Mac-specific layout work remains in Phase 12.

1. **Compact editorial shell (complete):** replace oversized iPhone chrome with the concept's compact wordmark, search/menu actions, slim navigation, safe content insets, and reusable editorial sizing while preserving the existing Mac shell.
2. **Today dashboard (complete):** compose a bounded hero, compact capture control, honest quick actions, Important preview, and dense Recent Entries list that prioritizes writing over decoration.
3. **Timeline journal rail (complete):** compact the date ribbon, move search behind the header action, place independent entry cards on a continuous chronology rail, and expose capture without hiding populated content.
4. **Day Reflection reader (complete):** remove duplicate hierarchy, create the calm editorial reading canvas, keep source provenance visible, and retain reachable organize, regenerate, and carry-forward actions.
5. **Highlights gallery (complete):** add the compact filter rhythm, dense saved-entry cards, honest type imagery, metadata, source navigation, and theme-specific light/dark surface alternation.
6. **Life Calendar (complete):** fit the month and truthful writing-rhythm summary into a useful viewport, improve day markers and selection, and prepare the presentation boundary for later optional mood tracking without inventing mood data.
7. **Theme fidelity passes (complete):** tune Cornerstone Signal, Gold Standard, Kingdom Green, and Covenant Blue independently so each changes meaningful surfaces, artwork placement, contrast, and card rhythm rather than acting as a palette swap.
8. **iPhone populated-state closeout (complete):** exercise all tabs and themes with deterministic fictional data, Dynamic Type, VoiceOver semantics, reduced motion/transparency fallbacks, empty/error states, and dense writing; run full iPhone builds, tests, Mac regression build, and complete repository-safety checks before Phase 12.

## Near-term improvements

- Search and calendar browsing
- Optional broad writing prompts
- Passage-level highlights
- Photos and video attachments
- Voice notes, playback, and transcription
- People, places, and custom tags
- Editable organized journals
- Intentional Carry Forward from reflections
- Export to Markdown and PDF
- iCloud synchronization
- Face ID or Touch ID app locking
- Private synchronization design and optional iCloud synchronization

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
