# Piyali iPhone backend

Dedicated Cloudflare authentication and tutor worker for the independent `piyali-ios` Firebase project. The existing web worker and web Firebase project are not modified.

`POST /auth/challenge` accepts a canonical `npub` and a valid Piyali iOS App Check token. It returns a 120-second, HTTP-bound Nostr event. `POST /auth/sign-in` verifies the exact Schnorr-signed event, consumes its challenge atomically in a SQLite Durable Object, and signs a Firebase custom token with that npub as the UID. Private Nostr keys stay on the device. Firebase signing credentials exist only in ignored local secrets and Cloudflare secrets. Requests are rate limited; Firebase rules prevent client subscription grants and cross-account data access.

## Development

Use Node 22 or newer. `npm ci` and `npm test` run the backend unit checks. From the repository root, with Java 21 and Firebase CLI installed:

```sh
firebase --config firebase.json --project demo-piyali-ios-auth \
  emulators:exec --only firestore 'PIYALI_RULES_EMULATOR=1 node --test Backend/test/*.test.js'
```

`npm run deploy -- --dry-run` validates packaging. `npm run deploy` publishes only `piyali-ios-api`. The live endpoint is `https://piyali-ios-api.robotsbuildingeducation.workers.dev`; `/health` is public, authentication routes require App Check.

The worker needs `FIREBASE_CLIENT_EMAIL` and `FIREBASE_PRIVATE_KEY`, delivered with `wrangler secret bulk` from an ignored JSON file. Never place them in `wrangler.toml`, app resources, source control, logs, or command arguments. The dedicated service account is `piyali-auth@piyali-ios.iam.gserviceaccount.com`.

The opt-in `node Backend/scripts/verify-live-auth.mjs` runs against Piyali only, requires the local iOS Firebase plist and `.secrets/app-check-debug.json`, creates an ephemeral Nostr identity, verifies App Check, sign-in, replay defense and Firestore isolation, and removes its own auth fixture. Firestore retains the harmless temporary root fixture because production root deletion is intentionally denied. This script never prints tokens or private keys.

`POST /proxyResponses` requires both a native Piyali App Check token and a Firebase custom-auth ID token. The worker verifies Google's signature, project issuer/audience, canonical npub and Nostr public-key claim. It permits only the reference's `gpt-6-luna` and `gpt-5-nano` models, bounded text input/output, and text/JSON output. It strips caller-selected tools, forces `store: false`, limits each learner to 60 requests per minute and aborts upstream calls after 40 seconds. `OPENAI_API_KEY` is a worker secret; it is never bundled in Swift. The contract follows the [official OpenAI Responses reference](https://developers.openai.com/api/reference/resources/responses/methods/create).

Set `PIYALI_LIVE_AI=1` when running `verify-live-auth.mjs` to additionally generate and validate a small exercise through the live tutor. `verify-web-subscription.mjs` verifies the existing external Patreon restore endpoint, unlinked-account denial and replay rejection without creating a payment or membership. Native `scripts/test-live-api.py` verifies the Swift authentication, Gemini text, Cloudflare JSON exercise, signed Patreon restore and live audio response using an isolated test key and the registered debug token.

Gemini text/live voice use the Gemini Developer API through Firebase AI Logic on Piyali's Spark plan. The dedicated Cloudflare worker provides the Responses fallback. Audio-cache playback and the alternate OpenAI WebRTC voice transport remain integration work.

Native RPG calls use fixed `outputProfile` values `rpg_story` and `rpg_speech`, resolved to strict provider JSON schemas by the worker. Unknown profiles and unsupported reasoning efforts are rejected. GPT-6 Luna requests may specify `none`, `low` or `medium`; its existing default remains `none`. Output tokens remain capped at 8,192 and the upstream deadline is 40 seconds. These bounds are tested in `test/responses.test.js`. See [RPG.md](../docs/RPG.md) for the native content and completion flow.

Native stories use fixed `story_episode` and `story_speaking` profiles, with complete dialogue/checkpoint and sentence schemas. Private analytics live in the owner-only `storyTurns` collection. The updated native worker and rules are deployed; web services are unchanged. See [STORIES.md](../docs/STORIES.md).
