import XCTest
@testable import Piyali
@MainActor private final class WritingNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor private final class WritingTestTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,microphone=false,closed=false
    func connect(session:JSONValue)async throws{self.session=session}
    func send(_ event:JSONValue)->Bool{true}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){microphone=enabled}
    func close(){closed=true;microphone=false}
}
@MainActor final class WritingSpeechControllerTests:XCTestCase {
    private func app()throws->AppModel{let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")};let app=AppModel(progressService:WritingNoCloud());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.target="es";app.learner.support="en";return app}
    private func run(_ app:AppModel)throws->PracticeRun{let recipes=try PracticeRecipes(),payload=try recipes.inspect("fallback",parameters:.object(["variant":.string("sentence_shapeshifter"),"moduleType":.string("grammar"),"targetLang":.string("es"),"supportLang":.string("en")])),q=try PracticeQuestion(module:.grammar,kind:"delight:sentence_shapeshifter",payload:payload,options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en"),run=PracticeRun(question:q,lessonID:nil,lessonLevel:"A1",response:.object(["text":.string("")]));app.learner.savePractice(run);return run}
    private func wait(_ condition:()->Bool)async throws{for _ in 0..<500 where !condition(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(condition())}
    func testCompletedRealtimeTranscriptSubmitsOnceWithoutAnswerHintBias()async throws{
        let app=try app(),run=try run(app),transport=WritingTestTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true}),writing=WritingSpeechController(recorder:recorder);defer{writing.clear();try? app.identity.disconnect()};var calls=0
        let service=PracticeService(judge:{prompt in calls+=1;XCTAssertTrue(prompt.contains("Learner response"));XCTAssertTrue(prompt.contains("Mi respuesta nueva"));return "YES"})
        writing.toggle(app,run:run,service:service);try await wait{transport.session != .null};XCTAssertFalse(transport.microphone);XCTAssertFalse(transport.session["audio"]["input"]["transcription"]["prompt"].string.contains(run.question.payload["answer"].string));transport.onOpen?();XCTAssertTrue(transport.microphone)
        transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("Mi respuesta nueva")]));recorder.stop();try await wait{app.learner.practiceRuns?[run.key]?.correct == true};XCTAssertEqual(calls,1);XCTAssertEqual(app.learner.totalXP,7);XCTAssertTrue(transport.closed)
        transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("late")]));try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(calls,1);XCTAssertEqual(app.learner.practiceRuns?[run.key]?.response["text"].string,"Mi respuesta nueva")
    }
    func testChangingQuestionCancelsCaptureAndRejectsTheOldTranscript()async throws{
        let app=try app(),old=try run(app),transport=WritingTestTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true}),writing=WritingSpeechController(recorder:recorder),service=PracticeService(judge:{_ in XCTFail("Old transcript must not be judged");return "YES"});defer{writing.clear();try? app.identity.disconnect()}
        writing.toggle(app,run:old,service:service);try await wait{transport.session != .null};transport.onOpen?();let current=try run(app);writing.bind(app,run:current);XCTAssertTrue(transport.closed);transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("old")]));recorder.stop();try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(app.learner.practiceRuns?[current.key]?.response["text"].string,"");XCTAssertEqual(app.learner.totalXP,0)
    }
    func testLeavingDuringAnUncooperativeJudgeCannotAwardTheTranscript()async throws{
        let app=try app(),run=try run(app),transport=WritingTestTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true}),writing=WritingSpeechController(recorder:recorder);defer{writing.clear();try? app.identity.disconnect()};var release:CheckedContinuation<String,Never>?
        let service=PracticeService(judge:{_ in await withCheckedContinuation{release=$0}});writing.toggle(app,run:run,service:service);try await wait{transport.session != .null};transport.onOpen?();transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("answer")]));recorder.stop();try await wait{release != nil};writing.clear();service.cancel();release?.resume(returning:"YES");release=nil;try await Task.sleep(for:.milliseconds(50));XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.practiceRuns?[run.key]?.correct)
    }
    func testMicrophoneDenialDoesNotStartTransportOrGrade()async throws{
        let app=try app(),run=try run(app),recorder=SpeechPracticeService(transportFactory:{XCTFail("Permission is required before transport creation");return WritingTestTransport()},permission:{false}),writing=WritingSpeechController(recorder:recorder);defer{writing.clear();try? app.identity.disconnect()}
        writing.toggle(app,run:run,service:PracticeService(judge:{_ in XCTFail("No recording to grade");return "YES"}));try await wait{recorder.error != nil};XCTAssertEqual(recorder.error,"mic-denied");XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.learner.practiceRuns?[run.key]?.correct)
    }
}
