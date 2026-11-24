import Foundation
import JavaScriptCore

/// Original message text, preferred voice and replay-language fallback rules.
final class TutorReplayPolicy {
    private let context:JSContext,api:JSValue
    init(bundle:Bundle = .main)throws{
        guard let url=bundle.url(forResource:"tutor-replay-policy",withExtension:"js"),let c=JSContext(),let api=c.evaluateScript(try String(contentsOf:url,encoding:.utf8)),c.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};context=c;self.api=api
    }
    func plan(_ input:JSONValue)throws->JSONValue{
        context.exception=nil;guard let result=api.invokeMethod("run",withArguments:[input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe};return try JSONDecoder().decode(JSONValue.self,from:Data(result.utf8))
    }
}
