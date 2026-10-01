# Visual design

Status: Phase 7 approved direction, October 1, 2026

## Product intent

Echo should feel like an adult independent magazine or album campaign expressed as a private, highly usable journal. It should be enjoyable enough to invite frequent capture without making personal writing compete with decorative interface chrome.

The visual system follows the same discipline as Ambition while preserving an independent identity: cinematic artwork carries atmosphere; controls remain quiet, native, and legible; a small number of semantic accents communicate state. Echo does not copy Ambition artwork, theme names, or feature presentation.

## Approved direction

The approved direction grows from Mirror City. Its signature is a nocturnal city reflected or inverted across water, glass, rain, or fog. Teal Immersion is the default visual world: layered petroleum teal, oxidized blue-green, luminous aqua, restrained graphite, and sparse warm city light.

The initial optional worlds are:

- **Crimson Static:** oxblood, black cherry, ember red, and silver city rain.
- **Sodium Fog:** concrete, olive-gray fog, sodium amber, and a restrained red signal.
- **Electric Blue Hour:** storm blue, peacock teal, cyan reflection, and warm window light.

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

### Teal Immersion production treatment

- The production artwork is `TealImmersionBackground.imageset/teal-immersion-background.png`, an original generated fictional city with no people, text, logos, personal media, or embedded location details.
- Phone presentation uses a portrait `scaledToFill` crop anchored to the top. The luminous skyline occupies the upper third while the quieter petroleum-teal center and lower region support capture, entries, and long-form writing.
- Wider iPad and Mac windows retain the top focal anchor and allow the outer city edges to crop. Semantic surface fills and the world overlay protect readability where the background becomes more detailed.
- The asset-generation prompt and provenance are recorded in `ARTWORK_PROVENANCE.md` so future variants can be reviewed against the same privacy and originality boundary.

## Accessibility and platform rules

- Text contrast is validated against the rendered artwork, not only against palette swatches.
- Content shadow and material strength may adapt to legibility settings without changing the selected world.
- Dynamic Type may reduce decorative artwork exposure to preserve content and actions.
- VoiceOver order follows product hierarchy rather than visual layering.
- Reduce Motion and reduced transparency receive intentional alternatives.
- iPad and Mac use adapted composition and readable line lengths instead of stretching the iPhone canvas.

## Acceptance boundary

Phase 7 is complete only when all current workflows remain functional in every shipped world, selection persists without touching journal storage, supported platforms remain readable and accessible, and repository-safety checks confirm that no personal content or credentials were introduced with the artwork.
