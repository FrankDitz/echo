# Roadmap

Each phase is implemented, built, tested where behavior exists, reviewed, committed, and reported before the next begins.

## MVP phases

- **Phase 0 — Foundation (complete):** shared iPhone/Mac SwiftUI project, app shell, public-repository privacy safeguards, and core documentation.
- **Phase 1 — Journal domain (complete):** entry and day models, extensible source and type values, independent highlight relationships, async repository contracts, calendar-aware grouping, deterministic ordering, and fictional-data tests.
- **Phase 2 — Local persistence:** SwiftData adapters and repository implementation with durable create, read, update, and delete behavior. Production stores must use the application container; tests must use in-memory or disposable stores and prove no data is written beneath the source checkout.
- **Phase 3 — Today:** fast text capture, today's chronological entries, editing, deletion, and empty state.
- **Phase 4 — Timeline:** previous-day summaries, Day Detail, and date navigation.
- **Phase 5 — Highlights:** highlight and unhighlight entries, browse the curated collection, and navigate to source context.
- **Phase 6 — AI architecture:** provider-neutral protocol, deterministic local mock, cleanup, polish, day organization, organized-journal model, and immutability tests. No provider credential or real journal content may enter the app bundle, fixtures, logs, or Git.
- **Phase 7 — MVP review:** full builds and tests, architecture and privacy review, naming cleanup, documentation refresh, staged-data scan, and full reachable-history scan.

## Near-term improvements

- Search and calendar browsing
- Optional broad writing prompts
- Passage-level highlights
- Photos and video attachments
- Voice notes, playback, and transcription
- People, places, and custom tags
- Editable and regeneratable organized journals
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
