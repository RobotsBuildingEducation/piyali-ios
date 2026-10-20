import XCTest
import CryptoKit
import CashuSwift
import secp256k1
@testable import Piyali

final class CashuMintBatchTests:XCTestCase {
    private func fixture() throws -> (CashuSwift.Mint,secp256k1.Signing.PrivateKey) {
        let key=try secp256k1.Signing.PrivateKey(dataRepresentation:Data(repeating:1,count:32)),hex=CashuMintBatch.hex(key.publicKey.dataRepresentation)
        let keys=["1":hex,"2":hex,"4":hex,"8":hex],serialized=try [1,2,4,8].reduce(into:Data()) { bytes,amount in bytes.append(try CashuMintBatch.bytes(keys[String(amount)]!)) }
        let id="00"+CashuMintBatch.hex(Data(SHA256.hash(data:serialized))).prefix(14)
        let keyset=try JSONDecoder().decode(CashuSwift.Keyset.self,from:JSONSerialization.data(withJSONObject:["id":id,"unit":"sat","active":true,"keys":keys]))
        XCTAssertTrue(keyset.validID);return(CashuSwift.Mint(url:URL(string:"https://test.mint.invalid")!,keysets:[keyset]),key)
    }
    /// A local issuer evaluates NUT-12's DLEQ equations; it has no network or monetary value.
    private func issue(_ batch:CashuMintBatch,key:secp256k1.Signing.PrivateKey) throws -> [CashuSwift.Promise] {
        try batch.outputs.map { output in
            let B=try secp256k1.Signing.PublicKey(dataRepresentation:CashuMintBatch.bytes(output.B_),format:.compressed)
            let C=try B.multiply(Array(key.dataRepresentation)),nonce=try secp256k1.Signing.PrivateKey()
            let R1=nonce.publicKey,R2=try B.multiply(Array(nonce.dataRepresentation))
            let material=[R1,R2,key.publicKey,C].map { CashuMintBatch.hex($0.uncompressedRepresentation) }.joined()
            let e=Data(SHA256.hash(data:Data(material.utf8))),s=try key.multiply(Array(e)).add(Array(nonce.dataRepresentation))
            return try JSONDecoder().decode(CashuSwift.Promise.self,from:JSONSerialization.data(withJSONObject:["id":output.id,"amount":output.amount,"C_":CashuMintBatch.hex(C.dataRepresentation),"dleq":["e":CashuMintBatch.hex(e),"s":CashuMintBatch.hex(s.dataRepresentation)]]))
        }
    }
    func testPersistedBlindedBatchUnblindsAndVerifiesDLEQWithoutAnyMintConnection() throws {
        let (mint,key)=try fixture(),batch=try CashuMintBatch.prepare(amount:7,mint:mint)
        let persisted=try JSONDecoder().decode(CashuMintBatch.self,from:JSONEncoder().encode(batch)),signatures=try issue(persisted,key:key),proofs=try persisted.unblind(signatures,mint:mint)
        XCTAssertEqual(proofs.map(\.amount).reduce(0,+),7);XCTAssertEqual(proofs.map(\.secret),batch.secrets)
        XCTAssertEqual(try CashuSwift.Crypto.checkDLEQ(for:proofs,with:mint),.valid)
    }
    func testLostResponseRecoveryUsesExactSavedOutputsEvenIfRestoreReordersThem() throws {
        let (mint,key)=try fixture(),batch=try CashuMintBatch.prepare(amount:7,mint:mint),signatures=try issue(batch,key:key)
        let restored=try batch.recover(outputs:Array(batch.outputs.reversed()),signatures:Array(signatures.reversed()),mint:mint)
        XCTAssertEqual(restored.map(\.amount),batch.outputs.map(\.amount))
        XCTAssertThrowsError(try batch.recover(outputs:Array(batch.outputs.dropLast()),signatures:Array(signatures.dropLast()),mint:mint))
    }
    func testP2PKOutputsRemainLockedToAdvertisedWalletKeyAfterUnblinding() throws {
        let (mint,key)=try fixture(),recipient=try secp256k1.Schnorr.PrivateKey(),lock="02"+CashuMintBatch.hex(Data(recipient.xonly.bytes))
        let batch=try CashuMintBatch.prepare(amount:1,mint:mint,lock:lock),proofs=try batch.unblind(issue(batch,key:key),mint:mint)
        let value=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(proofs[0]));XCTAssertTrue(try WalletProof(value).locked(to:lock))
    }
    func testTamperedSignaturesWrongDenominationsAndMissingDLEQAreRejected() throws {
        let (mint,key)=try fixture(),batch=try CashuMintBatch.prepare(amount:1,mint:mint),signature=try issue(batch,key:key)[0]
        let raw=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(signature))
        for changed in [raw.setting("amount",.number(2)),raw.setting("dleq",.null),raw.setting("C_",.string(CashuMintBatch.hex(key.publicKey.dataRepresentation))),raw.setting("dleq",.object(["e":.string(String(repeating:"1",count:64)),"s":.string(String(repeating:"1",count:64))]))] {
            let wrong=try JSONDecoder().decode(CashuSwift.Promise.self,from:JSONEncoder().encode(changed));XCTAssertThrowsError(try batch.unblind([wrong],mint:mint))
        }
        XCTAssertThrowsError(try CashuMintBatch.prepare(amount:0,mint:mint))
        XCTAssertThrowsError(try CashuMintBatch.prepare(amount:1,mint:mint,lock:"02"+String(repeating:"f",count:64)))
    }
}
