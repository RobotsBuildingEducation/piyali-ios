import SwiftUI

struct TutorMessage: Identifiable { let id = UUID(); let role: String; let text: String }
struct TutorView: View {
    @EnvironmentObject var app: AppModel
    @StateObject private var speech = SpeechService()
    @State private var messages: [TutorMessage] = []
    @State private var input = ""
    @State private var busy = false
    @State private var error: String?
    @State private var speakReplies = true
    var body: some View {
        SubscriptionRequiredView(service: app.subscription) {
            VStack {
                List {
                    NavigationLink("Live voice conversation") { LiveTutorView() }
                    ForEach(messages) { message in
                        VStack(alignment: .leading) {
                            Text(message.role == "user" ? "You" : "Piyali").font(.caption).foregroundStyle(.secondary)
                            Text(message.text).textSelection(.enabled)
                            if message.role == "assistant" { Button("Listen") { speech.speak(message.text, language: app.learner.target) } }
                        }
                    }
                    if busy { ProgressView("Tutor is replying…") }
                    if let error { Text(error).foregroundStyle(.red) }
                    if let error = speech.error { Text(error).foregroundStyle(.red) }
                }
                Toggle("Read replies aloud", isOn: $speakReplies).padding(.horizontal)
                HStack {
                    TextField("Message your tutor", text: $input, axis: .vertical).textFieldStyle(.roundedBorder)
                    Button { if speech.recording { speech.stop() } else { Task { await speech.start(language: app.learner.target) } } } label: { Image(systemName: speech.recording ? "stop.circle" : "mic") }.accessibilityLabel("Microphone")
                    Button("Send") { send() }.disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || busy)
                }.padding()
            }
        }.navigationTitle("Tutor")
            .toolbar { Button("New conversation") { messages = []; speech.stopAll() }.disabled(busy) }
            .onChange(of: speech.transcript) { _, text in input = text }
            .onDisappear { speech.stopAll() }
    }
    func send() {
        guard app.subscription.hasAccess else { return }
        speech.stop(); let text = input; input = ""; error = nil; busy = true
        messages.append(TutorMessage(role: "user", text: text))
        let history = messages.suffix(20).map { ["role":$0.role,"content":$0.text] }
        Task {
            defer { busy = false }
            do {
                let transcript = String(decoding: try JSONSerialization.data(withJSONObject: history), as: UTF8.self)
                let reply = try await app.ai.text("You are Piyali, a patient language tutor. Teach \(LearningLanguages.names[app.learner.target] ?? app.learner.target) at \(app.learner.level). Give explanations in \(LearningLanguages.names[app.learner.support] ?? app.learner.support). Goal: \(app.learner.goal). Keep replies brief, correct errors kindly, and ask one natural follow-up. Use the target language for practice. Conversation data: \(transcript)")
                messages.append(TutorMessage(role: "assistant", text: reply))
                if speakReplies { speech.speak(reply, language: app.learner.target) }
            } catch { self.error = error.localizedDescription }
        }
    }
}
