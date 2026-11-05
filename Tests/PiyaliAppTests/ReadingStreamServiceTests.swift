import XCTest
@testable import Piyali

@MainActor final class ReadingStreamServiceTests:XCTestCase {
    private func model() throws -> AppModel {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_READING_FIXTURE"] == "1",env["PIYALI_READING_STREAM_FIXTURE"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated streaming fixture required")}
        let app=AppModel();try app.identity.create();app.learner=LearnerState();app.learner.target="es";app.learner.support="en";return app
    }
    func testProviderBoundaryAcceptsNormalPartialStreamAndLeavesQuestionPending() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let ai=AIService(),snapshot="{\"type\":\"target\",\"text\":\"La flor crece.\"}\n";var observed:[String]=[]
        ai.readingStreamOverride={_,onChunk in onChunk(snapshot);return snapshot}
        let payload=try await ai.readingPayload(state:app.learner,lesson:nil,level:"A1",selection:.null,recent:[],tutorial:false,repair:false,onChunk:{observed.append($0)})
        XCTAssertTrue(payload["nativeReadingStream"].boolean);XCTAssertEqual(payload["target"].string,"La flor crece.");XCTAssertEqual(payload["reviewQuestion"],.null);XCTAssertFalse(observed.isEmpty)
        let run=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:.null,roll:0);XCTAssertNotNil(run.pendingQuestionType);XCTAssertTrue(run.takeaways.isEmpty)
    }
    func testReplacingPassageCancelsOldQuestionAndAllowsNewQuestion() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_READING_MISSING_QUESTION_FIXTURE"] == "1" else{throw XCTSkip("Missing-question fixture required")}
        let app=try model();defer{try? app.identity.disconnect()};let payload=try XCTUnwrap(ReadingStreamDraft.sourcePayload("{\"type\":\"target\",\"text\":\"La flor crece.\"}\n",target:"es",support:"en",questionType:"mc"))
        let old=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:.null,roll:0);app.learner.saveReading(old);let service=ReadingService()
        let previous=Task{await service.ensureReviewQuestion(app,run:old)};for _ in 0..<100 where !service.questionGenerating {try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(service.questionGenerating)
        await service.prepare(app,lesson:nil,fresh:true);await previous.value;let next=try XCTUnwrap(app.learner.reading);XCTAssertNotEqual(next.id,old.id);XCTAssertNotNil(next.pendingQuestionType);XCTAssertFalse(service.questionGenerating)
        await service.ensureReviewQuestion(app,run:next);XCTAssertNil(app.learner.reading?.pendingQuestionType);XCTAssertFalse(service.questionGenerating);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testCancelDiscardsDraftAndCannotSaveOrAward() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let service=ReadingService()
        let task=Task{await service.prepare(app,lesson:nil,fresh:true)}
        for _ in 0..<100 where service.draft == nil {try await Task.sleep(for:.milliseconds(20))}
        XCTAssertNotNil(service.draft);XCTAssertNil(app.learner.reading);XCTAssertEqual(app.learner.totalXP,0)
        service.cancel();await task.value
        XCTAssertNil(service.draft);XCTAssertFalse(service.generating);XCTAssertNil(app.learner.reading);XCTAssertEqual(app.learner.totalXP,0);XCTAssertTrue((app.learner.pendingChanges ?? []).isEmpty)
    }
    func testLanguageReplacementDiscardsLateDraftAndRun() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let service=ReadingService()
        let task=Task{await service.prepare(app,lesson:nil,fresh:true)}
        for _ in 0..<100 where service.draft == nil {try await Task.sleep(for:.milliseconds(20))}
        XCTAssertNotNil(service.draft);app.learner.target="fr";service.cancel();await task.value
        XCTAssertNil(service.draft);XCTAssertNil(app.learner.readingRuns?["es"]);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testCancelledTranslationNeverSavesPartialLines() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_READING_TRANSLATION_STREAM_FIXTURE"] == "1" else{throw XCTSkip("Isolated translation stream fixture required")}
        let app=try model();defer{try? app.identity.disconnect()};let run=try ReadingRun(payload:ContentLibrary.load(JSONValue.self,name:"reading-test-passage"),target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:.null,roll:0.5)
        app.learner.saveReading(run);let service=ReadingService(),task=Task{await service.translate(app,run:run)}
        for _ in 0..<100 where service.translationLines(for:run.id)?.isEmpty != false {try await Task.sleep(for:.milliseconds(20))}
        XCTAssertEqual(service.translationLines(for:run.id)?.first,"My green notebook is near the window.");XCTAssertNil(app.learner.reading?.lineTranslations)
        service.cancel();let result=await task.value;XCTAssertFalse(result);XCTAssertNil(service.translationLines(for:run.id));XCTAssertNil(app.learner.reading?.lineTranslations);XCTAssertEqual(app.learner.totalXP,0)
    }

}
