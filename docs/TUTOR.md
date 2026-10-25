# Native Tutor correction in progress

The main Tutor menu now opens the voice lesson itself. The previous text form and separate “Live voice conversation” link are no longer the ordinary Tutor entry. Focused Goal/repair Tutor still use their older renderer and are not covered by this correction.

The native course is exported by executing the reference's actual lazy `loadLearningPath` builder without writing into that checkout. It retains 8,750 lessons in 14 practice languages and seven levels, including the introductory unit, colors, launch modes, Tutor purpose, target forms and capability evidence. The ordinary skill-tree export remains separate. The source introductory record deliberately keeps raw `xpRequired:0`; Tutor's own source helper derives its 50-XP requirement.

`export-tutor-policy.mjs` extracts original pure declarations and prompt builders into an isolated JavaScriptCore policy. Swift owns the screen, transport, grading sequence and storage. Explicit snapshots replace React refs and store reads; no source UI, Firebase or provider code runs in the app. Manifests record source hashes and adapter boundaries. There are 307 source-executed comparisons covering introductory/regular content, prompts, agendas, quizzes, paths, voices, transcript matching, translations and reconnect state.

The ordinary native flow now includes:

- Source lesson header, XP wave, orb, latest assistant bubble, translated phrase pairs, replay control, chat log and shared call dock.
- Source level/unit map and circular nodes; locked lessons remain previewable. The introductory preview has seven objectives. The actual source launch helper chooses game or voice; the main microphone Start always starts voice.
- An ungraded support-language welcome for a new introductory conversation, followed by its lesson kickoff. Fresh Start clears visible bubbles and retains prior conversation privately. Pause/Resume retains the visible transcript and mute choice; interrupted WebRTC output uses the source reconstruction instruction.
- Original local phrase checks and semantic judge prompts. Successful turns award 3–7 XP and independent Score; help, filler and uncertain results do not. Capability objectives require their own evidence even when a prompted warm-up phrase earns XP.
- Ordered agendas, XP-only repeated quiz rounds, capped own-lesson XP and a separate once-only completion bonus/Speak activity. Ordinary Tutor completion requires XP plus agenda; quizzes require XP alone. Legacy full-XP checkpoints can recover once. Games complete through Tutor's bonus path and cannot claim a skill-tree reward.
- Canonical `tutorLanguageLessons` records with schema-2 agenda/quiz state and bounded private drafts. Native hydration reads the target’s saved Tutor levels together so browsing another level retains its existing work; the source uses per-level subscriptions, so read-cost optimization remains. Completion deletes agenda/draft fields, preserves unrelated document fields and retries the same completion receipt before advancing. Source progress remains separate from skill-tree Lessons.

The authenticated Piyali Cloudflare worker forwards bounded source ASR language/prompt hints while retaining the fixed transcription model, voice/model checks, App Check/authentication, rate limits and manual turn policy. Deployed worker version: `e7322cc5-8312-4c3e-83b4-5f266119a3e6`.

## Verification boundary

The source/native fixture compares the actual read-only Tutor component in English/light and Arabic/dark. Only external provider, microphone and persistence I/O are replaced with public fixtures. Native screenshots use the production Swift views; scripted protocol events exercise the real native voice controller. Tagged native captures are converted to sRGB before comparison. These checks are not proof of pixel parity or physical microphone quality.

The current controller checks cover welcome, exact-answer deduplication, help/uncertainty/script rejection, capability evidence, repeated quiz rounds, private fresh reconnect, mute/pause/resume, stale-language judgments and completion retry. Core, simulator, Firebase SDK, live-provider and product-menu results are recorded in `VALIDATION.md` after their terminal runs.

Remaining Tutor work includes the source cross-course/monotonic Tutor-level unlock calculation and summary denominators, the focused Goal/repair renderer, guided-session completion handoffs, replay of the original recorded clip and prepared audio caches, late split-ASR burst recovery, precise translated-token behavior in streamed bubbles, full completion/review and all-level/locale visual journeys, and physical-device speech/audio routes. The RPG renderer also still needs its own source design pass. Blur, orb lighting, animation, sound and some modal geometry remain calibration work. The overall parity goal remains active.

## Current checkpoint evidence

- Complete Core baseline: 276 tests pass; final affected Core selection: 15 tests pass. The policy fixture contains 307 results executed from the reference declarations.
- Eight native Tutor controller checks and the six source/native component pairs pass. The controller checks include acknowledged completion → next lesson → seven-item review across the 300-account-XP boundary, plus failed-save retry without another bonus.
- The real product-menu Tutor journey passes (56.8s): introductory objectives expand, locked previews cannot start, welcome/voice/mute/pause/resume/history work, and relaunch starts with a clean visible transcript. The source-sized action targets include blank row space. The shared header now occupies its own layout row, leaving the lesson controls visible. Existing Conversation and Phonics product journeys pass after that shared layout change.
- Two real Firestore SDK checks pass: the new canonical Tutor counter/draft/quiz/completion contract and the previous Tutor agenda merge contract. The new check starts at 298 account XP, retains a full 7-XP turn while capping own XP at 50, saves one 50-XP bonus at 355 account XP, rejects duplicate receipts, clears draft/agenda fields, preserves a foreign Timestamp and records one Speak activity without a skill-tree completion. Its Pre-A1 record restores while another Tutor level is selected.
- The live native check passes (17.7s): original semantic prompts accept `hola` and reject a meta-question; source welcome/session, marin voice, ASR context, authenticated WebRTC, transcript, playback stop, incoming RTP and positive audio amplitude all succeed. The disposable authentication is removed and the check writes no learner progress.
- Backend: 23 tests pass and two unrelated opt-in rule checks skip. The worker version above is deployed. These checks do not verify a physical microphone, every CEFR path, or complete app parity.

[English entry comparison](native/tutor-idle-en.png), [Arabic entry comparison](native/tutor-idle-ar.png), [English path](native/tutor-path-en.png), [Arabic path](native/tutor-path-ar.png), [English preview](native/tutor-preview-en.png), [Arabic preview](native/tutor-preview-ar.png), [expanded preview in the real product](native/tutor-expanded-product.png).

The comparisons still show modal typography/spacing, some colors, icons and orb-rendering differences. They are retained as review evidence rather than a pixel-equality claim. Completed-lesson voice review also needs a separate session-agenda audit; a completed canonical record must remain completed while its review session advances.
