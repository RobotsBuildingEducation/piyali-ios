import Foundation

public extension PracticeChange {
    var pendingRepairIndex:Int? {
        guard source == .repair else{return nil}
        if let repairStepIndex,repairStepIndex>=0{return repairStepIndex}
        // Existing queued step receipts predate the explicit index field.
        let prefix="repair-\(target)-\(dayKey)-s";guard let contentID,contentID.hasPrefix(prefix),let value=Int(contentID.dropFirst(prefix.count)),value>=0 else{return nil};return value
    }
}
public extension LearnerState {
    /// A saved pronunciation/lesson is distinct from its dependent repair-step commit.
    /// Keep the conductor and plate bonus behind the outstanding completion receipt.
    var confirmedPlateProgress:JSONValue {
        var progress=plateProgress
        for change in pendingChanges ?? [] {
            guard let index=change.pendingRepairIndex else{continue}
            let byTarget=progress["repairDailyActivity"],days=byTarget[change.target],count=days[change.dayKey].number
            progress=progress.setting("repairDailyActivity",byTarget.setting(change.target,days.setting(change.dayKey,.number(max(0,min(count,Double(index)))))))
        }
        return progress
    }
}
