import Foundation

/// Canonical Tutor documents retain their own XP, agenda cursor and private reconnect draft.
public enum TutorSourceProgress {
    public static func patch(_ change:PracticeChange,record:JSONValue)->JSONValue {
        guard let data=change.tutorData,let id=change.contentID,!data["review"].boolean else{return .object([:])}
        guard record["status"].string != "completed" || change.source == .speak else{return .object([:])}
        var patch:JSONValue = .object(["lessonId":.string(id),"targetLang":.string(change.target),"cefrLevel":.string(change.level),"updatedAt":.string(WebProgressContract.iso(change.date))])
        if change.source == .speak {
            return patch.setting("status",.string("completed")).setting("earnedXp",.number(Double(change.amount))).setting("xpEarned",.number(Double(change.amount))).setting("completedAt",record["completedAt"] == .null ? .string(WebProgressContract.iso(change.date)):record["completedAt"]).setting("tutorAgendaProgress",.null).setting("conversationDraft",.null)
        }
        patch=patch.setting("status",.string("in_progress"))
        if record["startedAt"] == .null {patch=patch.setting("startedAt",.string(WebProgressContract.iso(change.date)))}
        if change.source == .tutorTurn {
            let required=max(0,Int(data["required"].number)),earned=max(0,Int(record["earnedXp"].number))+max(0,change.amount)
            patch=patch.setting("earnedXp",.number(Double(required>0 ? min(required,earned):earned)))
        }else if record["earnedXp"] == .null {patch=patch.setting("earnedXp",.number(0))}
        if data["agenda"] != .null {
            var items=data["replaceAgenda"].boolean ? JSONValue.object([:]):record["tutorAgendaProgress"]["items"]
            if items == .null {items = .object([:])}
            for (key,value) in data["agenda"].object where value.boolean{items=items.setting(key,.bool(true))}
            var agenda:JSONValue = .object(["schemaVersion":.number(2),"items":items,"updatedAt":.string(WebProgressContract.iso(change.date))])
            if data["quiz"] != .null {agenda=agenda.setting("quiz",data["quiz"])}
            else if record["tutorAgendaProgress"]["quiz"] != .null {agenda=agenda.setting("quiz",record["tutorAgendaProgress"]["quiz"])}
            patch=patch.setting("tutorAgendaProgress",agenda)
        }
        if data["draft"] != .null {patch=patch.setting("conversationDraft",data["draft"])}
        return patch
    }
    public static func applying(_ change:PracticeChange,to original:TutorLessonProgress)->TutorLessonProgress {
        guard change.tutorData != nil else{return TutorCourse.applying(change,to:original)}
        if original.sourceState?["status"].string == "completed",change.source != .speak{return original}
        let base=(original.sourceState ?? .object([:])).setting("earnedXp",.number(Double(original.earnedXP))).setting("tutorAgendaProgress",(original.sourceState?["tutorAgendaProgress"] ?? .object([:])).setting("items",.object(Dictionary(uniqueKeysWithValues:original.items.map{($0,JSONValue.bool(true))}))))
        var record=base;for (key,value) in patch(change,record:base).object{record=record.setting(key,value)}
        return importing(record)
    }
    public static func importing(_ record:JSONValue)->TutorLessonProgress {
        var result=TutorLessonProgress();result.earnedXP=max(0,Int(record["earnedXp"].number));result.items=Set(record["tutorAgendaProgress"]["items"].object.filter{$0.value.boolean}.keys);result.sourceState=record;return result
    }
}
public extension LearnerState {
    mutating func applySourceTutor(_ change:PracticeChange){
        guard change.tutorData != nil,let id=change.contentID else{return}
        let key=change.target+":tutor:"+id
        if tutorLessons == nil{tutorLessons=[:]}
        if change.source == .tutorState,change.tutorData?["kind"].string == "start"{questProgress=plateProgress.setting("currentTutorLesson",.string(id))}
        if change.source == .speak{questProgress=plateProgress.setting("currentTutorLesson",.null)}
        let previous=tutorLessons?[key] ?? TutorLessonProgress();tutorLessons?[key]=TutorSourceProgress.applying(change,to:previous)
    }
    @discardableResult mutating func storeTutorState(lesson:Lesson,data:JSONValue,now:Date=Date())->UUID {
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:lesson.cefrLevel ?? tutorLevel,amount:0,source:.tutorState,contentID:lesson.id);change.tutorData=data;enqueue(change);return change.id
    }
    @discardableResult mutating func sourceTutorTurn(lesson:Lesson,required:Int,agenda:JSONValue,xp:Int,quiz:JSONValue?=nil,now:Date=Date())->UUID {
        let earned=max(3,min(7,xp));addXP(earned,now:now,calendar:.current)
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:lesson.cefrLevel ?? tutorLevel,amount:earned,source:.tutorTurn,contentID:lesson.id)
        var data:JSONValue = .object(["required":.number(Double(required)),"agenda":agenda]);if let quiz{data=data.setting("quiz",quiz).setting("replaceAgenda",.bool(true))};change.tutorData=data;enqueue(change);return change.id
    }
    /// Completed lessons keep a session agenda, while correct review turns still earn ordinary practice XP.
    mutating func sourceTutorReview(lesson:Lesson,xp:Int,now:Date=Date()) {
        let earned=max(3,min(7,xp));addXP(earned,now:now,calendar:.current)
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:lesson.cefrLevel ?? tutorLevel,amount:earned,source:.tutorTurn,contentID:lesson.id)
        change.tutorData = .object(["review":.bool(true)]);enqueue(change)
    }
    @discardableResult mutating func completeSourceTutor(lesson:Lesson,required:Int,ready:Bool,gameCompleted:Bool=false,now:Date=Date())->Bool {
        guard ready,required>0,(gameCompleted || tutorProgress(lesson.id).earnedXP>=required),completed.insert(tutorKey(lesson.id)).inserted else{return false}
        addXP(required,now:now,calendar:.current)
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:lesson.cefrLevel ?? tutorLevel,amount:required,source:.speak,contentID:lesson.id);change.tutorData = .object(["required":.number(Double(required))]);enqueue(change);return true
    }
}
