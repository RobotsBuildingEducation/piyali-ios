# Focused flashcard decks and saved handoffs — 2026-11-05

Scoped continuation of [PARITY_HANDOFF.md](PARITY_HANDOFF.md), against read-only reference `b269524ddc578027c549616fc47f5954991d9f6f`. The overall main-product parity goal remains open.

## Corrected behavior

- Goal cards now execute the original `getGoalFlashcards` prompt/parser/floor/card construction through the source policy. The prompt includes current performance context and removes `scoreAtGeneration`. Invalid, empty, failed and sparse generation keeps the original three-card fallback, numbered repeated cues, 180-character bounds and same-language overwrite behavior. Cached decks survive reentry without another provider request. Cancellation and changed identity/session/course scope reject a late response.
- Goal recall evidence now uses the source `recall:<card>:<success>` semantic ID and its explicit “not independent production” observation. Repeated unsuccessful recalls no longer inflate capability recurrence. The three-card completion observation and artifact-based evidence ID also come from the original component. Native outbox receipt IDs remain independent and idempotent.
- A focused rail displays the source answered/total introduction, and marks only acknowledged successful outcomes complete. An account-local cache retains previously acknowledged cards while later work is pending or a save fails. The cache survives private native restoration and is stripped from `iosStateJSON`; shared `questDays` artifacts remain authoritative. Reopening a failed Goal save still requires acknowledgment of the existing pending work before closing or routing forward.
- The grade can display +6 XP, while a successful Good/Easy choice banks the source's 2 focused XP. No ordinary review schedule or review-activity counter is written.
- Dashboard counts and course completion continue to describe the ordinary authored/custom SRS library during focused practice. Focused cards do not become ordinary scheduled reviews. The focused rail’s own progress is separate.
- The rail title now comes from the original expression (including Arabic “مراجعة سريعة”), and the iPhone card screen uses the flat source page background. Library panels use the source soft shadow. Dark actionable tiles regain the source two-second colored spread pulse; reduced motion keeps a static border. Arabic XP uses an explicit RTL text isolate to match the source order.
- Removed native-only summary banners from this card screen. The reference `SkillTree` mounts its level navigator, course header and `FlashcardSkillTree`; neither `GoalFocusBanner` nor `RepairFocusBanner` is mounted there. The standalone Goal banner used by the reference Astra browser harness does not prove a main-route card banner.
- Flashcard grading now also rejects signout and re-import of the same key under a new identity session. The shared source-style text provider retains native Firebase/Cloudflare configuration; it is reused for Goal deck generation without changing service destinations.

## Evidence and boundaries

`scripts/export-focused-flashcards.mjs` independently runs the original full async factory and the original recall/completion expressions. It bundles the original pure performance module separately from the production adapter. The 13 public cases cover exact/sparse generation, invalid entries, failure/empty/malformed replies, empty goals/chunks, same support and target language, truthy non-string values, long cues and Arabic support. Hashes and public vectors are committed with the fixture. No web Firebase service, web account or source file is written.

`FocusedDeckProgressTests` covers acknowledgment, private restore, another answer arriving during sync, and preservation of earlier confirmed Goal/repair cards. `FocusedFlashcardFlowTests` exercises the actual native generator and card controller, offline failure, close/reopen/offline retry, acknowledged retry, all-three completion, XP once, unchanged SRS, source semantic evidence and same-key-session rejection. The controlled save boundary is explicitly in-process; it is not a production network proof.

`FocusedDeckJourneyTests` uses disposable isolated simulator identities, the real native signup/onboarding/setup/placement controls, cached acknowledged public decks, fixed grading/note providers and a fixed lesson question and an acknowledgment-only save service. It answers actual cards through the native modal and chosen rating. Goal proceeds to its next lesson while a deliberately delayed note continues, then restores the lesson/note after relaunch. Repair proceeds to its next repair lesson and restores it after relaunch. No answers or rewards are seeded. The strict DEBUG fixture requires offline mode, a valid UUID scope and an explicit scenario; it cannot run in a regular launch.

`FocusedFlashcardComparisonTests` renders the original web tree in WKWebView, with public cached artifacts and recording I/O boundaries, beside the actual native view. English/light and Arabic/dark cover Goal 1/3 and repair 1/2. Both retain the ordinary library’s new-card count. The test also clicks the original web tile, types into its original grading modal and chooses Good, recording the actual outcome/evidence/XP/completion calls. It asserts 2 XP per success and no completion before the last card. These programmatic DOM control events do not prove browser touch targeting. These isolated 402-point content captures omit product chrome, device keyboard and real account/provider services. Native full-phone journey captures separately cover native routing and modal interaction. Static component comparisons do not establish complete viewport or main-app web routing parity.

## Validation ledger

| Check | Final result | Scope |
| --- | --- | --- |
| Core | 24 tests, 0 failures, 10.438 s; `/tmp/piyali-focused-deck-final2-core-20261105.log` | New 13-case factory oracle/projections plus original companion, Goal, Memory, Flashcard prompt/theme/schedule and receipt/rebase contracts |
| App/source/emulator | 8 tests, 0 failures, 59.625 s | Four actual native flow checks; focused original render/control/evidence comparison (31.656 s); ordinary source/native library regression (19.333 s); two real Firebase SDK emulator contracts (7.883 s) |
| Native journeys | 2 tests, 0 failures, 229.895 s | Goal note/next lesson/relaunch 140.182 s; repair next lesson/relaunch 89.713 s |

The final app/source/emulator and UI results are together in `/tmp/PiyaliFocusedDeckVerified20261105.xcresult`, log `/tmp/piyali-focused-deck-verified-ios-20261105.log`. All runs pinned `CE8248B6-7171-4FD4-97DE-89E499107F82`; the regular simulator was not changed. No concurrent Swift builds/tests ran. Source preview has been stopped. The reference stayed clean at the revision above. No backend deployment or ignored service/key file was changed.

Final public inputs, original source completion writes, original/native PNGs, geometry, 31 artifact hashes, relevant source/native hashes and tested-product hashes are in [the manifest](native/focused-flashcards-b269524d/manifest.json). Reviewed pairs: [Goal English/light](native/focused-flashcards-b269524d/goal-en-pair.png), [repair English/light](native/focused-flashcards-b269524d/repair-en-pair.png), [Goal Arabic/dark](native/focused-flashcards-b269524d/goal-ar-pair.png), [repair Arabic/dark](native/focused-flashcards-b269524d/repair-ar-pair.png). The pairs normalize tagged originals into sRGB for display; original full-resolution PNGs retain their profiles. The compared copy, library count, progress and section/card placement align in these states. Rasterization, gradient/blur composition and animation phases differ; this is not pixel-perfect or motion approval. The fixed next-lesson question proves routing, not generated lesson quality or the complete next lesson.

Reproduce with the read-only preview running, the existing `demo-piyali-ios` Firestore emulator on loopback port 8180, and a valid isolated UUID:

```sh
swift test --filter 'FocusedDeckProgressTests|GoalPracticeTests|CompanionQuestTests|SyncChangesTests|GoalMemoryCaptureTests|FlashcardSessionTests'
TEST_RUNNER_PIYALI_OFFLINE_TESTS=1 TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE="$(uuidgen)" \
TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1 TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1 \
PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82 scripts/test-ios.sh \
-parallel-testing-enabled NO -only-testing:PiyaliTests/FocusedFlashcardComparisonTests \
-only-testing:PiyaliTests/FocusedFlashcardFlowTests \
-only-testing:PiyaliTests/FlashcardFlowTests/testOriginalDeckAndNativeLevelHeaderQueuesAndLocksInEnglishAndArabic \
-only-testing:PiyaliTests/FirestoreContractTests/testGoalPreparationDeckAndOutcomesUseSharedQuestArtifact \
-only-testing:PiyaliTests/FirestoreContractTests/testCompanionBlueprintLeaseCanonicalMirrorsAndRepairEvidenceSurviveRetries \
-only-testing:PiyaliUITests/FocusedDeckJourneyTests -resultBundlePath /tmp/NewFocusedDeckRun.xcresult
```

Earlier nonfinal results: A preliminary native Goal run reached the next lesson with the note request pending, then failed on a nonexistent test identifier (`memoryNotesLevel-A1`). The test now uses the existing `memoryLevel-A1` control and the note-row label. The drawer intentionally groups Pre-A1 notes under A1, as before. The same preliminary repair journey passed in 91.221 seconds; it is not substituted for the final run. The first comparison attempt did not compile because the new test assigned a read-only level property and indexed JSONValue as an array; those test errors were corrected. The subsequent render/model/two-journey bundle passed before the final shadow/background/title/pulse changes. The first source control-event extension failed because the preview cached the old entry without `runFocusedRecall`; file watching and a preview restart fixed it. Both emulator contracts in that containing failed bundle passed. Only the final bundle above is counted as green final integrated evidence.

## Remaining gates

- Live focused Goal generation is subsequently verified in [offline preparation](FLASHCARD_OFFLINE_PREPARATION.md) through authenticated configured and Responses paths with English/Arabic cues. That scoped check does not establish release attestation, general content quality or all providers. The deterministic evidence above retains its original scope.
- Failed-save presentation still uses the native inline error; the source uses a toast. Native retries retain the chosen pending rating in an open modal to preserve its immutable earned intent. Changing ratings after a failed save, overlapping devices, stale legacy pending snapshots without an acknowledgment cache, and day/support changes need further integrated UI evidence. Legacy pending snapshots conservatively show no confirmed outcomes until synchronization when no old confirmation can be recovered.
- The comparison checks focused card content/controls and the normal library dashboard, not every locale, authored/custom library, Dynamic Type size, animation, VoiceOver path, full web app routing, repair plan, phonics mode or provider failure viewport. The repair journey stops at the next repair lesson; it does not claim that the whole subsequent repair plan has completed.
- Main-product coverage, design, cross-mode journeys, physical audio/accessibility, signer, Teams/Nostr, wallet, payment/subscription and release gates in the handoff remain open unless newer feature-specific records provide their own scoped proof. Separate native Firebase/Cloudflare services and the read-only reference are preserved. `/citizenship` and `/links` remain excluded.

Fresh Goal artifacts during remote failure are subsequently corrected and verified in [offline preparation](FLASHCARD_OFFLINE_PREPARATION.md), with fresh source cache/control comparisons and native/SDK restore scopes. Earlier cached-deck evidence above retains its original scope.
