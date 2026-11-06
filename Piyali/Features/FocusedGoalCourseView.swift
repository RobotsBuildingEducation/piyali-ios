import SwiftUI

/// The Goal course goes straight to its next unfinished modality, as App.jsx does.
struct FocusedGoalCourseView:View {
    @EnvironmentObject var app:AppModel
    var onSurface:(ProductMode)->Void = {_ in}
    var tutorControllerFactory:((TutorFocus)->TutorSessionController)? = nil
    var phonicsControllerFactory:((JSONValue)->PhonicsCourseController)? = nil
    @State private var routed:JSONValue?
    @State private var failure:String?
    @State private var request=UUID()
    @State private var tutorFinishing=false
    @State private var phonicsFinishing=false
    @State private var unavailablePhonicsScope:String?
    private var next:String? {app.readyGoal.flatMap(GoalPractice.nextMode)}
    private var preserveEarnedWork:Bool {if tutorFinishing || phonicsFinishing || app.hasPendingFocusedTutorCompletion{return true};guard let routed,routed["mode"].string == "lesson",let lesson=try? app.sourceGoalLesson(routed) else{return false};return app.preserveEarnedGoalLesson(lesson)}
    var body:some View {
        SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:preserveEarnedWork){content}
            .task(id:app.goalPreparationKey+request.uuidString){await prepare()}
            .onChange(of:next){_,value in if let value {route(value)}}
    }
    @ViewBuilder private var content:some View {
        if let routed,app.goalIsCurrent(routed) {activity(routed).id(routed["goalId"].string+":"+routed["dayKey"].string+":"+routed["mode"].string+":"+app.learner.support)}
        else if let failure {
            VStack(spacing:16){Text(failure).multilineTextAlignment(.center).accessibilityIdentifier("goalPreparationError");Button(app.goalCompletionText("retry")){request=UUID()}.buttonStyle(EntryButtonStyle()).accessibilityIdentifier("retryGoalPreparation")}.padding(24)
        }else{ProgressView(EntryCopy.ui(app.learner.support,"generic_loading")).frame(maxWidth:.infinity,maxHeight:.infinity).accessibilityIdentifier("preparingGoalCourse")}
    }
    @ViewBuilder private func activity(_ blueprint:JSONValue)->some View {
        switch blueprint["mode"].string {
        case "lesson":if let lesson=try? app.sourceGoalLesson(blueprint){LessonView(lesson:lesson)}
        case "flashcards":FlashcardsView(goalBlueprint:blueprint)
        case "phonics":if app.focusedTutorRun(.goal(blueprint)) != nil || app.authoredGoalPhonics(blueprint).isEmpty || unavailablePhonicsScope == phonicsScope(blueprint) {focusedTutor(blueprint)}else{PhonicsView(goalBlueprint:blueprint,controller:phonicsControllerFactory?(blueprint),onEarnedWorkChanged:{phonicsFinishing=$0},onFocusedPracticeUnavailable:{phonicsUnavailable(blueprint)})}
        default:focusedTutor(blueprint)
        }
    }
    private func phonicsScope(_ blueprint:JSONValue)->String {[app.identity.sessionRevision.uuidString,app.identity.npub,app.learner.target,app.learner.support,blueprint.canonicalJSON].joined(separator:":")}
    private func phonicsUnavailable(_ blueprint:JSONValue){guard routed == blueprint,next == "phonics",app.goalIsCurrent(blueprint) else{return};let scope=phonicsScope(blueprint);guard unavailablePhonicsScope != scope else{return};unavailablePhonicsScope=scope;onSurface(.tutor)}
    private func focusedTutor(_ blueprint:JSONValue)->some View {SourceTutorView(controller:tutorControllerFactory?(.goal(blueprint)),focus:.goal(blueprint),onCompletionPending:{tutorFinishing=$0})}
    private func prepare() async {
        let scope=app.goalCourseScope;failure=nil
        do {
            if app.readyGoal == nil || app.readyGoal.map(GoalPractice.needsBundleUpgrade) == true {try await app.prepareGoal()}
            try Task.checkCancellation();guard app.goalCourseScope == scope else{return}
            if let next {route(next)}
        }catch is CancellationError{}catch{if app.goalCourseScope == scope {failure=error.localizedDescription}}
    }
    private func route(_ mode:String) {
        guard let daily=app.readyGoal else{return}
        let blueprint=daily["blueprint"].setting("mode",.string(mode))
        guard routed != blueprint else{return}
        tutorFinishing=false;phonicsFinishing=false;routed=blueprint
        onSurface(mode == "lesson" ? .path:mode == "flashcards" ? .cards:mode == "phonics" && app.focusedTutorRun(.goal(blueprint)) == nil && !app.authoredGoalPhonics(blueprint).isEmpty ? .phonics:.tutor)
    }
}
