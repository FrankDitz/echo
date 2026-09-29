# Echo

Echo is a private, low-friction journal and life archive for iPhone and Mac. It is designed to feel like a quiet conversation with yourself: write once at the end of a day, capture several small moments, or simply leave the day alone.

> **Status:** Phase 0 — foundation complete. The app currently contains a native navigation shell only. Journal data, persistence, highlights, and AI assistance intentionally begin in later phases.

## Foundation

- One native SwiftUI target shared by iPhone, iPad, and Mac
- Native `TabView` navigation for Today, Timeline, and Highlights
- Settings kept outside the primary navigation
- No accounts, network services, analytics, or third-party dependencies
- No journal content is stored or transmitted in this phase
- Repository safety checks that reject common credentials and private runtime data

The shared target keeps the product and domain code consistent across Apple platforms. Platform-specific behavior will be isolated only when the platforms genuinely differ.

## Public source, private journal

Echo's implementation is public for learning and portfolio review. Personal journal data is not part of the project and must never enter Git.

Future persistence will use the application sandbox. Tests, previews, screenshots, and demos must use fictional data; development builds must never copy a personal application container into this checkout. Long-lived service credentials will not be embedded in the application. User-provided credentials, if supported later, belong in Keychain.

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

Phase 0 has no behavior to test, so it deliberately does not include placeholder UI tests. A unit-test target and meaningful domain tests are introduced with the journal domain in Phase 1. Once present, run them with:

```sh
xcodebuild \
  -project Echo.xcodeproj \
  -scheme Echo \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/EchoDerivedData-tests \
  test
```

## Architecture

The source tree grows by responsibility:

```text
Echo/
  App/          App lifecycle and dependency composition
  Features/     SwiftUI presentation grouped by user-facing feature
  Domain/       Platform-independent models and use cases (Phase 1)
  Data/         Persistence adapters and repository implementations (Phase 2)
  Services/     Replaceable external capabilities, including AI (Phase 6)
  Hub/          Future Hub boundary; no Hub implementation in the MVP
  Shared/       Focused UI utilities and resources
```

See [Architecture](docs/ARCHITECTURE.md) for dependency rules and decisions.

## Documentation

- [Product specification](docs/PRODUCT_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Future Hub integration](docs/HUB_INTEGRATION.md)
- [Privacy](docs/PRIVACY.md)
- [Development safety](docs/DEVELOPMENT_SAFETY.md)
- [Security reporting](SECURITY.md)
