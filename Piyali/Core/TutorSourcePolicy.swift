import Foundation
import JavaScriptCore

/// Original Tutor helpers with explicit snapshots; no source UI or I/O executes.
@MainActor public final class TutorSourcePolicy {
    private let context:JSContext,api:JSValue
    public init(source:URL)throws {
        guard let context=JSContext() else{throw PracticeRecipeFailure.unavailable};self.context=context
        guard let api=context.evaluateScript(try String(contentsOf:source,encoding:.utf8),withSourceURL:source),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.api=api
    }
    public convenience init(bundle:Bundle = .main)throws {guard let source=bundle.url(forResource:"tutor-policy",withExtension:"js") else{throw PracticeRecipeFailure.unavailable};try self.init(source:source)}
    public func run(_ operation:String,_ input:JSONValue = .object([:]))throws->JSONValue {
        context.exception=nil
        let result=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])
        guard context.exception == nil,let text=result?.toString() else{throw PracticeRecipeFailure.invalidRecipe}
        return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
    }
}
