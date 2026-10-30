# Shared Help chat correction

The product menu and RPG Help button now open the same native bottom drawer. The previous full-page assistant form, invented translation toggle, speech dictation and save-to-Notes action did not reproduce the source `HelpChatFab`. The drawer retains its current conversation when closed and reopened, with a separate saved-chat menu and morpheme mode.

## Original behavior and private storage

Ordinary questions use the actual support-language instruction and the last six prior messages, followed by the new question exactly once. Replies stream into their own message; Stop preserves partial text and rejects late chunks. The source `// ` line becomes a separate practice-language gloss. Errors retain the question and any received text. The root supplies the learner's selected level, support/practice languages, translation preference and saved help focus; the RPG supplies only its original two language props, retaining the source beginner fallback.

Saving creates a separate snapshot, titled from the first user message and limited to 20 chats. The menu can load or delete those snapshots or start an empty conversation. Saved chats and the morpheme preference persist in an account-scoped, protected local archive. They do not become Notes, learner progress, rewards, Firestore records or Nostr posts. Unsaved conversations remain in the mounted controller and are not restored after app termination. Account changes clear the current transcript and load only that account's archive. Language changes keep the conversation and cancel in-flight text so a late reply cannot replace the active language.

Morpheme mode uses the original two-stage protocol: determine translation direction and target-language wording, show the translation prefix, then stream a breakdown of exactly that wording. The original breakdown detector triggers a non-streaming retry when needed. This mode does not add ordinary conversation history to either prompt.

## Native presentation and voice

The drawer uses the source 90-percent height, paper/midnight palette, 48-point top frame, header controls, centered empty composer, message/gloss treatment and 280-point saved-chat menu. Source icon SVGs and the small accessible morpheme switch are bundled. Mixed Arabic/Latin messages retain the original drawer’s left-to-right paragraph context while preserving Arabic shaping. Markdown supports paragraphs, emphasis/links, headings, lists, quotes, fenced code and simple tables. Complex/nested Markdown, exact motion and wider device layouts remain calibration work.

The microphone starts the original OpenAI realtime Help session with the source support-language instructions, ash voice, 2-second VAD pause and no automatic greeting. It is a voice conversation, not dictation. Incoming turns use the shared native controller's stable IDs and delayed-transcript ordering without learning credit. The original event policy supplies the 15-second idle, 25-second waiting and 45-second speaking watchdogs. Closing, backgrounding or changing ownership stops audio and fences late callbacks. Replay uses the existing receive-only source narration service; the active microphone cue follows native audio amplitude. Control sound cues, physical microphone/route behavior, the exact four-band browser waveform, cached/prepared narration and broader replay/interruption layouts remain verification work.

## Evidence and limits

`scripts/export-help-chat.mjs` extracts pure original callbacks, copy, session settings, event deadlines, morpheme helpers and icon SVGs without starting React, Firebase, stores, providers or browser storage. The manifest records source hashes. All 746 source-executed policy cases pass. The full Core suite passed 296 tests; the final deadline fixture extension also passes its focused Core check.

Four native controller checks cover shared prompt/history streaming, failure, cancellation/account fencing, the morpheme retry pipeline, saved-chat limits/restoration and late voice ordering. Two Help voice checks cover the original session/listen-first behavior, idle closure and all three source deadlines with canceled timers. The English/light and Arabic/dark reference test captures the actual source component and native drawer in empty, transcript and saved-menu states. Its public source fixture replaces only external provider/audio/sound I/O and uses an isolated local origin.

The real product journey covers menu entry, streaming, save/new/load, close/reopen, morphemes, relaunch restoration, errors, Stop and deletion. The actual course journey also opens/closes Help before continuing its existing distant-object, retry, speech, resume and once-only reward checks. Current run results, captures and the opt-in live provider boundary are recorded in [VALIDATION.md](VALIDATION.md).

These checks establish the named paths, not complete main-product parity. The reference checkout and backend deployments remain unchanged. [PARITY_AUDIT.md](PARITY_AUDIT.md) retains the wider requirements.

Comparison examples: [English transcript](native/help-transcript-en.png), [Arabic transcript](native/help-transcript-ar.png), [English saved menu](native/help-menu-en.png), [Arabic saved menu](native/help-menu-ar.png). Product captures: [drawer](native/help-product.png), [morphemes](native/help-morphemes-product.png), [error](native/help-error-product.png).
