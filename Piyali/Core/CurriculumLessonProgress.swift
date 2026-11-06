import Foundation

/// Progress belongs to one language/lesson. Shared XP never fills this counter.
public struct CurriculumLessonProgress:Codable,Equatable,Sendable {
    public var status:LessonAccessStatus
    public var earnedXP:Int
    public var updatedAt:Date?
    public init(status:LessonAccessStatus = .inProgress,earnedXP:Int=0,updatedAt:Date?=nil) { self.status=status;self.earnedXP=max(0,earnedXP);self.updatedAt=updatedAt }
    public func fraction(goal:Int)->Double { goal > 0 ? min(1,Double(earnedXP)/Double(goal)) : 0 }
    public func ready(goal:Int)->Bool { goal > 0 && earnedXP >= goal }
    public static func fromWeb(_ fields:[String:Any])->Self {
        .init(status:LessonAccessStatus(rawValue:fields["status"] as? String ?? "") ?? .inProgress,earnedXP:WebProgressContract.integer(fields["earnedXp"]),updatedAt:WebProgressContract.date(fields["updatedAt"]))
    }
    public static func isCurriculumID(_ id:String)->Bool { !id.isEmpty && !id.hasPrefix("goal-") && !id.hasPrefix("repair-") }
    public static func localWorkID(_ change:PracticeChange)->String? {if let id=change.skillTreeLessonID,id.hasPrefix("repair-"){return id};return lessonID(change)}
    public static func lessonID(_ change:PracticeChange)->String? {
        let id:[String?] = [change.skillTreeLessonID,[.lessonStart,.lesson].contains(change.source) ? change.contentID : nil]
        return id.compactMap { $0 }.first(where:isCurriculumID)
    }
    public static func applying(_ change:PracticeChange,to saved:Self?)->Self? {
        guard localWorkID(change) != nil else { return saved }
        if change.source == .lessonStart {
            guard saved?.status != .completed else { return saved }
            return .init(status:.inProgress,earnedXP:saved?.earnedXP ?? 0,updatedAt:change.date)
        }
        if change.source == .lesson {
            guard saved?.status != .completed else { return saved }
            return .init(status:.completed,earnedXP:max(0,change.amount),updatedAt:change.date)
        }
        guard let saved,saved.status == .inProgress,change.skillTreeLessonID != nil,change.amount > 0 else { return saved }
        return .init(status:.inProgress,earnedXP:saved.earnedXP+change.amount,updatedAt:change.date)
    }
}
public extension PracticeChange {
    mutating func attachCurriculumLesson(id:String?,level:String) {
        guard let id,CurriculumLessonProgress.isCurriculumID(id) || id.hasPrefix("repair-") || id.hasPrefix("goal-") else { return }
        skillTreeLessonID=id;skillTreeLessonLevel=level
    }
}
public extension LearnerState {
    mutating func importLessonWork(_ fields:[String:Any],id:String,target:String) {
        guard CurriculumLessonProgress.isCurriculumID(id),["in_progress","completed"].contains(fields["status"] as? String ?? ""),fields["tutorAgendaProgress"] == nil else { return }
        let key="\(target):\(id)"
        if lessonWork == nil { lessonWork=[:] };lessonWork?[key]=CurriculumLessonProgress.fromWeb(fields)
        if lessonWork?[key]?.status == .completed { completed.insert(key) }
    }
    mutating func applyLessonWork(_ change:PracticeChange) {
        guard let id=CurriculumLessonProgress.localWorkID(change) else { return }
        let key="\(change.target):\(id)"
        guard let result=CurriculumLessonProgress.applying(change,to:lessonWork?[key]) else { return }
        if lessonWork == nil { lessonWork=[:] };lessonWork?[key]=result
    }
    @discardableResult mutating func beginLessonWork(_ lesson:Lesson,now:Date = Date())->Bool {
        if lesson.isRepair == true {
            let key=completionKey(lesson.id);guard lessonWork?[key] == nil,!completed.contains(key) else{return false}
            if lessonWork == nil {lessonWork=[:]};lessonWork?[key] = .init();return true
        }
        guard CurriculumLessonProgress.isCurriculumID(lesson.id),!completed.contains(completionKey(lesson.id)),lessonWork?[completionKey(lesson.id)]?.status != .completed else { return false }
        guard lessonWork?[completionKey(lesson.id)] == nil else { return false }
        enqueue(.init(date:now,dayKey:CalendarDay.key(now),target:target,level:lesson.cefrLevel ?? level,amount:0,source:.lessonStart,contentID:lesson.id))
        return true
    }
}
