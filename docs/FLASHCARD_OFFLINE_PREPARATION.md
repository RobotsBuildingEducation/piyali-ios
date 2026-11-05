# Fresh Goal flashcards during remote failure — 2026-11-05

Continuation of [focused recall](FOCUSED_FLASHCARD_HANDOFF.md), native base `4848404cdfe6118ef105a6b3c89ff1e7c94f71b3`, against read-only reference `b269524ddc578027c549616fc47f5954991d9f6f`. Main-product functional and design parity remains unfinished.

## Reproduced difference and correction

The original `getGoalFlashcards` runs inside `practiceArtifact`. A failed remote read does not prevent building three recall cards. Generation failure keeps the original blueprint cues; a failed artifact transaction keeps the captured candidate in the account-local cache and returns it. Native already built those same cards, but then threw “Reconnect to save this practice deck across devices.” while its artifact receipt remained pending. `FlashcardsView` could display the cards alongside that extra failure/Retry. This was a preparation error, not proof that every native entry rendered an empty deck.

The new native restore test reproduces that extra throw: one failed assertion, 6.070 s, `/tmp/PiyaliFreshGoalFlashcardReproduction20261105.xcresult`. The correction lets both existing focused factories return their captured local candidate after sync failure. It retains the original Goal-plan acknowledgment gate and all answer/completion save requirements. Opening/preparing a deck grants no XP, assessment or completion. The same private deck is reused after account restore without generating again. Cancelled preparation and replaced identity/session/target/support/Goal results cannot write a late artifact.

The narrow DEBUG UI fixture begins with a ready public Goal blueprint and **no artifact**. Its explicit generator failure and artifact-save failure require the existing offline-test flag, a valid isolated UUID and Goal scenario. Default/release launches retain their normal providers/services. UI grading uses the existing fixed grading fixture; this does not claim offline remote grading or physical airplane-mode operation.

## Source and native behavior evidence

The new read-only preview executes the full original `goalPromptData`, `practiceArtifactKey`, `artifactField`, `practiceArtifact`, `getGoalFlashcards` and `savePracticeOutcome` bodies. Source files are unchanged. Only remote read/transaction/provider boundaries use public recording fixtures. The original performance model and original account-local browser storage helpers execute. Existing cached-render comparisons keep their prior explicit fixture behavior.

Four fresh cases cover English/light and Arabic/dark, each with provider failure and with a valid generated reply while artifact I/O fails. Actual source/native cards and owner keys are compared; prompt instruction text and embedded Goal/performance objects are compared independently of JSON object key order. Initial source calls are remote read → generation → failed transaction. Remounting the real React root reuses the actual browser account-local cache without another provider or remote call. After the artifact boundary reconnects, the original tile → grading modal → Good controls save three outcomes, award 2 XP each and record one completion. Native snapshots in this comparison remain unpracticed; native completion is verified in the separate full journey and SDK test. These component checks do not prove full authenticated web routing, browser process persistence or live model quality.

The native full journey enters through signup, onboarding, Paper/setup/placement and Start tasks; opens the fresh fallback; answers the first card; retains its modal on failed acknowledgment; terminates and reopens the captured deck while the answer remains pending; reconnects and shows exactly one acknowledged answer; completes the remaining cards into the next Goal lesson; then restores that lesson after another relaunch. The next lesson still uses the existing public question fixture. A read-only scoped QA snapshot audit checks 6 XP, three assessments, one mode-completion event, no pending Goal/practice receipts and no ordinary review schedule.

The real Firebase SDK test disables networking on the named loopback `demo-piyali-ios` client while preparing/reopening the fresh Goal candidate, then reconnects. It verifies that an existing remote reservation winner and its outcomes survive, unrelated fields remain intact, preparation grants no reward, and the no-winner candidate can complete through the actual card controller with six total XP, three assessments and one Goal completion across repeated saves. SDK network toggling is not a physical-device outage claim.

## Validation and retained artifacts

The first comparison build fails on an async expression inside an assertion autoclosure. After fixing that test code, the SDK check passes (10.303 s), all six native flow checks pass (6.332 s), and the cached source/native regression passes (34.158 s). The fresh source comparison executes all four cases but fails four exact-string prompt assertions because JavaScript and Swift serialize equivalent Goal objects in different key order. Cards, cache/remount calls and original recall/completion controls pass their assertions. Both native journeys in that containing bundle pass (fresh Goal 131.032 s; repair regression 90.093 s), and the read-only Goal QA audit passes. `/tmp/PiyaliFreshGoalFlashcardVerified2_20261105.xcresult` is **not** a wholly green bundle.

The final comparison test preserves the exact instructions while comparing the embedded Goal/performance JSON structurally. Only test code changes after the two passing UI journeys; product implementation and fixtures remain unchanged.

| Check | Passing result | Scope |
| --- | --- | --- |
| Core | 24 tests, 11.017 s | Original 13-case factory/recall/completion oracle plus Goal/companion/Memory/receipt/rebase/SRS contracts |
| Final native/source/SDK | 9 tests, 391.739 s | Six native flow checks (6.239 s), actual SDK offline/reconnect/winner/reward check (10.894 s), four fresh source/native cases (35.405 s), cached focused Goal/repair regression (339.201 s) |
| Native full journeys | 2 tests, 221.125 s | Fresh Goal 131.032 s; repair regression 90.093 s; both passed in the separately labeled main bundle |
| Live focused generation | 1 test, 8.871 s | Four real authenticated calls through configured Gemini-first and explicit Responses paths, English/Arabic cues, parsed three-card replies, no learner progress writes, disposable auth identity removed |
| Scoped QA snapshot audit | Pass | 6 XP, three assessments, one Goal mode event, no pending Goal/practice receipts or ordinary review schedule |

The final native/source/SDK bundle is `/tmp/PiyaliFreshGoalFlashcardFinalComparisons20261105.xcresult`; its log is `/tmp/piyali-fresh-goal-flashcard-final-comparisons-20261105.log`. The live bundle is `/tmp/PiyaliFreshGoalFlashcardLive20261105.xcresult`. The configured path can use its normal source fallback; this check does not prove that each configured reply originated from Gemini. It exercises the separate native `piyali-ios` project and existing DEBUG App Check authentication, not release App Attest or paid verification.

[The manifest](native/fresh-goal-flashcards-b269524d/manifest.json) retains 30 hashed artifacts: eight original source/native fresh component PNGs, four sRGB display pairs, four public inputs, four actual source cache/recall traces, six full native journey frames, two SDK offline traces, one privacy-limited QA audit and one live public generation trace. It also records 44 historical/final cached-regression and repair-journey attachment hashes, source revisions and separately labeled main/final/live test products. The production implementation dylib hash is identical across the passing UI journeys, final comparison and live runs. All Swift builds/tests ran sequentially and pinned isolated QA simulator `CE8248B6-7171-4FD4-97DE-89E499107F82`; the regular simulator was untouched.

Reviewed [English/light fallback](native/fresh-goal-flashcards-b269524d/en-provider-failure-pair.png), [Arabic/dark fallback](native/fresh-goal-flashcards-b269524d/ar-provider-failure-pair.png) and [native pending first recall](native/fresh-goal-flashcards-b269524d/native-first-recall-pending.png). The repeated blueprint cue, library count, progress, card content and placement match these component states without the extra native preparation error. The public blueprint objective is English in both fallback inputs; those English fallback cues are source behavior for these inputs, not a localization-quality claim. The generated-reply fixtures likewise do not prove model quality; the separate live trace provides narrower actual-generation evidence. Card glow/pulse phases, gradients, compositing, rasterization and full-shell/toast behavior still differ or remain unapproved. The full-phone failed-save frame is not a matched source error viewport.

The preview was stopped after comparisons, and its three unrelated historical manifests were restored to their original bytes. The reference remains clean and separate service/configuration files remain unchanged.

Reproduce the final offline scope with the read-only preview and named loopback emulator running, a fresh result path and isolated UUID:

```sh
swift test --filter 'FocusedDeckProgressTests|GoalPracticeTests|CompanionQuestTests|SyncChangesTests|GoalMemoryCaptureTests|FlashcardSessionTests'
TEST_RUNNER_PIYALI_OFFLINE_TESTS=1 TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1 \
TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1 TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)" \
PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 scripts/test-ios.sh \
-parallel-testing-enabled NO -only-testing:PiyaliTests/FocusedFlashcardFlowTests \
-only-testing:PiyaliTests/FocusedFlashcardComparisonTests \
-only-testing:PiyaliTests/FirestoreContractTests/testFreshGoalFlashcardFallbackSurvivesSDKNetworkDisableThenPreservesWinnerAndEarnsOnce \
-only-testing:PiyaliUITests/FocusedDeckJourneyTests/testFreshGoalOfflineFallbackCanBeAnsweredRestoredThenAcknowledgedBeforeNextLesson \
-only-testing:PiyaliUITests/FocusedDeckJourneyTests/testRepairRecallCompletesThenNextRepairLessonOpens \
-resultBundlePath /tmp/NewFreshGoalFlashcardCheck.xcresult
```

For the audit, record `{ "startedAt": <Unix seconds before that UI run>, "device": "CE8248B6-7171-4FD4-97DE-89E499107F82" }` in a task-owned JSON file and run `python3 scripts/audit-fresh-goal-flashcard-qa.py --since <file> --output <new audit>`. The live check runs separately using the existing private App Check credential: `PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 python3 scripts/test-live-api.py --only focused-flashcards --result-bundle /tmp/NewLiveFocusedCards.xcresult`. Credentials are passed only through the runner environment; no new service configuration or deployment is required.

## Remaining scope

Release attestation/signing, wider live content-quality coverage, the wider Tutor and other learning-mode generation/repair differences remain separate work. Failed-save source toast versus native inline error, changed-rating retry, broader day/support/device conflicts, full authenticated browser routing, full product viewports/compositing/motion, physical audio/accessibility and payment/release gates remain open. Earlier unmarked legacy Phonics outcomes keep the limits in [durable finish](PHONICS_DURABLE_FINISH.md). No reference, ignored service configuration, Firebase rules or Cloudflare deployment is changed; `/citizenship` and `/links` remain excluded.

The previously listed unavailable Phonics routing boundary is subsequently reconciled in [the focused fallback record](PHONICS_TUTOR_FALLBACK.md): the unmatched-word preflight already existed, while post-mount restoration exceptions needed their own handoff. Its real voice/full-browser/release limits remain explicit.
