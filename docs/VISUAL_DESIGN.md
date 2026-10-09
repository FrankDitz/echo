# Visual design

Status: Phase 10 screen-specific implementation in progress, October 8, 2026

## Product intent

Echo should feel like an adult independent magazine or album campaign expressed as a private, highly usable journal. It should be enjoyable enough to invite frequent capture without making personal writing compete with decorative interface chrome.

The visual system follows the same discipline as Ambition while preserving an independent identity: cinematic artwork carries atmosphere; controls remain quiet, native, and legible; a small number of semantic accents communicate state. Echo does not copy Ambition artwork, theme names, or feature presentation.

## Approved direction

The approved direction is modern urban Christian: tactile editorial imagery, confident environmental color, worship and studio spaces, journaling objects, architectural light, and restrained faith symbols. It should feel fresh and personal without becoming a church flyer, a generic productivity dashboard, or a collection of slogan cards.

The shipped worlds are:

- **Cornerstone Signal (default):** warm newsprint, carbon, petrol teal, vermilion, and gold; an editorial street-and-studio collage centered on reflection and rebuilding.
- **Kingdom Green:** saturated emerald, near-black, warm ivory, and antique gold; a quiet-strength worship and journaling environment without oversized slogans.
- **Gold Standard:** mustard gold, charcoal, and warm cream; bold worship-notes imagery with color filling the environment rather than appearing as a thin accent.
- **Covenant Blue:** covenant cobalt, midnight navy, warm white, and pale silver; a clear worship, studio, journal, and concrete-church environment without a generic city backdrop.

These are presentation choices, not product modes. Every world exposes the same content, navigation, actions, accessibility semantics, and privacy behavior.

## Design principles

- **Artwork carries attitude.** Edge comes from composition, light, photography or illustration, and controlled contrast—not distressed display type, ornamental borders, or a gaming HUD.
- **Writing stays primary.** Background detail yields to calm reading areas. Dense text receives a localized shadow or material treatment rather than an opaque screen-wide panel.
- **Color is environmental.** The selected world may fill most of the canvas. Accent color is reserved for selection, capture, generation, and saved state.
- **Hierarchy stays familiar.** Natural casing, readable typography, native interaction patterns, and predictable navigation make the cinematic presentation usable every day.
- **Original and generated writing remain distinct.** Day Reflection identifies its generated narrative, themes, and original source entries without implying that raw text was replaced.
- **Motion has meaning.** Transitions may reinforce reflection, time, capture, or selection. They must remain subtle and provide a stable Reduce Motion alternative.
- **No ornamental component soup.** Avoid repeated glass cards, glowing outlines around every row, giant microphone orbs, novelty typography, and city thumbnails attached to every entry.

## Screen responsibilities

### Today

- Make text or voice capture the obvious primary action.
- Keep raw entries visible and chronological.
- Use the visual world most strongly here while retaining a calm input and reading region.

### Timeline

- Make date navigation and chronological structure immediately understandable.
- Allow the world to recede behind longer lists.
- Preserve stable entry identity and navigation into the full day.

### Day Detail and Day Reflection

- Keep raw entries available even when an organized journal exists.
- Present the generated narrative as editorial prose with visible themes and source provenance.
- Make organize and regenerate actions explicit without suggesting destructive replacement.

### Highlights

- Prioritize saved writing over decorative imagery.
- Support filtering and source navigation with an obvious saved-state treatment.

### Entry Editor

- Offer the quietest presentation in the app.
- Protect writing focus, keyboard behavior, save state, and error communication from background competition.

## Visual-world contract

A visual world will eventually provide semantic values rather than feature-specific styling:

- stable identifier and display name
- portrait background artwork and crop/focal guidance
- canvas, primary text, secondary text, accent, separator, and status colors
- content-shadow or material treatment and strength
- control fill, selected state, and saved state
- optional motion parameters with a Reduce Motion alternative

Feature screens consume semantic values. They must not switch on individual world identifiers to change behavior or data flow.

## Artwork requirements

- Production backgrounds are standalone portrait assets without application controls or journal text baked into them.
- Artwork reserves calm regions for navigation, capture, entries, and long-form reflection across supported device crops.
- Variants use fictional, non-identifying source material and contain no faces, personal media, location metadata, signatures, watermarks, or third-party marks.
- Assets are reviewed at the smallest and largest supported phone sizes before shipping.
- Theme assets may be public repository content; personal runtime photos and journal-derived imagery may never become theme assets.

### Cornerstone Signal production treatment

- Cornerstone uses five scene-specific artwork sets rather than repeating one wallpaper: `CornerstoneSignalBackground` for Today, plus `CornerstoneSignalTimelineBackground`, `CornerstoneSignalReflectionBackground`, `CornerstoneSignalHighlightsBackground`, and `CornerstoneSignalCalendarBackground`. Each contains an independently composed phone portrait and native 16:10 Mac image.
- The scenes reinforce each screen's job: Today centers journaling, Timeline supplies an architectural journey rail, Reflection reserves a cross-lit editorial field, Highlights frames saved thoughts with worship and journal fragments, and Calendar integrates a restrained month-grid texture. None contains people, readable text, logos, personal media, or embedded location details.
- Warm newsprint reading fields occupy the central content regions while carbon, petrol teal, vermilion, gold, and photographic detail build structure at the edges.
- Primary text uses carbon, vermilion communicates action, petrol teal distinguishes saved state, and warm cream surfaces protect long-form readability. Cornerstone Signal intentionally uses a light system appearance.
- Screen-specific artwork and shared concept-faithful components establish the default visual language; optional worlds retain the same screen jobs, behavior, accessibility semantics, and privacy boundary.

### Gold Standard production treatment

- Gold Standard uses five screen-specific artwork sets: `GoldStandardBackground` for Today, plus `GoldStandardTimelineBackground`, `GoldStandardReflectionBackground`, `GoldStandardHighlightsBackground`, and `GoldStandardCalendarBackground`. Every set provides a separately composed phone portrait and native 16:10 Mac image.
- Timeline uses a charcoal journey rail over saturated gold; Reflection opens a cream writing field beside cross-shaped light; Highlights frames saved writing with worship-stage and notebook imagery; Calendar uses a disciplined black-and-gold month grid.
- A blank journal, studio headphones, unbranded closed Bible, worship stage, and concrete steps stay near the outer edges. A broad mustard-gold field supports journal controls and reading surfaces.
- Primary text uses near-black charcoal, secondary text uses warm umber, and charcoal is the principal action accent against gold. Deep green distinguishes saved state while oxblood remains reserved for errors.
- Gold fills the environment and selected surfaces rather than appearing only as an outline. Warm cream panels preserve long-form readability without making the world feel like a generic white theme.

### Kingdom Green production treatment

- Kingdom Green uses five scene-specific artwork sets: `KingdomGreenBackground` for Today, plus `KingdomGreenTimelineBackground`, `KingdomGreenReflectionBackground`, `KingdomGreenHighlightsBackground`, and `KingdomGreenCalendarBackground`. Every set provides a separately composed phone portrait and native 16:10 Mac image.
- Timeline uses an ivory journey rail and architectural ascent; Reflection uses a warm cross-lit sanctuary field; Highlights surrounds saved writing with studio, worship, stair, and journal fragments; Calendar integrates a restrained gold month grid and symbolic geometry.
- A blank journal, unbranded closed Bible, empty worship stage, ascending steps, and warm architectural light stay concentrated at the outer edges. A calmer emerald center supports journal controls and reading surfaces.
- Primary text uses warm ivory, secondary text uses muted sage, and antique gold is reserved for selection and action. Mint distinguishes saved state while coral remains reserved for errors.
- The world avoids oversized slogans and generic city scenery. Its quiet-strength character comes from saturated emerald surfaces, near-black structure, worship-space depth, and disciplined gold detail.

### Covenant Blue production treatment

- `CovenantBlueBackground.imageset` contains separate portrait and native 16:10 Mac compositions. Both use original generated journaling, worship-stage, studio, and concrete-church imagery with no people, plants, readable text, logos, personal media, or embedded location details.
- A blank journal, unbranded closed Bible, studio microphone, stage, stairs, and cross-shaped architectural light stay near the outer edges. Broad cobalt and midnight fields support journal controls and reading surfaces.
- Primary text uses warm near-white, secondary text uses pale silver-blue, and clear cobalt is reserved for selection and action. Mint distinguishes saved state while coral remains reserved for errors.
- The world avoids waterfront skylines and generic cyberpunk light. Its visual identity comes from worship-space depth, disciplined blue fields, studio objects, and warm architectural light.

## Accessibility and platform rules

- Text contrast is validated against the rendered artwork, not only against palette swatches.
- Content shadow and material strength may adapt to legibility settings without changing the selected world.
- Dynamic Type may reduce decorative artwork exposure to preserve content and actions.
- VoiceOver order follows product hierarchy rather than visual layering.
- Reduce Motion and reduced transparency receive intentional alternatives.
- iPad and Mac use adapted composition and readable line lengths instead of stretching the iPhone canvas.

## Acceptance boundary

Phase 10 is complete only when all current workflows remain functional in every shipped world, legacy selections migrate without touching journal storage, supported platforms remain readable and accessible, and repository-safety checks confirm that no personal content or credentials were introduced with the artwork.
