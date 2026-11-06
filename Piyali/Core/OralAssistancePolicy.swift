import Foundation

public final class OralAssistancePolicy {
    private let engine:PracticeAssistancePolicy
    public init(source:String)throws{engine=try PracticeAssistancePolicy(source:source)}
    public convenience init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"oral-assistance",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public func runPolicy(_ operation:String,_ input:JSONValue)throws->JSONValue{try engine.runPolicy(operation,input)}
    public func build(_ operation:String,run:PracticeRun,level:String="beginner")throws->JSONValue{try engine.runPolicy(operation,.object(["module":.string(run.question.module.rawValue),"kind":.string(run.question.kind),"q":run.question.payload,"targetLang":.string(run.question.target),"supportLang":.string(run.question.support),"level":.string(level.isEmpty ? "beginner":level),"userAnswer":.string(operation == "explanation" ? run.lastMissedAnswer ?? run.answerText:run.answerText)]))}
}
