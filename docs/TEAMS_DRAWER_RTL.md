# Teams drawer direction and forms — 2026-11-06

Read-only source: `RobotsBuildingEducation/nosabos` **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `b092bfd`. This advances FUNC-10 / DES-08; the full functional/design parity objective remains **In progress**.

## Source behavior

The actual document-language conductor sets Arabic to RTL. Although most Teams copy falls back to English, the drawer's tabs, action rows, team/member cards, metric grid, companion row, invitations and editor forms mirror. The native drawer previously forced LTR even after its separate notices were corrected.

Physical exceptions matter. Drawer/editor close controls stay at the physical right. `WaveBar` pins its fill to CSS `left:0` and its gradient runs left to right; those do not mirror with the surrounding health row. Feed cards explicitly use `textAlign="left"` while their header flex row mirrors. The source also places editor headings under the physical-right close control in RTL; that overlap is preserved rather than silently redesigned.

## Native changes

- The drawer follows support-language direction. Its plain-text rendering uses a matching paragraph base even with English fallback copy, while accessibility retains the raw text. Interface changes preserve the mounted controller and account/session ownership.
- Cards, metric order, member language/name positions, companion/name/health rows, invitation actions, creation/addition rows, queued members and editor footers mirror. Source progress fills remain physically left-pinned; close controls stay physically right.
- Text fields align to the source physical text edge independently of the mirrored parent row. Their values, validation and signed/backend payloads remain raw; display direction never inserts markers into editable names or public keys.
- Queued members now use the source's bordered row, 12-point text, 24-point remove control and original 8-point close glyph. WebKit's RTL one-line clamp clips the Latin prefix at the right and paints an ellipsis at the physical left; native reproduces that presentation and exposes the complete ID to accessibility.
- Dark member/card surfaces use the actual Chakra alpha tokens (`whiteAlpha.50/.100/.200` are 4/6/8%, not 5/10/20%). Source member/companion borders and queued text color follow those tokens.

## Verification

**Five affected XCTest cases pass, zero failures/skips in the final retained runs:** three component checks (105.236 s), the Arabic management/relaunch journey (142.746 s), and the English management/relaunch journey (131.199 s). The three component methods contain **30 source/native scene pairs**: 16 drawer/card/form/feed states, two held-loading states and 12 notice states. Content/capture assertions are supplemented by visual inspection; they are not a claim of complete pixel or product parity. The source is rendered unchanged in WKWebView, using public external-I/O fixtures. These component comparisons are not an authenticated source App/browser or production-service check.

The real native management journey switches from English to Arabic through Settings, then copies its ID, dismisses the actual notice, tests an invalid invite, replaces the field value, queues a valid member, creates a signed team, renames it, adds another member, terminates/relaunches, deletes and relaunches again. It asserts mirrored control order and physical-right close placement; both relaunches recheck direction. Exact raw replacement values and exact team names prevent substring assertions from masking incorrect edits. The English journey covers the same operations.

### Diagnostics retained honestly

A passing capture/content test was not proof of design parity. Baseline and early iteration captures exposed the forced LTR layout, incorrectly aligned fields and missing queued-row styling. A draft clamp renderer failed to compile due to a missing closure brace; no tests ran in that attempt.

Right-aligned fields exposed the old test driver's caret assumption: tapping the empty center then backspacing could leave the previous text and produce an invalid invite. A subsequent edit-menu driver encountered XCTest's system-menu hit-point/interruption failure during rename. Those runs were interrupted and remain failed, rather than being counted as successful journeys. A physical-end/backspace draft also failed its clearing assertion and remains a failed diagnostic. The final driver selects the actual Latin word at its visible position for each direction, verifies the exact replacement before Return, and checks exact saved names. The final Arabic and English journeys pass with this driver.

## Evidence and commands

See the [baseline Arabic mismatch](native/teams-drawer-rtl-b269524d/baseline-pair-single-ar.png), [final Arabic card](native/teams-drawer-rtl-b269524d/pair-single-ar.png), [queued form](native/teams-drawer-rtl-b269524d/pair-queued-ar.png), [rename form](native/teams-drawer-rtl-b269524d/pair-rename-ar.png), [actual private relaunch](native/teams-drawer-rtl-b269524d/ui-ar-native-teams-restored-product.png) and [manifest](native/teams-drawer-rtl-b269524d/manifest.json). Originals, source geometry, normalized sRGB source-left/native-right pairs, UI phase captures, per-run summaries and final installed/build hashes are retained. Small font/truncation/raster differences remain visible; the source's closing-control overlap is deliberately not hidden.

All simulator operations use isolated QA `CE8248B6-7171-4FD4-97DE-89E499107F82`. The regular simulator is preserved. Native signed events use a loopback relay; private/mirror mutations use the existing isolated local Firebase emulator. The source components' public I/O fixture does not prove authenticated source writes or production-service behavior. Source schemas, services and policy extraction are unchanged.

Start the owned read-only preview with `node scripts/start-reference-preview.mjs`, wait for its ready URL, and restart after changing virtual fixture modules. Use a fresh `TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE` UUID, `TEST_RUNNER_PIYALI_OFFLINE_TESTS=1`, `TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1`, and the explicit QA device above:

```sh
scripts/test-ios.sh -parallel-testing-enabled NO \
  -only-testing:PiyaliTests/TeamsPanelReferenceTests \
  -resultBundlePath /tmp/piyali-teams-drawer-rtl-app-final-20261106.xcresult
```

The UI runs additionally set `TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1`. Their selectors and retained result bundles are:

| Selector after `PiyaliUITests/TeamsTests/` | Result bundle under `/tmp` |
| --- | --- |
| `testArabicSettingsThenCreateRenameAddAndPrivateRelaunchUsesMirroredNativeTeamsControls` | `piyali-teams-drawer-rtl-word-selection-20261106.xcresult` |
| `testCreateEditRosterAndDeleteUseSignedLocalRelayAndSurviveRelaunch` | `piyali-teams-drawer-rtl-english-final-20261106.xcresult` |

The baseline capture run passed its capture assertions in 61.550 s **while showing the RTL mismatch**. An initial mirror capture passed in 60.299 s; the next capture plus initial Arabic/English journeys passed, but those forms still showed an incorrect native text edge. These are earlier diagnostics, not the final design proof. The draft `piyali-teams-drawer-rtl-final-20261106.xcresult` did not execute because its clamp renderer was missing a closure brace. The `rtl-delivery`, `rtl-editing`, and `rtl-verified` diagnostic bundles had passing app checks and/or partial UI progress but failed during old caret/edit-menu handling; they were explicitly interrupted with exit 73. Their failed summaries remain failed. No blanket green claim is made for those mixed bundles.

## Remaining scope

This does not close all Teams or main-product parity. Feed loading/empty/error cards and its complete content/spacing presentation remain open, along with exact shadow/rasterization/motion, wider text/script/OS-locale/size/accessibility matrices, large/legacy roster variants, concurrent invitations, complete streamed/cache-only roster UI and production outage/grant combinations. Physical audio, account/payment/release and the other handoff requirements remain separate open gates. Source/backend schemas, private progress, signed-roster verification and separate Piyali Firebase/Cloudflare services are preserved. No deployment, merge or publication is included.
