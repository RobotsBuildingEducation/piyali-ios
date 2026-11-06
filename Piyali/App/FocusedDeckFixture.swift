import Foundation

/// Public acknowledged decks and a recording save boundary for isolated simulator journeys.
@MainActor enum FocusedDeckFixture {
    static var scenario:String {
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        if e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,["goal","repair"].contains(e["PIYALI_FOCUSED_DECK_FIXTURE"] ?? ""){return e["PIYALI_FOCUSED_DECK_FIXTURE"]!}
        #endif
        return ""
    }
    static func progressService()->(any LearnerProgressService)? {
        #if DEBUG
        return scenario.isEmpty ? nil:FocusedDeckFixtureStore()
        #else
        return nil
        #endif
    }
    static var freshGoalResponse:(@MainActor(String)async throws->String)? {
        #if DEBUG
        if scenario == "goal",ProcessInfo.processInfo.environment["PIYALI_FOCUSED_DECK_FRESH"] == "1"{return {_ in throw URLError(.notConnectedToInternet)}}
        #endif
        return nil
    }
    static func seed(_ app:AppModel) {
        #if DEBUG
        guard !scenario.isEmpty else{return};let key="piyali.focusedDeckFixture."+app.identity.npub
        guard !UserDefaults.standard.bool(forKey:key) else{return};var state=app.learner;let day=CalendarDay.key(Date())
        if scenario == "goal" {
            state.editGoal("Speak with family")
            let bp:JSONValue = .object(["goalId":state.goalBucket["activeGoal"]["id"],"goalText":.string(state.goal),"dayKey":.string(day),"lang":.string(state.target),"mode":.string("flashcards"),"modes":.array(["flashcards","lesson"].map(JSONValue.string)),"modeTargets":.object(["flashcards":.number(3),"lesson":.number(20)]),"cefrLevel":.string("Pre-A1"),"objective":.string("Name your family members"),"scenario":.string("Talk about your family."),"targetLanguage":.array(["papá","hermana","mamá"].map(JSONValue.string)),"supports":.array([.string("Use a short cue")]),"successCriteria":.array([.string("Recall the family words")])])
            state.applyGoal(.init(action:.blueprint,target:state.target,payload:bp))
            let cards=(try? app.companionQuestPolicy?.run("goalDeckCards",.object(["focus":.object(["blueprint":bp,"targetLang":.string(state.target),"supportLang":.string(state.support)]),"raw":.string("[{\"target\":\"papá\",\"support\":\"dad\"},{\"target\":\"hermana\",\"support\":\"sister\"},{\"target\":\"mamá\",\"support\":\"mom\"}]")])) ) ?? .array([])
            if ProcessInfo.processInfo.environment["PIYALI_FOCUSED_DECK_FRESH"] != "1"{state.applyGoal(.init(action:.artifact,target:state.target,payload:bp.setting("mode",.string("flashcards")).setting("cards",cards)))};state.questPlans=[state.target:.init(day:day,kinds:["goal","review"])]
        } else {
            state.goal="";state.goalIntelligence=[:]
            let items:JSONValue = .array([.object(["memoryId":.string("greeting"),"concept":.string("A greeting"),"expectedAnswer":.string("Hola"),"mode":.string("flashcards"),"errorType":.string("vocabulary"),"cefrLevel":.string("Pre-A1")]),.object(["memoryId":.string("agreement"),"concept":.string("A simple agreement"),"expectedAnswer":.string("Soy estudiante"),"mode":.string("lesson"),"errorType":.string("grammar"),"cefrLevel":.string("Pre-A1")])])
            let plan:JSONValue = .object(["targetLang":.string(state.target),"dayKey":.string(day),"target":.number(2),"items":items,"memoryIds":.array(["greeting","agreement"].map(JSONValue.string))])
            state.companionMemory=[state.target:items.array.map{item in MemoryNote(fields:["id":item["memoryId"],"concept":item["concept"],"expectedAnswer":item["expectedAnswer"],"errorType":item["errorType"],"sourceMode":item["errorType"],"createdDayKey":.string(CalendarDay.shift(day,by:-1)),"createdAt":.number(Date().addingTimeInterval(-86400).timeIntervalSince1970*1000),"expiresAfterDayKey":.string(day),"status":.string("captured"),"severity":.number(1),"supportLang":.string(state.support),"targetLang":.string(state.target)])}]
            state.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:state.target,day:day)
            if let raw=try? app.companionQuestPolicy?.run("next",.object(["plan":plan,"completedCount":.number(0)])),let step=try? JSONDecoder().decode(RepairStep.self,from:Data(raw.json.utf8)) {
                let cards:JSONValue = .array([("Hola","Hello"),("Gracias","Thanks")].enumerated().map{index,pair in .object(["id":.string("repair-\(state.target)-\(day)-s0-c\(index)"),"concept":.object(["es":.string(pair.0),"en":.string(pair.1)]),"category":.string("repair"),"type":.string("phrase"),"cefrLevel":.string("Pre-A1"),"isRepair":.bool(true)])})
                state.storeRepairArtifact(.object(["ownerKey":.string(CompanionQuestDay.artifactKey(step,mode:"flashcards")),"cards":cards,"outcomes":.object([:])]),step:step,mode:"flashcards")
            }
            state.questPlans=[state.target:.init(day:day,kinds:["repair","review"])]
        }
        state.questProgress=state.plateProgress.setting("dailyQuestFirstSeen",.bool(true)).setting("dailyQuestFirstDayKey",.string(CalendarDay.shift(day,by:-1)))
        state.pendingGoalChanges=[];state.pendingCompanionQuestDays=[:];state.pendingMemoryChanges=[];app.learner=state;UserDefaults.standard.set(true,forKey:key)
        #endif
    }
}
#if DEBUG
@MainActor private final class FocusedDeckFixtureStore:LearnerProgressService {
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState? {
        guard !FocusedDeckFixture.scenario.isEmpty,!npub.isEmpty else{throw CancellationError()}
        if ProcessInfo.processInfo.environment["PIYALI_FOCUSED_DECK_PREPARATION_OFFLINE"] == "1",(state.pendingGoalChanges ?? []).contains(where:{$0.action == .artifact}){throw URLError(.notConnectedToInternet)}
        var saved=state;saved.pendingChanges=[];saved.pendingGoalChanges=[];saved.pendingMemoryChanges=[];saved.pendingCompanionQuestDays=[:];saved.pendingRepairEvidence=[];saved.pendingPlacements=[:];saved.pendingSettingsChanges=[];saved.pendingImmersionChanges=[];saved.pendingPlateHeadlines=[:];saved.pendingCompanionQuestDays=[:];return saved
    }
}
#endif
