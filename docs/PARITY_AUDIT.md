# Main-product audit

The reference checkout is read-only. Scope covers the main `/` learner product and subscription; `/citizenship`, `/links`, `/orbing`, `/squircle` and other external products are excluded. The actual web payment route is `/subscribe`.

The native screens cover the main path modes in `App.jsx`: daily plate, lessons, flashcards, alphabet/phonics, conversations and tutor. The lesson activity switch also maps realtime speech, stories, reading, grammar, vocabulary and games to native screens. Notes, history, goals, companion memory/repair, private/public teams, community milestones, achievements, wallet and subscription have dedicated implementations and validation documents.

## Findings and native equivalents

- **Final quizzes:** the omitted metadata has been restored for all 1,246 quizzes. Native rounds implement the original counts, early outcomes, resume/retry and completion gating. See [FINAL_QUIZZES.md](FINAL_QUIZZES.md) for implementation and verification boundaries.
- **Random practice:** the source's random activity pool is available as Surprise practice, using speaking, stories, grammar, vocabulary and reading. Shuffle starts a fresh activity without changing learner settings.
- **Assistant and feedback:** the Tutor provides typed/dictated questions and spoken responses; activities offer feedback and saved notes. Native screens replace the web drawer and action-bar presentation.
- **Public milestones:** native progress posting uses an explicit preview/confirmation. The browser's automatic XP-publication preference is not carried into a new native account; public sharing remains opt-in.

The first functional build implements the learner activities and content in the reviewed main entry points. This audit does not claim identical browser transports, visual interactions or storage behavior. The initial request defers design; release distribution is subject to the setup below.

## Setup and validation boundaries

The separate Firebase project and Cloudflare worker are provisioned. Development App Check, authenticated text/audio, private progress and teams have live checks. An enrolled Apple Developer account is still needed for release signing and production App Attest. App Store Connect products, active paid-member restoration and physical iPhone microphone/playback remain external validation steps. No enrollment purchase, real financial transfer or public test post has been made.

The UI uses ordinary SwiftUI controls. Alternate browser transports (NIP-07, legacy NIP-04, client-generated signer QR, OpenAI WebRTC and Cloudflare audio cache) are not native equivalents of additional learner activities; supported native Nostr signers and Gemini Live provide the implemented paths. Voice recording files remain local; private note/draft snapshots use last-writer-wins synchronization. These limits are documented rather than represented as verified cross-device behavior.
