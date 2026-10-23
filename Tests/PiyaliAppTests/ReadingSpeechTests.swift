import XCTest
@testable import Piyali

@MainActor final class ReadingSpeechTests:XCTestCase {
    private func model()throws->AppModel {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("An isolated offline identity is required.") }
        let app=AppModel();try app.identity.create();app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.target="es";app.learner.support="en"
        var run=try ReadingRun(payload:ContentLibrary.load(JSONValue.self,name:"reading-test-passage"),target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:.null,roll:0.7);run.method="speech";app.learner.saveReading(run);return app
    }
    func testLowScoresCompletePracticeOnceAndPersistAllSixCards() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let run=try XCTUnwrap(app.learner.reading),rating=app.learner.rating
        let feedback=try XCTUnwrap(ReadingSpeechFeedback(try ContentLibrary.load(JSONValue.self,name:"reading-test-passage")["speechFeedback"]))
        let service=ReadingService(speechGrader:{ _,words in XCTAssertEqual(words,"short opening");return feedback })
        await service.check(app,run:run,answer:"short opening",speech:true)
        await service.check(app,run:run,answer:"duplicate",speech:true)
        XCTAssertTrue(app.learner.reading?.awarded == true);XCTAssertEqual(app.learner.reading?.speechFeedback,feedback);XCTAssertEqual(feedback.scores.count,6)
        XCTAssertEqual(app.learner.totalXP,7);XCTAssertEqual(app.learner.rating,rating);XCTAssertNil(app.learner.gradedByLanguage?["es"]);XCTAssertNil(service.error)
    }
    func testProviderFailureStillCompletesPracticeWithoutFabricatedScores() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let run=try XCTUnwrap(app.learner.reading)
        let service=ReadingService(speechGrader:{ _,_ in throw ReadingFailure.invalid })
        await service.check(app,run:run,answer:"recognized fragment",speech:true)
        XCTAssertEqual(app.learner.reading?.speechFeedback,.unavailable(support:"en"));XCTAssertEqual(app.learner.totalXP,7);XCTAssertEqual(app.learner.reading?.correct,true);XCTAssertNil(service.error)
    }
    func testCancelledLateGraderCannotAwardOrReplaceSavedFeedback() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let run=try XCTUnwrap(app.learner.reading)
        var release:CheckedContinuation<ReadingSpeechFeedback,Error>?,cancelled=false
        let service=ReadingService(speechGrader:{ _,_ in let result=try await withCheckedThrowingContinuation { release=$0 };cancelled=Task.isCancelled;return result })
        let task=Task { await service.check(app,run:run,answer:"opening",speech:true) }
        for _ in 0..<30 { if release != nil { break };await Task.yield() }
        XCTAssertNotNil(release);service.cancel();release?.resume(returning:.unavailable(support:"en"));await task.value
        XCTAssertTrue(cancelled);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.reading?.speechFeedback);XCTAssertFalse(service.busy)
    }
    func testLanguageSwitchDiscardsLateFeedbackAndReward() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let run=try XCTUnwrap(app.learner.reading)
        var release:CheckedContinuation<ReadingSpeechFeedback,Error>?
        let service=ReadingService(speechGrader:{ _,_ in try await withCheckedThrowingContinuation { release=$0 } })
        let task=Task { await service.check(app,run:run,answer:"opening",speech:true) }
        for _ in 0..<30 { if release != nil { break };await Task.yield() }
        XCTAssertNotNil(release);app.learner.support="es";release?.resume(returning:.unavailable(support:"en"));await task.value
        XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.reading?.speechFeedback)
    }
}
