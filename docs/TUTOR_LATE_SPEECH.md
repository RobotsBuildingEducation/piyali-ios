# Tutor late valid speech — 2026-11-05

This continues FUNC-03 against read-only reference `b269524ddc578027c549616fc47f5954991d9f6f`, from native `9ec3bf05c02e569df2a3b0c66ebd12928ceb47db`. It does not close source setup fallback, full-duplex original-audio capture, physical microphone/routes, all design/accessibility or the overall parity objective.

## Source behavior and reproduction

The actual `Tutor.jsx` transcript handler rejects unexpected scripts first, then handles valid speech arriving after `response.created` without adding a user message or requesting another tutor response. It updates the two-second exact-text duplicate window and invokes the original `gradeLateTutorUserTranscriptForXp`. That helper ignores pre-practice, pending-welcome and final-quiz input. A local match applies progress immediately; other meaningful attempts use the existing background semantic judge. XP is deduplicated by the **existing** practice turn. Regular agenda advancement is independently limited to that turn. Starter items can advance separately when another correct phrase arrives in the same turn, without another XP award. The source still permits a semantic slip to enter Memory and uses the original turn’s question/assessment ID. Completion is signaled when earned, with its finish deferred until idle (bounded at 45 seconds).

Native previously treated these events as ordinary new user turns. `/tmp/PiyaliTutorLateSpeechReproduction20261105.xcresult` reproduced extra chat, extra response requests, double XP/assessment, late history/draft pollution and a duplicate changing speaking to listening. Its one test reported eight failed assertions in 4.612s; one was a new fixture typo (`name` instead of the authored `myNameIs`) and was corrected. The first correction passes the two focused late/rejected-script checks in `/tmp/PiyaliTutorLateSpeechFirstFix20261105.xcresult` (8.335s).

## Implementation

- The target-owned exporter now executes the **original** late-transcript helper with explicit practice/welcome snapshots and capture-only local-progress/background-judge adapters. Its early exclusions and local/semantic classification are not a new Swift approximation. Swift retains audio, provider, storage and UI ownership.
- Source comparison exposed and corrected a second startup mismatch: saved starter XP/agenda/private context starts with a fresh tutor-led agenda turn, not another ungraded welcome. A genuinely fresh tutorial retains its ungraded welcome.
- Tutor no longer closes or clears input merely because a speech burst was committed. It keeps the source’s lightweight thinking state until a manual response is requested, closes the local mic at that request, and disables VAD at `response.created` without clearing already-committed/split speech. Explicit mute still clears input. Conversation retains its original commit lock.
- The callback snapshots reply activity, the current practice turn, original grading question and source prompt context before scheduling its task. A streamed follow-up is included in the prompt snapshot; the assessment still belongs to the question the learner answered. Old account/language/lesson/epoch results cannot commit.
- Late speech shares the existing phrase/semantic policy and receipt path. It does not append chat, saved conversation drafts or ordinary visible history, create another practice turn, send another response, or reopen the microphone on duplicate/empty input. XP, assessment and regular agenda each have their own per-turn dedupe. Additional starter progress is persisted even when the turn’s XP was already paid.
- Semantic mistakes preserve the source’s provider-specific Memory rule: Gemini may retain a low-confidence slip; OpenAI requires 0.55. The per-turn rating outcome is retained once even if a later burst earns XP. This is source behavior, not a claim that a prior incorrect rating is revised to correct.
- Earned late completion retains root ownership before crossing the 300-XP gate and waits for native playback to drain, with the source’s 45-second ceiling. Explicit Pause/End closes audio and settles already-earned completion; stale owner changes cannot finish a replacement task. Ordinary hydrated earned checkpoints retain their existing restart/retry path. Focused session durability beyond the existing source-shaped ephemeral record remains a wider persistence gate.
- The source wave palette (`#43e97b` → `#38f9d7`), 15-point height, white 0.8 background, `#ededed` inset border and original 0.8-second fill easing replace the old blue/static Tutor bar. These were confirmed from actual progressed source/native captures and `WaveBar.jsx`, not inferred from the ready 0% state.
- The progress badge now includes the original header’s horizontal insets so multi-digit percentages can grow naturally. The prior fixed-width badge only matched the 0% ready state. Source/native captures and remaining design differences are recorded with the final verification below.

## Verification

The intermediate `/tmp/PiyaliTutorLateSpeechBoundaries20261105.xcresult` ran 51 checks: 50 passed and the explicit source-preview test was skipped because that run did not opt into the preview. It includes the rendered trial gate/save retry (5.805s), six owner replacement boundaries (24.934s), semantic streamed-prompt and late Memory checks. `/tmp/PiyaliTutorLateSpeechSourceAndJourney20261105.xcresult` then passed the full native late-speech journey (52.351s) but failed the new source comparison waiting for a welcome on the resumed 45-XP starter. Inspection of the original `requestTutorLessonKickoff` proved it sends a kickoff instead. Native startup and the shared scenario were corrected; this failed comparison is retained as evidence, not counted as a pass.

The final Core run passes **14 tests in 18.806s** with zero skips, including **831 executed source policy cases**, original bridge traces and the configurable Tutor/Conversation input lock. Log: `/tmp/piyali-tutor-late-speech-core-20261105.log`. `/tmp/PiyaliTutorLateSpeechVerified20261105.xcresult` passes **64 app checks in 276.286s** and **all three full native UI journeys in 157.831s**, zero skips. This includes actual English/light and Arabic/dark source comparisons for fresh late credit and resumed 100% completion (43.477s), the rejected-script regression comparison (25.902s), ordinary/completed/Goal/repair/quiz, voice-controller and Gemini audio/transport checks.

`/tmp/PiyaliTutorLateSpeechFinalScopes20261105.xcresult` passes **three final scope checks in 73.576s**, zero skips. The source comparisons use a distinct disposable native identity per scenario so an old view’s asynchronous disappearance/draft callback cannot seed the next fixture (50.227s). The resumed trial fixture uses the actual kickoff phase (5.025s). Explicit Pause/End, a shortened injected idle timeout, owner replacement and subsequent hydrated earned-completion retry pass (18.324s); hydration never auto-connects.

After those runs, visual inspection identified the old blue progress bar. Only Tutor’s wave presentation and the screenshot-settle delay changed afterward. `/tmp/PiyaliTutorLateSpeechPresentation20261105.xcresult` passes the final original-source comparison (57.692s) and full native late-speech journey (52.148s), zero skips. The actual source badge widths are 43.15625 points at 10% and 49.765625 at 100% in both languages; native now grows naturally instead of retaining its old 38-point width.

### Evidence and limits

[`native/tutor-late-speech-b269524d/manifest.json`](native/tutor-late-speech-b269524d/manifest.json) contains **34 hashed artifacts**, current implementation/source hashes and explicit version scopes. The presentation bundle supplies twelve original component PNGs, six color-managed source-left/native-right pairs, eight public source/native traces and three full native journey PNGs. The final-scopes bundle supplies the trial-gate frame and close/timeout/hydration trace. That earlier trial frame deliberately retains the old blue bar and is labeled as such; its functional result is not presented as the final wave style. Read-only QA, unchanged-policy and presentation-delta records complete the set.

- [10% credit during the existing reply, English/light](native/tutor-late-speech-b269524d/pair-fresh-credited-en.png)
- [100% earned gate during the existing reply, Arabic/dark](native/tutor-late-speech-b269524d/pair-finishing-credited-ar.png)
- [Actual full native private history](native/tutor-late-speech-b269524d/native-product-history.png)
- [Read-only UI profile counters](native/tutor-late-speech-b269524d/qa-audit.json)
- [Close/timeout/hydrated recovery outcomes](native/tutor-late-speech-b269524d/native-completion-boundaries.json)

The scoped final QA profile has exactly one 3–7 XP turn receipt, one assessment, `hello` + `myNameIs` agenda progress, no late learner messages in the private draft, no bonus/lesson activity, no notes/Memory or late history entries. The source-policy audit verifies all 651 previous cases unchanged, with 180 new original late-input/objective cases added.

The paired captures use the actual original Tutor component/theme/CSS and actual `SourceTutorView` with the real activity dock, at 402×874 logical points. They omit the surrounding ProductShell/menu reservation; full native captures include it. Synthetic protocol input and scripted assistant text exercise real native controllers and views, not physical speech or provider acoustics. Full native fixture translations are public injected content. Visible source/native orb, feedback wash/edge glow, glyphs, panel/shadow and full-shell differences remain open. Original PNGs retain their bytes/ICC profiles; pairs explicitly convert to sRGB before resizing.

### Commands

Run from the native checkout, with the read-only preview started by `node scripts/start-reference-preview.mjs`. One Swift build/test was active at a time; every handle was polled to terminal. Only the isolated QA device was targeted; the regular simulator was untouched. Afterward the owned preview was stopped and the three unrelated historical manifests its launcher regenerates were restored to their original bytes.

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
-resultBundlePath /tmp/PiyaliTutorLateSpeechVerified20261105.xcresult
```

The final-scopes run used the same environment and selected `testOriginalLateBurstProgressAndCompletionGateAgainstRenderedNativeInEnglishAndArabic`, `testLateEarnedCompletionKeepsTheReplyAndTrialOwnerUntilPlaybackStopsThenRetriesOnce` and `testLateCompletionSettlesOnExplicitPauseEndAndTimeoutButRejectsAReplacedOwner`. The presentation run selected the first source/native test and UI `testNormalProductLateSpeechCreditsOnceKeepsChatPrivateAndRestoresProgressOnRelaunch`. Result bundles retain each exact command line; the artifact manifest distinguishes functional, test-only and final presentation changes. Public protocol/provider fixtures do not prove real microphone input or acoustic output. The separate native Firebase/Cloudflare configuration and the read-only source remain unchanged.

## Remaining scope

Source fallback connection configurations, original full-duplex OpenAI recording, interrupted partial PCM capture, wider completion/durability/interruption combinations, live/physical voice and full shell/orb/accessibility design remain open. The later [ordinary-turn checkpoint](TUTOR_ORDINARY_TURNS.md) supersedes this checkpoint's pending-worth, ordinary Gemini agenda and starter request/retry gaps. It separates immediate lesson/day progress from deferred account awards, preserves private earned delivery and verifies the original ordinary source flow on actual rendered components. Its exact Core/SDK/native/source/UI scopes and source hydration-race finding remain separate from the historical evidence above. Ordinary semantic Memory side effects, broader pending-quote termination/focused recovery, capture/setup fallback, physical voice and whole-product design remain open.

The later [semantic Memory checkpoint](TUTOR_SEMANTIC_MEMORY.md) applies the actual original judge side effects to ordinary and late turns, preserves original pending note fields and starts account-owned enrichment immediately. It adds ordinary successful/low-confidence and correction-fallback evidence; shared duplicate capture policy and process interruption during enrichment remain open.
