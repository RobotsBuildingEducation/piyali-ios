import XCTest
@testable import PiyaliCore
final class SubscriptionSourcePolicyTests:XCTestCase {
 func testOriginalMembershipAccessRecoveryFeedbackAndCurrencyStates()throws{
  let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/subscription-policy.json.gz")),policy=try SubscriptionSourcePolicy(url:root.appendingPathComponent("Piyali/Resources/subscription-policy.js"));XCTAssertEqual(rows.count,1053)
  for row in rows{XCTAssertEqual(try policy.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string+" "+row["input"].canonicalJSON)}
 }
}
