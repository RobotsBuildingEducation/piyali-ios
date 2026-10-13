import XCTest
@testable import Piyali

final class FirebaseIdentityTests: XCTestCase {
    func testChallengeBindsSigningToOurEndpointAndIdentity() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let endpoint = URL(string: "https://piyali.example/auth/sign-in")!
        let hex = String(repeating: "a", count: 64)
        let nonce = UUID().uuidString.lowercased()
        func challenge(endpointURL: String = endpoint.absoluteString, publicKey: String = hex, expiry: Double = now.timeIntervalSince1970 * 1000 + 120_000, kind: Int = 27235) throws -> FirebaseSignInChallenge {
            let data = try JSONSerialization.data(withJSONObject: ["challengeId":nonce,"expiresAt":expiry,"event":["pubkey":publicKey,"created_at":Int64(now.timeIntervalSince1970),"kind":kind,"tags":[["u",endpointURL],["method","POST"],["challenge",nonce]],"content":"Piyali Firebase sign-in"]])
            return try JSONDecoder().decode(FirebaseSignInChallenge.self, from:data)
        }
        XCTAssertNoThrow(try challenge().validate(npubHex:hex,endpoint:endpoint,now:now))
        XCTAssertThrowsError(try challenge(endpointURL:"https://other.example/auth/sign-in").validate(npubHex:hex,endpoint:endpoint,now:now))
        XCTAssertThrowsError(try challenge(publicKey:String(repeating:"b",count:64)).validate(npubHex:hex,endpoint:endpoint,now:now))
        XCTAssertThrowsError(try challenge(expiry:now.timeIntervalSince1970 * 1000).validate(npubHex:hex,endpoint:endpoint,now:now))
        XCTAssertThrowsError(try challenge(kind:30078).validate(npubHex:hex,endpoint:endpoint,now:now))
    }
}
