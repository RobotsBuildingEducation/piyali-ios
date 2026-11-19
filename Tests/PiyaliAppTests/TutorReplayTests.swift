import XCTest
import AVFoundation
@testable import Piyali

@MainActor private final class ReplyReplay:NarrationReplay {
    var onFinished:(()->Void)?,onFailed:(()->Void)?
    var wav:Data?,stopped=false,failPlay=false
    func play(_ wav:Data)throws{if failPlay{throw URLError(.cannotDecodeContentData)};self.wav=wav;stopped=false}
    func stop(){stopped=true;onFinished=nil;onFailed=nil}
}
@MainActor private final class ReplyNarration:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,sent:[JSONValue]=[],closed=false,failConnect=false
    func connect(session:JSONValue)async throws{self.session=session;if failConnect{throw URLError(.notConnectedToInternet)};onOpen?()}
    func send(_ event:JSONValue)->Bool{sent.append(event);return true}
    func setMicrophoneEnabled(_ enabled:Bool){}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func close(){closed=true}
}
@MainActor final class TutorReplayTests:XCTestCase {
    private let scope=TutorAudioClips.Scope(account:"public-fixture",target:"es",support:"en")
    private func settle()async{for _ in 0..<100{await Task.yield()}}
    private func directory()->URL{FileManager.default.temporaryDirectory.appendingPathComponent("piyali-reply-test-"+UUID().uuidString)}
    private func message(_ text:String="Hola",role:String="assistant")->JSONValue{.object(["id":.string("r"),"role":.string(role),"textFinal":.string(text),"lang":.string("es")])}
    private func fixture()throws->JSONValue{let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"tutor-replay-traces",withExtension:"json"));return try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))}
    func testOriginalFallbackTextVoiceLanguageRules()throws {
        let cases=try fixture()["cases"].array,policy=try TutorReplayPolicy();XCTAssertEqual(cases.count,32)
        for row in cases{XCTAssertEqual(try policy.plan(row["input"]),row["expected"],row["input"].json)}
        let tutor=try TutorSourcePolicy(),voice=try tutor.run("voice",.object(["provider":.string("gemini"),"voice":.string("marin")])).string
        let plan=try policy.plan(.object(["id":.string("r"),"messages":.array([message()]),"target":.string("es"),"voice":.string(voice)]));XCTAssertEqual(plan["voice"].string,"ash")
    }
    func testOriginalAsyncReplayTracesChooseRecordedAudioBeforeSynthesisAndReleaseOnEndOrFailure()async throws {
        let traces=try fixture()["traces"].array;XCTAssertEqual(traces.count,9)
        for row in traces {
            let mode=row["mode"].string,recorded=["cached","audio-error","play-error"].contains(mode),clip=Data(repeating:42,count:600),transport=ReplyNarration(),player=ReplyReplay();player.failPlay=mode == "play-error";transport.failConnect=mode == "tts-error"
            let narration=RealtimeNarrationService(factory:{transport},cacheEnabled:false,replayFactory:{player}),controller=TutorReplayController(narration:narration,lookup:{_,_ in recorded ? clip:nil}),clips=TutorAudioClips(directory:directory());var duck:[Bool]=[]
            let messages=mode == "missing" ? []:[message(mode == "empty" ? " ":"Hola",role:mode == "user" ? "user":"assistant")]
            func play(){controller.play("r",messages:messages,target:"en",voice:"cedar",scope:scope,clips:clips,engine:try? CompanionQuestPolicy(),live:true,duck:{duck.append($0)})}
            play();await settle()
            if mode == "same"{play()}
            if mode == "cached"{player.onFinished?()}
            if mode == "audio-error"{player.onFailed?()}
            if mode == "fallback"{transport.onEvent?(.object(["type":.string("output_audio_buffer.started")]));narration.stopAll()}
            await settle()
            let sourcePath=row["log"].array.compactMap{$0.array.first?.string}.filter{["recorded","synthesized"].contains($0)}
            if recorded{
                XCTAssertTrue(transport.sent.isEmpty,mode)
                if mode != "play-error"{XCTAssertEqual(player.wav,clip,mode);XCTAssertEqual(sourcePath,["recorded"],mode)}
            }else if ["fallback","same"].contains(mode){
                XCTAssertFalse(transport.sent.isEmpty,mode);XCTAssertEqual(transport.session["audio"]["output"]["voice"].string,"cedar");XCTAssertTrue(transport.session["instructions"].string.contains("es-MX"));XCTAssertEqual(transport.sent.first?["item"]["content"].array.first?["text"].string,"[NARRATE THIS TEXT EXACTLY]: Hola")
            }else if mode != "tts-error"{XCTAssertTrue(transport.sent.isEmpty,mode);XCTAssertNil(player.wav,mode);XCTAssertFalse(duck.contains(true),mode)}
            XCTAssertNil(controller.activeID,mode);if !duck.isEmpty{XCTAssertEqual(duck.last,false,mode)}
            if ["audio-error","play-error","tts-error"].contains(mode){XCTAssertNotNil(controller.error,mode)}
            controller.stop()
        }
    }
    func testStaleCacheLookupAndLatePlayerCallbacksCannotTakeAnotherOwner()async throws {
        let player=ReplyReplay(),narration=RealtimeNarrationService(factory:{ReplyNarration()},cacheEnabled:false,replayFactory:{player});var held:CheckedContinuation<Data?,Never>?,duck:[Bool]=[]
        let controller=TutorReplayController(narration:narration,lookup:{id,_ in if id == "r"{return await withCheckedContinuation{held=$0}};return Data(repeating:2,count:600)}),clips=TutorAudioClips(directory:directory())
        controller.play("r",messages:[message()],target:"es",voice:"ash",scope:scope,clips:clips,engine:nil,live:true,duck:{duck.append($0)});await settle();XCTAssertNotNil(held)
        let other=TutorAudioClips.Scope(account:"second",target:"ar",support:"es")
        controller.play("r2",messages:[],target:"ar",voice:"ash",scope:other,clips:clips,engine:nil,live:true,duck:{duck.append($0)});await settle();let late=player.onFinished;XCTAssertEqual(controller.activeID,"r2")
        held?.resume(returning:Data(repeating:1,count:600));await settle();XCTAssertEqual(player.wav,Data(repeating:2,count:600));XCTAssertEqual(controller.activeID,"r2")
        let next=RealtimeNarrationService(factory:{ReplyNarration()},cacheEnabled:false,replayFactory:{ReplyReplay()});next.playRecording(Data(repeating:3,count:600),preservingAudioSession:true);XCTAssertNil(controller.activeID);XCTAssertEqual(duck.last,false);late?();XCTAssertTrue(next.playing);next.stopAll();controller.stop()
    }
    func testAnotherAudioOwnerCancelsAnOutstandingClipLookupBeforeItCanPlay()async throws {
        var held:CheckedContinuation<Data?,Never>?,duck:[Bool]=[];let player=ReplyReplay(),narration=RealtimeNarrationService(factory:{ReplyNarration()},cacheEnabled:false,replayFactory:{player}),controller=TutorReplayController(narration:narration,lookup:{_,_ in await withCheckedContinuation{held=$0}}),clips=TutorAudioClips(directory:directory())
        controller.play("r",messages:[message()],target:"es",voice:"ash",scope:scope,clips:clips,engine:nil,live:true,duck:{duck.append($0)});await settle();XCTAssertNotNil(held)
        let next=RealtimeNarrationService(factory:{ReplyNarration()},cacheEnabled:false,replayFactory:{ReplyReplay()});next.playRecording(Data(repeating:3,count:600),preservingAudioSession:true);XCTAssertNil(controller.activeID)
        held?.resume(returning:Data(repeating:1,count:600));await settle();XCTAssertNil(player.wav);XCTAssertTrue(next.playing);XCTAssertEqual(duck,[false]);next.stopAll();controller.stop()
    }
    func testOriginalPCMIsLosslessPrivatePersistentAndCorruptCacheFallsBackToMiss()async throws {
        let root=directory();defer{try? FileManager.default.removeItem(at:root)};let clips=TutorAudioClips(directory:root),pcm=Data((0..<1200).map{UInt8($0%256)}),recording=NarrationRecording(pcm16:pcm,sampleRate:24000,channels:1)
        await clips.store(recording,response:"r",scope:scope);let first=await clips.load("r",scope:scope);XCTAssertEqual(first?.dropFirst(44),pcm);XCTAssertEqual(first?.prefix(4),Data("RIFF".utf8))
        let next=TutorAudioClips(directory:root),disk=await next.load("r",scope:scope);XCTAssertEqual(disk,first)
        for changed in [TutorAudioClips.Scope(account:"other",target:"es",support:"en"),.init(account:scope.account,target:"fr",support:"en"),.init(account:scope.account,target:"es",support:"ar")]{let miss=await next.load("r",scope:changed);XCTAssertNil(miss)}
        let wrongResponse=await next.load("another-response",scope:scope);XCTAssertNil(wrongResponse)
        let file=try XCTUnwrap(FileManager.default.contentsOfDirectory(at:root,includingPropertiesForKeys:nil).first);XCTAssertFalse(file.lastPathComponent.contains(scope.account));try Data("corrupt".utf8).write(to:file)
        let clean=TutorAudioClips(directory:root),bad=await clean.load("r",scope:scope);XCTAssertNil(bad)
    }
    func testPlayedPCMRejectsLateResponseAndDropsOverflowRatherThanSavingATruncatedReply(){
        var capture=TutorResponseAudio(limit:8);capture.begin("one");capture.played(Data([0,4,0,8]),response:"one",gain:0.5);capture.played(Data([9,9]),response:"late");let result=capture.take("one");XCTAssertEqual(result?.pcm16,Data([0,2,0,4]));XCTAssertNil(capture.take("one"))
        capture.begin("two");capture.played(Data(repeating:1,count:10),response:"two");XCTAssertNil(capture.take("two"));capture.begin("three");capture.played(Data([0,1]),response:"two");XCTAssertNil(capture.take("three"))
    }
}
