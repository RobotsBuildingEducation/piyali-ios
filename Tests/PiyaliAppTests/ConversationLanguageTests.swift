import XCTest
@testable import Piyali

@MainActor private final class ConversationProviderFixture:ConversationProviding {
    var suspendedGoals:Set<String>=[]
    var goals:[String:CheckedContinuation<ConversationGoal,Error>]=[:]
    var goalStarted:[String:XCTestExpectation]=[:]
    var translation:CheckedContinuation<String,Error>?
    var translationStarted:XCTestExpectation?
    var starter:CheckedContinuation<JSONValue,Error>?
    var starterStarted:XCTestExpectation?
    var verdict:CheckedContinuation<ConversationVerdict,Error>?
    var verdictStarted:XCTestExpectation?
    var translates=0
    func result(_ support:String)->ConversationGoal { .init(text:JSONValue.object(["en":.string("Goal in "+support)]).setting(support,.string("Goal in "+support)),questionLevel:"Pre-A1",worth:.null) }
    func conversationGoal(learner:LearnerState,draft:ConversationDraft,topics:[String],abandoned:Bool,contextual:Bool?) async throws ->ConversationGoal {
        if suspendedGoals.contains(learner.support) { return try await withCheckedThrowingContinuation { goals[learner.support]=$0;goalStarted[learner.support]?.fulfill() } }
        return result(learner.support)
    }
    func conversationTranslation(_ text:String,support:String) async throws ->String { translates += 1;return try await withCheckedThrowingContinuation { translation=$0;translationStarted?.fulfill() } }
    func conversationStarterPhrase(learner:LearnerState,draft:ConversationDraft) async throws ->JSONValue { try await withCheckedThrowingContinuation { starter=$0;starterStarted?.fulfill() } }
    func conversationVerdict(goal:ConversationGoal,learner:LearnerState,reply:String,answeredLine:String) async throws ->ConversationVerdict { try await withCheckedThrowingContinuation { verdict=$0;verdictStarted?.fulfill() } }
}

@MainActor final class ConversationLanguageServiceTests:XCTestCase {
    private func app() throws ->AppModel {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",ProcessInfo.processInfo.environment["PIYALI_CONVERSATION_FIXTURE"] != "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Isolated offline identity and injected providers required.") }
        let app=AppModel();try app.identity.create();app.subscription.bind(app.identity);app.learner.target="es";app.learner.support="en";app.learner.xpByLanguage=["es":5]
        var draft=ConversationDraft();var goal=ConversationGoal(text:.object(["en":.string("Say hello")]),questionLevel:"Pre-A1",worth:.null);goal.supportLang="en";draft.goal=goal;draft.turns=2;draft.goalsCompleted=1;draft.earnedXP=5;draft.seenTurnIDs=[UUID()];draft.append(.init(role:"assistant",text:"¡Hola!",providerID:"r0"));app.learner.saveConversation(draft)
        return app
    }
    func testLatestLanguageGoalSupersedesBusyGenerationWithoutWaitingForItsOldResult() async throws {
        let app=try app();defer {try? app.identity.disconnect()};var draft=app.learner.conversation;draft.goal=nil;app.learner.saveConversation(draft)
        let provider=ConversationProviderFixture();provider.suspendedGoals=["en","fr"];provider.goalStarted["en"]=expectation(description:"English topic pending");provider.goalStarted["fr"]=expectation(description:"French topic pending")
        let service=ConversationService(provider:provider),old=Task {await service.prepare(app)}
        await fulfillment(of:[provider.goalStarted["en"]!],timeout:2)
        app.learner.support="fr";let current=Task {await service.prepare(app)}
        await fulfillment(of:[provider.goalStarted["fr"]!],timeout:2)
        provider.goals.removeValue(forKey:"en")?.resume(returning:provider.result("en"));await old.value
        XCTAssertTrue(service.busy);XCTAssertNil(app.learner.conversation.goal)
        provider.goals.removeValue(forKey:"fr")?.resume(returning:provider.result("fr"));await current.value
        XCTAssertEqual(app.learner.conversation.goal?.supportLang,"fr");XCTAssertEqual(app.learner.conversation.goal?.text["fr"].string,"Goal in fr");XCTAssertEqual(app.learner.conversation.messages.count,1);XCTAssertEqual(app.learner.totalXP,5);XCTAssertFalse(service.busy)
    }
    func testLateTranslationCannotReplaceTheNewLanguagesMessageAndSameLanguageNeedsNoProvider() async throws {
        let app=try app();defer {try? app.identity.disconnect()};let provider=ConversationProviderFixture();provider.translationStarted=expectation(description:"English translation pending");let service=ConversationService(provider:provider),message=try XCTUnwrap(app.learner.conversation.messages.first)
        let old=Task {await service.translate(message,app:app)};await fulfillment(of:[provider.translationStarted!],timeout:2)
        app.learner.support="fr";await service.prepare(app)
        provider.translation?.resume(returning:"Old English answer");provider.translation=nil;await old.value
        XCTAssertNil(app.learner.conversation.messages.first?.translation(for:"fr"));XCTAssertNil(service.error)
        app.learner.support="es";await service.prepare(app);await service.translate(message,app:app)
        XCTAssertEqual(app.learner.conversation.messages.first?.translation(for:"es"),"¡Hola!");XCTAssertEqual(provider.translates,1);XCTAssertEqual(app.learner.totalXP,5)
    }
    func testLateStarterAndVerdictCannotChangeTheNewGoalOrLearningReceipts() async throws {
        let app=try app();defer {try? app.identity.disconnect()};let provider=ConversationProviderFixture();provider.starterStarted=expectation(description:"Old starter pending");let service=ConversationService(provider:provider)
        let old=Task {await service.starter(app)};await fulfillment(of:[provider.starterStarted!],timeout:2)
        app.learner.support="fr";await service.prepare(app);let goalID=app.learner.conversation.goal?.id
        provider.starter?.resume(returning:.object(["target":.string("Hola"),"support":.string("Old English")]));provider.starter=nil;await old.value
        XCTAssertEqual(app.learner.conversation.goal?.id,goalID);XCTAssertNil(app.learner.conversation.goal?.starter)
        provider.verdictStarted=expectation(description:"French verdict pending");let receipts=app.learner.conversation.seenTurnIDs,rating=app.learner.rating
        let grade=Task {await service.voiceTurn("Hola, soy Ana.",answered:"¡Hola!",reply:"",id:UUID(),app:app,providerID:"u1")};await fulfillment(of:[provider.verdictStarted!],timeout:2)
        app.learner.support="es";await service.prepare(app)
        provider.verdict?.resume(returning:.init(completed:true,reason:"Old-language result"));provider.verdict=nil;await grade.value
        XCTAssertEqual(app.learner.conversation.goal?.supportLang,"es");XCTAssertEqual(app.learner.totalXP,5);XCTAssertEqual(app.learner.rating,rating);XCTAssertEqual(app.learner.conversation.turns,2);XCTAssertEqual(app.learner.conversation.seenTurnIDs,receipts);XCTAssertNil(service.error)
    }
}

extension ConversationLanguageServiceTests {
    func testStaleTranslationErrorIsHiddenEvenBeforeAReplacementRequestStarts() async throws {
        let app=try app();defer {try? app.identity.disconnect()};let provider=ConversationProviderFixture();provider.translationStarted=expectation(description:"Translation pending");let service=ConversationService(provider:provider),message=try XCTUnwrap(app.learner.conversation.messages.first)
        let request=Task {await service.translate(message,app:app)};await fulfillment(of:[provider.translationStarted!],timeout:2)
        app.learner.support="fr";provider.translation?.resume(throwing:AppError.message("Old English failure"));provider.translation=nil;await request.value
        XCTAssertNil(service.error);XCTAssertFalse(service.busy);await service.prepare(app);XCTAssertEqual(app.learner.conversation.goal?.supportLang,"fr")
    }
    func testReturningToACompletedGoalCreatesTheNextGoalWithoutAnotherReward() async throws {
        let app=try app();defer {try? app.identity.disconnect()};var draft=app.learner.conversation;draft.goal?.completed=true;app.learner.saveConversation(draft);let previous=draft.goal?.id,provider=ConversationProviderFixture(),service=ConversationService(provider:provider)
        await service.prepare(app)
        XCTAssertNotEqual(app.learner.conversation.goal?.id,previous);XCTAssertEqual(app.learner.conversation.goal?.supportLang,"en");XCTAssertEqual(app.learner.totalXP,5);XCTAssertEqual(app.learner.conversation.turns,2);XCTAssertEqual(app.learner.conversation.earnedXP,5)
    }
}

extension ConversationLanguageServiceTests {
    func testSpeechStillGetsAssessedWhileATranslationIsPendingAndBusyTracksBothJobs() async throws {
        let app=try app();defer {try? app.identity.disconnect()};let provider=ConversationProviderFixture();provider.translationStarted=expectation(description:"Translation pending");provider.verdictStarted=expectation(description:"Speech assessed independently");let service=ConversationService(provider:provider),message=try XCTUnwrap(app.learner.conversation.messages.first)
        let translation=Task {await service.translate(message,app:app)};await fulfillment(of:[provider.translationStarted!],timeout:2)
        let grade=Task {await service.voiceTurn("wrong topic",answered:"¡Hola!",reply:"",id:UUID(),app:app,providerID:"u-overlap")};await fulfillment(of:[provider.verdictStarted!],timeout:2)
        provider.verdict?.resume(returning:.init(completed:false,reason:"Try the goal",goalStillFits:true));provider.verdict=nil;await grade.value
        XCTAssertTrue(service.busy);XCTAssertEqual(app.learner.totalXP,5);XCTAssertEqual(app.learner.conversation.goal?.misses,1);XCTAssertEqual(app.learner.conversation.turns,3)
        provider.translation?.resume(returning:"Hello");provider.translation=nil;await translation.value
        XCTAssertFalse(service.busy);XCTAssertEqual(app.learner.conversation.messages.first?.translation(for:"en"),"Hello")
    }
}

extension ConversationLanguageServiceTests {
    func testContinuedSpeechWhileTheSuccessorGoalIsPendingDoesNotStartDuplicateGoalRequests() async throws {
        let app=try app();defer {try? app.identity.disconnect()};let provider=ConversationProviderFixture();provider.verdictStarted=expectation(description:"First turn assessed");provider.suspendedGoals=["en"];provider.goalStarted["en"]=expectation(description:"One successor goal pending");let service=ConversationService(provider:provider)
        let first=Task {await service.voiceTurn("Hola, soy Ana.",answered:"¡Hola!",reply:"",id:UUID(),app:app,providerID:"u-first")};await fulfillment(of:[provider.verdictStarted!],timeout:2)
        provider.verdict?.resume(returning:.init(completed:true,reason:"Good"));provider.verdict=nil;await fulfillment(of:[provider.goalStarted["en"]!],timeout:4)
        await service.voiceTurn("Me gusta cocinar.",answered:"¿Qué te gusta?",reply:"",id:UUID(),app:app,providerID:"u-next")
        XCTAssertEqual(provider.goals.count,1);XCTAssertTrue(service.busy);XCTAssertEqual(app.learner.conversation.goalsCompleted,2);XCTAssertEqual(app.learner.conversation.turns,4);let xp=app.learner.totalXP
        provider.goals.removeValue(forKey:"en")?.resume(returning:provider.result("en"));await first.value
        XCTAssertFalse(service.busy);XCTAssertEqual(app.learner.totalXP,xp);XCTAssertEqual(app.learner.conversation.goalsCompleted,2)
    }
}
