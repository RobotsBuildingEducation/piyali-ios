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
}
