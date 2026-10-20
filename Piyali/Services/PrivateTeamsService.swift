import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import NostrSDK

@MainActor final class PrivateTeamsService:ObservableObject {
    @Published private(set) var teams:[PrivateTeam]=[]
    @Published private(set) var invites:[PrivateTeamInvite]=[]
    @Published private(set) var progress:[String:JSONValue]=[:]
    @Published private(set) var progressTeamID:String?
    @Published private(set) var busy=false
    @Published var error:String?
    private let injected:Firestore?
    private var account=""
    private var generation=UUID()
    private var pending:Task<Void,Error>?
    init(database:Firestore? = nil) {
        #if DEBUG
        injected=database ?? PrivateTeamsUIEmulator.configured()
        #else
        injected=database
        #endif
    }
    func cancel(clear:Bool = false) { generation=UUID();pending?.cancel();pending=nil;busy=false;if clear { account="";teams=[];invites=[];progress=[:];progressTeamID=nil;error=nil } }
    private func check(_ identity:IdentityService,_ owner:String,_ version:UUID) throws { try Task.checkCancellation();guard identity.npub == owner,account == owner,generation == version else { throw CancellationError() } }
    private func run(_ identity:IdentityService,_ action:@escaping @MainActor (Firestore,String,UUID) async throws -> Void) async throws {
        guard !busy,!identity.npub.isEmpty else { throw AppError.message("Wait for the current team request to finish.") }
        let owner=identity.npub;if account != owner { cancel(clear:true);account=owner }
        let version=generation;busy=true;error=nil
        let task=Task { @MainActor in
            let db:Firestore
            if let injected=self.injected { db=injected }
            else {
                guard FirebaseService.shared.configured else { throw AppError.message("Connect Firebase to use private teams. Your public Nostr teams remain available.") }
                try await FirebaseIdentityService.shared.ensure(identity);try self.check(identity,owner,version)
                guard Auth.auth().currentUser?.uid == owner else { throw CancellationError() };db=Firestore.firestore()
            }
            try await action(db,owner,version)
        };pending=task
        defer { if generation == version { busy=false;pending=nil } }
        do { try await withTaskCancellationHandler { try await task.value } onCancel:{ task.cancel() } }
        catch { if generation == version,!(error is CancellationError) { self.error=(error as? PrivateTeams.Failure)?.localizedDescription ?? (error as? AppError)?.localizedDescription ?? "The private team request could not be completed. Refresh to check its current state." };throw error }
    }
    private nonisolated static func json(_ data:[String:Any]) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self,from:JSONSerialization.data(withJSONObject:FirebaseService.normalized(data))) }
    private nonisolated static func fields(_ value:JSONValue) throws -> [String:Any] { guard let fields=try JSONSerialization.jsonObject(with:Data(value.json.utf8)) as? [String:Any] else { throw PrivateTeams.Failure.invalidRecord };return fields }
    private nonisolated static func team(_ db:Firestore,_ creator:String,_ id:String) -> DocumentReference { db.collection("users").document(creator).collection("teams").document(id) }
    private nonisolated static func invite(_ db:Firestore,_ member:String,_ id:String) -> DocumentReference { db.collection("users").document(member).collection("teamInvites").document(id) }
    private func members(_ text:String,owner:String) throws -> [String] {
        let values=text.components(separatedBy:CharacterSet(charactersIn:",; \n\t")).filter { !$0.isEmpty }
        guard values.allSatisfy({ PublicKey(npub:$0) != nil && $0 != owner }) else { throw PrivateTeams.Failure.invalidMembers };return values
    }
    private func load(_ db:Firestore,_ owner:String,_ identity:IdentityService,_ version:UUID) async throws {
        async let own=db.collection("users").document(owner).collection("teams").getDocuments(source:.server)
        async let receivedRequest=db.collection("users").document(owner).collection("teamInvites").getDocuments(source:.server)
        let (owned,received)=try await (own,receivedRequest);try check(identity,owner,version)
        var result:[String:PrivateTeam]=[:]
        for doc in owned.documents { if let team=try? PrivateTeam(id:doc.documentID,creator:owner,data:Self.json(doc.data())) { result[team.id]=team } }
        let invitations=received.documents.compactMap { try? PrivateTeamInvite(id:$0.documentID,data:Self.json($0.data())) }
        for invitation in invitations where invitation.status == "accepted" && invitation.creator != owner {
            do {
                let snapshot=try await Self.team(db,invitation.creator,invitation.teamID).getDocument(source:.server);try check(identity,owner,version)
                if let fields=snapshot.data(),let team=try? PrivateTeam(id:invitation.teamID,creator:invitation.creator,data:Self.json(fields)),team.members.contains(where:{ $0["npub"].string == owner && $0["status"].string == "accepted" }) { result[team.id]=team }
            } catch is CancellationError { throw CancellationError() } catch { /* A deleted or revoked invitation cannot grant access to its old team. */ }
        }
        try check(identity,owner,version);teams=result.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending };invites=invitations.filter { $0.status == "pending" }
    }
    func refresh(identity:IdentityService) async throws { try await run(identity) { db,owner,version in try await self.load(db,owner,identity,version) } }
    func create(name:String,members:String,creatorName:String,identity:IdentityService) async throws {
        try await run(identity) { db,owner,version in
            let name=try PrivateTeams.name(name),members=try self.members(members,owner:owner),id=UUID().uuidString.lowercased(),stamp=WebProgressContract.iso(Date())
            let base:JSONValue = .object(["teamName":.string(name),"creatorName":.string(String(creatorName.prefix(80))),"createdBy":.string(owner),"createdAt":.string(stamp),"members":.array([])])
            let added=try PrivateTeams.adding(members,to:base,creator:owner,now:Date()),teamRef=Self.team(db,owner,id),batch=db.batch()
            batch.setData(try Self.fields(added.team),forDocument:teamRef)
            for (member,entry) in added.invites { batch.setData(try Self.fields(Self.invitation(id:id,name:name,owner:owner,creatorName:creatorName,entry:entry)),forDocument:Self.invite(db,member,"team_"+id)) }
            try self.check(identity,owner,version);try await batch.commit();try self.check(identity,owner,version);try await self.load(db,owner,identity,version)
        }
    }
    private nonisolated static func invitation(id:String,name:String,owner:String,creatorName:String,entry:JSONValue) -> JSONValue {
        .object(["teamId":.string(id),"teamName":.string(name),"creatorNpub":.string(owner),"invitedBy":.string(owner),"invitedByName":.string(String(creatorName.prefix(80))),"status":.string("pending"),"createdAt":entry["addedAt"],"member":entry])
    }
    func add(to team:PrivateTeam,members:String,creatorName:String,identity:IdentityService) async throws {
        try await run(identity) { db,owner,version in
            guard team.creator == owner else { throw PrivateTeams.Failure.creatorOnly };let members=try self.members(members,owner:owner),ref=Self.team(db,owner,team.teamID)
            _=try await db.runTransaction { tx,error -> Any? in
                do {
                    guard let fields=try tx.getDocument(ref).data() else { throw PrivateTeams.Failure.missingTeam }
                    let current=try PrivateTeam(id:team.teamID,creator:owner,data:Self.json(fields)),added=try PrivateTeams.adding(members,to:current.data,creator:owner,now:Date())
                    tx.updateData(["members":try Self.fields(added.team)["members"]!],forDocument:ref)
                    for (member,entry) in added.invites { tx.setData(try Self.fields(Self.invitation(id:team.teamID,name:current.name,owner:owner,creatorName:creatorName,entry:entry)),forDocument:Self.invite(db,member,"team_"+team.teamID)) };return true
                } catch let caught { error?.pointee=caught as NSError;return nil }
            };try self.check(identity,owner,version);try await self.load(db,owner,identity,version)
        }
    }
    func rename(_ team:PrivateTeam,name:String,identity:IdentityService) async throws {
        try await run(identity) { db,owner,version in
            guard team.creator == owner else { throw PrivateTeams.Failure.creatorOnly };let name=try PrivateTeams.name(name),ref=Self.team(db,owner,team.teamID)
            _=try await db.runTransaction { tx,error -> Any? in
                do {
                    guard let fields=try tx.getDocument(ref).data() else { throw PrivateTeams.Failure.missingTeam };let current=try PrivateTeam(id:team.teamID,creator:owner,data:Self.json(fields))
                    let refs=current.members.map { Self.invite(db,$0["npub"].string,"team_"+team.teamID) }
                    let snapshots=try refs.map { try tx.getDocument($0) }
                    tx.updateData(["teamName":name],forDocument:ref)
                    for (invite,snapshot) in zip(refs,snapshots) where snapshot.exists { tx.updateData(["teamName":name],forDocument:invite) };return true
                } catch let caught { error?.pointee=caught as NSError;return nil }
            };try self.check(identity,owner,version);try await self.load(db,owner,identity,version)
        }
    }
    func respond(_ invite:PrivateTeamInvite,accept:Bool,identity:IdentityService) async throws {
        try await run(identity) { db,owner,version in
            let invitation=Self.invite(db,owner,invite.id),ref=Self.team(db,invite.creator,invite.teamID)
            _=try await db.runTransaction { tx,error -> Any? in
                do {
                    guard let fields=try tx.getDocument(invitation).data() else { throw PrivateTeams.Failure.missingMember };let actual=try PrivateTeamInvite(id:invite.id,data:Self.json(fields))
                    guard actual.creator == invite.creator,actual.teamID == invite.teamID,actual.status != "rejected" else { throw PrivateTeams.Failure.missingMember }
                    let snapshot=try tx.getDocument(ref)
                    if let fields=snapshot.data() {
                        let team=try PrivateTeam(id:invite.teamID,creator:invite.creator,data:Self.json(fields)),changed=try PrivateTeams.responding(team.data,member:owner,accept:accept),raw=try Self.fields(changed)
                        tx.updateData(["members":raw["members"]!,"_memberChange":raw["_memberChange"]!],forDocument:ref)
                    } else if accept { throw PrivateTeams.Failure.missingTeam }
                    tx.updateData(["status":accept ? "accepted" : "rejected"],forDocument:invitation);return true
                } catch let caught { error?.pointee=caught as NSError;return nil }
            };try self.check(identity,owner,version);try await self.load(db,owner,identity,version)
        }
    }
    func leave(_ team:PrivateTeam,identity:IdentityService) async throws {
        try await run(identity) { db,owner,version in
            let ref=Self.team(db,team.creator,team.teamID),invitation=Self.invite(db,owner,"team_"+team.teamID)
            _=try await db.runTransaction { tx,error -> Any? in
                do {
                    guard let fields=try tx.getDocument(ref).data() else { tx.deleteDocument(invitation);return true }
                    let current=try PrivateTeam(id:team.teamID,creator:team.creator,data:Self.json(fields))
                    if owner == team.creator {
                        let refs=current.members.map { Self.invite(db,$0["npub"].string,"team_"+team.teamID) }
                        let snapshots=try refs.map { try tx.getDocument($0) }
                        tx.deleteDocument(ref)
                        for (invite,snapshot) in zip(refs,snapshots) where snapshot.exists { tx.deleteDocument(invite) }
                    } else {
                        let changed=try PrivateTeams.responding(current.data,member:owner,accept:false),raw=try Self.fields(changed)
                        tx.updateData(["members":raw["members"]!,"_memberChange":raw["_memberChange"]!],forDocument:ref);tx.deleteDocument(invitation)
                        tx.deleteDocument(ref.collection("progress").document(owner))
                    };return true
                } catch let caught { error?.pointee=caught as NSError;return nil }
            };try self.check(identity,owner,version);try await self.load(db,owner,identity,version);self.progress=[:]
        }
    }
    func loadProgress(_ team:PrivateTeam,identity:IdentityService) async throws {
        try await run(identity) { db,owner,version in
            let docs=try await Self.team(db,team.creator,team.teamID).collection("progress").getDocuments(source:.server);try self.check(identity,owner,version)
            self.progress=try Dictionary(uniqueKeysWithValues:docs.documents.map { ($0.documentID,try Self.json($0.data())) });self.progressTeamID=team.id
        }
    }
    func shareProgress(_ learner:LearnerState,in team:PrivateTeam,identity:IdentityService) async throws {
        try await run(identity) { db,owner,version in
            try self.check(identity,owner,version);try await Self.team(db,team.creator,team.teamID).collection("progress").document(owner).setData(Self.fields(LearningTeams.snapshot(learner)));try self.check(identity,owner,version)
            if self.progressTeamID != team.id { self.progress=[:];self.progressTeamID=team.id };self.progress[owner]=LearningTeams.snapshot(learner)
        }
    }
}
