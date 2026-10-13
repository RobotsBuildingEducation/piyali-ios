import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        List {
            Section("Today") {
                Text(app.learner.goal)
                ProgressView(value: Double(min(app.learner.dailyXP, app.learner.dailyGoal)), total: Double(max(1, app.learner.dailyGoal)))
                Text("\(app.learner.dailyXP) / \(app.learner.dailyGoal) daily XP · \(app.learner.streak) day streak")
                Text("Score: \(app.learner.score)/100 · \(PerformanceScore.level(score: app.learner.score)) practice")
                NavigationLink("Focused learning goal") { FocusedGoalView() }
                NavigationLink("Repair mistakes") { RepairPracticeView() }
                Text("\(app.learner.companionName) · Level \(app.learner.companionLevel) · \(app.learner.xp) language XP")
                NavigationLink("Daily practice plate") { DailyPlateView() }
                if let lesson = app.selectedLesson { NavigationLink("Continue: " + lesson.title.localized(app.learner.support)) { LessonView(lesson: lesson) } }
            }
            Section("Learning path") {
                Picker("CEFR level", selection: $app.learner.level) { ForEach(LearningLanguages.levels, id: \.self) { Text($0).tag($0) } }
                if app.loadingContent { ProgressView("Loading curriculum…") }
                ForEach(app.units) { unit in
                    DisclosureGroup(unit.title.localized(app.learner.support)) {
                        Text(unit.description.localized(app.learner.support)).font(.footnote)
                        ForEach(unit.lessons) { lesson in
                            NavigationLink { LessonView(lesson: lesson) } label: {
                                HStack {
                                    Text(lesson.title.localized(app.learner.support))
                                    Spacer()
                                    if app.learner.completed.contains(app.learner.completionKey(lesson.id)) { Image(systemName: "checkmark.circle.fill") }
                                }
                            }
                        }
                    }
                }
            }
            Section { NavigationLink("Subscription") { SubscriptionView(service: app.subscription) } }
        }.navigationTitle("Piyali")
            .onChange(of: app.learner.level) { _, _ in app.persist(); Task { await app.reloadContent() } }
    }
}
struct DailyPlateView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        List {
            Text("Work on today's lesson across each skill. Correct answers earn XP and feed your companion.")
            ForEach([PracticeMode.vocabulary,.grammar,.reading,.listening,.speaking,.stories]) { mode in
                NavigationLink(mode.rawValue) { ExerciseView(mode: mode, lesson: app.selectedLesson) }
            }
            NavigationLink("Phonics") { PhonicsView() }
        }.navigationTitle("Daily plate")
    }
}
struct LessonView: View {
    @EnvironmentObject var app: AppModel
    let lesson: Lesson
    var body: some View {
        List {
            Section("Lesson") {
                Text(lesson.description.localized(app.learner.support))
                ForEach(Array(lesson.agenda["items"].array.enumerated()), id: \.offset) { _, item in
                    let goal = item["goal"].localized(app.learner.support)
                    if !goal.isEmpty { Text(goal) }
                }
            }
            Section("Practice each skill") {
                ForEach(AppModel.modes(for: lesson)) { mode in
                    NavigationLink { ExerciseView(mode: mode, lesson: lesson) } label: {
                        HStack {
                            Text(mode.rawValue); Spacer()
                            if app.learner.practicedModes.contains(app.learner.modeKey(lesson.id, mode.rawValue)) { Image(systemName: "checkmark") }
                        }
                    }
                }
                Button("Complete lesson (+\(lesson.xpReward) XP)") { app.complete(lesson) }
                    .disabled(!app.canComplete(lesson) || app.learner.completed.contains(app.learner.completionKey(lesson.id)))
                Text("Complete a correct exercise in every listed skill to finish this lesson.").font(.footnote)
            }
        }.navigationTitle(lesson.title.localized(app.learner.support))
    }
}
struct PracticeLibraryView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        List {
            Section("Authored content") {
                NavigationLink("Flashcards (\(app.cards.count))") { FlashcardsView() }
                NavigationLink("Phonics (\(app.phonics.count))") { PhonicsView() }
            }
            Section("Practice modes") {
                ForEach(PracticeMode.allCases) { mode in NavigationLink(mode.rawValue) { ExerciseView(mode: mode, lesson: app.selectedLesson) } }
                NavigationLink("Grammar reference") { GrammarReferenceView() }
                NavigationLink("Real-world task") { RealWorldTaskView() }
            }
        }.navigationTitle("Practice")
    }
}
struct FlashcardsView: View {
    @EnvironmentObject var app: AppModel
    @State private var index = 0
    @State private var answer = ""
    @State private var feedback: String?
    @State private var revealed = false
    @State private var graded = false
    @StateObject private var speech = SpeechService()
    var card: Flashcard? { app.cards.isEmpty ? nil : app.cards[index % app.cards.count] }
    var body: some View {
        Form {
            if let card {
                Section("\(card.cefrLevel) · \(card.category)") {
                    Text(card.text(app.learner.support)).font(.title2)
                    Text("Translate into \(LearningLanguages.names[app.learner.target] ?? app.learner.target).")
                    TextField("Your translation", text: $answer).autocorrectionDisabled()
                    if let target = card.concept[app.learner.target] {
                        Button("Check answer") {
                            let correct = AnswerMatcher.matches(answer, target)
                            app.learner.assess(correct: correct, independent: true)
                            feedback = correct ? "Correct! +10 XP" : "Answer: \(target)"
                            if !graded && correct && !revealed && !app.learner.flashcardMastery.contains(app.learner.target + ":" + card.id) { app.learner.award(10); app.learner.flashcardMastery.insert(app.learner.target + ":" + card.id); app.persist() }
                            graded = true; app.persist()
                        }.disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty || graded)
                        Button("Reveal answer") { revealed = true; feedback = target }
                        Button("Listen") { speech.speak(target, language: app.learner.target) }
                    } else {
                        NavigationLink("Practice with the tutor") { ExerciseView(mode: .vocabulary, lesson: app.selectedLesson, concept: card.text(app.learner.support), flashcardID: card.id) }
                    }
                    if let feedback { Text(feedback).accessibilityIdentifier("flashcardFeedback") }
                    Button("Next card") { index += 1; answer = ""; feedback = nil; revealed = false; graded = false }.accessibilityIdentifier("nextFlashcard")
                }
                Text("Card \(index % max(1, app.cards.count) + 1) of \(app.cards.count)")
            } else { Text("No flashcards at this level. Choose another CEFR level in Learn.") }
        }.navigationTitle("Flashcards").onDisappear { speech.stopAll() }
    }
}
struct PhonicsView: View {
    @EnvironmentObject var app: AppModel
    @StateObject private var speech = SpeechService()
    @State private var active: String?
    var body: some View {
        List {
            ForEach(app.phonics) { card in
                DisclosureGroup(card.letter + " · " + card.practiceWord) {
                    Text(card.sound); Text(card.tip)
                    if let meaning = card.practiceWordMeaning[app.learner.support] { Text(meaning) }
                    Button("Listen") { speech.speak(card.tts, language: app.learner.target) }
                    Button(speech.recording && active == card.id ? "Stop recording" : "Practice pronunciation") {
                        active = card.id
                        if speech.recording { speech.stop() } else { Task { await speech.start(language: app.learner.target) } }
                    }
                    if active == card.id, !speech.transcript.isEmpty {
                        Text("You said: \(speech.transcript)")
                        Button("Check pronunciation words") {
                            if AnswerMatcher.matches(speech.transcript, card.practiceWord) {
                                if app.learner.masteredPhonics == nil { app.learner.masteredPhonics = [] }
                                if app.learner.masteredPhonics?.insert(card.id).inserted == true { app.learner.award(5); app.persist() }
                            } else { speech.error = "Try again: " + card.practiceWord }
                        }
                    }
                }
            }
            if app.phonics.isEmpty { Text("Phonics content is unavailable for this language pair.") }
            if let error = speech.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Phonics").onDisappear { speech.stopAll() }
    }
}
