# Main-product learning teams

The native account screen supports the main web app's public Nostr learning-team contract: creating teams, reading joined/owned teams, creator renaming and roster additions, member departure, creator deletion, profiles and learning progress. Firestore-only legacy teams and their pending invitation flow still require a separate port. The existing web backend and reference checkout are unchanged.

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
