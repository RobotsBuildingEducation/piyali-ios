import SwiftUI
import StoreKit
import LocalAuthentication

struct SubscriptionView: View {
    @ObservedObject var service: SubscriptionService
    let config = AppConfiguration()
    var body: some View {
        List {
            Section {
                Text(service.authorized ? "Your subscription is active" : "Unlock Piyali").font(.title2)
                Text("Access the AI tutor, generated lessons, reading, stories, conversation and listening practice.")
                if service.webAuthorized { Text("Verified web subscription") }
                if service.appleAuthorized { Text("Verified Apple subscription") }
                if service.busy { ProgressView("Checking subscription…") }
            }
            Section("Subscribe on iPhone") {
                ForEach(service.products) { product in Button("\(product.displayName) · \(product.displayPrice)") { Task { await service.buy(product) } }.disabled(service.busy) }
                if service.products.isEmpty { Text("App Store plans are not available yet. Existing web subscribers can restore access below.") }
                Button("Restore purchases and web access") { Task { await service.restore() } }.disabled(service.busy)
                Button("Refresh subscription") { Task { await service.refresh() } }.disabled(service.busy)
                Button("Manage Apple subscription") { if let url = URL(string: "https://apps.apple.com/account/subscriptions") { UIApplication.shared.open(url) } }
            }
            if service.externalPaymentAllowed {
                Section("Subscribe on the web") {
                    Link("Open Piyali web subscriptions", destination: config.subscriptionURL)
                    Text("Use the same Piyali key on the web, connect Patreon there, then return and refresh access. Never put your private key in a URL.").font(.footnote)
                }
            }
            Section {
                NavigationLink("Subscription terms") { SubscriptionTermsView() }
                NavigationLink("Privacy") { PrivacyDisclosureView() }
            }
            if let error = service.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Subscription")
    }
}
struct NotebookView: View {
    @EnvironmentObject var app: AppModel
    @State private var title = ""
    @State private var bodyText = ""
    var body: some View {
        List {
            Section("Companion memory") {
                NavigationLink("Companion memory (\(app.learner.activeMemories.count))") { CompanionMemoryView() }
                NavigationLink("Repair mistakes") { RepairPracticeView() }
            }
            Section("New note") {
                TextField("Title", text: $title)
                TextField("What do you want to remember?", text: $bodyText, axis: .vertical)
                Button("Save note") {
                    app.learner.notes.insert(Note(title: title, body: bodyText), at: 0); app.persist(); title = ""; bodyText = ""
                }.disabled(title.isEmpty || bodyText.isEmpty)
            }
            Section("Your notes") {
                ForEach(app.learner.notes) { note in
                    NavigationLink(note.title) { NoteEditor(note: note) }
                }.onDelete { offsets in app.learner.notes.remove(atOffsets: offsets); app.persist() }
            }
            Section("Learning history") {
                ForEach(app.learner.history) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.mode + " · " + (LearningLanguages.names[entry.target] ?? entry.target)).font(.caption)
                        Text(entry.question).font(.headline); Text(entry.answer); Text(entry.feedback)
                        Text(entry.date, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }.navigationTitle("Notes & history")
    }
}
struct NoteEditor: View {
    @EnvironmentObject var app: AppModel
    @State var note: Note
    var body: some View {
        Form {
            TextField("Title", text: $note.title)
            TextEditor(text: $note.body).frame(minHeight: 250)
            Button("Save") { if let index = app.learner.notes.firstIndex(where: { $0.id == note.id }) { app.learner.notes[index] = note; app.persist() } }
        }.navigationTitle("Edit note")
    }
}
struct AccountView: View {
    @EnvironmentObject var app: AppModel
    @State private var backup: String?
    @State private var importKey = ""
    @State private var importConfirmation = false
    @State private var gettingStarted=false
    @State private var dailyGoalOpen=false
    var body: some View {
        Form {
            Section("Learning preferences") {
                TextField("Name", text: $app.learner.name)
                LanguagePicker(title: "Practice language", selection: Binding(get:{ app.learner.target },set:{ app.setPracticeLanguage($0) }), codes: LearningLanguages.practice).accessibilityIdentifier("practiceLanguagePicker")
                LanguagePicker(title: "Support language", selection: $app.learner.support, codes: LearningLanguages.support).accessibilityIdentifier("supportLanguagePicker")
                LearningGoalEditorView().listRowInsets(EdgeInsets(top:8,leading:0,bottom:8,trailing:0)).listRowBackground(Color.clear)
                Button(EntryCopy.ui(app.learner.support,"daily_goal_title")){dailyGoalOpen=true}.accessibilityIdentifier("accountDailyGoal")
                TextField("Companion name", text: $app.learner.companionName)
                Picker("Companion", selection: $app.learner.companionType) { ForEach(CompanionTypes.available(level: app.learner.companionLevel), id: \.self) { Text($0.capitalized).tag($0) } }
                Button("Save preferences") {app.flushGoalEditor();app.persist(); Task { await app.reloadContent() } }
            }
            Section("Your Nostr identity") {
                Button(FirstRunCopy.text(app.learner.support,0)) {gettingStarted=true}.accessibilityIdentifier("accountGettingStarted")
                Text(app.identity.npub).font(.caption).textSelection(.enabled)
                if app.identity.isRemote {
                    Text("Connected through your remote signer. Your main private key stays with that signer.").font(.footnote)
                    Button("Disconnect remote signer") { app.disconnectRemote() }.accessibilityIdentifier("remoteSignerDisconnect")
                } else { Button("Back up private key") { authenticateBackup() };Text("Keep a private copy of your key to recover this account on another device.").font(.footnote) }
                NavigationLink("Connect a remote signer") { RemoteSignerView() }
                SecureField("Import another nsec", text: $importKey).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Switch account") { importConfirmation = true }.disabled(importKey.isEmpty)
            }
            Section("Community & subscription") {
                NavigationLink("Achievements") { AchievementsView() }
                NavigationLink("Voice journey") { VoiceJourneyView() }
                NavigationLink("Wallet") { WalletView() }.accessibilityIdentifier("walletLink")
                NavigationLink("Learning teams") { TeamsView(service: app.teams) }
                NavigationLink("Subscription") { SubscriptionView(service: app.subscription) }
            }
            Section("Progress") {
                Text("\(app.learner.totalXP) total XP · \(app.learner.completed.count) lessons completed")
                Text(app.syncStatus)
                Text(FirebaseService.shared.configured ? "Firebase configured" : "Offline content available. Firebase setup is required for online features.").font(.footnote)
                Button("Sync progress") { Task { await app.sync() } }
            }
        }.navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button("Save") { app.flushGoalEditor();UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to:nil,from:nil,for:nil);app.persist(); Task { await app.reloadContent() } }.accessibilityIdentifier("saveLearningPreferences")
                }
            }
            .onChange(of: app.learner.support) { _, _ in app.persist(); Task { await app.reloadContent() } }
            .sheet(isPresented: Binding(get: { backup != nil }, set: { if !$0 { backup = nil } })) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Save this key privately. Anyone with it can access your account.")
                        Text(backup ?? "").textSelection(.enabled).privacySensitive().font(.caption)
                    }.padding().navigationTitle("Private key backup").toolbar { Button("Done") { backup = nil } }
                }
            }
            .fullScreenCover(isPresented:$gettingStarted) {
                ZStack {
                    Color.black.opacity(0.82).ignoresSafeArea().onTapGesture {gettingStarted=false;app.learner.gettingStartedModalShown=true;app.persist()}
                    GettingStartedView {gettingStarted=false;app.learner.gettingStartedModalShown=true;app.persist()}
                }.presentationBackground(.clear).environment(\.layoutDirection,app.learner.support == "ar" ? .rightToLeft : .leftToRight)
            }
            .fullScreenCover(isPresented:$dailyGoalOpen){DailyGoalManagerView(onClose:{dailyGoalOpen=false}).presentationBackground(.clear).environment(\.layoutDirection,app.learner.support == "ar" ? .rightToLeft : .leftToRight)}
            .confirmationDialog("Switch to another account? Your current progress is saved on this iPhone.", isPresented: $importConfirmation) {
                Button("Switch account") { Task { await app.signIn(nsec: importKey); importKey = "" } }
            }
    }
    func authenticateBackup() {
        Task {
            let context = LAContext()
            do { if try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Reveal your Piyali private key for backup") { backup = app.identity.exportKey() } }
            catch { app.error = error.localizedDescription }
        }
    }
}
struct TeamsView:View {
    @Environment(\.dismiss) private var dismiss
    let service:NostrTeamsService
    var body:some View{TeamsDrawerView(service:service,onClose:{dismiss()}).toolbar(.hidden,for:.navigationBar)}
}
