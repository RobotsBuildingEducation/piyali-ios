import XCTest
@testable import Piyali
final class PatreonRestoreTests: XCTestCase {
    func testOnlyFreshSubscriptionRestoreEventsMayBeSigned() throws {
        let now = Date(), id = String(repeating:"a",count:32)
        let content = "Authorize Piyali Patreon restore: " + String(repeating:"b",count:43)
        func challenge(kind: Int = 27235, action: String = "restore", expires: Date = now.addingTimeInterval(300), text: String = content) throws -> PatreonRestoreChallenge {
            let parser = ISO8601DateFormatter(); parser.formatOptions = [.withInternetDateTime,.withFractionalSeconds]
            let fields: [String:Any] = ["challengeId":id,"eventTemplate":["kind":kind,"created_at":Int64(now.timeIntervalSince1970),"tags":[["action",action],["challenge",id],["expires",parser.string(from:expires)]],"content":text]]
            return try JSONDecoder().decode(PatreonRestoreChallenge.self,from:JSONSerialization.data(withJSONObject:fields))
        }
        XCTAssertNoThrow(try challenge().validate(now:now))
        XCTAssertThrowsError(try challenge(kind:30078).validate(now:now))
        XCTAssertThrowsError(try challenge(action:"disconnect").validate(now:now))
        XCTAssertThrowsError(try challenge(expires:now.addingTimeInterval(-1)).validate(now:now))
        XCTAssertThrowsError(try challenge(text:"Publish my team").validate(now:now))
    }
}
