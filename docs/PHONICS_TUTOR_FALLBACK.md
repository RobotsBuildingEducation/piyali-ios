# Phonics load failure → focused Tutor — 2026-11-05

Continuation of [the handoff](PARITY_HANDOFF.md), native base `60d1f30a812522c9b1ab33ac3718f82037912161`, against read-only reference `b269524ddc578027c549616fc47f5954991d9f6f`. Main-product functional and design parity remains open.

## Existing behavior and reproduced difference

Both source `navigateToPlateCourse` and the native Goal/repair wrappers already route an unmatched authored word directly to focused Tutor. That preflight was not missing. The native `PhonicsCourseController` alone did not establish the product's routing behavior; the surrounding wrappers matter.

The source has a second boundary: mounted `AlphabetBootcamp` calls `onFocusedPracticeUnavailable` when the focused artifact requires Tutor **or throws while loading**. `App.handlePhonicsFocusUnavailable` keeps the same focus/blueprint/mode, changes only its surface to Tutor and calls `goToSkillTreeMode`. It does not substitute ordinary pronunciation words, connect automatically or award completion.

Native previously left a failed mounted deck on its Phonics error screen. A public malformed cached artifact (`cards: [null]`, with the correct owner) makes the full original/native restoration body throw after the initial authored selector succeeds. Both rendered native wrappers reproduce the missing handoff: four failed assertions, 17.335 s, `/tmp/PiyaliPhonicsTutorFallbackReproduction20261105.xcresult`. This proves a focused restoration exception, not a normal provider outage or evidence that a real user's cache has that shape.

## Correction

`PhonicsCourseController` distinguishes unavailable preparation from a failed save of already earned completion. `PhonicsView` forwards only a current, uncancelled preparation failure. Goal and repair wrappers mount the actual native `SourceTutorView` with the same original focus and keep the Phonics mode for later credit. They retain session/account/target/support/Goal/repair ownership; cancelled or replaced loads do not request a handoff. Goal fallback identity deliberately excludes subscription access, so an earned Tutor completion cannot be displaced when it crosses the trial limit.

The source catch does not recheck its cancelled flag before the unavailable callback. Native retains its existing cancellation/session fences under the handoff’s ownership requirements; the stale-error cases are not claimed to behave identically.

The handoff awards no XP, assessment or completion; it starts no voice connection and rewrites no artifact. Unavailable cached data remains captured, matching the source's cache/fallback behavior. Reopening the task reaches Tutor again. An earned Phonics save failure continues to show its existing Phonics/Retry surface. Tutor's existing Goal 25-XP requirement and repair completion/bonus semantics remain; finishing there credits the original Phonics Goal mode or repair step after acknowledgment, with no ordinary Tutor path or alphabet activity.

## Ready Tutor presentation

The paired screens also exposed concrete header differences. Native now uses the original `RiRoadMapLine` and `FaRegCommentDots` SVG paths, exported into the existing vector asset catalog, and the source badge text/background/border/shadow colors. Actual computed source styles record a 25-point badge, a one-point border plus eight-point inset, four-point progress spacing and 0.6 disabled history opacity. A custom history button style prevents SwiftUI from dimming that opacity again. The initial 0.4 opacity assumption was corrected against those computed values; the final captures are separate from that earlier presentation run.

## Source, native and journey evidence

The preview runs the full original `getFocusedPhonicsDeck`/cache/restoration body and original `AlphabetBootcamp` effect. It extracts the actual `handlePhonicsFocusUnavailable` and `goToSkillTreeMode` callback bodies from `App.jsx` without editing the reference. A bounded preview route driver calls those original callbacks and then mounts the actual source Tutor component. Public store/backend/voice fixtures isolate external I/O. This is not the complete authenticated App router.

Eight component cases cover Goal/repair × unmatched/restoration exception × English/light and Arabic/dark. The source `requiresTutor` cases exercise its mounted defensive callback, while native uses its existing unmatched-word preflight. The exception cases exercise the missing post-mount native handoff. Actual source focus writes preserve the complete original focus except for its surface; native receives the same blueprint or mini-plan, target/support and original mode. The source/native ready Tutor lesson and title are compared. No source learning writes or native XP/assessment occur.

The rendered native completion check holds the original Goal/repair task through failed saves. Goal fallback reaches 25 XP, including the trial-access transition; retry acknowledges only Phonics mode credit and routes to the next lesson. Repair earns one accepted turn plus its existing 12-XP completion bonus, retains its original step until acknowledgment, then routes to the next repair lesson. No ordinary Tutor lesson, alphabet activity or duplicate reward is introduced. These use injected speech/rubric/save boundaries, not real microphone/provider evidence.

Two full native journeys use normal signup, onboarding, Paper/setup/placement and Start tasks, encounter the failed deck and show disconnected Tutor, explicitly connect/pause/end through the existing synthetic voice transport, terminate, and reopen the same disconnected focused Tutor. They do not claim that the full voice lesson is completed through physical speech. A separate scoped private QA snapshot audit verifies no reward, assessment, completion or ordinary Tutor progress from these navigation/connection journeys.

## Validation and retained evidence

The first correction produces both routing callbacks but the minimal Goal test blueprint lacks `successCriteria`, so Tutor cannot build its actual source lesson (one failed assertion, 12.968 s). The public test blueprint is corrected to the product's required contract. The following four-check flow bundle passes (81.215 s): eight original/native transitions (60.973 s), rendered Goal/repair handoff (8.608 s), retained earned-save Retry (2.864 s) and acknowledged fallback completion (8.769 s). `/tmp/PiyaliPhonicsTutorFallbackFlow20261105.xcresult` predates the final trial-stable fallback key and added cancellation/UI checks; it is historical evidence with that scope.

| Check | Passing result | Exact scope |
| --- | --- | --- |
| Main app/source | 31 tests, 296.274 s | 26 native Phonics cases, three Tutor completion/trial cases, eight source/native fallback transitions, normal 16-state Phonics wrong/retry/correct regression |
| Initial full native journeys | 2 tests, 161.819 s | Goal 81.365 s; repair 80.454 s; same failure/connect/pause/end/private-reentry flows before ready-header styling |
| SVG/palette presentation run | 2 app checks, 68.368 s; 2 UI journeys, 159.979 s | Source/native ready states and fallback completion/trial check pass; this run precedes the final computed-style correction |
| Final computed-style source comparison | 1 test, 8 cases, 59.382 s | Same original callbacks and actual source/native Tutor ready frames, including computed source geometry/colors/disabled state |
| Final native journeys | 2 tests, 159.874 s | Goal 80.018 s; repair 79.856 s, on the final header/palette/inset code |
| Core | 29 tests, 14.451 s | Original authored/cache/Goal/companion/Phonics progress and Tutor policy/progress contracts |
| Read-only scoped QA audit | Pass | Both final private profiles keep the bad captured artifact and show zero XP, assessments, mode/repair completion, ordinary Tutor progress and pending learning receipts |

The main green bundle is `/tmp/PiyaliPhonicsTutorFallbackVerified20261105.xcresult`; the intermediate presentation bundle is `/tmp/PiyaliPhonicsTutorFallbackFinalScreens20261105.xcresult`. Final captures/journeys are in `/tmp/PiyaliPhonicsTutorComputedStyles20261105.xcresult`, log `/tmp/piyali-phonics-tutor-computed-styles-20261105.log`. The final source-only/presentation checks do not silently replace the broader main functional scope. Only the ready Tutor header, source geometry attachment and public completion trace were changed after the main functional run; handoff, ownership and completion implementation hashes remain unchanged.

[The manifest](native/phonics-tutor-fallback-b269524d/manifest.json) retains 47 hashed artifacts: 16 original source/native component PNGs, four sRGB display pairs, eight public inputs, eight actual source callback/geometry traces, six final full-phone journey frames, two native load-failure traces, two acknowledged completion traces and one privacy-limited QA audit. It also records 56 normal Phonics regression attachment hashes, separately labeled main/presentation/final source and product hashes, source revision hashes, and provenance for the two original SVG paths.

Reviewed [Goal English/light](native/phonics-tutor-fallback-b269524d/goal-malformed-en-pair.png), [repair Arabic/dark](native/phonics-tutor-fallback-b269524d/repair-malformed-ar-pair.png), and [the real restored Goal Tutor](native/phonics-tutor-fallback-b269524d/native-goal-tutor-restored.png). These prove the retained objective/ready state and improved header glyph/palette/inset alignment. The isolated native comparison host publishes the real dock without the full ProductShell menu reservation; its dock width is not a full-shell comparison. The full-phone frames separately include the native product menu/dock. Orb rasterization/lighting, shadows/compositing, larger percentages, long objectives, active archive highlights and wider layouts remain unapproved; no pixel-perfect or full-browser design claim is made.

All runs used isolated QA simulator `CE8248B6-7171-4FD4-97DE-89E499107F82`, one Swift build/test at a time. The regular simulator was not modified. The read-only preview was stopped and its three unrelated historical manifests restored to their original bytes. Reference and native service/configuration files remain unchanged.

Reproduce the functional/source/UI scope with the read-only preview running, an isolated UUID and a fresh result path:

```sh
swift test --filter 'FocusedPhonicsPolicyTests|GoalPracticeTests|CompanionQuestTests|PhonicsProgressTests|TutorSourcePolicyTests|TutorSourceProgressTests'
TEST_RUNNER_PIYALI_OFFLINE_TESTS=1 TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1 \
TEST_RUNNER_PIYALI_PHONICS_FIXTURE=1 TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)" \
PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 scripts/test-ios.sh \
-parallel-testing-enabled NO -only-testing:PiyaliTests/FocusedPhonicsFlowTests \
-only-testing:PiyaliTests/TutorSessionTests/testPhonicsFallbackTutorKeepsOriginalModeAndOnlyRoutesAfterEarnedCompletionAcknowledges \
-only-testing:PiyaliTests/TutorSessionTests/testRenderedGoalTutorRetainsEarnedWorkAcrossTrialGateAndRoutesAfterAcknowledgment \
-only-testing:PiyaliTests/TutorSessionTests/testRenderedRepairTutorRetainsFailedCompletionUntilRetryAcknowledgesIt \
-only-testing:PiyaliTests/FocusedPhonicsComparisonTests/testOriginalUnavailablePhonicsAndAppCallbacksOpenTheSameUnstartedTutorAgainstNative \
-only-testing:PiyaliTests/FocusedPhonicsComparisonTests/testOriginalFocusedDeckAndPracticeWrongRetryCorrectAgainstNativeInEnglishAndArabic \
-only-testing:PiyaliUITests/FocusedPhonicsJourneyTests/testGoalPhonicsLoadFailureOffersTheSameTutorThenReopensWithoutAutoConnecting \
-only-testing:PiyaliUITests/FocusedPhonicsJourneyTests/testRepairPhonicsLoadFailureOffersTheSameTutorThenReopensWithoutAutoConnecting \
-resultBundlePath /tmp/NewPhonicsTutorFallback.xcresult
```

For the privacy-limited post-UI audit, record `{ "startedAt": <Unix seconds before the run>, "device": "CE8248B6-7171-4FD4-97DE-89E499107F82" }` in a task-owned JSON file, then run `python3 scripts/audit-phonics-tutor-fallback-qa.py --since <file> --output <new audit>`. The audit reads only the two scoped public-fixture learner profiles. No credentials are exported.

## Remaining scope

Full authenticated browser routing, every failure shape/legacy artifact, wider day/language/device combinations, physical capture/playback/permissions, Tutor split/late transcription recovery, release signing/App Attest, real paid verification and whole-shell/motion/compositing/design gates remain open, including dynamic percentage-badge width, transcript/history highlight states and wider orb states. The cache-error fixture is not a live network-failure claim. Initial unmatched routing already existed and is now explicitly distinguished from the correction. No reference, separate Firebase/Cloudflare configuration, rules or deployments are changed; external `/citizenship` and `/links` remain excluded.
