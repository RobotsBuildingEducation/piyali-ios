# Piyali for iPhone

A functional native SwiftUI iPhone client for the main Piyali language-learning product. This repository is independent of the reference React web app. It contains no citizenship, links directory, landing-page experiments or other external route implementations.

Reference snapshot: `RobotsBuildingEducation/nosabos` commit `87d6fdc7954b89e021f336064fd6bf20a81d39f5`. Content export reads the reference checkout without changing it.

Open **Piyali.xcodeproj** in Xcode 26 or newer. Minimum iOS version is 17. Choose an iPhone simulator and run the **Piyali** scheme. Firebase configuration is optional for opening the app and practicing bundled content. All interfaces use ordinary SwiftUI controls; visual design is intentionally deferred.

## Included

- Native Nostr account creation and existing nsec import; device-only Keychain storage; authenticated private-key backup.
- Onboarding, target/support-language selection, CEFR selection, personal learning goals and daily XP goals.
- Authored CEFR curriculum exported from the reference: seven levels, 14 practice languages, 8,736 language-specific lessons; 1,150 localized flashcards including Pre-A1; 1,190 authored phonics language/support/level decks. Nahuatl and Yucatec Maya data remain available for existing learners; selectors follow the web's hidden-alpha behavior.
- Lesson skill requirements and completion, XP, streaks, daily practice plate and companion type unlocks, and the reference performance score rules. Companion health follows the web’s calendar-day decay, once-per-window goal recovery and observed healthy-day evidence. Daily goal bundles combine tutor, lesson, recall and authored phonics practice, adapt to observed ability, and resume shared progress across devices. Observable production checks distinguish preparation from independent communication. Goal completion records progress without adding an XP bonus; graded preparation retains its practice rewards. Daily quests use the web’s weighted selection, introductory sequence, varied daily targets and unfinished-course carryover. Completion is checked against committed activity and awards one +25 XP bonus and voice journey session per language/day. Mistake repair adapts generated activities to specific concepts. The authored achievement catalog shows evidenced native progression, and voice-journey milestones support private recordings.
- Offline flashcards with the web’s spaced review scheduler (Again/Hard/Good/Easy, learning steps, lapses, due queue), and phonics with speech playback. AI activities cover vocabulary, grammar, reading, listening, speaking, character stories, role-play conversation and text adventures.
- Independent tutor course levels, authored agenda tasks, graded tutor turns, saved lesson progress, tutor chat, speech recognition and spoken replies and native Firebase Gemini Live voice sessions with streaming PCM audio, transcripts and interruption handling.
- Notes creation/editing/deletion, saved explanations, conversation notes, learning history, grammar guides and real-world practice reflections. Companion memory captures graded mistakes, deduplicates daily slips, retains web enrichment, expires after the following day and feeds focused repair practice; repair completion retires its memory.
- Firebase AI Logic (Gemini Developer API), dedicated Cloudflare Responses fallback and Firebase App Check. Firestore imports and writes shared web XP, calendar activity, lesson completion and flashcard review records, with an offline outbox and transaction receipts to prevent repeated rewards.
- Public Nostr learning teams with verified events, relay acknowledgments, creation, leave/delete and opt-in progress publication.
- Subscription paywall with signed Nostr Patreon restore, StoreKit purchase/restore with verified Nostr-bound entitlements, independent provider restoration and storefront-controlled web payment link to the actual `/subscribe` route.
- Per-language starting-level self-assessment and independent lesson/flashcard course unlocks, with Firebase placement and Score persistence. Placement grants access without granting completion or XP.

## Connect services

**The separate Firebase project, native Nostr authentication bridge, App Check development setup and protected Firestore database are deployed and verified. Live AI text/audio and signed web restore are verified; App Store setup and paid-member/device verification remain.** See [docs/FIREBASE_PROJECT.md](docs/FIREBASE_PROJECT.md) for the provisioned resources. Start with [docs/BACKEND_SETUP.md](docs/BACKEND_SETUP.md). It explains native Firebase registration, App Check, Cloudflare's required native App ID allowlist, the existing API contracts, StoreKit product IDs, web subscription linking and deployment boundaries.

Place a real **iOS** `GoogleService-Info.plist` in `Piyali/Resources/`; local builds copy it conditionally. This file is gitignored. Optional `AppConfiguration.local.plist` overrides the public configuration without committing local settings. Server secrets never belong in the app.

The existing web backend deployment and reference checkout have not been changed. The dedicated native authentication worker is documented in [Backend/README.md](Backend/README.md). `BackendReference/` contains a tested App Check allowlist validator for the separately managed Cloudflare worker; it is an integration reference and has not been deployed.

Launch the locally configured simulator with `scripts/run-simulator.sh`; it reads the registered debug token from ignored local secrets and passes it only in the launch environment.

The opt-in `scripts/test-live-api.py` verifies native sign-in, Gemini text and JSON, Cloudflare exercises, signed Patreon restore and live PCM output using an isolated test identity. It needs the ignored Firebase configuration and debug token.

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
```

The exporter uses the reference's existing `esbuild` install. Only this repo's bundled gzip JSON files are written. Run the content tests after re-exporting.

## First-build boundaries

This is a functional native foundation, not a claim that every web feature has already reached parity. The independent Firebase project and its native app/Firestore are provisioned. Live Nostr-to-Firebase authentication, App Check debug exchange and protected Firestore access are verified. Production App Attest awaits an enrolled Apple Developer account; Native Gemini text/audio and authenticated Cloudflare exercises are verified. Signed web restoration correctly denies unlinked accounts; local StoreKit purchases/restoration, expiration, refunds and approval updates are verified. Active web membership, App Store Connect products and paid-device checks remain verification gates. Simulator tests cannot validate real paid transactions or physical-device audio quality.

Shared XP, daily goal plans/evidence/preparation outcomes, per-language self-assessment placement, separate course levels, regular/tutor lesson completion, daily quest counts and bonuses, voice journey session counts, flashcard schedules, companion health/history, companion memory, calendar activity and performance scores use the existing web Firestore fields. Native-only state also uses `iosStateJSON` version 2. Offline practice retries are idempotent, completion sets merge, and explicit profile edits use timestamps. Notes and history still use snapshot sync with last writer wins; every web map is not reconciled. Voice milestone recordings are stored locally and their filenames appear in cloud state; audio files do not sync automatically. NIP-46 remote signing, NIP-07 browser signers, legacy Firestore-only teams, Cashu/Lightning wallets and nutzaps, the graphical RPG world and cross-platform achievement sync are not yet ported. The RPG learning mode is a native text adventure, and companion functionality is represented by state and controls. OpenAI WebRTC and Cloudflare audio-cache playback remain separate follow-up transports; Gemini Live is the implemented continuous voice path.

The public curriculum contains 14 languages while the visible target selector includes the 12 languages currently shown by the main web app. Support language explains authored content and generated exercises; the first-build interface controls are English.
