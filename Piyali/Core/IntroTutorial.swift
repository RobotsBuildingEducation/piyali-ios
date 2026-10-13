import Foundation

public struct IntroLibrary:Codable,Sendable {
    public let target:String
    public let units:[String:LearningUnit]
    public let games:[String:RPGReview]
    public let worlds:[String:RPGWorld]
}
public struct IntroSession:Codable,Equatable,Sendable {
    public let level:String
    public var visited:[String]=[]
    public var updatedAt=Date()
    public init(level:String) { self.level=level }
    public var next:String? { visited.count < IntroTutorial.modes.count ? IntroTutorial.modes[visited.count] : nil }
    public var ready:Bool { visited == IntroTutorial.modes }
}
public enum IntroTutorial {
    public static let lessonID="lesson-tutorial-1"
    public static let modes=["vocabulary","grammar","reading","stories","realtime","game"]
    public static func needed(level:String,completed:Bool,hasFirstQuest:Bool) -> Bool { level != "Pre-A1" && LearningLanguages.levels.contains(level) && hasFirstQuest && !completed }
    public static func lessonCourseIndex(_ index:[String:[String]]) -> [String:[String]] {
        var result=index
        if let first=result["Pre-A1"],!first.contains(lessonID) { result["Pre-A1"]=[lessonID]+first }
        return result
    }
}
public extension LearnerState {
    var introSession:IntroSession { introSessions?[target].flatMap { $0.level == level ? $0 : nil } ?? IntroSession(level:level) }
    var needsIntro:Bool { level == "Pre-A1" || IntroTutorial.needed(level:level,completed:completed.contains(completionKey(IntroTutorial.lessonID)),hasFirstQuest:(journeyQuestCounts?[target] ?? 0)>0) }
    @discardableResult mutating func visitIntro(_ mode:String,expectedLevel:String,now:Date = Date()) -> Bool {
        guard level == expectedLevel else { return false };var session=introSession;guard session.next == mode else { return false }
        session.visited.append(mode);session.updatedAt=now
        if introSessions == nil { introSessions=[:] };introSessions?[target]=session;return true
    }
    @discardableResult mutating func completeIntro(_ lesson:Lesson,now:Date = Date()) -> Bool {
        let key=completionKey(IntroTutorial.lessonID)
        guard lesson.id == IntroTutorial.lessonID,introSession.ready,!completed.contains(key) else { return false }
        completed.insert(key);addXP(lesson.xpReward,now:now,calendar:.current)
        enqueue(PracticeChange(date:now,dayKey:dailyKey,target:target,level:level,amount:lesson.xpReward,source:.lesson,contentID:IntroTutorial.lessonID));return true
    }
}
