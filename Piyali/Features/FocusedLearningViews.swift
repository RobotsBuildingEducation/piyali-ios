import SwiftUI
import CryptoKit

struct FocusedGoalView: View {
    @EnvironmentObject var app: AppModel
    @State private var busy = false
    @State private var error: String?
    var plan: FocusedPlan? { app.learner.focusPlans?[app.learner.target] }
    var lesson: Lesson? {
        guard let plan else { return nil }
        let hash = SHA256.hash(data: Data((app.learner.target + app.learner.goal + app.learner.dailyKey).utf8)).prefix(8).map { String(format:"%02x",$0) }.joined()
        let brief = JSONValue.object(["objective":.string(plan.objective),"words":.array(plan.words.map(JSONValue.string)),"grammar":.array(plan.grammar.map(JSONValue.string)),"scenarios":.array(plan.scenarios.map(JSONValue.string)),"successCriteria":.array(plan.successCriteria.map(JSONValue.string))])
        return Lesson(id:"goal-\(hash)", title:.string(plan.title), description:.string(plan.objective), xpReward:30, modes:["vocabulary","reading","speaking"], agenda:brief, content:brief)
    }
    var body: some View {
        SubscriptionRequiredView(service: app.subscription) {
            Form {
                Section("Your goal") {
                    TextField("What would you like to do?", text:$app.learner.goal, axis:.vertical)
                    Button(plan == nil ? "Build a focused plan" : "Rebuild plan") { generate() }.disabled(busy || app.learner.goal.isEmpty)
                }
                if let plan, let lesson {
                    Section(plan.title) {
                        Text(plan.objective)
                        ForEach(plan.successCriteria,id:\.self) { Text($0) }
                        Text("Words: " + plan.words.joined(separator:", "))
                        Text("Grammar: " + plan.grammar.joined(separator:", "))
                    }
                    Section("Today's practice") {
                        ForEach(AppModel.modes(for:lesson)) { mode in NavigationLink(mode.rawValue) { ExerciseView(mode:mode,lesson:lesson) } }
                        Button("Complete today's goal (+30 XP)") { app.complete(lesson) }
                            .disabled(!app.canComplete(lesson) || app.learner.completed.contains(app.learner.completionKey(lesson.id)))
                    }
                }
                if busy { ProgressView("Building your plan…") }
                if let error { Text(error).foregroundStyle(.red) }
            }
        }.navigationTitle("Focused goal")
    }
    func generate() {
        guard app.subscription.hasAccess else { return }
        let account = app.identity.npub, target = app.learner.target, goal = app.learner.goal
        busy = true; error = nil; app.persist()
        Task {
            defer { busy = false }
            do {
                let plan = try await app.ai.structured(FocusedPlan.self,prompt:"Build a realistic focused language-learning plan for a \(app.learner.level) learner of \(LearningLanguages.names[app.learner.target] ?? app.learner.target). Goal data: \(JSONValue.string(app.learner.goal).json). Explain in \(LearningLanguages.names[app.learner.support] ?? app.learner.support). Be specific, achievable and aligned to the learner's level. Include 5 target-language words, 2 grammar concepts, 3 concrete scenarios and 3 observable success criteria. Return JSON {\"title\":\"short name\",\"objective\":\"goal\",\"words\":[\"word\"],\"grammar\":[\"concept\"],\"scenarios\":[\"situation\"],\"successCriteria\":[\"evidence\"]}.")
                guard app.identity.npub == account, app.learner.target == target, app.learner.goal == goal else { return }
                if app.learner.focusPlans == nil { app.learner.focusPlans = [:] }
                app.learner.focusPlans?[app.learner.target] = plan; app.persist()
            } catch { self.error = error.localizedDescription }
        }
    }
}
struct RepairPracticeView: View {
    @EnvironmentObject var app: AppModel
    var mistakes: [HistoryEntry] { Array(app.learner.history.filter { !$0.correct && $0.repairInMemory == nil && $0.target == app.learner.target }.prefix(30)) }
    var body: some View {
        List {
            if mistakes.isEmpty && app.learner.activeMemories.isEmpty { Text("Useful mistakes will appear here with focused practice. Answer reveals do not count as mistakes.") }
            ForEach(app.learner.activeMemories) { note in
                let mode = MemoryContract.practiceMode(note)
                let brief = JSONValue.object(note.fields)
                let lesson = Lesson(id:"repair-memory-" + note.id,title:.string(note.text("concept")),description:.string(note.text("mistake")),xpReward:20,modes:[mode == .speaking ? "speaking" : mode == .conversation ? "conversation" : mode.rawValue.lowercased()],agenda:brief,content:brief)
                Section(note.text("concept")) {
                    MemoryNoteDetails(note:note)
                    NavigationLink("Practice this concept") { ExerciseView(mode:mode,lesson:lesson,concept:note.text("concept")) }
                    Button("Complete repair (+20 XP)") { app.complete(lesson) }
                        .disabled(!app.canComplete(lesson) || app.learner.completed.contains(app.learner.completionKey(lesson.id)))
                }
            }
            ForEach(mistakes) { entry in
                let lesson = Lesson(id:"repair-\(entry.id.uuidString)",title:.string("Repair practice"),description:.string(entry.feedback),xpReward:20,modes:["grammar"],agenda:.object(["originalQuestion":.string(entry.question),"studentAnswer":.string(entry.answer),"feedback":.string(entry.feedback)]),content:.object(["grammar":.string("Practice the specific concept behind this error with a fresh example.")]))
                Section(entry.mode) {
                    Text(entry.question); Text(entry.feedback)
                    NavigationLink("Practice this concept") { ExerciseView(mode:.grammar,lesson:lesson) }
                    Button("Mark repair complete (+20 XP)") { app.complete(lesson) }
                        .disabled(!app.canComplete(lesson) || app.learner.completed.contains(app.learner.completionKey(lesson.id)))
                }
            }
        }.navigationTitle("Repair mistakes")
    }
}
struct AchievementsView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        List {
            Text("Achievement progress is earned through completed practice. The catalog uses the main web app's permanent achievement IDs and authored descriptions.").font(.footnote)
            ForEach(app.achievements) { achievement in
                let count = progress(achievement)
                VStack(alignment:.leading) {
                    HStack {
                        Text(achievement.title.localized(app.learner.support)).font(.headline)
                        Spacer()
                        if count.complete { Image(systemName:"checkmark.seal.fill") }
                    }
                    Text(achievement.description.localized(app.learner.support))
                    if let target = count.target { Text("\(count.value) / \(target)").font(.caption) }
                }
            }
        }.navigationTitle("Achievements")
    }
    func progress(_ achievement: AchievementDefinition) -> (value:Int,target:Int?,complete:Bool) {
        let metric = achievement.requirement["metric"].string
        let type = achievement.requirement["type"].string
        var target: Int?
        if case .number(let n) = achievement.requirement["target"] { target = Int(n) }
        let prefix = app.learner.target + ":"
        let lessons = app.learner.completed.filter { $0.hasPrefix(prefix + "lesson-") }.count
        let cards = app.learner.flashcardMastery.filter { $0.hasPrefix(prefix) }.count
        let value = metric == "skill_tree_lessons" ? lessons : metric == "flashcards_completed" ? cards : 0
        if type == "counter", ["skill_tree_lessons","flashcards_completed"].contains(metric) { return (value,target,value >= (target ?? Int.max)) }
        if type == "level_set", ["skillTree","flashcards"].contains(metric) {
            let level = achievement.requirement["level"].string
            guard let index = LearningLanguages.levels.firstIndex(of:level) else { return (0,nil,false) }
            let levels = Array(LearningLanguages.levels.prefix(index+1))
            let ids = levels.flatMap { level in
                metric == "skillTree" ? (app.curriculumIndex[app.learner.target]?[level] ?? []).map { prefix + $0 } : (app.flashcardIndex[level] ?? []).map { prefix + $0 }
            }
            let completed = metric == "skillTree" ? app.learner.completed : app.learner.flashcardMastery
            return (ids.filter { completed.contains($0) }.count,ids.count,!ids.isEmpty && ids.allSatisfy { completed.contains($0) })
        }
        return (0,nil,false)
    }
}
struct SubscriptionTermsView: View {
    var body: some View {
        List {
            Text("Apple subscriptions renew automatically unless cancelled before the current period ends. Apple displays the price and billing period before purchase. Manage or cancel your Apple subscription from your App Store account.")
            Text("Web subscriptions are billed and managed through Piyali's existing Patreon flow. Use the same Piyali identity when restoring access on your iPhone.")
            Text("Removing the app does not cancel a subscription.")
            Link("Apple standard license agreement",destination:URL(string:"https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        }.navigationTitle("Subscription terms")
    }
}
struct PrivacyDisclosureView: View {
    var body: some View {
        List {
            Text("Your Nostr private key is stored in this iPhone's device-only Keychain. It is used locally to sign proofs and events. The app does not send your private key to Firebase or AI services.")
            Text("Progress, preferences, notes and learning history are saved on this iPhone. When Firebase is configured, these are also saved to your npub's Firestore document. The account supports the reference product's existing Firestore rules.")
            Text("AI exercises and chat send their learning context, questions and your answers to Firebase Gemini or the configured Cloudflare AI proxy. Microphone practice uses Apple's speech recognition service; live tutor audio is streamed to Firebase Gemini for the duration of the session.")
            Text("Team membership and team names are public Nostr events. Learning progress is published publicly only when you enable sharing and press Publish progress. Public relay events can remain available after leaving or deleting a team.")
            Text("Voice journey recordings are private local files on this iPhone. They are not uploaded automatically.")
        }.navigationTitle("Privacy")
    }
}
