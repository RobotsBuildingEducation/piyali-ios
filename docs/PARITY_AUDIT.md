# Functional and design parity: correction in progress

The earlier claim of a completed functional port was incorrect. Shared feature names, exported lesson counts and isolated service tests did not establish that the native app reproduced the web product. The user confirmed that landing, login, onboarding and the main features were all materially different, and explicitly expanded the requirement to design parity.

The reference repository remains read-only. Work is in `codex/functional-design-parity` in `RobotsBuildingEducation/piyali-ios`. Existing Firebase, Cloudflare and Nostr services are reusable components; they are not evidence of screen or flow parity.

## Confirmed differences

| Flow | Actual web behavior | Existing native build | Status |
|---|---|---|---|
| Public landing | Branded multilingual page, named creation, language/theme choices, atlas, capability tabs/live demo, companion, toolkit, mission, FAQ and footer | Original copy/fonts/assets, native atlas/tabs/carousel/toolkit/FAQ/privacy/lower signup; real signed-out Gemini audio | Entry and section interactions checked. Scrolling header, orb gestures/motion, greetings, exact geometry, language/theme states and full voice-turn lifecycle remain |
| Login | Dedicated secret-key screen with back navigation, localized errors and optional browser signer | Branded key screen with back/error states and native remote signer | Main interaction checks pass; signer presentation and all language/theme layouts still need comparison |
| Onboarding | Welcome drawer: support language, practice language and optional learning goal | Original three-field flow and character artwork; blank goals; no invented placement or rewards | Entry checks pass; community-language choice and initial proficiency flow need further comparison |
| Product navigation | One active surface, Today’s Focus default; bottom menu with four panels and six modes | Five tabs replaced with that menu and a first native Today’s Focus surface | Build and journey checks cover the main structure. Header/timer, panel design, localization, detailed layout and mode switching during activities remain |
| Guided daily session | Start tasks opens the next mode without starting an activity; completion/Continue sequence; resume and final return home | Scoped saved session, mode routing and initial completion sheets | Scope/order tested. Actual activity completion/blocker sequencing, next-day restore, goal/repair routing and final bonus journey require end-to-end checks |
| Lesson access | Tutorial/sequential/placement gates in actual renderer | Renderer rules ported, native path and Tutor nodes gated; recommendations respect access | 336 renderer-generated cases pass. Broader saved-progress/import and course journey checks remain |
| Subscription | Main product is free below 300 account XP, then gated without verified membership | Immediate native AI paywall removed; account-wide 300-XP access and paid provider grants kept separate | Boundary and language-switch checks pass. Web gate design, migration/recovery, paid restore and App Store setup remain |
| Lesson activity | Original activity selection, authored objectives, context and completion sequence | Separate generic screens | Must compare each mode end to end |
| Lesson preview | Node opens unit-colored summary, mode badges, expandable objectives and goal before Start Lesson | Native preview uses original unit appearance and localized labels; Getting Started uses the actual seven starter phrase pairs rather than its 21-item internal agenda | Dark expand/close/start and continuation into practice checked. Session layout and preparation are still being corrected |
| Lesson XP | Active lesson's own saved `earnedXp` reaches its goal, then a separate completion bonus | Scoped local/cloud counters, explicit start, automatic threshold check and bonus deduplication | Counter/import/rebase and concurrent Firestore checks pass. Original session and completion-modal sequence remain |
| Grammar/vocabulary | Fill, single choice, multiple answer, speaking, matching, word-bank translation, repeat, flashcards and delight variants with distinct grading/rewards | Typed native questions using source instructions/copy, semantic judges, format rewards, retry and saved question state | All 17 grammar generation contracts passed a real iOS provider run; Japanese matching and representative semantic judges checked. Full session handoffs, grounding/worth checks, quiz integration, drag/drop layouts and physical audio remain; see [interaction checkpoint](PRACTICE_INTERACTIONS.md) |
| Other learner modes | Stories, reading, conversations, live tutor, games, phonics and flashcards each have their own controls and lifecycle | Partial native implementations exist | Requires screen/interaction verification |
| Companion, memory, teams, achievements, wallet, subscription | Main product surfaces and transitions, with opt-in privacy/payment behavior | Services and forms exist | Requires design and end-to-end comparison |

The public demo uses a separate named Firebase app and a fixed public service identity issued by an App Check protected, rate-limited native Cloudflare endpoint. It does not sign in the learner, create a Nostr identity, write a learner profile, award XP or save demo transcripts. This identity has no Nostr claim and is rejected by the existing learner-data and Responses authorization. The deployed worker version for this addition is `3d828e53-86cf-429d-8802-6c31e9536762`.

## Verification required before completion

Capture the reference at iPhone dimensions, list its visible controls and transitions, implement the native screen with the original assets/copy/theme, and compare equivalent signed-out and learner states. Validate user journeys from landing through onboarding and actual practice, including errors, resume, rewards, back navigation, modal sequencing and paywalls. Tests of the older substitute flows must be replaced rather than preserved behind a test-only shell.

`scripts/start-reference-preview.mjs` serves the reference at a separate local origin without modifying it or clearing existing sessions. Vite caches live in the ignored native `.reference-preview/` directory; PWA output and build-report plugins are excluded to keep the reference read-only. The public preview may be used without creating a web account.

## External release setup

The independent Firebase project and Cloudflare worker are provisioned. Apple release signing/App Attest, App Store Connect products, paid-member restoration and physical-device audio remain release/verification requirements, separate from the missing product parity above.
