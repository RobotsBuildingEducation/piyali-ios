import Foundation

@MainActor final class FinalQuizService:ObservableObject {
    @Published var busy=false
    @Published var error:String?
    private var generation=UUID()
    private var task:Task<Void,Never>?
    static var fixture:Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" && UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil && ProcessInfo.processInfo.environment["PIYALI_QUIZ_FIXTURE"] == "1"
        #else
        return false
        #endif
    }
    static func concept(_ run:FinalQuizRun,mode:PracticeMode) -> String {
        "Final quiz, question \(run.answers.count+1). Give a new question grounded in the authored \(mode.rawValue) content. Do not reveal its answer in the prompt. Previous question to avoid repeating: \(run.question?.exercise.question ?? "none")."
    }
    func cancel() { generation=UUID();task?.cancel();task=nil;busy=false }
    private func valid(_ app:AppModel,account:String,run:FinalQuizRun,token:UUID) -> Bool { !Task.isCancelled && token == generation && app.identity.npub == account && app.learner.target == run.target && app.learner.support == run.support && app.learner.quizRuns?[app.learner.quizKey(run.lessonID)]?.id == run.id }
    func prepare(_ app:AppModel,lesson:Lesson,mode:PracticeMode) async {
        guard lesson.isFinalQuiz == true,Self.fixture || app.subscription.hasAccess else { return }
        cancel();error=nil;let token=generation,account=app.identity.npub
        var run=app.learner.quizRuns?[app.learner.quizKey(lesson.id)] ?? FinalQuizRun(lesson:lesson,learner:app.learner)
        if !run.matches(lesson,app.learner) { run=FinalQuizRun(lesson:lesson,learner:app.learner) }
        app.learner.saveQuiz(run);app.persist()
        guard !run.outcome.completed,run.question == nil || run.question?.grade != nil else { return }
        busy=true
        let work=Task { @MainActor in
            defer { if token == self.generation { self.busy=false;self.task=nil } }
            do {
                var state=app.learner;state.level=run.level
                let exercise:Exercise
                if Self.fixture { exercise=Exercise(passage:"",question:"Select the Spanish greeting.",choices:["hola","adiós"],answer:"hola",explanation:"Hola means hello.") }
                else { exercise=try await app.ai.exercise(mode:mode,lesson:lesson,learner:state,concept:Self.concept(run,mode:mode)) }
                guard self.valid(app,account:account,run:run,token:token) else { return }
                guard run.prepare(exercise,mode:mode) else { throw AppError.message("The quiz question was incomplete. Try again.") }
                app.learner.saveQuiz(run);app.persist()
            } catch { if self.valid(app,account:account,run:run,token:token),!(error is CancellationError) { self.error=error.localizedDescription } }
        };task=work;await work.value
    }
    func submit(_ app:AppModel,lesson:Lesson,answer:String) async {
        guard !busy,Self.fixture || app.subscription.hasAccess,let run=app.learner.quizRuns?[app.learner.quizKey(lesson.id)],let question=run.question,question.grade == nil,!run.outcome.completed,!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return }
        cancel();error=nil;busy=true;let token=generation,account=app.identity.npub
        let work=Task { @MainActor in
            defer { if token == self.generation { self.busy=false;self.task=nil } }
            do {
                var state=app.learner;state.level=run.level
                let grade=try await app.ai.grade(exercise:question.exercise,answer:answer,learner:state)
                guard self.valid(app,account:account,run:run,token:token) else { return }
                if app.learner.answerQuiz(lesson:lesson,runID:run.id,questionID:question.id,answer:answer,grade:grade) { app.persist() }
            } catch { if self.valid(app,account:account,run:run,token:token),!(error is CancellationError) { self.error=error.localizedDescription } }
        };task=work;await work.value
    }
}
