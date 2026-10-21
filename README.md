# Piyali for iPhone

An in-progress native SwiftUI iPhone port for the main Piyali language-learning product. This repository is independent of the reference React web app. It contains no citizenship, links directory, landing-page experiments or other external route implementations.

Initial reference snapshot: `RobotsBuildingEducation/nosabos` commit `87d6fdc7954b89e021f336064fd6bf20a81d39f5`. Incremental exploration, community and quiz contract exports were checked against `d6c1184e056aa8a0f51a78d9a687213e1d2051db`. Content export reads the reference checkout without changing it.

Open **Piyali.xcodeproj** in Xcode 26 or newer. Minimum iOS version is 17. Choose an iPhone simulator and run the **Piyali** scheme. Firebase configuration is required for online practice. The current scope includes functional and design parity; the correction is still in progress.

> **Parity correction:** The existing build does not yet match the web product. Prior component, transport and content tests do not establish functional or visual parity. Landing/login/onboarding, product navigation, guided sessions and exercise interactions are being reworked against the actual web screens. See [the corrected audit](docs/PARITY_AUDIT.md).

## Existing native components (parity verification in progress)

- Native Nostr account creation, existing nsec import and NIP-46 bunker connections; device-only Keychain storage; authenticated backup for local keys. Remote accounts keep the learner’s private key in their signer. See [docs/REMOTE_SIGNER.md](docs/REMOTE_SIGNER.md).
- Named signup and key login, followed by the source's support language, practice language and optional goal onboarding. Starting-level selection belongs to the main learning flow. The Getting Started components include 98 language/CEFR templates, six ordered activities and 980 localized introductory adventures. The six activities now mount inline with the source stepper and finish with the shared lesson-completion dialog; the post-introduction scholarship/daily-goal sequence and deeper activity parity remain. See [docs/INTRO_TUTORIAL.md](docs/INTRO_TUTORIAL.md) and the [realtime correction](docs/REALTIME_LESSON.md).
- Authored CEFR curriculum exported from the reference: seven levels, 14 practice languages, 8,736 language-specific lessons; 1,150 localized flashcards including Pre-A1; 1,190 authored phonics language/support/level decks. Nahuatl and Yucatec Maya data remain available for existing learners; selectors follow the web's hidden-alpha behavior.
- Lesson skill requirements and completion, XP, streaks, daily practice plate and companion type unlocks, and the reference performance score rules. Grammar/vocabulary and curriculum realtime save original generated-question difficulty quotes, apply assistance-sensitive point changes locally and in Firebase, and preserve their question snapshots; see [the scoped assessment checks](docs/QUESTION_WORTH.md). Companion health follows the web’s calendar-day decay, once-per-window goal recovery and observed healthy-day evidence. Daily goal bundles combine tutor, lesson, recall and authored phonics practice, adapt to observed ability, and resume shared progress across devices. Observable production checks distinguish preparation from independent communication. Goal completion records progress without adding an XP bonus; graded preparation retains its practice rewards. Daily quests use the web’s weighted selection, introductory sequence, varied daily targets and unfinished-course carryover. Completion is checked against committed activity and awards one +25 XP bonus and voice journey session per language/day. Mistake repair adapts generated activities to specific concepts. The authored achievement catalog stores confirmed earned awards and private completion ledgers in Firebase, catches up saved history once and restores across native devices, and voice-journey milestones support private recordings.
- Offline flashcards with the web’s spaced review scheduler (Again/Hard/Good/Easy, learning steps, lapses, due queue), and phonics with speech playback. AI activities cover vocabulary, grammar, reading, listening, speaking, character stories, role-play conversation and text adventures. Native stories include sentence practice and radio/conversation episodes with listening, word-order and reply checkpoints, saved drafts and once-only source rewards. See [docs/STORIES.md](docs/STORIES.md).
- Final quizzes preserve standard and advanced question/pass counts, early outcomes, resumable rounds, retries, zero-XP questions and once-only lesson rewards. See [docs/FINAL_QUIZZES.md](docs/FINAL_QUIZZES.md).
- Exploration RPG worlds with room/portal travel, inventory, item gathering and object searches, offline object descriptions, saved runs and generated character/settings/quests through Cloudflare. Includes 224 source-derived templates across eight world families and seven levels. See [docs/EXPLORATION.md](docs/EXPLORATION.md).
- Authored RPG adventures: all 12 episodes, seeded maps and NPC interactions; 1,246 chapter-grounded unit reviews across 14 languages; choice/speech tasks, retry scoring, saved runs and once-only 15/22/30 XP recaps. Connected stories and NPC replies use the authenticated Cloudflare API. See [docs/RPG.md](docs/RPG.md).
- Independent tutor course levels, authored agenda tasks, graded tutor turns, saved lesson progress, tutor chat, speech recognition and spoken replies and native Firebase Gemini Live voice sessions with streaming PCM audio, transcripts and interruption handling.
- Native reading with curriculum document scopes, diverse passages, listening, translations, text/fill/choice comprehension, read-aloud transcript feedback, resumable drafts and one shared 5–8 XP reward. See [docs/READING.md](docs/READING.md).
- Notes creation/editing/deletion, saved explanations, conversation notes, learning history, grammar guides and the full daily immersion checklist with optional private reflections. Companion memory captures graded mistakes, deduplicates daily slips, retains web enrichment, expires after the following day and feeds focused repair practice; repair completion retires its memory.
- Firebase AI Logic (Gemini Developer API), dedicated Cloudflare Responses fallback and Firebase App Check. Firestore imports and writes shared web XP, calendar activity, lesson completion and flashcard review records, with an offline outbox and transaction receipts to prevent repeated rewards.
- Daily immersion uses three missions plus a goal mission, retained partial progress, language-specific history, the original Score landmarks and once-only 15 XP checklist rewards. See [docs/IMMERSION.md](docs/IMMERSION.md).
- Conversation goals support text, dictation and live voice, contextual goal changes, starter phrases, translation, personal topics and tutor personality. Each real turn counts once; completed goals receive one bonus, quoted Score result and achievement proof across device retries. Private drafts resume per language. See [docs/CONVERSATIONS.md](docs/CONVERSATIONS.md).
- Signed Nostr achievement restoration and opt-in automatic public collection sync, preserving legacy and other-host records. See [docs/NOSTR_ACHIEVEMENTS.md](docs/NOSTR_ACHIEVEMENTS.md).
- Community Nostr milestone feed with author profiles, refresh and explicit progress-post previews. See [docs/COMMUNITY_FEED.md](docs/COMMUNITY_FEED.md).
- Private Firebase teams and invitations with acceptance/decline, creator edits, concurrent roster updates, leave/delete and explicit per-team progress sharing. Public Nostr learning teams with verified events, relay authentication/acknowledgments, creation, creator rename/roster additions, member departure/deletion and opt-in progress publication. Team details show profile names, daily goals, Score, XP, streaks and companion status; acknowledged own teams survive relay indexing delays and restart. See [docs/TEAMS.md](docs/TEAMS.md).
- Subscription paywall with signed Nostr Patreon restore, StoreKit purchase/restore with verified Nostr-bound entitlements, independent provider restoration and storefront-controlled web payment link to the actual `/subscribe` route.
- Per-language starting-level self-assessment and independent lesson/flashcard course unlocks, with Firebase placement and Score persistence. Placement grants access without granting completion or XP.

## Connect services

**The separate Firebase project, native Nostr authentication bridge, App Check development setup and protected Firestore database are deployed and verified. Live AI text/audio and signed web restore are verified; App Store setup and paid-member/device verification remain.** See [docs/FIREBASE_PROJECT.md](docs/FIREBASE_PROJECT.md) for the provisioned resources. Start with [docs/BACKEND_SETUP.md](docs/BACKEND_SETUP.md). It explains native Firebase registration, App Check, Cloudflare's required native App ID allowlist, the existing API contracts, StoreKit product IDs, web subscription linking and deployment boundaries.

Place a real **iOS** `GoogleService-Info.plist` in `Piyali/Resources/`; local builds copy it conditionally. This file is gitignored. Optional `AppConfiguration.local.plist` overrides the public configuration without committing local settings. Server secrets never belong in the app.

The existing web backend deployment and reference checkout have not been changed. The dedicated native authentication worker is documented in [Backend/README.md](Backend/README.md). `BackendReference/` contains a tested App Check allowlist validator for the separately managed Cloudflare worker; it is an integration reference and has not been deployed.

Launch the locally configured simulator with `scripts/run-simulator.sh`; it reads the registered debug token from ignored local secrets and passes it only in the launch environment.

The opt-in `scripts/test-live-api.py` verifies native sign-in, Gemini text and JSON, Cloudflare exercises, signed Patreon restore and live PCM output using an isolated test identity. It needs the ignored Firebase configuration and debug token.

Nostr transport/collection tests use `scripts/test-nostr.sh` with isolated test keys and a loopback relay.

Local Apple subscription checks use `scripts/test-storekit.sh`; see [docs/STOREKIT_TESTING.md](docs/STOREKIT_TESTING.md). These use real StoreKit test transactions and never charge a payment method.

## Build and verify

```sh
brew install xcodegen
xcodegen generate
swift test
npm ci --prefix BackendReference
npm test --prefix BackendReference
npm ci --prefix Backend
npm test --prefix Backend
xcodebuild -project Piyali.xcodeproj -scheme Piyali \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath DerivedData CODE_SIGN_IDENTITY=- test
```

The Xcode project and Swift Package resolution are committed. `project.yml` is the project source. The standalone core package tests progress, streaks, accent-sensitive answers, persistence, all authored content and 116 scheduler cases exported from the web implementation. Xcode tests verify Nostr signatures and tampering; UI smoke tests cover account creation, onboarding, offline review scheduling, note persistence after relaunch and the tutor paywall. Simulator tests use ad hoc signing because Keychain requires signing entitlements. Do not disable signing for interactive simulator runs.

To run the opt-in Firestore contract tests against a local demo project (requires Firebase CLI and Java 21; does not require a Firebase account):

```sh
scripts/test-firestore.sh
scripts/test-rules.sh
```

The native SDK suite uses a reference copy of the web rules. `test-rules.sh` checks the deployed native rule source with authenticated emulator fixtures. Tests use a named emulator-only Firebase app, never the production app or database. See [docs/VALIDATION.md](docs/VALIDATION.md) for verified boundaries.

To refresh content from a local web reference checkout (read-only):

```sh
node scripts/export-content.mjs /absolute/path/to/reference/nosabos
node scripts/export-review-fixtures.mjs /absolute/path/to/reference/nosabos
node scripts/export-goal-fixtures.mjs /absolute/path/to/reference/nosabos
node scripts/export-plate-fixtures.mjs /absolute/path/to/reference/nosabos
node scripts/export-conversation-fixtures.mjs /absolute/path/to/reference/nosabos
node scripts/export-team-fixtures.mjs /absolute/path/to/reference/nosabos
```

The exporter uses the reference's existing `esbuild` install. Only this repo's bundled gzip JSON files are written. Run the content tests after re-exporting.

## First-build boundaries

This is a functional native foundation, not a claim that every web feature has already reached parity. The [main-product audit](docs/PARITY_AUDIT.md) tracks remaining implementation findings, and its validation boundaries. The independent Firebase project and its native app/Firestore are provisioned. Live Nostr-to-Firebase authentication, App Check debug exchange and protected Firestore access are verified. Production App Attest awaits an enrolled Apple Developer account; Native Gemini text/audio and authenticated Cloudflare exercises are verified. Signed web restoration correctly denies unlinked accounts; local StoreKit purchases/restoration, expiration, refunds and approval updates are verified. Active web membership, App Store Connect products and paid-device checks remain verification gates. Simulator tests cannot validate real paid transactions or physical-device audio quality.

Shared XP, daily goal plans/evidence/preparation outcomes, per-language self-assessment placement, separate course levels, regular/tutor lesson completion, daily quest counts and bonuses, daily immersion checklists/history/rewards, conversation-goal achievements and quoted Score results, voice journey session counts, flashcard schedules, companion health/history, companion memory, calendar activity, permanent achievements and performance scores use the existing web Firestore fields. Native-only state also uses `iosStateJSON` version 2. Offline practice retries are idempotent, completion sets merge, and explicit profile edits use timestamps. Notes, history and private conversation/RPG drafts still use snapshot sync with last writer wins; every web map is not reconciled. Voice milestone recordings are stored locally and their filenames appear in cloud state; audio files do not sync automatically. NIP-46 signer-provided bunker connections are implemented; client-generated QR connections and legacy NIP-04 transport remain outside this build. NIP-07 browser extensions have no native extension interface. Private Firestore teams and invitations are implemented; the community hashtag feed includes verified public milestones, author profiles, refresh and previewed progress sharing. Legacy exploration room travel, inventory, object searches and portal gameplay are implemented. Browser wallet key backups, proof-only records and saved quotes can be restored without replacing existing funds. Modern NIP-60 wallet creation/restoration and Lightning deposits are implemented, including encrypted synchronization, invoice sharing/QR, quote archives and resumable mint/relay recovery. Manual one-sat nutzaps support quoted mint fees, recipient locks, receiving and recovery. Optional automatic tips use newly earned XP events, approved fee limits and a durable deduplication journal; they are off by default. The current web catalog retires spent-sat achievements, which remain unawarded in native. See [docs/WALLET.md](docs/WALLET.md). Authored RPG episodes use native maps and controls, and companion functionality is represented by state and controls. OpenAI WebRTC and Cloudflare audio-cache playback remain separate follow-up transports; Gemini Live is the implemented continuous voice path.

The public curriculum contains 14 languages while the visible target selector includes the 12 languages currently shown by the main web app. Support language explains authored content and generated exercises; the first-build interface controls are English.
