# Artwork provenance

Echo's checked-in visual-world artwork must be safe for a public repository. It may not contain personal photos, journal-derived content, identifying metadata, third-party marks, or credentials.

## Teal Immersion background

- **Asset:** `Echo/Shared/Resources/Assets.xcassets/TealImmersionBackground.imageset/teal-immersion-background.png`
- **Created:** October 1, 2026
- **Method:** OpenAI built-in image generation
- **Purpose:** Production portrait background for the Teal Immersion visual world

### Generation prompt

> Use case: stylized-concept
>
> Asset type: production portrait background artwork for a private iPhone journaling app visual world named Teal Immersion
>
> Primary request: an original nocturnal city reflected and subtly inverted across rain-dark glass and water, creating a sophisticated Mirror City composition that feels adult, modern, sleek, cinematic, and quietly tough
>
> Scene/backdrop: dense but distant anonymous city architecture at night, mirrored vertical forms, rain haze, wet glass, abstracted windows and reflections; no recognizable real location
>
> Style/medium: premium cinematic editorial environment art with restrained photographic realism and subtle film grain, suitable behind a polished native Apple app
>
> Composition/framing: tall portrait phone canvas; strong atmospheric city detail around the upper third and outer edges; a broad calm low-detail petroleum-teal reading region through the center and lower-middle; maintain useful negative space near the top for navigation and near the bottom for controls; safe under varied phone crops
>
> Lighting/mood: nocturnal, introspective, self-possessed, masculine without aggression; luminous aqua reflections, deep graphite shadows, sparse warm distant window light
>
> Color palette: petroleum teal, oxidized blue-green, luminous bright aqua, deep graphite, tiny restrained warm amber highlights
>
> Materials/textures: rain-dark glass, wet pavement or water, fine fog, restrained grain; crisp enough for high-resolution display but never busy behind text
>
> Constraints: standalone background art only; original fictional city; no people, faces, vehicles as focal subjects, readable signage, text, logos, trademarks, watermarks, borders, UI controls, journal writing, signatures, or metadata-like overlays; avoid direct imitation of any album cover or existing artwork
>
> Avoid: generic cyberpunk neon overload, gaming HUD, purple-magenta palette, cartoon look, distressed typography, giant glowing objects, high-school edginess, excessive black empty space

### Review notes

The generated asset was reviewed before inclusion. It depicts an anonymous fictional city, contains no readable text or recognizable marks, and is used only as static application artwork. Personal runtime media remains outside the source repository and is never used to derive checked-in themes.

## Teal Immersion Mac background

- **Asset:** `Echo/Shared/Resources/Assets.xcassets/TealImmersionBackground.imageset/teal-immersion-background-mac.png`
- **Created:** October 1, 2026
- **Method:** OpenAI built-in image generation using the approved portrait artwork as a visual-world reference
- **Purpose:** Production landscape background for large macOS windows

### Generation prompt

> Use case: stylized-concept
>
> Asset type: production wide desktop background artwork for the macOS version of a private journaling app visual world named Teal Immersion
>
> Input images: Image 1 is the approved portrait Teal Immersion artwork and a visual-world reference only; create a new native landscape composition rather than stretching, cropping, or merely extending it
>
> Primary request: create a high-detail wide nocturnal Mirror City scene that clearly belongs to the same visual world as Image 1, with an original anonymous skyline reflected across rain-dark water and glass; adult, modern, sleek, cinematic, and quietly tough
>
> Scene/backdrop: a broad fictional waterfront city at night with layered architecture, rain haze, wet glass, fine fog, and long teal reflections; no recognizable real location
>
> Style/medium: premium cinematic editorial environment art with restrained photographic realism and subtle film grain, matching the atmosphere, material treatment, and visual sophistication of Image 1
>
> Composition/framing: native 16:10 landscape desktop composition; skyline and luminous atmosphere concentrated across the upper third and outer edges; preserve a broad calm low-detail petroleum-teal reading region through the center and lower-middle for app content; balance the entire width so common Mac window crops remain intentional; retain visible water reflection without centering one giant tower; no portrait-image stretching
>
> Lighting/mood: nocturnal, introspective, self-possessed, masculine without aggression; luminous aqua reflections, deep graphite shadows, sparse warm distant window light
>
> Color palette: petroleum teal, oxidized blue-green, luminous bright aqua, deep graphite, tiny restrained warm amber highlights; closely match Image 1
>
> Materials/textures: rain-dark glass, wet water, subtle surface ripples, fine fog, restrained grain; crisp and richly detailed at large desktop-window scale but never busy behind text
>
> Constraints: standalone background art only; original fictional city; no people, faces, focal vehicles, readable signage, text, logos, trademarks, watermarks, borders, UI controls, journal writing, signatures, or metadata-like overlays; preserve the approved visual identity without copying any real artwork or location
>
> Avoid: upscaling artifacts, softness, blurry buildings, generic cyberpunk neon overload, gaming HUD, purple-magenta palette, cartoon look, distressed typography, giant glowing objects, high-school edginess, excessive black empty space

### Review notes

The Mac asset was reviewed before inclusion. It retains the approved Teal Immersion identity while using a native landscape composition, and it contains no people, readable text, recognizable marks, personal content, or embedded color profile.

## Crimson Static background

- **Assets:** `Echo/Shared/Resources/Assets.xcassets/CrimsonStaticBackground.imageset/crimson-static-background.png` and `crimson-static-background-mac.png`
- **Created:** October 1, 2026
- **Method:** OpenAI built-in image generation using Teal Immersion only as a visual-system reference, followed by a separate native landscape generation using the approved Crimson Static portrait result
- **Purpose:** Production portrait and landscape backgrounds for the Crimson Static visual world

### Portrait generation prompt

> Use case: stylized-concept
>
> Asset type: production portrait background artwork for a private iPhone journaling app visual world named Crimson Static
>
> Input images: Image 1 is the approved Teal Immersion artwork and a visual-system reference only; create a clearly distinct original Crimson Static scene while matching its mature editorial quality, usable negative space, and restrained realism
>
> Primary request: an original rain-soaked nocturnal city reflected through black glass and dark water, with fragmented ember-red light and pale silver rain creating a sophisticated Mirror City composition; adult, modern, sleek, cinematic, and quietly tough
>
> Scene/backdrop: dense but distant anonymous city architecture at night, angular elevated structures, layered windows obscured by rain haze, mirrored vertical forms in wet glass and water; no recognizable real location
>
> Style/medium: premium cinematic editorial environment art with restrained photographic realism and subtle film grain, suitable behind a polished native Apple app
>
> Composition/framing: tall portrait phone canvas; atmospheric architectural detail and red light concentrated around the upper third and outer edges; a broad calm low-detail black-cherry reading region through the center and lower-middle; useful negative space near the top for navigation and near the bottom for controls; safe under varied phone crops
>
> Lighting/mood: nocturnal, focused, self-possessed, masculine without aggression; controlled oxblood and ember-red reflections, deep graphite and black-cherry shadows, thin silver rain highlights; brooding but not threatening
>
> Color palette: oxblood, black cherry, ember red, charcoal graphite, wet silver, with only tiny restrained neutral-white highlights; absolutely no teal, cyan, purple, or magenta
>
> Materials/textures: rain-dark glass, black water, wet concrete, brushed dark metal, fine fog, restrained grain; crisp enough for high-resolution display but never busy behind text
>
> Constraints: standalone background art only; original fictional city; no people, faces, focal vehicles, readable signage, text, logos, trademarks, watermarks, borders, UI controls, journal writing, signatures, or metadata-like overlays; no direct imitation of any existing album cover or artwork
>
> Avoid: gore, horror imagery, fire, generic cyberpunk neon overload, gaming HUD, purple-magenta lighting, cartoon look, distressed typography, giant glowing objects, high-school edginess, excessive pure-black empty space

### Mac generation prompt

> Use case: stylized-concept
>
> Asset type: production wide desktop background artwork for the macOS version of a private journaling app visual world named Crimson Static
>
> Input images: Image 1 is the approved portrait Crimson Static artwork and a visual-world reference only; create a new native landscape composition rather than stretching, cropping, or merely extending it
>
> Primary request: create a high-detail wide rain-soaked nocturnal Mirror City scene that clearly belongs to the same visual world as Image 1, with a broad original anonymous skyline reflected across black glass and dark water, fragmented ember-red light, and pale silver rain; adult, modern, sleek, cinematic, and quietly tough
>
> Scene/backdrop: broad fictional waterfront city at night with angular elevated structures, layered architecture, silver rain haze, wet glass, black water, and long oxblood reflections; no recognizable real location
>
> Style/medium: premium cinematic editorial environment art with restrained photographic realism and subtle film grain, matching the atmosphere, material treatment, and sophistication of Image 1
>
> Composition/framing: native 16:10 landscape desktop composition; skyline and controlled ember-red atmosphere concentrated across the upper third and outer edges; preserve a broad calm low-detail black-cherry reading region through the center and lower-middle for app content; balance the entire width so common Mac window crops remain intentional; retain visible dark-water reflection without centering one giant tower; no portrait-image stretching
>
> Lighting/mood: nocturnal, focused, self-possessed, masculine without aggression; controlled oxblood and ember-red reflections, deep graphite and black-cherry shadows, thin silver rain highlights; brooding but not threatening
>
> Color palette: oxblood, black cherry, ember red, charcoal graphite, wet silver, tiny restrained neutral-white highlights; absolutely no teal, cyan, purple, or magenta
>
> Materials/textures: rain-dark glass, black water, subtle surface ripples, wet concrete, brushed dark metal, fine fog, restrained grain; crisp and richly detailed at large desktop-window scale but never busy behind text
>
> Constraints: standalone background art only; original fictional city; no people, faces, focal vehicles, readable signage, text, logos, trademarks, watermarks, borders, UI controls, journal writing, signatures, or metadata-like overlays; preserve the Crimson Static visual identity without copying any real artwork or location
>
> Avoid: gore, horror imagery, fire, upscaling artifacts, softness, blurry buildings, generic cyberpunk neon overload, gaming HUD, purple-magenta lighting, cartoon look, distressed typography, giant glowing objects, high-school edginess, excessive pure-black empty space

### Review notes

Both assets were reviewed before inclusion. They depict an anonymous fictional city, contain no people, readable text, recognizable marks, personal content, or embedded color profile, and reserve calm regions for application content. The landscape version is a native composition rather than an enlarged portrait crop.
