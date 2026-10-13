import XCTest
import FirebaseFirestore
@testable import Piyali

final class AchievementContractTests: XCTestCase {
    func testCompletionDocumentIDsMatchReferenceIncludingUnicodeAndSlashes() throws {
        let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"achievement-hashes",withExtension:"json"))
        let fixtures=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        for fixture in fixtures { XCTAssertEqual(try AchievementSyncService.documentID(metric:fixture["metric"].string,id:fixture["id"].string),fixture["expected"].string) }
    }
    func testTimestampConversionKeepsSummaryAndUnknownFieldsCannotEraseEvidence() {
        let now=Date(),value=AchievementSyncService.jsonFields(["skillTree":["levels":["a1":["completed":3,"total":98]]],"updatedAt":Timestamp(date:now),"unknown":NSObject()])
        XCTAssertEqual(value["skillTree"]["levels"]["a1"]["completed"].number,3)
        XCTAssertEqual(value["updatedAt"].string,WebProgressContract.iso(now));XCTAssertEqual(value["unknown"],.null)
    }
}
