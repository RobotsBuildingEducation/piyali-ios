# Welcome drawer: parity correction in progress

The actual web `Onboarding.jsx` presents a bottom drawer with a 100-point character/header row, subtitle, support-language card, practice-language card, optional goal card and fixed Start session button. Its mobile body uses 28-point side/top padding after the shared theme overrides. The controls use the system font; the landing page's DM Sans styling does not carry into this drawer.

The native drawer now follows those cards, 12-point card padding, 16-point gaps, source light/dark surfaces and three-point drawer frame, 42-point language controls, 104-point goal field and 48-point teal Start session action. The original 24×24 circular flag SVGs and character 24 are packaged as native assets. Native status and home areas remain platform chrome. Native menu presentation, font fallback and keyboard UI differ from the browser.

Language menus execute the original option builders with the original **app translations**, including tier order and localized beta tags. They intentionally differ from the landing public-copy labels. Nahuatl and Maya remain hidden from ordinary selectors (`selectorHidden` in the source). Their external community-resource modal is not surfaced by the ordinary web onboarding flow, so iOS does not offer them as AI practice choices.

A separate draft stores goals by practice language. Support-language changes update the interface without changing practice language or losing its goal. Late account-language resolution follows the account until an explicit support choice, which is protected from later updates. The field applies the browser's 600 UTF-16-unit limit and keeps emoji valid at the boundary. Completion saves every nonblank language goal through the existing canonical goal/receipt mechanism, then stores the chosen languages and completion locally/cloud-side. Empty goals create no placeholder goal. This does not award XP or create a proficiency placement.

## Source evidence

The target-owned preview renders the **unmodified original Onboarding component** at 402×874 inside the same-origin mobile frame. Completion is an in-memory callback, sounds are disabled and no browser identity or learner profile is created. The read-only measurement button lives outside the iframe, records public layout/font/placeholder metrics and excludes input values. Source hashes are in [the manifest](reference/onboarding-manifest.json).

The observed original journey enters “Talk with family” for Spanish, switches to French and enters “Order in a cafe”, changes support to French, returns to Spanish and sees the original goal, then completes with French selected. Its callback returns both goals with French support/practice. That payload is retained in `Tests/PiyaliCoreTests/Fixtures/onboarding-completion.json` and compared with the native draft. This is source component evidence; the native Firestore checks establish native persistence separately.

| State | Original component (top 720 CSS pixels) | Native drawer (includes iOS chrome) |
|---|---|---|
| English light | [Source](reference/onboarding-en-light-402.png) | [Native](native/onboarding-en-light.png) |
| French, retained goal | [Source](reference/onboarding-fr-goal-402.png) | [Native](native/onboarding-fr-goal.png) |
| Arabic dark | [Source](reference/onboarding-ar-dark-402.png) | [Native](native/onboarding-ar-dark.png) |

Public layout measurements for English light and Arabic dark are retained alongside the source captures. The iPhone status area shifts native content down; the complete scrollable content and fixed button are checked separately.

## Remaining first-run work

The companion’s Continue → setup/key-backup → proficiency-decision chain is now implemented with an installed-app adaptation and the original web steps; see [FIRST_RUN.md](FIRST_RUN.md). Post-introduction daily-goal/timer dialogs and full Today’s Focus/design parity remain. Optional interaction sounds, hidden voice/effect defaults and broader locale/accessibility layouts still need comparison.
