import XCTest
@testable import Piyali
@MainActor private final class OralNoCloud:LearnerProgressService {
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor private final class OralTestTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,microphone=false,closed=false
    var connections=0
    func connect(session:JSONValue)async throws{self.session=session;connections+=1}
    func send(_ event:JSONValue)->Bool{true}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){microphone=enabled}
    func close(){closed=true;microphone=false}
}
@MainActor final class LessonSpeechControllerTests:XCTestCase {
    private func app()throws->AppModel{let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")};let app=AppModel(progressService:OralNoCloud());try app.identity.create();app.signedIn=true;app.subscription.bind(app.identity);app.learner=LearnerState();app.learner.target="es";app.learner.support="en";return app}
    private func run(_ app:AppModel,kind:String)throws->PracticeRun {let payload:JSONValue=kind == "speak" ? .object(["target":.string("Hola, soy Ana."),"prompt":.string("Say the sentence"),"variant":.string("repeat")]):.object(["concept":.string("Hello, I am Ana."),"answer":.string("Hola, soy Ana.")]);let q=try PracticeQuestion(module:.grammar,kind:kind,payload:payload,options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en"),run=PracticeRun(question:q,lessonID:nil,lessonLevel:"A1",response:.object(["text":.string("")]));app.learner.savePractice(run);return run}
    private func wait(_ condition:()->Bool)async throws{for _ in 0..<500 where !condition(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(condition())}
    func testBothFormatsStartAtReadinessAndSubmitEachCompletedTranscriptOnce()async throws {
        for kind in ["speak","flashcard"]{let app=try app(),run=try run(app,kind:kind),transport=OralTestTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true}),oral=LessonSpeechController(recorder:recorder),service=PracticeService(judge:{_ in "YES | 6"});defer{oral.clear();try? app.identity.disconnect()}
            oral.toggle(app,run:run,service:service);try await wait{transport.session != .null};XCTAssertFalse(transport.microphone);XCTAssertFalse(transport.session["audio"]["input"]["transcription"]["prompt"].string.contains("Hola, soy Ana."));transport.onOpen?();XCTAssertTrue(transport.microphone)
            transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("Hola, soy Ana.")]));recorder.stop();try await wait{app.learner.practiceRuns?[run.key]?.correct == true};XCTAssertEqual(app.learner.totalXP,6);XCTAssertTrue(transport.closed);XCTAssertEqual(app.learner.practiceDecks?[app.learner.practiceDeckKey(.grammar)]?.count ?? 0,kind == "flashcard" ? 1:0)
            transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("late")]));try await Task.sleep(for:.milliseconds(20));XCTAssertEqual(app.learner.totalXP,6)
        }
    }
    func testBothFormatsCanRetryTheSameWrongTranscriptAndDoNotAward()async throws{
        for kind in ["speak","flashcard"]{let app=try app();var run=try run(app,kind:kind);let transport=OralTestTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true}),oral=LessonSpeechController(recorder:recorder),service=PracticeService(judge:{_ in "NO"});defer{oral.clear();try? app.identity.disconnect()}
            for _ in 0..<2{let previous=transport.connections;oral.toggle(app,run:run,service:service);try await wait{transport.connections>previous};transport.onOpen?();transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("WRONG_FIXTURE")]));recorder.stop();try await wait{app.learner.practiceRuns?[run.key]?.correct == false};run=try XCTUnwrap(app.learner.practiceRuns?[run.key]);XCTAssertEqual(app.learner.totalXP,0)}
        }
    }
    func testQuestionChangeAndPermissionDenialRejectCaptureWithoutAwards()async throws{
        for kind in ["speak","flashcard"]{let app=try app(),old=try run(app,kind:kind),transport=OralTestTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true}),oral=LessonSpeechController(recorder:recorder),service=PracticeService(judge:{_ in XCTFail("Old capture must not reach judge");return "YES"});defer{oral.clear();try? app.identity.disconnect()};oral.toggle(app,run:old,service:service);try await wait{transport.session != .null};transport.onOpen?();let current=try run(app,kind:kind);oral.bind(app,run:current);XCTAssertTrue(transport.closed);transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("Hola, soy Ana.")]));recorder.stop();try await Task.sleep(for:.milliseconds(20));XCTAssertNil(app.learner.practiceRuns?[current.key]?.correct)
            let denied=SpeechPracticeService(transportFactory:{XCTFail("Denied microphone cannot create transport");return transport},permission:{false}),blocked=LessonSpeechController(recorder:denied);blocked.toggle(app,run:current,service:service);try await wait{denied.error != nil};XCTAssertEqual(denied.error,"mic-denied");XCTAssertEqual(app.learner.totalXP,0);blocked.clear()
        }
    }
    func testDeckPresentationCanPreserveGradingButLeavingRejectsAnUncooperativeJudge()async throws {
        for leaving in [false,true]{let app=try app(),run=try run(app,kind:"flashcard"),transport=OralTestTransport(),recorder=SpeechPracticeService(transportFactory:{transport},permission:{true}),oral=LessonSpeechController(recorder:recorder);var release:CheckedContinuation<String,Never>?
            let service=PracticeService(judge:{_ in await withCheckedContinuation{release=$0}});defer{oral.clear();try? app.identity.disconnect()};oral.toggle(app,run:run,service:service);try await wait{transport.session != .null};transport.onOpen?();transport.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string("Hola, soy Ana.")]));recorder.stop();try await wait{release != nil}
            if leaving{oral.clear()}else{recorder.cancel()};release?.resume(returning:"YES | 6");release=nil;try await wait{!service.busy};XCTAssertEqual(app.learner.totalXP,leaving ? 0:6);XCTAssertEqual(app.learner.practiceDecks?[app.learner.practiceDeckKey(.grammar)]?.count ?? 0,leaving ? 0:1)
        }
    }
    func testNewCardPreparationUsesThePersistedCollectedConcepts()async throws{
        let app=try app(),old=try run(app,kind:"flashcard");defer{try? app.identity.disconnect()};app.learner.collectPracticeCard(old)
        let original=try XCTUnwrap(Bundle.main.url(forResource:"practice-recipes",withExtension:"js")),temporary=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".js"),script=try String(contentsOf:original,encoding:.utf8)+"\nPiyaliPracticeRecipes=Object.assign({},PiyaliPracticeRecipes,{select:function(){return JSON.stringify({exerciseType:'flashcard',cefrLevel:'A1'})}});";try script.write(to:temporary,atomically:true,encoding:.utf8);defer{try? FileManager.default.removeItem(at:temporary)}
        var requests=0;let service=PracticeService(recipes:try PracticeRecipes(source:temporary),generator:{prompt in requests+=1;XCTAssertTrue(prompt.contains("Avoid repeating these already-collected concepts: Hello, I am Ana."));return #"{"type":"lesson_flashcard","concept":"Thank you","answer":"Gracias"}"#});await service.prepare(app,module:.grammar,lesson:nil,fresh:true);XCTAssertEqual(requests,1);XCTAssertFalse(service.preparationFailed);XCTAssertEqual(app.learner.practiceRuns?[old.key]?.question.payload["concept"].string,"Thank you");XCTAssertEqual(app.learner.totalXP,0)
    }

}
