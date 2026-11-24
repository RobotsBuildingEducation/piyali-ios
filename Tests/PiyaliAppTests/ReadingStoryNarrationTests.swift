import XCTest
@testable import Piyali

@MainActor final class ReadingStoryNarrationTests:XCTestCase {
    private func ready(_ t:LessonNarrationTransport)async throws{for _ in 0..<100 where t.sent.isEmpty{try await Task.sleep(for:.milliseconds(2))};XCTAssertFalse(t.sent.isEmpty)}
    private func complete(_ t:LessonNarrationTransport)async throws{t.onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));t.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]));try await Task.sleep(for:.milliseconds(40))}
    func testOriginalReadingAndCharacterRequestsAndSessions()throws{
        let policy=try ReadingStoryNarrationPolicy(),url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"reading-story-narration",withExtension:"json")),cases=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url)).array
        XCTAssertEqual(cases.count,287)
        for row in cases{XCTAssertEqual(try policy.request(row["operation"].string,row["input"]),row["output"])}
    }
    func testNativeStoryUsesOriginalCharacterVoicePersonalityAndPlaybackCallbacks()async throws{
        let t=LessonNarrationTransport(),audio=NativeStoryAudio(narration:RealtimeNarrationService(factory:{t}));defer{audio.stop()};var started=0,finished=0,failed=0
        audio.play(.init(speaker:"Sheilfer",target:"Hola."),language:"es",started:{started+=1},finished:{finished+=1},failed:{failed+=1});try await ready(t)
        XCTAssertEqual(t.microphone,[false]);XCTAssertEqual(t.session["audio"]["output"]["voice"].string,"echo");XCTAssertTrue(t.session["instructions"].string.contains("relaxed but confident"));XCTAssertTrue(t.session["instructions"].string.contains("es-MX"))
        t.onEvent?(.object(["type":.string("output_audio_buffer.started")]));t.onEvent?(.object(["type":.string("output_audio_buffer.started")]));XCTAssertEqual(started,1)
        t.onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));try await Task.sleep(for:.milliseconds(40));XCTAssertEqual(finished,0)
        t.onEvent?(.object(["type":.string("output_audio_buffer.stopped")]));try await Task.sleep(for:.milliseconds(40));XCTAssertEqual(finished,1);XCTAssertEqual(failed,0)
    }
    func testStoryQueueAndLearnerVoicePreviewWaitForActualPlayout()async throws{
        let main=[LessonNarrationTransport(),LessonNarrationTransport()],preview=LessonNarrationTransport();var index=0,done=0
        let player=NativeStoryAudio(narration:RealtimeNarrationService(factory:{let t=main[index];index+=1;return t})),previewPlayer=NativeStoryAudio(narration:RealtimeNarrationService(factory:{preview})),audio=StoryPlaybackService(player:player,previewPlayer:previewPlayer),user:JSONValue = .object(["name":.string("Alicia"),"progress":.object(["voice":.string("marin")])]);defer{audio.cancel()}
        let turns:[StoryTurn]=[.init(speaker:"Jiraiya",target:"Hola."),.init(speaker:"You",target:"Buenos días."),.init(speaker:"Neko",target:"Vamos.")]
        audio.start(turns,language:"es",learnerName:"Alicia",user:user){done+=1};try await ready(main[0]);XCTAssertEqual(audio.phase,.loading);XCTAssertEqual(main[0].session["audio"]["output"]["voice"].string,"ash")
        main[0].onEvent?(.object(["type":.string("output_audio_buffer.started")]));XCTAssertEqual(audio.phase,.playing);try await complete(main[0]);XCTAssertEqual(audio.phase,.awaitingSpeech);XCTAssertEqual(done,0)
        audio.preview(turns[1],language:"es",user:user);try await ready(preview);XCTAssertEqual(preview.session["audio"]["output"]["voice"].string,"marin");try await complete(preview);XCTAssertEqual(audio.phase,.awaitingSpeech);XCTAssertEqual(done,0)
        audio.continueSpeech();try await ready(main[1]);XCTAssertEqual(main[1].session["audio"]["output"]["voice"].string,"sage");try await complete(main[1]);XCTAssertEqual(done,1)
    }
    func testStoryTransportFailureIsOnceOnlyAndStopRejectsLateStart()async throws{
        let t=LessonNarrationTransport(),audio=NativeStoryAudio(narration:RealtimeNarrationService(factory:{t}));defer{audio.stop()};var starts=0,ends=0,failures=0
        audio.play(.init(speaker:"Yoruichi",target:"Hello."),language:"en",started:{starts+=1},finished:{ends+=1},failed:{failures+=1});try await ready(t);let late=t.onEvent,failure=t.onFailure
        failure?("offline");failure?("late");late?(.object(["type":.string("output_audio_buffer.started")]));XCTAssertEqual(failures,1);XCTAssertEqual(starts,0);XCTAssertEqual(ends,0)
    }
    func testReadingSentenceReplacementAndStopRejectOldCompletion()async throws{
        let transports=[LessonNarrationTransport(),LessonNarrationTransport()];var index=0
        let audio=ReadingPlaybackService(narration:RealtimeNarrationService(factory:{let t=transports[index];index+=1;return t}));defer{audio.stop()}
        audio.play("Una mañana tranquila.",language:"es");try await ready(transports[0]);XCTAssertTrue(audio.readingAll);XCTAssertTrue(audio.loading);XCTAssertNil(audio.activeSentence)
        let late=transports[0].onEvent;audio.play("مرحباً",language:"ar",sentence:2);try await ready(transports[1]);XCTAssertTrue(transports[0].closed);XCTAssertFalse(audio.readingAll);XCTAssertEqual(audio.activeSentence,2);XCTAssertTrue(transports[1].session["instructions"].string.contains("ar-EG"));XCTAssertEqual(transports[1].session["audio"]["output"]["voice"].string,"ash")
        late?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));late?(.object(["type":.string("output_audio_buffer.stopped")]));XCTAssertEqual(audio.activeSentence,2)
        audio.stop();transports[1].onEvent?(.object(["type":.string("output_audio_buffer.started")]));XCTAssertNil(audio.activeSentence);XCTAssertFalse(audio.loading)
    }
    func testReadingFailureAndPlayoutBothClearSelectionAndAllowRetry()async throws{
        let ts=[LessonNarrationTransport(),LessonNarrationTransport()];var index=0
        let audio=ReadingPlaybackService(narration:RealtimeNarrationService(factory:{let t=ts[index];index+=1;return t}));defer{audio.stop()}
        audio.play("Hello.",language:"en",sentence:0);try await ready(ts[0]);ts[0].onFailure?("offline");XCTAssertNil(audio.activeSentence);XCTAssertFalse(audio.loading)
        audio.play("Hello again.",language:"en");try await ready(ts[1]);XCTAssertTrue(audio.readingAll);try await complete(ts[1]);XCTAssertFalse(audio.readingAll);XCTAssertFalse(audio.loading)
    }
}
