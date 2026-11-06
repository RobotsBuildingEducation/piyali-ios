import Foundation

@MainActor final class FlashcardPolicy {
    private static var themes:[String:JSONValue]=[:]
    let engine:CompanionQuestPolicy
    init(engine:CompanionQuestPolicy?=nil)throws {self.engine=try engine ?? CompanionQuestPolicy()}
    func run(_ operation:String,_ parameters:JSONValue = .object([:]),language:String="en",now:Date=Date())throws->JSONValue {
        let key=language+":"+JSONValue.object(Dictionary(uniqueKeysWithValues:["level","light","correct","assessment","status"].map{($0,parameters[$0])})).canonicalJSON+parameters["card"]["practiceStatus"].string+":"+parameters["card"]["reviewState"].string
        if operation == "flashTheme",let value=Self.themes[key]{return value}
        let needsCopy=["flashTheme","flashJudge","flashReveal","flashExplain"].contains(operation)
        if !needsCopy {return try engine.run(operation,parameters.setting("language",.string(language)).setting("now",.number(now.timeIntervalSince1970*1000)))}
        let languages=Set(["en",language]),copy=EntryCopy.interface.filter{languages.contains($0.key)}.mapValues{value in JSONValue.object(value.object.filter{$0.key.hasPrefix("flashcard_") || $0.key.hasPrefix("language_")})}
        let input=parameters.setting("language",.string(language)).setting("now",.number(now.timeIntervalSince1970*1000))
        let value=try engine.run(operation,input.setting("copy",.object(copy)))
        if operation == "flashTheme" {if Self.themes.count>128{Self.themes=[:]};Self.themes[key]=value}
        return value
    }
    func dailyCount(_ state:LearnerState,now:Date=Date())->Int {
        let reviews=(state.cardReviews ?? [:]).filter{$0.key.hasPrefix(state.target+":")}.mapValues{$0.sourceFields}
        let map=(try? run("flashActivity",.object(["saved":state.plateProgress["flashcardDailyActivity"][state.target],"reviews":.object(reviews)]),now:now)) ?? .null
        return Int(map[CalendarDay.key(now)].number)
    }
    func dailyTarget(_ app:AppModel,now:Date=Date())->Int {
        let courses=app.plateCourses.map{JSONValue.object(["kind":.string($0.kind),"target":.number(Double($0.target))])}
        return Int((try? run("flashTarget",.object(["userKey":.string(app.identity.npub),"langKey":.string(app.learner.target),"dayKey":.string(CalendarDay.key(now)),"plateSnapshot":.object(["courses":.array(courses)])]),now:now).number) ?? 5)
    }
    func grade(_ raw:String)throws->FlashcardGrade {try JSONDecoder().decode(FlashcardGrade.self,from:Data(run("flashGrade",.object(["raw":.string(raw)])).json.utf8))}
    func ratings(_ progress:FlashcardReview,now:Date=Date())->[JSONValue] {(try? run("flashRatings",.object(["progress":progress.sourceFields]),now:now).array) ?? []}
    func snapshot(_ progress:FlashcardReview,now:Date=Date())->JSONValue {(try? run("flashSnapshot",.object(["progress":progress.sourceFields]),now:now)) ?? .object([:])}
}
