import Foundation
import CashuSwift
import secp256k1

/// Persist this complete batch in Keychain BEFORE submitting its blinded outputs to a mint.
/// Retaining the exact outputs, secrets and blinding factors permits NUT-09 recovery after a lost response.
struct CashuMintBatch:Codable,Sendable {
    let outputs:[CashuSwift.Output]
    let secrets:[String]
    let blindingFactors:[String]
    static func prepare(amount:Int,mint:CashuSwift.Mint,lock:String? = nil) throws -> CashuMintBatch {
        guard amount > 0,amount <= 1_000_000_000_000,let keyset=CashuSwift.activeKeysetForUnit("sat",mint:mint),keyset.validID else { throw WalletContract.Failure.invalidProof }
        var denominations:[Int]=[],remaining=amount,bit=1
        while remaining > 0 { if remaining & 1 == 1 { denominations.append(bit) };remaining >>= 1;bit <<= 1 }
        guard denominations.allSatisfy({ keyset.keys[String($0)] != nil }) else { throw WalletContract.Failure.invalidProof }
        let values:(outputs:[CashuSwift.Output],blindingFactors:[String],secrets:[String])
        if let lock {
            guard lock.hasPrefix("02"),lock.count == 66,WalletContract.key(String(lock.dropFirst(2))) else { throw WalletContract.Failure.invalidRecipient }
            _=try secp256k1.Signing.PublicKey(dataRepresentation:Self.bytes(lock),format:.compressed)
            values=try CashuSwift.generateP2PKOutputs(distribution:denominations,mint:mint,publicKey:lock,unit:"sat")
        } else { values=try CashuSwift.generateOutputs(distribution:denominations,mint:mint,seed:nil,unit:"sat") }
        return CashuMintBatch(outputs:values.outputs,secrets:values.secrets,blindingFactors:values.blindingFactors)
    }
    func unblind(_ promises:[CashuSwift.Promise],mint:CashuSwift.Mint) throws -> [CashuSwift.Proof] {
        guard !outputs.isEmpty,outputs.count == promises.count,secrets.count == outputs.count,blindingFactors.count == outputs.count,Set(outputs.map(\.B_)).count == outputs.count else { throw WalletContract.Failure.invalidProof }
        var proofs:[CashuSwift.Proof]=[]
        for index in outputs.indices {
            let output=outputs[index],promise=promises[index]
            guard promise.id == output.id,promise.amount == output.amount,let keyset=mint.keysets.first(where:{ $0.keysetID == output.id }),keyset.validID,let publicKey=keyset.keys[String(output.amount)],let dleq=promise.dleq else { throw WalletContract.Failure.invalidProof }
            let A=try secp256k1.Signing.PublicKey(dataRepresentation:Self.bytes(publicKey),format:.compressed)
            let blinded=try secp256k1.Signing.PublicKey(dataRepresentation:Self.bytes(promise.C_),format:.compressed)
            let r=try secp256k1.Signing.PrivateKey(dataRepresentation:Self.bytes(blindingFactors[index]))
            // NUT-00: C = C' - r*A. Point operations come from the shared secp256k1 library.
            let C=try blinded.combine([try A.multiply(Array(r.dataRepresentation)).negation])
            let verification=try JSONDecoder().decode(CashuSwift.DLEQ.self,from:JSONSerialization.data(withJSONObject:["e":dleq.e,"s":dleq.s,"r":blindingFactors[index]]))
            proofs.append(CashuSwift.Proof(keysetID:output.id,amount:output.amount,secret:secrets[index],C:Self.hex(C.dataRepresentation),dleq:verification))
        }
        guard case .valid = try CashuSwift.Crypto.checkDLEQ(for:proofs,with:mint) else { throw WalletContract.Failure.invalidProof }
        return proofs
    }
    /// NUT-09 may return outputs in a different order. Require the complete exact batch before finalizing.
    func recover(outputs restored:[CashuSwift.Output],signatures:[CashuSwift.Promise],mint:CashuSwift.Mint) throws -> [CashuSwift.Proof] {
        guard restored.count == signatures.count,restored.count == outputs.count,Set(restored.map(\.B_)).count == restored.count else { throw WalletContract.Failure.pending }
        let paired=Dictionary(uniqueKeysWithValues:zip(restored,signatures).map { ($0.0.B_,($0.0,$0.1)) })
        let ordered=try outputs.map { output -> CashuSwift.Promise in guard let value=paired[output.B_],value.0.id == output.id,value.0.amount == output.amount else { throw WalletContract.Failure.invalidProof };return value.1 }
        return try unblind(ordered,mint:mint)
    }
    static func hex(_ data:Data) -> String { data.map { String(format:"%02x",$0) }.joined() }
    static func bytes(_ hex:String) throws -> Data {
        guard !hex.isEmpty,hex.count % 2 == 0,hex.range(of:"^[0-9a-fA-F]+$",options:.regularExpression) != nil else { throw WalletContract.Failure.invalidProof }
        var data=Data();var offset=hex.startIndex
        while offset < hex.endIndex { let next=hex.index(offset,offsetBy:2);data.append(UInt8(hex[offset..<next],radix:16)!);offset=next };return data
    }
}
