import SwiftUI
struct LiveTutorView: View {
    @EnvironmentObject var app: AppModel
    var goalBlueprint: JSONValue? = nil
    var goalMode = "tutor"
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
                        Task { if live.connected { await live.stop() } else { await live.start(learner: app.learner,goalBlueprint:goalBlueprint) } }
                    }.disabled(live.connecting || (goalBlueprint.map { !app.goalIsCurrent($0) } ?? false))
                    if live.connecting { ProgressView("Connecting…") }
                    if live.connected { Text("Microphone active") }
                    if let error = live.error { Text(error).foregroundStyle(.red) }
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
            .onDisappear { Task { await live.stop() } }
            .onChange(of: scenePhase) { _, phase in if phase != .active { Task { await live.stop() } } }
            .onChange(of:goalBlueprint.map { app.goalIsCurrent($0) } ?? true) { _,valid in if !valid { Task { await live.stop() } } }
            .onChange(of:app.learner.target) { _,_ in Task { await live.stop() } }
            .onChange(of:app.identity.npub) { _,_ in Task { await live.stop() } }
            .onChange(of: app.subscription.authorized) { _, allowed in if !allowed { Task { await live.stop() } } }
    }
}
