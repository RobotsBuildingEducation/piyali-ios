import SwiftUI
import CryptoKit

struct FocusedGoalView:View {
    @EnvironmentObject var app:AppModel
    var body:some View {ScrollView{LearningGoalEditorView().padding(16)}.background(BrandBackground()).navigationTitle(app.goalText("label"))}
}
struct RepairPracticeView: View {
    @EnvironmentObject var app:AppModel
    var onSurface:(ProductMode)->Void = {_ in}
    var tutorControllerFactory:((TutorFocus)->TutorSessionController)? = nil
    @State private var routed:RepairStep?
    @State private var tutorFinishing=false
    var body:some View {
        SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:tutorFinishing) {Group {
            if let step=routed {
                Group {
                    if step.mode == "lesson",let lesson=app.repairLesson(step) {LessonView(lesson:lesson)}
                    else if step.mode == "flashcards" {FlashcardsView(repairStep:step)}
                    else if step.mode == "phonics",!app.authoredRepairPhonics(step).isEmpty {PhonicsView(repairStep:step)}
                    else {SourceTutorView(controller:tutorControllerFactory?(.repair(step)),focus:.repair(step),onCompletionPending:{tutorFinishing=$0},onFocusedCompletion:{route(app.currentRepairStep)})}
                }.id(step.id)
            } else {ContentUnavailableView(ProductCopy.course(app.learner.support,"repair"),systemImage:"checkmark.circle")}
        }}.navigationTitle(ProductCopy.course(app.learner.support,"repair")).task{route(app.currentRepairStep)}.onChange(of:app.currentRepairStep){_,step in if !tutorFinishing{route(step)}}
    }
    private func route(_ step:RepairStep?) {
        routed=step;guard let step else{return}
        onSurface(step.mode == "lesson" ? .path:step.mode == "flashcards" ? .cards:step.mode == "phonics" && !app.authoredRepairPhonics(step).isEmpty ? .phonics:.tutor)
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
