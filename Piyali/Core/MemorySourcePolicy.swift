import Foundation
import JavaScriptCore

/// Original Memory prompts, parsers, language guards, copy and display rules.
/// Provider calls are explicit response snapshots; native code owns their I/O.
@MainActor public final class MemorySourcePolicy {
    private let context:JSContext,api:JSValue
    public init(source:URL)throws {
        guard let context=JSContext() else{throw PracticeRecipeFailure.unavailable};self.context=context
        guard let api=context.evaluateScript(try String(contentsOf:source,encoding:.utf8)),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.api=api
    }
    public convenience init(bundle:Bundle = .main)throws {guard let url=bundle.url(forResource:"memory-policy",withExtension:"js") else{throw PracticeRecipeFailure.unavailable};try self.init(source:url)}
    public func inspect(_ operation:String,_ input:JSONValue = .object([:]))throws->JSONValue {
        context.exception=nil;let result=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])
        guard context.exception == nil,let text=result?.toString() else{throw PracticeRecipeFailure.invalidRecipe}
        return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
    }
    public func value(_ operation:String,_ input:JSONValue = .object([:]))throws->JSONValue {try inspect(operation,input)["value"]}
    public func generate(_ operation:String,_ input:JSONValue,respond:@MainActor (String)async throws->String)async throws->JSONValue {
        var responses:[JSONValue]=[]
        for _ in 0..<3 {
            try Task.checkCancellation();let plan=try inspect(operation,input.setting("responses",.array(responses)))
            if plan["requests"].array.count<=responses.count{return plan["value"]}
            guard responses.count<2 else{throw PracticeRecipeFailure.invalidRecipe}
            do{responses.append(.string(try await respond(plan["requests"].array[responses.count].string)))}catch is CancellationError{throw CancellationError()}catch{responses.append(.object(["nativeFailure":.bool(true)]))}
        };throw PracticeRecipeFailure.invalidRecipe
    }
}
