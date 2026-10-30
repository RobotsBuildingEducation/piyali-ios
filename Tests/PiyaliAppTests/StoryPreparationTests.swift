import XCTest
@testable import Piyali

@MainActor final class StoryPreparationTests:XCTestCase {
    private func model()throws->AppModel {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,StoryService.fixtureMode == nil else { throw XCTSkip("Isolated offline identity without a story fixture required.") }
        let app=AppModel();try app.identity.create();app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.target="es";app.learner.support="en";return app
    }
    private func cached()throws->StoryRun {
        let payload:JSONValue = .object(["title":.string("Old completed story"),"sentences":.array([.object(["speaker":.string("Sheilfer"),"target":.string("Hola.")]),.object(["speaker":.string("You"),"target":.string("Buenos días.")])])])
        var run=try StoryRun(payload:payload,mode:.speaking,target:"es",support:"en",level:"Pre-A1",lessonID:nil,worth:.null,tutorial:true);run.index=run.count;run.completed=true;return run
    }
    func testFreshFailureCannotExposeCachedCompletionAsPrepared() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let old=try cached();app.learner.saveStory(old)
        let service=StoryService(writer:{ _ in throw AppError.message("Temporary generation failure") })
        let prepared=await service.prepare(app,lesson:nil,mode:.speaking,fresh:true)
        XCTAssertFalse(prepared);XCTAssertNil(service.activeRunID);XCTAssertNotNil(service.error)
        XCTAssertEqual(app.learner.story?.id,old.id,"Keep the saved attempt available without presenting it as new content")
        XCTAssertEqual(app.learner.totalXP,0)
    }
    func testResumeMarksOnlyValidatedSavedRunWithoutGeneratingAnother() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let old=try cached();app.learner.saveStory(old)
        let service=StoryService(writer:{ _ in XCTFail("A valid saved run should resume");throw StoryFailure.invalid })
        let prepared=await service.prepare(app,lesson:nil,mode:.speaking,fresh:false)
        XCTAssertTrue(prepared);XCTAssertEqual(service.activeRunID,old.id);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testLegacyCacheCannotResumeAtAnotherAuthoredLevel() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let old=try cached();app.learner.saveStory(old);app.learner.level="B2"
        var requested=false
        let service=StoryService(writer:{ _ in requested=true;throw StoryFailure.invalid })
        let prepared=await service.prepare(app,lesson:nil,mode:.speaking,fresh:false)
        XCTAssertTrue(requested);XCTAssertFalse(prepared);XCTAssertNil(service.activeRunID);XCTAssertEqual(app.learner.story?.id,old.id);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testLateWriterAfterCancelCannotReplaceTheSavedRunOrBecomeActive() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let old=try cached();app.learner.saveStory(old)
        var release:CheckedContinuation<JSONValue,Error>?,writerWasCancelled=false
        let service=StoryService(writer:{ _ in let result=try await withCheckedThrowingContinuation { release=$0 };writerWasCancelled=Task.isCancelled;return result })
        let work=Task { await service.prepare(app,lesson:nil,mode:.speaking,fresh:true) }
        for _ in 0..<30 { if release != nil { break };await Task.yield() }
        XCTAssertNotNil(release);service.cancel();release?.resume(returning:.null)
        let prepared=await work.value;XCTAssertFalse(prepared);XCTAssertTrue(writerWasCancelled);XCTAssertNil(service.activeRunID);XCTAssertEqual(app.learner.story?.id,old.id);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testResumingCacheSupersedesAnOlderInFlightRegeneration() async throws {
        let app=try model();defer { try? app.identity.disconnect() };let old=try cached();app.learner.saveStory(old)
        var release:CheckedContinuation<JSONValue,Error>?
        let service=StoryService(writer:{ _ in try await withCheckedThrowingContinuation { release=$0 } })
        let work=Task { await service.prepare(app,lesson:nil,mode:.speaking,fresh:true) }
        for _ in 0..<30 { if release != nil { break };await Task.yield() }
        XCTAssertNotNil(release)
        let resumed=await service.prepare(app,lesson:nil,mode:.speaking,fresh:false)
        XCTAssertTrue(resumed);release?.resume(returning:.null)
        let stale=await work.value;XCTAssertFalse(stale);XCTAssertEqual(service.activeRunID,old.id);XCTAssertEqual(app.learner.story?.id,old.id)
    }

}
