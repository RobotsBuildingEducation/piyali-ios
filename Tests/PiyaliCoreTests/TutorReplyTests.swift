import XCTest
@testable import PiyaliCore
final class TutorReplyTests:XCTestCase {
    func testOriginalFilteringOverlapRepeatedUnicodeAndEmptyPhraseCases()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),policy=try TutorReplyPolicy(source:String(contentsOf:root.appendingPathComponent("Piyali/Resources/tutor-reply-policy.js"),encoding:.utf8)),cases=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/tutor-reply.json.gz")).array
        XCTAssertEqual(cases.count,40)
        for row in cases{let input=row["input"];XCTAssertEqual(try policy.plan(primary:input["primaryText"].string,secondary:input["secondaryText"].string,pairs:input["pairs"]),row["expected"],input.json)}
    }
}
