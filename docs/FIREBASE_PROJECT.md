# Piyali's independent Firebase project

Provisioned on 2026-10-12 after the user selected a separate Firebase project.

| Resource | Value |
| --- | --- |
| Project name | Piyali |
| Project ID | `piyali-ios` |
| Project number | `861709486546` |
| iOS app | Piyali iPhone |
| Bundle ID | `app.piyali.ios` |
| Firebase iOS App ID | `1:861709486546:ios:edbba9ce75380765bc200b` |
| Firestore database | `(default)` |
| Firestore location | `us-central1` |
| Firestore edition | Standard, native mode, free-tier database |

Open [Firebase Console](https://console.firebase.google.com/project/piyali-ios/overview).

The downloaded iOS configuration is stored locally at `Piyali/Resources/GoogleService-Info.plist`, is gitignored, and is copied into local builds conditionally. The committed Xcode project has no file reference requiring that private local file, so a fresh clone can build offline without it. To download it on another developer machine:

```sh
firebase apps:sdkconfig IOS '1:861709486546:ios:edbba9ce75380765bc200b' \
  --project piyali-ios --out Piyali/Resources/GoogleService-Info.plist
```

Verified: project, registered iOS app and Firestore database are active. Firebase Authentication is initialized with subtype `FIREBASE_AUTH` on the no-cost Spark plan. No billing account has been attached and no web-project data was copied.

The dedicated worker [piyali-ios-api](https://piyali-ios-api.robotsbuildingeducation.workers.dev/health) is deployed with issuer/audience and app ID bound to this project. It requires App Check and a single-use Nostr challenge before returning a Firebase custom token whose UID is the learner's npub. The native app uses FirebaseAuth before loading or saving progress. `Backend/firestore.rules` and indexes have been deployed only to `piyali-ios`.

A normal native simulator launch also completed FirebaseAuth sign-in and displayed “Synced with Firebase” after saving through the deployed rules.

A live ephemeral-identity check passed App Check exchange, wrong-key rejection, successful Firebase custom sign-in, replay rejection, own progress read/write, cross-account HTTP 403 and subscription-forgery HTTP 403. The test auth account was removed; the temporary root fixture was removed using the project administrator after the check, because production clients cannot delete root accounts. Emulator tests additionally cover anonymous access, enumeration and protected subcollections.

Development App Check token and Firebase service-account signing key are stored in `.secrets/` with owner-only permissions and excluded from Git. Cloudflare holds the signing key as encrypted worker secrets. To run the native simulator with the registered debug token, set `FIRAAppCheckDebugToken` in the app's launch environment using the token in `.secrets/app-check-debug.json`; do not commit a shared Xcode scheme containing it. App Attest for production awaits enrollment in the Apple Developer Program; the signed-in account currently shows the enrollment prompt and no membership Team ID.

Gemini Developer API was enabled after explicit user approval of its additional terms and usage policies. Firebase AI Logic requires App Check and Firebase-authenticated users. Optional AI monitoring remains disabled. No billing account was attached; Agent Platform/Vertex remains disabled. Native configuration selects `googleAI`, `gemini-3.5-flash-lite` and the provider-specific `gemini-2.5-flash-native-audio-preview-12-2025`. The latter matches the web app's 2.5 native-audio model through the Developer API's model naming.

The native Cloudflare worker now provides an authenticated Responses endpoint, using the existing server-side API key stored as a new worker secret. Live testing generated a valid Spanish exercise; tests reject untrusted identities and oversized/model/tool overrides. The native Swift integration test independently verified Firebase sign-in, Gemini text and JSON, Cloudflare exercise generation, signed web restore and 24 kHz PCM audio output using the app's actual voice configuration.

Remaining integration work: production App Attest registration, audio-cache and alternate voice transport. The old web worker validates the old Firebase project and cannot accept this project's App Check tokens.

The main app's web subscription link still points to `piyali.app/subscribe`. The existing web subscription API is independent of native learner storage. Live tests verified the signed restore challenge, unlinked-key denial and replay rejection, and Swift validates the exact restore action and expiry before signing. No paid membership was created; active-member restoration remains a sandbox/manual verification gate. StoreKit products and Apple signing setup remain separate requirements.

Daily goal preparation uses owner-only `questDays` documents. The deployed native rules include this collection, with emulator coverage for owner access and other-user/unauthenticated denial.

Daily quest/tutor update: owner access now includes `tutorLanguageLessons`, `voiceJourney` and its per-day `completions` receipts. Production rule emulator checks passed before deploying these rules to `piyali-ios`. The original web project and its rules were not changed.
