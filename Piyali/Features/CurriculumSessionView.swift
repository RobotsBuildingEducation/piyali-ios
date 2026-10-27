import SwiftUI

/// One active lesson engine. Correct answers keep their per-format rewards;
/// reaching this lesson's own XP goal finishes the lesson before the daily task.
struct CurriculumSessionView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let lesson:Lesson
    @State private var mode=""
    @State private var gamePresented=false
    @State private var revision=UUID()
    @State private var fresh=true
    @State private var finishing=false
    @State private var appeared=false
    @State private var startedCompleted=false
    @State private var goalCompletionError:String?
    @State private var goalCompletionTask:Task<Void,Never>?
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var work:CurriculumLessonProgress? {if lesson.isGoal == true {return .init(earnedXP:Int(min(99999,GoalLessonProgress.earned(app.learner.goalBucket))))};return app.learner.lessonWork?[app.learner.completionKey(lesson.id)]}
    private var complete:Bool { app.learner.completed.contains(app.learner.completionKey(lesson.id)) }
    var body:some View {
        VStack(spacing:0) {
            if lesson.isGoal == true,let bp=lesson.goalBlueprint {GoalFocusBanner(blueprint:bp)}
            if let goalCompletionError {
                VStack(spacing:16){Text(goalCompletionError).multilineTextAlignment(.center).accessibilityIdentifier("goalLessonSaveError");Button(app.goalCompletionText("retry")){finishGoalLesson()}.buttonStyle(EntryButtonStyle()).accessibilityIdentifier("retryGoalLessonSave")}.padding(24)
            } else if finishing,lesson.isGoal == true,!complete {ProgressView(app.goalCompletionText("saving")).padding(24).accessibilityIdentifier("savingGoalLesson")}
            if !mode.isEmpty {engine.id(revision).allowsHitTesting(!finishing)}
        }.background(brand.background).navigationTitle(lesson.title.localized(app.learner.support)).navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented:$gamePresented,onDismiss:finishGamePresentation){NavigationStack{RPGView(lesson:lesson,episode:nil,onReviewComplete:{gamePresented=false})}}
            .onAppear { app.lessonActivityActive=true;guard !appeared else{return};appeared=true;startedCompleted=complete;if lesson.modes.contains("game"){gamePresented=true};if mode.isEmpty { mode=lesson.modes.first ?? "vocabulary" };app.beginLesson(lesson);checkThreshold() }
            .onDisappear {goalCompletionTask?.cancel();if !gamePresented{app.lessonActivityActive=false}}
            .onChange(of:work?.earnedXP) { _,_ in checkThreshold() }
            .onChange(of:complete) { _,completed in if completed,lesson.isGoal != true,!startedCompleted,!finishing { if lesson.modes.contains("game"){gamePresented=false}else{presentCompletion(reward:work?.earnedXP ?? lesson.xpReward)} } }
    }
    @ViewBuilder private var engine:some View {
        if lesson.isFinalQuiz == true { FinalQuizView(lesson:lesson) }
        else { switch mode {
        case "grammar","vocabulary":LessonPracticeView(module:mode == "grammar" ? .grammar : .vocabulary,lesson:lesson,onNext:advance,startsFresh:fresh,embedded:true)
        case "reading":ReadingView(lesson:lesson,onComplete:advance,embedded:true,startsFresh:fresh)
        case "stories":StoryView(lesson:lesson,onComplete:advance,embedded:true,startsFresh:fresh)
        case "game":Color.clear
        case "realtime":RealtimeLessonView(lesson:lesson,onNext:advance,startsFresh:fresh)
        default:EmptyView()
        } }
    }
    private func finishGamePresentation(){
        if complete,!startedCompleted,!finishing{presentCompletion(reward:app.learner.rpgRuns?[app.learner.target]?.reward ?? lesson.xpReward)}else{dismiss()}
    }
    private func advance() {
        guard !finishing else { return };checkThreshold();guard !finishing else { return }
        let other=lesson.modes.filter { $0 != mode };mode=(other.isEmpty ? lesson.modes : other).randomElement() ?? "vocabulary";fresh=true;revision=UUID()
    }
    private func checkThreshold() {
        guard !finishing,!complete,work?.status == .inProgress,lesson.isFinalQuiz != true,!lesson.modes.contains("game"),app.canComplete(lesson) else { return }
        if lesson.isGoal == true {finishGoalLesson();return}
        finishing=true;app.complete(lesson)
        guard complete else { finishing=false;return }
        publishCompletion(reward:lesson.xpReward)
    }
    private func finishGoalLesson(){
        guard goalCompletionTask == nil else{return};finishing=true;goalCompletionError=nil
        goalCompletionTask=Task {defer{goalCompletionTask=nil};do{try await app.completeFocusedGoalLesson(lesson);app.lessonActivityActive=false}catch is CancellationError{}catch{goalCompletionError=app.goalCompletionText("error")}}
    }
    private func presentCompletion(reward:Int) { finishing=true;publishCompletion(reward:reward) }
    private func publishCompletion(reward:Int) {
        app.pendingLessonCompletion = .init(account:app.identity.npub,target:app.learner.target,lesson:lesson,reward:reward,languageXP:app.learner.xp)
        dismiss()
    }
}
