# Teams notices — 2026-11-06

Reference: read-only `RobotsBuildingEducation/nosabos` **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `0e2a301`. This advances FUNC-10 / DES-08. The full parity objective remains **In progress**.

## Source behavior and native change

The original `TeamCreation` and `TeamView` use Chakra `useToast`, rather than retaining mutation/validation errors inside the form. The installed source dependency is `@chakra-ui/react` 2.10.9. Its ordinary Teams notices default to bottom placement, five seconds, and no close button. Copy success explicitly uses two seconds and a close button. Source notices have a bold title, optional regular description, and a status icon. Short notices are 300 points wide; long notices fill the available 386 points at a 402-point viewport, with 8-point outside margins and 16-point spacing between notices.

Native now preserves those payloads and lifetimes for queue validation, creation, member additions, rename, invitation responses, removal and roster reads. Creation includes the localized `teams_create_invites` description (English actually says “invites sent”). Add-member success uses the source's singular/plural English title and roster-update description. A partial rename keeps the “Team renamed” title, uses warning status, and explains that local copies may still show the old name. The source ignores `mirrorSynced` when displaying add-member success; native now follows that distinction.

The exact installed Chakra check and close paths are reused as `Teams-NoticeSuccess` and `Teams-NoticeClose`; the existing source-matched warning asset supplies error and warning icons. Native direction marks reproduce HTML RTL paragraph ordering even for fallback English punctuation; accessibility keeps the unmodified copy. Text, source colors, wrapping, padding and bottom stacking replace the old generic three-second overlay. Copy has an explicit close control. Inline form/list mutation errors and their extra Retry control are removed. Diagnostic controller errors still survive unrelated invitation/watch updates; the source's separate progress-sharing error stays inline.

An app-owned notice center gives every occurrence its own identifier and timer, including identical messages. Closing the editor/drawer does not erase the notice. Sign-out or a new account/session clears feedback. A non-key window displays feedback above editors and passes unrelated touches through. Empty notice windows are hidden, detached and released. They cannot become the keyboard/key window. Pending native confirmations suspend notice windows without discarding their payloads/timers; cancellation or dismissal restores any still-current notices.

## Verification

**15 final XCTest cases pass, zero failures/skips:** 12 controller/UIKit lifecycle checks, one rendered comparison covering **12 source/native pairs**, and two complete product journeys. The clean app run passes **13 tests in 47.703 s**. The clean UI run passes **two journeys in 221.710 s** (creation/copy close: 122.374 s; held/rejected rename and invitation recovery: 99.336 s). Both UI journeys were rerun after the final RTL/paragraph/asset changes. Earlier mixed bundles remain failed below.

- Actual signup/onboarding → copy ID → tap the two-second notice's close button → invalid invitation → queued member → signed creation → rename → add member → terminate/relaunch → delete → relaunch → empty feed passes.
- Actual signup → signed team → held rename → incoming legacy invitation → rejected relay acknowledgment → error toast with editor retained → close editor → terminate/relaunch → old signed name and invitation retained → decline → notice expiry → native confirmation → delete passes. The real client error is “No relay acknowledged this update.”; it does not expose the loopback fixture's raw rejection reason.
- The UI bounds trace proves a real overlay interaction: Delete was **enabled**, at `(324.5, 808.5, 33, 33)`, but overlapped the ordinary notice at `(51, 783.67, 300, 48.33)`. XCTest's `isHittable` did not account for the separate notice window. The journey now verifies the original decline notice and waits for its five-second expiry before tapping the covered bottom control. The actual source browser also proves interception: its bottom delete control's center falls inside the original Chakra toast. This is preserved source behavior, not a disabled-control defect.
- **Five original-browser checks pass:** error/editor retention; successful rename/editor closure and notice after drawer close; clipboard automatic expiry; actual clipboard close-button click; bottom-action pointer interception. They render unmodified `TeamCreation`/`TeamView`; only external I/O is replaced by public fixtures.
- Controller/UIKit checks cover identical-message timers, owner changes, sign-out, editor/drawer closure, non-key window behavior, empty-window release and confirmation suspension, while retaining the existing read/watch/invitation/session races.
- Source/native static comparison triggers six actual source outcomes in English/light and Arabic-support/dark: rename error, partial warning, success, invalid queue, duplicate queue and copy. The source's Teams toast text actually falls back to English under Arabic, but its containers and text alignment are RTL. Native notices follow that direction, while preserving the source's physical upper-right close control (which overlaps the status icon in the source Arabic copy notice). No translations or cleaner replacement layout were invented.

See the [English detail sheet](native/teams-notices-b269524d/notices-en-detail.png), [Arabic-support/dark detail sheet](native/teams-notices-b269524d/notices-ar-detail.png), [actual rejected rename](native/teams-notices-b269524d/native-teams-rejected-rename-retains-its-error.png), [restored old name and invitation](native/teams-notices-b269524d/native-teams-old-signed-name-and-incoming-invitation-restore.png), [native confirmation](native/teams-notices-b269524d/native-teams-deletion-confirmation-after-decline-notice.png) and [artifact manifest](native/teams-notices-b269524d/manifest.json). Full-resolution originals, source geometry, normalized sRGB source-left/native-right pairs, per-case results, complete per-run summaries and matching installed/built executable/dylib hashes are retained there.

Component comparisons replay native notice presentation and **do not exercise native actions**. Separate full native product journeys exercise those actions with disposable identities, a signed loopback relay and the existing local Firebase emulator. Public original-component fixtures are not a fully authenticated source App/browser or production service test. All simulator work uses isolated QA `CE8248B6-7171-4FD4-97DE-89E499107F82`; the regular simulator and read-only reference remain untouched.

### Commands and retained failures

Start `node scripts/start-reference-preview.mjs` and wait for its READY URL. Restart it after changing virtual fixture modules: those modules are cached. Run `node scripts/check-teams-notices-browser.mjs --out /tmp/teams-notices-browser.json` for the five browser checks. All external source fixture I/O is isolated from production.

The final app command uses `TEST_RUNNER_PIYALI_OFFLINE_TESTS=1`, `TEST_RUNNER_PIYALI_REFERENCE_PREVIEW_TESTS=1`, a fresh UUID in `TEST_RUNNER_PIYALI_TEST_IDENTITY_SCOPE`, and `PIYALI_TEST_DEVICE=CE8248B6-7171-4FD4-97DE-89E499107F82`:

```sh
scripts/test-ios.sh -parallel-testing-enabled NO \
  -only-testing:PiyaliTests/TeamsPanelControllerTests \
  -only-testing:PiyaliTests/TeamsPanelReferenceTests/testOriginalTeamToastActionsAndNativePresentationInEnglishAndArabic \
  -resultBundlePath /tmp/piyali-teams-notices-assets-final-20261106.xcresult
```

UI runs additionally use `TEST_RUNNER_PIYALI_FIRESTORE_EMULATOR_TESTS=1`. Their selectors are `PiyaliUITests/TeamsTests/testCreateEditRosterAndDeleteUseSignedLocalRelayAndSurviveRelaunch` and `PiyaliUITests/TeamsTests/testIncomingInvitationSurvivesHeldRejectedRenameAndRelaunchWithoutAcceptingTheFailedRoster`. Both final selectors run together in the clean `/tmp/piyali-teams-notices-delivery-ui-20261106.xcresult` bundle.

The retained mixed runs remain **failed**, with their own summaries:

| Bundle prefix in `/tmp`, all suffixed `-20261106.xcresult` | Observed result |
| --- | --- |
| `piyali-teams-toasts-final` | 12 passing app cases, clipboard UI test failed after a second lookup outlived the two-second notice; explicitly interrupted, exit 73. |
| `piyali-teams-toasts-journeys` | Creation journey passed; rejection assertion expected a raw fixture reason instead of the real client's aggregate error; explicitly interrupted, exit 73. |
| `piyali-teams-notices-final` | 13 app cases passed; invitation journey restored correctly but its later covered Delete tap failed. |
| `piyali-teams-notices-confirmation` | 12 controller/UIKit cases passed; confirmation suspension alone did not fix the earlier covered Delete tap. |
| `piyali-teams-notices-ui-final` | Actual clipboard close and creation journey passed; invitation journey's readiness trace ruled out a disabled Delete, but its covered tap still failed. |

Final visual inspection also caught an RTL mismatch despite passing content assertions: an earlier cached preview omitted document direction, and native notices still forced LTR. The final comparison now asserts actual source direction and passes it explicitly to native presentation; the pre-fix Arabic detail sheet is retained as a failed design comparison.

Two visual/bounds drafts failed to compile before execution: an async call inside `XCTUnwrap` was moved outside its autoclosure; an unavailable `NSStringFromCGRect` test helper was replaced by `String(describing:)`. Neither is counted as a passing run. Early browser diagnostic assertions also assumed two accessible dialogs or used a cached no-op fixture close handler; corrected selectors and a fresh preview produce the final five passing checks. The rejected-rename inline error described in [the earlier checkpoint](TEAMS_LIVE_UPDATES.md) is superseded by this implementation.

## Remaining scope

- Source entry/exit motion (400 ms entrance and 200 ms scaled exit), exact shadows/text rasterization, mixed ordering with other feature notice portals and the wider language/Dynamic Type/VoiceOver/device matrix remain open. The surrounding native Teams drawer still forces LTR; the fresh source Arabic captures mirror its cards and controls, so whole-drawer RTL parity is explicitly still open. Static toast pairs do not close these requirements.
- Source clipboard rejection uses a closable 2.5-second error. Native uses UIKit's synchronous, nonthrowing pasteboard API; a source-style rejected promise was not invented or verified as a native OS failure.
- Global feed failures are a separate source **inline error card with Refresh**, rather than a toast. Native currently stores that feed failure without reproducing the card. Its loading/empty/error presentation still needs comparison and implementation.
- Streamed roster/member-row presentation versus refetches, complete cache-only UI, production outage/grant combinations, large/legacy teams, concurrent invitation actions and native confirmation presentation remain open. Existing whole-drawer card spacing, borders, gradients and shell differences remain visible outside these notice bounds.
- This checkpoint does not verify production Firebase/relay writes, full authenticated source journeys, physical audio/accessibility, payments, release signing or the other handoff acceptance gates. Separate Piyali Firebase/Cloudflare services and signed/public/private data boundaries are preserved. No deployment, merge or publication is included.
