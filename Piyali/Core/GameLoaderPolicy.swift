import Foundation
import JavaScriptCore

/// Original playable preparation map; UIKit owns its canvas, input and lifetime.
public final class GameLoaderPolicy {
    private let context:JSContext,api:JSValue
    public init(source:String)throws{guard let context=JSContext(),let api=context.evaluateScript(source),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.context=context;self.api=api}
    public convenience init(url:URL)throws{try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public convenience init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"game-loader-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(url:url)}
    private func result(_ operation:String,_ input:JSONValue)throws->Data{context.exception=nil;guard let text=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe};return Data(text.utf8)}
    public func run(_ operation:String,_ input:JSONValue = .object([:]))throws->JSONValue{try JSONDecoder().decode(JSONValue.self,from:result(operation,input))}
    public func frame(width:Double,height:Double,now:Double)throws->[String:Any]{try JSONSerialization.jsonObject(with:result("frame",.object(["width":.number(width),"height":.number(height),"now":.number(now)]))) as? [String:Any] ?? [:]}
}
