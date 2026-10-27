import Foundation

/// The source writing exercises submit a completed speech transcript once, through the normal judge.
@MainActor final class WritingSpeechController:ObservableObject {
    let recorder:SpeechPracticeService
    private var owner="",policy:FlashcardPolicy?,submission:Task<Void,Never>?
    init(recorder:SpeechPracticeService?=nil){self.recorder=recorder ?? WritingSpeechFixture.recorder()}
    private func scope(_ app:AppModel,_ run:PracticeRun)->String{[app.identity.npub,app.learner.target,app.learner.support,run.question.id.uuidString].joined(separator:"|")}
    func bind(_ app:AppModel,run:PracticeRun){let next=scope(app,run);guard next != owner else{return};clear();owner=next}
    func clear(){submission?.cancel();submission=nil;recorder.cancel();recorder.clearError();owner=""}
    func stop(){recorder.stop()}
    func toggle(_ app:AppModel,run:PracticeRun,service:PracticeService){
        guard WritingPracticeQuestion.variants.contains(run.question.variant),!service.busy,app.subscription.hasAccess,app.learner.practiceRuns?[run.key]?.question.id == run.question.id,run.correct != true,!(run.question.options["isFinalQuiz"].boolean && run.correct != nil)else{return}
        bind(app,run:run);if recorder.recording{recorder.stop();return};guard !recorder.connecting,!recorder.evaluating else{return}
        var current=run;current.correct=nil;app.learner.savePractice(current);app.persist()
        #if DEBUG
        WritingSpeechFixture.prepare(run)
        #endif
        do{if policy == nil{policy=try FlashcardPolicy()};let captured=owner
            recorder.start(target:run.question.target,policy:policy!,timeoutMs:2000){[weak self] text in
                guard let self,self.owner == captured,self.scope(app,run) == captured,app.subscription.hasAccess,var current=app.learner.practiceRuns?[run.key],current.question.id == run.question.id,current.correct != true else{return}
                current.response=WritingExerciseRules.response(current.response,text:text,variant:run.question.variant);current.correct=nil;app.learner.savePractice(current);app.persist()
                self.submission=Task{await service.check(app,run:current)}
            }
        }catch{recorder.reportError(error.localizedDescription)}
    }
}
