import XCTest
@testable import PiyaliCore
final class RPGObjectPolicyTests:XCTestCase {
    func testOriginalObjectFallbackPromptReplyAndHitCases()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),p=try RPGObjectPolicy(url:root.appendingPathComponent("Piyali/Resources/rpg-objects-policy.js")),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/rpg-objects.json.gz"))
        XCTAssertEqual(rows.count,590)
        for row in rows{XCTAssertEqual(try p.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string+" "+row["input"].canonicalJSON)}
    }
}
