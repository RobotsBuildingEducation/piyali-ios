import Foundation
import JavaScriptCore

public enum PracticeRecipeModule:String,Codable,Sendable { case grammar,vocabulary }
public enum PracticeRecipeFailure:LocalizedError {
    case unavailable,invalidRecipe
    public var errorDescription:String? { switch self { case .unavailable:return "The original practice instructions could not be loaded.";case .invalidRecipe:return "This practice format is unavailable. Choose another exercise." } }
}

/// Bundled, pure source prompt policies. UI, exercise state and audio stay native.
/// Only JSON lesson/progress data is passed; no host APIs or account credentials.
@MainActor public final class PracticeRecipes {
    private let context:JSContext
    private let api:JSValue
    public init(source:URL) throws {
        guard let context=JSContext() else { throw PracticeRecipeFailure.unavailable }
        self.context=context
        let code=try String(contentsOf:source,encoding:.utf8)
        context.evaluateScript(code,withSourceURL:source)
        guard context.exception == nil,let api=context.objectForKeyedSubscript("PiyaliPracticeRecipes"),!api.isUndefined else { throw PracticeRecipeFailure.unavailable }
        self.api=api
    }
    public convenience init(bundle:Bundle = .main) throws {
        guard let source=bundle.url(forResource:"practice-recipes",withExtension:"js") else { throw PracticeRecipeFailure.unavailable }
        try self.init(source:source)
    }
    public func build(module:PracticeRecipeModule,kind:String,parameters:JSONValue) throws -> String {
        try call("build",arguments:[module.rawValue,kind,try encoded(parameters)])
    }
    public func inspect(_ operation:String,parameters:JSONValue) throws -> JSONValue {
        let result=try call("inspect",arguments:[operation,try encoded(parameters)])
        return try JSONDecoder().decode(JSONValue.self,from:Data(result.utf8))
    }
    public func select(module:PracticeRecipeModule,context:JSONValue,randomSeed:UInt32?=nil) throws -> JSONValue {
        var parameters:JSONValue = .object(["context":context,"user":context["user"]])
        if let randomSeed { parameters=parameters.setting("randomSeed",.number(Double(randomSeed))) }
        return try JSONDecoder().decode(JSONValue.self,from:Data(call("select",arguments:[module.rawValue,try encoded(parameters)]).utf8))
    }
    public func realtime(_ operation:String,parameters:JSONValue) throws ->String {
        try call("realtime",arguments:[operation,try encoded(parameters)])
    }
    public func reading(_ operation:String,parameters:JSONValue) throws ->String {
        try call("reading",arguments:[operation,try encoded(parameters)])
    }
    public func resetOptions() throws { _=try call("resetOptions",arguments:[]) }
    private func encoded(_ parameters:JSONValue) throws -> String {
        let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys,.withoutEscapingSlashes]
        let bytes=try encoder.encode(parameters)
        guard let json=String(data:bytes,encoding:.utf8) else { throw PracticeRecipeFailure.invalidRecipe }
        return json
    }
    private func call(_ method:String,arguments:[Any]) throws -> String {
        context.exception=nil
        let result=api.invokeMethod(method,withArguments:arguments)
        guard context.exception == nil,result?.isString == true,let prompt=result?.toString(),!prompt.isEmpty else { context.exception=nil;throw PracticeRecipeFailure.invalidRecipe }
        return prompt
    }
}
