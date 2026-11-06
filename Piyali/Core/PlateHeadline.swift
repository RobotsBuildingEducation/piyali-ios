import Foundation
import JavaScriptCore

public struct PlateHeadline:Codable,Equatable,Sendable {
    public let dayKey:String
    public let appLanguage:String
    public let text:String
    public init(dayKey:String,appLanguage:String,text:String){self.dayKey=dayKey;self.appLanguage=appLanguage;self.text=text}
    public static func targetKey(_ code:String)->String {let value=code.trimmingCharacters(in:.whitespacesAndNewlines).lowercased();return value.isEmpty ? "es" : value}
    public static func supportKey(_ code:String)->String {code.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()}
    public func cached(day:String,support:String)->String? {!day.isEmpty && dayKey == day && appLanguage == Self.supportKey(support) && !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? text.trimmingCharacters(in:.whitespacesAndNewlines) : nil}
    public var fields:[String:Any] { ["dayKey":dayKey,"appLanguage":appLanguage,"text":text] }
    public static func decode(_ value:Any)->PlateHeadline? {guard let fields=value as? [String:Any],let day=fields["dayKey"] as? String,let support=fields["appLanguage"] as? String,let text=fields["text"] as? String else{return nil};return .init(dayKey:day,appLanguage:support,text:text)}
}

@MainActor public final class PlateHeadlinePolicy {
    private let context:JSContext,api:JSValue
    public init(source:URL)throws {
        guard let context=JSContext() else{throw PracticeRecipeFailure.unavailable};self.context=context
        context.evaluateScript(try String(contentsOf:source,encoding:.utf8),withSourceURL:source)
        guard context.exception == nil,let api=context.objectForKeyedSubscript("PiyaliPlateHeadline"),!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.api=api
    }
    public convenience init(bundle:Bundle = .main)throws {guard let url=bundle.url(forResource:"plate-headline-policy",withExtension:"js") else{throw PracticeRecipeFailure.unavailable};try self.init(source:url)}
    public func run(_ operation:String,_ input:JSONValue)throws->JSONValue {
        context.exception=nil;let result=api.invokeMethod("run",withArguments:[operation,input.json])
        guard context.exception == nil,let text=result?.toString() else{throw PracticeRecipeFailure.invalidRecipe}
        return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
    }
    public func clean(_ text:String)throws->String {try run("clean",.object(["text":.string(text)])).string}
}

public extension LearnerState {
    func plateHeadline(day:String)->String? {guard !target.isEmpty else{return nil};return plateHeadlines?[PlateHeadline.targetKey(target)]?.cached(day:day,support:support)}
    mutating func storePlateHeadline(_ value:PlateHeadline,target:String) {
        let target=PlateHeadline.targetKey(target)
        if plateHeadlines == nil {plateHeadlines=[:]};plateHeadlines?[target]=value
        if pendingPlateHeadlines == nil {pendingPlateHeadlines=[:]};pendingPlateHeadlines?[target]=value
    }
}
