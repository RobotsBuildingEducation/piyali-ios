# Native wallet implementation

Native wallet creation/restoration, NIP-60 synchronization and Lightning deposits are connected through Account → Wallet. Nutzap sending/receiving and legacy wallet migration remain in progress. No real funds have been moved during implementation or verification.

## Dependencies

CashuSwift is pinned to upstream revision `cd95afd419429539e97886a77f8ecb9cc5238d9a`. Its secp256k1 0.19.0 dependency conflicts with the original NostrSDK manifest's exact 0.12.2 requirement. `Vendor/NostrSDK` retains the original pinned NostrSDK sources and MIT license; its manifest shares the Cashu dependency instead. See its provenance file. The Xcode package resolution contains one secp256k1 implementation. Signing, a published NIP-44 ciphertext vector, encrypted remote-signer handshakes, teams and achievements passed after this change.

## Implemented components

- `WalletContract` validates wire records, sat amounts and mint URLs. Recipient discovery requires an advertised wallet key and an explicitly supported mint. It preserves the exact advertised mint URL for outgoing `u` tags while comparing normalized URLs for compatibility. It does not fall back to the recipient's main Nostr key.
- `WalletLedger` merges encrypted token contents after the service verifies/decrypts their enclosing events. Rollover and deletion tombstones work before or after the original token arrives. Duplicate proofs cannot inflate balances; conflicting signatures or reused secrets fail closed.
- `CashuMintBatch` prepares blinded outputs using CashuSwift and the shared secp256k1 library. The complete outputs, secrets and blinding factors are serializable before network submission. Unblinding checks denominations, keyset identifiers, valid keysets and DLEQ proofs. NUT-09 recovery matches exact saved blinded outputs even when a mint returns a different order, and requires the complete batch before finalizing. P2PK output keys must also be valid curve points.
- `IdentityService` encrypts/decrypts wallet contents to the current learner using NIP-44. Local keys stay in Keychain; remote signers receive `nip44_encrypt`/`nip44_decrypt` RPCs addressed to the actual learner key. Account changes cancel pending requests, and responses are fenced to the original account. Wallet-specific permissions are requested by those RPCs when used, rather than silently expanding the existing sign-in grant.
- `WalletVault` keeps wallet keys, proofs, invoices, pending operation phases and relay outboxes in account-scoped Keychain records. It deliberately has no field in the Firebase learner snapshot. Identity disconnect preserves wallet recovery data. Debug cleanup is restricted to isolated offline test scopes.

## Wallet synchronization and deposits

`WalletService` discovers modern wallet configuration and signed encrypted proof records, preserves rollover/deletion tombstones, and uses mint proof-state checks for the displayed spendable balance. A second relay discovery check precedes wallet creation. Existing legacy wallet/deposit records prevent accidental replacement. New wallets generate a separate receiving key and publish encrypted NIP-60 configuration plus public NIP-61 payment information. Configuration publication has a persistent retryable outbox.

`CashuHTTPClient` validates mint keys before requesting payment, including inactive keysets with unsigned 64-bit denominations. Deposit invoices must have a valid BOLT11 signature, exact requested sat amount and usable expiry. The native screen accepts 1–1,000,000 sats, shows a QR code, supports sharing/opening the invoice, polls while open and retains the quote across relaunches.

A paid quote creates and saves a complete blinded-output batch before submission. A lost response leaves the operation recoverable through NUT-09, without minting again when its signatures are available. Proofs and a stable relay outbox are saved before publication. An acknowledgment failure retries that outbox, preserving the already minted proofs. Per-account in-process leases and a fresh Keychain read prevent concurrent native service instances from overwriting each other's journal.

Expired unpaid invoices retain their quote identifiers. Users can archive them to request another invoice, and later check the archive for a delayed payment. Paid archived quotes return to the regular mint/recovery flow. Neither expiry nor archiving silently discards recovery data.

## Next integration

Complete incoming nutzap redemption and recipient-locked one-sat sends, publishing replacement proof records, deletion references and encrypted spend history. Add optional achievement evidence only after the outgoing receipt is acknowledged. Port legacy wallet records without overwriting existing receiving keys or funds.

The reference's main wallet supports creating/loading the wallet, a resumable BOLT11 deposit, mint-checked balances and one-sat tips. Its fallback to an unadvertised recipient key is intentionally not reproduced because current NIP-61 requires the advertised separate wallet key and supported mint. Existing browser wallet records include older event kinds; any compatibility importer must preserve encrypted funds and verify proof states instead of treating a missing modern wallet event as permission to overwrite them.

## Protocol references

- [CashuSwift](https://github.com/zeugmaster/CashuSwift)
- [Cashu NUTs](https://github.com/cashubtc/nuts)
- [NIP-60 wallet records](https://github.com/nostr-protocol/nips/blob/master/60.md)
- [NIP-61 nutzaps](https://github.com/nostr-protocol/nips/blob/master/61.md)
- [NIP-44 ciphertext vector](https://github.com/nostr-protocol/nips/blob/master/44.md#tests-and-code)

### SDK integration constraints

Keep the saved-batch adapter for monetary network operations. CashuSwift's convenience `send` generates P2PK secrets inside the network call; a lost response would not leave those outgoing secrets in the app's journal. Its `receive` compares a raw Schnorr key representation to the P2PK lock string; the native NIP-61 path must use the explicit 32-byte x-only key with `02` prefix. The standalone `sign(all:using:)` helper mutates copies of its input proofs, so it must not be used to build a redemption request. Construct and persist each proof's witness in the native request instead, and verify incoming DLEQ before accepting funds. None of these convenience helpers is currently used by the native payment flow.

## Verification

Seven core protocol/ledger tests and twenty focused simulator tests passed. The dependency regression also passed thirty Nostr, identity and remote-signer checks, with two optional public-relay checks skipped. Mint issuance is simulated locally with disposable test keys and valid DLEQ responses; no payment or wallet publication reaches a real service.

Deposit verification covers creation/restoration, an unpaid quote through service restart, once-only issue, lost mint response, delayed payment after expiry/archive, relay acknowledgment failure, stale wallet discovery, competing service instances and malformed invoice/keyset responses. The native UI test creates a wallet, checks deposit amount validation and restores it after relaunch through a loopback relay. A separate read-only check passed real Minibits metadata and all sat keysets; no real quote or payment was requested.
