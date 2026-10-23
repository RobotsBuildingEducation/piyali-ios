import XCTest
@testable import Piyali

@MainActor final class PlateHeadlineControllerTests:XCTestCase {
    private let english=PlateHeadlineScope(account:"fixture-a",target:"es",support:"en",day:"2026-10-23")
    func testNativePromptUsesTheIntroThenNextBundledLessonAndExcludesPrivateGoalAndNotes() throws {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Requires an isolated offline test identity.")}
        let app=AppModel();app.learner=LearnerState();app.learner.goal="PRIVATE_GOAL_SENTINEL";app.learner.notes=[Note(title:"private",body:"PRIVATE_NOTE_SENTINEL")]
        let scope=PlateHeadlineScope(account:"fixture-a",target:"es",support:"en",day:CalendarDay.key(Date()))
        let start=ContinuousClock.now;let first=try app.plateHeadlinePrompt(scope:scope);print("HEADLINE PROMPT BUILD: \(start.duration(to:.now))");XCTAssertTrue(first.contains("learn: Getting Started"));XCTAssertTrue(first.contains("Vocabulary flashcard review"));XCTAssertFalse(first.contains("PRIVATE_"))
        app.learner.completed.insert(app.learner.completionKey(IntroTutorial.lessonID))
        let next=try app.plateHeadlinePrompt(scope:scope);XCTAssertFalse(next.contains("learn: Getting Started"));XCTAssertTrue(next.contains("- learn:"));XCTAssertTrue(next.contains("strictly in English"))
        XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.pendingChanges)
    }
    func testPartialChunksAreCleanedAndOnlyFinalTextIsSaved() async throws {
        let policy=try PlateHeadlinePolicy(),controller=PlateHeadlineController();var saved:[PlateHeadline]=[]
        await controller.load(scope:english,cached:nil,cleared:false,policy:policy,generate:{update in
            XCTAssertTrue(controller.loading);update("\"Ask about");XCTAssertEqual(controller.text,"Ask about");XCTAssertTrue(saved.isEmpty)
            update("\"Ask about plans.\"");return "```text\n\"Ask about plans.\"\n```"
        },save:{saved.append($0)})
        XCTAssertFalse(controller.loading);XCTAssertEqual(controller.text,"Ask about plans.");XCTAssertEqual(saved,[.init(dayKey:english.day,appLanguage:"en",text:"Ask about plans.")])
    }
    func testOldStreamsCannotReplaceNewLanguageAccountOrDay() async throws {
        let policy=try PlateHeadlinePolicy()
        for newer in [PlateHeadlineScope(account:"fixture-a",target:"es",support:"fr",day:english.day),.init(account:"fixture-b",target:"es",support:"en",day:english.day),.init(account:"fixture-a",target:"fr",support:"en",day:english.day),.init(account:"fixture-a",target:"es",support:"en",day:"2026-10-24")] {
            let controller=PlateHeadlineController();var held:CheckedContinuation<String,Error>?,oldUpdate:((String)->Void)?,saved:[PlateHeadline]=[]
            let old=Task{await controller.load(scope:english,cached:nil,cleared:false,policy:policy,generate:{update in oldUpdate=update;return try await withCheckedThrowingContinuation{held=$0}},save:{saved.append($0)})}
            for _ in 0..<20 where held == nil {await Task.yield()};XCTAssertNotNil(held)
            await controller.load(scope:newer,cached:nil,cleared:false,policy:policy,generate:{update in update("New scope");return "New scope"},save:{saved.append($0)})
            oldUpdate?("Late old chunk");held?.resume(returning:"Late old result");await old.value
            XCTAssertEqual(controller.scope,newer);XCTAssertEqual(controller.text,"New scope");XCTAssertEqual(saved.count,1);XCTAssertEqual(saved.first?.appLanguage,newer.support)
        }
    }
    func testCachedClearedAndUnavailablePolicyDoNotGenerateAndFailureKeepsPartialText() async throws {
        let policy=try PlateHeadlinePolicy(),controller=PlateHeadlineController();var calls=0
        for (cache,cleared,p) in [("Saved sentence" as String?,false,policy as PlateHeadlinePolicy?),(nil,true,policy),(nil,false,nil)] {
            await controller.load(scope:english,cached:cache,cleared:cleared,policy:p,generate:{_ in calls += 1;return "Unexpected"},save:{_ in XCTFail("No new headline should be saved")})
            XCTAssertFalse(controller.loading)
        }
        XCTAssertEqual(calls,0)
        await controller.load(scope:english,cached:nil,cleared:false,policy:policy,generate:{update in update("Useful partial");throw CancellationError()},save:{_ in XCTFail("A partial failed response is not a cached final sentence")})
        XCTAssertFalse(controller.loading);XCTAssertEqual(controller.text,"Useful partial")
    }
    func testLeavingTheHomeInvalidatesPendingCallbacksAndSaving() async throws {
        let policy=try PlateHeadlinePolicy(),controller=PlateHeadlineController();var held:CheckedContinuation<String,Error>?,update:((String)->Void)?,saved=false
        let task=Task{await controller.load(scope:english,cached:nil,cleared:false,policy:policy,generate:{callback in update=callback;return try await withCheckedThrowingContinuation{held=$0}},save:{_ in saved=true})}
        for _ in 0..<20 where held == nil {await Task.yield()};XCTAssertNotNil(held);controller.cancel();task.cancel();update?("Late text");held?.resume(returning:"Late result");await task.value
        XCTAssertFalse(saved);XCTAssertFalse(controller.loading);XCTAssertEqual(controller.text,"")
    }
}
