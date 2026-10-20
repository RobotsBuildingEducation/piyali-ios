# Main-product learning teams

The native account screen supports the main web app's public Nostr learning-team contract: creating teams, reading joined/owned teams, creator renaming and roster additions, member departure, creator deletion, profiles and learning progress. Firestore-only private teams and pending invitations are available through Private teams and invitations. The existing web backend and reference checkout are unchanged.

## Public teams

Teams use signed kind `30078` addressable events at `learning-team:<id>` with the web's `learning-team` topic, name, member `p` tags and JSON name/creation content. New teams include the creator. Only the creator can rename or add members, and every edit reloads the latest signed roster before writing a newer event. In-app operations serialize so overlapping rename/add requests preserve each other. Duplicate or invalid teammate keys and empty/oversized names fail before publication.

The web's three team relays are the native defaults. Reads and writes support signed ephemeral NIP-42 authentication. Matching relay acknowledgment is required for an update to succeed. Newly acknowledged own-team events are retained locally, scoped by author and signature-checked on restoration, so a relay indexing delay cannot hide a created team. Deleted own-team tombstones also survive restart. The cache contains public events, not private keys or learner drafts.

Member departures use the web's `learning-team-left:<creatorHex>:<teamId>` address and `a` reference. Departures at or after the roster timestamp remove members; a newer roster can invite them again. Reading all member departures removes teammates who left, rather than only hiding teams the viewer left. Creator deletion emits a signed single-element `deleted` tag and a newer timestamp. Public events cannot be retroactively made private.

## Progress

The team detail screen shows profile names, Nostr IDs, creator role, language/course level, current Score and its estimated practice level, total XP, streak, daily goal progress and companion name/type/level/health. A kind-0 profile supplies a display name when available. Older progress without the current Score schema shows no Score instead of converting an unrelated legacy value. Companion types respect the web's level unlocks.

Your own row uses current native state. Other members use their latest signed `learning-progress` snapshot and metadata. Missing/unavailable shared progress does not remove a valid team. Private messages, notes, recordings and conversation drafts are excluded from the public snapshot. Public progress publication requires the sharing toggle and Publish progress button; simply opening or refreshing teams reads only.

Account changes cancel pending team operations and clear old-account UI state. Delayed relay results cannot restore a previous account's roster or sign an authentication proof with the replacement account. Public roster modifications remain explicit in-app actions.

## Verification

Reference fixtures compare 48 progress rows, two team event templates and 15 departure timestamp cases exported directly from `learningTeams.js`. Native loopback relay tests exercise actual WebSockets/signatures, concurrent edits, duplicate rejection, profiles/latest progress, other-member departure, renewed invitations, creator deletion, rejected publication, forged records, relay authentication, an account switch during a pending read and own-team restoration before relay indexing. Public-relay verification uses a fresh isolated key and performs only reads and optional ephemeral AUTH.

Simulator UI checks use a loopback relay for the actual native create/edit/add/delete/relaunch flow. The test relay override requires a debug build, explicit offline flag, valid isolated identity UUID and a `ws://127.0.0.1:<port>` endpoint; release builds always use the configured production relays. No test roster or progress is broadcast publicly.

Run `scripts/test-nostr.sh` for isolated native relay tests; `TEST_RUNNER_PIYALI_LIVE_NOSTR=1 scripts/test-nostr.sh` additionally enables the read-only public checks. Refresh pure source fixtures with `node scripts/export-team-fixtures.mjs /absolute/path/to/reference/nosabos`.

Address replacement and same-timestamp ordering follow [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md). Team event fields and departure semantics follow the reference product's own contract.

## Private Firestore teams

Account → Learning teams → Private teams and invitations reads and writes the browser's `users/{creator}/teams/{teamId}` and `users/{member}/teamInvites/team_{teamId}` records. Public Nostr mirror records are excluded from this list. The independent Piyali Firebase project does not automatically copy private records from the separate web Firebase project; compatible records already in the selected backend can be loaded.

Native private teams support creation, pending invitations, acceptance/refusal, creator rename and additional invitations, member departure and creator deletion. Accept/refuse/leave preserve every other roster entry and its unknown legacy fields. A small `_memberChange` before/after record lets rules prove the exact caller-only edit. Acceptance and the invitation status commit in one transaction. Missing or stale rosters cannot turn a pending invitation into an accepted team. Creator edits reload the latest roster, and concurrent additions use Firestore transaction retries. Rename updates existing invitation names, and deletion removes active invitation documents atomically.

Private progress is a deliberately limited per-team snapshot at `teams/{teamId}/progress/{npub}`. It uses the same proven language, XP, daily goal, Score, streak and companion fields as the public progress contract. The native Share my progress button writes to Firebase for that team, without publishing a Nostr event. An invitation allows reading its team's roster, but only an accepted invitation allows reading progress. A member can write only their own snapshot. Leaving deletes that member's invitation and snapshot, which revokes access; a deleted parent team makes any remaining snapshots inaccessible. Learner root documents, notes, conversations, recordings, wallet data and subscription grants remain owner-only. Sharing in a private team never grants access to a learner's complete Firestore document.

Four fixtures execute the actual browser acceptance/refusal helpers against an in-memory adapter and compare native mutations. Core checks also cover duplicate/self/invalid invitations and exclusion of populated private notes and recordings from shared progress. Two real Swift Firestore SDK tests cover invitation restoration, acceptance/refusal, preserved legacy data, private progress, rename propagation, concurrent additions, departure, deletion and stale or missing rosters. A separate suite loads the exact production rules in an authenticated emulator and verifies successful operations and denied forgeries, premature progress reads and cross-user learner access. These tests use demo projects and disposable identities.

Run `scripts/test-private-teams.sh` for SDK contracts, `scripts/test-private-teams.sh --ui` for the simulator flows, and `scripts/test-rules.sh` for authenticated production-rule checks. The UI test database override requires a debug build, explicit offline mode, a valid isolated identity UUID and an explicit emulator flag. Its project is fixed to `demo-piyali-ios` and its endpoint to `127.0.0.1:8180`; release builds contain no override. Refresh source fixtures with `node scripts/export-private-team-fixtures.mjs /absolute/path/to/reference/nosabos`.

The exact allowed roster mutation uses Firestore's documented list equality, `removeAll` and `concat` operations: [Firebase Rules list reference](https://firebase.google.com/docs/reference/rules/rules.List).

Both private-team simulator UI flows passed: creator management/shared progress/relaunch/delete and account switching/invitation acceptance/departure. The loopback relay observed no public event publication.

The private-team rules were deployed to `piyali-ios` on 2026-10-20. `PIYALI_LIVE_PRIVATE_TEAMS=1 node Backend/scripts/verify-private-teams.mjs` passed against that deployed backend using native Nostr/Firebase authentication and App Check. It proved atomic acceptance, pending/outside access denial, caller-only snapshots, learner-document isolation and revocation after departure. The unique team, progress snapshot, invitation and all three disposable auth identities were removed afterward; no learner root document or public relay event was written. The opt-in verifier requires the ignored local Firebase configuration and registered App Check debug token.
