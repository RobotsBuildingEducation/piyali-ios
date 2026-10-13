# Remote Nostr signer

Piyali for iPhone accepts a signer-provided `bunker://` connection URL from the sign-in screen or Account. This supplies a native alternative to the reference web app's external browser signer. The web source uses `window.nostr`; it does not contain a bunker implementation.

The client implements the current [NIP-46 protocol](https://github.com/nostr-protocol/nips/blob/master/46.md) with NIP-44 encrypted kind-24133 requests. It connects, obtains the learner's public key independently of the signer's transport key, and requests signatures for native authentication, web subscription restoration, relay authentication and public learning-team/achievement events. Optional relay switching accepts secure relay URLs. Responses must have the expected request ID, recipient and verified signer signature. The final signed event must exactly match the learner, kind, timestamp, tags and content requested by Piyali.

Only a newly generated client connection key, the public key roles and relay URLs are saved in the device-only Keychain. The one-time connection secret is not retained. Piyali cannot export the learner's private key for a remote account. StoreKit account binding and Firebase identity use the learner's public key, never the signer transport key or local connection key.

If a signer asks for browser authorization, Piyali presents its HTTPS link and continues listening for the same request. Opening the link is an explicit learner action. Canceling, replacing the account or disconnecting cancels outstanding signing work. A remote account can be restored after relaunch without another connection handshake. Disconnect removes the connection credentials and clears the native Firebase session; saved local learning progress remains available if the same learner reconnects.

The signer connection has a bounded timeout and can use up to eight relays. Its relay authentication uses the local client connection key, avoiding a recursive remote-signing request. Public relays require WSS; cleartext loopback is allowed only in explicitly isolated debug tests.

## Verification

- Three pure URL-parser tests cover connection secrets, repeated relay parameters, malformed URLs and loopback isolation.
- Nine SDK tests use a real loopback WebSocket relay, NIP-44 encryption and Schnorr signatures with separate signer and learner keys. They cover exact Unicode templates, denied or altered signatures, browser authorization, forged/misdirected/stale response noise, account replacement, stable Keychain restoration and expected-author checks.
- A simulator UI test connects, displays the learner's public key, relaunches, disconnects and verifies the session remains removed after another relaunch.
- The opt-in `scripts/test-live-api.py --only signer` passed native Firebase authentication with the remotely signed learner proof and denied an unlinked web subscription. It uses random isolated keys, deletes its temporary Firebase authentication user and writes no learner progress or entitlement.

These tests do not connect to a real external signer provider or publish test events to public relays. Client-generated `nostrconnect://` QR sessions and legacy NIP-04 transport are outside this implementation; use a signer-provided bunker URL supporting the current protocol.
