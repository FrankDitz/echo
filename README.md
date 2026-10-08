# Echo

Echo is a private, low-friction journal and life archive for iPhone and Mac. It is designed to feel like a quiet conversation with yourself: write once at the end of a day, capture several small moments, or simply leave the day alone.

> **Status:** Phase 7 — the functional MVP and approved Mirror City presentation system are complete. Echo supports local writing, historical browsing, highlights, deterministic assisted drafts, organized daily journals, four selectable visual worlds, and responsive iPhone, iPad, and Mac presentation without contacting an external AI provider.

## Foundation

- One native SwiftUI target shared by iPhone, iPad, and Mac
- Custom editorial navigation for Today, Timeline, Day Reflection, and Highlights
- Settings kept outside the primary navigation
- No accounts, network services, analytics, or third-party dependencies
- Local-only SwiftData persistence with CloudKit explicitly disabled
- Repository safety checks that reject common credentials and private runtime data
- Platform-independent entry, day, highlight, ordering, and repository contracts
- SwiftData repository adapters with durable entry and highlight CRUD
- A native Today experience with quick capture, calm empty and loading states, and chronological entries
- A distraction-free entry editor with explicit save feedback and unsaved-change protection
- Confirmed entry deletion through compact action and context menus
- A newest-first Timeline with previous-day entry counts and previews
- Readable Day Detail screens with complete chronological entries
- Persisted whole-entry highlights available from Today and Day Detail
- A newest-highlighted-first collection with navigation back to the source day and entry
- Offline deterministic cleanup and polish drafts that never replace raw writing
- Persisted organized daily journals with complete source-entry provenance
- Cornerstone Signal, Gold Standard, Kingdom Green, and Electric Blue Hour visual worlds
- Responsive wide-window journal and reflection workspaces on Mac
- Reduce Motion, Reduce Transparency, Dynamic Type, keyboard, and VoiceOver-aware presentation
- Fictional-data domain and persistence tests using Swift Testing

The shared target keeps the product and domain code consistent across Apple platforms. Platform-specific behavior will be isolated only when the platforms genuinely differ.

## Public source, private journal

Echo's implementation is public for learning and portfolio review. Personal journal data is not part of the project and must never enter Git.

Production persistence uses the application sandbox. Tests, previews, screenshots, and demos must use fictional data; development builds must never copy a personal application container into this checkout. Long-lived service credentials will not be embedded in the application. User-provided credentials, if supported later, belong in Keychain.

Before committing, activate the repository hook once per clone and run the full audit when appropriate:

```sh
git config core.hooksPath .githooks
./scripts/check-repository-safety.sh
./scripts/check-repository-safety.sh --history
```

The same history audit runs on GitHub for every push and pull request. See [Development Safety](docs/DEVELOPMENT_SAFETY.md) and [Security](SECURITY.md) before adding persistence, media, AI, fixtures, screenshots, or diagnostic logging.

## Requirements

- Xcode 26 or newer
- iOS 18 or newer
- macOS 15 or newer

The project was founded with Xcode 26.6 and Swift 6.3.3. It uses Swift 6 language mode.

## Open and run

1. Open `Echo.xcodeproj` in Xcode.
2. Select the shared `Echo` scheme.
3. Choose an iPhone simulator or **My Mac**.
4. Run with **Product > Run**.

Command-line builds use isolated derived-data directories:

```sh
xcodebuild \
  -project Echo.xcodeproj \
  -scheme Echo \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/EchoDerivedData-iOS \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project Echo.xcodeproj \
  -scheme Echo \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/EchoDerivedData-macOS \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Tests

The `EchoTests` target covers domain invariants, repository CRUD, persistence across container recreation, and storage-location safety rather than SwiftUI rendering. Run it with:

```sh
xcodebuild \
  -project Echo.xcodeproj \
  -scheme Echo \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/EchoDerivedData-tests \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Architecture

The source tree grows by responsibility:

```text
Echo/
  App/          App lifecycle and dependency composition
  Features/     SwiftUI presentation grouped by user-facing feature
  Domain/       Platform-independent models and repository contracts
  Data/         SwiftData persistence adapters and repository implementations
  Services/     Replaceable external capabilities, including the local AI stand-in
  Hub/          Future Hub boundary; no Hub implementation in the MVP
  Shared/       Focused UI utilities and resources
```

See [Architecture](docs/ARCHITECTURE.md) for dependency rules and decisions.

## Documentation

- [Product specification](docs/PRODUCT_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Visual design](docs/VISUAL_DESIGN.md)
- [Roadmap](docs/ROADMAP.md)
- [Future Hub integration](docs/HUB_INTEGRATION.md)
- [Privacy](docs/PRIVACY.md)
- [Development safety](docs/DEVELOPMENT_SAFETY.md)
- [Security reporting](SECURITY.md)
