# Piyali iPhone backend

Dedicated Cloudflare worker for the independent `piyali-ios` Firebase project. The existing web worker and web Firebase project are not modified.

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

This worker currently implements authentication. AI, speech/cache and subscription verification routes remain integration work.
