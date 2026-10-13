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
    @State private var currentID: String?
    @State private var dueOnly = false
    @State private var answer = ""
    @State private var feedback: String?
    @State private var revealed = false
    @State private var checked = false
    @State private var rated = false
    @State private var correct = false
    @StateObject private var speech = SpeechService()
    var card: Flashcard? { app.cards.first { $0.id == currentID } }
    var available: [Flashcard] {
        app.cards.filter { card in
            let review = app.learner.cardReviews?[app.learner.completionKey(card.id)]
            return !dueOnly || review == nil || review?.schedulerState == .new || review?.isDue() == true
        }.sorted { left,right in
            let a = app.learner.cardReviews?[app.learner.completionKey(left.id)]
            let b = app.learner.cardReviews?[app.learner.completionKey(right.id)]
            if a?.isDue() != b?.isDue() { return a?.isDue() == true }
            return (a?.nextReviewAt ?? .distantFuture) < (b?.nextReviewAt ?? .distantFuture)
        }
    }
    var body: some View {
        Form {
            Toggle("Due and new cards only",isOn:$dueOnly)
            if let card {
                Section("\(card.cefrLevel) · \(card.category)") {
                    Text(card.text(app.learner.support)).font(.title2).accessibilityIdentifier("flashcardPrompt")
                    Text("Translate into \(LearningLanguages.names[app.learner.target] ?? app.learner.target).")
                    TextField("Your translation",text:$answer).autocorrectionDisabled().disabled(checked || revealed)
                    if let target = card.concept[app.learner.target] {
                        Button("Check answer") {
                            correct = AnswerMatcher.matches(answer,target); checked = true
                            feedback = correct ? "Correct! Choose how easily you remembered it." : "Answer: \(target). Review again soon."
                            if !correct { app.reviewFlashcard(card,rating:.again,correct:false); rated = true }
                        }.disabled(answer.trimmingCharacters(in:.whitespaces).isEmpty || checked || revealed)
                        Button("Reveal answer") { revealed = true; feedback = target; app.reviewFlashcard(card,rating:.again,correct:nil); rated = true }.disabled(checked || revealed)
                        Button("Listen") { speech.speak(target,language:app.learner.target) }
                        if checked && correct && !rated {
                            ForEach([ReviewRating.hard,.good,.easy],id:\.self) { rating in
                                Button("\(rating.rawValue.capitalized) · next \(reviewDelay(card,rating:rating))") {
                                    app.reviewFlashcard(card,rating:rating,correct:true); rated = true
                                    feedback = "Saved review · +\(rating == .hard ? 4 : rating == .easy ? 7 : 5) XP"
                                }
                            }
                        }
                    } else {
                        NavigationLink("Practice with the tutor") { ExerciseView(mode:.vocabulary,lesson:app.selectedLesson,concept:card.text(app.learner.support),flashcardID:card.id) }
                    }
                    if let feedback { Text(feedback).accessibilityIdentifier("flashcardFeedback") }
                    if let next = app.learner.cardReviews?[app.learner.completionKey(card.id)]?.nextReviewAt { Text("Next review: " + next.formatted(date:.abbreviated,time:.shortened)).font(.footnote).accessibilityIdentifier("nextReview") }
                    Button("Next card") { selectNext(after:card.id) }.accessibilityIdentifier("nextFlashcard").disabled(checked && correct && !rated)
                }
                Text("\(available.count) cards available · \(app.cards.count) in this level")
            } else {
                Text(dueOnly ? "No reviews are due at this level. Come back when the next review is scheduled, or browse all cards." : "No flashcards at this level. Choose another CEFR level in Learn.")
            }
        }.navigationTitle("Flashcards")
            .onAppear { if currentID == nil { selectNext(after:nil) } }
            .onChange(of:dueOnly) { _,_ in selectNext(after:nil) }
            .onChange(of:app.cards.count) { _,_ in selectNext(after:nil) }
            .onDisappear { speech.stopAll() }
    }
    func selectNext(after id: String?) {
        let queue = available
        if let id, let index = queue.firstIndex(where:{ $0.id == id }), !queue.isEmpty { currentID = queue[(index + 1) % queue.count].id }
        else { currentID = queue.first?.id }
        answer = ""; feedback = nil; revealed = false; checked = false; rated = false; correct = false
    }
    func reviewDelay(_ card: Flashcard, rating: ReviewRating) -> String {
        let now = Date(), review = app.learner.cardReviews?[app.learner.completionKey(card.id)] ?? FlashcardReview()
        let seconds = (review.applying(rating,now:now).nextReviewAt ?? now).timeIntervalSince(now)
        return seconds < 3600 ? "\(Int((seconds/60).rounded()))m" : seconds < 86400 ? "\(Int((seconds/3600).rounded()))h" : "\(Int((seconds/86400).rounded()))d"
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
                                if app.learner.masteredPhonics?.insert(card.id).inserted == true { app.learner.award(5,source:.phonics,contentID:card.id); app.persist() }
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
