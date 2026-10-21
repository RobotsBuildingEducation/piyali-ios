import SwiftUI

/// One active lesson engine. Correct answers keep their per-format rewards;
/// reaching this lesson's own XP goal finishes the lesson before the daily task.
struct CurriculumSessionView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let lesson:Lesson
    @State private var mode=""
    @State private var revision=UUID()
    @State private var fresh=false
    @State private var finishing=false
    @State private var startedCompleted=false
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var work:CurriculumLessonProgress? { app.learner.lessonWork?[app.learner.completionKey(lesson.id)] }
    private var complete:Bool { app.learner.completed.contains(app.learner.completionKey(lesson.id)) }
    var body:some View {
        VStack(spacing:0) {
            if lesson.isFinalQuiz != true { VStack(spacing:10) {
                if lesson.isFinalQuiz != true {
                    HStack { Text(lesson.title.localized(app.learner.support)).font(PiyaliBrand.productFont(16,700));Spacer();Text("\(work?.earnedXP ?? 0) / \(lesson.xpReward) XP").font(PiyaliBrand.productFont(13,600)).accessibilityIdentifier("activeLessonXP") }
                    ProgressView(value:work?.fraction(goal:lesson.xpReward) ?? 0).tint(brand.questionChoice)
                }
                if lesson.isFinalQuiz != true,!lesson.modes.contains("game") {
                    ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:10) { ForEach(lesson.modes,id:\.self) { item in
                        Button { fresh=false;mode=item;revision=UUID() } label:{ Label(LessonSessionCopy.module(item,language:app.learner.support),systemImage:LessonPreviewView.icon(item)).font(PiyaliBrand.productFont(13,600)).padding(.horizontal,12).padding(.vertical,10).foregroundStyle(item == mode ? brand.questionChoice : brand.secondary).background(item == mode ? brand.questionChoiceBackground : brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(item == mode ? brand.questionChoice : brand.border) } }.buttonStyle(.plain).accessibilityIdentifier("lessonMode-"+item)
                    } } }
                }
            }.padding(18).background(brand.background) }
            if !mode.isEmpty { engine.id(revision) }
        }.background(brand.background).navigationTitle(lesson.title.localized(app.learner.support)).navigationBarTitleDisplayMode(.inline)
            .onAppear { startedCompleted=complete;app.lessonActivityActive=true;if mode.isEmpty { mode=lesson.modes.first ?? "vocabulary" };app.beginLesson(lesson);checkThreshold() }
            .onDisappear { app.lessonActivityActive=false }
            .onChange(of:work?.earnedXP) { _,_ in checkThreshold() }
            .onChange(of:complete) { _,completed in if completed,!startedCompleted,!finishing { presentCompletion(reward:work?.earnedXP ?? lesson.xpReward) } }
    }
    @ViewBuilder private var engine:some View {
        if lesson.isFinalQuiz == true { FinalQuizView(lesson:lesson) }
        else { switch mode {
        case "grammar","vocabulary":LessonPracticeView(module:mode == "grammar" ? .grammar : .vocabulary,lesson:lesson,onNext:advance,startsFresh:fresh,embedded:true)
        case "reading":ReadingView(lesson:lesson,onComplete:advance,embedded:true,startsFresh:fresh)
        case "stories":StoryView(lesson:lesson,onComplete:advance,embedded:true,startsFresh:fresh)
        case "game":RPGView(lesson:lesson,episode:nil)
        case "realtime":RealtimeLessonView(lesson:lesson,onNext:advance,startsFresh:fresh)
        default:EmptyView()
        } }
    }
    private func advance() {
        guard !finishing else { return };checkThreshold();guard !finishing else { return }
        let other=lesson.modes.filter { $0 != mode };mode=(other.isEmpty ? lesson.modes : other).randomElement() ?? "vocabulary";fresh=true;revision=UUID()
    }
    private func checkThreshold() {
        guard !finishing,!complete,work?.status == .inProgress,lesson.isFinalQuiz != true,!lesson.modes.contains("game"),app.canComplete(lesson) else { return }
        finishing=true;app.complete(lesson)
        guard complete else { finishing=false;return }
        publishCompletion(reward:lesson.xpReward)
    }
    private func presentCompletion(reward:Int) { finishing=true;publishCompletion(reward:reward) }
    private func publishCompletion(reward:Int) {
        app.pendingLessonCompletion = .init(account:app.identity.npub,target:app.learner.target,lesson:lesson,reward:reward,languageXP:app.learner.xp)
        dismiss()
    }
}
