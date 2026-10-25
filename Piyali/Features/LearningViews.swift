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
                Text("Companion health: \(app.learner.companionHealth)% · \(app.learner.companionStatus)").accessibilityIdentifier("companionHealth")
                Text("Reach your daily XP goal to recover 15% health. Each missed calendar day costs 10%.").font(.footnote)
                NavigationLink("Daily practice plate") { DailyPlateView() }
                NavigationLink("Immersion & Score") { RealWorldTaskView() }.accessibilityIdentifier("immersionLink")
                if let lesson = app.selectedLesson { NavigationLink("Continue: " + lesson.title.localized(app.learner.support)) { if lesson.id == IntroTutorial.lessonID { IntroTutorialView(lesson:lesson) } else { LessonView(lesson: lesson) } } }
                if let intro=app.introLesson { NavigationLink("Getting Started") { IntroTutorialView(lesson:intro) }.accessibilityIdentifier("introLink") }
            }
            Section("Learning path") {
                NavigationLink("Choose your starting level") { PlacementView() }
                Picker("Lesson level", selection: Binding(get: { app.learner.level }, set: { app.setLessonLevel($0) })) { ForEach(app.lessonLevels, id: \.self) { Text($0).tag($0) } }
                if app.lessonLevels.count < LearningLanguages.levels.count { Text("Complete this lesson course to unlock the next level, or set your starting level above.").font(.footnote) }
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
            .task(id:app.goalPreparationKey) { app.prepareDailyPlate(); try? await app.prepareGoal() }
            .onChange(of: app.learner.level) { _, _ in app.persist(); Task { await app.reloadContent() } }
    }
}
struct DailyPlateView: View {
    @EnvironmentObject var app: AppModel
    static let labels = ["repair":"Repair mistakes","goal":"Focused learning goal","speak":"Tutor lesson","learn":"Lesson","review":"Flashcard review","conversation":"Conversation","phonics":"Phonics"]
    var body: some View {
        List {
            Text("Complete today's courses. Saved quest completion earns a single +25 XP bonus and one voice journey session.")
            ForEach(app.plateCourses) { course in
                NavigationLink {
                    switch course.kind {
                    case "goal": FocusedGoalView()
                    case "repair": RepairPracticeView()
                    case "speak":
                        if let lesson = app.selectedTutorLesson { TutorView(tutorLesson:lesson) }
                        else { Text("This tutor course is complete. Choose another lesson level in Learn.") }
                    case "learn":
                        if let lesson = app.selectedLesson { if lesson.id == IntroTutorial.lessonID { IntroTutorialView(lesson:lesson) } else { LessonView(lesson:lesson) } }
                        else { Text("Choose a lesson level to continue.") }
                    case "review": FlashcardsView()
                    case "phonics": PhonicsView()
                    default: ConversationView()
                    }
                } label: {
                    VStack(alignment:.leading) {
                        HStack {
                            Text(Self.labels[course.kind] ?? course.kind.capitalized)
                            Spacer()
                            if course.done { Image(systemName:"checkmark.circle.fill") }
                            else if app.plateCourses.first(where:{ !$0.done })?.kind == course.kind { Text("Next").foregroundStyle(.secondary) }
                        }
                        Text("\(course.count) / \(course.target)").font(.caption)
                    }
                }.accessibilityIdentifier("quest-" + course.kind)
            }
            if DailyPlate.bonusAwarded(progress:app.learner.plateProgress,target:app.learner.target,day:CalendarDay.key(Date())) { Text("Quest completed · +25 XP").accessibilityIdentifier("questCompleted") }
            Section("Outside the app") { NavigationLink("Immersion & Score") { RealWorldTaskView() } }
        }.navigationTitle("Daily plate")
            .task(id:app.identity.npub + app.learner.target + CalendarDay.key(Date())) { app.prepareDailyPlate() }
    }
}
struct LessonView: View {
    let lesson:Lesson
    var body:some View {
        if lesson.isGoal == true || lesson.isRepair == true || (CurriculumLessonProgress.isCurriculumID(lesson.id) && lesson.id != IntroTutorial.lessonID) { CurriculumSessionView(lesson:lesson) }
        else { LegacyLessonOverviewView(lesson:lesson) }
    }
}
private struct LegacyLessonOverviewView: View {
    @EnvironmentObject var app: AppModel
    let lesson: Lesson
    private var curriculum:Bool { CurriculumLessonProgress.isCurriculumID(lesson.id) }
    private var work:CurriculumLessonProgress? { app.learner.lessonWork?[app.learner.completionKey(lesson.id)] }
    private var started:Bool { !curriculum || work != nil || app.learner.completed.contains(app.learner.completionKey(lesson.id)) }
    var body: some View {
        List {
            Section("Lesson") {
                Text(lesson.description.localized(app.learner.support))
                ForEach(Array(lesson.agenda["items"].array.enumerated()), id: \.offset) { _, item in
                    let goal = item["goal"].localized(app.learner.support)
                    if !goal.isEmpty { Text(goal) }
                }
                if curriculum {
                    ProgressView(value:work?.fraction(goal:lesson.xpReward) ?? 0)
                    Text("\(work?.earnedXP ?? 0) / \(lesson.xpReward) XP").font(.footnote).accessibilityIdentifier("lessonOwnedXP")
                    if !started { Button("Start lesson") { app.beginLesson(lesson) }.accessibilityIdentifier("startCurriculumLesson") }
                }
            }
            if started,lesson.isFinalQuiz == true {
                Section("Final quiz") {
                    let rules=QuizRules(lesson.quizConfig ?? .object([:]))
                    Text("Pass by answering \(rules.passingScore) of up to \(rules.questionsRequired) questions correctly.")
                    NavigationLink("Take final quiz") { FinalQuizView(lesson:lesson) }.accessibilityIdentifier("finalQuizLink")
                }
            } else if started { Section("Practice") {
                ForEach(AppModel.modes(for: lesson)) { mode in
                    NavigationLink { if mode == .game { RPGView(lesson:lesson,episode:nil) } else if mode == .reading { ReadingView(lesson:lesson) } else if mode == .stories { StoryView(lesson:lesson) } else { ExerciseView(mode: mode, lesson: lesson) } } label: {
                        HStack {
                            Text(mode.rawValue); Spacer()
                            if app.learner.practicedModes.contains(app.learner.modeKey(lesson.id, mode.rawValue)) { Image(systemName: "checkmark") }
                        }
                    }
                }
                if !lesson.modes.contains("game") {
                    if !curriculum { Button(lesson.id.hasPrefix("goal-") ? "Complete today’s goal lesson" : "Complete lesson (+\(lesson.xpReward) XP)") { app.complete(lesson) }
                    .disabled(!app.canComplete(lesson) || app.learner.completed.contains(app.learner.completionKey(lesson.id)))
                    }
                    Text(curriculum ? "Practice to reach this lesson’s XP goal. Your progress is saved when you leave." : "Complete a correct exercise in every listed skill to finish this lesson.").font(.footnote)
                    if app.learner.completed.contains(app.learner.completionKey(lesson.id)) { Label("Lesson completed",systemImage:"checkmark.circle.fill").accessibilityIdentifier("curriculumLessonCompleted") }
                }
                else { Text("Finish the adventure and confirm its recap to complete this unit review. Stars determine the lesson XP reward.").font(.footnote) }
            } }
        }.navigationTitle(lesson.title.localized(app.learner.support))
            .onChange(of:work?.earnedXP,initial:true) { _,_ in
                if curriculum,lesson.isFinalQuiz != true,!lesson.modes.contains("game"),app.canComplete(lesson) { app.complete(lesson) }
            }
    }
}
struct PracticeLibraryView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        List {
            Section("Authored content") {
                Picker("Flashcard level", selection: Binding(get: { app.learner.flashcardLevel }, set: { app.setCardLevel($0) })) { ForEach(app.cardLevels, id: \.self) { Text($0).tag($0) } }
                NavigationLink("Flashcards (\(app.cards.count))") { FlashcardsView() }
                NavigationLink("Phonics (\(app.phonics.count))") { PhonicsView() }
            }
            Section("Practice modes") {
                NavigationLink("Surprise practice") { ShufflePracticeView() }
                ForEach(PracticeMode.allCases) { mode in
                    if mode == .conversation { NavigationLink(mode.rawValue) { ConversationView() }.accessibilityIdentifier("conversationLink") }
                    else if mode == .game { NavigationLink(mode.rawValue) { RPGLibraryView() }.accessibilityIdentifier("adventureLink") }
                    else if mode == .reading { NavigationLink(mode.rawValue) { ReadingView(lesson:app.selectedLesson) }.accessibilityIdentifier("readingLink") }
                    else if mode == .stories { NavigationLink(mode.rawValue) { StoryView(lesson:app.selectedLesson) }.accessibilityIdentifier("storiesLink") }
                    else { NavigationLink(mode.rawValue) { ExerciseView(mode: mode, lesson: app.selectedLesson) } }
                }
                NavigationLink("Grammar reference") { GrammarReferenceView() }
                NavigationLink("Immersion & Score") { RealWorldTaskView() }
            }
        }.navigationTitle("Practice")
    }
}
