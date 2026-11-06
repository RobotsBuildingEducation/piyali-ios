import SwiftUI

/// The path quiz reuses the real typed grammar activity, with one attempt/item.
struct FinalQuizView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @StateObject private var service=PracticeService()
    let lesson:Lesson
    @State private var revision=UUID()
    @State private var fresh=false
    @State private var error:String?
    @State private var exiting=false
    private var run:FinalQuizRun? { app.learner.quizRuns?[app.learner.quizKey(lesson.id)] }
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var scope:String { app.identity.npub+":"+app.learner.target+":"+app.learner.support+":"+lesson.id }
    private func t(_ key:String)->String { EntryCopy.ui(app.learner.support,key) }
    var body:some View {
        SubscriptionRequiredView(service:app.subscription) {
            VStack(spacing:0) {
                if let run,!exiting {
                    if run.outcome.completed { result(run) }
                    else {
                        progress(run).padding(.top,14)
                        LessonPracticeView(module:.grammar,lesson:lesson,onNext:next,startsFresh:fresh,embedded:true,service:service).id(revision)
                    }
                } else { ProgressView().frame(maxWidth:.infinity,maxHeight:.infinity) }
                if let error { Text(error).foregroundStyle(.red).padding() }
            }.background(brand.background)
        }.navigationTitle(t("vocab_final_quiz")).navigationBarTitleDisplayMode(.inline)
            .task(id:scope) { do { _=try service.ensureQuiz(app,lesson:lesson) } catch { self.error=error.localizedDescription } }
            .onDisappear { service.cancel() }
    }
    private func progress(_ run:FinalQuizRun)->some View {
        VStack(spacing:8) {
            HStack { Text(t("vocab_final_quiz")).foregroundStyle(brand.secondary);Spacer();Text("\(run.outcome.answered)/\(run.rules.questionsRequired)").foregroundStyle(brand.muted).accessibilityIdentifier("quizProgress") }.font(PiyaliBrand.productFont(13,600))
            HStack(spacing:2) { ForEach(0..<run.rules.questionsRequired,id:\.self) { index in
                RoundedRectangle(cornerRadius:2).fill(index < run.answers.count ? run.answers[index] ? Color(red:99/255,green:179/255,blue:237/255) : Color(red:252/255,green:129/255,blue:129/255) : Color(red:45/255,green:55/255,blue:72/255).opacity(0.5)).frame(height:16)
            } }.accessibilityLabel("\(run.outcome.correct) correct, \(run.outcome.wrong) incorrect")
        }.frame(width:UIScreen.main.bounds.width/2)
    }
    private func result(_ run:FinalQuizRun)->some View {
        ScrollView {
            VStack(spacing:18) {
                Text(run.outcome.passed ? "🎉" : "🌱").font(.system(size:40))
                Text(t(run.outcome.passed ? "vocab_quiz_passed" : "vocab_quiz_not_passed")).font(PiyaliBrand.productFont(26,800)).multilineTextAlignment(.center).accessibilityIdentifier("quizResult")
                Text(t(run.outcome.passed ? "vocab_quiz_score_passed" : "vocab_quiz_score_failed").replacingOccurrences(of:"{correct}",with:String(run.outcome.correct)).replacingOccurrences(of:"{needed}",with:String(run.rules.passingScore))).font(PiyaliBrand.productFont(16)).foregroundStyle(brand.secondary)
                if !run.outcome.passed { Button(t("flashcard_try_again")) { restart() }.buttonStyle(QuestionPrimaryButtonStyle()).accessibilityIdentifier("quizRetry") }
                Button(t("vocab_back_to_skill_tree")) { exit(run) }.buttonStyle(BrandButtonStyle()).accessibilityIdentifier("quizExit")
            }.padding(24).frame(maxWidth:.infinity).background(brand.surface,in:RoundedRectangle(cornerRadius:24)).overlay { RoundedRectangle(cornerRadius:24).stroke(brand.border) }.padding(20)
        }
    }
    private func next() { guard run?.outcome.completed == false else { return };service.cancel();fresh=true;revision=UUID() }
    private func restart() {
        service.cancel();error=nil
        do { _=try service.ensureQuiz(app,lesson:lesson,restart:true);fresh=true;revision=UUID() }
        catch { self.error=error.localizedDescription }
    }
    private func exit(_ run:FinalQuizRun) {
        exiting=true;service.cancel()
        let completed=app.learner.completed.contains(app.learner.completionKey(lesson.id))
        if run.outcome.passed,!completed { app.complete(lesson) }
        let key=app.learner.quizKey(lesson.id);app.learner.quizRuns?.removeValue(forKey:key);app.persist()
        if !run.outcome.passed || completed || !app.lessonActivityActive { dismiss() }
    }
}
