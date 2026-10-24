import Foundation

extension AppModel {
    func registerGoalEditor(id:UUID,flush:@escaping ()->Void){if let current=goalEditorFlush,current.id != id {current.flush()};goalEditorFlush=(id,flush)}
    func unregisterGoalEditor(id:UUID){if goalEditorFlush?.id == id {goalEditorFlush=nil}}
    func flushGoalEditor(){goalEditorFlush?.flush();goalEditorFlush=nil}
    var goalCourseScope:GoalCourseScope {.init(account:identity.npub,target:learner.target,support:learner.support,goalID:learner.goalBucket["activeGoal"]["id"].string,day:CalendarDay.key(Date()))}
    func goalText(_ key:String)->String {
        guard let policy=companionQuestPolicy,let copy=try? policy.run("goalCopy",.object(["lang":.string(learner.support)])) else{return key}
        return copy[key].string
    }
    func goalCompletionText(_ key:String)->String {
        guard let policy=companionQuestPolicy,let copy=try? policy.run("goalCompletionCopy",.object(["lang":.string(learner.support)])) else{return key}
        return copy[key].string
    }
    func sourceGoalLesson(_ blueprint:JSONValue)throws->Lesson {
        guard let policy=companionQuestPolicy else{throw PracticeRecipeFailure.unavailable}
        let value=try policy.run("goalLesson",.object(["blueprint":blueprint]))
        return try JSONDecoder().decode(Lesson.self,from:Data(value.setting("agenda",.object([:])).json.utf8))
    }
    func sourceGoalInstructions(_ blueprint:JSONValue)->String? {
        try? companionQuestPolicy?.run("goalInstructions",.object(["blueprint":blueprint,"supportLang":.string(learner.support)])).string
    }
    func buildDailyGoal() async throws {
        let scope=goalCourseScope
        await sync();try Task.checkCancellation();guard goalCourseScope == scope else{throw CancellationError()}
        guard (learner.pendingGoalChanges ?? []).filter({$0.target == scope.target}).isEmpty else{throw AppError.message("Reconnect and sync to save your goal across devices.")}
        guard GoalPractice.active(learner.goalBucket) != nil,let policy=companionQuestPolicy else{return}
        let args:JSONValue = .object(["user":learner.companionQuestUser,"targetLang":.string(scope.target),"supportLang":.string(scope.support),"dayKey":.string(scope.day),"cefrLevel":.string(learner.level),"now":.number(Date().timeIntervalSince1970*1000)])
        let plan=try policy.run("goalPlan",args)
        if let daily=readyGoal {
            if GoalPractice.needsBundleUpgrade(daily) {
                let upgraded=try policy.run("goalNormalize",.object(["raw":daily["blueprint"],"context":plan["context"]]))
                learner.applyGoal(GoalChange(action:.bundleUpgrade,target:scope.target,payload:upgraded));persist();await sync()
                try Task.checkCancellation();guard goalCourseScope == scope else{throw CancellationError()}
                guard readyGoal != nil else{throw AppError.message("Reconnect and sync to save today's goal activities.")}
            }
            return
        }
        let state=learner
        var candidate=plan["fallback"]
        do {
            let raw=try await ai.responsesText(plan["prompt"].string),parsed=try policy.run("goalParse",.object(["raw":.string(raw)]))
            candidate=try policy.run("goalNormalize",.object(["raw":parsed,"context":plan["context"]]))
        }catch is CancellationError{throw CancellationError()}catch{} // The original deterministic goal remains usable during provider failure.
        try Task.checkCancellation();guard goalCourseScope == scope else{throw CancellationError()}
        let question=JSONValue.object(Dictionary(uniqueKeysWithValues:["objective","scenario","targetLanguage","successCriteria"].map{($0,candidate[$0])}))
        let worth=try await GeneratedQuestionWorth.assess(question:question,level:candidate["cefrLevel"].string,mode:"goal:"+candidate["mode"].string,learner:state,recipes:PracticeRecipes(),ai:ai)
        try Task.checkCancellation();guard goalCourseScope == scope else{throw CancellationError()}
        candidate=candidate.setting("worth",worth)
        learner.applyGoal(GoalChange(action:.blueprint,target:scope.target,payload:candidate));persist();await sync()
        try Task.checkCancellation();guard goalCourseScope == scope else{throw CancellationError()}
        guard readyGoal != nil else{throw AppError.message("Reconnect and sync to save today's goal activities.")}
    }
    func authoredGoalPhonics(_ blueprint:JSONValue)->[PhonicsCard] {
        let decks=phonicsLibrary.filter{$0.key.hasPrefix(learner.target+":"+learner.support+":")}
        guard let data=try? JSONEncoder().encode(decks),let snapshot=try? JSONDecoder().decode(JSONValue.self,from:data),let values=try? companionQuestPolicy?.run("phonics",.object(["decks":snapshot,"focus":.object(["targetLang":.string(learner.target),"supportLang":.string(learner.support),"blueprint":blueprint])])) else{return []}
        return (try? JSONDecoder().decode([PhonicsCard].self,from:Data(values.json.utf8))) ?? []
    }
    func preserveEarnedGoalLesson(_ lesson:Lesson?)->Bool {guard let lesson,lesson.isGoal == true else{return false};return canComplete(lesson)}
    func completeFocusedGoalLesson(_ lesson:Lesson) async throws {
        guard lesson.isGoal == true,let bp=lesson.goalBlueprint,bp["mode"].string == "lesson",goalIsCurrent(bp) else{throw CancellationError()}
        let scope=goalCourseScope
        if (readyGoal?["modeProgress"]["lesson"].number ?? 0) < 20 {
            guard GoalLessonProgress.ready(learner.goalBucket,goalID:bp["goalId"].string,day:bp["dayKey"].string,lessonID:lesson.id,target:lesson.xpReward) else{throw AppError.message(goalCompletionText("error"))}
            let existing=(learner.pendingGoalChanges ?? []).contains{$0.action == .attempt && $0.payload["requireLessonCompletion"].boolean && $0.target == scope.target && $0.payload["goalId"] == bp["goalId"] && $0.payload["dayKey"] == bp["dayKey"]}
            if !existing {
                let payload:JSONValue = .object(["goalId":bp["goalId"],"dayKey":bp["dayKey"],"mode":.string("lesson"),"success":.bool(true),"support":.string("prompted"),"domain":.string("production"),"observation":.string("Completed today's goal-specific lesson exercises for: "+bp["objective"].string+". Correct graded answers reached the lesson target with models and hints available. This demonstrates supported practice, not independent real-world mastery."),"requireLessonCompletion":.bool(true),"priorModeProgress":learner.goalBucket["dailyGoal"]["modeProgress"]["lesson"]])
                learner.applyGoal(GoalChange(action:.attempt,target:scope.target,payload:payload));persist()
            }
            await sync();try Task.checkCancellation();guard goalCourseScope == scope else{throw CancellationError()}
            guard (readyGoal?["modeProgress"]["lesson"].number ?? 0) >= 20 else{throw AppError.message(goalCompletionText("error"))}
        }
        learner.completed.insert(learner.completionKey(lesson.id));persist()
    }
}
