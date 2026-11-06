import Foundation

extension AppModel {
    /// Original focused authored selection, captured IDs/roles and canonical localization.
    func focusedPhonicsDeck(goal:JSONValue?=nil,repair:RepairStep?=nil,artifact:JSONValue = .null)throws->JSONValue {
        guard let policy=companionQuestPolicy else{throw PracticeRecipeFailure.unavailable}
        let decks=phonicsLibrary.filter{$0.key.hasPrefix(learner.target+":"+learner.support+":")}
        let snapshot=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(decks))
        var focus:JSONValue = .object(["npub":.string(identity.npub),"targetLang":.string(learner.target),"supportLang":.string(learner.support)])
        if let goal{focus=focus.setting("blueprint",goal)}
        if let repair{focus=focus.setting("plan",repair.plan).setting("stepIndex",.number(Double(repair.index)))}
        let alphabet=LearningLanguages.levels.flatMap{snapshot[learner.target+":"+learner.support+":"+$0].array}.prefix(1)
        return try policy.run("focusedPhonicsDeck",.object(["decks":snapshot,"focus":focus,"alphabet":.array(Array(alphabet)),"artifact":artifact]))
    }
    func displayedPhonicsArtifact(goal:JSONValue?,repair:RepairStep?)throws->JSONValue {
        if let goal{return try focusedPhonicsDeck(goal:goal,artifact:learner.displayedGoalArtifact(goal,mode:"phonics"))}
        if let repair{return try focusedPhonicsDeck(repair:repair,artifact:learner.displayedRepairArtifact(repair,mode:"phonics"))}
        return .null
    }
}
