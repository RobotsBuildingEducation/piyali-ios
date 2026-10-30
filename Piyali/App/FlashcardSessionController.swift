import Foundation
import Combine

@MainActor final class FlashcardSessionController:ObservableObject,Identifiable {
    let id=UUID(),scope:FlashcardScope,card:JSONValue,progress:FlashcardReview,languageXP:Int,practiceStatus:String
    let goal:JSONValue?,repair:RepairStep?
    let policy:FlashcardPolicy,provider:FlashcardProvider
    let openedAt=Date()
    @Published var answer=""
    @Published private(set) var recognized=""
    @Published private(set) var grade:FlashcardGrade?
    @Published private(set) var revealed=""
    @Published private(set) var explanation=""
    @Published private(set) var error:String?
    @Published private(set) var grading=false
    private var reviewPreviewBase:Int?
    @Published private(set) var revealing=false
    @Published private(set) var flipped=false
    @Published private(set) var explaining=false
    @Published private(set) var saving=false
    @Published private(set) var noteSaved=false
    @Published private(set) var creatingNote=false
    private var request=UUID(),closed=false,capturedMiss=false,assessedSuccess=false
    private var work:Task<Void,Never>?,revealTask:Task<Void,Never>?,explainTask:Task<Void,Never>?,quoteTask:Task<JSONValue,Error>?
    private var intentRating:ReviewRating?,intentGoalIDs:Set<UUID>=[],intentPracticeIDs:Set<UUID>=[],intentRepairIDs:Set<UUID>=[]
    init(app:AppModel,card:JSONValue,status:String,goal:JSONValue?=nil,repair:RepairStep?=nil,provider:FlashcardProvider?=nil)throws {
        self.card=card;self.goal=goal;self.repair=repair;practiceStatus=status;self.provider=provider ?? .native(app.ai);policy=try FlashcardPolicy(engine:app.companionQuestPolicy)
        scope = .init(account:app.identity.npub,target:app.learner.target,support:app.learner.support,cardID:card["id"].string,goalID:goal?["goalId"].string,day:goal?["dayKey"].string ?? repair?.day)
        var initial=goal != nil || repair != nil ? FlashcardReview():app.learner.cardReviews?[app.learner.completionKey(card["id"].string)] ?? FlashcardReview()
        if goal == nil,repair == nil,app.learner.cardReviews?[app.learner.completionKey(card["id"].string)] == nil,app.learner.flashcardMastery.contains(app.learner.completionKey(card["id"].string)){initial.completed=true;initial.schedulerState = .review;initial.intervalDays=1}
        progress=initial;languageXP=app.learner.xp
        let state=app.learner,provider=self.provider
        quoteTask=Task{try await provider.quote(card,state)}
    }
    var focused:Bool {goal != nil || repair != nil}
    var concept:String {let value=card["concept"][scope.support].string;return value.isEmpty ? card["concept"]["en"].string:value}
    func copy(_ key:String)->String {EntryCopy.ui(scope.support,"flashcard_"+key)}
    func dailyCount(_ app:AppModel)->Int {Int((try? policy.run("flashPreview",.object(["saved":.number(Double(policy.dailyCount(app.learner))),"base":reviewPreviewBase.map{.number(Double($0))} ?? .null])).number) ?? Double(policy.dailyCount(app.learner)))}
    var ratings:[JSONValue] {policy.ratings(progress,now:openedAt)}
    func matches(_ app:AppModel)->Bool {
        guard !closed,scope.account == app.identity.npub,scope.target == app.learner.target,scope.support == app.learner.support else{return false}
        if let goal {return app.goalIsCurrent(goal)}
        if let repair {guard repair.day == CalendarDay.key(Date()),let plan=app.learner.repairPlan(day:repair.day),plan["items"].array.indices.contains(repair.index) else{return false};return plan["items"].array[repair.index] == repair.item}
        return true
    }
    func submit(_ app:AppModel,spoken:String?=nil) {
        let text=spoken ?? answer
        guard !grading,grade == nil,!text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,matches(app) else{return}
        if let spoken {recognized=spoken};grading=true;error=nil;let token=request
        work=Task{defer{if request == token {grading=false}};do {
            let parameters:JSONValue = .object(["concept":.string(concept),"userAnswer":.string(text),"targetLang":.string(scope.target),"supportLang":.string(scope.support),"cefrLevel":card["cefrLevel"]])
            let prompt=try policy.run("flashJudge",parameters,language:scope.support).string
            let raw=try await provider.judge(prompt),verdict=try policy.grade(raw)
            try Task.checkCancellation();guard request == token,matches(app) else{return}
            let worth:JSONValue
            if let quoted=try? await quoteTask?.value {worth=quoted}else{worth=try GeneratedQuestionWorth.fallback(level:card["cefrLevel"].string,learner:app.learner,recipes:PracticeRecipes())}
            try Task.checkCancellation();guard request == token,matches(app) else{return}
            if verdict.correct,!assessedSuccess {assessedSuccess=true;app.learner.assess(correct:true,independent:true,questionLevel:card["cefrLevel"].string,worth:worth,concept:concept,mode:"flashcard",support:"independent");app.persist()}
            else if !verdict.correct,!capturedMiss {capturedMiss=true;app.learner.assess(correct:false,independent:true,questionLevel:card["cefrLevel"].string,worth:worth,concept:concept,mode:"flashcard",support:"independent");capture(app,text:text,context:"flashcards")}
            reviewPreviewBase=verdict.correct && !focused ? policy.dailyCount(app.learner):nil
            grade=verdict
        }catch is CancellationError{}catch{if request == token,matches(app){self.error=copy("grading_error_desc")}}}
    }
    func retry(){guard intentRating == nil else{return};request=UUID();work?.cancel();revealTask?.cancel();explainTask?.cancel();answer="";recognized="";grade=nil;reviewPreviewBase=nil;revealed="";explanation="";flipped=false;grading=false;revealing=false;explaining=false;noteSaved=false;error=nil}
    func flip(_ app:AppModel){
        guard matches(app),!revealing else{return}
        if flipped {revealTask?.cancel();flipped=false;revealed="";return}
        flipped=true;revealing=true;error=nil;let token=request
        revealTask=Task{defer{if token == request{revealing=false}};do{let prompt=try policy.run("flashReveal",.object(["concept":.string(concept),"targetLang":.string(scope.target),"supportLang":.string(scope.support)]),language:scope.support).string
            let final=try await provider.stream(prompt){value in if self.request == token,self.matches(app){self.revealed=value}}
            try Task.checkCancellation();if request == token,matches(app){revealed=final}
        }catch is CancellationError{}catch{if request == token,matches(app){revealed=copy("error_loading")}}}
    }
    func explain(_ app:AppModel){
        guard !explaining,explanation.isEmpty,matches(app),grade?.correct == false else{return};explaining=true;let token=request
        explainTask=Task{defer{if token == request{explaining=false}};do{let prompt=try policy.run("flashExplain",.object(["concept":.string(concept),"answer":.string(answer.isEmpty ? recognized:answer),"targetLang":.string(scope.target),"supportLang":.string(scope.support)]),language:scope.support).string
            let final=try await provider.stream(prompt){value in if self.request == token,self.matches(app){self.explanation=value}}
            try Task.checkCancellation();if request == token,matches(app){explanation=final}
        }catch is CancellationError{}catch{if request == token,matches(app){self.error=copy("grading_error_desc")}}}
    }
    func commit(_ rating:ReviewRating,app:AppModel) {
        guard !saving,let grade,matches(app),intentRating == nil || intentRating == rating else{return};saving=true;error=nil
        work=Task{defer{saving=false};do {
            if intentRating == nil {
                intentRating=rating
                if rating == .again,!capturedMiss {capturedMiss=true;capture(app,text:answer.isEmpty ? recognized:answer,context:"flashcard-again")}
                let value=try policy.run("flashReward",.object(["rating":.string(rating.rawValue),"correct":.bool(grade.correct),"xp":.number(Double(grade.xp)),"focused":.bool(focused)])),success=value["success"].boolean
                let goalBefore=Set((app.learner.pendingGoalChanges ?? []).map(\.id)),practiceBefore=Set((app.learner.pendingChanges ?? []).map(\.id)),repairBefore=Set((app.learner.pendingRepairEvidence ?? []).map(\.id))
                if let goal {app.recordGoalPreparation(goal,mode:"flashcards",card:card,success:success,answer:answer.isEmpty ? recognized:answer,assess:false)}
                else if let repair {app.recordRepairOutcome(repair,mode:"flashcards",cardID:scope.cardID,success:success,item:card["concept"][scope.target].string,deferCompletion:true)}
                else {app.learner.review(cardID:scope.cardID,rating:rating,xp:Int(value["persistedXp"].number),patch:progress.applying(rating,now:openedAt));app.persist()}
                intentGoalIDs=Set((app.learner.pendingGoalChanges ?? []).map(\.id)).subtracting(goalBefore);intentPracticeIDs=Set((app.learner.pendingChanges ?? []).map(\.id)).subtracting(practiceBefore);intentRepairIDs=Set((app.learner.pendingRepairEvidence ?? []).map(\.id)).subtracting(repairBefore)
            }
            if focused {
                await app.sync();try Task.checkCancellation();guard matches(app) else{throw CancellationError()}
                try requireAcknowledgment(app)
                if let repair {
                    let before=Set((app.learner.pendingChanges ?? []).map(\.id)),evidence=Set((app.learner.pendingRepairEvidence ?? []).map(\.id))
                    app.checkRepairPracticeCompletion(repair,mode:"flashcards")
                    intentPracticeIDs.formUnion(Set((app.learner.pendingChanges ?? []).map(\.id)).subtracting(before));intentRepairIDs.formUnion(Set((app.learner.pendingRepairEvidence ?? []).map(\.id)).subtracting(evidence))
                    if !intentPracticeIDs.isEmpty || !intentRepairIDs.isEmpty {await app.sync();try Task.checkCancellation();guard matches(app) else{throw CancellationError()};try requireAcknowledgment(app)}
                }
            }
            close(app,abandoned:false)
        }catch is CancellationError{}catch{self.error=error.localizedDescription}}
    }
    private func requireAcknowledgment(_ app:AppModel)throws {
        let goals=Set((app.learner.pendingGoalChanges ?? []).map(\.id)),practice=Set((app.learner.pendingChanges ?? []).map(\.id)),evidence=Set((app.learner.pendingRepairEvidence ?? []).map(\.id))
        let artifactPending=repair.map{step in (app.learner.pendingCompanionQuestDays?[CompanionQuestDay.key(step.target,step.day)]?[CompanionQuestDay.artifactField(step,mode:"flashcards")] ?? .null) != .null} ?? false
        guard goals.isDisjoint(with:intentGoalIDs),practice.isDisjoint(with:intentPracticeIDs),evidence.isDisjoint(with:intentRepairIDs),!artifactPending else{throw AppError.message("Could not save practice. Please try again.")}
    }
    func createNote(_ app:AppModel){
        guard !creatingNote,!noteSaved,let grade,matches(app) else{return};creatingNote=true;let token=request
        Task{defer{creatingNote=false};do{
            let parameters:JSONValue = .object(["concept":.string(concept),"userAnswer":.string(answer.isEmpty ? recognized:answer),"wasCorrect":.bool(grade.correct),"targetLang":.string(scope.target),"supportLang":.string(scope.support),"cefrLevel":card["cefrLevel"],"moduleType":.string("flashcard")])
            let prompt=try policy.run("flashNotePrompt",parameters,language:scope.support).string
            let raw=(try? await provider.judge(prompt)) ?? "",note=try policy.run("flashNoteParse",parameters.setting("raw",.string(raw)),language:scope.support)
            try Task.checkCancellation();guard token == request,matches(app) else{return}
            let metadata=parameters.setting("lessonTitle",.object(["en":.string(concept),"es":.string(concept)])).setting("example",note["example"]).setting("summary",note["summary"])
            app.learner.notes.insert(Note(title:concept,body:note["example"].string+"\n\n"+note["summary"].string,study:metadata,createdAt:Date()),at:0);app.persist();noteSaved=true
        }catch is CancellationError{}catch{if token == request,matches(app){self.error=copy("note_error")}}}
    }
    func canRate(_ rating:ReviewRating)->Bool {!saving && (intentRating == nil || intentRating == rating)}
    func close(_ app:AppModel,abandoned:Bool=true){
        if abandoned,grade == nil,!capturedMiss,matches(app){let text=(answer.isEmpty ? recognized:answer).trimmingCharacters(in:.whitespacesAndNewlines);if !text.isEmpty{capturedMiss=true;capture(app,text:text,context:"flashcard-abandoned")}}
        cancel();if app.flashcardSession?.id == id {app.flashcardSession=nil}
    }
    func cancel(){closed=true;request=UUID();work?.cancel();revealTask?.cancel();explainTask?.cancel();quoteTask?.cancel()}
    private func capture(_ app:AppModel,text:String,context:String){app.learner.captureMemory(mode:"flashcard",concept:concept,answer:text,expected:revealed,feedback:"",context:context,questionLevel:card["cefrLevel"].string);app.persist()}
}
