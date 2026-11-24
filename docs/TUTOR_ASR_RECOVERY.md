# Tutor unexpected-script recovery — 2026-11-05

This is a bounded FUNC-03 correction against read-only reference `b269524ddc578027c549616fc47f5954991d9f6f`, starting from native `1ac151fd72ac0913df067c11ce840ed24bf1c45d`. It does **not** close split/late valid-transcript grading, connection configuration fallback, all Tutor design, physical voice, or the overall parity goal.

## Source and observed mismatch

The actual main-product `src/components/Tutor.jsx` handler accepts both `conversation.item.input_audio_transcription.completed` and `input_audio_transcription.completed`. It rejects a transcript whose script lies outside the target/support language policy **before** learner chat, Goal evaluation, XP/slip grading or notes. It attempts `conversation.item.delete` for an available item ID. If the assistant is already replying, it leaves the reply alone. Otherwise `requestTutorTranscriptRecovery` locks local input and requests a short retry of the current phrase in the support language, with `metadata.kind=tutor_transcript_recovery`. The source OpenAI bridge subsequently adapts the wire dialect and composes its compact voice policy. The instructions explicitly forbid correction, praise, progress and mistake recording. A transcription failure simply resumes listening.

Native previously had a combined script/meaningful/duplicate guard that only discarded input. The microphone reopened without deleting the item or asking for the same phrase. Its shared voice service accepted only the longer event name and exposed a generic transcription-failure error card in Tutor.

The reproduction uses an English-supported Spanish starter task and public synthetic transcript `नमस्ते`. `/tmp/PiyaliTutorASRRecoveryReproductionCorrected20261105.xcresult` fails six assertions in one test (4.529s): missing deletion/recovery, no recovery phrase, listening instead of thinking, and an enabled microphone. The earlier `Reproduction20261105` bundle exited 70 before running because the command used the folder name `PiyaliAppTests` instead of test target `PiyaliTests`; it is not a product result. The initial correction passes the reproduction in `/tmp/PiyaliTutorASRRecoveryFirstFix20261105.xcresult` (4.183s).

## Implementation and boundaries

- The existing target-owned exporter now includes the **original** `requestTutorTranscriptRecovery` function and its dependencies. Timer/UI/lock callbacks are inert and its channel only captures the original event; Swift owns the actual input gate and transport. The regenerated source policy corpus has 651 cases, including ordinary starter/regular lessons and Goal/repair recovery prompts across representative targets/support languages.
- Native rejects the transcript before adding a user message, grading, XP, notes or progression. The rejected text is also removed from the shared live transcript. A failed context-delete attempt is ignored as in the source; it must not terminate the lesson.
- The original Gemini bridge ignores unsupported context-item deletion; its native adapter now accepts that no-op so the recovery request stays connected. OpenAI receives the actual delete event. This does not claim Gemini can retract already transmitted audio from its SDK context.
- Response activity is captured when the input callback arrives, before scheduling its task. Rejection during an existing reply cannot interrupt that reply or reopen its microphone. Existing account/language/epoch, pause and completion fences remain.
- Recovery during the welcome phase does not consume the pending ungraded greeting. Its assistant reply is not tagged as a welcome message; the next real greeting still starts the lesson without XP.
- Both transcription event spellings are accepted. Tutor failures return to listening without an error card; Conversation retains its existing explicit failure message.

## Verification and visual evidence

The intermediate `/tmp/PiyaliTutorASRRecoveryIntegration20261105.xcresult` ran 55 tests in 187.126s: 54 passed, including the two-language rendered comparison (30.363s), and one failed a fixture expectation that the next starter phrase was “¿Cómo estás?”. The original authored agenda and recovery function actually select “me llamo” after “hola”; the assertion and public assistant prompt were corrected. No product logic was changed to satisfy that mistaken expectation. The final `/tmp/PiyaliTutorASRRecoveryVerified20261105.xcresult` passes all **55 app checks** in **191.282s**, with zero skips: 32 Tutor session checks (184.687s), 12 shared voice-controller checks and 11 Gemini transport/audio checks. Its rendered original-source comparison passes in **27.426s**. Both full native UI journeys also pass in **107.020s**: the new signup → Tutor → rejected-speech recovery → End/history → private relaunch journey (51.060s), and the existing entry/path/locked-preview/welcome/mute/pause/resume/private-relaunch regression (55.960s). The read-only final UI snapshot audit confirms zero XP, graded attempts, notes, Memory records, Tutor-turn/completion receipts and earned Tutor XP; the recovery cue remains in the private draft and the rejected text is absent.

After that full run, a source bridge review identified the retained OpenAI dialect requirement: its bridge removes legacy `modalities`, selects `output_modalities:["audio"]`, and wraps the recovery task with the compact bilingual prefix/suffix. Native now applies that normalization only to the OpenAI profile, using the original composition helper. The original Gemini event stays unchanged. An explicit before/after audit verifies **600 prior cases unchanged, 33 intended OpenAI recovery adaptations, and 33 forced Gemini recovery cases unchanged**. No live OpenAI context-deletion or acoustic result is claimed for this checkpoint. `/tmp/PiyaliTutorASRRecoveryDialectFinal20261105.xcresult` passes all **four final app checks in 31.966s**, zero skips: actual source/native English/Arabic comparison (27.316s), pre-welcome/current-agenda recovery, Gemini socket continuation, and both event spellings/Tutor-vs-Conversation failure behavior. The final policy-only correction changes no Swift production logic, default Gemini response or view presentation. The source comparison renders the unmodified Tutor component under its original theme/CSS, with explicit public protocol input replacing only external I/O. Native renders `SourceTutorView` and its real shared activity dock. Both completed and late-script cases use explicit normalized protocol IDs; the separate native Gemini socket test exercises the bridge’s own synthesized input IDs and unsupported delete no-op. These are 402×874 component viewports with no surrounding ProductShell menu reservation; they are not a claim of whole-product viewport parity. Inspected pairs retain visible differences in source edge glow, orb rendering/compositing, replay/control glyphs, panel shadow and some shell geometry; passing state/copy checks do not close those design gaps. Synthetic speech is injected, and recovery replies are public scripted text, not a live provider or acoustic result.

### Captures and audit

[`native/tutor-asr-recovery-b269524d/manifest.json`](native/tutor-asr-recovery-b269524d/manifest.json) records **27 SHA-256 artifacts**, source/native implementation hashes, exact run scopes and the failed reproductions. The final four-test run supplies twelve original component PNGs and four public trace JSONs; six pairs convert embedded source/native ICC profiles to sRGB before resizing to logical points. The earlier wholly passing 57-test bundle supplies three full native journey PNGs. The scoped read-only QA audit and explicit policy-dialect audit complete the artifact set.

- [Waiting for the retry cue, English/light](native/tutor-asr-recovery-b269524d/pair-waiting-en.png)
- [Retry cue, Arabic/dark](native/tutor-asr-recovery-b269524d/pair-retry-ar.png)
- [Actual product recovery screen](native/tutor-asr-recovery-b269524d/native-product-recovery.png)
- [Read-only QA counters](native/tutor-asr-recovery-b269524d/qa-audit.json)

The full native journey’s provider translation is deliberately marked **Public fixture translation**; that label is injected test content, not shipped copy or proof of provider translation. No real Firebase learner or public relay write was used. Native Firebase/Cloudflare configuration remains separate and unchanged. The owned preview was stopped, and the three unrelated historical manifests regenerated by its launcher were restored to their original bytes.

### Commands and Core result

One Swift test/build ran at a time, with the same process polled to terminal. The regular simulator and reference checkout were not modified. Source preview is served from the native checkout’s isolated Vite cache with `node scripts/start-reference-preview.mjs`.

```sh
swift test --filter 'RealtimeVoiceTests|TutorSourcePolicyTests|GeminiTutorBridgeTests|TutorSourceProgressTests'

TEST_RUNNER_PIYALI_OFFLINE_TESTS=1 \
TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1 \
TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)" \
PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 \
scripts/test-ios.sh -parallel-testing-enabled NO \
-only-testing:PiyaliTests/TutorSessionTests \
-only-testing:PiyaliTests/RealtimeVoiceControllerTests \
-only-testing:PiyaliTests/GeminiTutorTransportTests \
-only-testing:PiyaliUITests/TutorParityTests \
-resultBundlePath /tmp/PiyaliTutorASRRecoveryVerified20261105.xcresult
```

The final Core run passes **13 tests in 13.742s** with zero skips. It includes the original bridge trace comparison, repeated-rejected-event privacy, both protocol spellings, the 651-case policy corpus and Tutor progress. Log: `/tmp/piyali-tutor-asr-recovery-core-final-20261105.log`.

## Remaining work

Valid split/late transcripts still need the reference's silent per-turn XP pipeline, duplicate suppression and quiz/welcome exclusions. Rejected-setup connection retries omitting transcription/selected voice remain open. The source's live narration, microphone/route/Bluetooth/background behavior, full viewport/history composition, orb/raster/lighting, long text/progress badge states and accessibility still require their own comparisons. All other unresolved handoff rows remain open.
