# Entry-screen parity work: partial

This replaces the earlier generic welcome/account form. It is an in-progress part of the larger functional and design correction, not a completed port of the landing page or whole product.

## Implemented in this branch

- Native entry hero uses the original public copy in ten languages, the original orb PNG, converted original DM Sans font files, light/dark color tokens, name field, guarded named registration, language menu and a dedicated secret-key sign-in screen with back/error states.
- Named registration carries the chosen language and trimmed name into the new native learner. The default practice language follows the web rule: English for Spanish support, Spanish otherwise. Existing accounts retain their loaded data.
- The onboarding screen follows the source fields: support language, practice language and an optional language-scoped goal. It omits the old CEFR/daily-goal form and no longer creates a proficiency placement or Score during onboarding. Blank goals remain blank.
- Native language atlas uses the original twelve postcard datasets and original globe geometry, with selectable languages and translated postcard meanings. Its initial mobile structure has been ported; detailed appearance and interaction review continues.
- Key login is still backed by the existing native Nostr identity service. Remote signing is a native alternative to the source's conditional browser extension login.
- Capabilities tabs, original memory/proficiency content, source-drawn animated companion carousel, 23-tool expansion, original light/dark ethos and mission vectors, independent FAQ disclosures, privacy sheet and shared lower signup form are ported. Their detailed visual comparison continues.
- Public voice now follows the source five teaching turns plus sixth final-feedback response, playback-gated input, duplicate/late-event handling, retry/reset and separate Firebase demo session. Its compact bubbles, language selector, display/tutor orb and nine-bar wave follow the source component. See [public demo evidence and device limits](LANDING_DEMO.md).
- The original orb is packaged as the iOS app icon. DM Sans regular, medium, semibold and bold are bundled and registered.

## Evidence and limits

The clean preview uses a separate local origin, so existing browser sessions are not cleared or signed out. Public reference captures in `docs/reference/` show the original mobile landing and sign-in at 402 CSS pixels wide. The raw reference source is never edited. Source screenshots contain no learner account information.

Native checks cover guarded signup/login/back/errors, actual onboarding controls, no invented placement/rewards, atlas selection, tab switching, companion navigation, toolkit expansion, FAQ disclosure, footer signup guards and privacy. Original artwork/fonts decode in the built app. Pixel measurements and screenshots are being compared; these interaction checks do not establish pixel parity.

## Still required

Match scrolling header actions, floating greetings, hero orb interaction/motion, selected-tab rendering, proficiency-card geometry, dark atlas styling and right-to-left presentation. Finish errors/loading/accessibility and equivalent screenshots for language/theme states. Verify the entire public voice lesson with physical microphone input and audible playback, beyond the controller, scripted UI and provider checks in [LANDING_DEMO.md](LANDING_DEMO.md).

The first Today’s Focus/menu shell, scoped conductor and sequential lesson gates are now implemented. Distinct exercise interaction types, leaf-screen designs and complete guided-session lifecycle remain. The broad gaps are tracked in [PARITY_AUDIT.md](PARITY_AUDIT.md).
