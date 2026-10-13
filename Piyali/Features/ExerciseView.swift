import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject var app: AppModel
    @StateObject private var speech = SpeechService()
    let mode: PracticeMode
    let lesson: Lesson?
    var concept: String? = nil
    var flashcardID: String? = nil
    @State private var exercise: Exercise?
    @State private var grade: Grade?
    @State private var answer = ""
    @State private var error: String?
    @State private var busy = false
    @State private var showPassage = false
    var body: some View {
        SubscriptionRequiredView(service: app.subscription) {
            Form {
                if let exercise {
                    Section(mode.rawValue) {
                        if mode != .listening || showPassage { if !exercise.passage.isEmpty { Text(exercise.passage).textSelection(.enabled) } }
                        if !exercise.passage.isEmpty { Button("Listen") { speech.speak(exercise.passage, language: app.learner.target) } }
                        if mode == .listening { Button(showPassage ? "Hide transcript" : "Show transcript") { showPassage.toggle() } }
                        Text(exercise.question).font(.headline)
                        ForEach(Array(exercise.choices.enumerated()), id: \.offset) { _, choice in
                            Button { answer = choice } label: { HStack { Text(choice); Spacer(); if answer == choice { Image(systemName: "checkmark") } } }.disabled(grade != nil)
                        }
                        if exercise.choices.isEmpty {
                            TextField("Your answer", text: $answer, axis: .vertical).disabled(grade != nil)
                            Button(speech.recording ? "Stop microphone" : "Answer aloud") { if speech.recording { speech.stop() } else { Task { await speech.start(language: app.learner.target) } } }.disabled(grade != nil)
                        }
                        Button("Check answer") { submit(exercise) }.disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || busy || grade != nil)
                    }
                    if let grade {
                        Section(grade.correct ? "Correct · +10 XP" : "Try this") {
                            Text(grade.feedback); Text(grade.correctedAnswer)
                            Button("Save to notes") {
                                app.learner.notes.insert(Note(title: exercise.question, body: exercise.passage + "\n" + grade.correctedAnswer + "\n" + grade.feedback), at: 0); app.persist()
                            }
                            Button("Next exercise") { Task { await generate() } }
                        }
                    }
                } else if !busy { Button("Start practice") { Task { await generate() } } }
                if busy { ProgressView("Working…") }
                if let error { Section { Text(error).foregroundStyle(.red); Button("Try again") { Task { await generate() } } } }
                if let error = speech.error { Text(error).foregroundStyle(.red) }
            }
        }.navigationTitle(mode.rawValue)
            .task { if app.subscription.hasAccess { await generate() } }
            .onChange(of: speech.transcript) { _, text in if grade == nil { answer = text } }
            .onDisappear { speech.stopAll() }
    }
    func generate() async {
        guard app.subscription.hasAccess else { return }
        busy = true; error = nil; grade = nil; answer = ""; speech.stopAll(); showPassage = false
        defer { busy = false }
        do { exercise = try await app.ai.exercise(mode: mode, lesson: lesson, learner: app.learner, concept: concept) }
        catch { self.error = error.localizedDescription }
    }
    func submit(_ exercise: Exercise) {
        guard app.subscription.hasAccess, grade == nil else { return }
        let account = app.identity.npub, target = app.learner.target
        speech.stop(); busy = true; error = nil
        Task {
            defer { busy = false }
            do {
                let grade = try await app.ai.grade(exercise: exercise, answer: answer, learner: app.learner)
                guard app.identity.npub == account, app.learner.target == target, !Task.isCancelled else { return }
                self.grade = grade
                app.record(exercise: exercise, answer: answer, grade: grade, mode: mode, lesson: lesson, flashcardID: flashcardID)
            } catch { self.error = error.localizedDescription }
        }
    }
}
struct SubscriptionRequiredView<Content: View>: View {
    @ObservedObject var service: SubscriptionService
    @ViewBuilder var content: () -> Content
    var body: some View { if service.authorized { content() } else { SubscriptionView(service: service) } }
}
struct GrammarReferenceView: View {
    @EnvironmentObject var app: AppModel
    @State var text = ""
    @State var busy = false
    @State var error: String?
    var body: some View {
        SubscriptionRequiredView(service: app.subscription) {
            List {
                if busy { ProgressView("Preparing grammar notes…") }
                Text(text).textSelection(.enabled)
                if let error { Text(error) }
                Button("Generate grammar guide") {
                    busy = true
                    Task {
                        defer { busy = false }
                        do { text = try await app.ai.text("Explain the grammar for \(app.learner.level) \(LearningLanguages.names[app.learner.target] ?? app.learner.target) in \(LearningLanguages.names[app.learner.support] ?? app.learner.support), with clear examples. Focus on this authored lesson: \(app.selectedLesson?.agenda.json ?? app.learner.goal)") }
                        catch { self.error = error.localizedDescription }
                    }
                }.disabled(busy)
                if !text.isEmpty { Button("Save guide to notes") { app.learner.notes.insert(Note(title: "Grammar · \(app.learner.level)", body: text), at: 0); app.persist() } }
            }
        }.navigationTitle("Grammar reference")
    }
}
struct RealWorldTaskView: View {
    @EnvironmentObject var app: AppModel
    @State private var taskText = ""
    @State private var reflection = ""
    @State private var error: String?
    @State private var busy = false
    var body: some View {
        SubscriptionRequiredView(service: app.subscription) {
            Form {
                Text(taskText.isEmpty ? "Get a practical task to use your language outside the app." : taskText)
                Button("Generate a task") {
                    busy = true
                    Task {
                        defer { busy = false }
                        do { taskText = try await app.ai.text("Give one safe everyday real-world task for a \(app.learner.level) learner of \(LearningLanguages.names[app.learner.target] ?? app.learner.target). Goal: \(app.learner.goal). Instructions in \(LearningLanguages.names[app.learner.support] ?? app.learner.support). Include a useful target-language phrase and a reflection prompt.") }
                        catch { self.error = error.localizedDescription }
                    }
                }.disabled(busy)
                if !taskText.isEmpty {
                    TextField("What happened?", text: $reflection, axis: .vertical)
                    Button("Complete task and save reflection") {
                        app.learner.notes.insert(Note(title: "Real-world practice", body: taskText + "\n" + reflection), at: 0)
                        app.learner.rollDay()
                        let key = app.learner.target + ":" + app.learner.dailyKey
                        if app.learner.immersionDays == nil { app.learner.immersionDays = [] }
                        if app.learner.immersionDays?.insert(key).inserted == true { app.learner.award(10,source:.immersion) }
                        app.persist(); reflection = ""
                    }.disabled(reflection.isEmpty)
                }
                if busy { ProgressView() }
                if let error { Text(error) }
            }
        }.navigationTitle("Real-world task")
    }
}
