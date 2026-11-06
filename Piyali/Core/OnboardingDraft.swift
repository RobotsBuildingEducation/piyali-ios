import Foundation

/// The welcome drawer keeps a separate optional goal for each practice
/// language. Changing support language never changes the chosen practice one.
public struct OnboardingDraft:Equatable,Sendable {
    public private(set) var pickedSupport=false
    public private(set) var support:String
    public private(set) var target:String
    public private(set) var learningGoals:[String:String]
    public init(support:String,target:String,learningGoals:[String:String]=[:]) {
        self.support=LearningLanguages.support.contains(support) ? support : "en"
        self.target=LearningLanguages.practice.contains(target) ? target : (support == "es" ? "en" : "es")
        self.learningGoals=learningGoals.mapValues(Self.limitedGoal)
    }
    public var goal:String {get{learningGoals[target] ?? ""}set{learningGoals[target]=Self.limitedGoal(newValue)}}
    public mutating func chooseSupport(_ code:String) {guard LearningLanguages.support.contains(code) else{return};support=code;pickedSupport=true}
    public mutating func resolveSupport(_ code:String) {guard !pickedSupport,LearningLanguages.support.contains(code) else{return};support=code}
    public mutating func choosePractice(_ code:String) {guard LearningLanguages.practice.contains(code) else{return};target=code}
    /// HTML maxlength counts UTF-16 units. Avoid cutting a surrogate pair when
    /// pasting into the native control at the 600-unit source limit.
    public static func limitedGoal(_ text:String)->String {
        var result=String.UnicodeScalarView(),count=0
        for scalar in text.unicodeScalars {let units=scalar.value>0xffff ? 2 : 1;guard count+units<=600 else{break};result.append(scalar);count+=units}
        return String(result)
    }
}
public extension LearnerState {
    mutating func completeOnboarding(_ draft:OnboardingDraft,now:Date=Date()) {
        support=draft.support;target=draft.target
        for language in draft.learningGoals.keys.sorted() where LearningLanguages.practice.contains(language) {
            let text=(draft.learningGoals[language] ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
            guard !text.isEmpty else{continue}
            applyGoal(GoalChange(action:.edit,target:language,date:now,payload:.object(["id":.string(UUID().uuidString.lowercased()),"text":.string(text),"status":.string("active")])))
        }
        goal=draft.goal.trimmingCharacters(in:.whitespacesAndNewlines)
        onboardingComplete=true;preferencesModifiedAt=now
    }
}
