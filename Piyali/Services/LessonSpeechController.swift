import Foundation
import Combine

/// Source speaking/lesson-card capture: no expected-answer ASR hint; completed transcripts grade once.
@MainActor final class LessonSpeechController:ObservableObject {
    let recorder:SpeechPracticeService
    private var owner="",policy:FlashcardPolicy?,submission:Task<Void,Never>?,changes:AnyCancellable?
    init(recorder:SpeechPracticeService?=nil){self.recorder=recorder ?? LessonSpeechFixture.recorder();changes=self.recorder.objectWillChange.sink{[weak self] in self?.objectWillChange.send()}}
    private func scope(_ app:AppModel,_ run:PracticeRun)->String{[app.identity.npub,app.learner.target,app.learner.support,run.question.id.uuidString].joined(separator:"|")}
    func bind(_ app:AppModel,run:PracticeRun){let next=scope(app,run);guard next != owner else{return};clear();owner=next}
    func clear(){submission?.cancel();submission=nil;recorder.cancel();recorder.clearError();owner=""}
    func toggle(_ app:AppModel,run:PracticeRun,service:PracticeService){
        guard ["speak","flashcard"].contains(run.question.kind),!service.busy,app.subscription.hasAccess,app.learner.practiceRuns?[run.key]?.question.id == run.question.id,run.correct != true,!(run.question.options["isFinalQuiz"].boolean && run.correct != nil)else{return}
        bind(app,run:run);if recorder.recording{recorder.stop();return};guard !recorder.connecting,!recorder.evaluating else{return}
        var current=run;current.correct=nil;current.lastMissedAnswer=nil;current.response=current.response.setting("recognizedText",.string(""));app.learner.savePractice(current);app.persist()
        #if DEBUG
        LessonSpeechFixture.prepare(run)
        #endif
        do{if policy == nil{policy=try FlashcardPolicy()};let captured=owner
            recorder.start(target:run.question.target,policy:policy!,timeoutMs:2000){[weak self] text in
                guard let self,self.owner == captured,self.scope(app,run) == captured,app.subscription.hasAccess,var current=app.learner.practiceRuns?[run.key],current.question.id == run.question.id,current.correct != true,!(current.question.options["isFinalQuiz"].boolean && current.correct != nil)else{return}
                current.response=current.response.setting("text",.string(text)).setting("recognizedText",.string(text)).setting("inputSource",.string("speech"));current.correct=nil;app.learner.savePractice(current);app.persist()
                self.submission=Task{await service.check(app,run:current,confidence:0.9)}
            }
        }catch{recorder.reportError(error.localizedDescription)}
    }
}
@MainActor enum LessonSpeechFixture {
    static func recorder()->SpeechPracticeService {
        #if DEBUG
        if enabled{return SpeechPracticeService(transportFactory:{LessonFixtureTransport()},permission:{true})}
        #endif
        return SpeechPracticeService()
    }
    #if DEBUG
    static var reference="",captures=0
    private static var enabled:Bool{let e=ProcessInfo.processInfo.environment;return e["PIYALI_OFFLINE_TESTS"] == "1" && e["PIYALI_LIVE_API_TESTS"] != "1" && e["PIYALI_LESSON_SPEECH_FIXTURE"] == "wrong-then-reference" && UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil}
    static func prepare(_ run:PracticeRun){guard enabled else{return};reference=run.question.kind == "speak" ? run.question.payload["target"].string:run.question.payload["answer"].string}
    #endif
}
#if DEBUG
@MainActor private final class LessonFixtureTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private var work:Task<Void,Never>?
    func connect(session:JSONValue)async throws{onOpen?()}
    func send(_ event:JSONValue)->Bool{true}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func setMicrophoneEnabled(_ enabled:Bool){guard enabled else{return};LessonSpeechFixture.captures+=1;let text=LessonSpeechFixture.captures == 1 ? "WRONG_FIXTURE":LessonSpeechFixture.reference
        work=Task{try? await Task.sleep(for:.milliseconds(300));guard !Task.isCancelled else{return};onEvent?(.object(["type":.string("conversation.item.input_audio_transcription.completed"),"transcript":.string(text)]));onEvent?(.object(["type":.string("response.done")]))}}
    func close(){work?.cancel()}
}
#endif
