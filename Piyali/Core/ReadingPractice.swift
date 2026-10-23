import Foundation

public struct ReadingRun:Codable,Equatable,Sendable {
    public var id=UUID()
    public let target:String
    public let support:String
    public let level:String
    public let lessonID:String?
    public var lessonLevel:String?
    public let title:String
    public let text:String
    public let takeaways:[String]
    public let question:ReadingQuestion
    public let selection:JSONValue
    public var worth:JSONValue
    public let reward:Int
    public var awarded=false
    public var method:String
    public var answer=""
    public var correct:Bool?
    public var feedback=""
    public var explanation:String?
    public var translation:String?
    public var lineTranslations:[String]?
    public var speechFeedback:ReadingSpeechFeedback?
    public var updatedAt=Date()
    public init(payload:JSONValue,target:String,support:String,level:String,lessonID:String?,selection:JSONValue,worth:JSONValue,roll:Double,method:String = "question",tutorial:Bool = false,recent:[JSONValue] = []) throws {
        guard payload.json.utf8.count <= 40_000,Reading.issues(candidate:payload,recent:recent,selection:selection,tutorial:tutorial).isEmpty,let question=ReadingQuestion(payload["reviewQuestion"]),payload["takeaways"].array.count == 3,payload["takeaways"].array.allSatisfy({ !$0.string.isEmpty }),StoryEpisode.compatible([payload["target"].string],target:target) else { throw ReadingFailure.invalid }
        guard !tutorial || Reading.sentences(payload["target"].string).count == 4 else { throw ReadingFailure.invalid }
        self.target=target;self.support=support;self.level=level;self.lessonID=lessonID;self.title=payload["title"].string;self.text=payload["target"].string;self.takeaways=payload["takeaways"].array.map(\.string);self.question=question;self.selection=selection;self.worth=worth;self.reward=Reading.award(roll:roll);self.method=method
    }
    public var contentID:String { id.uuidString.lowercased() }
    public var historyEntry:JSONValue { .object(["title":.string(title),"targetText":.string(String(text.prefix(6000))),"snippet":.string(String(text.prefix(900))),"lessonId":.string(lessonID ?? "free"),"format":selection["format"]["id"],"readingAngle":selection["readingAngle"]["id"],"structure":selection["structure"]["id"],"subject":selection["subject"]["id"]]) }
}
public enum ReadingFailure:LocalizedError { case invalid;public var errorDescription:String? { "The passage or question did not meet the reading requirements. Please try again." } }
public extension LearnerState {
    var reading:ReadingRun? { readingRuns?[target] }
    mutating func saveReading(_ run:ReadingRun) {
        var saved=run;saved.updatedAt=Date();if readingRuns == nil { readingRuns=[:] };readingRuns?[run.target]=saved
        while readingRuns!.count > 1,(readingRuns!.count > 3 || (try? JSONEncoder().encode(readingRuns).count) ?? 0 > 96_000) { let old=readingRuns!.values.filter { $0.target != run.target }.min { $0.updatedAt < $1.updatedAt }!.target;readingRuns?.removeValue(forKey:old) }
    }
    @discardableResult mutating func reviewReading(answer:String,correct:Bool,feedback:String,speech:Bool = false,speechFeedback:ReadingSpeechFeedback? = nil,now:Date = Date()) -> Int {
        guard var run=reading,run.support == support,!run.awarded,!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return 0 }
        run.answer=speech ? ReadingSpeechCapture.boundedTranscript(answer) : String(answer.prefix(4000));run.correct=correct;run.feedback=String(feedback.prefix(2000))
        if speech { run.speechFeedback=speechFeedback }
        let success=speech || correct,amount=success ? run.reward : 0
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:run.level,amount:amount,source:success ? (speech ? .readingSpeech : .readingTurn) : .practice,contentID:success ? run.contentID : run.contentID+":miss:"+UUID().uuidString)
        change.attachCurriculumLesson(id:run.lessonID,level:run.lessonLevel ?? run.level)
        if success {
            run.awarded=true;addXP(amount,now:now,calendar:.current)
            if !speech {
                change.correct=true;change.independent=true;change.conversationWorth=run.worth;change.conversationGoalText = .object(["en":.string(run.question.question)])
                let updated=ConversationPractice.rating(rating,level:run.level,success:true,worth:run.worth)
                if ratingByLanguage == nil { ratingByLanguage=[:] };ratingByLanguage?[target]=updated
                if gradedByLanguage == nil { gradedByLanguage=[:] };gradedByLanguage?[target,default:0] += 1
            }
            if let lesson=run.lessonID { practicedModes.insert(modeKey(lesson,PracticeMode.reading.rawValue)) }
        } else { captureMemory(mode:"reading",concept:run.question.question,answer:answer,expected:run.question.answer,feedback:feedback,context:run.lessonID ?? "reading",now:now) }
        change.readingProof = .object(["lang":.string(target),"supportLang":.string(support),"readingID":.string(run.contentID),"title":.string(run.title),"method":.string(speech ? "speech-transcript" : "question"),"answer":.string(run.answer),"ok":.bool(correct),"feedback":.string(run.feedback),"xpAwarded":.number(Double(amount))])
        if speech,let speechFeedback { change.readingProof=change.readingProof?.setting("speechFeedback",speechFeedback.value) }
        enqueue(change);saveReading(run);return amount
    }
}
