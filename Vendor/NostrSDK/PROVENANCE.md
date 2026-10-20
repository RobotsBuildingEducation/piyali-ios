# NostrSDK compatibility copy

Upstream: https://github.com/nostr-sdk/nostr-sdk-ios
Commit: e5855cbd3bdabf44075fd2abdf76f63bac4cbd5f
License: MIT; preserved in LICENSE.

Sources are unchanged from the app’s previously pinned upstream commit. The package manifest uses 21-DOT-DEV/swift-secp256k1 0.19.0 so NostrSDK and CashuSwift share one secp256k1 implementation. The upstream test target is omitted because its fixtures are not vendored. Application signing, identity, NIP-44 and remote-signer tests exercise the integration. Revisit this local package when upstream supports the same dependency.
