# Entry-screen parity work: partial

This replaces the earlier generic welcome/account form. It is an in-progress part of the larger functional and design correction, not a completed port of the landing page or whole product.

The signed-in home comparison is tracked separately in [Today’s Focus](TODAY_FOCUS.md), including the companion acknowledgement, setup/placement handoff, editor and immersion completion.

## Implemented in this branch

- Native entry hero uses the original public copy in ten languages, original DM Sans font files, floating greeting content/timing, gradient/grid background, source control shapes, name field, guarded named registration and localized/sorted language menu. The fixed header now uses the animated 50-point display orb without its shadow, theme switch and source scroll-triggered actions.
- Header Start Learning follows the original nameless registration shortcut, including when the name form is invalid. Hero/footer still require the source name guard. Twenty-four creation cases, 56 header visibility cases and eight sign-in error cases are captured by executing the actual source callbacks, then compared with the native rules.
- The compact capability tabs now pin below the actual iPhone header and stop at their parent panel's end. Source active-tab color/surface and retained demo state are preserved. Header and tabs measure the same global coordinates, accounting for the iOS status area.
- Named registration carries the chosen language and trimmed name into the new native learner. The default practice language follows the web rule: English for Spanish support, Spanish otherwise. Existing accounts retain their loaded data.
- The onboarding drawer follows the source three cards, system font, original circular flags, language menus and fixed Start session control: support language, practice language and an optional language-scoped goal. All nonblank language goals are saved at completion, including goals entered before switching practice language. It omits the old CEFR/daily-goal form and no longer creates a proficiency placement or Score during onboarding. Blank goals remain blank.
- Native language atlas uses the original twelve postcard datasets and original globe geometry, with selectable languages and translated postcard meanings. Its initial mobile structure has been ported; detailed appearance and interaction review continues.
- Key login uses the source card/control treatment and error classification, backed by the existing native Nostr identity service. The separate remote-signer action occupies the optional-signer layout and opens the native NIP-46 flow, with a visible navigation back control. This is the iPhone alternative to the browser's conditional NIP-07 extension action.
- Capabilities tabs, original memory/proficiency content, source-drawn animated companion carousel, 23-tool expansion, original light/dark ethos and mission vectors, independent FAQ disclosures, privacy sheet and shared lower signup form are ported. Their detailed visual comparison continues.
- Public voice now follows the source five teaching turns plus sixth final-feedback response, playback-gated input, duplicate/late-event handling, retry/reset and separate Firebase demo session. Its compact bubbles, language selector, display/tutor orb and nine-bar wave follow the source component. See [public demo evidence and device limits](LANDING_DEMO.md).
- The original orb is packaged as the iOS app icon. DM Sans regular, medium, semibold and bold are bundled and registered.

## Evidence and limits

The clean preview uses a separate local origin, so existing browser sessions are not cleared or signed out. Public reference captures in `docs/reference/` show the original mobile landing and sign-in at 402 CSS pixels wide. The raw reference source is never edited. Source screenshots contain no learner account information.

Native checks cover guarded signup/login/back/errors, actual onboarding controls, no invented placement/rewards, atlas selection, tab switching, companion navigation, toolkit expansion, FAQ disclosure, footer signup guards and privacy. Original artwork/fonts decode in the built app. Pixel measurements and screenshots are being compared; these interaction checks do not establish pixel parity.

## Header, hero and login checkpoint

The original full public app is now also rendered in the same-origin `__piyali-mobile-frame` preview at 402×874. Its read-only measurement control is outside the captured iframe and reads public layout/font metrics only. It records no input values, account state or microphone data. Source hashes, frame/capture dimensions and font provenance are in [entry render manifest](reference/entry-render-manifest.json). The source branch and existing user changes remain untouched.

At this width the source English hero has a 70.39-point heading, three 17.92-point subtitle lines and its name input at y=272.16. Preserving fractional font sizes corrects SwiftUI's earlier two-line subtitle; the native view now matches the measured paragraph height within 0.8 point at normal text size and still grows for accessibility sizes. The native input is at y=334.5 including the 62-point simulator status area. This is a component measurement, not a pixel-perfect whole-page claim. The existing DM Sans files are retained and their OFL text is bundled.

| State | Original app | Native app |
|---|---|---|
| English hero | [Light](reference/entry-hero-en-light-402.png), [dark](reference/entry-hero-en-dark-402.png) | [Light](native/entry-hero-en-light.png) |
| Scrolled header | [Source](reference/entry-header-en-light-402.png) | [Native](native/entry-header-en-light.png) |
| Secret-key login | [Source](reference/entry-signin-en-light-402.png), [invalid key](reference/entry-signin-error-en-light-402.png) | [Native with remote-signer alternative](native/entry-signin-en-light.png) |
| French dark hero | [Source](reference/entry-hero-fr-dark-402.png) | [Native](native/entry-hero-fr-dark.png) |
| Arabic dark hero | [Source](reference/entry-hero-ar-dark-402.png) | [Native](native/entry-hero-ar-dark.png) |
| Arabic dark login | [Source](reference/entry-signin-ar-dark-402.png) | [Native with remote-signer alternative](native/entry-signin-ar-dark.png) |

Simulator journeys cover header pet interaction, retained name/back navigation, key login, remote-signer navigation, nameless Spanish registration through onboarding/Today’s Focus/relaunch, and French → Arabic plus dark → light changes retained on relaunch. Arabic name and secret-key controls preserve physical right alignment for their localized placeholders. These preference-changing tests initialize ordinary defaults once in a strictly scoped DEBUG fixture; immutable launch-argument overrides are used only by fixed-state tests. Existing named signup, key errors, atlas, capability/toolkit/FAQ/privacy and mode-routing checks also cover the updated entry. The public-demo completion journey verifies that its sticky tabs remain below the header and retain the finished lesson when switching modes.

## Still required

Finish proficiency/atlas/card geometry, dark atlas styling, the rest of the locale/RTL layouts, the post-introduction modal chain and accessibility review across all controls. The welcome-drawer behavior is in [ONBOARDING.md](ONBOARDING.md), and the restored companion/setup/placement sequence is in [FIRST_RUN.md](FIRST_RUN.md). Background grain, exact gradient/blur/shadow and 3D compositing, platform icon/menu/font fallback differences, and any enabled interaction sounds still need comparison. Native remote signing is a platform adaptation rather than the browser extension UI. Verify the entire public voice lesson with physical microphone input and audible playback, beyond the controller, scripted UI and provider checks in [LANDING_DEMO.md](LANDING_DEMO.md).

The first Today’s Focus/menu shell, scoped conductor and sequential lesson gates are now implemented. Distinct exercise interaction types, leaf-screen designs and complete guided-session lifecycle remain. The broad gaps are tracked in [PARITY_AUDIT.md](PARITY_AUDIT.md).
