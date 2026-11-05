# Pronunciation earned work at the trial boundary — 2026-11-05

Continuation of [focused Phonics](FOCUSED_PHONICS_HANDOFF.md), from native `7e0a255` and read-only reference `b269524ddc578027c549616fc47f5954991d9f6f`. This closes a scoped in-flight access defect; the wider main-product parity goal remains open.

## Reproduced defect and source contract

The rendered `ProductAccessGate` → `FocusedGoalCourseView` → native Phonics path started with an acknowledged two-card deck, its first saved success and 299 subscription XP. The actual second pronunciation earned 2 XP while its save was held. Before correction the access change removed the footer and cancelled the session; releasing the save did not complete the Goal mode or route its conductor. `/tmp/PiyaliPhonicsTrialReproduction20261105.xcresult` retains five assertions from that one failing rendered test (8.215 seconds). The test used the production hierarchy and original authored deck, with an explicit synthetic grader and in-process progress store.

The original `AlphabetBootcamp.jsx` focused handler awaits `savePracticeOutcome`, `awardXp`, then `recordGoalAttempt`/`completeRepairFocus`. Its ordinary handler awaits XP and alphabet progress separately. `App.jsx` redirects to `/subscribe` at 300 XP without verified access; that redirect does not abort the already executing JavaScript handler. Native cancellation must likewise preserve earned work. Native deliberately keeps the current save/retry or ordinary Collect actionable, then presents subscription when that work retires. This is an earned-work adaptation, not a claim that the web keeps its card visible across its redirect.

## Native correction

A successful native pronunciation retains an account/target/day owner synchronously before changing XP. The existing root access mechanism, the focused Goal/repair hosts and this session's footer keep that owned work mounted through save failure/retry. Acknowledged completion changes the conductor only once; retirement or cancellation releases the owner. Ordinary success remains available for Collect or Back. Collected-card repeats use the same ownership path. Pending save failure cannot be dismissed through Back or reset into another recording; retry saves the existing attempt.

New practice, grading/quotes, microphone capture, narrated playback, level selection and supplemental-deck requests now require access at their entry points. Stopping existing audio and saving an already earned result remain available. This does not grant paid authorization or change service configuration, StoreKit/web verification, account custody or XP receipts. It does not claim that every other mode or cross-mode portal has an equivalent boundary proof.

## Evidence scope

Rendered app tests cover held Goal outcome save, lost connectivity and explicit retry; failed repair completion followed by acknowledgment; ordinary earned Collect; unchanged 2-XP/one-assessment counts; confirmed next routing; owner release; and rejected new grading, quote, recording, playback, level/deck requests after access ends. Existing focused canonical/offline/retry/identity cases and ordinary pronunciation/retry/save regressions run on the same implementation.

Two full native UI journeys use real signup, onboarding, Paper/setup/placement, Start tasks and Practice/Record/Try again/Collect controls. Public authored Goal/repair decks are acknowledged fixtures. Initial subscription adjustments place the last actual correct pronunciation at 299→301; no answers or earned rewards are seeded. The final dependent completion fails once; background acknowledgment recovers into subscription, the next lesson never starts, and subscription persists on relaunch. The strict DEBUG fixture requires the isolated offline identity and scenario; physical speech and production services are not exercised.

## Validation and retained results

Eleven app checks pass in `/tmp/PiyaliPhonicsTrialRecovery20261105.xcresult` (52.751 seconds); the containing bundle is not wholly green. Its first two full UI attempts fail because the scheduled background save acknowledges the one transient completion failure before the test can force a Retry tap (Goal 96.996 seconds; both UI attempts 204.158 seconds). The journeys now verify that automatic acknowledgment correctly retires the earned surface into subscription. Explicit Retry during sustained failure remains verified by the rendered app checks. The first narrower held-save correction passed in `/tmp/PiyaliPhonicsTrialFirstFix20261105.xcresult` (4.166 seconds).

Final full UI result: `/tmp/PiyaliPhonicsTrialJourneysVerified20261105.xcresult`, two tests pass in 190.429 seconds (Goal 92.752; repair 97.677), log `/tmp/piyali-phonics-trial-journeys-verified-20261105.log`. The UI-only rerun follows only the test expectation adjustment; no production Swift changed after the eleven passing app checks. All runs explicitly pinned isolated QA simulator `CE8248B6-7171-4FD4-97DE-89E499107F82`; the regular simulator was not modified.

[Retained capture manifest](native/phonics-trial-recovery-b269524d/manifest.json). Reviewed [Goal save failure and Retry](native/phonics-trial-recovery-b269524d/goal-failed-save.png) and [ordinary earned Collect](native/phonics-trial-recovery-b269524d/ordinary-earned-collect.png) retain the actual card and controls. The manifest retains ten original-resolution hashed captures plus relevant source/native and final tested-product hashes. Reviewed [full-product subscription](native/phonics-trial-recovery-b269524d/goal-product-subscription.png) and [repair relaunch](native/phonics-trial-recovery-b269524d/repair-product-relaunch.png) show the earned flow retiring into the existing gate. These app captures use a minimal host for the production root/route/footer, omitting the main product chrome; the full UI journey has its own screenshots. The source catch-all grading-error text and inline save-error composition remain known differences.

## Remaining scope

Fresh focused authored-artifact preparation was subsequently corrected and verified in [offline preparation](PHONICS_OFFLINE_PREPARATION.md). The following describes this earlier checkpoint: fresh focused authored-artifact creation during network failure is the next concrete Phonics preparation gap: the source returns a local candidate on remote failures, while native new Goal artifacts still require acknowledgment and production repair reservation can throw. Cached offline reentry has its narrower existing proof. Process termination while earned completion is still pending at the access boundary, multi-device conflicts, physical microphone/playback/route changes, wider locales/accessibility, source toast composition and whole-product design remain open. The separate Firebase/Cloudflare services and read-only reference are preserved.


Reproduce the app and UI scopes sequentially from the native checkout, using a new result path:

```sh
TEST_RUNNER_PIYALI_OFFLINE_TESTS=1 TEST_RUNNER_PIYALI_PHONICS_FIXTURE=1 \
TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)" \
PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 scripts/test-ios.sh \
-parallel-testing-enabled NO -only-testing:PiyaliTests/FocusedPhonicsFlowTests \
-only-testing:PiyaliTests/PhonicsFlowTests/testWrongRetryRepeatAndCollectionUseIndependentSourceBoundaries \
-only-testing:PiyaliTests/PhonicsFlowTests/testFocusedPhonicsFailureRetainsTwoXPAndDoesNotRepeatAssessmentOnSaveRetry \
-only-testing:PiyaliUITests/FocusedPhonicsJourneyTests/testGoalPronunciationTrialEndRecoversCompletionIntoSubscription \
-only-testing:PiyaliUITests/FocusedPhonicsJourneyTests/testRepairPronunciationTrialEndRecoversCompletionIntoSubscription \
-resultBundlePath /tmp/NewPhonicsTrialRecovery.xcresult
```
