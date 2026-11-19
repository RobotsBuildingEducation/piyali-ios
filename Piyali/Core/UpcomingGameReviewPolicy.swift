import Foundation
import JavaScriptCore

/// The source completion predicate and exact same-unit, immediate-next lookup.
@MainActor public final class UpcomingGameReviewPolicy {
    public struct Candidate:Codable,Equatable,Sendable {public let lessonID:String,level:String}
    private let context:JSContext,api:JSValue
    public init(url:URL)throws {guard let context=JSContext(),let api=context.evaluateScript(try String(contentsOf:url,encoding:.utf8)),context.exception == nil,!api.isUndefined else{throw PracticeRecipeFailure.unavailable};self.context=context;self.api=api}
    public convenience init(bundle:Bundle = .main)throws {guard let url=bundle.url(forResource:"upcoming-game-review-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};try self.init(url:url)}
    private func source(_ lesson:Lesson)->JSONValue {
        .object(["id":.string(lesson.id),"isGame":.bool(lesson.isGame ?? (lesson.modes == ["game"])),"isTutorial":.bool(lesson.isTutorial ?? (lesson.id == IntroTutorial.lessonID)),"content":.object(["game":.object(["cefrLevel":lesson.content["game"]["cefrLevel"]])])])
    }
    private func run(_ operation:String,lesson:Lesson,units:[LearningUnit]=[])throws->JSONValue {
        // The extracted selector reads only these identities/type flags; the
        // full original review context remains in the existing RPG library.
        let sourceUnits=units.map{unit in JSONValue.object(["lessons":.array(unit.lessons.map(source))])}
        let input:JSONValue = .object(["lesson":source(lesson),"units":.array(sourceUnits)])
        context.exception=nil;guard let text=api.invokeMethod("run",withArguments:[operation,input.canonicalJSON])?.toString(),context.exception == nil else{throw PracticeRecipeFailure.invalidRecipe};return try JSONDecoder().decode(JSONValue.self,from:Data(text.utf8))
    }
    public func level(after lesson:Lesson)throws->String? {let value=try run("level",lesson:lesson);return value == .null ? nil:value.string}
    public func candidate(after lesson:Lesson,units:[LearningUnit])throws->Candidate? {let value=try run("candidate",lesson:lesson,units:units);return value == .null ? nil:try JSONDecoder().decode(Candidate.self,from:Data(value.json.utf8))}
}
