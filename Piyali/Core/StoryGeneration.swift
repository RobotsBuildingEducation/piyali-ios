import Foundation

@MainActor public enum StoryGeneration {
    public static func parameters(state:LearnerState,lesson:Lesson?,unit:LearningUnit?,mode:StoryMode,account:String,level:String,user:JSONValue,recipes:PracticeRecipes)throws->JSONValue {
        let context=try PracticeCurriculum.context(lesson:lesson,unit:unit,target:state.target,recipes:recipes)
        var content=PracticeCurriculum.content(lesson,mode:"stories",context:context)
        if lesson?.id == IntroTutorial.lessonID {
            content=content.setting("topic",.string("tutorial"))
            if let level=lesson?.cefrLevel,level != "Pre-A1" { content=content.setting("tutorialPracticeLevel",.string(level)) }
        }
        if content == .null { content = .object(["topic":.string(state.goal)]) }
        return .object(["lessonContent":content,"lessonId":.string(lesson?.id ?? "free"),"npub":.string(account),"mode":.string(mode == .speaking ? "practice" : mode.rawValue),"targetLang":.string(state.target),"targetName":.string(LearningLanguages.names[state.target] ?? state.target),"supportLang":.string(state.support),"supportName":.string(LearningLanguages.names[state.support] ?? state.support),"cefrLevel":.string(level),"curriculumCefrLevel":.string(lesson?.cefrLevel ?? state.level),"user":user,"history":.array(history(state.storyHistory?[state.target] ?? []))])
    }
    public static func history(_ entries:[JSONValue])->[JSONValue] {
        entries.map { entry in
            entry.setting("targetText",.string(entry["targetText"].string.isEmpty ? entry["opening"].string : entry["targetText"].string))
                .setting("lessonId",entry["lessonId"] == .null ? entry["lessonID"] : entry["lessonId"])
                .setting("mode",entry["mode"].string == "speaking" ? .string("practice") : entry["mode"])
        }
    }
    public static func payload(_ raw:String,mode:StoryMode,target:String,tutorial:Bool,title:String,recipes:PracticeRecipes)throws->JSONValue {
        guard raw.utf8.count <= 100_000 else { throw StoryFailure.invalid }
        if mode != .speaking { return try recipes.story("streamPayload",parameters:.object(["raw":.string(raw)])) }
        let parsed=try recipes.story("parseSpeaking",parameters:.object(["raw":.string(raw),"targetLang":.string(target),"isTutorial":.bool(tutorial)]))
        let lines=parsed["sentences"].array.map { .object(["speaker":$0["character"],"target":$0["tgt"],"support":$0["sup"],"gender":$0["gender"]]) as JSONValue }
        return .object(["title":.string(title.isEmpty ? "Practice" : title),"sentences":.array(lines)])
    }
    public static func candidate(_ run:StoryRun)->JSONValue { .object(["title":.string(run.title),"target":.string(run.text)]) }
    public static func historyEntry(_ run:StoryRun,plan:JSONValue)->JSONValue {
        .object(["lessonId":plan["lessonId"],"mode":plan["mode"],"title":.string(run.title),"targetText":.string(String(run.text.prefix(6000))),"subject":plan["subject"]["id"] == .null ? .string("") : plan["subject"]["id"],"purpose":plan["purpose"]["id"] == .null ? .string("") : plan["purpose"]["id"]])
    }
}
