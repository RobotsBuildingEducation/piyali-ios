# Local subscription testing

Run `scripts/test-storekit.sh` to exercise the actual StoreKit 2 purchase and entitlement APIs without App Store Connect products or real charges. The script uses the separate `PiyaliStoreKit` scheme, an isolated Nostr test identity and an offline Firebase launch. Web restoration uses test-only URLSession adapters in these tests; it never calls Patreon or the deployed backend.

`Tests/PiyaliAppTests/Fixtures/PiyaliSubscriptions.storekit` defines two local subscription products. Its names include “Local Test”; its prices are test data, not proposed production pricing. The fixture belongs to the test target. The ordinary `Piyali` scheme and application resources do not configure a simulated store.

The eleven checks verify:

- Monthly/annual purchases through `SubscriptionService.buy`, verified `.xcode` entitlements and the real Nostr-derived `appAccountToken`.
- Restoring the same learner's purchase and refusing access after switching to a different Nostr key.
- Expiration/refund transaction updates removing access.
- Ask to Buy staying locked until approval, then clearing the pending message.
- Unconfigured products and unverified purchases failing to unlock access.
- Apple restoration with an unavailable web provider, signed web restoration with unavailable Apple sync, and both providers failing without opening the paywall.

Apple documents [SKTestSession](https://developer.apple.com/documentation/storekittest/sktestsession) as a shared test environment. These tests run serially, clear their local transactions and reset their test overrides.

## Simulator selection

The local iOS 26.4 command-line run returned `SKInternalErrorDomain Code=3` before any product could load, including with a configured StoreKit scheme. A similar configuration-sync issue is [reported on Apple Developer Forums](https://developer.apple.com/forums/thread/826971). The complete suite passed on the installed iOS 17 runtime, which also verifies the app's minimum supported version.

When iOS 17 is installed, the wrapper creates/reuses a dedicated `Piyali StoreKit Tests` iPhone 15 simulator. Set `PIYALI_TEST_DEVICE=<UDID>` to choose another supported runtime. On other machines it uses the ordinary iPhone test selection; a StoreKit infrastructure failure is a failed test, not a fabricated successful purchase. You can also select `PiyaliStoreKit` in Xcode and test there.

## Production boundary

Local StoreKit verification does not create App Store Connect products, a developer membership, an Apple sandbox account or real subscriptions. Those setup and paid-member/physical-device checks remain required for distribution. The production web subscription link and signed Patreon restore continue to use Piyali's existing service.
