# Development Safety

Echo separates public source code from private runtime data. The Git repository contains implementation, documentation, and reviewed synthetic assets only. It is never a storage or backup location for a person's journal.

## Non-negotiable repository rules

- Never commit real entries, organized journals, search queries, tags, names, locations, dates tied to real events, or copied production databases.
- Never commit exports, backups, recordings, personal photos or videos, crash reports containing entry text, or screenshots of real journal content.
- Tests, previews, screenshots, documentation, and demos use clearly fictional data created for that purpose.
- Runtime storage paths are derived from the application sandbox, never the repository, current working directory, source bundle, or a developer-controlled relative path.
- Tests use in-memory stores or disposable directories created by the test process. They never copy the developer's production container.

## Credentials and API keys

Long-lived provider credentials must not ship inside an Apple app. Values embedded through source, plist files, asset files, build settings, environment substitutions, or obfuscated constants can be extracted from the distributed application.

Allowed future approaches are:

1. A user supplies their own provider credential and Echo stores it in Keychain, never `UserDefaults`, SwiftData, logs, or Git.
2. Echo calls an authenticated service owned by the developer, and that service holds the provider credential outside the client application.
3. Echo uses an on-device capability that requires no remote secret.

Local development configuration such as `Secrets.xcconfig`, `.env`, service-account files, and signing keys is ignored and rejected by the repository scanner. A secret that has ever been committed must be revoked or rotated; deleting the latest copy is insufficient.

## Journal storage

Phase 2 must place SwiftData or other journal stores inside the system-provided application container, normally under Application Support. Attachments and exports require similarly explicit destinations. No production code may accept the repository root as a default persistence location.

The Phase 2 acceptance tests must prove that:

- the production store URL comes from an application-container directory
- tests default to an in-memory or disposable store
- database and sidecar files are not created beneath the source checkout
- deleting test stores cannot target a broad or unresolved path

## Repository checks

The safety script rejects known credential formats, generic credential assignments, database files, private-data directories, signing material, and media outside the reviewed public asset catalog.

Run the staged snapshot check:

```sh
./scripts/check-repository-safety.sh
```

Audit all reachable commits before making or keeping the repository public:

```sh
./scripts/check-repository-safety.sh --history
```

The committed pre-commit hook runs the staged check. Activate it once per clone:

```sh
git config core.hooksPath .githooks
```

GitHub Actions repeats the full-history check for pushes and pull requests. These checks reduce risk but do not replace reviewing staged changes before every commit.

## Public demos and bug reports

Demo mode should use deterministic fictional fixtures stored separately from production persistence. Public screenshots should be reviewed for visible content and embedded metadata. Bug reports should reproduce behavior with the smallest fictional example and omit production containers entirely.

## Incident response

If private data reaches Git history:

1. Keep the repository private or make it private immediately.
2. Revoke any exposed credentials.
3. Identify every affected revision and clone.
4. Rewrite reachable history using an appropriate Git-history tool.
5. Force-update the remote only after review and coordinate with anyone who cloned it.
6. Treat previously published personal data as disclosed; history rewriting cannot recall existing copies.
