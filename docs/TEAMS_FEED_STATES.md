# Teams feed state and content parity — 2026-11-06

Read-only source: `RobotsBuildingEducation/nosabos` at **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `4307cdd`. This advances FUNC-10 / DES-08. Complete product parity remains **In progress**.

## Confirmed differences and implementation

The previous drawer stored feed failures in the shared roster/action diagnostic and never rendered a feed error. It showed an unbordered empty label and kept rendering old posts beneath the loading state. Its fixed-cache source fixture could not exercise real cache or recovery behavior.

The native feed now owns its own error independently of roster refreshes and management notices. Exclusive branches follow the original component: loading, error with Refresh, empty bordered card, or posts. A cold/forced fetch hides posts; a cached background fetch keeps them visible until failure replaces them with the error card. Refresh clears the error, forces the shared request and displays loading; success replaces the feed with posts or the successful empty result. Repeated taps/requests coalesce, and account/session/closed-controller guards reject stale results. A successful empty cache remains distinct from an unloaded feed. A still-valid cache after a failed forced read can be used successfully, without inheriting that failure.

The real fetch boundary matters: `useDecentralizedIdentity` catches connection/query errors and returns `[]`. Its normal main-product relay-failure path therefore resolves to a cached empty feed, rather than the component’s rejected-fetch error branch. Native Teams startup/drawer reads now use the same normalization, retaining diagnostic errors internally. A rejected injected fetch still exercises the component error/Refresh contract; it is not presented as proof that the default web adapter rejects.

Error/empty borders, six-point corners, source text colors, the blue raised Refresh control and source orb loading presentation replace the incomplete feed states. Post cards use the source's surface mixture, dark alpha borders, soft light shadow, content spacing and portrait/name treatment. Question progress is the original green gradient; daily-goal progress stays amber. Paragraphs keep the source's physical left alignment inside the otherwise mirrored header. Literal http(s) URLs are linked individually; post Markdown remains literal, as in the source.

## Verification

**27 final XCTest cases pass, zero failures or skips:** 25 app/source/relay/controller/startup checks in 101.290 s, plus both actual product journeys in 172.341 s (Arabic 93.502 s; English 78.840 s). Two capture methods cover **34 source/native scene pairs**: 18 feed/cache/content phases and 16 drawer/form/card regressions after replacing the fixed source-cache stub. Two additional contracts cover independent diagnostics, forced-read coalescing and old-account replies; five signed-relay/cache checks, twelve existing Teams controller checks and four startup checks also pass.

Six browser checks and two extracted original-adapter cases pass. Browser checks exercise the actual original `TeamFeed` and `globalTeamFeedCache`: the fixture replaces only the public fetch boundary. It seeds an expired original cache, holds/rejects requests, and uses the real Refresh button. Neither the source component nor the source cache implementation is replaced or edited.

The native comparison fixture supplies equivalent public results and captures cold loading, successful empty, initial failure, cached background refresh, cached failure, forced retry, recovered posts, ordinary progress and question/URL/literal-Markdown cards in English/light and Arabic/dark. Those component captures do not establish authenticated source App behavior, production relay availability, or complete shell parity. Native signed-relay product journeys separately exercise real signup, Settings language change, navigation, relay-failure-to-empty normalization, verified Nostr posts, cached reopen and process relaunch/empty recovery. Their failure expectation follows the default original adapter; Refresh is tested separately with an actual rejected fetch at the component/controller boundary.

## Evidence and exact runs

The [manifest](native/teams-feed-states-b269524d/manifest.json) hashes **165 artifacts** and ten implementation/test/harness files. The [evidence directory](native/teams-feed-states-b269524d) retains all 102 original source/native/geometry attachments for the 34 scenes, 34 normalized source-left/native-right pairs, eight actual product phases, representative pre-fix failures, per-run results, original browser/adapter outcomes, source/implementation hashes and matching built/installed QA hashes. See [loading](native/teams-feed-states-b269524d/pair-feed-loading-en.png), [Arabic rejected-fetch card](native/teams-feed-states-b269524d/pair-feed-error-ar.png), [literal Markdown and URL/question progress](native/teams-feed-states-b269524d/pair-feed-question-ar.png), [actual signed feed](native/teams-feed-states-b269524d/ui-native-teams-feed-signed-recovery-en.png) and [actual Arabic relaunch failure resolved to empty](native/teams-feed-states-b269524d/ui-native-teams-feed-relaunch-failure-is-empty-ar.png). Representative final loading/error/empty/progress/question/RTL pairs and actual native post/relaunch frames were visually inspected. Small text/raster/shadow differences remain; green capture assertions alone did not establish these design results.

All operations use isolated QA `CE8248B6-7171-4FD4-97DE-89E499107F82`. The regular simulator and its learner are untouched. Native verified events come from a loopback relay; team/account I/O uses the existing local `demo-piyali-ios` emulator. The source component uses public fixtures, and the two adapter cases execute the unchanged callback extracted by AST offsets; neither is an authenticated source account or a production NDK/relay test. The read-only preview is stopped after testing, and its three unrelated regenerated native manifests are restored to their initially clean bytes.

Start `node scripts/start-reference-preview.mjs` and wait for its ready URL. With `PIYALI_TEST_DEVICE` pinned to the QA device, a fresh `TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE` UUID, `TEST_RUNNER_PIYALI_OFFLINE_TESTS=1` and `TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1`, the final app run is:

```sh
scripts/test-ios.sh -parallel-testing-enabled NO \
  -only-testing:PiyaliTests/TeamsPanelReferenceTests/testActualFeedCacheLoadingEmptyFailureRefreshAndQuestionCardsInBothDirections \
  -only-testing:PiyaliTests/TeamsPanelReferenceTests/testFeedFailurePersistsAcrossRosterReloadAndForcedRetryCoalescesWithoutClearingManagementError \
  -only-testing:PiyaliTests/TeamsPanelReferenceTests/testLateFeedFailureAfterAccountReplacementCannotReappearOrStopTheNewRequest \
  -only-testing:PiyaliTests/TeamsPanelReferenceTests/testActualSourceAndNativeTeamDrawerFormsCardsFeedAndArabic \
  -only-testing:PiyaliTests/CommunityFeedTests \
  -only-testing:PiyaliTests/TeamsPanelControllerTests \
  -only-testing:PiyaliTests/TeamsStartupTests/testStartupReadsAndWatchesBeforeDrawerAndViewedSameIDsStayQuietUntilANewInvitation \
  -only-testing:PiyaliTests/TeamsStartupTests/testAccountReplacementRejectsOldLoadAndSubscriptionWithoutRestartingOnLanguageChanges \
  -only-testing:PiyaliTests/TeamsStartupTests/testPreloadedEmptyAndNonemptyDrawersRemainVisibleWhileTheirFirstFreshReadIsHeld \
  -only-testing:PiyaliTests/TeamsStartupTests/testForegroundRetriesFailedPreparationAndWatchWithoutRepeatingViewedAttentionOrAcceptingOldCallbacks \
  -resultBundlePath /tmp/piyali-teams-feed-app-delivery-20261106.xcresult
```

The separate final UI run additionally uses `TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1`, selecting `PiyaliUITests/TeamsTests/testFeedAdapterFailureSignedRecoveryAndCacheThroughActualArabicProductAndRelaunch` and `PiyaliUITests/TeamsTests/testFeedAdapterFailureSignedRecoveryAndCacheThroughActualEnglishProductAndRelaunch`, with `-parallel-testing-enabled NO` and result bundle `/tmp/piyali-teams-feed-product-final-20261106.xcresult`. Each journey uses a new scoped identity and asserts that reads/reopens/recovery never publish a Nostr event. It verifies fresh-cache reuse avoids another relay request and requires actual drawer dismissal before reopening.

Original checks: `node scripts/check-teams-feed-browser.mjs --out /tmp/piyali-teams-feed-browser-final-20261106.json`. Use new result paths for subsequent runs. Attachment exports and installed/build comparison occur only after the respective test process is terminal. No Swift source is edited while any Swift build/test process is live.

## Diagnostics

Two early builds did not run tests: the UI fixture referenced an app-target signing helper, and the new app-test subclass initializer omitted Swift's required `override`. They are failed diagnostics, not green test runs. A later 19-test run passed while captures still exposed the collapsed loading orb and a shadow behind Refresh text. Both were corrected. The next combined run was deliberately interrupted after inspecting the original default Nostr adapter: its planned UI failure expectation did not follow the source’s catch-to-empty behavior. That interrupted run is not counted as a passing final result. The fixture uses the existing UI test `ContentSigning` pattern after correction. A later combined run passed its 20 app tests but failed a UI query that assumed SwiftUI Link appears as XCTest `Link`. The captured hierarchy shows the correctly named, underlined author as a native `Button`; the driver now asserts that actual native control and requires the drawer to disappear before reopening. That mixed run was interrupted and remains a failed diagnostic.

## Remaining scope

This work does not close all Teams or main-product requirements. Remaining checks include broader real-relay outage/grant/roster combinations, default-adapter NDK subscription/EOSE hangs and full provider error/caching behavior, large/legacy/cache-only team rendering, all script/size/OS-locale/accessibility variants, full-shell portal/footer ordering and exact motion/rasterization. Source random orb personality and native renderer are not asserted pixel-identical at an arbitrary frame. Physical audio, external account/payment and release gates remain open in the handoff. Separate Piyali Firebase/Cloudflare services, custody, private learner data and opt-in publishing are preserved. No deployment, merge or publication is included.

Subsequent retained/non-milestone/filtered/mixed feed and metadata-boundary work is recorded in [TEAMS_FEED_CONTENT.md](TEAMS_FEED_CONTENT.md). Its raw-cache clock is distinct from sanitized presentation; broader NDK/provider outage and malformed-profile behavior remains open.
