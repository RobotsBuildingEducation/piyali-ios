# Connect the iPhone app to the existing backend

The native app intentionally contains no server API keys, Patreon secrets, passcode unlocks, or copied web environment files. No service in the reference repo has been modified or deployed.

## Firebase

1. In Firebase project `nosabo-30dcb`, register an **iOS** app with bundle ID `app.piyali.ios`.
2. Download that app's `GoogleService-Info.plist` into `Piyali/Resources/GoogleService-Info.plist`. Do not reuse the web Firebase App ID. This file is gitignored.
3. Run `xcodegen generate` after adding the plist so it is included as a resource. Set your signing team in Xcode.
4. Register the iOS app in Firebase App Check using App Attest (DeviceCheck is the fallback). The debug build uses Firebase's debug provider; register its generated debug token in the Firebase console for simulator development.
5. Enable Firebase AI Logic with the Vertex AI backend and billing, as in the web app. Its default model and provider are in `AppConfiguration.plist`.

The Firestore contract is `users/{npub}` with a matching `local_npub` field. iOS stores its complete progress in `iosStateJSON`, version 1, using a merge write so it does not replace the web's maps. Initial account import reads web preferences and language XP. Native progress does **not** currently mirror every web progress field. Concurrent edits on multiple native devices are last writer wins; offline progress stays on-device until sync succeeds.

## Cloudflare

The existing worker uses a strict **single web App ID** check in `cloudflare-tts-proxy/src/app-check.js`. Adding an iOS Firebase app does not automatically authorize its tokens. An operator of that separate backend must change its `payload.sub` check to a configured allowlist that contains both the existing web ID and the new iOS ID. Keep JWT issuer, audience, signature, expiration and algorithm checks in place.

A ready-to-integrate replacement validator is supplied in `BackendReference/app-check.js` in this repo, with tests. It is not deployed. Set `FIREBASE_APP_IDS` to the comma-separated web and native IDs, retain `FIREBASE_PROJECT_NUMBER`, and deploy from the backend owner's workflow. Do not solve this by disabling App Check or giving iOS the web ID.

Native `URLSession` calls do not send an Origin header, which the existing worker supports. Requests use `X-Firebase-AppCheck` and the existing `/api/tts-proxy/proxyResponses` request shape (`model`, `input`, `text.format`). Firebase Gemini is attempted first, with Responses as fallback. Cloudflare keys stay on the server.

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

The tutor supports typed conversations, microphone transcription and synthesized replies. Turn-based interaction uses Apple's Speech/AVFoundation. Continuous voice tutoring uses Firebase Gemini Live with 16 kHz PCM microphone input, 24 kHz PCM playback, voice processing, server interruptions and input/output transcription. It uses `gemini-live-2.5-flash-native-audio` in `us-central1`, matching the web provider. The session closes on navigation away or backgrounding. The alternate OpenAI WebRTC transport and Cloudflare audio cache are not implemented. Physical-device audio quality and live network access still require testing with the configured Firebase app. Speech recognition may require network access and the target locale must be supported on the device. Typed answers remain available.

References: [Firebase App Check for iOS](https://firebase.google.com/docs/app-check/ios/app-attest-provider), [Gemini Live API](https://firebase.google.com/docs/ai-logic/live-api), [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).
