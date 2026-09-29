# Security and Private Data

Echo's source code is public, but journal content is private. Real entries, databases, exports, recordings, photos, videos, credentials, and diagnostic data containing personal information must never be committed or attached to a public issue.

## Reporting a security issue

Use GitHub's private vulnerability reporting for security-sensitive reports. Do not open a public issue containing an exploit, credential, private journal content, database, media attachment, or unredacted log.

For ordinary bugs, use a minimal reproduction with fictional data. Redact names, dates, locations, identifiers, file paths, and entry text from screenshots and logs.

## Credential exposure

If a credential is committed, assume it has been compromised even if the commit is later removed or the repository is made private. Revoke or rotate it first, then remove it from every reachable Git revision before publishing corrected history.

See [Development Safety](docs/DEVELOPMENT_SAFETY.md) for the enforced repository rules and local checks.
