import XCTest
@testable import Piyali

@MainActor final class StorySpeechNoCloud:LearnerProgressService{
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{throw URLError(.notConnectedToInternet)}
}
@MainActor private final class StoryCaptureTransport:RealtimeVoiceTransport{
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,sent:[JSONValue]=[],microphone:[Bool]=[],closed=false
    func connect(session:JSONValue)async throws{self.session=session}
    func send(_ event:JSONValue)->Bool{sent.append(event);return true}
    func setMicrophoneEnabled(_ enabled:Bool){microphone.append(enabled)}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func close(){closed=true}
}
@MainActor final class StorySpeechControllerTests:XCTestCase{
    private func app()throws->AppModel{let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline identity required")};let app=AppModel(progressService:StorySpeechNoCloud());try app.identity.create();app.signedIn=true;app.learner=LearnerState();app.learner.name="Alicia";app.learner.target="es";app.learner.support="en";app.learner.level="A1";return app}
    private func run(_ app:AppModel,mode:StoryMode)throws->StoryRun{
        var payload=try ContentLibrary.load(JSONValue.self,name:"story-test-episode")
        if mode == .speaking{let lines=Array(payload["segments"].array.flatMap{$0["turns"].array}.prefix(2));payload = .object(["title":payload["title"],"sentences":.array(lines)])}
        else{payload=payload.setting("segments",.array(payload["segments"].array.map{segment in segment.setting("turns",.array(segment["turns"].array.map{$0["speaker"].string == "Luis" ? $0.setting("speaker",.string("You")):$0}))}))}
        let run=try StoryRun(payload:payload,mode:mode,target:"es",support:"en",level:"A1",lessonID:nil,worth:ConversationPractice.worth(rating:0,level:"A1"),tutorial:true);app.learner.saveStory(run);return run
    }
    private func ready(_ t:StoryCaptureTransport)async throws{for _ in 0..<500 where t.session == .null{try await Task.sleep(for:.milliseconds(2))};XCTAssertNotEqual(t.session,.null)}
    private func finish(_ t:StoryCaptureTransport,_ controller:StorySpeechController,text:String){t.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string(text)]));controller.stop()}
    func testOriginalStoryCallerOptionsAndCompletionMetadata()throws{
        let policy=try StorySpeechPolicy(),url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"story-speech-policy",withExtension:"json")),cases=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url)).array;XCTAssertEqual(cases.count,275)
        for row in cases{XCTAssertEqual(try policy.run(row["operation"].string,row["input"]),row["output"])}
    }
    func testSpeakingWaitsForChannelUsesSavedPauseAndAwardsEachCompletedCaptureOnce()async throws{
        let app=try app(),run=try run(app,mode:.speaking),t=StoryCaptureTransport(),controller=StorySpeechController(recorder:SpeechPracticeService(transportFactory:{t},permission:{true}));defer{controller.cancel();try? app.identity.disconnect()};app.learner.changeSettings(.object(["pauseMs":.number(1800)]));var results=0
        let target=try XCTUnwrap(run.currentSentence?.target)
        controller.start(app,run:run,target:target,role:nil,allowed:{true}){metadata in results+=1;XCTAssertEqual(metadata["confidence"].number,0.9);XCTAssertEqual(metadata["audioMetrics"],.null);XCTAssertEqual(metadata["method"].string,"realtime-whisper");_=app.learner.practiceStoryLine(words:metadata["recognizedText"].string,confidence:metadata["confidence"].number,audio:nil)}
        try await ready(t);XCTAssertTrue(controller.recorder.connecting);XCTAssertFalse(controller.recorder.recording);XCTAssertTrue(t.microphone.isEmpty);XCTAssertFalse(t.session["audio"]["input"]["transcription"]["prompt"].string.contains(target));XCTAssertEqual(t.session["audio"]["input"]["turn_detection"]["silence_duration_ms"].number,1800)
        t.onOpen?();XCTAssertTrue(controller.recorder.recording);XCTAssertEqual(t.microphone,[true]);finish(t,controller,text:target);XCTAssertEqual(results,1);XCTAssertEqual(app.learner.totalXP,2);XCTAssertTrue(t.closed)
        t.onEvent?(.object(["type":.string("input_audio_transcription.completed"),"transcript":.string(target)]));XCTAssertEqual(results,1);XCTAssertEqual(app.learner.totalXP,2)
    }
    func testConversationAndRadioUseExpectedHintWithoutAnyLineAward()async throws{
        for mode in[StoryMode.conversation,.radio]{let app=try app(),run=try run(app,mode:mode),t=StoryCaptureTransport(),controller=StorySpeechController(recorder:SpeechPracticeService(transportFactory:{t},permission:{true}));defer{controller.cancel();try? app.identity.disconnect()};let role=try XCTUnwrap(run.currentSegment?.turns.firstIndex(where:{$0.speaker == "You"})),target=run.currentSegment!.turns[role].target;var result:StorySpeechResult?
            controller.start(app,run:run,target:target,role:role,allowed:{true}){metadata in result=StorySpeech.evaluate(recognized:metadata["recognizedText"].string,target:target,lang:"es",confidence:metadata["confidence"].number,audio:nil)};try await ready(t);XCTAssertTrue(t.session["audio"]["input"]["transcription"]["prompt"].string.contains(target));XCTAssertEqual(t.session["audio"]["input"]["turn_detection"]["silence_duration_ms"].number,2000)
            t.onOpen?();finish(t,controller,text:target);XCTAssertEqual(result?.pass,true);XCTAssertEqual(app.learner.totalXP,0);XCTAssertFalse(app.learner.story?.heard.contains(0) ?? true)
        }
    }
    func testSameWrongTranscriptCanBeRetriedBeforeACorrectCapture()async throws{
        let app=try app(),run=try run(app,mode:.speaking),ts=[StoryCaptureTransport(),StoryCaptureTransport(),StoryCaptureTransport()];var index=0,results=0
        let controller=StorySpeechController(recorder:SpeechPracticeService(transportFactory:{let t=ts[index];index+=1;return t},permission:{true}));defer{controller.cancel();try? app.identity.disconnect()};let target=run.currentSentence!.target
        for text in["wrong phrase","wrong phrase",target]{if var current=app.learner.story{current.speechResult=nil;current.lastWords="";app.learner.saveStory(current)};controller.start(app,run:run,target:target,role:nil,allowed:{true}){m in results+=1;_=app.learner.practiceStoryLine(words:m["recognizedText"].string,confidence:m["confidence"].number,audio:nil)};let t=ts[index];try await ready(t);t.onOpen?();finish(t,controller,text:text)}
        XCTAssertEqual(results,3);XCTAssertEqual(app.learner.totalXP,2);XCTAssertEqual(app.learner.story?.passedLines,[0])
    }
    func testChangedOwnerRunSegmentLanguageAccessOrCancellationRejectsLateResults()async throws{
        for mutation in["account","target","support","level","run","segment","access","cancel"]{let app=try app(),run=try run(app,mode:.speaking),t=StoryCaptureTransport(),controller=StorySpeechController(recorder:SpeechPracticeService(transportFactory:{t},permission:{true}));defer{controller.cancel();try? app.identity.disconnect()};var allowed=true,results=0;let target=run.currentSentence!.target
            controller.start(app,run:run,target:target,role:nil,allowed:{allowed}){_ in results+=1};try await ready(t);t.onOpen?()
            switch mutation{case "account":try app.identity.create();case "target":app.learner.target="ja";case "support":app.learner.support="ar";case "level":app.learner.level="B2";case "run":var changed=run;changed.id=UUID();app.learner.saveStory(changed);case "segment":var changed=run;changed.index=1;app.learner.saveStory(changed);case "access":allowed=false;default:controller.cancel()}
            finish(t,controller,text:target);XCTAssertEqual(results,0,mutation);XCTAssertEqual(app.learner.totalXP,0,mutation);XCTAssertFalse(controller.recorder.recording)
        }
    }
    func testPermissionDenialConnectionFailureAndTranscriptionFailureNeverGrade()async throws{
        for kind in["permission","connection","transcription"]{let app=try app(),run=try run(app,mode:.speaking),t=StoryCaptureTransport(),controller=StorySpeechController(recorder:SpeechPracticeService(transportFactory:{t},permission:{kind != "permission"}));defer{controller.cancel();try? app.identity.disconnect()};var results=0
            controller.start(app,run:run,target:run.currentSentence!.target,role:nil,allowed:{true}){_ in results+=1}
            if kind == "permission"{for _ in 0..<100 where controller.recorder.error == nil{try await Task.sleep(for:.milliseconds(2))};XCTAssertEqual(controller.recorder.error,"mic-denied");XCTAssertEqual(t.session,.null)}else{try await ready(t);t.onOpen?();if kind == "connection"{t.onFailure?("offline")}else{t.onEvent?(.object(["type":.string("input_audio_transcription.failed")]))};XCTAssertNotNil(controller.recorder.error)}
            XCTAssertEqual(results,0);XCTAssertEqual(app.learner.totalXP,0);XCTAssertFalse(controller.recorder.connecting);XCTAssertFalse(controller.recorder.recording)
        }
    }
}
