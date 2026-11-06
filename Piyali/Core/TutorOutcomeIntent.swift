import Foundation

/// A Tutor turn's source UI progress is immediate; its account award waits for
/// the original question-worth promise. This private, device-owned intent keeps
/// that delivery independent of a voice connection or controller lifetime.
public struct TutorOutcomeIntent:Codable,Identifiable,Sendable {
    public var id:UUID
    public var turn:PracticeChange?
    public var target:String
    public var level:String
    public var date:Date
    public var recordsAssessment:Bool?
    public var correct:Bool
    public var independent:Bool
    public var support:String?
    public var concept:String?
    public var worthParameters:JSONValue
    public var crossedDailyGoal:Bool
    public var day:String {CalendarDay.key(date)}
    public var dailyAmount:Int {max(0,turn?.amount ?? 0)}
    public init(id:UUID=UUID(),turn:PracticeChange?,target:String,level:String,date:Date=Date(),correct:Bool,independent:Bool,support:String?=nil,concept:String?=nil,recordsAssessment:Bool=true,worthParameters:JSONValue,crossedDailyGoal:Bool=false){self.id=id;self.turn=turn;self.target=target;self.level=level;self.date=date;self.correct=correct;self.independent=independent;self.support=support;self.concept=concept;self.recordsAssessment=recordsAssessment;self.worthParameters=worthParameters;self.crossedDailyGoal=crossedDailyGoal}
}

public extension LearnerState {
    /// Adds only the source's optimistic daily progress. Account XP and the
    /// assessment are not delivered until the frozen question quote resolves.
    mutating func queueTutorOutcome(_ raw:TutorOutcomeIntent) {
        guard !(pendingTutorOutcomes ?? []).contains(where:{$0.id == raw.id}),!(pendingChanges ?? []).contains(where:{$0.id == raw.id}),!(acknowledgedEventIDs ?? []).contains(raw.id) else{return}
        if raw.recordsAssessment == false {
            let receipts=Set((pendingChanges ?? []).map(\.id)).union(acknowledgedEventIDs ?? [])
            guard let turn=raw.turn,!receipts.contains(turn.id) else{return}
        }
        var outcome=raw
        if let turn=outcome.turn {
            let selected=target;target=outcome.target
            rollDay(now:outcome.date,calendar:.current)
            outcome.crossedDailyGoal=dailyXP<dailyGoal && dailyXP+turn.amount>=dailyGoal
            rewardCompanion(turn.amount,now:outcome.date);dailyXP += max(0,turn.amount);rememberActivity()
            target=selected
        }
        if pendingTutorOutcomes == nil{pendingTutorOutcomes=[]};pendingTutorOutcomes?.append(outcome)
    }
    @discardableResult mutating func deliverTutorOutcome(_ id:UUID,worth:JSONValue?)->Bool {
        guard let outcome=pendingTutorOutcomes?.first(where:{$0.id == id}) else{return false}
        let selected=target;target=outcome.target;defer{target=selected}
        let receiptIDs=Set((pendingChanges ?? []).map(\.id)).union(acknowledgedEventIDs ?? [])
        if let turn=outcome.turn,!receiptIDs.contains(turn.id) {
            xpByLanguage[outcome.target,default:0] += max(0,turn.amount)
            if outcome.crossedDailyGoal,CalendarDay.key(outcome.date)==dailyKey{streak += 1}
            enqueue(turn)
        }
        if outcome.recordsAssessment != false,!receiptIDs.contains(outcome.id) {
            assess(correct:outcome.correct,independent:outcome.independent,now:outcome.date,questionLevel:outcome.level,worth:worth == .null ? nil:worth,concept:outcome.concept,mode:"tutor",support:outcome.support,receiptID:outcome.id)
        }
        pendingTutorOutcomes?.removeAll{$0.id == id}
        return true
    }
    /// Firebase applies the turn receipt before its assessment. A stale private
    /// intent must stop projecting an award already present in canonical XP.
    mutating func reconcileTutorOutcomes(acknowledged:Set<UUID>) {
        pendingTutorOutcomes=pendingTutorOutcomes?.compactMap{raw in
            if raw.recordsAssessment != false,acknowledged.contains(raw.id){return nil}
            var outcome=raw
            if let turn=outcome.turn,acknowledged.contains(turn.id){
                if outcome.recordsAssessment == false{return nil}
                outcome.turn=nil
            }
            return outcome
        }
    }
    func pendingTutorDailyXP(day:String)->Int {(pendingTutorOutcomes ?? []).filter{$0.day == day}.reduce(0){$0+$1.dailyAmount}}
}
