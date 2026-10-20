import Foundation

/// Wire-only wallet values. Secrets belong in Keychain or NIP-44 ciphertext, never LearnerState.
public enum WalletContract {
    public static let defaultMint="https://mint.minibits.cash/Bitcoin"
    public static func mint(_ value:String) throws -> String {
        guard value.utf8.count <= 2048,let url=URLComponents(string:value),url.scheme == "https",let host=url.host,!host.isEmpty,url.user == nil,url.password == nil,url.query == nil,url.fragment == nil else { throw Failure.invalidMint }
        return value
    }
    public static func canonicalMint(_ value:String) throws -> String {
        _=try mint(value);var parts=URLComponents(string:value)!;parts.host=parts.host?.lowercased();if parts.port == 443 { parts.port=nil };while parts.path.hasSuffix("/") { parts.path.removeLast() };return parts.string!
    }
    public static func key(_ value:String) -> Bool { value.range(of:"^[0-9a-f]{64}$",options:.regularExpression) != nil }
    public enum Failure:LocalizedError { case invalidMint,invalidRecipient,invalidProof,invalidToken,conflictingProof,pending
        public var errorDescription:String? { switch self { case .invalidMint:"Use a secure Cashu mint URL without credentials, query or fragment.";case .invalidRecipient:"The recipient has not published valid nutzap payment information for a supported mint.";case .invalidProof:"The mint returned an invalid ecash proof.";case .invalidToken:"The wallet token could not be read.";case .conflictingProof:"Conflicting ecash proofs require a balance refresh.";case .pending:"Finish or recover the pending wallet operation first." } }
    }
}
public struct NutzapRecipient:Equatable,Sendable {
    public let author:String
    public let walletKey:String
    public let mints:[String]
    public let relays:[String]
    public init(author:String,tags:[[String]]) throws {
        let keys=tags.filter { $0.first == "pubkey" }.compactMap { $0.count == 2 ? $0[1] : nil }
        guard tags.count <= 128,WalletContract.key(author),keys.count == 1 else { throw WalletContract.Failure.invalidRecipient }
        let key=keys[0].hasPrefix("02") && keys[0].count == 66 ? String(keys[0].dropFirst(2)) : keys[0]
        guard WalletContract.key(key),key != author else { throw WalletContract.Failure.invalidRecipient }
        var seen=Set<String>();let mints=try tags.filter { $0.first == "mint" && $0.count >= 2 && ($0.count == 2 || $0.dropFirst(2).contains("sat")) }.map { try WalletContract.mint($0[1]) }.filter { seen.insert(try WalletContract.canonicalMint($0)).inserted }
        guard !mints.isEmpty,mints.count <= 16 else { throw WalletContract.Failure.invalidRecipient }
        self.author=author;self.walletKey="02"+key;self.mints=mints
        let relays=Array(Set(tags.filter { $0.first == "relay" && $0.count == 2 }.compactMap { try? BunkerConnection.relay($0[1]) })).sorted();guard relays.count <= 16 else { throw WalletContract.Failure.invalidRecipient };self.relays=relays
    }
    public func compatibleMint(holding:[String]) throws -> String {
        let allowed=Set(try holding.map(WalletContract.canonicalMint));guard let selected=try mints.first(where:{ allowed.contains(try WalletContract.canonicalMint($0)) }) else { throw WalletContract.Failure.invalidRecipient };return selected
    }
}
public struct WalletProof:Codable,Equatable,Sendable {
    public let wire:JSONValue
    public var id:String { wire["C"].string }
    public var secret:String { wire["secret"].string }
    public var amount:Int { Int(wire["amount"].number) }
    public init(_ wire:JSONValue) throws {
        guard case .number(let amount)=wire["amount"],amount.isFinite,amount > 0,amount <= pow(2,40),amount.rounded(.down) == amount,wire["id"].string.range(of:"^(?:[0-9a-f]{16}|[0-9a-f]{66}|[A-Za-z0-9+/]{12})$",options:.regularExpression) != nil,wire["C"].string.range(of:"^0[23][0-9a-f]{64}$",options:.regularExpression) != nil,!wire["secret"].string.isEmpty,wire["secret"].string.utf8.count <= 8192,wire.json.utf8.count <= 16_384 else { throw WalletContract.Failure.invalidProof }
        self.wire=wire
    }
    public func locked(to walletKey:String) -> Bool {
        guard let data=secret.data(using:.utf8),let value=try? JSONDecoder().decode(JSONValue.self,from:data),value.array.count == 2,value.array[0].string == "P2PK",value.array[1]["data"].string == walletKey,WalletContract.key(value.array[1]["nonce"].string),(value.array[1]["tags"] == .null || value.array[1]["tags"] == .array([])) else { return false };return true
    }
}
public struct WalletTokenRecord:Codable,Equatable,Sendable {
    public let id:String
    public let mint:String
    public let proofs:[WalletProof]
    public let destroyed:[String]
    public init(id:String,payload:JSONValue) throws {
        guard WalletContract.key(id),payload.json.utf8.count <= 60_000,payload["unit"] == .null || payload["unit"].string == "sat",payload["proofs"].array.count <= 512 else { throw WalletContract.Failure.invalidToken }
        self.id=id;self.mint=try WalletContract.mint(payload["mint"].string);self.proofs=try payload["proofs"].array.map(WalletProof.init)
        guard payload["del"].array.count <= 512,payload["del"].array.allSatisfy({ WalletContract.key($0.string) }),Set(proofs.map(\.id)).count == proofs.count,Set(proofs.map(\.secret)).count == proofs.count else { throw WalletContract.Failure.invalidToken };self.destroyed=payload["del"].array.map(\.string)
    }
}
/// Rollovers can arrive before their originals. Tombstones always win; proof identities are deduplicated.
public struct WalletLedger:Codable,Equatable,Sendable {
    public private(set) var records:[String:WalletTokenRecord]=[:]
    public private(set) var deleted=Set<String>()
    public init() {}
    public mutating func ingest(_ token:WalletTokenRecord) throws {
        if let existing=records[token.id],existing != token { throw WalletContract.Failure.conflictingProof }
        records[token.id]=token;deleted.formUnion(token.destroyed)
    }
    public mutating func remove(_ ids:[String]) { deleted.formUnion(ids.filter(WalletContract.key)) }
    public func proofs(mint:String) throws -> [WalletProof] {
        let desired=try WalletContract.canonicalMint(mint);var result:[String:WalletProof]=[:],secrets:[String:String]=[:]
        for token in records.values where !deleted.contains(token.id) && (try? WalletContract.canonicalMint(token.mint)) == desired {
            for proof in token.proofs {
                if let previous=result[proof.id],previous != proof { throw WalletContract.Failure.conflictingProof }
                if let previous=secrets[proof.secret],previous != proof.id { throw WalletContract.Failure.conflictingProof }
                result[proof.id]=proof;secrets[proof.secret]=proof.id
            }
        }
        return result.values.sorted { $0.id < $1.id }
    }
    public func balance(mint:String) throws -> Int { try proofs(mint:mint).reduce(0) { total,proof in let next=total.addingReportingOverflow(proof.amount);guard !next.overflow else { throw WalletContract.Failure.invalidProof };return next.partialValue } }
}
