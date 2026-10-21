import SwiftUI

struct ExerciseView: View {
    let mode:PracticeMode
    let lesson:Lesson?
    var concept:String?=nil
    var flashcardID:String?=nil
    var body:some View {
        if flashcardID == nil,let lesson,lesson.isFinalQuiz == true { FinalQuizView(lesson:lesson) }
        else if flashcardID == nil,mode == .conversation,let lesson { RealtimeLessonView(lesson:lesson) }
        else if flashcardID == nil,[.grammar,.vocabulary].contains(mode) { LessonPracticeView(module:mode == .grammar ? .grammar : .vocabulary,lesson:lesson) }
        else { LegacyExerciseView(mode:mode,lesson:lesson,concept:concept,flashcardID:flashcardID) }
    }
}
private struct LegacyExerciseView: View {
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
        let account = app.identity.npub, state = app.learner
        exercise = nil
        do {
            let generated = try await app.ai.exercise(mode:mode,lesson:lesson,learner:state,concept:concept)
            guard app.identity.npub == account, app.learner.target == state.target, app.learner.support == state.support, !Task.isCancelled else { return }
            exercise = generated
        }
        catch { self.error = error.localizedDescription }
    }
    func submit(_ exercise: Exercise) {
        guard app.subscription.hasAccess, grade == nil else { return }
        let account = app.identity.npub, target = app.learner.target
        speech.stop(); busy = true; error = nil
        Task {
            defer { busy = false }
            do {
                var state = app.learner
                if lesson?.id.hasPrefix("goal-") == true, let level = lesson?.agenda["cefrLevel"].string, LearningLanguages.levels.contains(level) { state.level = level }
                let grade = try await app.ai.grade(exercise: exercise, answer: answer, learner:state)
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
    var body: some View { if service.hasAccess { content() } else { SubscriptionView(service: service) } }
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
    private let milestones=(try? ContentLibrary.load([JSONValue].self,name:"score-milestones")) ?? []
    @State private var reflection = ""
    @State private var error: String?
    @State private var busy = false
    var body: some View {
        TimelineView(.periodic(from:.now,by:60)) { context in
            let state=app.learner.immersionState(now:context.date)
            Form {
                if app.learner.placements?[app.learner.target] == nil {
                    Text("Choose your starting level to create today's immersion missions.")
                    NavigationLink("Choose your starting level") { PlacementView() }
                } else {
                    Section("Today's immersion") {
                        Text("Three short missions outside the app, plus one for your active personal goal. Complete the whole checklist to earn 15 XP once per language per day.").font(.footnote)
                        ForEach(Array(state["tasks"].array.enumerated()),id:\.offset) { index,task in
                            Button { app.learner.toggleImmersion(index:index);app.persist() } label: {
                                HStack {
                                    VStack(alignment:.leading) { Text(task["title"].string);Text(task["description"].string).font(.footnote) }
                                    Spacer();Image(systemName:state["completed"].array[index].boolean ? "checkmark.circle.fill" : "circle")
                                }.contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityIdentifier("immersion-task-"+String(index)).accessibilityValue(state["completed"].array[index].boolean ? "Completed" : "Not completed").disabled(busy || state["status"].string != "ready")
                        }
                        if state["rewarded"].boolean { Text("Checklist reward saved · +15 XP").accessibilityIdentifier("immersionReward") }
                        if busy { ProgressView("Creating today's missions…") }
                        if let error { Text(error).foregroundStyle(.red) }
                        if state["status"].string != "ready" { Button("Retry today's missions") { Task { await generate() } }.disabled(busy) }
                        Text("Missions reset at your local midnight. Completed missions and their reward sync with your account.").font(.footnote)
                    }
                    if !state["tasks"].array.isEmpty {
                        Section("Private reflection") {
                            TextField("What happened?",text:$reflection,axis:.vertical)
                            Button("Save reflection") {
                                let summary=state["tasks"].array.map { $0["title"].string+": "+$0["description"].string }.joined(separator:"\n")
                                app.learner.notes.insert(Note(title:"Immersion reflection",body:summary+"\n"+reflection),at:0);app.persist();reflection=""
                            }.disabled(reflection.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                Section("Score") {
                    Text("\(LearningLanguages.names[app.learner.target] ?? app.learner.target): \(app.learner.score) / 100 · \(PerformanceScore.level(score:app.learner.score))")
                    DisclosureGroup("Capability landmarks") {
                        ForEach(Array(milestones.enumerated()),id:\.offset) { _,item in
                            HStack { Text("\(Int(item["score"].number)): \(item.localized(app.learner.support))");Spacer();if item["score"].number <= Double(app.learner.score) { Image(systemName:"checkmark.circle") } }
                        }
                    }
                }
            }.task(id:app.immersionPreparationKey) { await generate() }
        }.navigationTitle("Immersion & Score")
    }
    private func generate() async {
        guard !busy else { return };busy=true;error=nil
        defer { busy=false }
        do { try await app.prepareImmersion() } catch is CancellationError { } catch { self.error=error.localizedDescription }
    }
}
