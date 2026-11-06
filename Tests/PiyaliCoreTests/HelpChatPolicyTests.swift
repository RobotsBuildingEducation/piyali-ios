import XCTest
@testable import PiyaliCore
final class HelpChatPolicyTests:XCTestCase {
    func testOriginalHelpPolicies()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),policy=try HelpChatPolicy(url:root.appendingPathComponent("Piyali/Resources/help-chat-policy.js")),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/help-chat.json.gz"))
        XCTAssertGreaterThan(rows.count,700)
        for row in rows{XCTAssertEqual(try policy.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string+" "+row["input"].canonicalJSON)}
    }
}
