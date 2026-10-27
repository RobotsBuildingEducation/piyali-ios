import Foundation

public enum LessonAccessStatus:String,Codable,Sendable {
    case locked,available,completed
    case inProgress="in_progress"
    public var canOpen:Bool { self != .locked }
}
public enum LessonAccess {
    /// Sequential nodes, tutorial gate and placement override from SkillTree.jsx.
    /// Completion and resumable work win over later changes to access gates.
    public static func status(lesson:String,units:[[String]],progress:[String:LessonAccessStatus],tutorial:Bool,placed:Bool)->LessonAccessStatus {
        for (u,unit) in units.enumerated() {
            guard let l=unit.firstIndex(of:lesson) else { continue }
            if let saved=progress[lesson],saved == .completed || saved == .inProgress { return saved }
            let previousCompleted:Bool
            if l > 0 { previousCompleted=progress[unit[l-1]] == .completed }
            else if u > 0,let previous=units[u-1].last { previousCompleted=progress[previous] == .completed }
            else { previousCompleted=tutorial }
            return placed || previousCompleted ? .available : .locked
        }
        return .locked
    }
    public static func throughPlacement(_ placement:String?,level:String)->Bool {
        guard let placement,let placed=LearningLanguages.levels.firstIndex(of:placement),let requested=LearningLanguages.levels.firstIndex(of:level) else { return false }
        // A completely new learner keeps the introductory sequential path.
        return placed > 0 && requested <= placed
    }
}
public extension LearnerState {
    func lessonAccess(_ lesson:Lesson,units:[LearningUnit],tutor:Bool=false)->LessonAccessStatus {
        var progress:[String:LessonAccessStatus]=[:]
        for node in units.flatMap(\.lessons) {
            let key=tutor ? tutorKey(node.id) : completionKey(node.id)
            if !tutor,let saved=lessonWork?[key] { progress[node.id]=saved.status }
            if completed.contains(key) { progress[node.id] = .completed }
            else if tutor ? !tutorProgress(node.id).items.isEmpty || tutorProgress(node.id).earnedXP > 0 : practicedModes.contains(where:{ $0.hasPrefix(key+":") }) { progress[node.id] = .inProgress }
        }
        let tutorial=tutor || !needsIntro || completed.contains(completionKey(IntroTutorial.lessonID))
        return LessonAccess.status(lesson:lesson.id,units:units.map { $0.lessons.map(\.id) },progress:progress,tutorial:tutorial,placed:LessonAccess.throughPlacement(placements?[target]?.level,level:lesson.cefrLevel ?? (tutor ? tutorLevel : level)))
    }
}
