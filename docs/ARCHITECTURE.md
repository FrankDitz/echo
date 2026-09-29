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
    Today/             Planned Today presentation
    Timeline/          Planned timeline presentation
    Highlights/        Planned highlights presentation
    EntryEditor/       Planned entry editor presentation
    DayDetail/         Planned day-detail presentation
  Domain/
    Models/            Planned value types and entities
    Services/          Planned application use-case contracts
    Repositories/      Planned persistence contracts
  Data/
    Persistence/       Planned SwiftData models and mapping
    Repositories/      Planned repository implementations
  Services/
    AI/                Planned provider-neutral AI boundary
  Hub/                 Future integration contracts only
  Shared/              Focused reusable UI and resources
```

Only directories with real Phase 0 files exist today. Future directories are created when their first implementation arrives, avoiding empty abstractions and placeholder production types.

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

Phase 1 defines stable UUIDs, explicit timestamps, calendar-day semantics, source, entry type, and highlight behavior in serialization-friendly domain models. Phase 2 maps those models to SwiftData behind repository interfaces. SwiftData types do not flow through SwiftUI as the application's only model.

Calendar grouping must use an injected or explicit `Calendar` so day boundaries remain testable and correct for the user's locale and time zone.

Production persistence is confined to the system-provided application container. No repository or service may default to a relative path, the current working directory, the source checkout, or the application bundle. Tests use in-memory stores or unique disposable directories and never read from a personal application container.

## AI boundary

Phase 6 introduces a provider-neutral service for cleanup, polish, and day organization. Every operation returns a separate result. Raw entry text is never mutated by AI output. The first adapter is local and deterministic; provider credentials and network calls remain absent.

A future distributed build must not contain an app-owned provider secret: build settings and obfuscation do not make bundled values private. A user-provided credential may be stored in Keychain, or an authenticated service may keep its own provider credential outside the client. UI and domain code continue to depend only on the provider-neutral service contract.

## State and concurrency

Feature state will be owned by focused observable presentation types when behavior warrants it. Long-running or external work will use structured Swift concurrency. No important application state should be trapped in a view hierarchy.

## Testing strategy

Tests begin with Phase 1, when meaningful domain behavior exists. They prioritize creation and editing invariants, day grouping, ordering, highlighting, repository behavior, and proof that assisted text never replaces originals. UI snapshot or rendering tests are not part of the initial strategy.

All fixtures are fictional. Persistence tests use in-memory or disposable stores and include an invariant that no database is created beneath the repository checkout. Repository safety checks scan staged files and reachable history for private-data paths and credential patterns.

## Significant decisions

### One multiplatform target

Shared product behavior outweighs the small amount of platform variation. One target reduces drift while still producing native binaries for iOS and macOS.

### No persistence in Phase 0

Adding SwiftData before defining domain semantics would let a storage framework shape the model prematurely. Persistence follows the tested domain contract in Phase 2.

### No empty test suite

Phase 0 contains only static navigation. The project does not add a test that proves a SwiftUI placeholder renders; the first test target arrives alongside meaningful domain rules in Phase 1.

### Generated Info.plist

Xcode generates platform Info.plists from build settings. This avoids maintaining duplicate iOS and macOS plist files while the application has no custom usage descriptions or document types.

### Public source and private runtime data

The repository is suitable for public review, but it is not a data store. Journal databases, exports, backups, media, logs containing content, signing material, and credentials are prohibited from Git. This is enforced through ignore rules, a pre-commit scanner, CI, synthetic fixture requirements, and application-container persistence.
