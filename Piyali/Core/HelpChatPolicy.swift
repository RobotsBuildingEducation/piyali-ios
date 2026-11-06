import Foundation
import JavaScriptCore

/// Pure original Help instructions, localization and morpheme protocols.
public final class HelpChatPolicy {
    private let context:JSContext,api:JSValue
    public init(source:String)throws {
        guard let context=JSContext(),let api=context.evaluateScript(source),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable}
        self.context=context;self.api=api
    }
    public convenience init(url:URL)throws{try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public convenience init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"help-chat-policy",withExtension:"js") else{throw PracticeRecipeFailure.unavailable};try self.init(url:url)}
    public func run(_ operation:String,_ input:JSONValue = .object([:]))throws->JSONValue {
        context.exception=nil
        guard let text=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe}
        return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
    }
}
