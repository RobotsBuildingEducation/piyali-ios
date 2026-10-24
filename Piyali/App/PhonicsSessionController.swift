import Foundation
import Combine

@MainActor final class PhonicsSessionController:ObservableObject {
    let id=UUID(),card:JSONValue,collects:Bool,account,target,support:String,goal:JSONValue?,repair:RepairStep?,policy:PhonicsPolicy,provider:PhonicsProvider
    @Published private(set) var practicing=false
    @Published private(set) var flipped=false
    @Published private(set) var grading=false
    @Published private(set) var saving=false
    @Published private(set) var grade:PhonicsGrade?
    @Published private(set) var correctCount:Int
    @Published private(set) var error:String?
    @Published private(set) var transcript=""
    let recorder:SpeechPracticeService
    let playback:RealtimeNarrationService
    @Published private(set) var playingKind:String?
    private var subscriptions:Set<AnyCancellable>=[]
    private var generation=UUID(),work:Task<Void,Never>?,quote:Task<JSONValue,Error>?,submitted=false,closed=false
    init(app:AppModel,card:JSONValue,correctCount:Int=0,collects:Bool=true,goal:JSONValue?=nil,repair:RepairStep?=nil,provider:PhonicsProvider?=nil,recorder:SpeechPracticeService?=nil,playback:RealtimeNarrationService?=nil)throws {
        self.card=card;self.collects=collects;self.correctCount=correctCount;self.goal=goal;self.repair=repair;account=app.identity.npub;target=app.learner.target;support=app.learner.support;policy=try PhonicsPolicy(engine:app.companionQuestPolicy);self.provider=provider ?? .native(app.ai);self.recorder=recorder ?? PhonicsSpeechFixture.recorder();self.playback=playback ?? RealtimeNarrationService()
        self.recorder.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}.store(in:&subscriptions);self.playback.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}.store(in:&subscriptions)
    }
    var focused:Bool {goal != nil || repair != nil}
    var busy:Bool {grading || saving}
    var needsSaveRetry:Bool {submitted && focused && error != nil}
    func text(_ key:String)->String {policy.copy(key,language:support,target:target)}
    func matches(_ app:AppModel)->Bool {
        guard !closed,account == app.identity.npub,target == app.learner.target,support == app.learner.support else{return false}
        if let goal{return app.goalIsCurrent(goal)}
        if let repair {let plan=app.learner.repairPlan(day:repair.day);return repair.day == CalendarDay.key(Date()) && plan?["items"].array.indices.contains(repair.index) == true && plan?["items"].array[repair.index] == repair.item}
        return true
    }
    func practice(_ app:AppModel){guard matches(app),!busy else{return};practicing=true;flipped=true;grade=nil;error=nil;submitted=false;startQuote(app)}
    func back(){flipped=false;practicing=false;grade=nil;error=nil;submitted=false;transcript=""}
    func retry(){guard !busy,!needsSaveRetry else{return};grade=nil;error=nil;submitted=false;transcript=""}
    private func startQuote(_ app:AppModel){if quote == nil{let provider=self.provider,card=self.card,state=app.learner;quote=Task{try await provider.quote(card,state)}}}
    func submit(_ text:String,app:AppModel){
        guard matches(app),!busy,grade == nil,!text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return};startQuote(app);grading=true;error=nil;transcript=text;let token=generation
        work=Task{defer{if generation == token{grading=false}};do {
            let prompt=try policy.run("ph_judge",.object(["practiceWord":card["practiceWord"],"phoneme":card["phoneme"],"userAnswer":.string(text),"targetLang":.string(target),"cefrLevel":card["cefrLevel"]])).string
            let verdict=try policy.grade(await provider.judge(prompt));try Task.checkCancellation();guard matches(app),token == generation else{return}
            let worth:JSONValue
            if let quoted=try? await quote?.value{worth=quoted}else{worth=try GeneratedQuestionWorth.fallback(level:card["cefrLevel"].string,learner:app.learner,recipes:PracticeRecipes())}
            try Task.checkCancellation();guard matches(app),token == generation else{return}
            app.learner.assess(correct:verdict.correct,independent:false,questionLevel:card["cefrLevel"].string,worth:worth,concept:card["practiceWord"].string,mode:"phonics",support:"modeled")
            if !verdict.correct,goal == nil {app.learner.captureMemory(mode:"phonics",concept:card["practiceWord"].string,answer:text,expected:card["practiceWord"].string,feedback:"",questionLevel:card["cefrLevel"].string,sourceContext:.object(["card":card]))}
            let attempt=app.learner.attemptPhonics(card:card,grade:verdict,focused:focused)
            if let goal {
                let payload=goal.setting("mode",.string("phonics")).setting("cardID",card["id"]).setting("success",.bool(verdict.correct)).setting("support",.string("modeled")).setting("item",card["practiceWord"]).setting("transfer",.bool(card["practiceRole"].string == "transfer")).setting("externalReward",.bool(true))
                app.learner.applyGoal(GoalChange(action:.outcome,target:target,payload:payload))
            }else if let repair {
                let artifact=app.learner.repairArtifact(repair,mode:"phonics"),outcome:JSONValue = .object(["success":.bool(verdict.correct),"support":.string("modeled"),"item":card["practiceWord"],"transfer":.bool(card["practiceRole"].string == "transfer"),"iosAttemptID":.string(attempt.uuidString),"iosUpdatedAt":.string(WebProgressContract.iso(Date()))])
                app.learner.storeRepairArtifact(artifact.setting("outcomes",artifact["outcomes"].setting(card["id"].string,outcome)),step:repair,mode:"phonics")
            }
            submitted=true;grade=verdict;if verdict.correct{correctCount += 1};app.persist()
            if focused {saving=true;defer{saving=false};try await app.finishPhonicsFocus(goal:goal,repair:repair)}
        }catch is CancellationError{}catch{if generation == token,matches(app){self.error=self.text("gradingErrorDescription")}}}
    }
    func retrySave(_ app:AppModel){guard needsSaveRetry,!busy,matches(app) else{return};saving=true;error=nil;let token=generation
        work=Task{defer{saving=false};do{try await app.finishPhonicsFocus(goal:goal,repair:repair)}catch is CancellationError{}catch{if generation == token,matches(app){self.error=self.text("gradingErrorDescription")}}}
    }
    func record(_ app:AppModel){
        guard matches(app),!busy else{return};playback.stopAll();playingKind=nil
        if recorder.recording || recorder.evaluating{recorder.stop();return}
        retry()
        do{let policy=try FlashcardPolicy(engine:app.companionQuestPolicy),pause=Int(app.learner.plateProgress["pauseMs"].number)
            recorder.start(target:target,policy:policy,transcriptionHint:card["practiceWord"].string,timeoutMs:pause>0 ? pause:2000){[weak self,weak app] text in guard let self,let app else{return};self.submit(text,app:app)}
        }catch{self.error=text("gradingErrorDescription")}
    }
    func speak(_ kind:String,app:AppModel){
        guard matches(app) else{return};recorder.cancel()
        if playingKind == kind && (playback.loading || playback.playing){playback.stopAll();playingKind=nil;return}
        playingKind=kind;playback.play(kind == "letter" ? card["tts"].string:card["practiceWord"].string,language:target,engine:app.companionQuestPolicy){[weak self] in self?.playingKind=nil}
    }
    func stopAudio(){recorder.cancel();playback.stopAll();playingKind=nil}
    func cancel(){stopAudio();closed=true;generation=UUID();work?.cancel();quote?.cancel()}
}

extension AppModel {
    /// Focused pronunciation waits for the saved outcome/XP before dependent completion.
    func finishPhonicsFocus(goal:JSONValue?,repair:RepairStep?)async throws {
        let account=identity.npub,target=learner.target,support=learner.support
        await sync();try Task.checkCancellation();guard account == identity.npub,target == learner.target,support == learner.support else{throw CancellationError()}
        let hasAttempt=(learner.pendingChanges ?? []).contains{$0.source == .phonicsAttempt && $0.target == target && $0.phonicsData?["focused"].boolean == true}
        if hasAttempt {throw AppError.message("Could not save pronunciation. Please try again.")}
        if let goal {
            guard goalIsCurrent(goal) else{throw CancellationError()}
            guard !(learner.pendingGoalChanges ?? []).contains(where:{$0.target == target && $0.payload["goalId"] == goal["goalId"]}) else{throw AppError.message("Could not save pronunciation. Please try again.")}
            let artifact=goalArtifact(goal,mode:"phonics"),required=Array(artifact["cards"].array.prefix(2))
            if required.count == 2,required.allSatisfy({artifact["outcomes"][$0["id"].string]["success"].boolean}),(readyGoal?["modeProgress"]["phonics"].number ?? 0)<2 {
                recordGoalAttempt(goal,mode:"phonics",success:true,support:"modeled",observation:required.map{$0["practiceWord"].string+" pronounced successfully after a model"}.joined(separator:"; "),domain:"pronunciation")
                await sync();try Task.checkCancellation();guard account == identity.npub,target == learner.target else{throw CancellationError()}
                guard (readyGoal?["modeProgress"]["phonics"].number ?? 0)>=2 else{throw AppError.message("Could not finish pronunciation. Please try again.")}
            }
        }else if let repair {
            let field=CompanionQuestDay.artifactField(repair,mode:"phonics"),key=CompanionQuestDay.key(target,repair.day)
            guard (learner.pendingCompanionQuestDays?[key]?[field] ?? .null) == .null else{throw AppError.message("Could not save pronunciation. Please try again.")}
            checkRepairPracticeCompletion(repair,mode:"phonics");await sync();try Task.checkCancellation();guard account == identity.npub,target == learner.target else{throw CancellationError()}
            guard !(learner.pendingRepairEvidence ?? []).contains(where:{$0.target == target && $0.event["dayKey"].string == repair.day}),!(learner.pendingChanges ?? []).contains(where:{$0.source == .repair && $0.target == target && $0.dayKey == repair.day}) else{throw AppError.message("Could not finish pronunciation. Please try again.")}
        }
    }
}
