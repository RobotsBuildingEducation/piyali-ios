import Foundation
import Security
import CryptoKit
import NostrSDK
import Combine

struct NostrEventPayload: Codable, Identifiable, Sendable {
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
struct SignerAuthorization:Identifiable { let id:UUID;let url:URL }
@MainActor final class IdentityService:ObservableObject {
    private let service: String
    private(set) var keypair: Keypair?
    private(set) var remoteRecord:RemoteSignerRecord?
    private var remote:RemoteSignerService?
    private var generation=UUID()
    private var connecting:Task<RemoteSignerRecord,Error>?
    private var signing:[UUID:Task<NostrEventPayload,Error>]=[:]
    private var crypting:[UUID:Task<String,Error>]=[:]
    @Published var authorization:SignerAuthorization?
    var isRemote:Bool { remoteRecord != nil }
    var npub: String { remoteRecord.flatMap { PublicKey(hex:$0.user)?.npub } ?? keypair?.publicKey.npub ?? "" }
    var hex: String { remoteRecord?.user ?? keypair?.publicKey.hex ?? "" }
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
        if status == errSecSuccess,let data=result as? Data {
            if let record=try? JSONDecoder().decode(RemoteSignerRecord.self,from:data),BunkerConnection.validKey(record.user),let restored=try? RemoteSignerService(signer:record.signer,relays:record.relays,clientNsec:record.clientNsec,allowLoopback:Self.allowLoopback) { remoteRecord=record;remote=restored }
            else if let nsec=String(data:data,encoding:.utf8) { keypair=Keypair(nsec:nsec) }
        }
    }
    private var baseQuery: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "identity"] }
    func create() throws { guard let keys = Keypair() else { throw AppError.message("Unable to create a Nostr key.") }; try store(keys) }
    func importKey(_ nsec: String) throws {
        let cleaned = nsec.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.hasPrefix("nsec1"), let keys = Keypair(nsec: cleaned), keys.privateKey.dataRepresentation.count == 32 else { throw AppError.message("Enter a valid nsec private key. An npub cannot sign in.") }
        try store(keys)
    }
    private func store(_ keys: Keypair) throws {
        try storeData(Data(keys.privateKey.nsec.utf8));cancelSigning();remoteRecord=nil;remote=nil;keypair=keys
    }
    private func storeData(_ data:Data) throws {
        let status = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let added = SecItemAdd(query as CFDictionary, nil)
            guard added == errSecSuccess else { throw AppError.message("Keychain could not save the key (\(added)).") }
        } else if status != errSecSuccess { throw AppError.message("Keychain could not save the key (\(status)).") }
    }
    private static var allowLoopback:Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" && UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil
        #else
        return false
        #endif
    }
    func cancelSigning() { generation=UUID();authorization=nil;connecting?.cancel();for task in signing.values { task.cancel() };for task in crypting.values { task.cancel() };let active=remote;Task { await active?.cancel() } }
    private func authorizer(_ token:UUID,request:UUID) -> @Sendable (URL) async -> Void {
        { [weak self] url in await MainActor.run { guard let self,self.generation == token else { return };if self.authorization?.url != url || self.authorization?.id != request { self.authorization=SignerAuthorization(id:request,url:url) } } }
    }
    func connect(_ bunker:String) async throws {
        let connection=try BunkerConnection(bunker,allowLoopback:Self.allowLoopback)
        guard let keys=Keypair() else { throw AppError.message("Unable to create a signer session.") }
        cancelSigning();let token=generation
        let candidate=try RemoteSignerService(signer:connection.signer,relays:connection.relays,clientNsec:keys.privateKey.nsec,allowLoopback:Self.allowLoopback)
        let authorize=authorizer(token,request:token)
        let task=Task { try await candidate.connected(connection,onAuthorization:authorize) };connecting=task
        defer { if generation == token { authorization=nil;connecting=nil } }
        do {
            let record=try await withTaskCancellationHandler { try await task.value } onCancel:{ task.cancel() }
            try Task.checkCancellation();guard generation == token else { throw CancellationError() }
            try storeData(JSONEncoder().encode(record));keypair=nil;remoteRecord=record;remote=candidate
        } catch { await candidate.cancel();throw error }
    }
    func disconnect() throws { let status=SecItemDelete(baseQuery as CFDictionary);guard status == errSecSuccess || status == errSecItemNotFound else { throw AppError.message("Keychain could not remove this session.") };cancelSigning();remote=nil;remoteRecord=nil;keypair=nil }
    func exportKey() -> String { keypair?.privateKey.nsec ?? "" }
    func sign(kind: Int, tags: [[String]], content: String, createdAt: Int64 = Int64(Date().timeIntervalSince1970)) throws -> NostrEventPayload {
        guard let keys = keypair else { throw AppError.message("Sign in first.") }
        return try Self.localEvent(keys:keys,kind:kind,tags:tags,content:content,createdAt:createdAt)
    }
    func signEvent(kind:Int,tags:[[String]],content:String,createdAt:Int64 = Int64(Date().timeIntervalSince1970),expectedAuthor:String? = nil) async throws -> NostrEventPayload {
        try Task.checkCancellation();guard expectedAuthor == nil || expectedAuthor == hex else { throw CancellationError() }
        guard let remote,let record=remoteRecord else { return try sign(kind:kind,tags:tags,content:content,createdAt:createdAt) }
        let token=generation,id=UUID()
        let authorize=authorizer(token,request:id)
        let task=Task { try await remote.sign(kind:kind,tags:tags,content:content,createdAt:createdAt,user:record.user,onAuthorization:authorize) };signing[id]=task
        defer { signing.removeValue(forKey:id);if generation == token,authorization?.id == id { authorization=nil } }
        let result=try await withTaskCancellationHandler { try await task.value } onCancel:{ task.cancel() }
        try Task.checkCancellation();guard generation == token,self.remote === remote else { throw CancellationError() };return result
    }
    func encryptWallet(_ plaintext:String,expectedAuthor:String) async throws -> String { try await walletCryptography(plaintext,decrypt:false,expectedAuthor:expectedAuthor) }
    func decryptWallet(_ ciphertext:String,expectedAuthor:String) async throws -> String { try await walletCryptography(ciphertext,decrypt:true,expectedAuthor:expectedAuthor) }
    private func walletCryptography(_ value:String,decrypt:Bool,expectedAuthor:String) async throws -> String {
        try Task.checkCancellation();guard expectedAuthor == hex,!value.isEmpty,value.utf8.count <= (decrypt ? 100_000 : 60_000) else { throw CancellationError() }
        if decrypt { guard let raw=Data(base64Encoded:value),raw.count >= 99,raw.first == 2 else { throw BunkerConnection.Failure.invalidResponse } }
        guard let remote,let record=remoteRecord else {
            guard let keys=keypair else { throw AppError.message("Sign in before opening the wallet.") }
            return try decrypt ? NostrSessionCrypto().decrypt(payload:value,privateKeyA:keys.privateKey,publicKeyB:keys.publicKey) : NostrSessionCrypto().encrypt(plaintext:value,privateKeyA:keys.privateKey,publicKeyB:keys.publicKey)
        }
        let token=generation,id=UUID();let authorize=authorizer(generation,request:id)
        let task=Task { let result=try await remote.request(decrypt ? "nip44_decrypt" : "nip44_encrypt",params:[record.user,value],onAuthorization:authorize);guard case .string(let string)=result,!string.isEmpty,string.utf8.count <= (decrypt ? 60_000 : 100_000) else { throw BunkerConnection.Failure.invalidResponse };return string };crypting[id]=task
        defer { crypting.removeValue(forKey:id);if generation == token,authorization?.id == id { authorization=nil } }
        let result=try await withTaskCancellationHandler { try await task.value } onCancel:{ task.cancel() }
        try Task.checkCancellation();guard generation == token,self.remote === remote,self.hex == expectedAuthor else { throw CancellationError() }
        if !decrypt { guard let raw=Data(base64Encoded:result),raw.count >= 99,raw.first == 2 else { throw BunkerConnection.Failure.invalidResponse } }
        return result
    }
    nonisolated static func localEvent(keys:Keypair,kind:Int,tags:[[String]],content:String,createdAt:Int64 = Int64(Date().timeIntervalSince1970)) throws -> NostrEventPayload {
        let serialized = try JSONSerialization.data(withJSONObject: [0, keys.publicKey.hex, createdAt, kind, tags, content], options: [.withoutEscapingSlashes, .fragmentsAllowed])
        let id = SHA256.hash(data: serialized).map { String(format: "%02x", $0) }.joined()
        let sig = try NostrCrypto().signatureForContent(id, privateKey: keys.privateKey.hex)
        return NostrEventPayload(id: id, pubkey: keys.publicKey.hex, created_at: createdAt, kind: kind, tags: tags, content: content, sig: sig)
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
