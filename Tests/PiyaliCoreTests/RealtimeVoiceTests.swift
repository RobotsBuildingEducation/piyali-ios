import XCTest
@testable import PiyaliCore

final class RealtimeVoiceTests:XCTestCase {
    private func event(_ json:String) throws ->JSONValue { try JSONDecoder().decode(JSONValue.self,from:Data(json.utf8)) }
    func testLateInputTranscriptKeepsAnsweredQuestionAndDeliversExactlyOnce() throws {
        var state=RealtimeVoiceState(previousAssistant:"¿Qué quieres beber?")
        for raw in [#"{"type":"input_audio_buffer.speech_started"}"#,#"{"type":"input_audio_buffer.committed","item_id":"u1"}"#,#"{"type":"response.created","response":{"id":"r1"}}"#,#"{"type":"response.output_audio_transcript.delta","response_id":"r1","delta":"Un café. "}"#,#"{"type":"response.output_audio_transcript.done","response_id":"r1","transcript":"Un café. ¿Algo más?"}"#,#"{"type":"response.done","response":{"id":"r1","status":"completed"}}"#] { XCTAssertTrue(state.receive(try event(raw)).isEmpty) }
        XCTAssertEqual(state.assistantText,"Un café. ¿Algo más?");XCTAssertFalse(state.microphoneEnabled,"Generation completion is earlier than audible playback completion.")
        let input=try event(#"{"type":"conversation.item.input_audio_transcription.completed","item_id":"u1","transcript":"Un café, por favor."}"#)
        let turn=try XCTUnwrap(state.receive(input).first)
        XCTAssertEqual(turn.text,"Un café, por favor.");XCTAssertEqual(turn.answered,"¿Qué quieres beber?");XCTAssertEqual(turn.reply,"Un café. ¿Algo más?")
        XCTAssertEqual(state.transcript,"You: Un café, por favor.\nPiyali: Un café. ¿Algo más?")
        XCTAssertTrue(state.receive(input).isEmpty);XCTAssertTrue(state.receive(try event(#"{"type":"response.done","response":{"id":"r1"}}"#)).isEmpty)
        _=state.receive(try event(#"{"type":"output_audio_buffer.stopped"}"#));XCTAssertTrue(state.microphoneEnabled)
    }
    func testIncompleteAudioStillWaitsForPlaybackBeforeOpeningTheMicrophone() throws {
        var state=RealtimeVoiceState()
        _=state.receive(try event(#"{"type":"response.created","response":{"id":"r1"}}"#))
        _=state.receive(try event(#"{"type":"response.done","response":{"id":"r1","status":"incomplete"}}"#))
        XCTAssertFalse(state.microphoneEnabled)
        _=state.receive(try event(#"{"type":"output_audio_buffer.stopped"}"#));XCTAssertTrue(state.microphoneEnabled)
    }
    func testMuteSurvivesPlaybackStopAndCancelledResponseUnlocksWithoutDuplicatingTurns() throws {
        var state=RealtimeVoiceState();state.setMuted(true)
        _=state.receive(try event(#"{"type":"input_audio_buffer.committed","item_id":"u1"}"#))
        _=state.receive(try event(#"{"type":"conversation.item.input_audio_transcription.completed","item_id":"u1","transcript":"Hola"}"#))
        _=state.receive(try event(#"{"type":"response.created","response":{"id":"r1"}}"#))
        let turns=state.receive(try event(#"{"type":"response.done","response":{"id":"r1","status":"cancelled"}}"#))
        XCTAssertEqual(turns.count,1);XCTAssertFalse(state.assistantLocked);XCTAssertFalse(state.microphoneEnabled)
        _=state.receive(try event(#"{"type":"output_audio_buffer.stopped"}"#));XCTAssertFalse(state.microphoneEnabled)
        state.setMuted(false);XCTAssertTrue(state.microphoneEnabled)
    }
    func testInitialAssistantResponseIsNotLearnerSpeechAndNextTurnAnswersItsFinalText() throws {
        var state=RealtimeVoiceState()
        for raw in [#"{"type":"response.created","response":{"id":"opening"}}"#,#"{"type":"response.audio_transcript.delta","response_id":"opening","delta":"Hola. "}"#,#"{"type":"response.output_text.delta","response_id":"opening","delta":"Hola. "}"#,#"{"type":"response.done","response":{"id":"opening","status":"completed","output":[{"content":[{"transcript":"Hola. ¿Cómo estás?"}]}]}}"#] { XCTAssertTrue(state.receive(try event(raw)).isEmpty) }
        _=state.receive(try event(#"{"type":"output_audio_buffer.stopped"}"#))
        _=state.receive(try event(#"{"type":"input_audio_buffer.speech_started"}"#));_=state.receive(try event(#"{"type":"input_audio_buffer.committed","item_id":"u2"}"#))
        _=state.receive(try event(#"{"type":"conversation.item.input_audio_transcription.completed","item_id":"u2","transcript":"Bien, gracias."}"#))
        _=state.receive(try event(#"{"type":"response.created","response":{"id":"r2"}}"#))
        let turns=state.receive(try event(#"{"type":"response.done","response":{"id":"r2","status":"completed","output":[{"content":[{"transcript":"¡Muy bien!"}]}]}}"#))
        XCTAssertEqual(turns.first?.answered,"Hola. ¿Cómo estás?");XCTAssertEqual(turns.first?.reply,"¡Muy bien!")
    }
    @MainActor func testOriginalConversationPolicyKeepsLanguagePersonaGoalAndPrivateResumeContext() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let p:JSONValue = .object(["targetLang":.string("es"),"personality":.string("A dramatic pirate"),"pronunciation":.bool(true),"interests":.string("coffee"),"goal":.object(["text":.object(["en":.string("Ask the price of a coffee")]),"completed":.bool(false)]),"guidance":.string("Ask rather than describe"),"messages":.array([.object(["role":.string("assistant"),"textFinal":.string("¿Qué quieres saber?")])])])
        let prompt=try recipes.conversation("instructions",parameters:p)
        for text in ["Responde ÚNICAMENTE en español","Pre-A1","A dramatic pirate","PRONUNCIATION PRACTICE MODE","Ask the price of a coffee","Ask rather than describe","≤25 words","do not restart or greet","¿Qué quieres saber?"] { XCTAssertTrue(prompt.contains(text),text) }
        XCTAssertFalse(prompt.contains("undefined"))
        let response=try JSONDecoder().decode(JSONValue.self,from:Data(recipes.conversation("response",parameters:p).utf8))
        XCTAssertEqual(response["type"].string,"response.create");XCTAssertTrue(response["response"]["instructions"].string.contains("FINAL STYLE REQUIREMENT"))
        let vad=try JSONDecoder().decode(JSONValue.self,from:Data(recipes.conversation("vad",parameters:p).utf8))
        XCTAssertEqual(vad,RealtimeVoicePolicy.vad(manualResponse:true))
    }
}
