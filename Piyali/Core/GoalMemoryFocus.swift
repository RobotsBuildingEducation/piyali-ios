import Foundation

/// A currently mounted Goal activity's capture context. It is never persisted in a run.
public struct GoalMemoryFocus:Sendable {
    public let target:String
    public let blueprint:JSONValue
    public init(target:String,blueprint:JSONValue){self.target=target;self.blueprint=blueprint}
    public func matches(_ learner:LearnerState,now:Date = Date())->Bool {
        guard target == learner.target,let daily=GoalPractice.today(learner.goalBucket,day:CalendarDay.key(now)) else{return false}
        return blueprint["lang"].string == target && blueprint["goalId"] == daily["blueprint"]["goalId"] && blueprint["dayKey"] == daily["blueprint"]["dayKey"] && GoalPractice.list(daily["blueprint"]["modes"],max:4).contains(blueprint["mode"].string)
    }
    public func payload(mode:String,concept:String,answer:String,expected:String)->JSONValue {
        .object(["goalId":blueprint["goalId"],"dayKey":blueprint["dayKey"],"target":.string(concept),"observation":.string(answer),"expectedAnswer":.string(expected),"mode":blueprint["mode"],"domain":.string(mode),"success":.bool(false),"support":.string("prompted")])
    }
}
