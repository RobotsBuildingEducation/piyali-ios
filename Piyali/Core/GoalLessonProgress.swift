import Foundation

/// Source lessonProgress.js: only XP earned in this goal/day's ephemeral lesson fills its own counter.
public enum GoalLessonProgress {
    public static func earned(_ bucket:JSONValue)->Double {max(0,bucket["dailyGoal"]["preparationXp"].number)}
    public static func matches(_ bucket:JSONValue,goalID:String,day:String,lessonID:String)->Bool {
        let goal=bucket["activeGoal"],blueprint=bucket["dailyGoal"]["blueprint"]
        return !goalID.isEmpty && !day.isEmpty && goal["status"].string == "active" && goal["id"].string == goalID && blueprint["goalId"].string == goalID && blueprint["dayKey"].string == day && lessonID == "goal-\(goalID)-\(day)"
    }
    public static func applying(_ change:PracticeChange,to bucket:JSONValue)->JSONValue {
        guard let id=change.skillTreeLessonID,id.hasPrefix("goal-"),change.earnedAmount > 0 else{return bucket}
        let goalID=bucket["dailyGoal"]["blueprint"]["goalId"].string
        guard matches(bucket,goalID:goalID,day:change.dayKey,lessonID:id) else{return bucket}
        return bucket.setting("dailyGoal",bucket["dailyGoal"].setting("preparationXp",.number(earned(bucket)+Double(change.earnedAmount))))
    }
    public static func ready(_ bucket:JSONValue,goalID:String,day:String,lessonID:String,target:Int=20)->Bool {
        guard target > 0,matches(bucket,goalID:goalID,day:day,lessonID:lessonID) else{return false}
        return bucket["dailyGoal"]["completed"].boolean || earned(bucket) >= Double(target)
    }
}
public extension LearnerState {
    mutating func applyGoalLessonWork(_ change:PracticeChange) {
        let original=goalIntelligence?[change.target] ?? .object([:]),next=GoalLessonProgress.applying(change,to:original)
        guard next != original else{return}
        if goalIntelligence == nil {goalIntelligence=[:]};goalIntelligence?[change.target]=next
    }
    /// Keep the next-activity conductor and plate bonus on acknowledged mode completions.
    /// Local evidence/outboxes are retained; they do not impersonate a successful server commit.
    var confirmedGoalBucket:JSONValue {
        var bucket=goalBucket,daily=bucket["dailyGoal"],progress=daily["modeProgress"]
        let pending=(pendingGoalChanges ?? []).filter{$0.action == .attempt && $0.target == target && $0.payload["success"].boolean && $0.payload["goalId"] == daily["blueprint"]["goalId"] && $0.payload["dayKey"] == daily["blueprint"]["dayKey"]}
        guard !pending.isEmpty else{return bucket}
        for change in pending.sorted(by:{$0.date < $1.date}) {
            let mode=change.payload["mode"].string
            progress=progress.setting(mode,.number(max(0,min(progress[mode].number,change.payload["priorModeProgress"].number))))
        }
        let modes=GoalPractice.list(daily["blueprint"]["modes"],max:4)
        daily=daily.setting("modeProgress",progress).setting("completed",.bool(!modes.isEmpty && modes.allSatisfy{progress[$0].number >= Double(GoalPractice.targets[$0] ?? 1)}))
        bucket=bucket.setting("dailyGoal",daily);return bucket
    }
}

public struct GoalCourseScope:Equatable,Sendable {
    public let account:String,target:String,support:String,goalID:String,day:String
    public init(account:String,target:String,support:String,goalID:String,day:String){self.account=account;self.target=target;self.support=support;self.goalID=goalID;self.day=day}
}
public extension GoalPractice {
    static func needsBundleUpgrade(_ daily:JSONValue)->Bool {
        guard !daily["completed"].boolean else{return false}
        let bp=daily["blueprint"],bundle=list(bp["modes"],max:4).filter{modes.contains($0)}
        return bundle.count < 2 || bp["mode"].string == "conversation" || list(bp["modes"],max:4).contains("conversation") || bundle.contains{bp["modeTargets"][$0].number != Double(targets[$0] ?? 1)}
    }
}

public enum GoalText {
    public static func limit(_ text:String,units:Int)->String {
        var result=String.UnicodeScalarView(),count=0
        for scalar in text.unicodeScalars {let size=scalar.value>0xffff ? 2:1;guard count+size<=max(0,units) else{break};result.append(scalar);count+=size}
        return String(result)
    }
}
