import Foundation

/// The path's realtime goal is separate from the free conversation course.
public struct RealtimeLessonRun:Codable,Sendable {
    public var id=UUID()
    public let target:String
    public let support:String
    public let lessonID:String
    public let lessonLevel:String
    public let questionLevel:String
    public var goal:JSONValue
    public var attempts=0
    public var completed=false
    public var earnedXP=0
    public var feedback=""
    public var pronunciation=false
    public var helpRequest=""
    public var starter:JSONValue?
    public var messages:[ConversationMessage]=[]
    public var seenTurns:[UUID]=[]
    public var updatedAt=Date()
    public init(target:String,support:String,lessonID:String,lessonLevel:String,questionLevel:String,goal:JSONValue) {
        self.target=target;self.support=support;self.lessonID=lessonID;self.lessonLevel=lessonLevel;self.questionLevel=questionLevel;self.goal=goal
    }
    public static func key(target:String,lesson:String)->String { target+":"+lesson+":realtime" }
    public var key:String { Self.key(target:target,lesson:lessonID) }
    public var title:String { goal["title_"+support].string.isEmpty ? goal["lessonScenario"].string : goal["title_"+support].string }
    public var rubric:String { goal["rubric_"+support].string.isEmpty ? goal["successCriteria"].string : goal["rubric_"+support].string }
    public mutating func append(_ message:ConversationMessage) { messages.append(message);messages=Array(messages.suffix(30)) }
    /// awardXp in the web rounds the source's half-point effort penalties.
    public static func reward(attempts:Int,pronunciation:Bool)->Int { Int(max(4,min(7,6+(pronunciation ? 1 : 0)-Double(max(0,attempts-1))*0.5)).rounded()) }
}
public struct RealtimeLessonVerdict:Decodable,Sendable {
    public let met:Bool
    public let confidence:Double
    public let feedback_tl:String
    public let feedback_ui:String
    public init(met:Bool,confidence:Double,feedbackTL:String="",feedbackUI:String="") { self.met=met;self.confidence=confidence;feedback_tl=feedbackTL;feedback_ui=feedbackUI }
    private enum CodingKeys:String,CodingKey { case met,confidence,feedback_tl,feedback_ui }
    public init(from decoder:Decoder) throws {
        let values=try decoder.container(keyedBy:CodingKeys.self);met=try values.decode(Bool.self,forKey:.met)
        let raw=(try? values.decode(Double.self,forKey:.confidence)) ?? 0;confidence=raw.isFinite ? min(1,max(0,raw)) : 0
        feedback_tl=String(((try? values.decode(String.self,forKey:.feedback_tl)) ?? "").prefix(400));feedback_ui=String(((try? values.decode(String.self,forKey:.feedback_ui)) ?? "").prefix(400))
    }
    public var feedback:String { feedback_ui.isEmpty ? feedback_tl : feedback_ui }
}
public extension LearnerState {
    mutating func saveRealtimeLesson(_ run:RealtimeLessonRun) {
        guard run.target == target,run.support == support else { return }
        if realtimeLessonRuns == nil { realtimeLessonRuns=[:] };var next=run;next.updatedAt=Date();realtimeLessonRuns?[run.key]=next
        while realtimeLessonRuns!.count > 1,(realtimeLessonRuns!.count > 8 || (try? JSONEncoder().encode(realtimeLessonRuns).count) ?? 0 > 80_000) { if let key=realtimeLessonRuns!.min(by:{$0.value.updatedAt < $1.value.updatedAt})?.key { realtimeLessonRuns?.removeValue(forKey:key) } }
    }
    mutating func captureRealtimeTranscript(key:String,runID:UUID,turnID:UUID,utterance:String,reply:String) {
        guard var run=realtimeLessonRuns?[key],run.id == runID,run.target == target,run.support == support,!run.messages.contains(where:{$0.id == turnID}),!utterance.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        var message=ConversationMessage(role:"user",text:utterance);message.id=turnID;run.append(message)
        if !reply.isEmpty { run.append(.init(role:"assistant",text:reply)) };saveRealtimeLesson(run)
    }
    @discardableResult mutating func answerRealtimeLesson(key:String,runID:UUID,turnID:UUID,utterance:String,reply:String,verdict:RealtimeLessonVerdict,now:Date = Date())->Int {
        guard var run=realtimeLessonRuns?[key],run.id == runID,run.target == target,run.support == support,!run.completed,!run.seenTurns.contains(turnID),!utterance.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return 0 }
        run.seenTurns=Array((run.seenTurns+[turnID]).suffix(100));run.attempts += 1;run.feedback=verdict.feedback
        if !run.messages.contains(where:{$0.id == turnID}) { var message=ConversationMessage(role:"user",text:utterance);message.id=turnID;run.append(message);if !reply.isEmpty { run.append(.init(role:"assistant",text:reply)) } }
        let amount=verdict.met ? RealtimeLessonRun.reward(attempts:run.attempts,pronunciation:run.pronunciation) : 0
        if verdict.met {
            run.completed=true;run.earnedXP=amount
            assess(correct:true,independent:run.attempts <= 1,now:now,questionLevel:run.questionLevel)
            addXP(amount,now:now,calendar:.current)
            var change=PracticeChange(date:now,dayKey:dailyKey,target:target,level:run.questionLevel,amount:amount,source:.practice,contentID:run.id.uuidString)
            change.attachCurriculumLesson(id:run.lessonID,level:run.lessonLevel);enqueue(change)
            practicedModes.insert(modeKey(run.lessonID,PracticeMode.conversation.rawValue))
        } else { captureMemory(mode:"conversation",concept:run.title,answer:utterance,expected:run.rubric,feedback:run.feedback,context:"realtime-goal",now:now) }
        history.insert(.init(date:now,target:target,mode:"realtime",question:run.title,answer:utterance,feedback:run.feedback,correct:verdict.met,repairInMemory:!verdict.met),at:0);history=Array(history.prefix(500))
        saveRealtimeLesson(run);return amount
    }
}
