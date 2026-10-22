import XCTest
import SwiftUI
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
    func testVisibleFooterWithdrawsAtQuotaAndRestoresWithAccess() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Isolated offline identity required.") }
        let app=AppModel();try app.identity.create();defer { try? app.identity.disconnect() }
        app.subscription.bind(app.identity);app.signedIn=true;app.learner.xpByLanguage=["es":299]
        let owner=UUID()
        let view=Text("Activity").activityFooter(owner:owner,revision:"same-run",access:app.subscription) { Button("Record") {} }.environmentObject(app)
        let window=UIWindow(frame:UIScreen.main.bounds);window.rootViewController=UIHostingController(rootView:view);window.makeKeyAndVisible()
        defer { window.isHidden=true;window.rootViewController=nil }
        func awaitFooter(_ present:Bool) async {
            for _ in 0..<120 {
                if (app.activityFooter?.owner == owner) == present { return }
                try? await Task.sleep(for:.milliseconds(25))
            }
            XCTFail("Footer visibility did not follow practice access")
        }
        await awaitFooter(true)
        app.learner.xpByLanguage["es"]=300
        await awaitFooter(false)
        app.learner.xpByLanguage["es"]=299
        await awaitFooter(true)
    }

}
