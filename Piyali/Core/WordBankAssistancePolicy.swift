import Foundation

/// The original child help callback and parent prompt construction, without provider I/O.
public final class WordBankAssistancePolicy {
    private let engine:PracticeAssistancePolicy
    public init(source:String)throws{engine=try PracticeAssistancePolicy(source:source)}
    public convenience init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"word-bank-assistance",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public func runPolicy(_ operation:String,_ input:JSONValue)throws->JSONValue{try engine.runPolicy(operation,input)}
    public func build(_ operation:String,run:PracticeRun,level:String="beginner")throws->JSONValue {
        let q=run.question,p=q.payload
        return try engine.runPolicy(operation,.object(["module":.string(q.module.rawValue),"kind":.string(q.kind),"sourceSentence":.string(q.audioText),"wordBank":.array(run.bank.map(JSONValue.string)),"correctWords":p["correctWords"],"hint":p["hint"] == .null ? .string(""):p["hint"],"userAnswer":.string(operation == "explanation" ? run.lastMissedAnswer ?? run.answerText:run.answerText),"targetLang":.string(q.target),"supportLang":.string(q.support),"level":.string(level.isEmpty ? "beginner":level)]))
    }
}
