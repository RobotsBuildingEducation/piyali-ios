# Native implementation validation

Verified locally with Xcode 26.4.1 / Swift 6.3.1 on an iPhone 17 Pro simulator running iOS 26.4.1. The minimum deployment target remains iOS 17.

- `swift test`: **18 tests passed**, including all 14 bundled curricula, 1,150 flashcards and 1,190 phonics decks, daily reset/streaks, language-specific XP, idempotent lesson rewards, answer normalization, persistence/migration, companion unlock rules and performance score boundaries. The scheduler test compares **116 cases** exported directly from the reference web algorithm, covering learning steps, hard/easy intervals, graduation, legacy records and lapses. Additional tests cover offline calendar days, in-flight practice/preference edits and zero-XP answer reveals.
- Xcode `PiyaliTests` with the local Firestore emulator: **9 tests passed**. Two verify Schnorr signatures, tampering rejection and a web-signed deletion fixture. Seven exercise the real Firestore SDK and native sync service against copied reference rules: first account upload, shared XP visibility, duplicate retries, concurrent lesson completion, scheduler graduation/restoration, offline calendar history and stale preference requests. Existing subscription fields, unrelated web settings and migration markers survive these writes.
- Xcode `PiyaliUITests`: **1 smoke test passed**, exercising offline account/onboarding, answer reveal and persisted review scheduling after terminating/relaunching, flashcard navigation, note creation/persistence and the locked tutor screen.
- `npm test --prefix BackendReference`: **4 tests passed**, accepting the web and native App Check IDs and rejecting unrelated IDs, wrong audience and expired tokens.
- `git diff --check`: passed.

Run the isolated emulator suite with `scripts/test-firestore.sh` (Firebase CLI and Java 21 required), or start the emulator and run `TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1 scripts/test-ios.sh` for the complete simulator suite. The wrapper chooses an available iPhone simulator; `PIYALI_TEST_DEVICE` can select a UDID. `PIYALI_SOURCE_PACKAGES` optionally reuses an existing Xcode package cache. CI runs the core/backend tests, simulator build and opt-in Firestore suite.

The demo project is `demo-piyali-ios`, with Firestore at `127.0.0.1:8180`. Tests create a named Firebase app using emulator-only configuration and a test-only App Check provider. They do not initialize the production Firebase app, disable production App Check, deploy rules or write to a production database. A simulator configuration issue was fixed by assigning the local host before disabling SSL; no compiler workaround or deployment-target change was retained.

Xcode simulator tests must use ordinary/ad hoc signing (`CODE_SIGN_IDENTITY=-`). Disabling signing caused Keychain error -34018; signed runs pass. No in-memory fallback or Keychain bypass was added.

Live Firebase/Cloudflare calls, production App Check, deployed Firestore indexes, real Patreon linking, StoreKit purchases, relay publication and physical-device speech/audio were not certified by these tests. The native Firebase app has not been provisioned. Cloudflare's deployed App Check allowlist and App Store products still require setup described in `BACKEND_SETUP.md`. No production backend was deployed or modified.

Snapshot-only notes/history/goal details, full pet health decay and achievement reconciliation remain outside the shared-progress contract tested here. The feature boundaries in README still apply.

The reference repository retained its pre-existing change to `nosabos/src/components/LinksPage.jsx`; this task made no edits there.
