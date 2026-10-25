# Memory and Voice Journey checkpoint

The product Memory panel now uses the original bottom drawer and four tabs: Repairs, Goals when a goal exists, Notes, and Journey. It replaces the earlier generic notebook form. This is a scoped parity checkpoint; the whole app is still in progress.

Repairs retain the source's today/yesterday grouping, reinforced records, status/source/severity badges, answers, corrections and support-language explanation guards. The original enrichment and digest prompts/parsers run through the native policy interpreter. Digest caches belong to an account, practice language, support language and day. A repair arriving during generation schedules another pass. Localization updates preserve concurrent reinforcement, severity, unknown fields and Firestore timestamp values, without another XP grant.

Goals shows the saved goal, demonstrated capabilities, open capabilities, useful language and today's objective/rationale. Notes filters the current practice language, groups saved examples by CEFR level and retains the original example, explanation, lesson, module, date and result. Answered exercises now generate the original study note instead of storing a generic question/answer blob. Expand, Listen, Delete and language-only Clear all use normal product controls. Earlier manual native notes remain accessible separately. Study notes still use private snapshot synchronization; simultaneous edits remain last writer wins.

Journey follows the source's 1, 5, 15, 30, 45, 60, 90, 120 and 150 session milestones, expiry windows and earliest-recorded baseline. Only a fully completed daily plate counts, using the existing durable per-language/day receipt. The automatic prompt waits for a quiet 1.5 seconds after the existing modal chain, acknowledges its milestone and routes View Journey to the drawer. Dismissing the prompt leaves manual recording available.

Recording creates a private temporary draft, capped at 45 seconds. Preview and Record again precede explicit Save. iOS records AAC/M4A; the isolated test transport supplies a public WAV. Save uses a random AES-256-GCM key, authenticated to the account/language/milestone, wrapped through the learner's self NIP-44 signer. Firestore stores the encrypted envelope at `users/<npub>/voiceJourney/<language>/recordings/<milestone>` and only dates/session counts in the parent metadata. Duplicate and expired saves fail transactionally. Listen compares the current clip with the earliest recording; Delete removes both document and metadata. Existing local recordings from the earlier native build remain playable/exportable without automatic upload.

Owner-only recording rules were tested against unauthenticated, anonymous, public-demo and other-account access, then deployed only to the independent `piyali-ios` Firebase project. The reference web project was not changed.

## Verification

- The read-only exporter executes 55 actual source copy, prompt, parser, language-guard and Journey cases. Native milestone/baseline/pending/expiry checks cover counts 0–160, saved histories and legacy count/prompt values.
- A public interoperability vector is produced by the actual source encryption module and `nostr-tools`. Native tests open its AES-GCM payload, verify matching ciphertext, reject altered bindings/tags and unwrap its self NIP-44 key with the native identity. The vector's declared all-01 test secret is never a learner identity.
- Real Firestore SDK emulator transactions verify encrypted save/load/delete, duplicate/expired rejection, acknowledgment, unchanged counts, preserved foreign fields and concurrent repair localization/retry behavior.
- Product UI journeys cover repair/goal content, note accordion/delete/clear/relaunch, an answered exercise generating a note and restoring it, recording/preview/encrypted save/baseline comparison/delete/relaunch, and automatic prompting/acknowledgment/View Journey/relaunch. The existing guided daily-practice → reward sequence → Notes/relaunch journey also passes.
- Equivalent English/light and Arabic/dark screens render the actual source JSX in iPhone WebKit and native Swift. Only provider, account and recording I/O are public fixtures; source UI behavior is retained. Comparisons are reviewed visually rather than treated as pixel-equality assertions.

## Remaining work

Physical microphone/playback/routes, Chrome WebM/Opus recording import, device/signer interruption recovery, all locales and text sizes, exact motion/sound timing and broader combined modal interruptions and Journey prompting across the root trial boundary remain unverified. The native audio slider and file exporter retain platform controls. This checkpoint does not establish design parity for Settings, teams, achievements, wallet, subscription or RPG, or close the remaining activity-specific gaps in the main audit.

[Repairs, English](native/memory-repairs-en.png), [Goals](native/memory-goals-en.png), [Notes](native/memory-notes-en.png), [Journey](native/memory-journey-en.png), [recording](native/memory-record-en.png), [Arabic Notes](native/memory-notes-ar.png), [Arabic recording](native/memory-record-ar.png).

Product captures: [generated exercise note](native/memory-note-created-product.png), [automatic prompt](native/journey-prompt-product.png), [private preview](native/journey-preview-product.png), [baseline comparison](native/journey-compare-product.png).
