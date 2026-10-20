import SwiftUI

struct PrivateTeamsView:View {
    @EnvironmentObject var app:AppModel
    @StateObject private var service=PrivateTeamsService()
    @State private var name=""
    @State private var members=""
    @FocusState private var editing:String?
    var body:some View {
        List {
            Section {
                Text("Private team names and rosters stay in Firebase. Invited learners can view the roster. Only accepted teammates can view progress you explicitly share with this team. Notes, recordings, conversations, wallet data and private keys are excluded.").font(.footnote)
                Text("Your ID: "+app.identity.npub).font(.caption).textSelection(.enabled)
                Button("Refresh private teams") { perform { try await service.refresh(identity:app.identity) } }.disabled(service.busy)
            }
            if !service.invites.isEmpty {
                Section("Invitations") {
                    ForEach(service.invites) { invite in
                        VStack(alignment:.leading,spacing:8) {
                            Text(invite.name).font(.headline)
                            Text(invite.data["invitedByName"].string.isEmpty ? invite.creator : invite.data["invitedByName"].string).font(.caption)
                            HStack {
                                Button("Accept") { perform { try await service.respond(invite,accept:true,identity:app.identity) } }.buttonStyle(.bordered).accessibilityIdentifier("privateTeamAccept")
                                Button("Decline",role:.destructive) { perform { try await service.respond(invite,accept:false,identity:app.identity) } }.buttonStyle(.bordered)
                            }.disabled(service.busy)
                        }
                    }
                }
            }
            Section("Create a private team") {
                TextField("Team name",text:$name).focused($editing,equals:"name").accessibilityIdentifier("privateTeamName")
                TextField("Teammate npubs, comma-separated",text:$members,axis:.vertical).focused($editing,equals:"members").textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("privateTeamMembers")
                Button("Create and invite") { perform { try await service.create(name:name,members:members,creatorName:app.learner.name,identity:app.identity);name="";members="" } }.disabled(service.busy || name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || members.isEmpty).accessibilityIdentifier("privateTeamCreate")
            }
            Section("Your private teams") {
                ForEach(service.teams) { team in
                    NavigationLink { PrivateTeamView(service:service,id:team.id) } label: {
                        VStack(alignment:.leading) { Text(team.name);Text("\(team.members.filter { $0["status"].string == "accepted" }.count+1) joined · \(team.members.filter { $0["status"].string == "pending" }.count) invited").font(.caption) }
                    }.accessibilityIdentifier("privateTeamRow")
                }
                if service.teams.isEmpty,!service.busy { Text("No private teams yet.") }
            }
            if service.busy { ProgressView("Updating private teams…") }
            if let error=service.error { Text(error).foregroundStyle(.red).accessibilityIdentifier("privateTeamsError") }
        }.navigationTitle("Private teams").toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { editing=nil } } }
            .task(id:app.identity.npub) { service.cancel(clear:true);try? await service.refresh(identity:app.identity) }
            .onChange(of:app.identity.npub) { service.cancel(clear:true) }
    }
    private func perform(_ action:@escaping @MainActor () async throws -> Void) { editing=nil;Task { try? await action() } }
}
struct PrivateTeamView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var service:PrivateTeamsService
    let id:String
    @State private var name=""
    @State private var members=""
    @State private var removing=false
    @FocusState private var editing:String?
    private var team:PrivateTeam? { service.teams.first { $0.id == id } }
    var body:some View {
        List {
            if let team {
                Section("Progress shared with this team") {
                    Text("Your current progress is visible to you here. Press Share my progress to copy a summary for this team's accepted members. It is not published to Nostr.").font(.footnote)
                    Button("Share my progress with this team") { perform { try await service.shareProgress(app.learner,in:team,identity:app.identity) } }.disabled(service.busy).accessibilityIdentifier("privateTeamShare")
                    Button("Refresh shared progress") { perform { try await service.loadProgress(team,identity:app.identity) } }.disabled(service.busy)
                }
                Section("Members") {
                    member(team.creator,name:team.data["creatorName"].string,status:"Creator",team:team)
                    ForEach(Array(team.members.enumerated()),id:\.offset) { _,entry in member(entry["npub"].string,name:entry["name"].string,status:entry["status"].string.capitalized,team:team) }
                }
                if team.creator == app.identity.npub {
                    Section("Manage private team") {
                        TextField("Team name",text:$name).focused($editing,equals:"name").accessibilityIdentifier("privateTeamEditName")
                        Button("Save name") { perform { try await service.rename(team,name:name,identity:app.identity) } }.disabled(service.busy || name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityIdentifier("privateTeamRename")
                        TextField("New teammate npubs",text:$members,axis:.vertical).focused($editing,equals:"members").textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("privateTeamAddInput")
                        Button("Invite teammates") { perform { try await service.add(to:team,members:members,creatorName:app.learner.name,identity:app.identity);members="" } }.disabled(service.busy || members.isEmpty).accessibilityIdentifier("privateTeamAdd")
                    }
                }
                Button(team.creator == app.identity.npub ? "Delete private team" : "Leave private team",role:.destructive) { removing=true }.disabled(service.busy)
            } else { Text("This private team is no longer available.");Button("Back to private teams") { dismiss() } }
            if service.busy { ProgressView("Updating private team…") }
            if let error=service.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle(team?.name ?? "Private team").toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { editing=nil } } }
            .task(id:id) { name=team?.name ?? "";if let team { try? await service.loadProgress(team,identity:app.identity) } }
            .onDisappear { service.cancel() }
            .confirmationDialog("\(team?.creator == app.identity.npub ? "Delete" : "Leave") this private team?",isPresented:$removing,titleVisibility:.visible) {
                if let team { Button(team.creator == app.identity.npub ? "Delete private team" : "Leave private team",role:.destructive) { perform { try await service.leave(team,identity:app.identity);dismiss() } } }
            }
    }
    private func member(_ npub:String,name:String,status:String,team:PrivateTeam) -> some View {
        let data=npub == app.identity.npub ? LearningTeams.snapshot(app.learner) : service.progressTeamID == team.id ? service.progress[npub] ?? .null : .null
        let row=LearningTeams.progressRow(member:npub,data:data,creator:npub == team.creator)
        return VStack(alignment:.leading,spacing:6) {
            Text(row["name"].string.isEmpty ? (name.isEmpty ? String(npub.prefix(20))+"…" : name) : row["name"].string).font(.headline)
            Text(npub).font(.caption).textSelection(.enabled);Text(status).font(.caption)
            if data != .null {
                Text("\(LearningLanguages.names[row["targetLang"].string] ?? row["targetLang"].string) · \(row["level"].string)")
                Text("\(row["totalXp"].number.formatted()) total XP · \(row["streak"].number.formatted()) day streak")
                if row["score"] != .null { Text("Score: \(row["score"].number.formatted())/100 · \(row["scoreLevel"].string)") }
                ProgressView(value:max(0,min(100,row["progressPercent"].number)),total:100)
                Text("\(row["dailyXp"].number.formatted()) / \(row["dailyGoalXp"].number.formatted()) daily XP")
                Text("Companion: \(row["companion"]["name"].string.isEmpty ? row["companion"]["type"].string : row["companion"]["name"].string) · Level \(row["companion"]["level"].number.formatted()) · \(row["companion"]["health"].number.formatted())% health").font(.footnote)
            } else { Text("No progress shared with this team yet.").font(.footnote) }
        }
    }
    private func perform(_ action:@escaping @MainActor () async throws -> Void) { editing=nil;Task { try? await action() } }
}
