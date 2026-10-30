import XCTest
@testable import Piyali

@MainActor final class LessonNarrationTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    var session:JSONValue = .null,sent:[JSONValue]=[],microphone:[Bool]=[],closed=false
    func connect(session:JSONValue)async throws{self.session=session;onOpen?()}
    func send(_ event:JSONValue)->Bool{sent.append(event);return true}
    func setMicrophoneEnabled(_ enabled:Bool){microphone.append(enabled)}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func playbackDrainMilliseconds()async->Double{1}
    func close(){closed=true}
}
@MainActor final class LessonAudioTests:XCTestCase {
    private func ready(_ transport:LessonNarrationTransport)async throws{for _ in 0..<100 where transport.sent.isEmpty{try await Task.sleep(for:.milliseconds(2))};XCTAssertFalse(transport.sent.isEmpty)}
    func testExecutedOriginalTextPreparationAcrossBothModules()throws{
        let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"lesson-audio-text",withExtension:"json")),cases=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url)).array
        XCTAssertEqual(cases.count,54)
        for row in cases{XCTAssertEqual(LessonAudioController.prepare(row["input"].string,verbatim:row["kind"].string != "question"),row["output"].string,row["module"].string+" "+row["kind"].string)}
    }
    func testOriginalQuestionPauseDefaultVoiceAndSourceLanguageLocales()async throws{
        let engine=try CompanionQuestPolicy()
        for(language,locale)in[("es","es-MX"),("ar","ar-EG"),("ja","ja-JP"),("nah","es-MX")]{
            let transport=LessonNarrationTransport(),audio=LessonAudioController(narration:RealtimeNarrationService(factory:{transport}));defer{audio.clear()}
            audio.bind("question");audio.play("  Yo ___ pan.  ",language:language,owner:"question",engine:engine);try await ready(transport)
            XCTAssertEqual(transport.microphone,[false]);XCTAssertEqual(transport.session["audio"]["output"]["voice"].string,"ash");XCTAssertTrue(transport.session["instructions"].string.contains(locale));XCTAssertEqual(transport.sent.first?["item"]["content"].array.first?["text"].string,"[NARRATE THIS TEXT EXACTLY]: Yo  …  pan.")
        }
    }
    func testScopeChangeRejectsOldRequestsAndLateCallbacks()async throws{
        let transport=LessonNarrationTransport(),audio=LessonAudioController(narration:RealtimeNarrationService(factory:{transport})),engine=try CompanionQuestPolicy();defer{audio.clear()}
        audio.bind("first");audio.play("hola",language:"es",owner:"first",engine:engine);try await ready(transport);let late=transport.onEvent
        audio.bind("second");XCTAssertTrue(transport.closed);late?(.object(["type":.string("output_audio_buffer.started")]));XCTAssertFalse(audio.playing);XCTAssertFalse(audio.loading)
        audio.play("old text",language:"es",owner:"first",engine:engine);XCTAssertFalse(audio.loading);XCTAssertEqual(transport.sent.count,2)
        audio.clear();audio.play("departed",language:"es",owner:"second",engine:engine);XCTAssertFalse(audio.loading)
    }
    func testMatchingLoadingToggleAndSpokenTargetRemainVerbatim()async throws{
        let transports=[LessonNarrationTransport(),LessonNarrationTransport()];var index=0
        let narration=RealtimeNarrationService(factory:{let result=transports[index];index+=1;return result}),audio=LessonAudioController(narration:narration),engine=try CompanionQuestPolicy();defer{audio.clear()}
        audio.bind("match");audio.play("casa___",language:"es",owner:"match",wordIndex:0,engine:engine);try await ready(transports[0]);XCTAssertEqual(transports[0].sent.first?["item"]["content"].array.first?["text"].string,"[NARRATE THIS TEXT EXACTLY]: casa___");XCTAssertEqual(audio.wordIndex,0);XCTAssertTrue(audio.loading)
        audio.play("casa___",language:"es",owner:"match",wordIndex:0,engine:engine);XCTAssertFalse(audio.loading);XCTAssertTrue(transports[0].closed);XCTAssertEqual(index,1)
        audio.bind("spoken");audio.play("  ___ hola  ",language:"es",owner:"spoken",spokenCard:true,engine:engine);try await ready(transports[1]);XCTAssertEqual(transports[1].sent.first?["item"]["content"].array.first?["text"].string,"[NARRATE THIS TEXT EXACTLY]: ___ hola")
        audio.play("another answer",language:"es",owner:"spoken",spokenCard:true,ignoreWhileLoading:true,engine:engine);XCTAssertEqual(index,2);XCTAssertFalse(transports[1].closed)
        transports[1].onEvent?(.object(["type":.string("output_audio_buffer.started")]));XCTAssertTrue(audio.playing);XCTAssertFalse(audio.loading)
        transports[1].onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));XCTAssertTrue(audio.playing)
        transports[1].onEvent?(.object(["type":.string("output_audio_buffer.stopped")]));try await Task.sleep(for:.milliseconds(40));XCTAssertFalse(audio.playing);XCTAssertFalse(audio.loading)
    }
    func testFailureAllowsFreshPlaybackAndNeverKeepsBusyState()async throws{
        let transports=[LessonNarrationTransport(),LessonNarrationTransport()];var index=0
        let narration=RealtimeNarrationService(factory:{let result=transports[index];index+=1;return result}),audio=LessonAudioController(narration:narration),engine=try CompanionQuestPolicy();defer{audio.clear()}
        audio.bind("retry");audio.play("hola",language:"es",owner:"retry",engine:engine);try await ready(transports[0]);transports[0].onFailure?("offline");XCTAssertFalse(audio.loading);XCTAssertFalse(audio.playing)
        audio.play("hola",language:"es",owner:"retry",engine:engine);try await ready(transports[1]);XCTAssertTrue(audio.loading);XCTAssertNil(narration.error)
    }
}
