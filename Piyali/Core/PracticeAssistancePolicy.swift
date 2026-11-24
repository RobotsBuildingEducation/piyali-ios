import Foundation
import JavaScriptCore

/// Original DelightQuestionLab help/explanation prompt construction.
public final class PracticeAssistancePolicy {
    private let context:JSContext,api:JSValue
    public init(source:String)throws {guard let context=JSContext(),let api=context.evaluateScript(source),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.context=context;self.api=api}
    public convenience init(bundle:Bundle = .main)throws {guard let url=bundle.url(forResource:"practice-assistance-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public func build(_ operation:String,run:PracticeRun)throws->JSONValue {try runPolicy(operation,.object(["question":run.question.payload,"response":run.response,"targetLang":.string(run.question.target),"supportLang":.string(run.question.support),"revealedClues":.number(Double(run.revealedClues))]))}
    public func runPolicy(_ operation:String,_ input:JSONValue)throws->JSONValue {context.exception=nil;guard let text=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe};return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))}
}
