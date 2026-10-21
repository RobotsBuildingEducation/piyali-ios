import XCTest
@testable import Piyali

@MainActor final class PracticeAccessTests:XCTestCase {
    func testFreePracticeUsesThreeHundredAccountXPWithoutClaimingPaidMembership() throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Isolated offline identity required.") }
        let identity=IdentityService();try identity.create();defer { try? identity.disconnect() }
        let subscription=SubscriptionService();XCTAssertFalse(subscription.hasAccess)
        subscription.bind(identity);XCTAssertFalse(subscription.hasAccess,"Wait for the account XP before allowing practice.")
        for xp in [0,1,299] { subscription.updatePracticeXP(xp);XCTAssertTrue(subscription.hasAccess);XCTAssertFalse(subscription.authorized);XCTAssertFalse(subscription.webAuthorized);XCTAssertFalse(subscription.appleAuthorized) }
        for xp in [300,301,500] { subscription.updatePracticeXP(xp);XCTAssertFalse(subscription.hasAccess) }
    }
    func testLearnerMutationUpdatesQuotaAcrossPracticeLanguages() throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Isolated offline identity required.") }
        let app=AppModel();try app.identity.create();defer { try? app.identity.disconnect() }
        app.subscription.bind(app.identity);app.learner.xpByLanguage=["es":200,"fr":99]
        XCTAssertEqual(app.subscription.practiceXP,299);XCTAssertTrue(app.subscription.hasAccess)
        app.learner.target="fr";XCTAssertTrue(app.subscription.hasAccess)
        app.learner.xpByLanguage["fr"]=100;XCTAssertEqual(app.subscription.practiceXP,300);XCTAssertFalse(app.subscription.hasAccess)
    }
}
