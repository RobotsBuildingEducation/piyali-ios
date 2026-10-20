import Foundation
import Security
import CashuSwift
import NostrSDK

/// A monetary operation stays reserved until its mint response and relay publication are reconciled.
struct WalletPendingOperation:Codable,Sendable {
    enum Purpose:String,Codable,Sendable { case deposit,tip,receive }
    enum Phase:String,Codable,Sendable { case prepared,submitted,minted,publishing }
    let id:UUID
    let purpose:Purpose
    let mint:String
    let amount:Int
    let batch:CashuMintBatch
    let inputs:[WalletProof]
    let destroyedTokenIDs:[String]
    let recipient:NutzapDestination?
    let keepCount:Int
    let quote:JSONValue?
    var phase:Phase = .prepared
    var rollover:[WalletProof]?
    var mintFee:Int?
    var incoming:[NostrEventPayload]?
    var signatures:[CashuSwift.Promise]?
    var received:[WalletProof]?
    var outbox:[NostrEventPayload]=[]
    var acknowledged=Set<String>()
    let createdAt:Date
    init(purpose:Purpose,mint:String,amount:Int,batch:CashuMintBatch,inputs:[WalletProof] = [],destroyedTokenIDs:[String] = [],recipient:NutzapDestination? = nil,keepCount:Int = 0,quote:JSONValue? = nil) {
        id=UUID();self.purpose=purpose;self.mint=mint;self.amount=amount;self.batch=batch;self.inputs=inputs;self.destroyedTokenIDs=destroyedTokenIDs;self.recipient=recipient;self.keepCount=keepCount;self.quote=quote;createdAt=Date()
    }
}
struct NutzapDestination:Codable,Equatable,Sendable {
    let author:String
    let walletKey:String
    let mint:String
    let relays:[String]
}
struct WalletPrivateState:Codable,Sendable {
    let owner:String
    let walletPrivateKey:String
    var mints:[String]
    var relays:[String]
    var ledger=WalletLedger()
    var pending:WalletPendingOperation?
    var configurationOutbox:[NostrEventPayload]=[]
    var redeemed=Set<String>()
    var sentReceipts:[NostrEventPayload]?
    var archivedInvoices:[JSONValue]?
    var invoice:JSONValue?
    var configurationPublished=false
}
/// This vault is deliberately separate from the learner's Firebase JSON snapshot.
/// Disconnecting an identity preserves its account-scoped recovery data for a later sign-in.
struct WalletVault {
    private let service:String
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",let scope=ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"],UUID(uuidString:scope) != nil { service="app.piyali.ios.wallet.test."+scope;return }
        #endif
        service="app.piyali.ios.wallet"
    }
    private func query(_ owner:String) throws -> [String:Any] {
        guard WalletContract.key(owner) else { throw AppError.message("Sign in before opening the wallet.") }
        return [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:owner]
    }
    func load(owner:String) throws -> WalletPrivateState? {
        var query=try query(owner);query[kSecReturnData as String]=true;query[kSecMatchLimit as String]=kSecMatchLimitOne
        var item:CFTypeRef?;let status=SecItemCopyMatching(query as CFDictionary,&item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,let data=item as? Data,let state=try? JSONDecoder().decode(WalletPrivateState.self,from:data),state.owner == owner,Keypair(hex:state.walletPrivateKey) != nil else { throw AppError.message("Wallet recovery data could not be read. Keep this device's data while recovering the wallet.") }
        return state
    }
    func save(_ state:WalletPrivateState) throws {
        guard Keypair(hex:state.walletPrivateKey) != nil else { throw WalletContract.Failure.invalidProof }
        let query=try query(state.owner),data=try JSONEncoder().encode(state)
        guard data.count <= 2_000_000 else { throw AppError.message("The wallet needs to consolidate its saved records before continuing.") }
        let status=SecItemUpdate(query as CFDictionary,[kSecValueData as String:data] as CFDictionary)
        if status == errSecItemNotFound {
            var new=query;new[kSecValueData as String]=data;new[kSecAttrAccessible as String]=kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(new as CFDictionary,nil) == errSecSuccess else { throw AppError.message("Keychain could not save the wallet recovery data. The operation has not been submitted.") }
        } else if status != errSecSuccess { throw AppError.message("Keychain could not update the wallet recovery data. Keep this device's data while recovering the wallet.") }
    }
    #if DEBUG
    func removeTestState(owner:String) throws {
        guard service.contains(".test."),ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" else { throw AppError.message("Wallet data removal is available only to isolated tests.") }
        let status=SecItemDelete(try query(owner) as CFDictionary);guard status == errSecSuccess || status == errSecItemNotFound else { throw AppError.message("Test wallet cleanup failed.") }
    }
    #endif
}
