import XCTest
@testable import PiyaliCore

final class ConversationTests: XCTestCase {
    private func learner() -> LearnerState {
        var state=LearnerState();var draft=ConversationDraft()
        draft.goal=ConversationGoal(text:.object(["en":.string("Say hello and your name")]),questionLevel:"Pre-A1",worth:ConversationPractice.worth(rating:800,level:"Pre-A1"))
        state.saveConversation(draft);return state
    }
    private func compare(_ actual: JSONValue,_ expected: JSONValue, file: StaticString = #filePath,line: UInt = #line) {
        switch (actual,expected) {
        case (.number(let a),.number(let b)):XCTAssertEqual(a,b,accuracy:1e-10,file:file,line:line)
        case (.object(let a),.object(let b)):XCTAssertEqual(Set(a.keys),Set(b.keys),file:file,line:line);for (k,v) in b { compare(a[k] ?? .null,v,file:file,line:line) }
        case (.array(let a),.array(let b)):XCTAssertEqual(a.count,b.count,file:file,line:line);for (a,b) in zip(a,b) { compare(a,b,file:file,line:line) }
        default:XCTAssertEqual(actual,expected,file:file,line:line)
        }
    }
    func testQuotesAndGradingMatchActualWebFunctions() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/conversation.json")
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
        for sample in fixture["worth"].array {
            let difficulty:Double?;if case .number(let value)=sample["difficulty"] { difficulty=value } else { difficulty=nil }
            compare(ConversationPractice.worth(rating:sample["rating"].number,level:sample["level"].string,difficulty:difficulty),sample["expected"])
        }
        for sample in fixture["graded"].array {
            let event=sample["event"]
            var change=PracticeChange(date:WebProgressContract.date("2026-10-13T12:00:00.000Z")!,dayKey:"2026-10-13",target:"es",level:event["questionLevel"].string,amount:0,source:.conversation)
            change.id=UUID(uuidString:event["id"].string)!;change.correct=event["success"].boolean;change.conversationWorth=event["worth"];change.conversationGoalText = .object(["en":event["concept"]])
            let result=ConversationPractice.gradedBucket(sample["bucket"].foundation,change:change)
            compare(.foundation(result),sample["expected"])
            compare(.foundation(ConversationPractice.gradedBucket(result,change:change)),sample["expected"])
        }
    }
    func testSuccessGivesTurnAndGoalXPOnceWithoutDoubleCountingQuestActivity() {
        var state=learner();let id=UUID(),verdict=ConversationVerdict(completed:true,reason:"Great")
        XCTAssertEqual(state.conversationTurn(id:id,answer:"Hola, me llamo Ana.",verdict:verdict,turnXP:2,goalXP:3),5)
        XCTAssertEqual(state.conversationTurn(id:id,answer:"Hola, me llamo Ana.",verdict:verdict,turnXP:2,goalXP:3),0)
        XCTAssertEqual(state.totalXP,5);XCTAssertEqual(state.conversation.goalsCompleted,1);XCTAssertEqual(state.conversation.turns,1);XCTAssertEqual(state.gradedByLanguage?["es"],1)
        XCTAssertEqual(state.pendingChanges?.count,1);XCTAssertEqual(state.pendingChanges?.first?.earnedAmount,5)
        XCTAssertEqual(state.plateProgress["conversationDailyActivity"]["es"][CalendarDay.key(Date())].number,1)
        XCTAssertEqual(state.completedConversationGoals?.count,1)
    }
    func testMissesAndDriftGetNoXPAndOnlyMissesAffectScore() {
        var state=learner()
        XCTAssertEqual(state.conversationTurn(id:UUID(),answer:"wrong words",verdict:.init(completed:false,reason:"Try your name"),turnXP:3,goalXP:4),0)
        XCTAssertFalse(ConversationPractice.nextGoal(state.conversation.goal!));XCTAssertEqual(state.gradedByLanguage?["es"],1)
        _=state.conversationTurn(id:UUID(),answer:"wrong again",verdict:.init(completed:false,reason:"Try your name"),turnXP:3,goalXP:4)
        XCTAssertTrue(ConversationPractice.nextGoal(state.conversation.goal!));XCTAssertEqual(state.gradedByLanguage?["es"],2)
        var drift=learner();_=drift.conversationTurn(id:UUID(),answer:"I don't watch TV",verdict:.init(completed:false,reason:"New direction",goalStillFits:false),turnXP:3,goalXP:4)
        XCTAssertTrue(ConversationPractice.nextGoal(drift.conversation.goal!));XCTAssertNil(drift.gradedByLanguage?["es"]);XCTAssertEqual(drift.totalXP,0)
        XCTAssertTrue(drift.activeMemories.isEmpty)
    }
    func testShortOrUnavailableVerdictIsNeutralPractice() {
        var state=learner();_=state.conversationTurn(id:UUID(),answer:"Sí",verdict:.init(completed:true,reason:"Not gradable"),turnXP:2,goalXP:4)
        _=state.conversationTurn(id:UUID(),answer:"A useful reply",verdict:nil,turnXP:3,goalXP:4)
        XCTAssertEqual(state.totalXP,5);XCTAssertEqual(state.conversation.goalsCompleted,0);XCTAssertNil(state.gradedByLanguage?["es"])
    }
    func testCompletionIDIsStableAcrossDraftPersistenceAndScopedToLanguage() throws {
        let state=learner(),goal=state.conversation.goal!
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(ConversationPractice.completionID(target:"es",goal:goal),ConversationPractice.completionID(target:"es",goal:restored.conversation.goal!))
        XCTAssertNotEqual(ConversationPractice.completionID(target:"fr",goal:goal),ConversationPractice.completionID(target:"es",goal:goal))
        XCTAssertNil(ConversationPractice.completionID(target:"es",goal:ConversationGoal(text:.object([:]),questionLevel:"A1",worth:.null)))
    }
    func testInFlightCompletionSurvivesAcknowledgmentAndDuplicateGoalBonusIsNotReplayed() {
        let sent=learner();var current=sent
        _=current.conversationTurn(id:UUID(),answer:"Me llamo Ana.",verdict:.init(completed:true,reason:"Good"),turnXP:2,goalXP:3)
        let rebased=LearnerState.rebased(current:current,sent:sent,acknowledged:sent)
        XCTAssertEqual(rebased.totalXP,5);XCTAssertEqual(rebased.pendingChanges?.count,1)
        var cloud=sent;cloud.completedConversationGoals=current.completedConversationGoals;cloud.xpByLanguage["es"]=3
        let duplicate=LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(duplicate.totalXP,5)
    }
    func testBoundedDraftKeepsLatestMessagesAndPerLanguageSettings() throws {
        var state=learner(),draft=state.conversation;draft.interests="Cooking";draft.personality="Warm and direct"
        for index in 0..<60 { draft.append(.init(role:index%2 == 0 ? "user" : "assistant",text:String(repeating:"日",count:2000)+String(index))) }
        XCTAssertLessThanOrEqual(try JSONEncoder().encode(draft).count,24_000);XCTAssertFalse(draft.messages.isEmpty)
        state.saveConversation(draft);state.target="fr";XCTAssertTrue(state.conversation.interests.isEmpty);state.target="es";XCTAssertEqual(state.conversation.personality,"Warm and direct")
    }
    func testVoiceInterruptionKeepsTheSpokenPromptAndSeparatesTheNewReply() {
        var context=ConversationVoiceContext()
        context.appendAssistant("¿Cómo te llamas?");_=context.finish()
        context.appendAssistant("Dime tu nombre, por favor.");context.inputStarted();context.interrupted()
        context.appendAssistant("Gracias, Ana. ¿Qué te gusta?")
        let turn=context.finish()
        XCTAssertEqual(turn.answered,"Dime tu nombre, por favor.")
        XCTAssertEqual(turn.reply,"Gracias, Ana. ¿Qué te gusta?")
        context.inputStarted();context.appendAssistant("Me gusta cocinar también.")
        XCTAssertEqual(context.finish().answered,"Gracias, Ana. ¿Qué te gusta?")
    }
    func testVoiceGoalCheckUsesTheAnsweredLineRatherThanTheNewTutorReply() {
        var context=ConversationVoiceContext()
        context.appendAssistant("¿Cómo te llamas?");_=context.finish()
        context.inputStarted();context.appendAssistant("Encantada. ¿Qué ");context.appendAssistant("te gusta?")
        let first=context.finish()
        XCTAssertEqual(first.answered,"¿Cómo te llamas?");XCTAssertEqual(first.reply,"Encantada. ¿Qué te gusta?")
        context.inputStarted();context.appendAssistant("¡Buena elección!")
        XCTAssertEqual(context.finish().answered,"Encantada. ¿Qué te gusta?")
    }
}
