import Foundation

public struct StoryRun:Codable,Equatable,Sendable {
    public var id=UUID()
    public let target:String
    public let support:String
    public let level:String
    public let lessonID:String?
    public var lessonLevel:String?
    public var sourceContext:String?
    public let mode:StoryMode
    public var portraitIDs:[String:String]?
    public var episode:StoryEpisode?
    public var sentences:[StoryTurn]
    public let title:String
    public let worth:JSONValue
    public var index=0
    public var answers:[String:[Int]]=[:]
    public var results:[String:Bool]=[:]
    public var heard=Set<Int>()
    public var practicedRoleLines=Set<String>()
    public var passedLines=Set<Int>()
    public var completed=false
    public var earnedXP=0
    public var speechResult:StorySpeechResult?
    public var lastWords=""
    public var translations:[String:String]=[:]
    public var updatedAt=Date()
    public init(payload:JSONValue,mode:StoryMode,target:String,support:String,level:String,lessonID:String?,worth:JSONValue,tutorial:Bool = false) throws {
        guard payload.json.utf8.count <= 60_000 else { throw StoryFailure.invalid }
        self.target=target;self.support=support;self.level=level;self.lessonID=lessonID;self.mode=mode;self.worth=worth
        if mode == .speaking {
            guard !payload["title"].string.isEmpty,let lines=try? JSONDecoder().decode([StoryTurn].self,from:JSONEncoder().encode(payload["sentences"])),(tutorial ? 2...3 : 8...10).contains(lines.count),Set(lines.map(\.speaker)).count == 2,lines.allSatisfy({ !$0.target.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && $0.target.utf8.count <= 8000 && !$0.speaker.isEmpty }),StoryEpisode.compatible(lines.map(\.target),target:target) else { throw StoryFailure.invalid }
            sentences=lines;title=payload["title"].string;episode=nil
        } else { let value=try StoryEpisode.parse(payload,target:target,prepare:true);episode=value;sentences=[];title=value.title }
    }
    public static func contextData(content:JSONValue,agenda:JSONValue,level:String)throws->Data {
        let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys,.withoutEscapingSlashes]
        return try encoder.encode(JSONValue.object(["content":content,"agenda":agenda,"level":.string(level)]))
    }
    public var count:Int { mode == .speaking ? sentences.count : episode?.segments.count ?? 0 }
    public var atEnd:Bool { index >= count }
    public var currentSegment:StorySegment? { guard let episode,episode.segments.indices.contains(index) else { return nil };return episode.segments[index] }
    public var currentSentence:StoryTurn? { sentences.indices.contains(index) ? sentences[index] : nil }
    public var result:Bool? { results[String(index)] }
    public var correctQuestions:Int { results.values.filter { $0 }.count }
    public var text:String { episode?.text ?? sentences.map(\.target).joined(separator:"\n") }
    public func contentID(_ step:String) -> String { id.uuidString.lowercased()+":"+step }
    public mutating func select(_ option:Int) {
        guard result == nil,let q=currentSegment?.question,q.options.indices.contains(option) else { return }
        var chosen=answers[String(index)] ?? []
        if ["select_words","order_words"].contains(q.type) { if let found=chosen.firstIndex(of:option) { chosen.remove(at:found) } else if chosen.count < q.answer.count { chosen.append(option) } } else { chosen=[option] }
        answers[String(index)]=chosen
    }
    public var readyToCheck:Bool {
        guard result == nil,let question=currentSegment?.question else { return false }
        return (answers[String(index)] ?? []).count == (["order_words","select_words"].contains(question.type) ? question.answer.count : 1)
    }
    public mutating func check() {
        guard !completed,heard.contains(index),readyToCheck,let q=currentSegment?.question else { return }
        results[String(index)]=q.correct(answers[String(index)] ?? [])
    }
    public mutating func advance() {
        guard !completed,!atEnd,mode == .speaking || result != nil else { return }
        index += 1;speechResult=nil;lastWords=""
    }
}
public extension LearnerState {
    var story:StoryRun? { storyRuns?[target] }
    mutating func saveStory(_ run:StoryRun) {
        var saved=run;saved.updatedAt=Date();if storyRuns == nil { storyRuns=[:] };storyRuns?[run.target]=saved
        while storyRuns!.count > 1,(storyRuns!.count > 3 || (try? JSONEncoder().encode(storyRuns).count) ?? 0 > 80_000) {
            let oldest=storyRuns!.values.filter { $0.target != run.target }.min { $0.updatedAt < $1.updatedAt }!.target;storyRuns?.removeValue(forKey:oldest)
        }
    }
    @discardableResult mutating func practiceStoryLine(words:String,confidence:Double = 0,audio:SpeechAudioMetrics? = nil,typed:Bool = false,now:Date = Date()) -> Int {
        guard var run=story,run.support == support,run.mode == .speaking,!run.completed,!run.passedLines.contains(run.index),run.speechResult == nil,let line=run.currentSentence,!words.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return 0 }
        let verdict=StorySpeech.evaluate(recognized:words,target:line.target,lang:run.target,confidence:confidence,audio:audio)
        run.speechResult=verdict;run.lastWords=String(words.prefix(2000));let amount=verdict.pass ? 2 : 0
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:run.target,level:run.level,amount:amount,source:verdict.pass ? .storyTurn : .practice,contentID:run.contentID(verdict.pass ? "line-"+String(run.index) : "miss-"+UUID().uuidString))
        change.attachCurriculumLesson(id:run.lessonID,level:run.lessonLevel ?? run.level)
        if verdict.pass {
            run.passedLines.insert(run.index);run.earnedXP += 2
            change.correct=true;change.independent=true;change.conversationWorth=run.worth;change.conversationGoalText = .object(["en":.string(line.target)])
            let updated=ConversationPractice.rating(rating,level:run.level,success:true,worth:run.worth)
            if ratingByLanguage == nil { ratingByLanguage=[:] };ratingByLanguage?[target]=updated
            if gradedByLanguage == nil { gradedByLanguage=[:] };gradedByLanguage?[target,default:0] += 1
            addXP(2,now:now,calendar:.current)
        } else { captureMemory(mode:"story",concept:line.target,answer:words,expected:line.target,feedback:"Match the line's words and speak clearly.",context:run.lessonID ?? "story",now:now) }
        change.storyProof = .object(["origin":.string("story"),"mode":.string("sentence"),"lang":.string(run.target),"supportLang":.string(run.support),"sentenceIndex":.number(Double(run.index)),"target":.string(line.target),"recognizedText":.string(String(words.prefix(2000))),"ok":.bool(verdict.pass),"method":.string(typed ? "typed" : "speech"),"xpAwarded":.number(Double(amount)),"confidence":.number(confidence),"eval":.object(["pass":.bool(verdict.pass),"score":.number(Double(verdict.score)),"reasons":.array(verdict.reasons.map(JSONValue.string))])])
        enqueue(change);saveStory(run);return amount
    }
    @discardableResult mutating func finishStory(now:Date = Date()) -> Int {
        guard var run=story,run.support == support,run.atEnd,!run.completed,run.mode == .speaking || run.results.count == run.count else { return 0 }
        let amount=run.mode == .speaking ? 0 : 6;run.completed=true;run.earnedXP += amount
        var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:run.target,level:run.level,amount:amount,source:.storyCompletion,contentID:run.contentID("complete"))
        change.attachCurriculumLesson(id:run.lessonID,level:run.lessonLevel ?? run.level)
        change.storyProof = .object(["origin":.string("story"),"mode":.string(run.mode == .speaking ? "story-session-complete" : "story-"+run.mode.rawValue+"-complete"),"lang":.string(run.target),"supportLang":.string(run.support),"totalQuestions":.number(Double(run.count)),"correctQuestions":.number(Double(run.correctQuestions)),"totalSentences":.number(Double(run.sentences.count)),"passedSentences":.number(Double(run.passedLines.count)),"xpAwarded":.number(Double(amount)),"sessionXp":.number(Double(run.earnedXP))])
        if amount > 0 { addXP(amount,now:now,calendar:.current) };enqueue(change)
        if let lesson=run.lessonID { practicedModes.insert(modeKey(lesson,PracticeMode.stories.rawValue)) }
        saveStory(run);return amount
    }
}
