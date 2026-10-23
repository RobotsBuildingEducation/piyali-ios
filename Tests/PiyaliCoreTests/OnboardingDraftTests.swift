import XCTest
@testable import PiyaliCore

final class OnboardingDraftTests:XCTestCase {
    func testLanguageChangesKeepEveryGoalAndSupportDoesNotResetPractice() throws {
        var draft=OnboardingDraft(support:"en",target:"es")
        draft.goal="Talk with family";draft.choosePractice("fr");XCTAssertEqual(draft.goal,"")
        draft.goal="Order in a cafe";draft.chooseSupport("ar");XCTAssertEqual(draft.target,"fr");XCTAssertEqual(draft.goal,"Order in a cafe")
        draft.choosePractice("es");XCTAssertEqual(draft.goal,"Talk with family")
        // Community-only languages are hidden by the original selector and
        // must not become a native AI practice selection.
        draft.choosePractice("nah");XCTAssertEqual(draft.target,"es")
        // Payload observed from the original Onboarding component after the
        // equivalent English/French goal journey in the read-only browser fixture.
        draft.chooseSupport("fr");draft.choosePractice("fr")
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/onboarding-completion.json")))
        XCTAssertEqual(draft.support,fixture["supportLang"].string);XCTAssertEqual(draft.target,fixture["targetLang"].string);XCTAssertEqual(draft.learningGoals,fixture["learningGoals"].object.mapValues(\.string))
        var learner=LearnerState();learner.completeOnboarding(draft)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(learner))
        XCTAssertEqual(restored.support,"fr");XCTAssertEqual(restored.target,"fr");XCTAssertEqual(restored.goal,"Order in a cafe")
        XCTAssertEqual(restored.goalIntelligence?["es"]?["activeGoal"]["text"].string,"Talk with family")
        XCTAssertEqual(restored.goalIntelligence?["fr"]?["activeGoal"]["text"].string,"Order in a cafe")
        XCTAssertEqual(Set(restored.pendingGoalChanges?.map(\.target) ?? []),["es","fr"])
        XCTAssertEqual(restored.totalXP,0);XCTAssertEqual(restored.score,0);XCTAssertNil(restored.placements)
    }
    func testBlankGoalsDoNotInventGoalsAndUntouchedLanguageGoalsRemain() {
        var learner=LearnerState();learner.editGoal("Existing Spanish goal")
        let previous=learner.goalIntelligence?["es"]
        learner.completeOnboarding(OnboardingDraft(support:"es",target:"en",learningGoals:["en":" \n ","fr":""]))
        XCTAssertEqual(learner.goal,"");XCTAssertNil(learner.goalIntelligence?["en"]);XCTAssertNil(learner.goalIntelligence?["fr"])
        XCTAssertEqual(learner.goalIntelligence?["es"],previous);XCTAssertEqual(learner.pendingGoalChanges?.count,1);XCTAssertTrue(learner.onboardingComplete)
    }
    func testSourceTextareaLimitUsesUTF16WithoutBreakingEmoji() {
        var draft=OnboardingDraft(support:"en",target:"es")
        draft.goal=String(repeating:"a",count:599)+"😀tail";XCTAssertEqual(draft.goal,String(repeating:"a",count:599))
        draft.goal=String(repeating:"😀",count:301);XCTAssertEqual(draft.goal.utf16.count,600);XCTAssertEqual(draft.goal.count,300)
    }
    func testLateResolvedSupportFollowsAccountUntilLearnerChoosesExplicitly() {
        var draft=OnboardingDraft(support:"en",target:"es");draft.goal="Talk with family"
        draft.resolveSupport("fr");XCTAssertEqual(draft.support,"fr");XCTAssertEqual(draft.target,"es");XCTAssertEqual(draft.goal,"Talk with family")
        draft.chooseSupport("ar");draft.resolveSupport("en");XCTAssertEqual(draft.support,"ar");XCTAssertTrue(draft.pickedSupport)
    }

}
