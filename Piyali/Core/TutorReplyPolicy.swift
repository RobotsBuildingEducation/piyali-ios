import Foundation
import JavaScriptCore

/// Executes the original pure phrase helper declarations; no DOM or provider I/O.
public final class TutorReplyPolicy {
    private let context:JSContext,api:JSValue
    public init(source:String)throws{guard let c=JSContext(),let a=c.evaluateScript(source),c.exception == nil,!a.isUndefined else{throw PracticeRecipeFailure.unavailable};context=c;api=a}
    public convenience init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"tutor-reply-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public func plan(primary:String,secondary:String,pairs:JSONValue)throws->JSONValue{context.exception=nil;let input:JSONValue = .object(["primaryText":.string(primary),"secondaryText":.string(secondary),"pairs":pairs]);guard let text=api.invokeMethod("run",withArguments:[input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe};return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))}
}
