# Main-product audit

The reference checkout is read-only. Scope covers the main `/` learner product and subscription; `/citizenship`, `/links`, `/orbing`, `/squircle` and other external products are excluded. The actual web payment route is `/subscribe`.

The native screens cover the main path modes in `App.jsx`: daily plate, lessons, flashcards, alphabet/phonics, conversations and tutor. The lesson activity switch also maps realtime speech, stories, reading, grammar, vocabulary and games to native screens. Notes, history, goals, companion memory/repair, private/public teams, community milestones, achievements, wallet and subscription have dedicated implementations and validation documents.

## Open implementation findings

- **Final quizzes:** `skillTreeData.js` retains `isFinalQuiz` and sometimes `quizConfig` (default ten questions, eight correct). The source GrammarBook and Vocabulary accumulate answered/correct counts and can fail early. `scripts/export-content.mjs` currently omits these fields, and `LessonView`/`ExerciseView` treat these lessons as ordinary skill practice. Preserve the metadata and implement resumable quiz rounds, failure/retry and completion gating before calling the functional port complete. Unit game reviews are separate and already implemented.
- Continue the main-product audit after closing the quiz gap; this document records reviewed entry points, not a blanket parity claim.

## Setup and validation boundaries

The separate Firebase project and Cloudflare worker are provisioned. Development App Check, authenticated text/audio, private progress and teams have live checks. An enrolled Apple Developer account is still needed for release signing and production App Attest. App Store Connect products, active paid-member restoration and physical iPhone microphone/playback remain external validation steps. No enrollment purchase, real financial transfer or public test post has been made.

The UI uses ordinary SwiftUI controls. Alternate browser transports (NIP-07, legacy NIP-04, client-generated signer QR, OpenAI WebRTC and Cloudflare audio cache) are not native equivalents of additional learner activities; supported native Nostr signers and Gemini Live provide the implemented paths. Voice recording files remain local; private note/draft snapshots use last-writer-wins synchronization. These limits are documented rather than represented as verified cross-device behavior.
