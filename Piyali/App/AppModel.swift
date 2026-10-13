import Foundation
import SwiftUI

@MainActor final class AppModel: ObservableObject {
    @Published var learner = LearnerState()
    @Published var signedIn = false
    @Published var units: [LearningUnit] = []
    @Published var cards: [Flashcard] = []
    @Published var phonics: [PhonicsCard] = []
    var curriculumIndex: [String:[String:[String]]] = [:]
    var flashcardIndex: [String:[String]] = [:]
    @Published var achievements: [AchievementDefinition] = []
    @Published var error: String?
    @Published var syncStatus = "Saved on this iPhone"
    @Published var loadingContent = false
    let identity = IdentityService()
    let ai = AIService()
    let subscription = SubscriptionService()
    let teams = NostrTeamsService()
    private var saveTask: Task<Void, Never>?
    private var contentTask: Task<Void, Never>?
    var selectedLesson: Lesson? { units.flatMap(\.lessons).first { !learner.completed.contains(learner.completionKey($0.id)) } ?? units.last?.lessons.last }
    init() {
        curriculumIndex = (try? ContentLibrary.load([String:[String:[String]]].self, name: "curriculum-index")) ?? [:]
        flashcardIndex = (try? ContentLibrary.load([String:[String]].self, name: "flashcard-index")) ?? [:]
        achievements = (try? ContentLibrary.load([AchievementDefinition].self, name: "achievements")) ?? []
        signedIn = !identity.npub.isEmpty
        if signedIn { loadLocal(); subscription.bind(identity) }
    }
    private var localURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Piyali", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent(identity.npub + ".json")
    }
    func loadLocal() {
        if let data = try? Data(contentsOf: localURL), let state = try? JSONDecoder().decode(LearnerState.self, from: data) { learner = state } else { learner = LearnerState() }
        learner.rollDay()
    }
    func signIn(nsec: String?) async {
        do {
            if let nsec { try identity.importKey(nsec) } else { try identity.create() }
            saveTask?.cancel(); contentTask?.cancel()
            let account = identity.npub
            loadLocal(); signedIn = true; subscription.bind(identity)
            if let cloud = try await FirebaseService.shared.load(npub: identity.npub) {
                // A pending local offline save is authoritative until uploaded.
                guard identity.npub == account else { return }
                if !FileManager.default.fileExists(atPath: localURL.path) { learner = cloud; persist() }
            }
            await reloadContent(); await subscription.refresh()
        } catch { self.error = error.localizedDescription }
    }
    func boot() async { guard signedIn else { return }; await reloadContent(); await subscription.refresh() }
    func reloadContent() async {
        contentTask?.cancel()
        let target = learner.target, support = learner.support, level = learner.level
        loadingContent = true
        let task = Task { [weak self] in
            do {
                let data = try await Task.detached(priority: .userInitiated) { () -> ([LearningUnit], [Flashcard], [PhonicsCard]) in
                    let curriculum = try ContentLibrary.load([String:[LearningUnit]].self, name: "curriculum-" + target)
                    let cards = try ContentLibrary.load([Flashcard].self, name: "flashcards").filter { $0.cefrLevel == level }
                    let allPhonics = try ContentLibrary.load([String:[PhonicsCard]].self, name: "phonics")
                    return (curriculum[level] ?? [], cards, allPhonics["\(target):\(support):\(level)"] ?? [])
                }.value
                guard !Task.isCancelled else { return }
                self?.units = data.0; self?.cards = data.1; self?.phonics = data.2
            } catch { if !Task.isCancelled { self?.error = error.localizedDescription } }
            if !Task.isCancelled { self?.loadingContent = false }
        }
        contentTask = task; await task.value
    }
    func persist() {
        do { try JSONEncoder().encode(learner).write(to: localURL, options: [.atomic, .completeFileProtection]) }
        catch { self.error = "Could not save progress: \(error.localizedDescription)"; return }
        saveTask?.cancel()
        let state = learner, npub = identity.npub
        saveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                try await FirebaseService.shared.save(state, npub: npub)
                syncStatus = FirebaseService.shared.configured ? "Synced with Firebase" : "Saved on this iPhone"
            } catch is CancellationError { } catch { syncStatus = "Saved on iPhone; cloud sync pending"; self.error = error.localizedDescription }
        }
    }
    func sync() async {
        do { try await FirebaseService.shared.save(learner, npub: identity.npub); syncStatus = FirebaseService.shared.configured ? "Synced with Firebase" : "Saved on this iPhone" }
        catch { self.error = error.localizedDescription }
    }
    func record(exercise: Exercise, answer: String, grade: Grade, mode: PracticeMode, lesson: Lesson?, flashcardID: String? = nil) {
        learner.history.insert(HistoryEntry(date: Date(), target: learner.target, mode: mode.rawValue, question: exercise.question, answer: answer, feedback: grade.feedback, correct: grade.correct), at: 0)
        learner.history = Array(learner.history.prefix(500))
        learner.assess(correct: grade.correct, independent: exercise.choices.isEmpty)
        if grade.correct {
            if let flashcardID { learner.flashcardMastery.insert(learner.target + ":" + flashcardID) }
            learner.award(10)
            if mode == .speaking || mode == .conversation {
                if learner.journeyDays == nil { learner.journeyDays = [] }
                learner.journeyDays?.insert(learner.target + ":" + learner.dailyKey)
            }
            if let lesson { learner.practicedModes.insert(learner.modeKey(lesson.id, mode.rawValue)) }
        }
        persist()
    }
    func canComplete(_ lesson: Lesson) -> Bool { Self.modes(for: lesson).allSatisfy { learner.practicedModes.contains(learner.modeKey(lesson.id, $0.rawValue)) } }
    func complete(_ lesson: Lesson) { guard canComplete(lesson) else { return }; _ = learner.complete(lesson); persist() }
    static func modes(for lesson: Lesson) -> [PracticeMode] {
        let map: [String: PracticeMode] = ["vocabulary":.vocabulary,"flashcards":.vocabulary,"grammar":.grammar,"reading":.reading,"listening":.listening,"repeat":.listening,"speaking":.speaking,"speak":.speaking,"stories":.stories,"story":.stories,"conversation":.conversation,"conversations":.conversation,"tutor":.conversation,"realtime":.conversation,"game":.game,"translate":.vocabulary]
        let mapped = lesson.modes.compactMap { map[$0.lowercased()] }
        return mapped.isEmpty ? [.vocabulary,.grammar,.reading] : Array(Set(mapped)).sorted { $0.rawValue < $1.rawValue }
    }
}
