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
    @EnvironmentObject var app:AppModel
    var body:some View {
        SubscriptionRequiredView(service:app.subscription) {Group {
            if let step=app.currentRepairStep {
                Group {
                    if step.mode == "lesson",let lesson=app.repairLesson(step) {LessonView(lesson:lesson)}
                    else if step.mode == "flashcards" {FlashcardsView(repairStep:step)}
                    else if step.mode == "phonics",!app.authoredRepairPhonics(step).isEmpty {PhonicsView(repairStep:step)}
                    else {TutorView(repairStep:step)}
                }.id(step.id)
            } else {ContentUnavailableView(ProductCopy.course(app.learner.support,"repair"),systemImage:"checkmark.circle")}
        }}.navigationTitle(ProductCopy.course(app.learner.support,"repair"))
    }
}
struct AchievementsView: View {
    @EnvironmentObject var app: AppModel
    var body: some View {
        List {
            Text("Achievements are confirmed after progress syncs. Earned awards stay in your collection when you change languages or devices. Placement and XP alone do not prove course completion.").font(.footnote)
            Section("Nostr collection") { NostrAchievementControls(service:app.nostrAchievements) }
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
        let earned=record["unlockedAt"].number > 0 && !NostrAchievementCollection.truthy(record["test"])
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
            Text("When you enable public achievement sharing, your signed achievement collection is published to Nostr relays and kept up to date. Signed collections from your own key are restored privately and can be imported into the Piyali Firebase project.")
            Text("Voice journey recordings are private local files on this iPhone. They are not uploaded automatically.")
        }.navigationTitle("Privacy")
    }
}

struct NostrAchievementControls: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var service: NostrAchievementsService
    var body: some View {
        Toggle("Keep my achievement collection public on Nostr",isOn:Binding(get:{ app.learner.shareNostrAchievements == true },set:{ app.setNostrAchievementSharing($0) }))
        Text("Published achievement records can be read by anyone. Your learning notes and private key are kept separately. Sharing is saved on this iPhone.").font(.footnote)
        Button("Restore signed Nostr collection") { Task { try? await app.syncNostrAchievements(publish:false) } }.disabled(service.busy)
        Button("Publish achievement collection") { Task { try? await app.syncNostrAchievements(publish:true) } }.disabled(service.busy || app.learner.shareNostrAchievements != true)
        if service.busy { ProgressView("Syncing achievement collection…") }
        if !service.status.isEmpty { Text(service.status) }
        if let error=service.error { Text(error).foregroundStyle(.red) }
    }
}
