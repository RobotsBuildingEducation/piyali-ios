# Teams live updates during reads, mutations and close — 2026-11-06

Read-only reference: `RobotsBuildingEducation/nosabos` **`b269524ddc578027c549616fc47f5954991d9f6f`**. Native base: `1ee58f3`. This advances FUNC-10 and DES-08; complete functional/design parity remains **In progress**.

## Reproduced failures

The original TeamView applies the first invitation/roster subscription snapshot. Invitation and roster callbacks update their state independently of an in-flight rename. The normal source close cleanup cancels the 700 ms progress timer. Native had several different boundaries:

- A watched change arriving during a read was dropped. After the held read finished, its old data remained and no current read followed.
- A watched change during a failed management action was dropped, leaving the old data after the failure.
- An already queued drawer-watch callback could run after close, reload the controller and restart its progress publisher. The baseline records an extra read and a fake publisher call after cancellation.
- Roster watches ignored their first snapshot. An online SDK baseline happened to receive a later snapshot and passed; a stable cache-only/offline variant reproduced the omitted first notification.

The initial controller/SDK bundle has **three failed tests and one pass**. The cache-only SDK reproduction then fails separately. These are retained as failures, not summarized as a passing baseline.

## Corrected native behavior

Live invitations now have a separate subscription and can also consume the startup cache's live invitation updates. They update while a roster read or management request is held. A stale read cannot overwrite an invitation snapshot that arrived after it began. Pending-only changes do not require a full roster reload.

Roster signals coalesce behind an in-flight read or action. A signal received during a failed action still refreshes afterward. Successful watched reads clear an earlier read failure, while action/form errors remain independent of unrelated incoming data. An accepted invitation's grant timestamp participates in the roster-watch key, so a replacement grant for the same team replaces the old watch/query context.

Watch callbacks, reads, refresh tasks, feed delivery and progress publication retain account/session ownership. Closing cancels pending work; an old callback cannot reopen the controller or restart its publisher. Reimporting the same account key creates a new session and rejects old read/watch/publication work. These explicit native task fences are a lifecycle adaptation; the source callback oracle does not claim equivalent fencing for already queued browser work.

The first cached Firebase watch notification is now delivered. This verifies notification delivery after a cached roster change, **not complete cache-only roster/member UI parity**. Native still refetches roster/member data for generic roster signals; broader offline/permission/legacy behavior remains open below.

The drawer replaces its generic loading spinner with the original label and three four-point animated dots, including source spacing, stagger and colors. Pending cards and team cards stay hidden while a fresh initial read is loading, as in the source; the pending count remains available on the tab. The original English fallback is preserved in the Arabic-support fixture where the source has no translated label.

## Verification

The final `/tmp/PiyaliTeamsLiveUpdateFinal20261106.xcresult` passes **13 tests, zero failures or skips**: 12 app/source/SDK checks in **13.519 seconds**, plus the complete native journey in **96.754 seconds**. The final visual-host refinement then passes its loading comparison again in **6.635 seconds**. That refinement supplies the ordinary native page background and active scene phase to the isolated comparison; application code is unchanged.

The real native journey performs signup → onboarding/setup/placement → Teams → signed public team creation → held rename. A real local Firebase snapshot delivers a new invitation while that rename is pending. The loopback relay rejects the rename; the error remains visible, the invitation remains available and the old signed team name remains unchanged. Termination/relaunch restores that name and invitation. The journey then declines and deletes its local fixtures. All published events remain kind 30078 on the loopback relay; it emits no public community note and writes no production team.

Controller checks cover held reads, bursts coalescing into one refresh, live invitations during a held/failing action, old-session reimport, replacement grant timestamps, resolved read errors and post-close publisher protection. Real local Firebase SDK checks cover public mirror lifecycle and cached first-watch notification with network disabled/re-enabled on the isolated test database. The source's existing 700 ms debounce and legacy-only no-publication behavior remain covered.

The original callback oracle executes **four held-rename/live-update cases** spanning rejection, success and partial mirror success, plus **two normal share-close cleanup states**. It uses the unmodified TeamView subscription effects and rename handler with public subscription/progress/persistence/toast/timer I/O. Its first snapshots apply immediately; live invitations and peer roster changes arrive while rename is still saving, and failure retains them. It is not a mounted authenticated App or a claim that all source reads are atomic.

The earlier broad run passed 20 checks and failed one loading comparison. Its assertion ran before the native invitation watch had attached; the corrected comparison waits for both the held read and the delivered invitation before asserting/capturing. That failed bundle remains recorded as failed. The broad run also passed the existing 16 source/native drawer/form/feed pairs, startup regression checks, rules-backed rollback and both full native invitation journeys; those retain their own earlier implementation scope.

## Captures and remaining gaps

- [English/light loading — source left, native right](native/teams-live-updates-b269524d/pair-loading-en.png).
- [Arabic-support/dark loading — source left, native right](native/teams-live-updates-b269524d/pair-loading-ar.png).
- [Full native held rename → rejection → live invitation → relaunch](native/teams-live-updates-b269524d/native-failed-rename-contact.png).

These captures were visually inspected. Loading content, card visibility and three-dot presentation agree; small button/close-icon geometry and timing differences remain. The [manifest](native/teams-live-updates-b269524d/manifest.json) hashes **20 artifacts**, including original images/geometry, callback traces, passing/failing summaries, exact commands and final native file hashes. Installed QA executable/debug-library hashes match the final build. Component pairs do not prove complete authenticated browser or full-shell parity.

Remaining work includes direct streamed roster/member-row presentation versus refetches, complete cache-only UI, production relay/Firebase outage and permission-grant combinations, large/legacy roster variants, concurrent invitation actions and complete toast/confirmation presentation. That checkpoint retained a rejected rename as an inline error/Retry while the source used a transient toast. This historical difference now has scoped implementation/evidence in [TEAMS_NOTICES.md](TEAMS_NOTICES.md); notice motion and wider confirmation/design work remain open. Wider language/size/motion/VoiceOver and the full handoff's other product/device/payment/release gates remain open. Separate Firebase/Cloudflare services, signed roster verification, creator permissions and private learner-root access are preserved. No service/rules deployment, merge or App Store publication is included.
