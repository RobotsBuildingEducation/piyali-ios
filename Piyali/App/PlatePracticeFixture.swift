import Foundation

/// A saved checkpoint for scoped simulator journeys; all subsequent interaction,
/// grading, completion and reward logic is the normal product implementation.
enum PlatePracticeFixture {
    nonisolated static var scenario:String {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_TUTOR_FIXTURE"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,["full","tutor-trial","conversation"].contains(env["PIYALI_PLATE_JOURNEY_FIXTURE"] ?? "") else{return ""}
        return env["PIYALI_PLATE_JOURNEY_FIXTURE"] ?? ""
        #else
        return ""
        #endif
    }
    nonisolated static func turnXP()->Int {scenario.isEmpty ? Int.random(in:3...7):5}
    @MainActor static func seed(_ app:AppModel){
        #if DEBUG
        guard !scenario.isEmpty else{return}
        let key="piyali.plateFixture.seeded."+app.identity.npub
        guard !UserDefaults.standard.bool(forKey:key),let catalog=try? ContentLibrary.load(JSONValue.self,name:"tutor-curriculum-"+app.learner.target),let unit=catalog["Pre-A1"].array.first,let lesson=unit["lessons"].array.first,let policy=try? TutorSourcePolicy(),let agenda=try? policy.run("state",.object(["lesson":lesson,"unit":unit,"target":.string(app.learner.target),"support":.string(app.learner.support),"earned":.number(47),"progress":.object([:])])) else{return}
        var learner=app.learner
        learner.goal="";learner.dailyGoal=100;learner.level="Pre-A1";learner.gettingStartedModalShown=true
        learner.tutorLessons=[learner.tutorKey(lesson["id"].string):TutorSourceProgress.importing(.object(["status":.string("in_progress"),"earnedXp":.number(47),"tutorAgendaProgress":.object(["schemaVersion":.number(2),"items":.object(Dictionary(uniqueKeysWithValues:agenda["items"].array.filter{$0["id"].string != "hello"}.map{($0["id"].string,.bool(true))}))])]))]
        learner.dailyKey=CalendarDay.key(Date());learner.dailyXP=47;learner.xpByLanguage=[learner.target:scenario == "full" ? 127:scenario == "conversation" ? 47:245]
        learner.companionProgress = .object(["dailyXp":.number(47),"dailyHasCelebrated":.bool(false),"dailyResetAt":.string(WebProgressContract.iso(Date().addingTimeInterval(86400))),"dailyGoalPetHealth":.number(100)])
        learner.questProgress = .object(["dailyQuestFirstSeen":.bool(true),"dailyQuestFirstDayKey":.string(learner.dailyKey)])
        learner.questPlans=[learner.target:DailyQuestPlan(day:learner.dailyKey,kinds:DailyPlate.introductory)]
        if scenario == "full" {
            learner.completed.insert(learner.completionKey(IntroTutorial.lessonID))
            learner.lessonWork=[learner.completionKey("lesson-pre-a1-1-1"):.init(earnedXP:80)]
            learner.questProgress=learner.plateProgress.setting("flashcardDailyActivity",.object([learner.target:.object([learner.dailyKey:.number(4)])]))
        }
        if scenario == "conversation" {
            learner.questProgress=learner.plateProgress.setting("dailyQuestFirstDayKey",.string(CalendarDay.shift(learner.dailyKey,by:-1)))
            learner.questPlans=[learner.target:DailyQuestPlan(day:learner.dailyKey,kinds:["conversation","review"])]
            let count=learner.plateCourses(user:app.identity.npub).first{$0.kind == "conversation"}?.target ?? 4
            learner.questProgress=learner.plateProgress.setting("conversationDailyActivity",.object([learner.target:.object([learner.dailyKey:.number(Double(count-1))])]))
        }
        learner.pendingChanges=[];app.learner=learner;UserDefaults.standard.set(true,forKey:key)
        UserDefaults.standard.set(true,forKey:"piyali.companionBubbleDismissed:"+app.identity.npub+":"+learner.target+":"+learner.dailyKey)
        #endif
    }
}
