import Foundation
import Security
import CryptoKit
import NostrSDK

struct NostrEventPayload: Codable, Identifiable {
    let id: String
    let pubkey: String
    let created_at: Int64
    let kind: Int
    let tags: [[String]]
    let content: String
    let sig: String
    func tag(_ key: String) -> String { tags.first(where: { $0.first == key })?.dropFirst().first ?? "" }
}
struct NostrCrypto: ContentSigning, EventVerifying {}
@MainActor final class IdentityService {
    private let service: String
    private(set) var keypair: Keypair?
    var npub: String { keypair?.publicKey.npub ?? "" }
    var hex: String { keypair?.publicKey.hex ?? "" }
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",
           let scope = ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"], UUID(uuidString:scope) != nil {
            service = "app.piyali.ios.nostr.ui-test." + scope
        } else { service = "app.piyali.ios.nostr" }
        #else
        service = "app.piyali.ios.nostr"
        #endif
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let nsec = String(data: data, encoding: .utf8) { keypair = Keypair(nsec: nsec) }
    }
    private var baseQuery: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "identity"] }
    func create() throws { guard let keys = Keypair() else { throw AppError.message("Unable to create a Nostr key.") }; try store(keys) }
    func importKey(_ nsec: String) throws {
        let cleaned = nsec.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.hasPrefix("nsec1"), let keys = Keypair(nsec: cleaned), keys.privateKey.dataRepresentation.count == 32 else { throw AppError.message("Enter a valid nsec private key. An npub cannot sign in.") }
        try store(keys)
    }
    private func store(_ keys: Keypair) throws {
        let data = Data(keys.privateKey.nsec.utf8)
        let status = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let added = SecItemAdd(query as CFDictionary, nil)
            guard added == errSecSuccess else { throw AppError.message("Keychain could not save the key (\(added)).") }
        } else if status != errSecSuccess { throw AppError.message("Keychain could not save the key (\(status)).") }
        keypair = keys
    }
    func exportKey() -> String { keypair?.privateKey.nsec ?? "" }
    func sign(kind: Int, tags: [[String]], content: String, createdAt: Int64 = Int64(Date().timeIntervalSince1970)) throws -> NostrEventPayload {
        guard let keys = keypair else { throw AppError.message("Sign in first.") }
        let serialized = try JSONSerialization.data(withJSONObject: [0, hex, createdAt, kind, tags, content], options: [.withoutEscapingSlashes, .fragmentsAllowed])
        let id = SHA256.hash(data: serialized).map { String(format: "%02x", $0) }.joined()
        let sig = try NostrCrypto().signatureForContent(id, privateKey: keys.privateKey.hex)
        return NostrEventPayload(id: id, pubkey: hex, created_at: createdAt, kind: kind, tags: tags, content: content, sig: sig)
    }
    nonisolated static func verify(_ payload: NostrEventPayload) -> Bool {
        guard payload.pubkey.count == 64, payload.sig.count == 128, payload.id.count == 64,
              payload.tags.allSatisfy({ !$0.isEmpty }),
              let serialized = try? JSONSerialization.data(withJSONObject: [0, payload.pubkey, payload.created_at, payload.kind, payload.tags, payload.content], options: [.withoutEscapingSlashes, .fragmentsAllowed]) else { return false }
        // Keep wire tags intact, including single-element ["deleted"] tags from the web.
        let expected = SHA256.hash(data: serialized).map { String(format: "%02x", $0) }.joined()
        guard payload.id == expected else { return false }
        return (try? NostrCrypto().verifySignature(payload.sig, for: payload.id, withPublicKey: payload.pubkey)) != nil
    }
    // Bind StoreKit entitlements to the same Nostr learner without exposing their key.
    var accountToken: UUID {
        let digest = Array(SHA256.hash(data: Data(npub.utf8)))
        return UUID(uuid: (digest[0],digest[1],digest[2],digest[3],digest[4],digest[5],digest[6],digest[7],digest[8],digest[9],digest[10],digest[11],digest[12],digest[13],digest[14],digest[15]))
    }
}
enum AppError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let s) = self { return s }; return nil }
}
