import Foundation

public struct QuizRules:Codable,Equatable,Sendable {
    public let questionsRequired:Int
    public let passingScore:Int
    public init(_ raw:JSONValue = .object([:])) {
        func numeric(_ value:JSONValue,_ fallback:Int) -> Int {
            let n:Double
            switch value { case .number(let v):n=v;case .string(let v):n=Double(v) ?? 0;default:n=0 }
            guard n.isFinite,n != 0 else { return fallback };return Int(max(1,min(100,n.rounded(.up))))
        }
        questionsRequired=numeric(raw["questionsRequired"],10)
        passingScore=min(questionsRequired,numeric(raw["passingScore"],8))
    }
    public func outcome(_ answers:[Bool]) -> QuizOutcome {
        let correct=answers.filter { $0 }.count,wrong=answers.count-correct
        let completed=correct >= passingScore || wrong > questionsRequired-passingScore || answers.count >= questionsRequired
        return QuizOutcome(answered:answers.count,correct:correct,wrong:wrong,completed:completed,passed:completed && correct >= passingScore)
    }
}
public struct QuizOutcome:Equatable,Sendable { public let answered:Int;public let correct:Int;public let wrong:Int;public let completed:Bool;public let passed:Bool }
public struct QuizQuestion:Codable,Sendable {
    public var id=UUID()
    public let mode:PracticeMode
    public let exercise:Exercise
    public var answer=""
    public var grade:Grade?
    public init(mode:PracticeMode,exercise:Exercise) { self.mode=mode;self.exercise=exercise }
}
public struct FinalQuizRun:Codable,Sendable {
    public var id=UUID()
    public let target:String
    public let support:String
    public let level:String
    public let lessonID:String
    public let rules:QuizRules
    public var answers:[Bool]=[]
    public var question:QuizQuestion?
    public var typedOptions:[JSONValue]?
    public var typedQuestionID:UUID?
    public var typedAnsweredIDs:[UUID]?
    public var updatedAt=Date()
    public var outcome:QuizOutcome { rules.outcome(answers) }
    public init(lesson:Lesson,learner:LearnerState) {
        target=learner.target;support=learner.support;level=lesson.cefrLevel ?? learner.level;lessonID=lesson.id;rules=QuizRules(lesson.quizConfig ?? .object([:]))
    }
    public func matches(_ lesson:Lesson,_ learner:LearnerState) -> Bool { target == learner.target && lessonID == lesson.id && rules == QuizRules(lesson.quizConfig ?? .object([:])) && (outcome.completed || support == learner.support) }
    public mutating func prepare(_ exercise:Exercise,mode:PracticeMode) -> Bool {
        guard !outcome.completed,question == nil || question?.grade != nil,!exercise.question.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,!exercise.answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,exercise.choices.count <= 8,exercise.choices.isEmpty || exercise.choices.count >= 2 && exercise.choices.contains(where:{ AnswerMatcher.matches($0,exercise.answer) }) else { return false }
        question=QuizQuestion(mode:mode,exercise:exercise);updatedAt=Date();return true
    }
}
public extension LearnerState {
    func quizKey(_ lessonID:String) -> String { target+":"+lessonID }
    func quizPassed(_ lesson:Lesson) -> Bool {
        if quizPasses?[quizKey(lesson.id)] == QuizRules(lesson.quizConfig ?? .object([:])) { return true }
        guard let run=quizRuns?[quizKey(lesson.id)],run.matches(lesson,self) else { return false };return run.outcome.passed
    }
    mutating func saveQuiz(_ run:FinalQuizRun) {
        guard run.target == target else { return };let key=quizKey(run.lessonID);if quizRuns == nil { quizRuns=[:] };quizRuns?[key]=run
        while quizRuns!.count > 1,(quizRuns!.count > 30 || (try? JSONEncoder().encode(quizRuns).count) ?? 0 > 150_000) { guard let old=quizRuns!.filter({ $0.key != quizKey(run.lessonID) }).min(by:{ $0.value.updatedAt < $1.value.updatedAt })?.key else { break };quizRuns?.removeValue(forKey:old) }
    }
    @discardableResult mutating func prepareTypedQuizQuestion(_ question:PracticeQuestion,lessonID:String,runID:UUID)->Bool {
        let key=quizKey(lessonID)
        guard var run=quizRuns?[key],run.id == runID,run.target == target,run.support == support,!run.outcome.completed,question.target == target,question.support == support,question.options["isFinalQuiz"].boolean,question.kind != "flashcard",run.typedQuestionID == nil || (run.typedAnsweredIDs ?? []).contains(run.typedQuestionID!) else { return false }
        run.question=nil;run.typedQuestionID=question.id;run.updatedAt=Date();saveQuiz(run);return true
    }
    @discardableResult mutating func answerTypedQuizQuestion(lessonID:String,runID:UUID,questionID:UUID,correct:Bool,now:Date = Date())->Bool {
        let key=quizKey(lessonID)
        guard var run=quizRuns?[key],run.id == runID,run.target == target,run.support == support,!run.outcome.completed,run.typedQuestionID == questionID,!(run.typedAnsweredIDs ?? []).contains(questionID) else { return false }
        run.typedAnsweredIDs=(run.typedAnsweredIDs ?? [])+[questionID];run.answers.append(correct);run.updatedAt=now;saveQuiz(run)
        if run.outcome.passed { if quizPasses == nil { quizPasses=[:] };quizPasses?[key]=run.rules };return true
    }
    @discardableResult mutating func answerQuiz(lesson:Lesson,runID:UUID,questionID:UUID,answer:String,grade:Grade,now:Date=Date()) -> Bool {
        let key=quizKey(lesson.id)
        guard lesson.isFinalQuiz == true,var run=quizRuns?[key],run.matches(lesson,self),run.support == support,run.id == runID,!run.outcome.completed,var question=run.question,question.id == questionID,question.grade == nil,!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return false }
        question.answer=String(answer.prefix(8000));question.grade=grade;run.question=question;run.answers.append(grade.correct);run.updatedAt=now;saveQuiz(run)
        if run.outcome.passed { if quizPasses == nil { quizPasses=[:] };quizPasses?[key]=run.rules }
        if !(pendingChanges ?? []).contains(where:{ $0.id == questionID }),!(acknowledgedEventIDs ?? []).contains(questionID) {
            let updated=PerformanceScore.update(rating:rating,questionLevel:run.level,correct:grade.correct,independent:question.exercise.choices.isEmpty)
            if ratingByLanguage == nil { ratingByLanguage=[:] };ratingByLanguage?[target]=updated
            if gradedByLanguage == nil { gradedByLanguage=[:] };gradedByLanguage?[target,default:0] += 1
            var change=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:target,level:run.level,amount:0,source:.assessment,contentID:lesson.id,correct:grade.correct,independent:question.exercise.choices.isEmpty);change.id=questionID;enqueue(change)
        }
        if !history.contains(where:{ $0.id == questionID }) {
            var item=HistoryEntry(date:now,target:target,mode:"Quiz · "+question.mode.rawValue,question:question.exercise.question,answer:question.answer,feedback:grade.feedback,correct:grade.correct,repairInMemory:!grade.correct);item.id=questionID;history.insert(item,at:0);history=Array(history.prefix(500))
        }
        if !grade.correct { captureMemory(mode:question.mode.rawValue.lowercased(),concept:question.exercise.question,answer:question.answer,expected:grade.correctedAnswer,feedback:grade.feedback,context:lesson.id,now:now) }
        return true
    }
}
