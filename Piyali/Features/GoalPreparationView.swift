import SwiftUI

struct GoalPreparationView: View {
    @EnvironmentObject var app: AppModel
    let mode: String
    let blueprint: JSONValue
    @StateObject private var speech = SpeechService()
    @State private var index = 0
    @State private var answer = ""
    @State private var feedback: String?
    @State private var error: String?
    @State private var busy = false
    @State private var revealed = false
    @State private var checked = false
    var artifact: JSONValue { app.goalArtifact(blueprint,mode:mode) }
    var cards: [JSONValue] { artifact["cards"].array }
    var body: some View {
        SubscriptionRequiredView(service:app.subscription) {
            VStack(spacing:0){GoalFocusBanner(blueprint:blueprint)
            Form {
                if !app.goalIsCurrent(blueprint) { Text("This task has changed. Return to today's goal.") }
                else if artifact["requiresTutor"].boolean {
                    Text("This goal needs a practical conversation. Its words aren't in the authored pronunciation collection.")
                    NavigationLink("Practice the goal with your tutor") { SourceTutorView(focus:.goal(blueprint.setting("mode",.string(mode)))) }
                } else if mode == "flashcards", cards.contains(where:{ $0["concept"][app.learner.support == app.learner.target ? "iosCue" : app.learner.support].string.isEmpty }) {
                    Text("These saved preparation cues use your previous support language. Continue this goal with your tutor in your current language.")
                    NavigationLink("Practice with current language support") { SourceTutorView(focus:.goal(blueprint.setting("mode",.string(mode)))) }
                } else if cards.indices.contains(index) {
                    let card = cards[index]
                    let expected = mode == "phonics" ? card["practiceWord"].string : card["concept"][app.learner.target].string
                    Section("Preparation \(index + 1) / \(cards.count)") {
                        if mode == "phonics" { Text(card["letter"].string); Text(card["tip"].string); Text(expected) }
                        else { Text(card["concept"][app.learner.support == app.learner.target ? "iosCue" : app.learner.support].string) }
                        Button("Listen to model") { speech.speak(expected,language:app.learner.target) }
                        if mode == "flashcards" { Button("Reveal answer") { revealed = true; feedback = expected } }
                        TextField(mode == "phonics" ? "Practice word" : "Your translation",text:$answer,axis:.vertical).autocorrectionDisabled().disabled(mode == "phonics")
                        Button(speech.recording ? "Stop recording" : "Answer aloud") { if speech.recording { speech.stop() } else { Task { await speech.start(language:app.learner.target) } } }
                        Button("Check preparation") {
                            speech.stop(); checked = true
                            let success = !revealed && AnswerMatcher.matches(mode == "phonics" ? speech.transcript : answer,expected)
                            app.recordGoalPreparation(blueprint,mode:mode,card:card,success:success,answer:answer)
                            feedback = success ? "Correct preparation. This does not demonstrate independent communication." : "Try again: " + expected
                        }.disabled(answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || busy || revealed || checked)
                        if let feedback { Text(feedback) }
                        if artifact["outcomes"][card["id"].string]["success"].boolean { Label("Preparation saved",systemImage:"checkmark") }
                        Button("Next preparation card") { index = (index + 1) % max(1,cards.count); answer = ""; feedback = nil; revealed = false; checked = false; speech.stopAll(); speech.transcript = "" }
                        Button("Try without the answer") { answer = ""; feedback = nil; revealed = false; checked = false; speech.transcript = "" }
                    }

                }
                if busy { ProgressView("Preparing practice…") }
                if let error { Text(error).foregroundStyle(.red); Button("Retry") { prepare() } }
                if let error = speech.error { Text(error).foregroundStyle(.red) }
            }
        }}.navigationTitle(app.goalText("title"))
            .task { prepare() }
            .onChange(of:speech.transcript) { _,text in answer = text }
            .onDisappear { speech.stopAll() }
    }
    func prepare() {
        busy = true; error = nil
        Task { defer { busy = false }; do { try await app.prepareGoalDeck(blueprint,mode:mode) } catch { self.error = error.localizedDescription } }
    }
}
