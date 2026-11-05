# Earned Phonics completion after termination — 2026-11-05

Continuation of [trial recovery](PHONICS_TRIAL_RECOVERY.md) and [offline preparation](PHONICS_OFFLINE_PREPARATION.md), from native `aa07e95` against read-only reference `b269524ddc578027c549616fc47f5954991d9f6f`. This covers the dependent Goal/repair completion after an earned pronunciation, including account-private restore at 300 XP. The full main-product parity objective remains open.

## Reproduced gap

A correct final pronunciation at 299→301 saves an attempt/outcome in the native private outbox. If the session disappears before that outcome is acknowledged, the later sync saves XP and assessment but no longer has the call that records dependent Goal/repair completion. Two restore checks reproduce the gap: Goal Phonics remains at 0 with Phonics still next, and repair remains at step 0 after its pronunciation has saved. `/tmp/PiyaliPhonicsDurableFinishReproduction20261105.xcresult` retains four failed assertions in two tests (16.213 s). Private account restore, cold content loading and the closed access gate are included; this initial model reproduction is not a process-kill UI test.

The original focused pronunciation handler awaits outcome save, XP and then its dependent completion. A component unmount does not cancel that already executing JavaScript promise. The repair helper still rereads the current focus, and Goal writes check the active Goal/day; this component experiment does not establish global focus retention through every authenticated route transition. Native now preserves that continuation across process/account restoration too, as required by the handoff's earned-work invariant. This is a native persistence adaptation, not a claim that the web persists a corresponding browser job after termination.

## Native continuation and ownership

A successful focused pronunciation queues a `PhonicsFinishIntent` with its existing attempt receipt, account, target/support/day and actual Goal/repair context before the atomic local save. It does not contain a new answer, grading prompt or provider request. Sync/acknowledgment recovery resumes the same original completion checks and clears only the matching intent after the required saves acknowledge. Partial successful decks retire their saved continuation without completing a mode. Source-style unsuccessful attempts do not trigger completion just because another cached card already succeeded.

Automatic recovery and the active card's save retry share an in-flight task. Old cleanup cannot remove a newer attempt's intent. Account/session, target/support/day and Goal/repair context remain checked across awaits; signout cancels the old tasks. Stale same-target contexts retire only after their saved receipts clear, without completing a replacement Goal. Other targets/accounts do not acquire new completion. The private marker survives snapshot rebase and is omitted from the shared `iosStateJSON`; a server-only snapshot cannot introduce this private continuation.

Older native pending successful attempts can migrate only with their matching still-queued focused receipt and saved outcome. Capture happens before either explicit sync or the automatic cloud coordinator sends its snapshot, so acknowledgment cannot remove the proof before migration. Acknowledged cached successes without an interrupted-attempt proof do not infer mode completion on boot. Older already-acknowledged outcomes with no remaining receipt cannot be safely distinguished from an ordinary completed cache; they are not automatically promoted.

Recovery runs behind the existing subscription gate. It does not open a new practice surface, grade again, play uncached narration, start another practice session or grant paid access. Native subscription presentation stays unchanged. Existing mounted earned-result/save Retry behavior remains in the trial record. Physical audio, actual payments and full web-authenticated routing have their separate unverified scopes.

## Verification progression

The first correction passes both original restore checks in `/tmp/PiyaliPhonicsDurableFinishFirstFix20261105.xcresult` (10.615/10.556 s). Twenty selected Core checks pass (2.093 s), including private JSON restore, rebasing a newer continuation over an older acknowledgment and preventing retired-marker resurrection. Nineteen native flow checks pass in the following recovery bundle (110.848 s), including cold private restore, receipt-backed legacy migration, no inference from acknowledged caches, stale replacement Goal, existing offline preparation, verdict/reservation ownership and rendered trial save/Collect cases.

The first SDK test used a minimal public Goal blueprint without an objective. Its mode completion and reward checks passed, but its demonstrated-evidence count failed (0 instead of 1): the source-aligned reducer refuses evidence with an empty target. The corrected fixture supplies the actual product's nonempty objective; the assertion is retained. `/tmp/PiyaliPhonicsDurableFinishRecovery20261105.xcresult` contains that failed SDK expectation, alongside the separately passing native flow scope. It is not a wholly green bundle.

## Remaining scope

The next confirmed preparation gap is fresh Goal flashcards: their artifact save still blocks the source local fallback during remote failure. Earlier already-acknowledged unmarked outcomes cannot infer a missing completion without evidence of an interrupted attempt. Broader cross-target/day recovery and stale snapshot/receipt ordering, other learning modes, arbitrary-objective Tutor fallback, full-product viewports/toast composition, physical speech/playback/accessibility and provider/signing/App Check/payment gates remain open. Reference files and the separate native Firebase/Cloudflare services are preserved; external `/citizenship` and `/links` remain excluded.


The original component's held-XP check passes (16.561 s): both Goal and repair run their actual Practice/Record/wrong/Try again/correct handlers, pause at the XP boundary, unmount the real React root, release the promise and record exactly one completion afterward. Its observation is checked against the original completion expression. The account/store/grade/XP boundaries are explicit public fixtures; this proves component promise continuation, not full authenticated browser navigation or tab/process persistence.

The corrected SDK check passes (49.509 s) for Goal and repair: both the pronunciation transaction and its dependent completion commit while their responses are repeatedly lost; two private account restores and concurrent syncs retain the same earned continuation until acknowledgment. Final account subscription XP is 301, target/practice XP rises by exactly 2, assessment count remains one, completion evidence is recorded once and the marker is absent from the shared server snapshot. These checks use only the named loopback `demo-piyali-ios` database.

The earlier process-kill UI journeys pass (Goal 92.957 s; repair 102.268 s) even though their containing SDK/model bundle has the fixture failure above. A read-only audit of the two scoped QA account files independently verifies final Goal XP 4 / three assessments / one mode event, repair XP 6 / four assessments / one step/evidence event, 301 subscription XP for both and no pending finish/practice/Goal/repair receipts. Full app signup, onboarding, Paper/setup/placement, miss/retry, Collect and final pronunciation occur before the actual terminate calls; an offline relaunch and an online relaunch both keep the subscription gate visible and expose no new Phonics or next-lesson controls. The main green run repeats these journeys after the narrow legacy matching-outcome guard was added. A later cloud-first migration correction is verified separately below.


## Main verification and retained evidence

| Check | Passing result | Exact scope |
| --- | --- | --- |
| Core | 20 tests, 2.093 s | Existing original authored/cache/Goal/companion cases plus JSON/rebase/newer-intent/retirement proof |
| App/source/SDK | 24 tests, 238.791 s | 21 native flow cases (115.182 s), actual SDK transaction-result loss/repeated restore (49.509 s), source unmount continuation (16.561 s), normal 16-state English/light and Arabic/dark source/native regression (57.538 s) |
| Full native termination journeys | 2 tests, 194.645 s | Goal 92.356 s; repair 102.289 s; real entry/setup/controls/process kills and gated offline/online relaunch |
| Production cloud coordinator | 1 test, 11.061 s | Same native continuation through automatic retry coordination, without deadlock, reward/assessment replay or access grant |
| Read-only QA snapshot audit | Pass | Correct 301-XP gate, per-flow XP/assessment/completion counts, retired continuations and empty practice/Goal/repair outboxes |

The main wholly green bundle is `/tmp/PiyaliPhonicsDurableFinishVerified20261105.xcresult`, log `/tmp/piyali-phonics-durable-finish-verified-20261105.log`. The coordinator check is separately green in `/tmp/PiyaliPhonicsDurableFinishCoordinator20261105.xcresult`, log `/tmp/piyali-phonics-durable-finish-coordinator-20261105.log`. The coordinator-only run added a test without changing production code. A subsequent cloud-first legacy test then exposed one remaining migration ordering bug, described below; the main historical bundle does not cover that final one-line fix. Historical main-bundle and coordinator test-product hashes are distinguished in the manifest. All runs pinned isolated QA device `CE8248B6-7171-4FD4-97DE-89E499107F82`; the regular simulator was not modified. One Swift build/test ran at a time.

[The evidence manifest](native/phonics-durable-finish-b269524d/manifest.json) retains 13 hashed artifacts: two original source held-XP frames, two public inputs, two actual source completion-after-unmount traces, six full-phone native before-termination/offline-relaunch/online-recovery frames and the privacy-limited QA snapshot audit. It also records all 32 normal comparison-original hashes from the final regression, relevant source/native hashes and revision-labeled tested product sets. Other original regression frames remain in the named result bundle; the earlier [focused content pairs](FOCUSED_PHONICS_HANDOFF.md) retain their own historical scope.

Reviewed [source Goal awaiting XP](native/phonics-durable-finish-b269524d/source-goal-awaiting-xp.png), [native earned Goal before termination](native/phonics-durable-finish-b269524d/goal-before-termination.png) and [native repair after online recovery](native/phonics-durable-finish-b269524d/repair-online-recovered.png). These are different network/lifecycle phases, not a matched full-viewport failure-design claim. The source shows its original busy grading state while the held promise waits; the native failure frame retains the correct verdict plus the source catch-all grading-error wording and inline Retry. Source toast versus inline error, dock compositing, physical audio and whole-shell design remain open. No new generic recovery screen replaces the native Phonics or subscription views.

The read-only preview was stopped after verification. Its three unrelated historical source manifests were restored to their prior bytes. Separate native Firebase/Cloudflare configuration and reference files remain unchanged.


## Final cloud-first legacy ordering correction

A legacy profile can start automatic cloud retry before public `sync()`. The new constructor-level test calls the real coordinator first and reproduces lost completion: the queued legacy receipt is acknowledged before migration, leaving mode progress 0 instead of 2 (one failure, 3.328 s, `/tmp/PiyaliPhonicsLegacyCloudFirstReproduction20261105.xcresult`). Production now captures the same receipt-backed continuation immediately before that automatic cloud save, in addition to the explicit sync path.

On this final code, `/tmp/PiyaliPhonicsDurableFinishLegacyOrderVerified20261105.xcresult` passes all 23 native flow checks (131.782 s) and the real SDK outcome/completion result-loss check (50.012 s), 24 tests total (181.794 s). Both modern coordinator recovery and the legacy cloud-first reproduction pass. These final checks are separate from the original source/component comparisons above; the one-line hook changes no presentation or source fixtures.

The final process-termination journeys pass on the corrected code in `/tmp/PiyaliPhonicsDurableFinishLastJourneys20261105.xcresult`: Goal 96.283 s, repair 101.818 s, 198.102 s total. The scoped read-only QA audit passes again, verifying exact XP, assessment, completion and retired-receipt counts. The six retained native frames and audit now come from this final UI run; the six source artifacts retain their earlier main-bundle scope. Final source hashes and final UI product hashes are recorded separately from the historical main/coordinator products.

Reproduce the main scopes with the named local `demo-piyali-ios` emulator and read-only preview running, using a new result path:

```sh
swift test --filter 'FocusedPhonicsPolicyTests|FocusedDeckProgressTests|GoalPracticeTests|CompanionQuestTests'
TEST_RUNNER_PIYALI_OFFLINE_TESTS=1 TEST_RUNNER_PIYALI_PHONICS_FIXTURE=1 \
TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1 TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1 \
TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)" \
PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 scripts/test-ios.sh \
-parallel-testing-enabled NO -only-testing:PiyaliTests/FocusedPhonicsFlowTests \
-only-testing:PiyaliTests/FocusedPhonicsComparisonTests/testOriginalFocusedCompletionContinuesAfterUnmountWhileXPIsAwaited \
-only-testing:PiyaliTests/FocusedPhonicsComparisonTests/testOriginalFocusedDeckAndPracticeWrongRetryCorrectAgainstNativeInEnglishAndArabic \
-only-testing:PiyaliTests/FirestoreContractTests/testDurableGoalAndRepairPhonicsRestoreAcrossLostOutcomeAndCompletionResponsesWithoutDuplicatingReward \
-only-testing:PiyaliUITests/FocusedPhonicsJourneyTests/testGoalPhonicsTerminationBeforeAcknowledgmentRecoversBehindTheTrialGate \
-only-testing:PiyaliUITests/FocusedPhonicsJourneyTests/testRepairPhonicsTerminationBeforeAcknowledgmentRecoversBehindTheTrialGate \
-resultBundlePath /tmp/NewPhonicsDurableFinish.xcresult
```

The added coordinator method is included by the class filter on a new run. For the post-UI audit, record `{ "startedAt": <Unix seconds before that UI run>, "device": "CE8248B6-7171-4FD4-97DE-89E499107F82" }` in a task-owned JSON file, then run `python3 scripts/audit-phonics-recovery-qa.py --since <that file> --output <new audit path>`. The script reads only the scoped QA simulator profiles and exports counts/hashes, not names, keys, notes or full profiles.
