import Foundation

@MainActor enum FocusedPhonicsFixture {
    static var scenario:String {
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        if e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,["goal","repair"].contains(e["PIYALI_FOCUSED_PHONICS_FIXTURE"] ?? ""){return e["PIYALI_FOCUSED_PHONICS_FIXTURE"]!}
        #endif
        return ""
    }
    static func progressService()->(any LearnerProgressService)? {
        #if DEBUG
        return scenario.isEmpty ? nil:FocusedPhonicsFixtureStore()
        #else
        return nil
        #endif
    }
    static func seed(_ app:AppModel) {
        #if DEBUG
        guard !scenario.isEmpty else{return};let key="piyali.focusedPhonicsFixture."+app.identity.npub;guard !UserDefaults.standard.bool(forKey:key) else{return}
        if app.phonicsLibrary.isEmpty {app.phonicsLibrary=(try? ContentLibrary.load([String:[PhonicsCard]].self,name:"phonics")) ?? [:]}
        var state=app.learner;let day=CalendarDay.key(Date()),yesterday=CalendarDay.shift(day,by:-1)
        if scenario == "goal" {
            state.editGoal("Pronounce Spanish clearly")
            let bp:JSONValue = .object(["goalId":state.goalBucket["activeGoal"]["id"],"goalText":.string(state.goal),"dayKey":.string(day),"lang":.string(state.target),"mode":.string("phonics"),"modes":.array(["phonics","lesson"].map(JSONValue.string)),"modeTargets":.object(["phonics":.number(2),"lesson":.number(20)]),"cefrLevel":.string("Pre-A1"),"objective":.string("Pronounce casa and mesa"),"scenario":.string("Say the Spanish words clearly."),"targetLanguage":.array([.string("casa")]),"supports":.array([.string("Listen to a model")]),"successCriteria":.array([.string("Pronounce both words")])])
            state.applyGoal(.init(action:.blueprint,target:state.target,payload:bp))
            let artifact=(try? app.focusedPhonicsDeck(goal:bp)) ?? .null
            state.applyGoal(.init(action:.artifact,target:state.target,payload:bp.setting("cards",artifact["cards"])));state.questPlans=[state.target:.init(day:day,kinds:["goal","review"])]
        }else{
            state.goal="";state.goalIntelligence=[:]
            let item:JSONValue = .object(["memoryId":.string("pronunciation"),"concept":.string("casa"),"expectedAnswer":.string("casa"),"mode":.string("phonics"),"errorType":.string("phonics"),"cefrLevel":.string("Pre-A1"),"sourceContext":.object(["card":.object(["practiceWord":.string("casa")])])]),plan:JSONValue = .object(["targetLang":.string(state.target),"dayKey":.string(day),"target":.number(2),"items":.array([item,.object(["memoryId":.string("agreement"),"concept":.string("Soy estudiante"),"mode":.string("lesson"),"errorType":.string("grammar"),"cefrLevel":.string("Pre-A1")])]),"memoryIds":.array(["pronunciation","agreement"].map(JSONValue.string))])
            state.companionMemory=[state.target:[MemoryNote(fields:["id":item["memoryId"],"concept":item["concept"],"expectedAnswer":item["expectedAnswer"],"errorType":item["errorType"],"sourceMode":.string("phonics"),"createdDayKey":.string(yesterday),"createdAt":.number(Date().addingTimeInterval(-86400).timeIntervalSince1970*1000),"expiresAfterDayKey":.string(day),"status":.string("captured"),"severity":.number(1),"supportLang":.string(state.support),"targetLang":.string(state.target)])]]
            state.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:state.target,day:day)
            if let raw=try? app.companionQuestPolicy?.run("next",.object(["plan":plan,"completedCount":.number(0)])),let step=try? JSONDecoder().decode(RepairStep.self,from:Data(raw.json.utf8)),let artifact=try? app.focusedPhonicsDeck(repair:step){state.storeRepairArtifact(artifact,step:step,mode:"phonics")}
            state.questPlans=[state.target:.init(day:day,kinds:["repair","review"])]
        }
        state.questProgress=state.plateProgress.setting("dailyQuestFirstSeen",.bool(true)).setting("dailyQuestFirstDayKey",.string(yesterday));state.pendingGoalChanges=[];state.pendingCompanionQuestDays=[:];state.pendingMemoryChanges=[];app.learner=state;UserDefaults.standard.set(true,forKey:key)
        #endif
    }
}
#if DEBUG
@MainActor private final class FocusedPhonicsFixtureStore:LearnerProgressService {
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState? {
        guard !FocusedPhonicsFixture.scenario.isEmpty,!npub.isEmpty else{throw CancellationError()}
        if ProcessInfo.processInfo.environment["PIYALI_FOCUSED_PHONICS_COMPLETION_OFFLINE"] == "1",!(state.pendingRepairEvidence ?? []).isEmpty{throw URLError(.notConnectedToInternet)}
        var saved=state;saved.pendingChanges=[];saved.pendingGoalChanges=[];saved.pendingMemoryChanges=[];saved.pendingCompanionQuestDays=[:];saved.pendingRepairEvidence=[];saved.pendingPlacements=[:];saved.pendingSettingsChanges=[];saved.pendingImmersionChanges=[];saved.pendingPlateHeadlines=[:];return saved
    }
}
#endif
