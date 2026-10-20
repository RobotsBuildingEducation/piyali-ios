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
    @FocusState private var goalFocused: Bool
    var body: some View {
        Form {
            Section("Learning preferences") {
                TextField("Name", text: $app.learner.name)
                LanguagePicker(title: "Practice language", selection: Binding(get:{ app.learner.target },set:{ app.setPracticeLanguage($0) }), codes: LearningLanguages.practice).accessibilityIdentifier("practiceLanguagePicker")
                LanguagePicker(title: "Support language", selection: $app.learner.support, codes: LearningLanguages.support)
                TextField("Learning goal", text: $app.learner.goal, axis: .vertical).accessibilityIdentifier("learningGoalField").focused($goalFocused)
                Stepper("Daily goal: \(app.learner.dailyGoal) XP", value: $app.learner.dailyGoal, in: 10...300, step: 10)
                TextField("Companion name", text: $app.learner.companionName)
                Picker("Companion", selection: $app.learner.companionType) { ForEach(CompanionTypes.available(level: app.learner.companionLevel), id: \.self) { Text($0.capitalized).tag($0) } }
                Button("Save preferences") { app.persist(); Task { await app.reloadContent() } }
            }
            Section("Your Nostr identity") {
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
                    Button("Save") { goalFocused = false; app.persist(); Task { await app.reloadContent() } }.accessibilityIdentifier("saveLearningPreferences")
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
struct TeamsView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var service: NostrTeamsService
    @State private var name=""
    @State private var members=""
    @State private var busy=false
    @State private var consent=false
    @FocusState private var focusedField: String?
    var body: some View {
        List {
            Section("Nostr teams") {
                Text("Team names and membership are public on Nostr. Sharing learning progress publishes your name, language, XP, daily goal, streak and companion status publicly.").font(.footnote)
                Text("Your ID: "+app.identity.npub).font(.caption).textSelection(.enabled)
                Toggle("Share my learning progress publicly",isOn:$consent)
                Button("Publish progress") { perform { try await service.publishProgress(app.learner,identity:app.identity) } }.disabled(!consent || busy || service.busy)
                Button("Refresh teams") { Task { await service.refresh(identity:app.identity) } }.disabled(service.busy || busy)
            }
            Section("Create a public team") {
                TextField("Team name",text:$name).focused($focusedField,equals:"name").accessibilityIdentifier("teamName")
                TextField("Teammate npubs, comma-separated",text:$members,axis:.vertical).focused($focusedField,equals:"members").accessibilityIdentifier("teamMembers").textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Create team") { perform { try await service.create(name:name,members:members,identity:app.identity);name="";members="" } }.accessibilityIdentifier("teamCreate").disabled(busy || service.busy || name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || members.isEmpty)
            }
            Section("Your teams") {
                ForEach(service.teams) { team in
                    NavigationLink { LearningTeamView(service:service,id:team.id) } label: { VStack(alignment:.leading) { Text(team.name);Text("\(team.members.count) members"+(team.creator == app.identity.hex ? " · You are the creator" : "")).font(.caption) } }.accessibilityIdentifier("learningTeamRow")
                }
                if service.teams.isEmpty,!service.busy { Text("No teams found. Refresh to check your relays.") }
            }
            if service.busy || busy { ProgressView("Connecting to relays…") }
            if let error=service.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Teams").toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { focusedField=nil } } }.task(id:app.identity.npub) { await service.refresh(identity:app.identity) }
    }
    private func perform(_ action: @escaping () async throws -> Void) {
        focusedField=nil;busy=true;let account=app.identity.npub
        Task { defer { busy=false };do { try await action() } catch { if app.identity.npub == account,!(error is CancellationError) { service.error=error.localizedDescription } } }
    }
}
struct LearningTeamView: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var service: NostrTeamsService
    let id: String
    @State private var name=""
    @State private var members=""
    @State private var busy=false
    @State private var removal=false
    @FocusState private var focusedField: String?
    var team: LearningTeam? { service.teams.first { $0.id == id } }
    var body: some View {
        List {
            if let team {
                Section("Members") {
                    ForEach(team.members,id:\.self) { member in
                        let row=service.row(member:member,team:team,learner:app.learner,viewer:app.identity.hex)
                        VStack(alignment:.leading,spacing:6) {
                            Text(row["name"].string.isEmpty ? String(row["npub"].string.prefix(20))+"…" : row["name"].string).font(.headline)
                            Text(row["npub"].string).font(.caption).textSelection(.enabled)
                            if row["isCreator"].boolean { Text("Creator").font(.caption) }
                            if !row["targetLang"].string.isEmpty {
                                Text("\(LearningLanguages.names[row["targetLang"].string] ?? row["targetLang"].string) · Course \(row["level"].string)")
                                if case .number(let score)=row["score"] { Text("Score: \(score.formatted())/100 · \(row["scoreLevel"].string)") }
                                Text("\(row["totalXp"].number.formatted()) total XP · \(row["streak"].number.formatted()) day streak")
                                ProgressView(value:max(0,min(100,row["progressPercent"].number)),total:100)
                                Text("\(row["dailyXp"].number.formatted()) / \(row["dailyGoalXp"].number.formatted()) daily XP")
                                let pet=row["companion"]
                                Text("\(pet["name"].string.isEmpty ? pet["type"].string.capitalized : pet["name"].string) · Level \(pet["level"].number.formatted()) · \(pet["health"].number.formatted())% health").font(.footnote)
                            } else { Text("No shared learning progress yet.").font(.footnote) }
                        }
                    }
                }
                if team.creator == app.identity.hex {
                    Section("Manage team") {
                        TextField("Team name",text:$name).focused($focusedField,equals:"name").accessibilityIdentifier("teamEditName")
                        Button("Save team name") { perform { try await service.rename(team,name:name,identity:app.identity) } }.accessibilityIdentifier("teamRename").disabled(busy || service.busy || name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                        TextField("New teammate npubs",text:$members,axis:.vertical).focused($focusedField,equals:"members").accessibilityIdentifier("teamAddInput").textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button("Add members") { perform { try await service.addMembers(team,members:members,identity:app.identity);members="" } }.accessibilityIdentifier("teamAdd").disabled(busy || service.busy || members.isEmpty)
                        Text("Roster changes and names are public. Teammates added here can see the team in either app.").font(.footnote)
                    }
                }
                Button(team.creator == app.identity.hex ? "Delete team" : "Leave team",role:.destructive) { removal=true }.disabled(busy || service.busy)
            } else { Text("This team is no longer in your roster.");Button("Back to teams") { dismiss() } }
            Button("Refresh team") { Task { await service.refresh(identity:app.identity) } }.disabled(service.busy || busy)
            if service.busy || busy { ProgressView("Updating team…") }
            if let error=service.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle(team?.name ?? "Team").toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { focusedField=nil } } }
            .onAppear { name=team?.name ?? "" }
            .confirmationDialog(team?.creator == app.identity.hex ? "Delete this team for every member?" : "Leave this team?",isPresented:$removal,titleVisibility:.visible) {
                if let team { Button(team.creator == app.identity.hex ? "Delete team" : "Leave team",role:.destructive) { perform { try await service.leave(team,identity:app.identity);dismiss() } } }
            }
    }
    private func perform(_ action: @escaping () async throws -> Void) {
        focusedField=nil;busy=true;let account=app.identity.npub
        Task { defer { busy=false };do { try await action() } catch { if app.identity.npub == account,!(error is CancellationError) { service.error=error.localizedDescription } } }
    }
}
