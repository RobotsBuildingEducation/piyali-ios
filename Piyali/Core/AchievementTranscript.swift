import Foundation
import JavaScriptCore

/// The main product's complete, localized cross-platform transcript catalog.
public struct AchievementTranscript:Sendable {
    public let data:JSONValue
    public init(data:JSONValue){self.data=data}
    public init(bundle:Bundle = .main)throws{data=try ContentLibrary.load(JSONValue.self,name:"achievement-transcript",bundle:bundle)}
    public func locale(_ language:String)->String{let parts=language.lowercased().replacingOccurrences(of:"_",with:"-").split(separator:"-").map(String.init),key=parts.first ?? "en";if ["py","swift","android","compsci"].contains(key){return parts.contains("es") ? "es":"en"};return data["items"][key] == .null ? "en":key}
    public func text(_ key:String,language:String,values:[String:String]=[:])->String{var text=data["copy"][key][locale(language)].string;for(k,v)in values{text=text.replacingOccurrences(of:"{\(k)}",with:v)};return text}
    public func number(_ value:Int,language:String)->String{let numbers=data["numbers"][locale(language)].array;return numbers.indices.contains(value) ? numbers[value].string:String(value)}
    public func items(language:String,host:String)->[JSONValue]{let all=data["items"][locale(language)].array,byID=Dictionary(uniqueKeysWithValues:all.map{($0["id"].string,$0)});return data["order"].array.compactMap{byID[$0.string]}.filter{$0["source"].string == host || $0["source"].string == "shared"}}
    public func sections(language:String,host:String,unlocked:JSONValue)->[JSONValue]{let items=items(language:language,host:host);return [true,false].map{complete in let rows=items.filter{NostrAchievementCollection.truthy(unlocked[$0["id"].string]) == complete};return .object(["status":.string(complete ? "unlocked":"locked"),"count":.number(Double(rows.count)),"items":.array(rows)])}}
}

/// Original twenty-one character reactions, evaluated in the native animation loop.
public final class AchievementOrbPolicy {
    private let context:JSContext,api:JSValue
    public init(source:String)throws{guard let context=JSContext(),let api=context.evaluateScript(source),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.context=context;self.api=api}
    public convenience init(bundle:Bundle = .main)throws{guard let url=bundle.url(forResource:"achievement-orb-policy",withExtension:"js") else{throw PracticeRecipeFailure.unavailable};try self.init(source:String(contentsOf:url))}
    public func voiceLevel(_ time:Double)->Double{context.exception=nil;let value=api.invokeMethod("voiceLevel",withArguments:[time])?.toDouble() ?? 0;return context.exception == nil && value.isFinite ? value:0}
    public func pose(kind:String,elapsed:Double,amount:Double)throws->JSONValue{context.exception=nil;let input=JSONValue.object(["kind":.string(kind),"elapsed":.number(elapsed),"amount":.number(amount)]);guard let text=api.invokeMethod("run",withArguments:[input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe};return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))}
}
