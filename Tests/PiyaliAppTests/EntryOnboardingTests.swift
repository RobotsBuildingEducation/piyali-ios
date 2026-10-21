import XCTest
@testable import Piyali

@MainActor final class EntryOnboardingTests:XCTestCase {
    func testOnboardingDoesNotInventPlacementOrChangeAbilityAndRewards() throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Requires isolated test identity.") }
        let app=AppModel();try app.identity.create();defer { try? app.identity.disconnect() };app.learner=LearnerState()
        app.finishOnboarding()
        XCTAssertTrue(app.learner.onboardingComplete);XCTAssertEqual(app.learner.goal,"");XCTAssertEqual(app.learner.score,0);XCTAssertEqual(app.learner.totalXP,0)
        XCTAssertNil(app.learner.placements);XCTAssertNil(app.learner.pendingPlacements)
    }
}
