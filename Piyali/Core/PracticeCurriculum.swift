import Foundation

/// Reconstructs the exact authored context consumed by the web lesson engines.
/// Dynamic goal/repair lessons already supply their own focused payloads.
@MainActor public enum PracticeCurriculum {
    public static func lessonData(_ lesson:Lesson)->JSONValue {
        var data=(try? JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(lesson))) ?? .object([:])
        let tutorial=lesson.id == IntroTutorial.lessonID
        data=data.setting("isTutorial",.bool(tutorial)).setting("isGame",.bool(!tutorial && lesson.modes == ["game"]))
        if tutorial,let level=lesson.cefrLevel,level != "Pre-A1" { data=data.setting("tutorialPracticeLevel",.string(level)) }
        return data
    }
    public static func context(lesson:Lesson?,unit:LearningUnit?,target:String,recipes:PracticeRecipes) throws ->JSONValue {
        guard let lesson,CurriculumLessonProgress.isCurriculumID(lesson.id) else { return .null }
        var data:JSONValue = .null
        if let unit {
            data=(try? JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(unit))) ?? .null
            data=data.setting("lessons",.array(unit.lessons.map(lessonData))).setting("cefrLevel",.string(lesson.cefrLevel ?? "Pre-A1"))
        }
        return try recipes.inspect("curriculum",parameters:.object(["lesson":lessonData(lesson),"unit":data,"targetLang":.string(target),"fallbackLevel":.string(lesson.cefrLevel ?? "Pre-A1")]))
    }
    public static func content(_ lesson:Lesson?,mode:String,context:JSONValue)->JSONValue {
        let data=lesson?.content[mode] ?? .null
        return context == .null ? data : data.setting("curriculumContext",context)
    }
    /// The source applies this deterministic acceptance guard to grammar matching.
    /// Other formats receive curriculum instructions without an invented filter.
    public static func accepts(_ question:PracticeQuestion,context:JSONValue,recipes:PracticeRecipes) throws ->Bool {
        guard question.module == .grammar,question.kind == "match" else { return true }
        return try grounded(.object(["left":question.payload["left"],"right":question.payload["right"]]),mode:"grammar",context:context,recipes:recipes)
    }
    public static func grounded(_ payload:JSONValue,mode:String,context:JSONValue,recipes:PracticeRecipes) throws ->Bool {
        try recipes.inspect("grounded",parameters:.object(["payload":payload,"mode":.string(mode),"curriculumContext":context])).boolean
    }
}
