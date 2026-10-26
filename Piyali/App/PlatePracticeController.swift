import Foundation
import Combine

struct DailyGoalReward:Identifiable {let id=UUID();let account:String;let day:String;let goal:Int;let health:Int}

struct PlateCourseCompletion:Identifiable {let id=UUID();let kind:String}

/// Owns the original plate conductor's native lifecycle, persistence and route actions.
@MainActor final class PlatePracticeController:ObservableObject {
    let owner=UUID()
    @Published private(set) var guided:GuidedPracticeSession?
    @Published private(set) var visible:JSONValue?
    @Published private(set) var pending:JSONValue?
    @Published private(set) var notesOpen=false
    @Published private(set) var dailyGoalVisible:DailyGoalReward?
    var onNavigate:((String)->Void)?
    var onHome:(()->Void)?
    var onNotes:(()->Void)?
    var onSound:((String)->Void)?
    private weak var app:AppModel?
    private var policy:PlateSessionPolicy?
    private var task:Task<Void,Never>?,scope="",updating=false,blocked=false,bonusSeen=false
    private let clock:()->Date
    init(clock:@escaping()->Date=Date.init){self.clock=clock;policy=try? PlateSessionPolicy()}
    private func context(_ app:AppModel)->String {[app.identity.npub,app.learner.target,CalendarDay.key(clock())].joined(separator:":")}
    private func sessionKey(_ app:AppModel)->String {"piyali.guidedSession."+app.identity.npub}
    func bind(_ app:AppModel) {
        self.app=app
        if scope != context(app) {
            task?.cancel();scope=context(app);policy=try? PlateSessionPolicy();visible=nil;pending=nil;notesOpen=false;dailyGoalVisible=nil
            bonusSeen=DailyPlate.bonusAwarded(progress:app.learner.plateProgress,target:app.learner.target,day:CalendarDay.key(clock()))
            if let data=UserDefaults.standard.data(forKey:sessionKey(app)),var saved=try? JSONDecoder().decode(GuidedPracticeSession.self,from:data),saved.matches(account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(clock())) {
                if saved.taskCompleted(app.plateCourses),!saved.advance(app.plateCourses){guided=nil}else{guided=saved}
            }else{guided=nil}
            persist(app)
        }
        app.observePractice(owner:owner){[weak self,weak app] in guard let self,let app else{return};self.refresh(app)}
        refresh(app)
    }
    func unbind(){task?.cancel();app?.stopObservingPractice(owner:owner);app?.releaseEarnedPractice(owner:owner);app=nil;onNavigate=nil;onHome=nil;onNotes=nil;onSound=nil}
    func start(_ app:AppModel){
        bind(app);guided=GuidedPracticeSession(account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(clock()),courses:app.plateCourses);persist(app)
        onNavigate?(guided?.current ?? "speak");refresh(app)
    }
    func cancel(_ app:AppModel){guided=nil;persist(app);refresh(app)}
    func presentationBlocked(_ blocked:Bool,app:AppModel){self.blocked=blocked;refresh(app)}
    func closeDailyGoal(_ app:AppModel){dailyGoalVisible=nil;app.dailyGoalReward=nil;refresh(app)}
    func closeNotes(_ app:AppModel){notesOpen=false;refresh(app)}
    func continuePractice(_ app:AppModel,viewNotes:Bool=false,ephemeralLesson:Bool=false){
        guard scope == context(app),visible != nil,let policy else{return}
        if viewNotes{notesOpen=true}
        let result=try? policy.run("continue",input(app,ephemeralLesson:ephemeralLesson));consume(result,app:app)
        if viewNotes{onNotes?()};refresh(app)
    }
    private func persist(_ app:AppModel){if let guided,let data=try? JSONEncoder().encode(guided){UserDefaults.standard.set(data,forKey:sessionKey(app))}else{UserDefaults.standard.removeObject(forKey:sessionKey(app))}}
    private func snapshot(_ app:AppModel)->JSONValue {
        let courses=app.plateCourses.map{JSONValue.object(["kind":.string($0.kind),"count":.number(Double($0.count)),"target":.number(Double($0.target)),"done":.bool($0.done)])}
        return .object(["langKey":.string(app.learner.target),"dayKey":.string(CalendarDay.key(clock())),"courses":.array(courses),"byKind":.object(Dictionary(uniqueKeysWithValues:courses.map{($0["kind"].string,$0)})),"isCleared":.bool(!courses.isEmpty && courses.allSatisfy{$0["done"].boolean})])
    }
    private func input(_ app:AppModel,ephemeralLesson:Bool=false)->JSONValue {
        let bp=app.learner.goalBucket["dailyGoal"]["blueprint"],plan=app.learner.repairPlan(day:CalendarDay.key(clock())) ?? .null,items=plan["items"].array
        let goalDetails:JSONValue=bp == .null ? .null:.object(["what":bp["objective"].string.isEmpty ? bp["goalText"]:bp["objective"],"why":bp["rationale"].string.isEmpty ? bp["scenario"]:bp["rationale"]])
        let repairDetails:JSONValue=items.isEmpty ? .null:.object(["what":.string(items.map{$0["originalConcept"].string.isEmpty ? $0["concept"].string:$0["originalConcept"].string}.filter{!$0.isEmpty}.joined(separator:" · ")),"why":.string(plan["summary"].string.isEmpty ? items.map{$0["summary"].string.isEmpty ? $0["expectedAnswer"].string:$0["summary"].string}.filter{!$0.isEmpty}.joined(separator:" "):plan["summary"].string)])
        return .object(["scope":.string(scope),"now":.number(clock().timeIntervalSince1970*1000),"snapshot":snapshot(app),"guided":.bool(guided != nil),"blocked":.bool(app.dailyGoalReward != nil || blocked || app.scholarship.pending != nil || app.hasEarnedPractice(excluding:owner) || app.lessonActivityActive || app.pendingLessonCompletion != nil || app.flashcardSession != nil || app.goalCheck != nil),"goalDetails":goalDetails,"repairDetails":repairDetails,"ephemeralLesson":.bool(ephemeralLesson)])
    }
    private func refresh(_ app:AppModel){
        guard !updating,app.signedIn,app.learner.onboardingComplete else{return}
        if scope != context(app){bind(app);return}
        guard let policy else{return};updating=true;defer{updating=false}
        task?.cancel()
        if let reward=app.dailyGoalReward {
            if reward.account != app.identity.npub || reward.day != CalendarDay.key(clock()){app.dailyGoalReward=nil;dailyGoalVisible=nil}
            else if !blocked && !app.dailyGoalBlocked(excluding:owner) && app.flashcardSession == nil && app.goalCheck == nil && visible == nil {dailyGoalVisible=reward}
        }else{dailyGoalVisible=nil}
        let awarded=DailyPlate.bonusAwarded(progress:app.learner.plateProgress,target:app.learner.target,day:CalendarDay.key(clock())),justClaimed=awarded && !bonusSeen;bonusSeen=awarded
        let result=try? policy.run("step",input(app).setting("bonusJustClaimed",.bool(justClaimed)))
        consume(result,app:app)
        app.retainEarnedPractice(owner:owner,active:pending != nil || visible != nil || notesOpen || app.dailyGoalReward != nil,account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(clock()))
        if let wake=result?["nextWake"],wake != .null {
            let delay=max(0,wake.number-clock().timeIntervalSince1970*1000),token=scope
            task=Task{[weak self,weak app] in try? await Task.sleep(for:.milliseconds(Int(min(60_000,delay))));guard !Task.isCancelled,let self,let app,self.scope == token else{return};self.refresh(app)}
        }
    }
    private func consume(_ result:JSONValue?,app:AppModel){
        guard let result else{return};pending=result["pending"] == .null ? nil:result["pending"];visible=result["visible"] == .null ? nil:result["visible"]
        for action in result["actions"].array {
            switch action["type"].string {
            case "endSession":guided=nil;persist(app)
            case "navigate":if var session=guided{_=session.advance(app.plateCourses);guided=session;persist(app)};onNavigate?(action["course"].string)
            case "surface":onHome?()
            case "courseComplete":app.plateCourseCompletion = .init(kind:action["kind"].string)
            case "sound":onSound?(action["name"].string)
            default:break
            }
        }
    }
}
