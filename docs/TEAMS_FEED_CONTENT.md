# Teams retained feed content and metadata — 2026-11-06

Reference: read-only `RobotsBuildingEducation/nosabos` at **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `ea75a22`. This advances FUNC-10 / DES-08. The complete main-product objective remains **In progress**.

## Confirmed source behavior and native correction

The actual source adapter returns all fetched notes before `TeamFeed` sanitizes author names and decides which cards to render. An ordinary note survives in the profiles array even though `renderPost` returns null. Question zero and scholarship-only notes also render no card in the current source. A nonempty sanitized array with no renderable cards therefore produces a blank feed, not the empty-message box. Mixed input renders only its qualifying cards; it does not expose the other note bodies.

The shared source cache chooses 120 seconds versus 15 seconds from its raw result, before author filtering. A successful response containing only banned authors remains a nonempty raw cache for two minutes even though the UI displays the empty box. Native previously discarded non-milestone notes and used the filtered array to choose its expiry, incorrectly showing an empty message and re-querying too soon.

Native feed records now retain signed notes within the existing native event bounds independently of optional milestone classification. The existing exact author-name filter still applies. Cache state separately remembers whether the successful raw response contained notes, so unknown or completely filtered input uses the original two-minute expiry. The cache timestamp is now taken when the fetch result arrives, as in the source, rather than at request start. A controlled clock advances beyond a cache lifetime while a metadata reply is held, then verifies fresh post and normalized-empty results from completion time. The separate legacy sharing utility continues displaying milestone cards; it does not start rendering arbitrary notes as a consequence of the shared record change.

The unchanged source adapter also catches synchronous metadata subscription setup failure and returns an empty result. Native main-product reads now treat note/profile fetching as one operation: a failed metadata query normalizes the whole result to empty, while preserving its diagnostic. Successful metadata EOSE with no matching profile uses the original `New Private User` fallback and keeps the post. The native standalone utility retains its existing soft metadata fallback policy.

This is scoped boundary evidence. A source NDK subscription that never emits EOSE can remain pending; native retains its existing bounded transport. Controlled source setup rejection and native relay rejection do not prove identical production NDK outage timing. Invalid metadata JSON/non-string names, older replaceable metadata delivery and broader relay combinations remain open.

## Verification and diagnostics

The baseline run against native `ea75a22` fails **both new signed-relay tests, five assertions**: ordinary note retention, nonempty raw-cache expiry, entirely filtered raw-cache expiry and metadata-failure behavior. It is retained as a failure. The original source probe independently confirms ordinary/banned raw retention, missing-profile fallback, metadata setup rejection and the two-minute raw-cache clock.

The original browser component is compared in English/light and Arabic/dark for six states: ordinary, question zero, scholarship-only, banned author, mixed input and adapter fallback name. The same original adapter callback is extracted by AST offsets and executed without rewriting its body; only NDK I/O is supplied. Source cache code is imported unchanged. None of these source fixtures authenticates a source learner, publishes events or verifies a production NDK relay.

**Eleven final iOS XCTest cases pass, zero failures/skips:** nine app cases (30.881 s), including eight signed-relay/cache/identity contracts and the actual source/native comparison; both actual product journeys (213.019 s: Arabic 112.429 s, English 100.590 s) pass on the same final implementation. Core regression checks also pass: four tests (0.061 s), including all 42 existing community fixtures and 134 original Teams policy cases, zero failures.

**Twenty original-source checks pass:** twelve actual browser scenes, four unchanged extracted adapter cases, two raw-cache expiry cases and two held-response completion-clock cases. The native comparison captures twelve equivalent source/native pairs in English/light and Arabic/dark. The six source blank/empty/mixed/fallback states were not replaced with generic screens. Final ordinary-blank, filtered-author, mixed-progress and fallback frames were visually inspected as well as content/count assertions.

The real native journeys create/onboard a disposable identity, change Arabic through actual Settings where applicable, open Teams → Global feed, verify a signed ordinary note yields a blank feed, close/reopen from cache without a relay request, then terminate/relaunch through filtered-author empty, metadata-failure empty, missing-profile fallback and mixed signed progress recovery. Both verify one rendered qualifying post and no rendering of the ordinary note body, and reject unsolicited publishing. Controlled-clock SDK checks independently cover longer-than-TTL logical time while metadata is held and post/normalized-empty expiry after completion.

## Evidence and commands

The [manifest](native/teams-feed-content-b269524d/manifest.json) hashes **69 artifacts** and nine implementation/test/harness inputs. The [evidence directory](native/teams-feed-content-b269524d) retains all 36 original component PNG/geometry attachments, twelve normalized source-left/native-right pairs, twelve actual product frames, the failed baseline/individual assertions, final test results, Core output, original source callback/cache/browser results and matching built/installed QA hashes. See [ordinary blank](native/teams-feed-content-b269524d/pair-feed-ordinary-en.png), [filtered Arabic empty](native/teams-feed-content-b269524d/pair-feed-banned-ar.png), [mixed Arabic content](native/teams-feed-content-b269524d/pair-feed-mixed-ar.png), [fallback](native/teams-feed-content-b269524d/pair-feed-fallback-en.png), [actual Arabic blank](native/teams-feed-content-b269524d/ui-native-ordinary-blank-ar.png) and [actual missing-profile recovery](native/teams-feed-content-b269524d/ui-native-missing-profile-fallback-en.png).

All simulator operations are pinned to isolated QA `CE8248B6-7171-4FD4-97DE-89E499107F82`. Regular simulator `5CEE88FE-AE9D-4982-88BE-3FB739281A80` and its learner are preserved. Native events use a loopback relay; team/account I/O uses the existing local `demo-piyali-ios` emulator. Signed native wire tests are not production relay or authenticated source-App checks. The read-only source remains unchanged. The owned preview is stopped after testing, and its three unrelated regenerated native manifests are restored to their initially clean bytes.

Start `node scripts/start-reference-preview.mjs` and wait for the ready URL. Source checks use `node scripts/check-teams-feed-content.mjs --out /tmp/piyali-teams-feed-content-source-delivery-20261106.json`; Core checks use `swift test --filter 'CommunityFeedTests|TeamsPanelPolicyTests'` before any Xcode build. With the QA device explicitly in `PIYALI_TEST_DEVICE`, a new `TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE` UUID, and `TEST_RUNNER_PIYALI_OFFLINE_TESTS=1`, `TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1`, `TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1`, the final iOS command is:

```sh
scripts/test-ios.sh -parallel-testing-enabled NO \
  -only-testing:PiyaliTests/CommunityFeedTests \
  -only-testing:PiyaliTests/TeamsPanelReferenceTests/testOriginalRetainedNonMilestoneFilteredMixedAndFallbackFeedScreens \
  -only-testing:PiyaliUITests/TeamsTests/testRawFeedBlankCacheFilteredMetadataAndMixedRecoveryInArabicProduct \
  -only-testing:PiyaliUITests/TeamsTests/testRawFeedBlankCacheFilteredMetadataAndMixedRecoveryInEnglishProduct \
  -resultBundlePath /tmp/piyali-teams-feed-content-delivery-20261106.xcresult
```

Use fresh result paths for future runs. Baseline `/tmp/piyali-teams-feed-content-baseline-20261106.xcresult` remains failed. An intermediate eight-case app run and two product journeys passed before adding completion-time cache coverage; only the final combined eleven-case delivery run above establishes the final implementation. Attachments are exported only after each process is terminal. Swift sources are never edited during a live Swift build/test. No production deployment, regular-simulator install, merge or publication is included.

## Remaining scope

This does not close the Teams or overall product goal. Full NDK/provider outage/hang/malformed metadata/replaceable-profile behavior, large feeds/rosters and existing event-size/cap boundary equivalence, legacy/cache-only team UI, concurrent invitations, whole-shell layout/portal/motion, broader scripts/sizes/accessibility, physical audio, payments and release gates remain open. Source/backend schemas, the separate Piyali Firebase/Cloudflare services, custody and opt-in publishing remain unchanged. No deployment, merge or publication is included.
