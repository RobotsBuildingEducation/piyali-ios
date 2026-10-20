import Foundation

public struct ImportedWalletConfiguration:Equatable,Sendable {
    public let privateKeys:[String]
    public let mints:[String]
    public init(_ payload:JSONValue) throws {
        guard !payload.array.isEmpty,payload.array.count <= 128,payload.json.utf8.count <= 60_000 else { throw WalletContract.Failure.invalidToken }
        let keys=payload.array.filter { ["privkey","legacy_privkey"].contains($0.array.first?.string ?? "") }.map { $0.array }
        guard !keys.isEmpty,keys.count <= 32,keys.allSatisfy({ $0.count == 2 && WalletContract.key($0[1].string) }) else { throw WalletContract.Failure.invalidToken }
        var seen=Set<String>();privateKeys=keys.map { $0[1].string }.filter { seen.insert($0).inserted }
        let values=payload.array.filter { $0.array.first?.string == "mint" }.map { $0.array }
        guard !values.isEmpty,values.count <= 16,values.allSatisfy({ $0.count >= 2 }) else { throw WalletContract.Failure.invalidToken }
        var unique=Set<String>();mints=try values.map { try WalletContract.mint($0[1].string) }.filter { unique.insert($0).inserted }
    }
}
public enum WalletImport {
    public static func token(_ payload:JSONValue,mintTag:String) throws -> JSONValue {
        if payload["mint"] != .null { return payload }
        return payload.setting("mint",.string(try WalletContract.mint(mintTag)))
    }
    public static func quote(_ payload:JSONValue,eventID:String) throws -> JSONValue {
        let id=payload["quoteId"].string.isEmpty ? payload["quote"].string : payload["quoteId"].string
        guard id.range(of:"^[A-Za-z0-9_-]{1,256}$",options:.regularExpression) != nil,case .number(let amount)=payload["amount"],amount > 0,amount <= 1_000_000,amount.rounded(.down) == amount,payload["unit"] == .null || payload["unit"].string == "sat" else { throw WalletContract.Failure.invalidToken }
        let mint=try WalletContract.mint(payload["mint"].string)
        return .object(["mint":.string(mint),"amount":.number(amount),"legacyEventID":.string(eventID),"quote":.object(["quote":.string(id),"amount":.number(amount),"unit":.string("sat")])])
    }
}
