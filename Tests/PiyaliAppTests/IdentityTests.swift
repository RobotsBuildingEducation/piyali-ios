import XCTest
import NostrSDK
@testable import Piyali

final class IdentityTests: XCTestCase {
    func testSchnorrSignatureAndTampering() throws {
        let keys = try XCTUnwrap(Keypair(hex: String(repeating: "0", count: 63) + "1"))
        let tags = [["d","learning-progress"],["t","learning-progress"]]
        let serialized = EventSerializer.serializedEvent(withPubkey: keys.publicKey.hex, createdAt: 1_700_000_000, kind: 30078, tags: try JSONDecoder().decode([Tag].self,from:JSONSerialization.data(withJSONObject:tags)), content: "{\"schemaVersion\":2}")
        let id = EventSerializer.identifierForEvent(withPubkey: keys.publicKey.hex, createdAt: 1_700_000_000, kind: 30078, tags: try JSONDecoder().decode([Tag].self,from:JSONSerialization.data(withJSONObject:tags)), content: "{\"schemaVersion\":2}")
        XCTAssertFalse(serialized.isEmpty)
        let sig = try NostrCrypto().signatureForContent(id, privateKey: keys.privateKey.hex)
        let payload = NostrEventPayload(id:id,pubkey:keys.publicKey.hex,created_at:1_700_000_000,kind:30078,tags:tags,content:"{\"schemaVersion\":2}",sig:sig)
        XCTAssertTrue(IdentityService.verify(payload))
        let changed = NostrEventPayload(id:id,pubkey:keys.publicKey.hex,created_at:1_700_000_000,kind:30078,tags:tags,content:"tampered",sig:sig)
        XCTAssertFalse(IdentityService.verify(changed))
    }
    func testNIP44OfficialKnownCiphertextStillDecryptsAfterCryptoDependencyChange() throws {
        // NIP-44's published sec1=1, sec2=2, plaintext="a" known-answer vector.
        let sender=try XCTUnwrap(Keypair(hex:String(repeating:"0",count:63)+"1")),recipient=try XCTUnwrap(Keypair(hex:String(repeating:"0",count:63)+"2"))
        let payload="AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABee0G5VSK0/9YypIObAtDKfYEAjD35uVkHyB0F4DwrcNaCXlCWZKaArsGrY6M9wnuTMxWfp1RTN9Xga8no+kF5Vsb"
        XCTAssertEqual(try NostrSessionCrypto().decrypt(payload:payload,privateKeyA:recipient.privateKey,publicKeyB:sender.publicKey),"a")
        var corrupt=Data(base64Encoded:payload)!;corrupt[corrupt.count-1] ^= 1
        XCTAssertThrowsError(try NostrSessionCrypto().decrypt(payload:corrupt.base64EncodedString(),privateKeyA:recipient.privateKey,publicKeyB:sender.publicKey))
    }

}
