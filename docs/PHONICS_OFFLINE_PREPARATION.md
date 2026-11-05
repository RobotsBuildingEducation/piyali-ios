# Fresh authored Phonics during remote failure — 2026-11-05

Continuation of [focused Phonics](FOCUSED_PHONICS_HANDOFF.md) and [trial recovery](PHONICS_TRIAL_RECOVERY.md), from native `83e0963` against read-only reference `b269524ddc578027c549616fc47f5954991d9f6f`. This covers fresh authored Goal/repair deck preparation and recovery. The full main-product parity objective remains active.

## Reproduction and original behavior

The original `practiceArtifact` first checks its account-local cache, then a remote document, then attempts a transaction. Both remote boundaries have explicit catches: a deterministic authored candidate is cached and returned after failure. A transaction winner or valid remote/local artifact retains its saved IDs and outcomes, while `getFocusedPhonicsDeck` replaces its display text with canonical authored copy.

The two native reproduction checks remove the saved artifact while keeping an acknowledged ready Goal/repair plan. Goal preparation reports “Reconnect to save this practice deck across devices” and leaves its course uninitialized after its save fails. Repair preparation throws from remote reservation before displaying its candidate. `/tmp/PiyaliPhonicsFreshOfflineReproduction20261105.xcresult` retains both failed cases (12 assertions, 6.187 seconds). The repair reproduction routes reservation through the injected progress service; the old DEBUG-only shortcut previously bypassed the production network-failure path.

## Correction

Fresh authored Goal Phonics now remains usable with its artifact receipt pending. Repair reservation uses the bound progress service (the same production Firebase implementation), catches remote failures and keeps the original authored candidate. Cancellation and stale account/session, target/support, day or repair plan still reject reservation results. New preparation requires signed-in access. An acknowledged reservation winner is retained rather than replaced by the local selection. Cached relaunch does not reserve or generate again.

Only authored Phonics preparation receives this fallback. Existing new-plan and dependent outcome/completion acknowledgment gates remain. Loading a deck grants no XP, assessment, Goal evidence, repair completion or plate bonus. The focused course's error Retry now reloads focused state instead of invoking the ordinary-only New round action. The separate Firebase/Cloudflare configurations, identity custody and account-private persistence are preserved.

This makes an authored deck and its model text available during an outage. It does not make remote grading, generation or uncached narration work without a network. Synthetic pronunciation and acknowledgment fixtures in the reproducible journeys have their narrower scopes.

## Independent source evidence

`scripts/export-focused-phonics-cache.mjs` executes the unmodified original `practiceArtifactKey`, `artifactField`, `practiceArtifact` and `getFocusedPhonicsDeck` with the independently bundled original authored module. Fourteen Goal/repair cases cover failed reads plus failed writes, failed reads with successful transactions, empty reads with failed writes, existing remote/local artifacts, a competing transaction winner and an empty local cache. Public read/write/transaction call traces are retained in the compressed vectors. Canonical copy, IDs, roles and outcomes are compared with the production native policy adapter; this adds cache behavior to the prior authored-selector oracle.

The exporter initially addressed the original lexical `artifactField` as a VM property; that harness error was corrected by reading its unchanged lexical binding. No reference file changed. The resulting [source manifest](reference/focused-phonics-cache-manifest.json) records function names and source/authored-bundle hashes.

Nineteen selected Core checks pass in 2.126 seconds, log `/tmp/piyali-phonics-cache-core-20261105.log`: new full-cache cases, existing selector/completion/capture cases and focused/Goal/companion contracts. These are pure policy/cache-boundary checks, not full authenticated browser navigation or production network evidence.

A subsequent controller run reproduced an additional acknowledgment-projection error: a successful repair reservation returns a previously saved first outcome, but the pending local artifact patch initially hides it from collection. Its raw server IDs/outcomes remain intact. A successful reservation now confirms that base before queuing the local artifact mirror; failed reservations do not confirm optimistic outcomes. All fourteen model checks pass after that correction, including the seven held-reservation ownership cases and preserved server-winner collection.

## Rendered comparison and persistence scope

The original `AlphabetBootcamp` component executes its actual full cache/factory functions with empty local storage and explicit remote read/transaction failures. English/light and Arabic/dark Goal and repair front/Practice captures are paired with native fresh preparation using a failing progress service. The original local read → remote read → transaction → local write trace, generated IDs/roles/cards and zero outcomes/XP are checked. Native requires no placeholder or generic replacement screen. These eight content pairs omit main product chrome and do not prove browser signup, authenticated app routing or touch targets.

Reviewed [Goal front/light](native/phonics-offline-preparation-b269524d/goal-front-en-pair.png) and [repair practice/dark Arabic](native/phonics-offline-preparation-b269524d/repair-practice-ar-pair.png) retain equivalent source copy, cards, progress, feedback-free practice and action controls. Small icon/rasterization/edge differences, dock glass/shadows and motion phases remain unapproved. The collection-complete/error/Tutor states have their prior or remaining scopes; these captures do not expand them.

The named local `demo-piyali-ios` Firebase SDK test disables and restores the client network around preparation/private restore. It accepts an available canonical reservation winner or the local candidate while disabled, then requires preservation of the seeded remote IDs/outcomes and unrelated quest fields after reconnect. XP, ordinary alphabet records and mode/repair completion do not change. Disabling the SDK network did not guarantee a missing reservation in the observed run: repair returned an available winner. The first SDK expectation incorrectly demanded the local candidate and failed three assertions (13.844 s). The corrected check records both preparation traces and checks the two contractually valid states; injected failures independently prove the actual fallback. This is not physical airplane-mode or production outage evidence.

## Remaining scope

Termination before earned completion acknowledgment at the trial boundary remains open in [trial recovery](PHONICS_TRIAL_RECOVERY.md). Fresh Goal flashcard artifact preparation still has its separate native acknowledgment guard despite the shared source cache fallback; it needs its own provider/fallback and recovery proof. Broader day/version/multi-device conflicts, arbitrary-objective Tutor engagement, actual offline network/device behavior, physical speech/playback/routes, accessibility, source toast presentation, full product viewports and payment/release gates remain open. Earlier source/native normal card comparisons retain their original revision and scope.

The first native recovery bundle also contains two passing full setup/offline-deck/relaunch/reconnect/pronunciation/next-lesson journeys (Goal 105.906 s; repair 114.716 s), alongside the failed reservation-projection check. A following source comparison build failed because an async JavaScript evaluation was placed inside `XCTUnwrap`’s synchronous autoclosure; splitting evaluation from unwrapping corrected this test harness error. Final model/source checks pass in `PiyaliPhonicsFreshOfflineVerified2_20261105.xcresult` (14 models 77.741 s; source comparison 28.364 s; existing flashcard generation 0.115 s and legacy repair 0.584 s). Its earlier SDK expectation fails as described above; the bundle is not wholly green. No production Swift changes followed these model/source checks.


## Final checks and retained artifacts

| Check | Passing result | Scope and authoritative bundle |
| --- | --- | --- |
| Core | 19 tests, 2.126 s | Fourteen original full-cache cases plus existing authored/focused/Goal/companion contracts; Core log above |
| Native models | 14 tests, 77.741 s | Offline fresh/private restore, canonical/server winners, seven reservation and seven verdict ownership boundaries, completion/retry/trial regressions; `PiyaliPhonicsFreshOfflineVerified2_20261105.xcresult` |
| Original/native component | 1 test, 28.364 s | Eight front/Practice pairs, four actual original cache traces, exact public card arrays and zero XP; same bundle |
| Shared regressions | 2 tests, 0.115/0.584 s | Original Goal flashcard generation/cache and legacy authored repair; same bundle |
| Real Firebase SDK | 1 test, 13.810 s | Network disable/restore, local candidate or available winner, preserved server cards/outcomes/foreign fields and no rewards; `PiyaliPhonicsFreshOfflineJourneysVerified20261105.xcresult` |
| Full native UI | 2 tests, 221.589 s | Goal 105.617 s; repair 115.972 s: signup/onboarding/Paper/setup/placement → fresh offline deck → Practice → private relaunch → reconnect → miss/retry/correct/Collect → next lesson; same final SDK/UI bundle |

The final SDK/UI bundle is wholly green; the earlier model/source bundle has the failed SDK expectation described above. Final logs are `/tmp/piyali-phonics-fresh-offline-verified2-20261105.log` and `/tmp/piyali-phonics-fresh-offline-journeys-verified-20261105.log`. Only the SDK test expectation changed between them. The final two full UI journeys rerun on the corrected reservation-projection implementation.

[The capture manifest](native/phonics-offline-preparation-b269524d/manifest.json) retains 30 hashed artifacts: eight sRGB source-left/native-right pairs, four selected original PNGs, four public inputs, four original cache traces, eight full-phone native frames and two SDK preparation traces. All sixteen comparison-original hashes and final relevant source/native/test-product hashes are recorded. Originals retain their profiles; pairs are normalized to 402-point sRGB. Reviewed [offline Goal relaunch](native/phonics-offline-preparation-b269524d/goal-phone-offline-relaunch.png) and [next repair lesson](native/phonics-offline-preparation-b269524d/repair-phone-next-lesson.png) show the actual native product chrome and handoff. The next lesson uses the established explicit question fixture; generated lesson quality/full completion is not claimed. The SDK Goal trace retains a local candidate with one pending artifact; repair retains the available server IDs and collected success. This distinction remains visible in the evidence.

All runs pinned isolated QA simulator `CE8248B6-7171-4FD4-97DE-89E499107F82`. The regular simulator and production services were not changed. One Swift build/test ran at a time, and the read-only preview was stopped after verification. Its three unrelated historical source manifests were restored to their prior bytes.

Reproduce the source oracle and Core scope first:

```sh
node scripts/export-focused-phonics-cache.mjs
swift test --filter 'FocusedPhonicsPolicyTests|FocusedDeckProgressTests|CompanionQuestTests|GoalPracticeTests'
```

With the read-only preview (`node scripts/start-reference-preview.mjs`) and named loopback `demo-piyali-ios` emulator running, use a new result path:

```sh
TEST_RUNNER_PIYALI_OFFLINE_TESTS=1 TEST_RUNNER_PIYALI_PHONICS_FIXTURE=1 \
TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1 TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1 \
TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)" \
PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 scripts/test-ios.sh \
-parallel-testing-enabled NO -only-testing:PiyaliTests/FocusedPhonicsFlowTests \
-only-testing:PiyaliTests/FocusedPhonicsComparisonTests/testOriginalFreshOfflineAuthoredGoalAndRepairFrontAndPracticeAgainstNative \
-only-testing:PiyaliTests/FirestoreContractTests/testFreshAuthoredPhonicsSurvivesSDKNetworkDisableAndPreservesRemoteWinnerOnReconnect \
-only-testing:PiyaliTests/FocusedFlashcardFlowTests/testGoalGenerationUsesOriginalPromptAndFloorThenRestoresCachedArtifactWithoutAnotherRequest \
-only-testing:PiyaliTests/CompanionQuestFlowTests/testAuthoredPhonicsRepairKeepsOriginalAndTransferOutcomesSeparateFromNormalPhonics \
-only-testing:PiyaliUITests/FocusedPhonicsJourneyTests/testFreshGoalPhonicsOfflinePreparationReentryThenOnlinePronunciationAndNextLesson \
-only-testing:PiyaliUITests/FocusedPhonicsJourneyTests/testFreshRepairPhonicsOfflinePreparationReentryThenOnlinePronunciationAndNextLesson \
-resultBundlePath /tmp/NewPhonicsOfflinePreparation.xcresult
```
