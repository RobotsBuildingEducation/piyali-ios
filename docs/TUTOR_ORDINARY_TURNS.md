# Ordinary Tutor turns and deferred question worth — 2026-11-05

Reference: read-only `RobotsBuildingEducation/nosabos` at **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native implementation base: `671c553`. This is a scoped FUNC-03 correction, not completion of the Tutor row or main-product parity.

## Behavior corrected

The original `Tutor.jsx` applies a locally accepted phrase before optional semantic grading or the original question-worth promise. Gemini advances the regular agenda on that local success. OpenAI can award the phrase while its separate objective judge decides whether to advance. For ambiguous Gemini answers away from completion, the next prompt starts while a background judge runs; a later successful verdict silently updates progress. The original near-completion gate and synchronous quiz path remain distinct.

Native now follows those sequences. Starter follow-ups execute the actual original `requestTutorTurnFollowup` → `requestRealtimeTutorAgendaResponse` → `buildTutorAgendaResponseInstructions`, including kickoff active-item initialization, retry counts, current-item resets and one-use private reconnect context. They no longer select the broader ordinary follow-up builder. Gemini uses the source's default follow-up verdict where the ordinary handler does; quizzes and OpenAI retain their explicit verdict. The retained OpenAI profile converts the source response dialect and composes its original bilingual voice policy.

A turn's lesson XP, agenda and daily XP now appear immediately. Account XP and the assessment wait for the **original question's** quote. The native worker owns an account-private saved intent with frozen question/level/target/user parameters and stable award/assessment receipt IDs. End or a language change cannot discard already-earned delivery; replacing the account/session rejects its late callback. A restored worker reuses those parameters, authenticates the current identity before a new remote assessment, and uses the original CEFR fallback on an outage. No private continuation is accepted from, or written into, the shared server snapshot hint.

Early lesson progress is a zero-XP Tutor-state receipt. Its later account award is marked as already recorded in lesson progress, preventing a second lesson increment. Canonical acknowledgment retires an already-delivered intent, or leaves only an undelivered assessment after a turn receipt. This avoids reapplying optimistic daily/companion XP on stale saves. XP and assessment dedupe remain independent: a late correct answer can earn its existing turn's XP after a failed assessment without grading that turn again.

Completion ownership is published before optimistic daily rewards. Lesson/Goal/repair completion waits for the earned award, preserves already-earned save retries, and does not leave the saving flag set after selecting the next lesson. A held final quote followed by End is checked through the acknowledged next-lesson handoff.

## Verification and evidence

The final Core run passes **28 tests in 31.155 seconds**, including **991 original-source policy cases**. All **831 previous cases are unchanged**; 160 new cases execute the original kickoff, follow-up and potential-completion helpers. Other checks cover serialized intents, partial/stale acknowledgments, independent late awards, language ownership, day/companion/streak projection and existing sync contracts.

`/tmp/PiyaliTutorOrdinaryAgendaVerified20261105.xcresult` passes **52 tests with zero skips**: 46 native Tutor model/rendered-flow checks, three actual source/native comparison methods, two real local Firebase SDK checks and one complete native UI journey. The 49-test Tutor suite takes 468.215 seconds; the SDK checks take 12.834 seconds together; the signup/setup → Tutor late credit → End/history → process-relaunch journey takes 55.398 seconds. No production, test or fixture source changes follow this passing combined run.

The final ordinary source/native comparison passes in **66.851 seconds**: starter and regular capability objectives in English/light and Arabic/dark, both while question worth is held and after delivery, plus a same-mounted English starter answer whose semantic judge is held and then succeeds in the background. Starter next-prompt instructions match exactly; all four source/native agendas match. The existing four-scenario late-credit comparison (65.921 seconds) and unexpected-script comparison (34.307 seconds) pass on the same final code. Native first/second starter rejections also match the original retry instructions after the kickoff installs its active-item state.

The source component can hydrate its conversation after connect under fast fixture timing, clearing the welcome flag or current question. A retained read-only phase trace proves that reset at original `Tutor.jsx:5346`. Final comparisons wait for the selected conversation identity to finish hydrating **before Start**. The final source transform adds only a read-only readiness getter; temporary hooks around assignments are removed. Reference files stay untouched, and the native greeting remains ungraded. This is prepared-component parity evidence, not proof that the source fast-start race is fixed in the full web App.

The SDK cases use the existing `demo-piyali-ios` emulator through the real Firebase SDK, not a fake progress service. They verify lesson-only early persistence, unchanged canonical account/day XP while worth is pending, private server-hint exclusion, one later award/rating, repeated/stale save idempotency and unchanged Tutor completion/activity semantics. A separate existing contract checks Tutor XP cap, private draft, quiz reset and completion retries beyond the trial boundary.

The native flow checks include Gemini local/background behavior, OpenAI objective gating, positive quiz feedback, held quote ordering, End/language/account replacement, serialized restoration with a fresh worker, late correction after a rated slip, ordinary/review/game/Goal/repair completion and failed-save retry. The new pending-worth restoration check decodes a saved state and creates a new worker; it is **not** a claim that an actual process was killed while that quote was pending.

[The artifact manifest](native/tutor-ordinary-b269524d/manifest.json) checks **52 hashed artifacts**: final combined-run captures/traces, separate Core/policy checks, a post-run QA audit and the explicitly retained failed-run hydration diagnostic. It includes original component PNGs, ten ICC-managed pairs, source/native traces, actual SDK counters, three full native journey frames, read-only QA audit, Core log and unchanged-policy audit.

- [Starter while worth is pending, English/light](native/tutor-ordinary-b269524d/pair-starter-worth-pending-en.png)
- [Regular objective while worth is pending, Arabic/dark](native/tutor-ordinary-b269524d/pair-regular-worth-pending-ar.png)
- [Background semantic success, same mounted source/native flow](native/tutor-ordinary-b269524d/pair-starter-semantic-delivered-en.png)
- [Real Firebase SDK award/lesson separation and stale-save results](native/tutor-ordinary-b269524d/firebase-sdk-pending-worth.json)
- [Full native relaunch](native/tutor-ordinary-b269524d/native-product-relaunch.png)

Visual inspection confirms matching lesson/percentage/reply content and the corrected states. It also retains visible orb/eye/shading, status-dot, speaker glyph, border/shadow and small spacing differences; these are not called whole-screen design parity. The full native frame includes its Daily XP/menu reservations, which the paired component driver omits.

The final read-only QA audit finds one 3–7 XP turn and assessment, matching daily/lesson XP, `hello` and `myNameIs`, an empty pending-award list, and zero late private-chat entries, history, Memory, bonus or Tutor daily activity.

## Retained failed attempts

- The first two-test reproduction exposed the real pending-worth stall. Its Gemini warm-up used single curly quotes, which the source extractor does not recognize, so that part did not demonstrate a locally accepted phrase. Corrected tests use recognized double quotes; no expected product result was weakened.
- Two intermediate builds failed on an actor-isolated default argument and a catch-local `error` shadowing the published property.
- A broader run exposed introduced saving-state cleanup and already-earned repair retry bugs. A completed-review test also needed to wait for the source's eventual Gemini background result. Those are corrected. Its native UI journey passed. High observed host load inflated that run's duration.
- The initial new browser comparison returned a JavaScript function from an assignment to WKWebView. A later fixture run used an empty user store and an older running plugin without the judge-hold hook. Those fixture errors are retained in their result bundles.
- A new canonical stale-intent reproduction failed four assertions: daily XP was projected twice after acknowledgment. Receipt-aware retirement/remaining-assessment normalization fixes it; Core and real Firebase SDK checks now cover it.

## Remaining scope

The source comparisons execute the actual original Tutor component, theme and CSS beside actual native views at 402×874 logical points. External model, microphone and web persistence I/O use explicit public fixtures. They do not establish live acoustic/provider quality, actual web Firebase writes, full authenticated browser routing or matching complete surrounding shells. Original PNGs retain their bytes; published pairs convert ICC profiles to sRGB before resizing.

Orb shape, feedback wash/edge glow, glyphs, shadows, full-shell geometry, accessibility and broader language/device comparisons remain open. This checkpoint adds no new SwiftUI presentation correction; it verifies the newly corrected states against the progressed design from the preceding checkpoint.

Connection-setup fallback, interrupted partial PCM and retained OpenAI output capture remain open. Wider concurrent-turn/day/target/support/interruption combinations, actual termination during a pending quote and dependent focused completion restoration need further evidence. The later [semantic Memory checkpoint](TUTOR_SEMANTIC_MEMORY.md) corrects ordinary successful/low-confidence slip capture, original initial note fields and immediate enrichment. Wider duplicate capture policy and process interruption during enrichment remain open; the preceding late-speech correction alone did not prove those ordinary paths. Continue all other open [handoff](PARITY_HANDOFF.md) rows; neither a matched prompt nor these selected tests establishes complete parity or release readiness.

Reference files and the separate native Firebase/Cloudflare configuration are unchanged. Only `CE8248B6-7171-4FD4-97DE-89E499107F82` is used for native QA; the regular simulator, pre-existing preview and emulators are preserved. Every Swift run is observed to a terminal result before Swift edits or another Swift run.

## Reproduce this scope

Start the read-only public preview with `node scripts/start-reference-preview.mjs` and preserve any pre-existing preview/emulator processes. The SDK contracts require the already configured local Firestore emulator at port 8180. Run one Swift command at a time; the final test used:

```sh
swift test --filter 'TutorOutcomeIntentTests|TutorSourceProgressTests|TutorSourcePolicyTests|SyncContractTests|CompanionHealthTests'

TEST_RUNNER_PIYALI_OFFLINE_TESTS=1 \
TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1 \
TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1 \
TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)" \
PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 \
scripts/test-ios.sh -parallel-testing-enabled NO \
-only-testing:PiyaliTests/TutorSessionTests \
-only-testing:PiyaliTests/FirestoreContractTests/testTutorPendingWorthSavesLessonBeforeAccountAwardAndStaleRetryCannotReplayItsProjection \
-only-testing:PiyaliTests/FirestoreContractTests/testSourceTutorOwnXPCapPrivateDraftQuizResetAndCompletionSurviveRetriesBeyondTrial \
-only-testing:PiyaliUITests/TutorParityTests/testNormalProductLateSpeechCreditsOnceKeepsChatPrivateAndRestoresProgressOnRelaunch \
-resultBundlePath /tmp/PiyaliTutorOrdinaryAgendaVerified20261105.xcresult
```

Use a new result path for another run. All final tested sources precede the passing bundle. Only its owned preview was stopped after verification; the three unrelated historical manifests regenerated by that launcher were restored to their original bytes.
