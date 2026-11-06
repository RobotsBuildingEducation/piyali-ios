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
    func testCompletingMultiLanguageDraftSavesGoalsAndLocalRelaunchWithoutDuplicateReceipts() throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else {throw XCTSkip("Requires isolated test identity.")}
        let app=AppModel();try app.identity.create();defer {try? app.identity.disconnect()};app.learner=LearnerState()
        var draft=OnboardingDraft(support:"en",target:"es");draft.goal="Talk with family";draft.choosePractice("fr");draft.goal="Order in a cafe";draft.chooseSupport("fr")
        app.finishOnboarding(draft);app.persist();let pending=app.learner.pendingGoalChanges?.map(\.id)
        app.learner=LearnerState();app.loadLocal()
        XCTAssertTrue(app.learner.onboardingComplete);XCTAssertEqual(app.learner.support,"fr");XCTAssertEqual(app.learner.target,"fr");XCTAssertEqual(app.learner.goal,"Order in a cafe")
        XCTAssertEqual(app.learner.goalIntelligence?["es"]?["activeGoal"]["text"].string,"Talk with family");XCTAssertEqual(app.learner.pendingGoalChanges?.map(\.id),pending);XCTAssertEqual(pending?.count,2)
        app.setPracticeLanguage("es");XCTAssertEqual(app.learner.goal,"Talk with family");XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.placements)
    }

}
