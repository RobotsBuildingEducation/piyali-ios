import SwiftUI
struct LiveTutorView: View {
    @EnvironmentObject var app: AppModel
    var goalBlueprint: JSONValue? = nil
    var goalMode = "tutor"
    var plateKind: String? = nil
    var tutorLesson: Lesson? = nil
    @State private var checkedTurn = 0
    @State private var tutorFeedback: String?
    @State private var checking = false
    @State private var verdict: GoalVerdict?
    @State private var checkError: String?
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var live = LiveTutorService()
    var body: some View {
        SubscriptionRequiredView(service: app.subscription) {
            List {
                Section {
                    Text("Speak naturally with your tutor. Microphone audio is sent to Firebase Gemini during this session.")
                    Button(live.connected ? "End voice session" : "Start voice session") {
                        Task {
                            if live.connected { await live.stop() }
                            else {
                                let account = app.identity.npub, learner = app.learner
                                await live.start(learner:learner,goalBlueprint:goalBlueprint,tutorLesson:tutorLesson,onLearnerTurn:plateKind == "conversation" ? { text in
                                    guard app.identity.npub == account, app.learner.target == learner.target, app.subscription.hasAccess else { return }
                                    app.recordConversationTurn(text)
                                } : nil)
                            }
                        }
                    }.disabled(live.connecting || (goalBlueprint.map { !app.goalIsCurrent($0) } ?? false))
                    if live.connecting { ProgressView("Connecting…") }
                    if live.connected { Text("Microphone active") }
                    if let error = live.error { Text(error).foregroundStyle(.red) }
                }
                if let tutorLesson {
                    Section("Tutor lesson") {
                        Text(tutorLesson.title.localized(app.learner.support))
                        if let item = app.learner.nextTutorItem(tutorLesson) { Text(item["label"].localized(app.learner.support)) }
                        let progress = app.learner.tutorProgress(tutorLesson.id)
                        Text("\(progress.earnedXP) / \(TutorCourse.requiredXP(tutorLesson.id)) practice XP · \(progress.items.count) / \(TutorCourse.agenda(tutorLesson).count) agenda tasks")
                        Button("Check my latest response") { checkTutor(tutorLesson) }.disabled(checking || live.learnerTurnNumber <= checkedTurn || app.learner.completed.contains(app.learner.tutorKey(tutorLesson.id)))
                        Button("Continue with current tutor task") { Task { await live.stop(); await live.start(learner:app.learner,tutorLesson:tutorLesson) } }.disabled(checking || live.connecting)
                        if let tutorFeedback { Text(tutorFeedback) }
                        if let checkError { Text(checkError).foregroundStyle(.red) }
                        if app.learner.completed.contains(app.learner.tutorKey(tutorLesson.id)) { Text("Tutor lesson complete") }
                    }
                }
                if let goalBlueprint {
                    Section("Daily goal") {
                        Text(goalBlueprint["objective"].string)
                        Button("Check my goal attempt") {
                            checking = true; checkError = nil
                            Task { defer { checking = false }; do { verdict = try await app.checkGoal(goalBlueprint,mode:goalMode,response:live.learnerTranscript,context:live.transcript) } catch { checkError = error.localizedDescription } }
                        }.disabled(checking || live.learnerTranscript.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                        if let verdict { Text(verdict.feedback) }
                        if let checkError { Text(checkError).foregroundStyle(.red) }
                    }
                }
                Section("Transcript") { Text(live.transcript.isEmpty ? "The conversation will appear here." : live.transcript).textSelection(.enabled) }
                if !live.transcript.isEmpty {
                    Button("Save conversation to notes") { app.learner.notes.insert(Note(title: "Voice tutor · \(app.learner.target)", body: live.transcript), at: 0); app.persist() }
                }
            }
        }.navigationTitle("Live voice tutor")
            .onChange(of:live.connected) { _,connected in if connected { checkedTurn = live.learnerTurnNumber } }
            .onDisappear { Task { await live.stop() } }
            .onChange(of: scenePhase) { _, phase in if phase != .active { Task { await live.stop() } } }
            .onChange(of:goalBlueprint.map { app.goalIsCurrent($0) } ?? true) { _,valid in if !valid { Task { await live.stop() } } }
            .onChange(of:app.learner.target) { _,_ in Task { await live.stop() } }
            .onChange(of:app.identity.npub) { _,_ in Task { await live.stop() } }
            .onChange(of: app.subscription.authorized) { _, allowed in if !allowed { Task { await live.stop() } } }
    }
    func checkTutor(_ lesson: Lesson) {
        guard app.subscription.hasAccess, !checking else { return }
        checking = true; checkError = nil
        let before = checkedTurn
        let response = live.completedLearnerTurn, context = live.transcript
        checkedTurn = live.learnerTurnNumber
        let account = app.identity.npub, learner = app.learner
        let item = learner.nextTutorItem(lesson) ?? TutorCourse.agenda(lesson).first!
        Task {
            defer { checking = false }
            do {
                let verdict = try await app.ai.tutorVerdict(lesson:lesson,item:item,learner:learner,response:response,context:context)
                guard app.identity.npub == account, app.learner.target == learner.target, app.learner.tutorLevel == learner.tutorLevel else { return }
                let earned = app.recordTutorTurn(lesson:lesson,item:item,answer:response,verdict:verdict)
                tutorFeedback = verdict.reason + (earned > 0 ? " · +\(earned) XP" : "")
            } catch { checkedTurn = before; checkError = error.localizedDescription }
        }
    }

}
