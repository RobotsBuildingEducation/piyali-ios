# Teams startup, invitation attention and native foreground recovery — 2026-11-06

Read-only reference: `RobotsBuildingEducation/nosabos` **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `8cd15aa`. This advances FUNC-10 and DES-02/DES-08. Overall functional/design parity remains **In progress**.

## Source and corrected native behavior

The original App preloads teams, member progress and Global feed when an identity becomes active. A separate Firebase invitation subscription runs before the drawer opens. Its pending-ID set drives an unseen flag on both the activity-menu trigger and Teams item. Opening Your teams views invitations without accepting them; Global feed does not. Renaming/re-delivering the same pending ID stays quiet after viewing, while a newly pending ID restores attention. The source keeps unseen attention sticky when pending IDs disappear until the viewed callback clears it. A fresh App mount makes existing pending invitations unseen again.

Native previously started these reads only when Teams opened and had no startup invitation attention. It now owns an account/session-scoped startup controller, independent of each drawer's cancellation. The first drawer uses acknowledged cached teams/member rows and the latest invitations while doing its fresh read, including an already-loaded empty cache. Changing target/support language does not restart the identity's reads. Signing out/replacing an account clears the cache and rejects old callbacks. No new local persistence of viewed state is introduced.

Preparation/authentication can fail before a Firebase listener attaches; a terminal listener failure can also leave no active watch. Native retries failed preparation/watch attachment on foreground entry without clearing viewed IDs or repeating successful initial reads. Replaced watch callbacks cannot overwrite the replacement. This retry is a native lifecycle adaptation, not a claim that the source App has the same foreground retry method. Firestore's ordinary transient reconnection remains with its SDK.

The two attention dots use the source's nine-point shape and red. The Teams menu item now uses the original `TbHeartHandshake` SVG. Actual source captures exposed the previous native 58-point rounded square: the standalone navigation surface now follows the source's 66-point circle, 22-point glyph and mobile glass styling. Compact activity-footer behavior stays on its existing host. The source and native glyph/badge states now agree; gradient/shadow rendering, some border/glyph details and whole-shell positioning still need calibration.

## Evidence and scope

`export-teams-startup.mjs` executes the original App subscription effect and viewed callback in **56 public invitation sequences**, including duplicate IDs, viewed/re-delivered IDs, accepted/empty lists and new pending IDs. Two additional traces execute the original asynchronous team preload effect, including cleanup before its result. The generated fixture and original menu SVG regenerate byte-for-byte. **11 affected Core tests pass in 0.098 seconds**, including the existing Teams reconciliation, signed progress/private invitation and feed contracts.

The retained native runs have deliberately separate scopes:

| Run | Result and scope |
| --- | --- |
| `PiyaliTeamsStartupFirst20261106` | 8 pass: startup/cache/account/SDK/controller checks and the first full invitation journey (91.785 s). |
| `PiyaliTeamsStartupVerified20261106` | 21 pass, 1 skip, zero failures: 18 app/source/SDK checks plus three full UI journeys. The rollback test lacked its separate rules-emulator opt-in. App checks take 84.557 s; UI journeys take 279.349 s. |
| `PiyaliTeamsStartupReconnect20261106` | 8 pass, zero skips: failed-preparation/watch recovery, stale replacement callbacks, real invitation SDK, source control comparisons, rules-backed rollback and the full invitation journey again (98.703 s). |
| `PiyaliTeamsStartupDesignFinal20261106` | 2 pass, zero skips: final English/Arabic control captures (13.911 s) and the actual invitation journey on the final circular-surface build (99.452 s). |

The latest retained result for each of 23 distinct native checks is passing. These are incremental targeted runs, not a full-app sign-off. The broad run also exercises signed roster concurrency, owner/account replacement, indexing-delay restore, feed cache/cancellation and progress debounce. Its source drawer test covers eight states in English/light and Arabic/dark (16 component pairs, 67.180 s). The public roster product journey creates, renames, adds a member, relaunches, deletes and relaunches again (120.018 s); the legacy invitation journey accepts, declines, leaves and relaunches (60.544 s).

The final invitation journey uses normal signup → onboarding/setup/placement → Focus/menu. Real local Firebase snapshots deliver invitations while the drawer is closed, while Your teams is visible, and while Global feed is visible. It verifies both badges, clearing on viewing, quiet same-ID rename, new-ID attention on Feed, pending attention after process termination/relaunch and decline. The loopback relay receives no public publish events. The separate signed-roster and denied-mirror rollback tests publish only to their loopback relay. No production team or social event is created.

The real local Firebase SDK checks that startup observes legacy and public invitation records, and that closing the drawer watch does not stop the startup subscription. Identity/cancellation fences are additionally tested with explicitly held reads and stale callbacks. Native foreground failures/retries use injected I/O; this does not prove all production relay/auth outage combinations.

## Visual review and retained artifacts

The source badge fixture renders the original `App.jsx` BottomActionBar and its original dependencies/effect with public subscription I/O. It is not a replacement menu or a mounted authenticated App. Four states per language—pending, viewed, same ID and new ID—are retained beside native:

- [English/light control states](native/teams-startup-b269524d/pair-badge-en.png), [Arabic/dark control states](native/teams-startup-b269524d/pair-badge-ar.png).
- [Before English](native/teams-startup-b269524d/before-design-pair-badge-en.png), [before Arabic](native/teams-startup-b269524d/before-design-pair-badge-ar.png).
- [Real native startup/menu/Feed/relaunch journey](native/teams-startup-b269524d/native-startup-contact.png).
- Representative inspected drawer pairs: [single team English](native/teams-startup-b269524d/pair-drawer-single-en.png), [pending Arabic](native/teams-startup-b269524d/pair-drawer-pending-ar.png), [feed English](native/teams-startup-b269524d/pair-drawer-feed-en.png).

The [manifest](native/teams-startup-b269524d/manifest.json) hashes **60 artifacts**, including original screenshot bytes/geometry, source effects, test summaries/commands, before/after captures and final native file hashes. QA-installed executable/debug-library hashes match the final built products. A new Core test initially failed to compile because it used an integer JSONValue subscript; it was corrected to the array API. One visual command was explicitly interrupted after the local source server had already been stopped; the server was restarted before the passing final captures. Neither is represented as a passing verification run.

## Remaining work

Broader legacy/public roster variants, large rosters, production relay outage/reconnect and permission-grant combinations, complete loading/error/toast/confirmation presentation, all support languages/sizes, VoiceOver and whole-menu/footer animation/placement remain open. The new scoped foreground tests do not close that matrix. Existing [Teams](TEAMS.md) and [feed](COMMUNITY_FEED.md) records retain their other verified and open scopes. The separate Firebase/Cloudflare services, signed roster verification, creator permissions, limited public progress, explicit community publication and 700 ms drawer-owned progress debounce are preserved. No rules/service deployment, merge or App Store publication is included.

The later [live-update checkpoint](TEAMS_LIVE_UPDATES.md) corrects dropped in-flight signals, omitted initial cached watch notifications and queued work after close, while adding source loading presentation. Its remaining cache/roster/error scopes stay open.
