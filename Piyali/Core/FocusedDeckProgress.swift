import Foundation

/// Last acknowledged focused outcomes for presentation while newer local work is pending.
/// The cache stays in the account's private native snapshot, never in source artifact documents.
public extension LearnerState {
    func pendingGoalOutcomes(key:String)->Bool {
        (pendingGoalChanges ?? []).contains{change in change.action == .outcome && GoalPractice.artifactKey(target:change.target,day:change.payload["dayKey"].string,mode:change.payload["mode"].string,goalID:change.payload["goalId"].string) == key}
    }
    mutating func rememberFocusedBase(_ artifact:JSONValue,pending:Bool) {
        let key=artifact["ownerKey"].string;guard !key.isEmpty else{return}
        if confirmedFocusedOutcomes == nil{confirmedFocusedOutcomes=[:]}
        if !pending || confirmedFocusedOutcomes?[key] == nil {confirmedFocusedOutcomes?[key]=pending ? .object([:]):artifact["outcomes"]}
    }
    mutating func confirmFocusedArtifact(_ artifact:JSONValue) {
        let key=artifact["ownerKey"].string;guard !key.isEmpty else{return}
        if confirmedFocusedOutcomes == nil{confirmedFocusedOutcomes=[:]};confirmedFocusedOutcomes?[key]=artifact["outcomes"]
    }
    mutating func confirmFocusedArtifacts(in document:JSONValue) {
        for field in CompanionQuestDay.artifactFields.union([GoalPractice.artifactField(mode:"flashcards"),GoalPractice.artifactField(mode:"phonics")]) {confirmFocusedArtifact(document[field])}
    }
    mutating func confirmFocusedArtifacts(from snapshot:LearnerState) {
        for artifact in (snapshot.goalArtifacts ?? [:]).values {confirmFocusedArtifact(artifact)}
        for document in (snapshot.companionQuestDays ?? [:]).values {confirmFocusedArtifacts(in:document)}
    }
    func displayedGoalArtifact(_ blueprint:JSONValue,mode:String)->JSONValue {
        let key=GoalPractice.artifactKey(target:target,day:blueprint["dayKey"].string,mode:mode,goalID:blueprint["goalId"].string),artifact=goalArtifacts?[key] ?? .object([:])
        return pendingGoalOutcomes(key:key) ? artifact.setting("outcomes",confirmedFocusedOutcomes?[key] ?? .object([:])):artifact
    }
    func displayedRepairArtifact(_ step:RepairStep,mode:String)->JSONValue {
        let artifact=repairArtifact(step,mode:mode),pending=pendingCompanionQuestDays?[CompanionQuestDay.key(step.target,step.day)]?[CompanionQuestDay.artifactField(step,mode:mode)] ?? .null
        return pending != .null ? artifact.setting("outcomes",confirmedFocusedOutcomes?[artifact["ownerKey"].string] ?? .object([:])):artifact
    }
}
