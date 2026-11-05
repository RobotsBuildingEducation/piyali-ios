import Foundation

/// An acknowledged public Goal blueprint for the isolated product journey.
/// This seeds no answers, evidence, rewards or active routing context.
enum GoalPracticeFixture {
    @MainActor static func seed(_ app:AppModel){
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_LIVE_API_TESTS"] != "1",e["PIYALI_GOAL_PRACTICE_FIXTURE"] == "lesson",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{return}
        let key="piyali.goalPracticeFixture.seeded."+app.identity.npub
        guard !UserDefaults.standard.bool(forKey:key) else{return}
        var state=app.learner;state.editGoal("Speak with family")
        let day=CalendarDay.key(Date()),bp:JSONValue = .object(["goalId":state.goalBucket["activeGoal"]["id"],"goalText":.string(state.goal),"dayKey":.string(day),"lang":.string(state.target),"mode":.string("lesson"),"modes":.array(["lesson","tutor"].map(JSONValue.string)),"modeTargets":.object(["lesson":.number(20),"tutor":.number(25)]),"cefrLevel":.string("Pre-A1"),"objective":.string("Greet a family member"),"scenario":.string("You are visiting family. Start a short conversation in Spanish."),"targetLanguage":.array(["Hola","¿Cómo estás?"].map(JSONValue.string)),"supports":.array([.string("Use a model")]),"successCriteria":.array([.string("Say hello")])])
        state.applyGoal(GoalChange(action:.blueprint,target:state.target,payload:bp));state.pendingGoalChanges=[]
        state.questPlans=[state.target:DailyQuestPlan(day:day,kinds:["goal","review"])]
        state.questProgress=state.plateProgress.setting("dailyQuestFirstSeen",.bool(true)).setting("dailyQuestFirstDayKey",.string(CalendarDay.shift(day,by:-1)))
        app.learner=state;UserDefaults.standard.set(true,forKey:key)
        #endif
    }
}
