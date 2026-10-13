# Connect the iPhone app to Piyali services

The native app intentionally contains no server API keys, Patreon secrets, passcode unlocks, or copied web environment files. The reference services have not been modified or deployed. A separate Firebase project has been provisioned; its current state is documented in [FIREBASE_PROJECT.md](FIREBASE_PROJECT.md).

## Firebase

1. The selected backend is the independent `piyali-ios` Firebase project. Its iOS app uses bundle ID `app.piyali.ios`; its `(default)` Firestore database is in `us-central1`. Do not register another duplicate app or point native development at `nosabo-30dcb`.
2. The real iOS `GoogleService-Info.plist` has been downloaded locally into `Piyali/Resources/GoogleService-Info.plist`. It is gitignored and conditionally copied by the build phase. Other developers can download it using the command in `FIREBASE_PROJECT.md`. Set your Apple signing team in Xcode.
3. Nostr-bound Firebase custom authentication, owner-only Firestore rules/indexes and the dedicated Cloudflare authentication worker are deployed. Live App Check debug exchange, sign-in, own progress and cross-account isolation passed. The copied web rules remain emulator fixtures; deployed production policy is `Backend/firestore.rules`.
4. Register the iOS app in Firebase App Check using App Attest once an enrolled Apple Developer Team ID is available (DeviceCheck is the fallback). The signed-in Apple account currently offers program enrollment, so production registration is pending. Debug builds use Firebase's debug provider; a simulator debug token is registered and stored in ignored `.secrets/app-check-debug.json`. Set it as `FIRAAppCheckDebugToken` in the app launch environment. Offline UI tests and the named emulator test app skip production Firebase initialization even when a real local plist is present.
5. Firebase AI Logic is configured with the Gemini Developer API on Spark after the user approved the Gemini terms. App Check and authenticated-user mode are enforced; native text and live audio have been tested. `GeminiAPIProvider` selects `googleAI`; Agent Platform/Vertex can be selected later with appropriate billing and model/location configuration.

The Firestore contract is `users/{npub}` with a matching `local_npub` field. The native client uses the existing shared fields:

- XP: `xp`, `progress.languageXp`, `progress.totalXp`, `dailyXpRecent` and `xpHistory/{YYYY-MM}`. Offline awards retain their original calendar day; syncing yesterday’s work does not add it to today’s 24-hour XP window.
- Lessons: `languageLessons/{targetLang}_{lessonId}`, plus first-completion increments in `courseProgress/{targetLang}`. The app preserves unknown fields and existing migration markers.
- Flashcards: `languageFlashcards/{targetLang}_{cardId}`, using the web scheduler fields and completion convention. Current target/level records hydrate on sync; scheduler completion is earned by graduating the learning steps.
- Companion memory: `companion/{targetLang}.notes` uses the web capture/status fields, daily concept/source deduplication, priority cap, 40-note cap and expiry window. Captures and reinforcement changes use transactional receipts, preserving existing enrichment and unrelated bucket fields. Native memory is hydrated from this document, not copied into the root snapshot.
- Practice activity and score: existing per-language daily activity maps and score-scale v4 `learningIntelligence` fields.
- Profile: web preferences are imported; explicit native preference edits update the shared fields. Native timestamps prevent an older native request from replacing a newer native preference edit.

A protected local outbox stores each practice change until server acknowledgment. Firestore transactions write `iosPracticeReceipts/{id}` along with shared progress or companion memory. Retries cannot repeat XP; lesson/goal/repair receipts use stable completion identifiers across native devices. New practice or memory captures during a sync remain queued. A bounded `iosRecentEventIDs` journal prevents already-committed changes from being applied locally again when sync requests overlap. Progress synchronization runs under authenticated ownership rules. Subscription fields remain server-protected; client practice totals are not server-graded.

`iosStateJSON` version 2 retains native-only state. Completion sets merge across native devices. Manual notes, history, native goal plans and recordings still use snapshot state with last writer wins; audio files remain local. Existing v1 snapshots decode without the new optional fields. Aggregate v1 XP is not automatically backfilled into shared web XP, avoiding duplicate credit when its origin cannot be established. Full cross-platform reconciliation, pet decay and achievement sync remain follow-up work.

The copied rules in `BackendReference/firestore.emulator.rules` are used only for local tests. Neither rules nor indexes are deployed by this repo. The two-field lesson/card queries match the web queries and need the same deployed indexes.

## Cloudflare

Native authentication uses `AuthBaseURL`, defaulting to the dedicated `piyali-ios-api` worker. It also serves `WorkerBaseURL` for the native Responses fallback, with the native App Check audience and Firebase-authenticated npub ownership. See [../Backend/README.md](../Backend/README.md) for deployment and tests.

The existing web worker accepts the old project's single web App ID. Native traffic uses the independently deployed `piyali-ios-api` worker, bound to the new project and iOS App ID. `BackendReference/` remains an undeployed reference fixture; the web worker has not been changed.

Native `URLSession` calls use `X-Firebase-AppCheck` and `Authorization: Bearer <Firebase ID token>` with the reference Responses request shape (`model`, `input`, `text.format`). The worker verifies both tokens, permits the reference models, limits per-learner requests, and bounds input/output. Gemini Developer API is attempted first; Responses is the fallback. Swift requests JSON output for structured exercise/grade/goal content. Cloudflare keys stay on the server.

## Subscriptions

The actual web route in the reference app is `/subscribe`. The iOS screen is named Subscription and opens `https://piyali.app/subscribe`; no `/subscription` server route is invented. It also handles `piyali://subscription` to refresh access, but no web callback changes were made.

Web subscription restore uses the existing `/api/patreon/link-challenge` (`action: restore`) and `/api/patreon/key-status` endpoints. The server-provided event's exact timestamp, kind, tags and content are signed with the learner's Nostr key. No Firestore boolean or user-entered passcode grants paid access. Web authorization is held in memory for at most 15 minutes and rechecked on foreground.

To subscribe or link Patreon, sign in on the website with the same key, complete its existing linking/payment flow, return to iOS, and refresh. Private keys are never placed in URLs, logs, UserDefaults or Firestore. The current app does not automate cross-browser Patreon cookies.

Configure auto-renewing subscription products in App Store Connect. Defaults are `app.piyali.ios.monthly` and `app.piyali.ios.annual`; change the configuration to your real product IDs. Native purchases use `appAccountToken` derived from the npub. Only StoreKit-verified, unrevoked, unexpired transactions with that matching token grant access on that account. Refunds and renewals are observed with `Transaction.updates`. Configure your StoreKit sandbox for purchase testing.

External payment links appear in debug builds for testing. Release builds show them only when StoreKit's storefront matches `ExternalPaymentStorefronts` (default `USA`). Review current Apple rules before extending the list or shipping other storefronts. Missing StoreKit products and failed web verification never unlock the app.

## Nostr

Identity uses NostrSDK secp256k1 Schnorr signing and NIP-19 nsec/npub encoding. Private keys are saved in a device-only, unlocked Keychain item. Backup requires device authentication. Import supports local nsec signers; NIP-07 browser extensions and NIP-46 remote signing are not part of this first native build.

Teams use signed kind 30078 events on `relay.primal.net`, `relay.ditto.pub` and `nos.lol`, with the reference app's `d`, `t`, `name`, `p`, `deleted` and team-leave conventions. Incoming events are verified before display. Publication waits for a positive relay acknowledgment. Progress sharing is explicit and public; the native app publishes the fields it actually measures and uses the ported score-scale v4 CEFR fallback rules and does not fabricate model-assessed difficulty. Legacy Firestore-only teams are not migrated.

## Speech

The tutor supports typed conversations, microphone transcription and synthesized replies. Turn-based interaction uses Apple's Speech/AVFoundation. Continuous voice tutoring uses Firebase Gemini Live with 16 kHz PCM microphone input, 24 kHz PCM playback, voice processing, server interruptions and input/output transcription. It uses `gemini-2.5-flash-native-audio-preview-12-2025` through the Gemini Developer API, equivalent to the reference's Agent Platform 2.5 native-audio model. The opening greeting uses realtime text input, which returned PCM audio in a live Swift SDK test. The session closes on navigation away or backgrounding. The alternate OpenAI WebRTC transport and Cloudflare audio cache are not implemented. Microphone input and playback quality still require physical-device testing. Live network text and audio output have passed with the configured Firebase app. Speech recognition may require network access and the target locale must be supported on the device. Typed answers remain available.

References: [Firebase App Check for iOS](https://firebase.google.com/docs/app-check/ios/app-attest-provider), [Gemini Live API](https://firebase.google.com/docs/ai-logic/live-api), [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).
