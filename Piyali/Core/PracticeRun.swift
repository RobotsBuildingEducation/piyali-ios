import Foundation

public struct PracticeRun:Codable,Sendable {
    public let question:PracticeQuestion
    public let lessonID:String?
    public let lessonLevel:String?
    public let bank:[String]
    public var rightOrder:[Int]?
    public var response:JSONValue = .object([:])
    public var correct:Bool?
    public var earnedXP=0
    public var assisted=false
    public var showAnswer:Bool?
    public var revealedClues=1
    public var explanation=""
    public var updatedAt=Date()
    public init(question:PracticeQuestion,lessonID:String?,lessonLevel:String?,response:JSONValue = .object([:]),bank:[String]?=nil) {
        self.question=question;self.lessonID=lessonID;self.lessonLevel=lessonLevel;self.response=response
        self.bank=bank ?? (["translate","repeat"].contains(question.kind) ? (question.strings("correctWords")+question.strings("distractors")).shuffled() : question.strings("choices"))
        if question.kind == "match" { rightOrder=Array(question.strings("right").indices).shuffled() }
    }
    public var key:String { Self.key(target:question.target,lesson:lessonID,module:question.module) }
    public static func key(target:String,lesson:String?,module:PracticeRecipeModule)->String { target+":"+(lesson ?? "free")+":"+module.rawValue }
    public var answerText:String {
        guard question.isDelight else { return question.responseText(response,bank:bank) }
        let p=question.payload,r=response
        switch question.variant {
        case "sentence_detective":return r["replacement"].string
        case "dialogue_fork","listen_difference":let index=Int(r["selectedIndex"].number);let options=question.strings("options");return options.indices.contains(index) ? options[index] : ""
        case "morphology_forge":let pieces=question.strings("pieces");return r["pieceIndices"].array.compactMap { value in let index=Int(value.number);return pieces.indices.contains(index) ? pieces[index] : nil }.joined()
        case "word_neighborhoods":let groups=p["groups"].array;return r["assignments"].object.keys.sorted().map { word in let index=Int(r["assignments"][word].number);return word+" → "+(groups.indices.contains(index) ? groups[index]["label"].string : "") }.joined(separator:"\n")
        case "natural_or_weird":return r["choice"] == .null ? "" : r["choice"].boolean ? "Natural" : "Weird"
        default:return r["text"].string
        }
    }
    public var expected:String {
        if ["translate","repeat"].contains(question.kind) { return question.strings("correctWords").joined(separator:" ") }
        if question.kind == "ma" { return question.strings("answers").joined(separator:", ") }
        if question.kind == "speak" { return question.payload["target"].string }
        if question.variant == "morphology_forge" { return question.payload["answerWord"].string }
        if question.variant == "natural_or_weird" { return question.payload["correction"].string.isEmpty ? question.payload["sentence"].string : question.payload["correction"].string }
        if ["dialogue_fork","listen_difference"].contains(question.variant) { let choices=question.strings("options"),index=Int(question.payload["answerIndex"].number);return choices.indices.contains(index) ? choices[index] : "" }
        if question.kind == "match" { return question.strings("left").enumerated().map { i,left in let right=question.module == .vocabulary ? i : Int(question.payload["map"].array[i].number);return left+" → "+question.strings("right")[right] }.joined(separator:"\n") }
        if !question.payload["answer"].string.isEmpty { return question.payload["answer"].string }
        return question.payload["explanation"].string
    }
}
public extension LearnerState {
    mutating func savePractice(_ run:PracticeRun) {
        if practiceRuns == nil { practiceRuns=[:] };var saved=run;saved.updatedAt=Date();practiceRuns?[run.key]=saved
        // Bound private snapshots while preserving the most recent sessions.
        while practiceRuns!.count > 1,(practiceRuns!.count > 12 || (try? JSONEncoder().encode(practiceRuns).count) ?? 0 > 100_000) { if let oldest=practiceRuns!.min(by:{ $0.value.updatedAt < $1.value.updatedAt })?.key { practiceRuns?.removeValue(forKey:oldest) } }
    }
    @discardableResult mutating func answerPractice(key:String,questionID:UUID,correct:Bool,reward:Int,now:Date = Date())->Bool {
        guard var run=practiceRuns?[key],run.question.id == questionID,run.question.target == target,run.question.support == support,run.correct != true else { return false }
        run.correct=correct;run.earnedXP=correct && !run.question.options["isFinalQuiz"].boolean ? max(0,min(10,reward)) : 0;run.updatedAt=now
        let q=run.question
        assess(correct:correct,independent:!run.assisted,now:now,questionLevel:q.level)
        if correct,run.earnedXP > 0 {
            addXP(run.earnedXP,now:now,calendar:.current)
            var change=PracticeChange(date:now,dayKey:dailyKey,target:target,level:q.level,amount:run.earnedXP,source:.practice,contentID:q.id.uuidString)
            change.attachCurriculumLesson(id:run.lessonID,level:run.lessonLevel ?? level);enqueue(change)
            if let id=run.lessonID { practicedModes.insert(modeKey(id,q.module == .grammar ? PracticeMode.grammar.rawValue : PracticeMode.vocabulary.rawValue)) }
        } else if !correct { captureMemory(mode:q.module.rawValue,concept:q.questionText,answer:run.answerText,expected:run.expected,feedback:"",context:run.lessonID ?? "",now:now) }
        history.insert(.init(date:now,target:target,mode:q.module.rawValue,question:q.questionText,answer:run.answerText,feedback:correct ? "Correct" : "Try again",correct:correct,repairInMemory:!correct),at:0);history=Array(history.prefix(500))
        practiceRuns?[key]=run
        if correct { collectPracticeCard(run) }
        return true
    }
}
public struct PracticeCollectedCard:Codable,Identifiable,Sendable {
    public let id:UUID
    public let concept:String
    public let answer:String
    public let target:String
    public let support:String
}
public extension LearnerState {
    func practiceDeckKey(_ module:PracticeRecipeModule)->String { target+":"+module.rawValue }
    mutating func collectPracticeCard(_ run:PracticeRun) {
        guard run.question.kind == "flashcard",run.question.target == target,run.question.support == support else { return }
        let key=practiceDeckKey(run.question.module)
        guard !(practiceDecks?[key] ?? []).contains(where:{ $0.id == run.question.id }) else { return }
        if practiceDecks == nil { practiceDecks=[:] }
        let card=PracticeCollectedCard(id:run.question.id,concept:run.question.payload["concept"].string,answer:run.question.payload["answer"].string,target:target,support:support)
        let next=Array(((practiceDecks?[key] ?? [])+[card]).suffix(100))
        practiceDecks?[key]=next
    }
}
