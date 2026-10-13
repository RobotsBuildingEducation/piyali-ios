# Validation of the initial native implementation

Verified locally with Xcode 26.4.1 / Swift 6.3.1 on an iPhone 17 Pro simulator running iOS 26.4.1.

- `swift test`: **10 tests passed**, including all 14 bundled curricula, 1,150 flashcards and 1,190 phonics decks, daily reset/streaks, language-specific XP, idempotent lesson rewards, answer normalization, persistence/migration, companion unlock rules and performance score boundaries.
- Xcode `PiyaliTests`: **2 tests passed** for Schnorr signatures, tampering rejection and a deletion event fixture signed by the web app's `nostr-tools`, including its single-element tag and Unicode content.
- Xcode `PiyaliUITests`: **1 smoke test passed**, exercising offline account/onboarding, flashcard navigation, note creation, persistence after terminating/relaunching and the locked tutor screen.
- `npm test --prefix BackendReference`: **4 tests passed**, accepting the web and native App Check IDs and rejecting unrelated IDs, wrong audience and expired tokens.
- `git diff --check`: passed.

Xcode simulator tests must use ordinary/ad hoc signing (`CODE_SIGN_IDENTITY=-`). Disabling signing caused Keychain error -34018; signed runs pass. No in-memory fallback or Keychain bypass was added.

Live Firebase/Cloudflare calls, real Patreon linking, StoreKit purchases, relay publication and physical-device speech/audio were not certified by these tests. The user has not yet provisioned an iOS Firebase app. Cloudflare's deployed App Check allowlist and App Store products still require setup described in `BACKEND_SETUP.md`. No production backend was deployed or modified.

The reference repository retained its pre-existing change to `nosabos/src/components/LinksPage.jsx`; this task made no edits there.
