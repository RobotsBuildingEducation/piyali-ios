import Foundation
import JavaScriptCore

public struct GuidedPracticeSession:Codable,Equatable,Sendable {
    public let account:String
    public let target:String
    public let day:String
    public private(set) var current:String
    public init?(account:String,target:String,day:String,courses:[PlateCourse]) {
        guard let first=courses.first(where:{ !$0.done }) else { return nil }
        self.account=account;self.target=target;self.day=day;current=first.kind
    }
    public func matches(account:String,target:String,day:String)->Bool { self.account == account && self.target == target && self.day == day }
    public func taskCompleted(_ courses:[PlateCourse])->Bool { courses.first { $0.kind == current }?.done == true }
    public mutating func advance(_ courses:[PlateCourse])->Bool {
        guard let next=courses.first(where:{ !$0.done }) else { return false }
        current=next.kind;return true
    }
}

/// The web conductor's callbacks run with explicit native snapshots and timers.
/// This policy never mounts React or performs storage/network work.
@MainActor public final class PlateSessionPolicy {
    private let context:JSContext,api:JSValue
    public init(source:URL)throws {
        guard let context=JSContext() else{throw PracticeRecipeFailure.unavailable};self.context=context
        guard let api=context.evaluateScript(try String(contentsOf:source,encoding:.utf8)),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.api=api
    }
    public convenience init(bundle:Bundle = .main)throws {guard let url=bundle.url(forResource:"plate-session-policy",withExtension:"js") else{throw PracticeRecipeFailure.unavailable};try self.init(source:url)}
    public func run(_ operation:String,_ input:JSONValue)throws->JSONValue {
        context.exception=nil;let result=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])
        guard context.exception == nil,let text=result?.toString() else{throw PracticeRecipeFailure.invalidRecipe}
        return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
    }
}
