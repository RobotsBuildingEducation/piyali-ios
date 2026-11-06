import XCTest
@testable import PiyaliCore
final class TeamsPanelPolicyTests:XCTestCase {
    func testActualTeamsPanelPolicies()throws{let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),policy=try TeamsPanelPolicy(url:root.appendingPathComponent("Piyali/Resources/teams-panel-policy.js")),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/teams-panel.json.gz"));XCTAssertGreaterThan(rows.count,100);for row in rows{XCTAssertEqual(try policy.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string+" "+row["input"].canonicalJSON)}}
}
