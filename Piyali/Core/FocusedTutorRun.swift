import Foundation

/// Device-private continuity for the source's ephemeral Goal/Repair Tutor lesson.
/// It holds earned progress and dependent receipt identity, never a new voice run.
public struct FocusedTutorRun:Codable,Identifiable,Sendable {
    public let id:UUID
    public let account,target,support,day:String
    public let goal:JSONValue?
    public let repair:RepairStep?
    public let lesson:JSONValue
    public var earnedXP:Int
    public let required:Int
    public var evidence:JSONValue
    public var outcomeIDs:Set<UUID>
    public var ready:Bool
    public var completionID:UUID?
    public init?(account:String,target:String,support:String,goal:JSONValue?,repair:RepairStep?,lesson:JSONValue,required:Int) {
        guard !account.isEmpty,!target.isEmpty,!support.isEmpty,(goal != nil) != (repair != nil),required>0,!lesson["id"].string.isEmpty else{return nil}
        let day=goal?["dayKey"].string ?? repair?.day ?? ""
        guard !day.isEmpty,goal == nil || !(goal?["goalId"].string ?? "").isEmpty else{return nil}
        self.id=UUID();self.account=account;self.target=target;self.support=support;self.day=day;self.goal=goal;self.repair=repair;self.lesson=lesson;self.required=required;self.earnedXP=0;self.evidence = .object([:]);self.outcomeIDs=[];self.ready=false;self.completionID=nil
    }
    public var focusKey:String {if let goal{return "goal:"+goal["goalId"].string+":"+day+":"+goal["mode"].string};return repair.map{$0.id+":"+$0.mode} ?? ""}
    public var key:String {target+":"+support+":"+focusKey}
}
public extension LearnerState {
    mutating func storeFocusedTutorRun(_ run:FocusedTutorRun){if focusedTutorRuns == nil{focusedTutorRuns=[:]};focusedTutorRuns?[run.key]=run}
    @discardableResult mutating func retireFocusedTutorRun(_ run:FocusedTutorRun)->Bool {guard focusedTutorRuns?[run.key]?.id == run.id else{return false};focusedTutorRuns?.removeValue(forKey:run.key);return true}
}
