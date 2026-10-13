import SwiftUI
import CryptoKit

struct FocusedGoalView: View {
    @EnvironmentObject var app: AppModel
    @State private var draft = ""
    @State private var busy = false
    @State private var error: String?
    var body: some View {
        SubscriptionRequiredView(service:app.subscription) {
            Form {
                Section("Your goal") {
                    TextField("What would you like to do?",text:$draft,axis:.vertical)
                    Button("Save goal") { app.learner.editGoal(draft); app.persist(); prepare() }.disabled(busy || draft.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                    if !app.learner.goalBucket["activeGoal"]["id"].string.isEmpty {
                        let status = app.learner.goalBucket["activeGoal"]["status"].string
                        Text("Status: " + status)
                        Button(status == "active" ? "Pause goal" : "Resume goal") { app.setGoalStatus(status == "active" ? "paused" : "active"); if status != "active" { prepare() } }
                        Button("Mark personal goal achieved") { app.setGoalStatus("achieved") }
                        Button("Remove goal",role:.destructive) { app.learner.editGoal(""); draft = ""; app.persist() }
                    }
                }
                if let daily = app.readyGoal {
                    let blueprint = daily["blueprint"]
                    Section("Today's focus") {
                        Text(blueprint["objective"].string).font(.headline)
                        Text(blueprint["scenario"].string)
                        ForEach(GoalPractice.list(blueprint["successCriteria"]),id:\.self) { Text($0) }
                        Text(blueprint["rationale"].string).font(.footnote)
                    }
                    Section(daily["completed"].boolean ? "Today's bundle completed" : "Practice bundle") {
                        ForEach(GoalPractice.list(blueprint["modes"],max:4),id:\.self) { mode in
                            NavigationLink {
                                if mode == "lesson" { LessonView(lesson:GoalPractice.lesson(blueprint)) }
                                else if mode == "tutor" { TutorView(goalBlueprint:blueprint) }
                                else { GoalPreparationView(mode:mode,blueprint:blueprint) }
                            } label: {
                                HStack {
                                    Text(mode.capitalized); Spacer()
                                    if daily["modeProgress"][mode].number >= Double(GoalPractice.targets[mode] ?? 1) { Image(systemName:"checkmark.circle.fill") }
                                    else if GoalPractice.nextMode(daily) == mode { Text("Next").foregroundStyle(.secondary) }
                                }
                            }
                        }
                        Text("Recall and modeled pronunciation are preparation. Task checks use what you demonstrate against today's criteria.").font(.footnote)
                    }
                    if !app.learner.goalBucket["goalProgress"]["prose"].string.isEmpty {
                        Section("Progress evidence") { Text(app.learner.goalBucket["goalProgress"]["prose"].string) }
                    }
                } else if app.learner.goalBucket["activeGoal"]["status"].string == "active" {
                    Button("Prepare today's practice") { prepare() }.disabled(busy)
                }
                if busy { ProgressView("Preparing today's goal…") }
                if let error { Text(error).foregroundStyle(.red) }
            }
        }.navigationTitle("Focused goal")
            .onAppear { draft = app.learner.goal }
            .task(id:app.goalPreparationKey) { guard !busy else { return }; busy = true; defer { busy = false }; do { try await app.prepareGoal() } catch { self.error = error.localizedDescription } }
    }
    func prepare() {
        busy = true; error = nil
        Task { defer { busy = false }; do { try await app.prepareGoal() } catch { self.error = error.localizedDescription } }
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
            Text("Achievements are confirmed after progress syncs. Earned awards stay in your collection when you change languages or devices. Placement and XP alone do not prove course completion.").font(.footnote)
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
        let record=app.learner.achievementRecords?[achievement.id] ?? .null
        let earned=record["unlockedAt"].number > 0 && !record["test"].boolean
        let summary=app.learner.achievementEvidence?[app.learner.target] ?? .object([:])
        let counts=AchievementProgress.counters(summary)
        var evidence=JSONValue.object(["language":.string(app.learner.target),"counters":counts])
        evidence=AchievementProgress.snapshot(ledger:app.learner.achievementLedger ?? .object([:]),evidence:evidence)
        let metric=achievement.requirement["metric"].string
        let cardCount=(app.learner.achievementLedger?["flashcards_completed:"+app.learner.target].object.count ?? 0)
        let value=metric == "flashcards_completed" ? max(Int(counts[metric].number),cardCount) : Int(evidence["counters"][metric].number)
        let target=achievement.requirement["target"] == .null ? nil : Int(achievement.requirement["target"].number)
        return (value,target,earned)
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
