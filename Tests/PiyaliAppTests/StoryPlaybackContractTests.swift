import XCTest
@testable import Piyali

@MainActor final class StoryPlaybackContractTests:XCTestCase {
    private final class Player:StoryAudioTransport {
        struct Call { let turn:StoryTurn;let started:()->Void;let finished:()->Void;let failed:()->Void }
        var calls:[Call]=[]
        func play(_ turn:StoryTurn,language:String,started:@escaping()->Void,finished:@escaping()->Void,failed:@escaping()->Void) { calls.append(.init(turn:turn,started:started,finished:finished,failed:failed)) }
        func stop() {}
        func complete(_ index:Int) { calls[index].started();calls[index].finished() }
    }
    private func turn(_ speaker:String,_ text:String)->StoryTurn { .init(speaker:speaker,target:text,support:nil) }
    func testCancelledAndReplacedPlaybackCannotUnlockAQuestionFromLateCallbacks() {
        let player=Player(),preview=Player(),audio=StoryPlaybackService(player:player,previewPlayer:preview)
        var completions=0
        audio.start([turn("Ana","Hola")],language:"es",learnerName:"") { completions += 1 }
        audio.cancel();player.complete(0);XCTAssertEqual(completions,0);XCTAssertEqual(audio.phase,.idle)
        audio.start([turn("Luis","Buenos días")],language:"es",learnerName:"") { completions += 1 }
        player.calls[0].finished();XCTAssertEqual(completions,0);XCTAssertEqual(audio.currentTurn?.speaker,"Luis")
        player.complete(1);XCTAssertEqual(completions,1);player.calls[1].finished();XCTAssertEqual(completions,1);audio.cancel()
    }
    func testUserLineAndItsPreviewWaitForContinueAndTheRestOfTheQueue() {
        let player=Player(),preview=Player(),audio=StoryPlaybackService(player:player,previewPlayer:preview)
        let values=[turn("Ana","Hola"),turn("You","Buenos días"),turn("Ana","Vamos")];var completions=0
        audio.start(values,language:"es",learnerName:"") { completions += 1 };player.complete(0)
        XCTAssertEqual(audio.phase,.awaitingSpeech);XCTAssertEqual(audio.roleIndex,1);XCTAssertEqual(completions,0)
        audio.preview(values[0],language:"es");preview.complete(0);XCTAssertEqual(audio.phase,.awaitingSpeech);XCTAssertEqual(completions,0)
        audio.continueSpeech();XCTAssertEqual(player.calls.count,2);XCTAssertEqual(audio.currentTurn?.target,"Vamos");XCTAssertEqual(completions,0)
        player.calls[0].finished();XCTAssertEqual(completions,0);player.complete(1);XCTAssertEqual(completions,1)
        audio.start(values,language:"es",learnerName:"",replay:true) { completions += 1 };player.complete(2);XCTAssertEqual(player.calls[3].turn.speaker,"Ana");player.complete(3);XCTAssertEqual(completions,2);audio.cancel()
    }
    func testContextReplayKeepsTheMainQueuePausedAndIgnoresReplacedPreviewCallbacks() {
        let player=Player(),preview=Player(),audio=StoryPlaybackService(player:player,previewPlayer:preview)
        let values=[turn("Ana","Hola"),turn("You","Buenas"),turn("Ana","Vamos"),
                    turn("You","Sí"),turn("Ana","Adiós")]
        var completions=0
        audio.start(values,language:"es",learnerName:"") { completions += 1 }
        player.complete(0)
        audio.continueSpeech()
        player.complete(1)
        XCTAssertEqual(audio.roleIndex,3)

        XCTAssertTrue(audio.replaySpeechContext(user:.null))
        XCTAssertEqual(preview.calls.map(\.turn.target),["Hola"])
        preview.complete(0)
        XCTAssertEqual(preview.calls.map(\.turn.target),["Hola","Vamos"])
        preview.calls[0].finished()
        XCTAssertEqual(preview.calls.count,2)
        XCTAssertEqual(audio.phase,.awaitingSpeech)
        XCTAssertEqual(audio.currentTurn?.target,"Sí")
        XCTAssertEqual(completions,0)

        XCTAssertTrue(audio.replaySpeechContext(user:.null))
        preview.calls[1].failed()
        XCTAssertFalse(audio.previewError)
        XCTAssertEqual(audio.previewTurn?.target,"Hola")
        audio.continueSpeech()
        preview.complete(2)
        XCTAssertFalse(audio.previewPlaying)
        XCTAssertEqual(preview.calls.count,3)
        XCTAssertEqual(player.calls.last?.turn.target,"Adiós")
        player.complete(2)
        XCTAssertEqual(completions,1)
    }

    func testContextReplayWithNoEarlierCharacterPlaysTheLearnerModelWithoutUnlocking() {
        let player=Player(),preview=Player(),audio=StoryPlaybackService(player:player,previewPlayer:preview)
        var completions=0
        audio.start([turn("You","Hola")],language:"es",learnerName:"") { completions += 1 }
        XCTAssertTrue(audio.replaySpeechContext(user:.null))
        XCTAssertEqual(preview.calls.first?.turn.target,"Hola")
        preview.complete(0)
        XCTAssertEqual(audio.phase,.awaitingSpeech)
        XCTAssertEqual(completions,0)
        audio.continueSpeech()
        XCTAssertEqual(completions,1)
    }

    func testTransportFailureAndLateSuccessDoNotUnlockButExplicitRetryCanFinish() {
        let player=Player(),preview=Player(),audio=StoryPlaybackService(player:player,previewPlayer:preview);var completions=0
        audio.start([turn("Ana","Hola")],language:"es",learnerName:"") { completions += 1 };player.calls[0].failed()
        XCTAssertEqual(audio.phase,.failed);player.complete(0);XCTAssertEqual(completions,0)
        audio.start([turn("Ana","Hola")],language:"es",learnerName:"") { completions += 1 };player.complete(1);XCTAssertEqual(completions,1);audio.cancel()
    }
}
