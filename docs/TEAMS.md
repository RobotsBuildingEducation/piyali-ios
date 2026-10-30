# Teams drawer checkpoint

The former native Teams lists exposed separate public/private sections, an extra sharing switch, inline management fields and generic progress rows. The root menu now opens the web product's 80% bottom drawer, with Your teams and Global feed tabs. Creation, adding members and renaming use separate dialogs. New teams use signed public Nostr rosters and the web app's accepted Firebase invitation copies; existing private invitations appear in the same list.

## Source and native behavior

`scripts/export-teams-panel.mjs` extracts the original reconciliation policy, invitation-input guards, feed filtering/metrics and stable author-to-portrait selection. Its 134 cases compare native JavaScriptCore results to the original JavaScript. The manifest in `reference/teams-panel-manifest.json` records the source component, service, drawing, theme and stylesheet hashes. The three management icons are the original React icon SVGs.

Single teams are expanded; multiple teams use independent accordion sections. Creator controls, pending invitations, queued npubs, member names/languages, Score, proficiency, total XP, daily progress and companion health follow the source. Companion pictures use the original healthy drawing at time zero, as `TeamCompanionAvatar` does. Labels use the existing source language bundle and the components' English fallbacks. The feed uses existing Nostr service verification/cache, original card conditions and the source Stories portrait hash.

Opening a drawer containing a Nostr team schedules the source's 700 ms progress publication. A changed snapshot replaces the pending one and updates the learner's row; unchanged snapshots are not sent again, and closing cancels pending work. This uses the same limited public progress fields as the web component. The unrelated setting for automatic community notes does not gate this team snapshot. Legacy-only teams do not trigger publication.

## Firebase mirrors and failure handling

`TeamsMirrorService` writes the web schema under `users/{creator}/teams/{id}` and `users/{member}/teamInvites/team_{id}`. Creating a public team publishes its signed roster first, then commits the Firebase roster and accepted invitations together. If that commit fails, the new signed roster is deleted, matching the source rollback. Rename/add preserve a successful signed action when mirror synchronization fails and report a warning. Leaving and deleting revoke the corresponding invitation copies. Live listeners refresh incoming invitations and roster changes while the drawer is open.

The rules permit only creator writes to public mirrors and accepted invitations proven to match the roster. Member changes use the existing before/after proof so a caller can change only their own entry. Other learners' root documents remain private. Legacy private progress continues using scoped progress records; the port does not reproduce unrestricted reads of teammates' learner roots.

The rules were deployed only to `piyali-ios`; Cloudflare is unchanged. A live SDK check authenticates three disposable Nostr identities through Piyali/App Check, verifies create/rename/add/leave/delete, outsider and learner-root denial, and a creator update reaching the newly invited member's open subscription. The fixture and all three auth users are removed afterward; no learner root or public Nostr event is written.

That check exposed a denied point-document listener remaining unusable after a membership grant. New public member reads/subscriptions now use a bounded query for the exact team and accepted roster entry, including its invitation timestamp. The rules prove invitation access to the exact team; broad, unbounded and outsider queries remain denied. Older records retain a server transaction recheck when a point read is denied. This avoids treating a stale listener failure as proof that a valid invitation is missing.

## Verification

- Original policy: 134 comparisons, passing focused Core test.
- Backend rules: 27 checks, passing against the rules emulator; includes public creation, accepted invitation, rename/add, outsider/root denial, departure/deletion, forged changes and older pending public invitations.
- Actual Firebase SDK: public mirror lifecycle and existing private invitation/progress/concurrent-add regressions.
- Controller and failure contracts: latest-only debounce, row replacement, close cancellation, legacy-only behavior, late-load rejection, and a real permission-denied SDK write followed by a signed local-relay rollback.
- Visual comparisons: actual React `TeamsDrawer`/`TeamView`/`TeamCreation`/`TeamFeed` components at 402 × 874, eight states each in English/light and Arabic/dark. Only external I/O is replaced; fixed fixtures cannot publish to production. Vite caches and fixture sources live in the iOS repository.
- `TeamsPanelFinal1.xcresult`: all nine selected tests passed, including 16 source/native states (61.047s), the complete public roster/relaunch journey (99.166s) and incoming legacy invitation/leave/relaunch (41.706s).
- `TeamsLiveReadFinal1.xcresult`: real public team-relay reads pass (1.242s) for a new identity, without publishing.
- `scripts/test-live-api.py --only teams`: the final live grant, subscription update and revocation check passes in 11.453s. The harness reuses each test user's SDK session after its initial real Nostr sign-in, keeping within the unchanged auth rate limit.
- `TeamsContractsFinal2.xcresult`: all eight post-fix SDK/controller/rollback and product checks pass; both complete journeys pass again (42.108s and 99.195s).

[Single team](native/teams-single-en.png), [creation](native/teams-create-en.png), [pending invitation](native/teams-pending-en.png), [Global feed](native/teams-feed-en.png), and [Arabic/dark](native/teams-single-ar.png) show the web component beside Swift. Five additional captures show the actual root-product journey, including queued invitations and restored membership.

## Remaining scope

This checkpoint does not establish complete app parity. Startup team preloading and the main menu's unseen-invitation badge still need comparison. Broader relay interruptions, older public roster variants, large rosters, all support languages and additional iPhone sizes remain unverified. Native keyboard/confirmation controls differ from browser controls, and transient error/toast presentation and exact animation still need refinement. Wallet, achievements, subscription and the remaining gameplay/audio gaps are tracked in `PARITY_AUDIT.md` and their checkpoints.
