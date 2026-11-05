import Foundation

/// Local continuation of an already graded, rewarded pronunciation. Never a new practice request.
public struct PhonicsFinishIntent:Codable,Equatable,Sendable,Identifiable {
    public let id:UUID
    public let account,target,support,day:String
    public let goal:JSONValue?
    public let repair:RepairStep?
    public init?(id:UUID,account:String,target:String,support:String,goal:JSONValue?,repair:RepairStep?) {
        guard !account.isEmpty,!target.isEmpty,(goal != nil) != (repair != nil) else{return nil}
        let day=goal?["dayKey"].string ?? repair?.day ?? ""
        guard !day.isEmpty,goal == nil || !(goal?["goalId"].string ?? "").isEmpty else{return nil}
        self.id=id;self.account=account;self.target=target;self.support=support;self.day=day;self.goal=goal;self.repair=repair
    }
    public var key:String {
        if let goal{return GoalPractice.artifactKey(target:target,day:day,mode:"phonics",goalID:goal["goalId"].string)}
        return repair.map{CompanionQuestDay.artifactKey($0,mode:"phonics")} ?? ""
    }
}
public extension LearnerState {
    mutating func queuePhonicsFinish(_ intent:PhonicsFinishIntent){if pendingPhonicsFinishes == nil{pendingPhonicsFinishes=[:]};pendingPhonicsFinishes?[intent.key]=intent}
    @discardableResult mutating func retirePhonicsFinish(_ intent:PhonicsFinishIntent)->Bool {
        guard pendingPhonicsFinishes?[intent.key]?.id == intent.id else{return false};pendingPhonicsFinishes?.removeValue(forKey:intent.key);return true
    }
    func hasPendingPhonicsReceipt(_ intent:PhonicsFinishIntent)->Bool {
        if (pendingChanges ?? []).contains(where:{$0.id == intent.id}){return true}
        if let goal=intent.goal{return (pendingGoalChanges ?? []).contains{$0.target == intent.target && $0.payload["goalId"] == goal["goalId"] && $0.payload["dayKey"].string == intent.day && $0.payload["mode"].string == "phonics"}}
        if let step=intent.repair{return (pendingCompanionQuestDays?[CompanionQuestDay.key(intent.target,intent.day)]?[CompanionQuestDay.artifactField(step,mode:"phonics")] ?? .null) != .null}
        return false
    }
}
