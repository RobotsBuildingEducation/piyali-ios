import Foundation
import Combine

enum TutorFocus:Equatable {
    case goal(JSONValue)
    case repair(RepairStep)
    var key:String {switch self {case .goal(let bp):return "goal:"+bp["goalId"].string+":"+bp["dayKey"].string+":"+bp["mode"].string;case .repair(let step):return step.id+":"+step.mode}}
    var level:String {switch self {case .goal(let bp):return bp["cefrLevel"].string;case .repair(let step):return step.item["cefrLevel"].string}}
    @MainActor func isCurrent(_ app:AppModel)->Bool {switch self {case .goal(let bp):return app.goalIsCurrent(bp);case .repair(let step):return app.learner.repairStepIsCurrent(step)}}
    @MainActor func snapshot(_ app:AppModel)->JSONValue {
        var value:JSONValue = .object(["npub":.string(app.identity.npub),"targetLang":.string(app.learner.target),"supportLang":.string(app.learner.support),"surface":.string("tutor")])
        switch self {case .goal(let bp):value=value.setting("blueprint",bp).setting("mode",bp["mode"]);case .repair(let step):value=value.setting("plan",step.plan).setting("mode",.string(step.mode)).setting("stepIndex",.number(Double(step.index))).setting("stepCount",.number(Double(step.stepCount)))}
        return value
    }
}

/// Native sequencing around the reference Tutor's unmodified policy and prompts.
@MainActor final class TutorSessionController:ObservableObject {
    @Published private(set) var catalog:JSONValue = .null
    @Published private(set) var unit:JSONValue = .null
    @Published private(set) var lesson:JSONValue = .null
    @Published private(set) var content:JSONValue = .null
    @Published private(set) var state:JSONValue = .null
    @Published private(set) var messages:[JSONValue]=[]
    @Published private(set) var loading=false
    @Published private(set) var grading=false
    @Published private(set) var paused=false
    @Published private(set) var saving=false
    @Published private(set) var completionPending=false {didSet{onCompletionPending?(completionPending)}}
    @Published private(set) var focus:TutorFocus?
    @Published private(set) var focusSkipped=false
    @Published private(set) var focusedFinished=false
    var onCompletionPending:((Bool)->Void)?
    var onFocusedCompletion:(()->Void)?
    @Published var error:String?
    @Published var completion:JSONValue?
    @Published var review:JSONValue?
    @Published private(set) var feedback:OrbFeedback?
    let clips:TutorAudioClips
    let live:LiveTutorService
    private(set) var policy:TutorSourcePolicy?
    private var provider:TutorProvider?
    private let realtimeProvider:String
    private let turnXP:()->Int
    private var ownerRevision:UUID?
    private var owner="",epoch=UUID(),turn=0,welcomePending=false,mutedWhenPaused=false
    private var seenInputs:Set<String>=[],seenResponses:Set<String>=[]
    private var lastInput="",lastInputAt=Date.distantPast
    private var practiceStarted=false,practiceQuestion:JSONValue = .null
    private var awardedTurns:Set<Int>=[],assessedTurns:Set<Int>=[],advancedTurns:Set<Int>=[]
    private var lateCompletionTask:Task<Void,Never>?
    private let completionIdleTimeout:TimeInterval
    private var resume:[JSONValue]=[],pausedMessages:[JSONValue]=[]
    private var quiz:JSONValue = .object([:]),quizFeedback:JSONValue = .null,previousQuiz:JSONValue = .null
    private var draftTask:Task<Void,Never>?,worth:[String:Task<JSONValue?,Never>]=[:]
    private var worthParameters:[String:JSONValue]=[:],claimedWorth:Set<String>=[],outcomeIDs:Set<UUID>=[]
    private var followupRetry=0,activeItemID="",needsResumeContext=false
    private var xpCache:[String:Int]=[:],contentCache:[String:JSONValue]=[:],copyCache:[String:String]=[:],pathCopyCache:[String:String]=[:]
    private var levelCache:JSONValue?
    private var liveUpdates:AnyCancellable?
    private var completionLesson:Lesson?,completionChange:UUID?
    private var savingRevision=UUID()
    private var scholarshipCompletion:ScholarshipPrompt.Scope?
    private var focusedRecord:JSONValue = .object([:]),repairEvidence:JSONValue = .object([:])
    private var focusedGoalChange:UUID?,focusedRepairChange:UUID?
    private var reviewRecord:JSONValue?
    var practicingCompletedLesson:Bool { reviewRecord != nil }
    private func sessionRecord(_ app:AppModel)->JSONValue { focus != nil ? focusedRecord:reviewRecord ?? record(app) }
    init(focus:TutorFocus?=nil,live:LiveTutorService?=nil,clips:TutorAudioClips = .shared,provider:TutorProvider?=nil,turnXP:@escaping()->Int={PlatePracticeFixture.turnXP()},completionIdleTimeout:TimeInterval=45,realtimeProvider:String?=nil){self.realtimeProvider=(realtimeProvider ?? TutorRealtime.provider) == "openai" ? "openai":"gemini";self.completionIdleTimeout=completionIdleTimeout;self.clips=clips;self.turnXP=turnXP;self.focus=focus;self.live=live ?? TutorVoiceFixture.service(provider:realtimeProvider);self.provider=provider;policy=try? TutorSourcePolicy();liveUpdates=self.live.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}}
    static var fixture:Bool {TutorVoiceFixture.enabled}
    var id:String {lesson["id"].string}
    var required:Int {Int(state["required"].number)}
    func scope(_ app:AppModel)->String {
        let course=focus.map{focus in let day=CalendarDay.key(Date());if case .goal=focus{return focus.key+":"+day+":"+app.goalCourseScope.goalID};return focus.key+":"+day} ?? app.learner.tutorLevel
        return [app.identity.npub,app.learner.target,app.learner.support,course].joined(separator:":")
    }
    func clipScope(_ app:AppModel)->TutorAudioClips.Scope{.init(account:app.identity.npub,target:app.learner.target,support:app.learner.support)}
    func replayVoice(_ app:AppModel)->String{(try? policy?.run("voice",payload(app)))?.string ?? ""}
    private var displayingWelcome:Bool{welcomePending && live.assistantResponseKind != "tutor_transcript_recovery"}
    var currentReplyLanguage:String{displayingWelcome ? "support":"target"}
    func earnedXP(_ app:AppModel)->Int {Int(sessionRecord(app)["earnedXp"].number)}
    private func focusIsCurrent(_ app:AppModel)->Bool {focus?.isCurrent(app) ?? true}
    private func valid(_ app:AppModel,_ token:UUID)->Bool {epoch == token && app.signedIn && ownerRevision == app.identity.sessionRevision && owner == scope(app) && !Task.isCancelled}
    var typedLesson:Lesson? {Self.decodeLesson(lesson)}
    static func decodeLesson(_ source:JSONValue)->Lesson? {
        // The source ephemeral builder omits curriculum-only fields. Supply
        // neutral decoder defaults here; prompts keep using its untouched JSON.
        var raw=source
        if raw["agenda"] == .null{raw=raw.setting("agenda",.object([:]))}
        if raw["xpReward"] == .null{raw=raw.setting("xpReward",.number(0))}
        if raw["modes"] == .null{raw=raw.setting("modes",.array([.string("realtime")]))}
        return try? JSONDecoder().decode(Lesson.self,from:Data(raw.json.utf8))
    }
    func record(_ app:AppModel,_ lessonID:String?=nil)->JSONValue {
        let key=lessonID ?? id,progress=app.learner.tutorProgress(key)
        var value=progress.sourceState ?? .object([:])
        value=value.setting("earnedXp",.number(Double(progress.earnedXP)))
        if value["tutorAgendaProgress"] == .null {value=value.setting("tutorAgendaProgress",.object(["items":.object(Dictionary(uniqueKeysWithValues:progress.items.map{($0,.bool(true))}))]))}
        if app.learner.completed.contains(app.learner.tutorKey(key)){value=value.setting("status",.string("completed"))}
        return value
    }
    func records(_ app:AppModel,units:[JSONValue])->JSONValue {.object(Dictionary(uniqueKeysWithValues:units.flatMap{$0["lessons"].array}.map{($0["id"].string,record(app,$0["id"].string))}))}
    func path(_ app:AppModel,level:String,id:String="")->JSONValue {
        let units=catalog[level].array
        return (try? policy?.run("path",.object(["units":.array(units),"records":records(app,units:units),"id":.string(id),"placement":app.learner.placements?[app.learner.target].map{.string($0.level)} ?? .null]))) ?? .null
    }
    func allowed(_ app:AppModel,level:String,id:String)->Bool {path(app,level:level,id:id)["allowed"].boolean}
    func details(_ app:AppModel,lesson:JSONValue,unit:JSONValue)->JSONValue {
        let key=[app.learner.target,app.learner.support,unit["id"].string,lesson["id"].string].joined(separator:":")
        if let cached=contentCache[key]{return cached}
        let value=(try? policy?.run("content",.object(["completed":.bool(practicingCompletedLesson),"lesson":lesson,"unit":unit,"target":.string(app.learner.target),"support":.string(app.learner.support)]))) ?? .null
        contentCache[key]=value;return value
    }
    func xpRequired(_ lesson:JSONValue)->Int {
        let small:JSONValue = .object(["id":lesson["id"],"isGoal":lesson["isGoal"],"isRepair":lesson["isRepair"],"xpRequired":lesson["xpRequired"]]),key=small.canonicalJSON
        if let cached=xpCache[key]{return cached};let value=Int((try? policy?.run("xp",.object(["lesson":small])))?.number ?? 0);xpCache[key]=value;return value
    }
    func statusLabel(_ support:String)->String {
        let state=["speaking","thinking"].contains(live.voiceState) ? live.voiceState:"listening"
        return (try? policy?.run("status",.object(["state":.string(state),"support":.string(support)])))?.string ?? ""
    }
    func copy(_ text:String,_ support:String)->String {let key=support+":"+text;if let cached=copyCache[key]{return cached};let value=(try? policy?.run("copy",.object(["text":.string(text),"support":.string(support)])))?.string ?? text;copyCache[key]=value;return value}
    func pathCopy(_ key:String,_ support:String)->String {let cacheKey=support+":"+key;if let cached=pathCopyCache[cacheKey]{return cached};let value=(try? policy?.run("pathCopy",.object(["key":.string(key),"support":.string(support)])))?.string ?? key;pathCopyCache[cacheKey]=value;return value}
    func levels()->JSONValue {if let levelCache{return levelCache};let value=(try? policy?.run("levels")) ?? .null;levelCache=value;return value}
    private func payload(_ app:AppModel)->JSONValue {
        let settings:JSONValue = .object(["practicePronunciation":.bool(app.learner.conversation.pronunciation),"conversationSubjects":.string(app.learner.conversation.interests)]),record=sessionRecord(app)
        return .object(["provider":.string(realtimeProvider),"completed":.bool(practicingCompletedLesson),"lesson":lesson,"unit":unit,"target":.string(app.learner.target),"support":.string(app.learner.support),"level":.string(focus?.level ?? app.learner.tutorLevel),"goalFocus":{if case .goal?=focus{return focus?.snapshot(app) ?? .null};return JSONValue.null}(),"repairFocus":{if case .repair?=focus,!focusSkipped{return focus?.snapshot(app) ?? .null};return JSONValue.null}(),"user":app.learner.recipeUser,"settings":settings,"progress":record["tutorAgendaProgress"]["items"],"earned":record["earnedXp"],"turn":.number(Double(turn)),"messages":.array(messages),"resume":.array(resume),"pausedMessages":.array(pausedMessages),"voice":SettingsUI.effective(app.learner)["progress"]["tutorVoice"],"persona":.string(SettingsUI.effective(app.learner)["progress"]["tutorVoicePersona"].string),"pause":.number(Double(app.learner.tutorPauseMilliseconds)),"retry":.number(Double(followupRetry)),"activeItemID":.string(activeItemID),"needsResumeContext":.bool(needsResumeContext),"quizLastFeedback":quizFeedback,"quizPreviousAttemptResult":previousQuiz])
    }
    func refresh(_ app:AppModel) {guard owner == scope(app),!id.isEmpty else{return};content=details(app,lesson:lesson,unit:unit);state=(try? policy?.run("state",payload(app))) ?? .null}
    func prepare(_ app:AppModel) async {
        if owner == scope(app),!id.isEmpty {refresh(app);return}
        await stop(app,saveDraft:false)
        completionPending=false;completion=nil;review=nil;saving=false;savingRevision=UUID();focusedFinished=false;focusedGoalChange=nil;focusedRepairChange=nil;completionChange=nil;completionLesson=nil;reviewRecord=nil;scholarshipCompletion=nil
        owner=scope(app);ownerRevision=app.identity.sessionRevision;let token=epoch,target=app.learner.target;loading=true;error=nil
        defer {if epoch == token{loading=false}}
        do {
            catalog=try await Task.detached {try ContentLibrary.load(JSONValue.self,name:"tutor-curriculum-"+target)}.value
            guard valid(app,token) else{return}
            if provider == nil {provider=Self.fixture ? TutorVoiceFixture.provider(support:app.learner.support):.native(app.ai)}
            guard policy != nil else{throw PracticeRecipeFailure.unavailable}
            if let focus {
                guard focus.isCurrent(app) else{throw AppError.message("Return to today's current focused task.")}
                let lesson=try policy!.run("focusLesson",.object(["focus":focus.snapshot(app)]))
                guard lesson != .null else{throw PracticeRecipeFailure.invalidRecipe}
                select(app,lesson:lesson,unit:.object(["cefrLevel":lesson["cefrLevel"]]));return
            }
            let level=app.learner.tutorLevel,stored=app.learner.plateProgress["currentTutorLesson"].string
            let units=catalog[level].array
            if let unit=units.first(where:{$0["lessons"].array.contains(where:{$0["id"].string == stored})}),let lesson=unit["lessons"].array.first(where:{$0["id"].string == stored}),record(app,stored)["status"].string != "completed",allowed(app,level:level,id:stored){select(app,lesson:lesson,unit:unit)}
            else {let current=path(app,level:level)["current"];select(app,lesson:current["lesson"],unit:current["unit"])}
            // Interrupted source checkpoints can finish once hydrated. Schema-2
            // records additionally require their agenda; quizzes use XP alone.
            if required>0,record(app)["earnedXp"].number >= Double(required),record(app)["status"].string != "completed" {
                let legacy=record(app)["tutorAgendaProgress"]["schemaVersion"].number<2
                if legacy || state["isComplete"].boolean || lesson["isFinalQuiz"].boolean {await complete(app,ready:true)}
            }
        }catch {if valid(app,token){self.error=error.localizedDescription}}
    }
    func adoptLevel(_ app:AppModel){owner=scope(app);ownerRevision=app.identity.sessionRevision}
    func select(_ app:AppModel,lesson:JSONValue,unit:JSONValue){
        lateCompletionTask?.cancel();lateCompletionTask=nil;practiceStarted=false;practiceQuestion = .null;awardedTurns=[];assessedTurns=[];advancedTurns=[]
        outcomeIDs=[];followupRetry=0;activeItemID="";needsResumeContext=false
        self.lesson=lesson;self.unit=unit;messages=[];resume=[];pausedMessages=[];turn=0;quizFeedback = .null;previousQuiz = .null;seenInputs=[];seenResponses=[];lastInput="";lastInputAt = .distantPast
        if lesson["isGoal"].boolean || lesson["isRepair"].boolean {
            focusedRecord = .object(["earnedXp":.number(0)]);repairEvidence = .object([:]);reviewRecord=nil
        }else{focus=nil;focusSkipped=false;focusedFinished=false;owner=scope(app);ownerRevision=app.identity.sessionRevision}
        let saved=focus == nil ? record(app):focusedRecord
        reviewRecord=focus == nil && saved["status"].string == "completed" ? saved.setting("earnedXp",.number(Double(xpRequired(lesson)))):nil
        quiz=sessionRecord(app)["tutorAgendaProgress"]["quiz"];refresh(app)
    }
    func start(_ app:AppModel,resuming:Bool=false) async {
        guard !focusedFinished,focusIsCurrent(app),!live.connected,!live.connecting,!saving,!id.isEmpty,Self.fixture || app.subscription.hasAccess,let policy,let typedLesson else{return}
        error=nil;draftTask?.cancel()
        if !resuming {
            let privateMessages=messages.isEmpty ? ((try? policy.run("resume",.object(["record":sessionRecord(app)]))) ?? .null)["resumeContextMessages"].array:messages
            resume=privateMessages;needsResumeContext = !resume.isEmpty;messages=[];pausedMessages=[];turn=0;practiceStarted=false;practiceQuestion = .null;awardedTurns=[];assessedTurns=[];advancedTurns=[];mutedWhenPaused=false;seenInputs=[];seenResponses=[]
        }
        paused=false;epoch=UUID();let token=epoch
        if focus == nil,!practicingCompletedLesson {app.learner.storeTutorState(lesson:typedLesson,data:.object(["kind":.string("start"),"agenda":record(app)["tutorAgendaProgress"]["items"]]));app.persist()};refresh(app)
        welcomePending = focus == nil && !resuming && state["starter"].boolean && resume.isEmpty && earnedXP(app) == 0 && sessionRecord(app)["tutorAgendaProgress"]["items"].object.isEmpty
        do {
            if !Self.fixture {try await FirebaseIdentityService.shared.ensure(app.identity)}
            guard valid(app,token) else{return}
            let baseSession=try policy.run(realtimeProvider == "gemini" ? "geminiSession":"session",payload(app))
            let session=realtimeProvider == "gemini" ? baseSession.setting("owner",.string(app.identity.npub)):baseSession
            await live.start(learner:app.learner,instructions:session["instructions"].string,openingPrompt:nil,inactivityTimeout:30,initiallyMuted:resuming && mutedWhenPaused,onInputTurn:{[weak self,weak app] input in guard let self,let app,self.valid(app,token) else{return};let responding=self.live.outputPending,number=self.turn,snapshot=self.transcriptSnapshot(app);Task{await self.input(input,app:app,token:token,assistantResponding:responding,lateSnapshot:snapshot,practiceTurn:number)}},onAssistantTurn:{[weak self,weak app] response,text in guard let self,let app,self.valid(app,token) else{return};self.assistant(response,text:text,app:app,token:token)},sessionConfiguration:session,externallyControlled:true,previousAssistant:resuming ? messages.last(where:{$0["role"].string == "assistant"})?["textFinal"].string:nil,onResponseRecording:{[weak self,weak app] response,recording in
                guard let self,let app,self.valid(app,token)else{return};let scope=self.clipScope(app),clips=self.clips
                Task{await clips.store(recording,response:response,scope:scope)}
            },onAssistantInterrupted:{[weak self,weak app] response,text in
                guard let self,let app,self.valid(app,token)else{return};self.assistant(response,text:text,app:app,token:token,canceled:true)
            })
            guard valid(app,token),live.connected else{return}
            live.setOutputGain(app.learner.settingsSnapshot["tutorVolume"] == .null ? 1:app.learner.settingsSnapshot["tutorVolume"].number)
            if resuming,let interrupted=pausedMessages.last(where:{$0["interrupted"].boolean}),!interrupted["textFinal"].string.isEmpty {
                let event=try policy.run("resumeSpeech",.object(["speech":.object(["text":interrupted["textFinal"]]),"instructions":session["instructions"]]))
                if event != .null{live.requestResponse(event)}
            } else {try request(app,welcome:welcomePending,kickoff:true)}
        }catch {if valid(app,token){self.error=error.localizedDescription;await live.stop()}}
    }
    private func request(_ app:AppModel,welcome:Bool=false,kickoff:Bool=false,answer:String="",accepted:JSONValue = .array([]),verdict:String="uncertain")throws {
        guard let policy else{throw PracticeRecipeFailure.unavailable}
        let p=payload(app).setting("welcome",.bool(welcome)).setting("kickoff",.bool(kickoff)).setting("answer",.string(answer)).setting("accepted",accepted).setting("verdict",.string(verdict))
        if !welcome && (!kickoff || state["starter"].boolean) {
            let followup=try policy.run(kickoff ? "starterKickoff":"followup",p.setting("verdict",verdict.isEmpty ? .null:.string(verdict)))
            followupRetry=Int(followup["retry"].number);activeItemID=followup["activeItemID"].string;needsResumeContext=followup["needsResumeContext"].boolean
            if followup["event"] != .null{live.requestResponse(followup["event"])}
        }else {
            live.requestResponse(.object(["type":.string("response.create"),"response":.object(["output_modalities":.array([.string("audio")]),"instructions":try policy.run("response",p),"metadata":.object(["kind":.string(welcome ? "tutor_welcome":"tutor_kickoff")])])]))
            needsResumeContext=false
        }
    }
    private func assistant(_ response:String,text:String,app:AppModel,token:UUID,canceled:Bool=false){
        guard seenResponses.insert(response).inserted,!text.isEmpty else{return}
        let text=(try? policy?.run("sanitize",.object(["text":.string(text)])))?.string ?? text
        let welcome=displayingWelcome
        let message:JSONValue = .object(["id":.string(response),"role":.string("assistant"),"textFinal":.string(text),"done":.bool(true),"welcome":.bool(welcome),"lang":.string(welcome ? app.learner.support:app.learner.target),"ts":.number(Date().timeIntervalSince1970*1000),"questionLevel":state["level"]])
        messages.append(message);scheduleDraft(app)
        let p=provider,learner=app.learner,level=state["level"].string,question:JSONValue = .object(["tutorPrompt":.string(text),"lesson":lesson["title"]])
        if !welcome && !canceled {
            worthParameters[response]=GeneratedQuestionWorth.parameters(question:question,level:level,mode:"tutor",learner:learner)
            worth[response]=Task{try? await p?.quote(question,level,learner)}
        }
        Task{await translate(response,text:text,app:app,token:token)}
    }
    func input(_ input:RealtimeVoiceState.InputTurn,app:AppModel,token:UUID?=nil,assistantResponding:Bool?=nil,lateSnapshot:JSONValue?=nil,practiceTurn:Int?=nil) async {
        let token=token ?? epoch
        guard valid(app,token),focusIsCurrent(app),!paused,!completionPending,let policy,let typedLesson,seenInputs.insert(input.id).inserted else{return}
        let text=input.text.trimmingCharacters(in:.whitespacesAndNewlines),now=Date(),late=assistantResponding ?? live.outputPending,lessonID=id
        var number=practiceTurn ?? turn
        let snapshot=lateSnapshot ?? transcriptSnapshot(app)
        do {
            if !text.isEmpty,try policy.run("script",payload(app).setting("text",.string(text))).boolean {
                let recovery=late ? nil:try policy.run("transcriptRecovery",payload(app))
                live.rejectTranscript(input.id,recovery:recovery)
                return
            }
            let p:JSONValue,before:JSONValue,local:JSONValue,lateEffect:JSONValue
            if late {
                // The source updates its textual duplicate window even when a
                // welcome/quiz/pre-practice transcript is deliberately ignored.
                guard !text.isEmpty,!(text == lastInput && now.timeIntervalSince(lastInputAt)<2),number == turn else{return}
                lastInput=text;lastInputAt=now
                p=snapshot.setting("answer",.string(text));lateEffect=try policy.run("lateInput",p)
                guard lateEffect != .null else{return}
                before=try policy.run("state",p);local=try policy.run("classify",p)
                if lateEffect["kind"].string == "judge",!(try policy.run("matches",p))["meaningful"].boolean{return}
            }else {
                guard !grading else{return}
                let match=try policy.run("matches",payload(app).setting("answer",.string(text)))
                guard match["meaningful"].boolean,!(text == lastInput && now.timeIntervalSince(lastInputAt)<2) else{live.discardInput(input.id);return}
                lastInput=text;lastInputAt=now
                messages.append(.object(["id":.string(input.id),"role":.string("user"),"textFinal":.string(text),"done":.bool(true),"lang":.string(app.learner.target),"ts":.number(now.timeIntervalSince1970*1000)]));scheduleDraft(app)
                if welcomePending {welcomePending=false;try request(app,kickoff:true);return}
                turn += 1;number=turn;practiceStarted=true
                practiceQuestion=messages.last(where:{$0["role"].string == "assistant" && !$0["welcome"].boolean}) ?? .null
                grading=true;before=state;p=payload(app).setting("answer",.string(text));local=try policy.run("classify",p);lateEffect = .null
            }
            defer{if !late,epoch == token,number == turn{grading=false}}
            let context=TurnContext(token:token,lessonID:lessonID,number:number,text:text,date:now,payload:p,before:before,local:local,late:late,question:late ? snapshot["practiceQuestion"]:practiceQuestion)
            let isQuiz=lesson["isFinalQuiz"].boolean,isLocal = !isQuiz && (late ? lateEffect["kind"].string == "local":local["local"].boolean)
            let objectiveJudge=realtimeProvider == "openai" && !before["starter"].boolean && isLocal && !local["objectiveLocal"].boolean && !before["isComplete"].boolean
            let completionGate=try policy.run("completionGate",p.setting("candidateIds",local["candidateIds"])).boolean
            let needsJudge=late ? lateEffect["kind"].string == "judge":focus != nil || isQuiz || !isLocal || objectiveJudge
            // The free local matcher commits lesson/day progress before any
            // optional objective judge or original question-worth promise.
            var result=try apply(context,app:app,parsed:.object([:]),semantic:false,localSuccessful:isLocal,history:!needsJudge)
            if !late,isLocal,result.ready {await finish(context,app:app,result:result);return}
            let background = !late && realtimeProvider == "gemini" && focus == nil && !isQuiz && !isLocal && !completionGate
            if background {
                grading=false
                try followup(app,answer:text,accepted:result.accepted,verdict:"")
                Task{[weak self,weak app] in
                    guard let self,let app else{return}
                    let parsed=await self.judge(context,app:app,isQuiz:false)
                    guard self.current(context,app:app) else{return}
                    do {
                        let result=try self.apply(context,app:app,parsed:parsed,semantic:true,localSuccessful:false,history:true)
                        if result.ready {self.completeAfterReply(app,token:token)}
                    }catch{/* The saved earned intent remains recoverable. */}
                }
                return
            }
            if needsJudge {
                let parsed=await judge(context,app:app,isQuiz:isQuiz)
                guard current(context,app:app) else{return}
                result=try apply(context,app:app,parsed:parsed,semantic:true,localSuccessful:isLocal,history:true)
            }
            guard current(context,app:app) else{return}
            grading=false
            await finish(context,app:app,result:result)
        }catch {if valid(app,token){if !late{self.error="This turn could not be checked. Please try again.";grading=false;completionPending=false;live.discardInput(input.id)}}}
    }
    private struct TurnContext {
        let token:UUID;let lessonID:String;let number:Int;let text:String;let date:Date
        let payload:JSONValue;let before:JSONValue;let local:JSONValue;let late:Bool;let question:JSONValue
    }
    private struct TurnResult {let accepted:JSONValue;let verdict:String;let ready:Bool}
    private func current(_ c:TurnContext,app:AppModel)->Bool {
        valid(app,c.token) && focusIsCurrent(app) && !paused && id == c.lessonID && (!c.late || c.number == turn)
    }
    private func judge(_ c:TurnContext,app:AppModel,isQuiz:Bool)async->JSONValue {
        guard let policy else{return .null}
        var options=c.local["options"]
        if !c.late && (isQuiz || c.local["local"].boolean) {
            // The source omits directPhraseAnswer for the OpenAI capability
            // pass, preventing its free phrase shortcut from skipping the judge.
            options=options.setting("directPhraseAnswer",.bool(false))
            if isQuiz{options=options.setting("regularPhraseMatch",.bool(false))}
        }
        do {
            if case .goal(let bp)?=focus {
                guard let provider else{return .null}
                let verdict=try await provider.goal(bp,c.text,options.json,app.learner.support)
                return .object(["successful":.bool(verdict.success),"confidence":.number(1),"reason":.string(verdict.feedback),"observation":.string(verdict.observation)])
            }
            return try await provider?.judge(try policy.run("judge",c.payload.setting("options",options)).string) ?? .null
        }catch{return .object(["confidence":.number(0)])}
    }
    private func apply(_ c:TurnContext,app:AppModel,parsed:JSONValue,semantic:Bool,localSuccessful:Bool,history:Bool)throws->TurnResult {
        guard let policy,let typedLesson else{throw PracticeRecipeFailure.unavailable}
        let before=c.before,isQuiz=lesson["isFinalQuiz"].boolean
        let grade=try policy.run("grade",.object(["parsed":parsed,"local":.bool(localSuccessful),"attempted":.bool(semantic)]))
        let confidence=grade["confidence"].number,accepted=grade["verdict"].string == "accepted",mistake=parsed["mistake"].boolean && confidence>=0.55 && !accepted
        let semanticObjective=grade["successful"].boolean && (parsed["objectiveAdvanced"] == .null || parsed["objectiveAdvanced"].boolean)
        let objective=realtimeProvider != "openai" || c.local["objectiveLocal"].boolean || semanticObjective
        var agenda=sessionRecord(app)["tutorAgendaProgress"]["items"],acceptedIDs:[JSONValue]=[]
        if isQuiz,semantic,confidence>=0.55,parsed["quizAnswered"].boolean {
            let next=try policy.run("quiz",.object(["items":before["items"],"progress":agenda,"correctItems":quiz["correctItems"],"correct":.bool(accepted)]))
            agenda=next["progress"];quiz = .object(["correctItems":next["correctItems"],"attemptNumber":.number(max(1,quiz["attemptNumber"].number)+(next["failed"].boolean ? 1:0))]);quizFeedback = .object(["correct":.bool(accepted),"correction":parsed["correction"],"reason":parsed["reason"]]);previousQuiz=next["failed"].boolean ? .object(["score":next["score"],"total":.number(Double(before["items"].array.count))]):.null
        }else if accepted,focus == nil {
            if before["starter"].boolean {
                for candidate in c.local["candidateIds"].array where before["items"].array.contains(where:{$0["id"] == candidate}) && !agenda[candidate.string].boolean {agenda=agenda.setting(candidate.string,.bool(true));acceptedIDs.append(candidate)}
            }else if objective,!advancedTurns.contains(c.number),let current=before["currentItem"]["id"].string.nilIfEmpty {agenda=agenda.setting(current,.bool(true));advancedTurns.insert(c.number)}
        }
        if accepted{followupRetry=0}
        let repairAdvanced:Bool
        if case .repair?=focus {repairAdvanced=parsed["repairAdvanced"].boolean}else{repairAdvanced=false}
        if repairAdvanced {repairEvidence = .object(["success":.bool(true),"support":.string("prompted"),"observation":.string(String(c.text.prefix(600)))]);completionPending=true}
        let canPay=accepted && (!before["starter"].boolean || !acceptedIDs.isEmpty || before["items"].array.allSatisfy{agenda[$0["id"].string].boolean})
        let paid=canPay && awardedTurns.insert(c.number).inserted,xp=paid ? max(3,min(7,turnXP())):0
        let earned=paid ? min(required,earnedXP(app)+xp):earnedXP(app)
        if paid,focus != nil {focusedRecord=focusedRecord.setting("earnedXp",.number(Double(earned)))}
        if focus == nil,!practicingCompletedLesson,(paid || agenda != sessionRecord(app)["tutorAgendaProgress"]["items"] || (isQuiz && semantic)) {
            var data:JSONValue = .object(["agenda":agenda,"earnedXp":.number(Double(earned)),"required":.number(Double(required))])
            if isQuiz{data=data.setting("quiz",quiz).setting("replaceAgenda",.bool(true))}
            app.learner.storeTutorState(lesson:typedLesson,data:data,now:c.date)
        }
        refresh(app)
        let ready = !practicingCompletedLesson && (repairAdvanced || earnedXP(app)>=required) && (focus != nil || isQuiz || state["isComplete"].boolean)
        if ready{completionPending=true}
        let assesses=(paid || mistake) && assessedTurns.insert(c.number).inserted
        if paid || assesses {
            var planned:PracticeChange?
            if paid {
                var change=PracticeChange(date:c.date,dayKey:CalendarDay.key(c.date),target:app.learner.target,level:focus?.level ?? typedLesson.cefrLevel ?? app.learner.tutorLevel,amount:xp,source:.tutorTurn,contentID:focus == nil ? typedLesson.id:nil)
                if focus == nil {change.tutorData = practicingCompletedLesson ? .object(["review":.bool(true)]):.object(["required":.number(Double(required)),"progressRecorded":.bool(true)])}
                planned=change
            }
            let level=c.question["questionLevel"].string.nilIfEmpty ?? before["level"].string
            let parameters=worthParameters[c.question["id"].string] ?? GeneratedQuestionWorth.parameters(question:.object(["tutorPrompt":c.question["textFinal"],"lesson":lesson["title"]]),level:level,mode:"tutor",learner:app.learner)
            let outcome=TutorOutcomeIntent(turn:planned,target:app.learner.target,level:level,date:c.date,correct:paid,independent:paid,support:paid ? "independent":nil,concept:mistake ? parsed["concept"].string:nil,recordsAssessment:assesses,worthParameters:parameters)
            app.learner.queueTutorOutcome(outcome);outcomeIDs.insert(outcome.id)
            // Ownership transfers to AppModel; End/Pause cancels only unused quotes.
            claimedWorth.insert(c.question["id"].string)
            let quote=worth[c.question["id"].string] ?? Task<JSONValue?,Never>{nil}
            app.persist();app.tutorOutcomes.start(outcome,app:app,quote:quote)
        }
        if paid{feedback = .init(correct:true)}
        else if mistake,!awardedTurns.contains(c.number){feedback = .init(correct:false)}
        var capturedMemory=false
        if semantic {
            let effects=try policy.run("judgeEffects",c.payload.setting("parsed",parsed).setting("answer",.string(c.text)).setting("turn",.number(Double(c.number))).setting("questionLevel",c.question["questionLevel"]).setting("turnAwarded",.bool(awardedTurns.contains(c.number))))["effects"].array
            for effect in effects where effect["kind"].string == "memory" {
                let now=Date(),fields=MemoryUI.value("captureNote",effect["parameters"].setting("now",.string(WebProgressContract.iso(now))))
                if fields != .null,let note=app.learner.captureMemory(MemoryNote(fields:fields.object),concept:effect["parameters"]["concept"].string,now:now) {
                    capturedMemory=true
                    if let respond=provider?.memory {app.tutorMemories.start(note,concept:MemoryContract.cleanConcept(effect["parameters"]["concept"].string,support:note.text("supportLang")),app:app,respond:respond)}
                }
            }
        }
        if let saved=reviewRecord {
            var progress=saved["tutorAgendaProgress"].setting("items",agenda)
            if isQuiz {progress=progress.setting("quiz",quiz)}
            reviewRecord=saved.setting("tutorAgendaProgress",progress)
        }
        refresh(app)
        if history,!c.late,(accepted || mistake) {
            app.learner.history.insert(.init(date:c.date,target:app.learner.target,mode:"Tutor",question:c.question["textFinal"].string,answer:c.text,feedback:parsed["reason"].string,correct:accepted,repairInMemory:capturedMemory),at:0);app.learner.history=Array(app.learner.history.prefix(500))
        }
        app.persist()
        return TurnResult(accepted:.array(acceptedIDs),verdict:grade["verdict"].string,ready:ready)
    }
    private func followup(_ app:AppModel,answer:String,accepted:JSONValue,verdict:String)throws {
        guard let policy else{throw PracticeRecipeFailure.unavailable}
        if Self.fixture || app.subscription.hasAccess {
            let session=try policy.run(realtimeProvider == "gemini" ? "geminiSession":"session",payload(app))
            if realtimeProvider == "gemini"{live.updateTutorContext(session)}else{live.updateTranscription(session["audio"]["input"]["transcription"])}
            try request(app,answer:answer,accepted:accepted,verdict:verdict)
        }
    }
    private func earnedOutcomeIDs(_ app:AppModel)->Set<UUID> {
        outcomeIDs.union((app.learner.pendingTutorOutcomes ?? []).filter{$0.target == app.learner.target && $0.turn?.contentID == id}.map(\.id))
    }
    private func finish(_ c:TurnContext,app:AppModel,result:TurnResult)async {
        if result.ready {
            if c.late && live.outputPending {completeAfterReply(app,token:c.token)}else{await complete(app,ready:true)}
        }else if !c.late {
            completionPending=false
            do{try followup(app,answer:c.text,accepted:result.accepted,verdict:(realtimeProvider == "openai" || lesson["isFinalQuiz"].boolean) ? result.verdict:"")}catch{self.error="Could not request the next Tutor reply."}
            if !Self.fixture && !app.subscription.hasAccess {await stop(app)}
        }
        await app.tutorOutcomes.wait(earnedOutcomeIDs(app),app:app)
    }
    private func transcriptSnapshot(_ app:AppModel)->JSONValue {
        var p=payload(app)
        if live.outputPending,!live.assistantTurnText.isEmpty,!messages.contains(where:{$0["id"].string == live.assistantResponseID}) {
            let streaming:JSONValue = .object(["id":.string(live.assistantResponseID),"role":.string("assistant"),"textFinal":.string(live.assistantTurnText),"done":.bool(false),"welcome":.bool(displayingWelcome)])
            p=p.setting("messages",.array(messages+[streaming]))
        }
        return p.setting("practiceStarted",.bool(practiceStarted)).setting("welcomePending",.bool(welcomePending)).setting("practiceQuestion",practiceQuestion)
    }
    private func completeAfterReply(_ app:AppModel,token:UUID) {
        completionPending=true
        guard lateCompletionTask == nil else{return}
        let lessonID=id,deadline=Date().addingTimeInterval(max(0,completionIdleTimeout))
        lateCompletionTask=Task{[weak self,weak app] in
            while let self,let app,self.valid(app,token),self.id == lessonID,self.live.connected,self.live.outputPending,Date()<deadline {
                do{try await Task.sleep(for:.milliseconds(50))}catch{return}
            }
            guard let self,let app,self.valid(app,token),self.focusIsCurrent(app),self.id == lessonID,!Task.isCancelled else{return}
            self.lateCompletionTask=nil;await self.complete(app,ready:true)
        }
    }
    private func uniqueMessages(_ values:[JSONValue])->[JSONValue]{var seen:Set<String>=[];return values.filter{seen.insert($0["id"].string).inserted}}
    private func scheduleDraft(_ app:AppModel){draftTask?.cancel();let token=epoch;draftTask=Task{try? await Task.sleep(for:.milliseconds(900));guard !Task.isCancelled,valid(app,token) else{return};flushDraft(app)}}
    func flushDraft(_ app:AppModel){
        draftTask?.cancel();guard focus == nil,owner == scope(app),let typedLesson,!completionPending,record(app)["status"].string != "completed",let draft=try? policy?.run("draft",.object(["messages":.array(uniqueMessages(resume+messages))])),!draft.array.isEmpty else{return}
        let current=record(app)["conversationDraft"]["messages"];guard current != draft else{return}
        app.learner.storeTutorState(lesson:typedLesson,data:.object(["draft":.object(["version":.number(1),"messages":draft]) ]));app.persist()
    }
    func pause(_ app:AppModel) async {
        guard live.connected else{return};let finishLate=lateCompletionTask != nil;lateCompletionTask?.cancel();lateCompletionTask=nil;mutedWhenPaused=live.muted;paused=true
        var snapshot=messages
        if live.outputPending,!live.assistantTurnText.isEmpty {
            if let index=snapshot.lastIndex(where:{$0["role"].string == "assistant" && $0["textFinal"].string == live.assistantTurnText}){snapshot[index]=snapshot[index].setting("interrupted",.bool(true))}
            else{snapshot.append(.object(["id":.string(live.assistantResponseID.isEmpty ? "interrupted-"+UUID().uuidString:live.assistantResponseID),"role":.string("assistant"),"textFinal":.string(live.assistantTurnText),"lang":.string(displayingWelcome ? app.learner.support:app.learner.target),"done":.bool(false)]))}
        }
        live.captureCurrentReply()
        pausedMessages=(try? policy?.run("snapshotMessages",.object(["messages":.array(snapshot)])))?.array ?? snapshot;messages=pausedMessages;epoch=UUID();grading=false;flushDraft(app);await live.stop();if finishLate,owner == scope(app),focusIsCurrent(app){await complete(app,ready:true)}
    }
    func stop(_ app:AppModel,saveDraft:Bool=true) async {
        let finishLate=lateCompletionTask != nil;lateCompletionTask?.cancel();lateCompletionTask=nil
        if live.outputPending,!live.assistantTurnText.isEmpty,!live.assistantResponseID.isEmpty,!messages.contains(where:{$0["id"].string == live.assistantResponseID}){
            messages.append(.object(["id":.string(live.assistantResponseID),"role":.string("assistant"),"textFinal":.string(live.assistantTurnText),"lang":.string(displayingWelcome ? app.learner.support:app.learner.target),"done":.bool(false),"interrupted":.bool(true)]))
        }
        live.captureCurrentReply();if saveDraft{flushDraft(app)};epoch=UUID();draftTask?.cancel();for (id,task) in worth where !claimedWorth.contains(id){task.cancel()};worth=[:];worthParameters=[:];claimedWorth=[];paused=false;grading=false;await live.stop()
        if finishLate,owner == scope(app),focusIsCurrent(app){await complete(app,ready:true)}
        if focusSkipped {focus=nil;focusSkipped=false;owner="";await prepare(app)}
    }
    func skipFocus(_ app:AppModel)async {focusSkipped=true;if !live.connected && !live.connecting{await stop(app)}}
    func selectPreparedGame(_ app:AppModel,lesson:JSONValue,unit:JSONValue)->Lesson?{
        select(app,lesson:lesson,unit:unit)
        guard let typed=typedLesson else{return nil}
        if !practicingCompletedLesson{app.learner.storeTutorState(lesson:typed,data:.object(["kind":.string("start"),"agenda":record(app)["tutorAgendaProgress"]["items"]]))}
        else{app.learner.questProgress=app.learner.plateProgress.setting("currentTutorLesson",.string(typed.id))}
        app.persist();refresh(app)
        return typed
    }
    /// Keep the finished game and its retry action mounted until the canonical
    /// Tutor receipt is acknowledged. Replaying a completed game stays practice.
    func completeGame(_ app:AppModel)async->Bool{
        guard focus == nil,owner == scope(app),!saving else{return false}
        let lessonID=id,runID=app.learner.rpgRuns?[app.learner.target]?.id
        // A restored local completion can still own an unacknowledged bonus.
        // Reuse its durable receipt before treating the lesson as practice.
        if completionChange == nil,let pending=app.learner.pendingChanges?.first(where:{$0.source == .speak && $0.target == app.learner.target && $0.contentID == lessonID && ($0.tutorData?["required"].number ?? 0)>0}){completionChange=pending.id;completionLesson=typedLesson;reviewRecord=nil}
        if !practicingCompletedLesson{await complete(app,ready:true,gameCompleted:true)}
        guard practicingCompletedLesson || (completion != nil && completionChange == nil && error == nil)else{return false}
        if var run=app.learner.rpgRuns?[app.learner.target],run.id == runID,run.lessonID == lessonID,run.tutor == true,run.completed{run.claimed=true;app.learner.saveRPG(run);app.persist()}
        return true
    }
    func complete(_ app:AppModel,ready:Bool,gameCompleted:Bool=false) async {
        if let focus {await completeFocus(app,focus:focus,ready:ready);return}
        guard !practicingCompletedLesson,let typedLesson,let policy,!saving else{return}
        completionPending=true;draftTask?.cancel();saving=true;let saveID=UUID(),account=app.identity.npub,session=app.identity.sessionRevision,lessonID=id
        savingRevision=saveID;defer{if savingRevision == saveID{saving=false}}
        await live.stop();paused=false
        await app.tutorOutcomes.wait(earnedOutcomeIDs(app),app:app)
        guard owner == scope(app),app.identity.npub == account,app.identity.sessionRevision == session,id == lessonID else{return}
        let token=epoch
        if completionChange == nil {
            guard app.learner.completeSourceTutor(lesson:typedLesson,required:required,ready:ready,gameCompleted:gameCompleted) else{completionPending=false;return}
            completionLesson=typedLesson;completionChange=app.learner.pendingChanges?.last(where:{$0.source == .speak && $0.contentID == typedLesson.id})?.id;app.persist()
        }
        await live.stop();paused=false;await app.sync();guard valid(app,token) else{return}
        if !Self.fixture,let change=completionChange,app.learner.pendingChanges?.contains(where:{$0.id == change}) == true {error="Tutor progress is saved on this iPhone. Retry when you’re connected to finish saving.";return}
        if state["starter"].boolean{scholarshipCompletion = .init(account:app.identity.npub,target:app.learner.target)}
        completion=try? policy.run("completed",payload(app).setting("earned",.number(Double(required))))
        let level=app.learner.tutorLevel
        var next=path(app,level:level,id:id)["next"]
        if next["lesson"] == .null,let index=LearningLanguages.levels.firstIndex(of:level),index+1<LearningLanguages.levels.count {
            let nextLevel=LearningLanguages.levels[index+1]
            if app.tutorLevels.contains(nextLevel),!catalog[nextLevel].array.isEmpty {
                next=path(app,level:nextLevel)["current"]
                app.setTutorLevel(nextLevel);owner=scope(app);ownerRevision=app.identity.sessionRevision
            }
        }
        if next["lesson"] != .null{select(app,lesson:next["lesson"],unit:next["unit"])}else{refresh(app)}
        completionChange=nil;completionLesson=nil;error=nil
    }
    private func completeFocus(_ app:AppModel,focus:TutorFocus,ready:Bool)async {
        guard ready,!saving,!focusedFinished,(completionPending || focus.isCurrent(app)),(earnedXP(app)>=required || repairEvidence["success"].boolean) else{return}
        completionPending=true;saving=true;draftTask?.cancel();let saveID=UUID(),account=app.identity.npub,session=app.identity.sessionRevision,lessonID=id
        savingRevision=saveID;defer{if savingRevision == saveID{saving=false}}
        await live.stop();paused=false
        await app.tutorOutcomes.wait(earnedOutcomeIDs(app),app:app)
        guard owner == scope(app),app.identity.npub == account,app.identity.sessionRevision == session,id == lessonID,self.focus?.key == focus.key else{return}
        let token=epoch
        switch focus {
        case .goal(let bp):
            if focusedGoalChange == nil {
                app.recordGoalAttempt(bp,mode:bp["mode"].string,success:true,support:"prompted",observation:"Completed \(required) XP of goal-specific Tutor practice with successful spoken turns.",domain:"production")
                focusedGoalChange=app.learner.pendingGoalChanges?.last(where:{$0.action == .attempt && $0.payload["goalId"] == bp["goalId"] && $0.payload["dayKey"] == bp["dayKey"] && $0.payload["mode"] == bp["mode"]})?.id
            }
        case .repair(let step):
            if focusedRepairChange == nil {
                guard app.completeSourceTutorRepair(step,bonus:required,evidence:repairEvidence) else{error="Return to today's current repair task.";return}
                focusedRepairChange=app.learner.pendingChanges?.last(where:{$0.source == .repair && $0.contentID == step.id})?.id
            }
        }
        await app.sync();guard valid(app,token) else{return}
        let pendingGoal=focusedGoalChange.map{id in app.learner.pendingGoalChanges?.contains(where:{$0.id == id}) == true} ?? false
        let pendingRepair=focusedRepairChange.map{id in app.learner.pendingChanges?.contains(where:{$0.id == id}) == true} ?? false
        if !Self.fixture,(pendingGoal || pendingRepair) {error="Focused practice is saved on this iPhone. Retry when you’re connected to finish saving.";return}
        focusedFinished=true;completionPending=false;error=nil
        onFocusedCompletion?()
    }
    func closeCompletion(){review=completion;completion=nil}
    func closeReview(_ app:AppModel?=nil){if let app,scholarshipCompletion == .init(account:app.identity.npub,target:app.learner.target){app.requestScholarship()};scholarshipCompletion=nil;review=nil;completionPending=false}
    private func translate(_ response:String,text:String,app:AppModel,token:UUID) async {
        guard app.learner.target != app.learner.support,app.learner.recipeUser["progress"]["showTranslations"] != .bool(false),let policy else{return}
        do {
            if let index=messages.firstIndex(where:{$0["id"].string == response}),messages[index]["lang"].string == app.learner.support {messages[index]=messages[index].setting("translation",.string(text));return}
            let prompt=try policy.run("translation",.object(["support":.string(app.learner.support),"source":.string(app.learner.target)])).string
            let value=try await provider?.translate(prompt,text) ?? .null
            guard valid(app,token),let index=messages.firstIndex(where:{$0["id"].string == response}) else{return};messages[index]=messages[index].setting("translation",value["translation"]).setting("pairs",(try? policy.run("pairs",.object(["pairs":value["pairs"],"text":.string(text)]))) ?? .array([]))
        }catch{/* A translation failure does not interrupt voice or grading. */}
    }
}
private extension String {var nilIfEmpty:String?{isEmpty ? nil:self}}
