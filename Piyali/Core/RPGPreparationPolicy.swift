import Foundation
import JavaScriptCore

/// Original authored-episode prompts, validation and application. UI stays native.
public final class RPGPreparationPolicy {
    private let context:JSContext,api:JSValue
    public init(source:String)throws {
        guard let context=JSContext(),let api=context.evaluateScript(source),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.context=context;self.api=api
    }
    public convenience init(url:URL)throws{try self.init(source:String(contentsOf:url,encoding:.utf8))}
    public convenience init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"rpg-preparation-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(url:url)}
    public func run(_ operation:String,_ input:JSONValue)throws->JSONValue{
        context.exception=nil
        guard let text=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe}
        return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
    }
    public struct Request:Sendable {public let prompt:String,cacheKey:String,parameters:JSONValue}
    public struct Prepared:Sendable {public let scenario:RPGScenario,cacheValue:JSONValue}
    public func request(scenario:RPGScenario,lesson:JSONValue,target:String,support:String)throws->Request {
        let input:JSONValue = .object(["scenario":try Self.value(scenario),"lesson":lesson,"target":.string(target),"support":.string(support)]),result=try run("request",input)
        return Request(prompt:result["prompt"].string,cacheKey:result["cacheKey"].string,parameters:input)
    }
    public func prepare(response:String,request:Request)throws->Prepared?{try resolve("prepare",request.parameters.setting("response",.string(response)))}
    public func cached(_ value:JSONValue,request:Request)throws->Prepared?{try resolve("cached",request.parameters.setting("prepared",value))}
    private func resolve(_ operation:String,_ input:JSONValue)throws->Prepared? {
        let value=try run(operation,input);guard value != .null else{return nil}
        return Prepared(scenario:try JSONDecoder().decode(RPGScenario.self,from:JSONEncoder().encode(value["scenario"])),cacheValue:value["prepared"])
    }
    public func speechPrompt(run:RPGRun,answer:String)throws->String {
        guard let node=run.node,let npc=run.npc else{throw PracticeRecipeFailure.invalidRecipe}
        let turn:JSONValue = .object(["npcName":.string(npc.name),"personality":.string(npc.personality),"heard":.string(answer),"npcLine":.string(node.npcLine),"speechGoal":.string(node.speechGoal ?? node.supportLine),"speechExample":.string(node.speechExample ?? node.speechTarget ?? ""),"storyIntro":.string(run.scenario.storyIntro?["target"].string.isEmpty == false ? run.scenario.storyIntro!["target"].string:run.scenario.quest.storySeed),"historyContext":.string(run.dialogue.suffix(10).joined(separator:"\n"))])
        return try self.run("speechPrompt",.object(["target":.string(run.target),"support":.string(run.support),"turn":turn])).string
    }
    public func speechResult(_ response:String)throws->RPGSpeechTurn? {
        let value=try run("speechResult",.object(["response":.string(response)]));guard value != .null else{return nil}
        return try JSONDecoder().decode(RPGSpeechTurn.self,from:JSONEncoder().encode(value))
    }
    public static func value<T:Encodable>(_ value:T)throws->JSONValue{try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(value))}
}
