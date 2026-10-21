import XCTest
@testable import PiyaliCore

final class SubscriptionXPTests:XCTestCase {
    func testWebGatePrefersRootAccountXPAndCountsNewAwardsWithoutChangingLanguageProgress() {
        let fields:[String:Any] = ["xp":300,"progress":["totalXp":250,"languageXp":["es":100,"fr":150],"targetLang":"es"]]
        var state=WebProgressContract.imported(fields)
        XCTAssertEqual(state.totalXP,250);XCTAssertEqual(state.subscriptionXP,300)
        state.target="fr";XCTAssertEqual(state.subscriptionXP,300)
        state.award(5);XCTAssertEqual(state.totalXP,255);XCTAssertEqual(state.subscriptionXP,305)
    }
    func testMissingAndInvalidRootValuesFallBackToTheWebProgressTotal() {
        for root in [nil,"invalid"] as [String?] {
            var fields:[String:Any] = ["progress":["totalXp":299,"languageXp":["es":120,"fr":179]]]
            if let root { fields["xp"]=root }
            XCTAssertEqual(WebProgressContract.imported(fields).subscriptionXP,299)
        }
        XCTAssertGreaterThanOrEqual(WebProgressContract.imported(["xp":1e100]).subscriptionXP,300)
    }
}
