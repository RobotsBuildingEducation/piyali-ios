import XCTest
@testable import Piyali
final class WebNostrFixtures: XCTestCase {
 func testWebSignedDeletionEvent() throws {
 let json = #"{"kind":30078,"created_at":1700000000,"tags":[["d","learning-team:fixture"],["t","learning-team"],["deleted"]],"content":"{\"name\":\"Piyali / español 🌱\"}","pubkey":"79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798","id":"67af48b1d0021b45aedc7a05e26cbd263c7e56e3cd6d65ddc37a584fe82e6aab","sig":"52685c23c7d0bf6e46882e7b13ae3d4944a38c4e72678d7d7337f4f1655c71c729a1a163b0fedec5d789d43d875ab022461757a3dc42a97d5c752ed0b619af97"}"#
 let payload = try JSONDecoder().decode(NostrEventPayload.self, from: Data(json.utf8))
 XCTAssertTrue(IdentityService.verify(payload))
 }
}
