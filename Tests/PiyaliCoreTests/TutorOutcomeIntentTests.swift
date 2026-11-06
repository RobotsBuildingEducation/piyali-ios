import XCTest
@testable import PiyaliCore
final class TutorOutcomeIntentTests:XCTestCase {
    private func outcome(_ state:LearnerState,xp:Int=5,now:Date=Date())->TutorOutcomeIntent {
        var turn=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:"es",level:"Pre-A1",amount:xp,source:.tutorTurn,contentID:"public-lesson");turn.tutorData = .object(["required":.number(50),"progressRecorded":.bool(true)])
        return .init(turn:turn,target:"es",level:"Pre-A1",date:now,correct:true,independent:true,support:"independent",worthParameters:.object(["question":.object(["tutorPrompt":.string("Say hola.")])]))
    }
    func testPendingWorthProjectsDailyOnlyThenDeliversAccountAwardAndAssessmentExactlyOnce()throws {
        var state=LearnerState();state.target="es";let intent=outcome(state);state.queueTutorOutcome(intent)
        XCTAssertEqual(state.totalXP,0);XCTAssertEqual(state.dailyXP,5);XCTAssertNil(state.gradedByLanguage)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));state=restored
        XCTAssertTrue(state.deliverTutorOutcome(intent.id,worth:nil));XCTAssertFalse(state.deliverTutorOutcome(intent.id,worth:nil))
        XCTAssertEqual(state.totalXP,5);XCTAssertEqual(state.dailyXP,5);XCTAssertEqual(state.gradedByLanguage?["es"],1);XCTAssertEqual(state.pendingChanges?.filter{$0.source == .tutorTurn}.count,1);XCTAssertEqual(state.pendingChanges?.filter{$0.source == .assessment}.first?.id,intent.id)
    }
    func testEarnedDeliveryKeepsItsLanguageWhenTheSelectedTargetChanges() {
        var state=LearnerState();state.target="es";let intent=outcome(state);state.queueTutorOutcome(intent);state.target="fr"
        XCTAssertTrue(state.deliverTutorOutcome(intent.id,worth:nil));XCTAssertEqual(state.target,"fr");XCTAssertEqual(state.xpByLanguage["es"],5);XCTAssertNil(state.xpByLanguage["fr"]);XCTAssertEqual(state.gradedByLanguage?["es"],1);XCTAssertNil(state.gradedByLanguage?["fr"])
    }
    func testAcknowledgmentKeepsPendingDailyProjectionAndHandlesDeliveryDuringTheSave() {
        var current=LearnerState();current.target="es";let intent=outcome(current);current.queueTutorOutcome(intent);let sent=current
        var cloud=sent;cloud.pendingChanges=[]
        var pending=LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(pending.dailyXP,5);XCTAssertEqual(pending.totalXP,0);XCTAssertEqual(pending.pendingTutorOutcomes?.count,1)
        _=current.deliverTutorOutcome(intent.id,worth:nil);pending=LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(pending.dailyXP,5);XCTAssertEqual(pending.totalXP,5);XCTAssertTrue(pending.pendingTutorOutcomes?.isEmpty == true)
    }
    func testCanonicalImportReappliesOnlyPrivatePendingDailyProjection() {
        var state=LearnerState();state.target="es";state.queueTutorOutcome(outcome(state))
        let imported=WebProgressContract.imported(["progress":["targetLang":"es"],"dailyXp":0,"dailyStartedAt":WebProgressContract.iso(Date())],native:state)
        XCTAssertEqual(imported.dailyXP,5);XCTAssertEqual(imported.totalXP,0);XCTAssertNil(imported.gradedByLanguage)
    }
    func testDeferredGlobalTurnDoesNotPayLessonProgressTwice() {
        let now=Date();var state=LearnerState();state.target="es"
        var progress=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:"es",level:"Pre-A1",amount:0,source:.tutorState,contentID:"public-lesson");progress.tutorData = .object(["earnedXp":.number(5),"required":.number(50),"agenda":.object(["hello":.bool(true)])]);state.applySourceTutor(progress)
        let intent=outcome(state);state.queueTutorOutcome(intent);_=state.deliverTutorOutcome(intent.id,worth:nil)
        XCTAssertEqual(state.tutorProgress("public-lesson").earnedXP,5);XCTAssertEqual(state.totalXP,5)
    }
    func testGoalCompanionAndDailyProjectionDoNotDoubleAcrossDeliveryAndAcknowledgment() {
        let now=Date(),today=CalendarDay.key(now);var state=LearnerState();state.target="es";state.dailyGoal=50
        state.companionProgress=JSONValue.foundation(["dailyXp":0,"dailyResetAt":WebProgressContract.iso(now.addingTimeInterval(3600)),"dailyGoalPetHealth":50,"dailyGoalPetLastAccountedDay":CalendarDay.shift(today,by:-1)])
        state.award(45,now:now);let first=outcome(state,now:now);state.queueTutorOutcome(first);let sent=state
        XCTAssertEqual(state.dailyXP,50);XCTAssertEqual(state.totalXP,45);XCTAssertEqual(state.companionHealth,65)
        let second=outcome(state,now:now);state.queueTutorOutcome(second);_=state.deliverTutorOutcome(first.id,worth:nil)
        var cloud=sent;cloud.pendingChanges=[];cloud.acknowledgedEventIDs=Set((sent.pendingChanges ?? []).map(\.id))
        state=LearnerState.rebased(current:state,sent:sent,acknowledged:cloud)
        XCTAssertEqual(state.dailyXP,55);XCTAssertEqual(state.totalXP,50);XCTAssertEqual(state.companionHealth,65);XCTAssertEqual(state.streak,1)
        XCTAssertTrue(state.deliverTutorOutcome(second.id,worth:nil));state.queueTutorOutcome(first);state.queueTutorOutcome(second)
        XCTAssertEqual(state.dailyXP,55);XCTAssertEqual(state.totalXP,55);XCTAssertEqual(state.companionHealth,65);XCTAssertEqual(state.streak,1);XCTAssertTrue(state.pendingTutorOutcomes?.isEmpty == true)
    }

}

extension TutorOutcomeIntentTests {
    func testCanonicalAcknowledgmentRetiresAStaleIntentWithoutProjectingItsDailyAwardAgain()throws {
        let now=Date();var state=LearnerState();state.target="es";let intent=outcome(state,now:now);state.queueTutorOutcome(intent)
        let turn=try XCTUnwrap(intent.turn),fields:[String:Any]=["xp":5,"dailyXp":5,"dailyStartedAt":WebProgressContract.iso(now),"progress":["targetLang":"es","languageXp":["es":5]],"iosRecentEventIDs":[turn.id.uuidString,intent.id.uuidString]]
        let canonical=WebProgressContract.imported(fields,native:state,now:now)
        XCTAssertTrue(canonical.pendingTutorOutcomes?.isEmpty == true);XCTAssertEqual(canonical.dailyXP,5);XCTAssertEqual(canonical.totalXP,5)
        let merged=LearnerState.rebased(current:state,sent:state,acknowledged:canonical)
        XCTAssertTrue(merged.pendingTutorOutcomes?.isEmpty == true);XCTAssertEqual(merged.dailyXP,5);XCTAssertEqual(merged.totalXP,5)
    }
    func testAcknowledgedTurnWithPendingAssessmentOnlyDeliversTheRemainingRating()throws {
        let now=Date();var state=LearnerState();state.target="es";let intent=outcome(state,now:now);state.queueTutorOutcome(intent)
        let turn=try XCTUnwrap(intent.turn),fields:[String:Any]=["xp":5,"dailyXp":5,"dailyStartedAt":WebProgressContract.iso(now),"progress":["targetLang":"es","languageXp":["es":5]],"iosRecentEventIDs":[turn.id.uuidString]]
        state=WebProgressContract.imported(fields,native:state,now:now)
        XCTAssertEqual(state.pendingTutorOutcomes?.count,1);XCTAssertNil(state.pendingTutorOutcomes?.first?.turn);XCTAssertEqual(state.dailyXP,5)
        XCTAssertTrue(state.deliverTutorOutcome(intent.id,worth:nil));XCTAssertEqual(state.totalXP,5);XCTAssertEqual(state.dailyXP,5);XCTAssertEqual(state.gradedByLanguage?["es"],1);XCTAssertEqual(state.pendingChanges?.filter{$0.source == .tutorTurn}.count ?? 0,0)
    }

    func testLateCorrectAwardRemainsIndependentOfAnAlreadyRecordedAssessment() {
        var state=LearnerState();state.target="es";state.assess(correct:false,independent:false,mode:"tutor")
        var intent=outcome(state);intent.recordsAssessment=false;state.queueTutorOutcome(intent)
        XCTAssertEqual(state.totalXP,0);XCTAssertEqual(state.dailyXP,5);XCTAssertTrue(state.deliverTutorOutcome(intent.id,worth:nil));XCTAssertEqual(state.totalXP,5);XCTAssertEqual(state.gradedByLanguage?["es"],1);XCTAssertEqual(state.pendingChanges?.filter{$0.source == .assessment}.count,1)
        state.queueTutorOutcome(intent);XCTAssertEqual(state.dailyXP,5);XCTAssertTrue(state.pendingTutorOutcomes?.isEmpty == true)
        var stale=LearnerState();stale.pendingTutorOutcomes=[intent];stale.reconcileTutorOutcomes(acknowledged:[intent.turn!.id]);XCTAssertTrue(stale.pendingTutorOutcomes?.isEmpty == true)
    }

}
