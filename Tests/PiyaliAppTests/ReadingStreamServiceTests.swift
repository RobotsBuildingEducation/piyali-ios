import XCTest
@testable import Piyali

@MainActor final class ReadingStreamServiceTests:XCTestCase {
    private func model() throws -> AppModel {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_READING_FIXTURE"] == "1",env["PIYALI_READING_STREAM_FIXTURE"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated streaming fixture required")}
        let app=AppModel();try app.identity.create();app.learner=LearnerState();app.learner.target="es";app.learner.support="en";return app
    }
    private func duplicateModel() throws ->AppModel {
        guard ProcessInfo.processInfo.environment["PIYALI_READING_MISSING_QUESTION_FIXTURE"] == "1" else{throw XCTSkip("Immediate partial fixture required")}
        return try model()
    }
    private func translationRun(_ app:AppModel) throws ->ReadingRun {
        let payload:JSONValue = .object(["title":.string("Tres frases"),"target":.string("Una. Dos. Tres."),"takeaways":.array([]),"reviewQuestionType":.string("text"),"nativeReadingStream":.bool(true),"reviewQuestion":.object(["type":.string("text"),"question":.string("What comes first?"),"answer":.string("One")])])
        let run=try ReadingRun(payload:payload,target:"es",support:"en",level:PerformanceScore.level(score:app.learner.score),lessonID:nil,selection:.null,worth:.null,roll:0)
        app.learner.saveReading(run);return run
    }
    func testTranslationServiceMatchesReachableSourceOutcomesWithoutErrorOrReward() async throws {
        let app=try model();defer{try? app.identity.disconnect()}
        let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"reading-translation-outcomes",withExtension:"json")),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        for row in rows where row["input"]["support"].string.isEmpty && !row["input"]["noProvider"].boolean {
            let spec=row["input"],run=try translationRun(app);var calls=0
            let service=ReadingService(translationWriter:{_,publish in
                calls += 1;var snapshot=""
                for chunk in spec["chunks"].array {snapshot += chunk.string;publish(snapshot)}
                if spec["fail"].boolean {throw ReadingFailure.invalid};return snapshot
            })
            service.error="Existing grade message"
            let success=await service.translate(app,run:run),expected=row["expected"]["lines"]
            XCTAssertEqual(calls,1);XCTAssertEqual(success,expected != .null,spec["name"].string);XCTAssertEqual(service.translationVisibility(for:run.id),row["expected"]["visible"].boolean)
            XCTAssertEqual(app.learner.reading?.lineTranslations,expected == .null ? nil:expected.array.map(\.string));XCTAssertEqual(service.error,"Existing grade message");XCTAssertFalse(service.translationLoading);XCTAssertFalse(service.busy);XCTAssertEqual(app.learner.totalXP,0)
        }
    }
    func testTranslationDoesNotBlockReviewOrOverwriteItsCompletedReceipt() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let run=try translationRun(app);var completion:CheckedContinuation<String,Error>?
        let service=ReadingService(speechGrader:{_,_ in .unavailable(support:"en")},translationWriter:{_,publish in publish("One.\n");return try await withCheckedThrowingContinuation{completion=$0}})
        let translation=Task{await service.translate(app,run:run)}
        for _ in 0..<100 where completion == nil {try await Task.sleep(for:.milliseconds(10))}
        XCTAssertTrue(service.translationLoading);XCTAssertFalse(service.busy);XCTAssertEqual(service.translationLines(for:run.id),["One."])
        await service.check(app,run:run,answer:"Una.",speech:true);let receipt=app.learner.pendingChanges?.map(\.id)
        XCTAssertTrue(app.learner.reading?.awarded == true);XCTAssertEqual(app.learner.totalXP,run.reward)
        completion?.resume(returning:"One.\nTwo.\nThree.");let translated=await translation.value;XCTAssertTrue(translated)
        XCTAssertEqual(app.learner.reading?.lineTranslations,["One.","Two.","Three."]);XCTAssertTrue(app.learner.reading?.awarded == true);XCTAssertEqual(app.learner.totalXP,run.reward);XCTAssertEqual(app.learner.pendingChanges?.map(\.id),receipt)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner));XCTAssertEqual(restored.reading?.lineTranslations,app.learner.reading?.lineTranslations)
    }
    func testCancelledTranslationCannotClearAReplacementRequestInTheSameRun() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let run=try translationRun(app);var completions:[CheckedContinuation<String,Error>]=[]
        let service=ReadingService(translationWriter:{_,publish in publish(completions.isEmpty ? "Old.\n":"New.\n");return try await withCheckedThrowingContinuation{completions.append($0)}})
        let old=Task{await service.translate(app,run:run)}
        for _ in 0..<100 where completions.isEmpty {try await Task.sleep(for:.milliseconds(10))}
        await service.prepare(app,lesson:nil,fresh:false)
        let new=Task{await service.translate(app,run:run)}
        for _ in 0..<100 where completions.count < 2 {try await Task.sleep(for:.milliseconds(10))}
        XCTAssertEqual(completions.count,2);guard completions.count == 2 else{completions.first?.resume(throwing:CancellationError());return}
        completions[0].resume(returning:"Old.\nOld.\nOld.");let stale=await old.value;XCTAssertFalse(stale)
        XCTAssertTrue(service.translationLoading);XCTAssertEqual(service.translationLines(for:run.id),["New."]);XCTAssertNil(app.learner.reading?.lineTranslations)
        completions[1].resume(returning:"New.\nTwo.\nThree.");let fresh=await new.value;XCTAssertTrue(fresh);XCTAssertFalse(service.translationLoading);XCTAssertEqual(app.learner.reading?.lineTranslations,["New.","Two.","Three."])
    }
    func testSourceFailureBudgetsAndDraftVisibility() async throws {
        let app=try model();defer{try? app.identity.disconnect()}
        let fixture=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"reading-outcomes",withExtension:"json")),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:fixture))
        for row in rows where row["expected"]["fallback"].number > 0 {
            let ai=AIService(),spec=row["input"];var streams=0,backends=0,visible:ReadingStreamDraft?,backendTexts:[String?]=[]
            ai.readingStreamOverride={_,chunk in
                streams += 1;var snapshot=""
                for part in spec["chunks"].array {snapshot += part.string;chunk(snapshot)}
                if spec["fail"].boolean {throw ReadingFailure.invalid};return snapshot
            }
            ai.readingBackendOverride={_ in
                backends += 1;backendTexts.append(visible?.text)
                if spec["fallbackFail"].boolean {throw ReadingFailure.invalid}
                return "{\"title\":\"A new passage\",\"target\":\"La planta crece.\"}"
            }
            var failed=false
            do {_=try await ai.readingPayload(state:app.learner,lesson:nil,level:"A1",selection:.null,recent:[],tutorial:false,repair:false,onChunk:{visible=ReadingStreamDraft.parse($0,target:"es",support:"en")})}catch{failed=true}
            XCTAssertEqual(streams,1);XCTAssertEqual(backends,Int(row["expected"]["fallback"].number),spec["name"].string);XCTAssertEqual(failed,row["expected"]["error"].boolean)
            let expected=row["expected"]["fallbackDrafts"].array.map{$0 == .null ? nil:$0["target"].string}
            XCTAssertEqual(backendTexts,expected,spec["name"].string)
        }
    }
    func testExhaustedFallbackShowsSourceErrorAndOnlyExplicitRetryRestartsStream() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let ai=AIService();var streams=0,backends=0,fail=true
        ai.readingStreamOverride={_,chunk in streams += 1;chunk("{\"type\":\"target\",\"text\":\"La flor crece.\"}\n");throw ReadingFailure.invalid}
        ai.readingBackendOverride={_ in backends += 1;if fail {throw ReadingFailure.invalid};return "{\"title\":\"El jardín\",\"target\":\"La planta crece.\"}"}
        let service=ReadingService(passageWriter:{publish in try await ai.readingPayload(state:app.learner,lesson:nil,level:"A1",selection:.null,recent:[],tutorial:false,repair:false,onChunk:publish)})
        await service.prepare(app,lesson:nil,fresh:true)
        XCTAssertEqual(streams,1);XCTAssertEqual(backends,1);XCTAssertEqual(service.error,"We couldn't create a fresh reading. Please try again.");XCTAssertNil(service.draft);XCTAssertNil(app.learner.reading);XCTAssertEqual(app.learner.totalXP,0)
        fail=false;await service.prepare(app,lesson:nil,fresh:true)
        XCTAssertEqual(streams,2);XCTAssertEqual(backends,2);XCTAssertNil(service.error);XCTAssertEqual(app.learner.reading?.text,"La planta crece.");XCTAssertEqual(app.learner.totalXP,0);XCTAssertEqual(app.learner.readingHistory?["es"]?.count,1)
    }
    func testImmediateDuplicateRetainsReviewedRunHistoryAndOneReward() async throws {
        let app=try duplicateModel();defer{try? app.identity.disconnect()};var clock=Date(timeIntervalSince1970:1700000000)
        let service=ReadingService(now:{clock});await service.prepare(app,lesson:nil,fresh:true)
        var first=try XCTUnwrap(app.learner.reading);first.method="speech";first.lineTranslations=try ContentLibrary.load(JSONValue.self,name:"reading-test-passage")["translations"].array.map(\.string);app.learner.saveReading(first)
        let reward=app.learner.reviewReading(answer:"Mi libreta verde está cerca de la ventana.",correct:true,feedback:"Reviewed",speech:true)
        let completed=try XCTUnwrap(app.learner.reading),events=app.learner.pendingChanges,history=app.learner.readingHistory
        XCTAssertGreaterThan(reward,0);clock=clock.addingTimeInterval(14.999);await service.prepare(app,lesson:nil,fresh:true)
        XCTAssertEqual(app.learner.reading,completed);XCTAssertEqual(app.learner.pendingChanges?.map(\.id),events?.map(\.id));XCTAssertEqual(app.learner.readingHistory,history);XCTAssertEqual(app.learner.totalXP,reward)
        XCTAssertFalse(service.suppressedPrevious);XCTAssertFalse(service.generating);XCTAssertFalse(service.busy)
        XCTAssertEqual(app.learner.reviewReading(answer:"Again",correct:true,feedback:"",speech:true),0)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(app.learner));XCTAssertEqual(restored.reading?.id,completed.id);XCTAssertTrue(restored.reading?.awarded == true)
    }
    func testDuplicateExpiresAtFifteenSecondsAndDoesNotPersistAcrossMounts() async throws {
        let app=try duplicateModel();defer{try? app.identity.disconnect()};var clock=Date(timeIntervalSince1970:1700000000)
        let service=ReadingService(now:{clock});await service.prepare(app,lesson:nil,fresh:true);let first=try XCTUnwrap(app.learner.reading)
        clock=clock.addingTimeInterval(15);await service.prepare(app,lesson:nil,fresh:true);let expired=try XCTUnwrap(app.learner.reading);XCTAssertNotEqual(expired.id,first.id)
        let remounted=ReadingService(now:{clock});await remounted.prepare(app,lesson:nil,fresh:true);XCTAssertNotEqual(app.learner.reading?.id,expired.id);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testDuplicateCannotReuseAnotherAccountOrLanguage() async throws {
        let app=try duplicateModel();defer{try? app.identity.disconnect()};let service=ReadingService(now:{Date(timeIntervalSince1970:1700000000)})
        await service.prepare(app,lesson:nil,fresh:true);let first=try XCTUnwrap(app.learner.reading)
        try app.identity.disconnect();try app.identity.create();await service.prepare(app,lesson:nil,fresh:true);let replacement=try XCTUnwrap(app.learner.reading);XCTAssertNotEqual(replacement.id,first.id)
        app.learner.support="fr";await service.prepare(app,lesson:nil,fresh:true);XCTAssertNotEqual(app.learner.reading?.id,replacement.id);XCTAssertEqual(app.learner.reading?.support,"fr");XCTAssertEqual(app.learner.totalXP,0)
    }
    func testProviderBoundaryAcceptsNormalPartialStreamAndLeavesQuestionPending() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let ai=AIService(),snapshot="{\"type\":\"target\",\"text\":\"La flor crece.\"}\n";var observed:[String]=[]
        ai.readingStreamOverride={_,onChunk in onChunk(snapshot);return snapshot}
        let payload=try await ai.readingPayload(state:app.learner,lesson:nil,level:"A1",selection:.null,recent:[],tutorial:false,repair:false,onChunk:{observed.append($0)})
        XCTAssertTrue(payload["nativeReadingStream"].boolean);XCTAssertEqual(payload["target"].string,"La flor crece.");XCTAssertEqual(payload["reviewQuestion"],.null);XCTAssertFalse(observed.isEmpty)
        let run=try ReadingRun(payload:payload,target:"es",support:"en",level:"A1",lessonID:nil,selection:.null,worth:.null,roll:0);XCTAssertNotNil(run.pendingQuestionType);XCTAssertTrue(run.takeaways.isEmpty)
    }
    func testFailedAndEmptyStreamsUseJSONBackendAndRetainRevealedDraft() async throws {
        let app=try model();defer{try? app.identity.disconnect()}
        for fail in [false,true] {
            let ai=AIService();var snapshots:[String]=[],requests=0
            ai.readingStreamOverride={_,chunk in
                if fail {chunk("{\"type\":\"target\",\"text\":\"Discard this partial.\"}\n");throw ReadingFailure.invalid}
                return "malformed\n"
            }
            ai.readingBackendOverride={prompt in
                requests += 1;XCTAssertTrue(prompt.contains("Return JSON ONLY:"));XCTAssertFalse(prompt.contains("Emit one line:"))
                return "{\"title\":\"Spanish: El jardín\",\"target\":\"La flor crece.\",\"takeaways\":[\"English: A flower grows.\"]}"
            }
            let payload=try await ai.readingPayload(state:app.learner,lesson:nil,level:"A1",selection:.null,recent:[],tutorial:false,repair:false,onChunk:{snapshots.append($0)})
            XCTAssertEqual(requests,1);XCTAssertFalse(snapshots.contains(""));if fail {XCTAssertTrue(snapshots.last?.contains("Discard this partial.") == true)};XCTAssertEqual(payload["title"].string,"El jardín");XCTAssertEqual(payload["target"].string,"La flor crece.");XCTAssertEqual(payload["reviewQuestion"],.null);XCTAssertEqual(app.learner.totalXP,0)
        }
    }
    func testCancelledStreamNeverStartsBackend() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let ai=AIService();var started=false,backend=false
        ai.readingStreamOverride={_,chunk in started=true;chunk("{\"type\":\"target\",\"text\":\"A partial.\"}\n");try await Task.sleep(for:.seconds(20));return ""}
        ai.readingBackendOverride={_ in backend=true;return "{}"}
        let request=Task{try await ai.readingPayload(state:app.learner,lesson:nil,level:"A1",selection:.null,recent:[],tutorial:false,repair:false)}
        for _ in 0..<100 where !started {try await Task.sleep(for:.milliseconds(10))}
        XCTAssertTrue(started);request.cancel()
        do {_=try await request.value;XCTFail("Cancelled generation must not return a passage")}catch is CancellationError {}catch{XCTFail("Unexpected cancellation error: \(error)")}
        XCTAssertFalse(backend);XCTAssertNil(app.learner.reading);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testProviderCancellationDoesNotTriggerBackend() async throws {
        let app=try model();defer{try? app.identity.disconnect()};let ai=AIService();var backend=false
        ai.readingStreamOverride={_,_ in throw CancellationError()};ai.readingBackendOverride={_ in backend=true;return "{}"}
        do {_=try await ai.readingPayload(state:app.learner,lesson:nil,level:"A1",selection:.null,recent:[],tutorial:false,repair:false);XCTFail("Provider cancellation must propagate")}catch is CancellationError {}catch{XCTFail("Unexpected cancellation error: \(error)")}
        XCTAssertFalse(backend)
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
