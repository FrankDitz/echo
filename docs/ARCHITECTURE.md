# Architecture

## Goals

Echo uses a small, explicit architecture that keeps personal data, application rules, UI, persistence, and replaceable services separate. The structure should remain easy to follow and test without introducing layers that do no real work.

## Platform setup

Echo uses one SwiftUI application target for iPhone, iPad, and Mac. Today, Timeline, Highlights, and most future domain behavior are the same product on each platform, so separate targets would duplicate files and configuration. Platform-specific presentation or capabilities will live in narrowly scoped files when needed.

Deployment starts at iOS 18 and macOS 15. The app has no third-party dependencies.

## Source layout

```text
Echo/
  App/                 App entry point and composition root
  Features/
    AppShell/          Phase 0 navigation shell
    Today/             Today journal presentation and application state
    Timeline/          Planned timeline presentation
    Highlights/        Planned highlights presentation
    EntryEditor/       Focused long-form entry editing
    DayDetail/         Planned day-detail presentation
  Domain/
    Models/            Entry, calendar day, ordering, and highlight behavior
    Repositories/      Async persistence contracts
  Data/
    Persistence/       Versioned SwiftData records, mapping, and container setup
    Repositories/      SwiftData repository actors
  Services/
    AI/                Planned provider-neutral AI boundary
  Hub/                 Future integration contracts only
  Shared/              Focused reusable UI and resources
```

Only directories with real implementation files exist today. Future directories are created when their first implementation arrives, avoiding empty abstractions and placeholder production types.

## Dependency direction

```text
SwiftUI features -> application/domain contracts <- data and service adapters
                         ^
                    app composition
```

- Domain code does not import SwiftUI, SwiftData, or a concrete AI provider.
- Feature views call application behavior rather than owning persistence rules.
- Data and service implementations conform to contracts defined closer to the domain.
- `App` is the composition root that chooses concrete implementations.
- Hub integration consumes stable, explicit contracts; Echo does not depend on Ambition.

These are boundaries, not a requirement to create one type per layer. A protocol is introduced when there is a real replacement or testing seam.

## Data and identity decisions

Phase 1 defines stable UUIDs, explicit timestamps, calendar-day semantics, source, entry type, and highlight behavior in serialization-friendly domain models. Entry type, source, and highlight-target kind are extensible raw values so newly introduced kinds do not break older decoders. Phase 2 maps these models to a versioned SwiftData schema behind repository interfaces. SwiftData records remain internal to the data layer and never replace the domain models.

Calendar grouping uses an injected `Calendar`. An entry captures its calendar identifier and local era/year/month/day at creation, so later time-zone changes do not silently move it to another day. Day groups and their entries have deterministic chronological ordering with UUID tie-breaking.

Highlights are independent relationships rather than Boolean entry fields. The current target references an entry UUID, while its extensible kind leaves room for organized journals, media, and future passage anchors. A behavior-only collection prevents duplicate highlights for the same target.

Production persistence is confined to the system-provided application container. No repository or service may default to a relative path, the current working directory, the source checkout, or the application bundle. Tests use in-memory stores or unique disposable directories and never read from a personal application container.

The app composition root creates the production `ModelContainer` and installs it in the SwiftUI environment. Its configuration has no app group and explicitly disables CloudKit. Entry and highlight repository actors each receive a container, perform durable CRUD through their isolated `ModelContext`, and translate records through a dedicated mapper. The first schema is versioned so future storage changes have an explicit migration boundary.

## AI boundary

Phase 6 introduces a provider-neutral service for cleanup, polish, and day organization. Every operation returns a separate result. Raw entry text is never mutated by AI output. The first adapter is local and deterministic; provider credentials and network calls remain absent.

A future distributed build must not contain an app-owned provider secret: build settings and obfuscation do not make bundled values private. A user-provided credential may be stored in Keychain, or an authenticated service may keep its own provider credential outside the client. UI and domain code continue to depend only on the provider-neutral service contract.

## State and concurrency

Feature state is owned by focused observable presentation types when behavior warrants it. `TodayViewModel` runs on the main actor, depends on the domain repository contract, and owns loading plus create, edit, and delete workflows. SwiftUI owns only transient presentation state such as drafts, focus, sheets, and confirmation dialogs. Long-running or external work uses structured Swift concurrency.

## Testing strategy

Tests begin with Phase 1, when meaningful domain behavior exists. They cover creation and editing invariants, monotonic timestamps, Codable round-trips, calendar and time-zone boundaries, deterministic ordering, day grouping, highlighting, and proof that assisted text never replaces originals. Phase 2 adds repository CRUD, identity errors, deterministic query ordering, highlight uniqueness, storage-location safety, and a durable-store test that recreates the container before reading. Phase 3 adds deterministic tests for current-day loading, capture validation, editing timestamps, deletion, save state, and persistence failures. UI snapshot or rendering tests are not part of the initial strategy.

All fixtures are fictional. Persistence tests use in-memory or disposable stores and include an invariant that no database is created beneath the repository checkout. Repository safety checks scan staged files and reachable history for private-data paths and credential patterns.

## Significant decisions

### One multiplatform target

Shared product behavior outweighs the small amount of platform variation. One target reduces drift while still producing native binaries for iOS and macOS.

### Persistence follows the domain

SwiftData was added only after the domain semantics were defined and tested. Concrete records and repository actors conform to those contracts, keeping storage concerns from shaping feature code.

### Local-only SwiftData configuration

Phase 2 uses the system application container and explicitly disables CloudKit. Test-only factories provide in-memory and caller-selected disposable stores; production code has no checkout-relative storage option.

### Independent highlights

An entry does not own an `isHighlighted` flag. A separate highlight has its own stable identity, timestamp, and entity target. This keeps entry data focused and supports future highlight targets without rewriting entry persistence.

### No empty test suite

Phase 0 contains only static navigation. The project does not add a test that proves a SwiftUI placeholder renders; the first test target arrives alongside meaningful domain rules in Phase 1.

### Generated Info.plist

Xcode generates platform Info.plists from build settings. This avoids maintaining duplicate iOS and macOS plist files while the application has no custom usage descriptions or document types.

### Public source and private runtime data

The repository is suitable for public review, but it is not a data store. Journal databases, exports, backups, media, logs containing content, signing material, and credentials are prohibited from Git. This is enforced through ignore rules, a pre-commit scanner, CI, synthetic fixture requirements, and application-container persistence.
