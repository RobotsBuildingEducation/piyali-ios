import Foundation
import CashuSwift
import Bolt11
import secp256k1

@MainActor protocol WalletMintNetworking {
    func loadMint(_ value:String) async throws -> CashuSwift.Mint
    func request(mint:String,path:String,body:JSONValue?) async throws -> JSONValue
    func states(_ proofs:[CashuSwift.Proof],mint:CashuSwift.Mint) async throws -> [CashuSwift.Proof.ProofState]
}
@MainActor final class CashuHTTPClient:WalletMintNetworking {
    private let session:URLSession
    init(session:URLSession = .shared) { self.session=session }
    func request(mint:String,path:String,body:JSONValue? = nil) async throws -> JSONValue {
        _=try WalletContract.mint(mint);guard path.hasPrefix("v1/"),!path.contains(".."),!path.contains("?"),!path.contains("#"),let base=URL(string:mint) else { throw WalletContract.Failure.invalidMint }
        var request=URLRequest(url:base.appending(path:path));request.timeoutInterval=30;request.cachePolicy = .reloadIgnoringLocalCacheData
        if let body { request.httpMethod="POST";request.httpBody=try JSONEncoder().encode(body);request.setValue("application/json",forHTTPHeaderField:"Content-Type") }
        let (data,response)=try await session.data(for:request);try Task.checkCancellation()
        guard let response=response as? HTTPURLResponse,(200..<300).contains(response.statusCode),data.count <= 2_097_152 else { throw AppError.message("The mint could not complete this request. Refresh or recover the saved operation before trying another payment.") }
        return try JSONDecoder().decode(JSONValue.self,from:data)
    }
    func loadMint(_ value:String) async throws -> CashuSwift.Mint {
        let list=try await request(mint:value,path:"v1/keysets");let entries=list["keysets"].array
        guard !entries.isEmpty,entries.count <= 128 else { throw WalletContract.Failure.invalidProof };var keysets:[CashuSwift.Keyset]=[]
        for entry in entries where entry["unit"].string == "sat" {
            let id=entry["id"].string
            guard id.range(of:"^(?:[0-9a-f]{16}|[0-9a-f]{66}|[A-Za-z0-9+/]{12})$",options:.regularExpression) != nil else { throw WalletContract.Failure.invalidProof }
            let safe=id.replacingOccurrences(of:"+",with:"-").replacingOccurrences(of:"/",with:"_")
            let response=try await request(mint:value,path:"v1/keys/"+safe)
            guard let keys=response["keysets"].array.first(where:{ $0["id"].string == id }),!keys["keys"].object.isEmpty,keys["keys"].object.count <= 64 else { throw WalletContract.Failure.invalidProof }
            let keyset=try JSONDecoder().decode(CashuSwift.Keyset.self,from:JSONEncoder().encode(entry.setting("keys",keys["keys"])))
            guard keyset.validID,keyset.keys.allSatisfy({ UInt64($0.key).map { $0 > 0 } ?? false }),keyset.inputFeePPK >= 0,keyset.inputFeePPK <= 1_000_000 else { throw WalletContract.Failure.invalidProof };for key in keyset.keys.values { _=try secp256k1.Signing.PublicKey(dataRepresentation:CashuMintBatch.bytes(key),format:.compressed) };keysets.append(keyset)
        }
        guard keysets.contains(where:{ $0.active && $0.unit == "sat" }) else { throw WalletContract.Failure.invalidMint }
        return CashuSwift.Mint(url:URL(string:value)!,keysets:keysets)
    }
    func states(_ proofs:[CashuSwift.Proof],mint:CashuSwift.Mint) async throws -> [CashuSwift.Proof.ProofState] {
        guard proofs.count <= 512 else { throw WalletContract.Failure.invalidProof }
        if proofs.isEmpty { return [] };let states=try await CashuSwift.check(proofs,mint:mint);guard states.count == proofs.count else { throw WalletContract.Failure.invalidProof };return states
    }
    static func validateQuote(_ quote:JSONValue,amount:Int,now:Date) throws -> JSONValue {
        let id=quote["quote"].string,request=quote["request"].string
        guard amount > 0,amount <= 1_000_000,request.utf8.count <= 12_000,request.lowercased().hasPrefix("lnbc"),id.range(of:"^[A-Za-z0-9_-]{1,256}$",options:.regularExpression) != nil,quote["unit"] == .null || quote["unit"].string == "sat" else { throw WalletContract.Failure.invalidToken }
        let decoded=try Bolt11Decoder.decode(request)
        guard decoded.amountMillisatoshis == UInt64(amount)*1000,Double(decoded.timestamp)+Double(decoded.expiryTime) > now.timeIntervalSince1970,quote["amount"] == .null || quote["amount"].number == Double(amount) else { throw WalletContract.Failure.invalidToken }
        let expiry=quote["expiry"] == .null ? min(now.timeIntervalSince1970+1800,Double(decoded.timestamp)+Double(decoded.expiryTime)) : min(quote["expiry"].number,Double(decoded.timestamp)+Double(decoded.expiryTime))
        let state=quote["state"].string.isEmpty ? (quote["paid"].boolean ? "PAID" : "UNPAID") : quote["state"].string
        guard ["UNPAID","PAID","ISSUED"].contains(state),expiry > now.timeIntervalSince1970 else { throw AppError.message("The deposit invoice expired. Refresh its payment status before requesting another invoice.") }
        return quote.setting("amount",.number(Double(amount))).setting("unit",.string("sat")).setting("state",.string(state)).setting("expiry",.number(expiry))
    }
}
