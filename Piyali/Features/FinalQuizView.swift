import SwiftUI

struct FinalQuizView:View {
    @EnvironmentObject var app:AppModel
    @StateObject private var service=FinalQuizService()
    @StateObject private var speech=SpeechService()
    let lesson:Lesson
    @State private var answer=""
    @State private var mode:PracticeMode = .grammar
    private var run:FinalQuizRun? { app.learner.quizRuns?[app.learner.quizKey(lesson.id)] }
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,lesson.id].joined(separator:"|") }
    var body:some View {
        Group { if FinalQuizService.fixture { activity } else { SubscriptionRequiredView(service:app.subscription) { activity } } }
            .navigationTitle("Final quiz")
            .task(id:scope) { answer="";await service.prepare(app,lesson:lesson,mode:mode) }
            .onChange(of:speech.transcript) { _,value in if run?.question?.grade == nil { answer=value } }
            .onDisappear { service.cancel();speech.stopAll() }
    }
    private var activity:some View {
        Form {
            let rules=QuizRules(lesson.quizConfig ?? .object([:]))
            Section(lesson.title.localized(app.learner.support)) {
                Text("Get \(rules.passingScore) correct within \(rules.questionsRequired) questions. The quiz ends early when you pass or passing becomes impossible. Questions earn no XP; completing the lesson awards its reward once.")
                if let run {
                    Text("\(run.outcome.correct) correct · \(run.outcome.wrong) incorrect · \(run.outcome.answered)/\(rules.questionsRequired) answered").accessibilityIdentifier("quizProgress")
                    ProgressView(value:Double(run.outcome.answered),total:Double(rules.questionsRequired))
                }
            }
            if let run,run.outcome.completed {
                Section(run.outcome.passed ? "Quiz passed" : "Quiz not passed") {
                    Text(run.outcome.passed ? "You reached the passing score." : "Review the feedback and try a new round.").accessibilityIdentifier("quizResult")
                    if !run.outcome.passed { Button("Retry quiz") { service.cancel();speech.stopAll();app.learner.saveQuiz(FinalQuizRun(lesson:lesson,learner:app.learner));app.persist();answer="";Task { await service.prepare(app,lesson:lesson,mode:mode) } }.accessibilityIdentifier("quizRetry") }
                    else { Button(app.learner.completed.contains(app.learner.completionKey(lesson.id)) ? "Lesson already completed" : "Complete quiz lesson (+\(lesson.xpReward) XP)") { app.complete(lesson) }.disabled(app.learner.completed.contains(app.learner.completionKey(lesson.id))).accessibilityIdentifier("quizComplete") }
                }
            }
            if let question=run?.question {
                Section(question.mode.rawValue) {
                    if !question.exercise.passage.isEmpty { Text(question.exercise.passage);Button("Listen") { speech.speak(question.exercise.passage,language:app.learner.target) } }
                    Text(question.exercise.question).accessibilityIdentifier("quizQuestion")
                    if question.grade == nil {
                        ForEach(Array(question.exercise.choices.enumerated()),id:\.offset) { index,value in Button { answer=value } label:{ HStack { Text(value);Spacer();if answer == value { Image(systemName:"checkmark") } } }.accessibilityIdentifier("quizOption-"+String(index)).disabled(service.busy) }
                        if question.exercise.choices.isEmpty { TextField("Your answer",text:$answer,axis:.vertical).accessibilityIdentifier("quizAnswer");Button(speech.recording ? "Stop microphone" : "Answer aloud") { if speech.recording { speech.stop() } else { Task { await speech.start(language:app.learner.target) } } } }
                        Button("Check answer") { speech.stop();Task { await service.submit(app,lesson:lesson,answer:answer) } }.disabled(answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || service.busy).accessibilityIdentifier("quizCheck")
                    } else if let grade=question.grade {
                        Text(grade.correct ? "Correct" : "Incorrect").font(.headline);Text(grade.feedback);Text(grade.correctedAnswer)
                        Button("Save feedback to notes") { app.learner.notes.insert(Note(title:question.exercise.question,body:grade.correctedAnswer+"\n"+grade.feedback),at:0);app.persist() }
                    }
                }
            }
            if let run,!run.outcome.completed,run.question?.grade != nil || run.question == nil {
                Section {
                    Picker("Next question",selection:$mode) { Text("Grammar").tag(PracticeMode.grammar);Text("Vocabulary").tag(PracticeMode.vocabulary) }
                    Button(run.question == nil ? "Generate question" : "Next question") { answer="";speech.stopAll();Task { await service.prepare(app,lesson:lesson,mode:mode) } }.disabled(service.busy).accessibilityIdentifier("quizNext")
                }
            }
            if service.busy { ProgressView("Working on your quiz…") }
            if let error=service.error { Text(error).foregroundStyle(.red) }
            if let error=speech.error { Text(error).foregroundStyle(.red) }
        }
    }
}
