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
    func testProvisionalEpisodePromotesOnlyMatchingQuestionsAndTurns() throws {
        let payload=try ContentLibrary.load(JSONValue.self,name:"story-test-episode")
        let complete=try StoryRun(payload:payload,mode:.radio,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null)
        let episode=try XCTUnwrap(complete.episode)
        var partial=StoryRun(provisionalID:UUID(),episode:.init(title:episode.title,segments:[episode.segments[0]]),ready:[0],mode:.radio,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null)
        partial.heard=[0];partial.answers=["0":[1]];partial.results=["0":false];partial.index=1
        var matching=complete;XCTAssertTrue(StoryService.promoteEpisode(partial,into:&matching));XCTAssertEqual(matching.id,partial.id);XCTAssertEqual(matching.index,1);XCTAssertEqual(matching.answers,partial.answers);XCTAssertEqual(matching.results,partial.results);XCTAssertEqual(matching.heard,partial.heard)
        var changed=partial;changed.episode!.segments[0].turns[0] = .init(speaker:"Ana",target:"Changed")
        var rejected=complete;XCTAssertFalse(StoryService.promoteEpisode(changed,into:&rejected));XCTAssertEqual(rejected.id,complete.id);XCTAssertTrue(rejected.results.isEmpty)
        changed=partial;changed.episode!.segments[0].question.options.swapAt(0,1)
        XCTAssertFalse(StoryService.promoteEpisode(changed,into:&rejected));XCTAssertEqual(rejected.id,complete.id);XCTAssertTrue(rejected.results.isEmpty)
    }
    func testSourceProviderBoundaryRetainsCompletedAndInterruptedOneLine() async throws {
        let app=try model();defer {try? app.identity.disconnect()};let line="{\"type\":\"sentence\",\"tgt\":\"Hola.\"}\n"
        for interrupted in [false,true] {
            let ai=AIService();var snapshots:[String]=[]
            ai.storyStreamOverride={_,onChunk in onChunk(line);if interrupted {throw AppError.message("Public test stream interruption")};return line}
            var state=LearnerState();state.target="es";state.support="en";state.level="A1"
            let payload=try await ai.storyPayload(mode:.speaking,lesson:nil,state:state,level:"A1",tutorial:true,recent:[],repair:false,onSpeakingChunk:{snapshots.append($0)})
            XCTAssertEqual(payload["nativeSpeakingStream"].string,interrupted ? "interrupted":"completed");XCTAssertEqual(payload["sentences"].array.map{$0["target"].string},["Hola."]);XCTAssertFalse(snapshots.contains(""));XCTAssertEqual(payload["nativePlan"] == .null,interrupted)
        }
    }
    func testSourceProviderBeforeRevealUsesBatchFallback() async throws {
        let app=try model();defer {try? app.identity.disconnect()};let ai=AIService();var fallbackCalls=0,snapshots:[String]=[]
        ai.storyStreamOverride={_,onChunk in onChunk("{\"type\":\"sentence\",\"tgt\":\"unfinished");throw AppError.message("Public test stream interruption")}
        ai.storyBatchOverride={_,_ in fallbackCalls += 1;return ["{\"type\":\"sentence\",\"character\":\"Sheilfer\",\"tgt\":\"Hola.\"}","{\"type\":\"sentence\",\"character\":\"You\",\"tgt\":\"Buenos días.\"}","{\"type\":\"done\"}"].joined(separator:"\n")}
        let payload=try await ai.storyPayload(mode:.speaking,lesson:nil,state:app.learner,level:"A1",tutorial:true,recent:[],repair:false,onSpeakingChunk:{snapshots.append($0)})
        XCTAssertEqual(fallbackCalls,1);XCTAssertEqual(payload["nativeSpeakingStream"],.null);XCTAssertEqual(payload["sentences"].array.count,2);XCTAssertEqual(snapshots.last,"")
    }
    func testCancelledSourceProviderNeverPromotesPartialOrUsesFallback() async throws {
        let app=try model();defer {try? app.identity.disconnect()};let ai=AIService();var fallbackCalls=0,started=false
        ai.storyStreamOverride={_,onChunk in onChunk("{\"type\":\"sentence\",\"tgt\":\"Hola.\"}\n");started=true;try await Task.sleep(for:.seconds(30));return ""}
        ai.storyBatchOverride={_,_ in fallbackCalls += 1;return ""}
        let work=Task {try await ai.storyPayload(mode:.speaking,lesson:nil,state:app.learner,level:"A1",tutorial:true,recent:[],repair:false)}
        for _ in 0..<500 where !started {try await Task.sleep(for:.milliseconds(2))};XCTAssertTrue(started);work.cancel()
        do {_ = try await work.value;XCTFail("Cancellation must not promote or regenerate a partial story")} catch is CancellationError {} catch {XCTFail("Unexpected error: \(error)")}
        XCTAssertEqual(fallbackCalls,0);XCTAssertNil(app.learner.story);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testInterruptedSourceStreamPreparesOneLineWithoutAssessmentOrDuplicateReward() async throws {
        let app=try model();defer {try? app.identity.disconnect()}
        let payload=try XCTUnwrap(StoryStreamDraft.speakingPayload("{\"type\":\"sentence\",\"tgt\":\"Hola.\"}\n",completed:false,title:"Practice"))
        let service=StoryService(writer:{ _ in payload });let prepared=await service.prepare(app,lesson:nil,mode:.speaking,fresh:true)
        XCTAssertTrue(prepared);let run=try XCTUnwrap(app.learner.story);XCTAssertEqual(service.activeRunID,run.id);XCTAssertEqual(run.sentences.map(\.target),["Hola."]);XCTAssertNil(run.sentenceWorths);XCTAssertTrue(app.learner.storyHistory?.isEmpty ?? true)
        XCTAssertEqual(app.learner.practiceStoryLine(words:"Hola.",confidence:0.9),2);XCTAssertEqual(app.learner.practiceStoryLine(words:"Hola.",confidence:0.9),0)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner));XCTAssertEqual(restored.totalXP,2);XCTAssertEqual(restored.story?.passedLines,[0])
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
