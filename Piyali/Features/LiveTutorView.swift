import SwiftUI
struct LiveTutorView: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var live = LiveTutorService()
    var body: some View {
        SubscriptionRequiredView(service: app.subscription) {
            List {
                Section {
                    Text("Speak naturally with your tutor. Microphone audio is sent to Firebase Gemini during this session.")
                    Button(live.connected ? "End voice session" : "Start voice session") {
                        Task { if live.connected { await live.stop() } else { await live.start(learner: app.learner) } }
                    }.disabled(live.connecting)
                    if live.connecting { ProgressView("Connecting…") }
                    if live.connected { Text("Microphone active") }
                    if let error = live.error { Text(error).foregroundStyle(.red) }
                }
                Section("Transcript") { Text(live.transcript.isEmpty ? "The conversation will appear here." : live.transcript).textSelection(.enabled) }
                if !live.transcript.isEmpty {
                    Button("Save conversation to notes") { app.learner.notes.insert(Note(title: "Voice tutor · \(app.learner.target)", body: live.transcript), at: 0); app.persist() }
                }
            }
        }.navigationTitle("Live voice tutor")
            .onDisappear { Task { await live.stop() } }
            .onChange(of: scenePhase) { _, phase in if phase != .active { Task { await live.stop() } } }
            .onChange(of: app.subscription.authorized) { _, allowed in if !allowed { Task { await live.stop() } } }
    }
}
