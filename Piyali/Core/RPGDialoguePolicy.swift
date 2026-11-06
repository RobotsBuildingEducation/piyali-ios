import Foundation
import JavaScriptCore

/// Pure original dialogue/translation rules. All rendering and I/O stay native.
public final class RPGDialoguePolicy {
    private let context:JSContext,api:JSValue
    public init(source:String)throws{guard let c=JSContext(),let a=c.evaluateScript(source),c.exception == nil,!a.isUndefined else{throw PracticeRecipeFailure.unavailable};context=c;api=a}
    public convenience init(url:URL)throws{try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public convenience init(bundle:Bundle = .main)throws{guard let u=bundle.url(forResource:"rpg-dialogue-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(url:u)}
    public func run(_ operation:String,_ input:JSONValue = .object([:]))throws->JSONValue{context.exception=nil;guard let text=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe};return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))}
    public struct Plan:Equatable,Sendable{
        public let value:JSONValue
        public var lines:[String]{value["lines"].array.map(\.string)}
        public var choices:[String]{value["choices"].array.map(\.string)}
        public var prompt:String{value["prompt"].string}
        public var count:Int{value["targets"].array.count}
    }
    public struct Presentation:Equatable,Sendable{
        public let caption:String,prompt:String,reply:String,isReply:Bool
        public init(_ value:JSONValue){caption=value["caption"].string;prompt=value["prompt"].string;reply=value["reply"].string;isReply=value["isReply"].boolean}
    }
    public func plan(_ input:JSONValue)throws->Plan{Plan(value:try run("plan",input))}
    public func presentation(_ input:JSONValue)throws->Presentation{Presentation(try run("presentation",input))}
    public func initial(_ plan:Plan)throws->JSONValue{try run("initial",plan.value)}
    public func append(_ chunk:String,state:JSONValue,plan:Plan,final:Bool=false)throws->JSONValue{try run("append",.object(["plan":plan.value,"state":state,"chunk":.string(chunk),"final":.bool(final)]))}
    public static func parameters(_ run:RPGRun,continueLabel:String)throws->JSONValue{
        guard let node=run.node else{throw PracticeRecipeFailure.invalidRecipe}
        let rawReply=run.feedback.isEmpty ? "":run.feedback+(run.tip.isEmpty ? "":"\n\n*"+run.tip+"*")
        return .object(["target":.string(run.target),"support":.string(run.support),"names":.array(run.scenario.npcs.map{.string($0.name)}),"inventory":.array([]),"ui":.object(["continue":.string(continueLabel)]),"dialogue":.object(["node":try RPGPreparationPolicy.value(node),"npcReply":.string(rawReply),"sceneLine":.string(run.feedbackScene ?? "")])])
    }
}

public enum RPGCharacterReveal {
    /// CSS ease-in (the original opacity transition), evaluated without changing layout.
    public static func opacity(unit:Int,elapsed:Double,delayMilliseconds:Double=18,fadeMilliseconds:Double=120)->Double{
        let start=Double(unit+1)*delayMilliseconds/1000,x=max(0,min(1,(elapsed-start)/(fadeMilliseconds/1000)))
        guard x>0,x<1 else{return x};var lo=0.0,hi=1.0
        for _ in 0..<24{let t=(lo+hi)/2,u=1-t,position=3*u*u*t*0.42+3*u*t*t+t*t*t;if position<x{lo=t}else{hi=t}}
        let t=(lo+hi)/2;return 3*(1-t)*t*t+t*t*t
    }
}
