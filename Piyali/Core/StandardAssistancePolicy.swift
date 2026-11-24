import Foundation

/// Original inline legacy callbacks and submitted snapshots; provider and clipboard I/O stay native.
public final class StandardAssistancePolicy {
    private let engine:PracticeAssistancePolicy
    public init(source:String)throws{engine=try PracticeAssistancePolicy(source:source)}
    public convenience init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"standard-assistance",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public func runPolicy(_ operation:String,_ input:JSONValue)throws->JSONValue{try engine.runPolicy(operation,input)}
    public func build(_ operation:String,run:PracticeRun,level:String="beginner",showTranslations:Bool?=nil)throws->JSONValue{
        let q=run.question
        var input:JSONValue = .object(["module":.string(q.module.rawValue),"kind":.string(q.kind),"q":q.payload,"response":operation == "explanation" ? run.lastMissedResponse ?? run.response:run.response,"bank":.array(run.bank.map(JSONValue.string)),"targetLang":.string(q.target),"supportLang":.string(q.support),"level":.string(level.isEmpty ? "beginner":level),"showTranslations":.bool(showTranslations ?? (q.options["showTranslations"] != .bool(false)))])
        if operation == "explanation",run.lastMissedResponse == nil,let saved=run.lastMissedAnswer{input=input.setting("legacySubmittedAnswer",.string(saved))}
        return try engine.runPolicy(operation,input)
    }
}
