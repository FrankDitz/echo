# Phase 10 approved theme concepts

These boards are the approved visual references for Echo's Phase 10 urban Christian redesign:

- `cornerstone-signal.png` — the primary editorial world and default replacement for Teal Immersion
- `kingdom-green.png` — the quiet-strength replacement for Sodium Fog
- `gold-standard.png` — the worship-notes replacement for Crimson Static
- `covenant-blue.png` — the clarity-focused replacement for Electric Blue Hour

The boards are design references, not production application assets. Their systems must be recreated with native SwiftUI components and original platform-specific artwork rather than displaying these composite images inside Echo.

| Retired world | Phase 10 replacement |
| --- | --- |
| Teal Immersion | Cornerstone Signal |
| Sodium Fog | Kingdom Green |
| Crimson Static | Gold Standard |
| Electric Blue Hour | Covenant Blue |

Previously persisted raw identifiers remain recognized during migration so an upgrade never changes journal storage or fails to resolve the user's appearance preference.

## Shared direction

- modern urban Christian rather than generic church software
- confident editorial typography with calm long-form reading
- meaningful color across complete surfaces, not accent-only recoloring
- imagery rooted in journaling, prayer, worship, reflection, discipline, and personal growth
- restrained crown, cross, scripture, notebook, and sound motifs
- no people, faces, personal journal content, third-party marks, or identifying locations
- no botanical theme, childish sticker language, rainbow palette, or oversized slogan typography in routine product screens

## Privacy and implementation boundary

Only fictional generated artwork may ship with the application. Runtime journal text, recordings, transcripts, exports, and user media may never be used to construct a theme or enter Git. Existing visual-world preference values are presentation settings only and migrate independently of SwiftData journal storage.
