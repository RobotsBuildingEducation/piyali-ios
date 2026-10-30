import Foundation
import FirebaseFirestore
import FirebaseAuth
import NostrSDK

/// Firebase mirrors of signed public rosters, alongside legacy private teams.
/// Public learning snapshots remain Nostr events; private learner roots are never shared.
@MainActor final class TeamsMirrorService {
    struct Records{var owned:[JSONValue]=[],joined:[JSONValue]=[],invites:[JSONValue]=[]}
    private let injected:Firestore?
    private var listeners:[ListenerRegistration]=[]
    private var watchGeneration=UUID()
    init(database:Firestore?=nil){
        #if DEBUG
        injected=database ?? PrivateTeamsUIEmulator.configured()
        #else
        injected=database
        #endif
    }
    private func database(_ identity:IdentityService,owner:String)async throws->Firestore{
        guard identity.npub == owner,!owner.isEmpty else{throw CancellationError()}
        if let injected{return injected}
        guard FirebaseService.shared.configured else{throw AppError.message("Connect Firebase to load team invitations and roster copies.")}
        try await FirebaseIdentityService.shared.ensure(identity);guard identity.npub == owner,Auth.auth().currentUser?.uid == owner else{throw CancellationError()};return Firestore.firestore()
    }
    private nonisolated static func json(_ fields:[String:Any])throws->JSONValue{try JSONDecoder().decode(JSONValue.self,from:JSONSerialization.data(withJSONObject:FirebaseService.normalized(fields)))}
    private nonisolated static func fields(_ json:JSONValue)throws->[String:Any]{try JSONSerialization.jsonObject(with:Data(json.json.utf8)) as! [String:Any]}
    private nonisolated static func ref(_ db:Firestore,_ owner:String,_ id:String)->DocumentReference{db.collection("users").document(owner).collection("teams").document(id)}
    private nonisolated static func invite(_ db:Firestore,_ member:String,_ id:String)->DocumentReference{db.collection("users").document(member).collection("teamInvites").document("team_"+id)}
    private nonisolated static func valid(_ value:JSONValue,_ id:String,_ creator:String)->Bool{PrivateTeams.identifier(id) && PrivateTeams.npub(creator) && value["createdBy"].string == creator && value["nostr"]["id"].string == id && value["members"].array.allSatisfy{PrivateTeams.npub($0["npub"].string)}}
    /// A previously denied watch-based get can remain stale across a new grant.
    /// Recheck it with a server transaction; the same rules still decide access.
    private nonisolated static func serverFields(_ reference:DocumentReference,database:Firestore)async throws->[String:Any]?{
        do{return try await reference.getDocument(source:.server).data()}
        catch let denied as NSError where denied.domain == FirestoreErrorDomain && denied.code == FirestoreErrorCode.permissionDenied.rawValue{
            return try await database.runTransaction{transaction,error->Any? in
                do{return try transaction.getDocument(reference).data() ?? NSNull()}
                catch let caught{error?.pointee=caught as NSError;return nil}
            } as? [String:Any]
        }
    }
    /// The grant's exact roster entry makes each membership a distinct listener
    /// target, including a re-invitation after an earlier denied document watch.
    nonisolated static func memberQuery(_ db:Firestore,creator:String,id:String,member:String,stamp:String)->Query{
        db.collection("users").document(creator).collection("teams")
            .whereField(FieldPath.documentID(),isEqualTo:id)
            .whereField("members",arrayContains:["npub":member,"status":"accepted","addedAt":stamp,"name":""])
            .limit(to:1)
    }
    private nonisolated static func memberFields(_ db:Firestore,invite:JSONValue,member:String)async throws->[String:Any]?{
        let creator=invite["creatorNpub"].string,id=invite["teamId"].string,stamp=invite["createdAt"].string
        if !stamp.isEmpty,let document=try await memberQuery(db,creator:creator,id:id,member:member,stamp:stamp).getDocuments(source:.server).documents.first{return document.data()}
        return try await serverFields(ref(db,creator,id),database:db)
    }
    func read(identity:IdentityService)async throws->Records{
        let owner=identity.npub,db=try await database(identity,owner:owner)
        async let owned=db.collection("users").document(owner).collection("teams").getDocuments(source:.server)
        async let invitations=db.collection("users").document(owner).collection("teamInvites").getDocuments(source:.server)
        let(a,b)=try await(owned,invitations);guard identity.npub == owner else{throw CancellationError()};var result=Records()
        for doc in a.documents{let v=try Self.json(doc.data());if Self.valid(v,doc.documentID,owner){result.owned.append(v.setting("id",.string(doc.documentID)).setting("isCreator",.bool(true)))}}
        for doc in b.documents{
            let value=try Self.json(doc.data());guard value["nostr"] != .null,PrivateTeams.identifier(value["teamId"].string),PrivateTeams.npub(value["creatorNpub"].string) else{continue};let invitation=value.setting("id",.string(doc.documentID));result.invites.append(invitation)
            if value["status"].string == "accepted",value["creatorNpub"].string != owner,let fields=try? await Self.memberFields(db,invite:value,member:owner),let team=try? Self.json(fields),Self.valid(team,value["teamId"].string,value["creatorNpub"].string){result.joined.append(team.setting("id",value["teamId"]).setting("isCreator",.bool(false)))}
        };guard identity.npub == owner else{throw CancellationError()};return result
    }
    nonisolated static func roster(id:String,name:String,creator:String,creatorName:String,members:[String],stamp:String)->JSONValue{
        .object(["teamName":.string(name),"creatorName":.string(creatorName),"createdBy":.string(creator),"createdAt":.string(stamp),"members":.array(members.map{.object(["npub":.string($0),"status":.string("accepted"),"addedAt":.string(stamp),"name":.string("")])}),"nostr":.object(["id":.string(id),"identifier":.string(LearningTeams.teamIdentifier(id)),"relays":.array(LearningTeams.relays.map(JSONValue.string))])])
    }
    private nonisolated static func invitation(_ roster:JSONValue,id:String,creatorName:String,stamp:String)->JSONValue{.object(["teamId":.string(id),"teamName":roster["teamName"],"creatorNpub":roster["createdBy"],"invitedBy":roster["createdBy"],"invitedByName":.string(creatorName),"nostr":roster["nostr"],"status":.string("accepted"),"createdAt":.string(stamp)])}
    func create(id:String,name:String,members:[String],creatorName:String,identity:IdentityService)async throws{
        let owner=identity.npub,db=try await database(identity,owner:owner),stamp=WebProgressContract.iso(Date()),roster=Self.roster(id:id,name:name,creator:owner,creatorName:creatorName,members:members,stamp:stamp)
        guard Self.valid(roster,id,owner),members.count<=256,members.allSatisfy({PublicKey(npub:$0) != nil && $0 != owner}) else{throw PrivateTeams.Failure.invalidRecord}
        let batch=db.batch();batch.setData(try Self.fields(roster),forDocument:Self.ref(db,owner,id));for member in members{batch.setData(try Self.fields(Self.invitation(roster,id:id,creatorName:creatorName,stamp:stamp)),forDocument:Self.invite(db,member,id))};guard identity.npub == owner else{throw CancellationError()};try await batch.commit()
    }
    func rename(id:String,name:String,identity:IdentityService)async throws->Bool{
        let owner=identity.npub,db=try await database(identity,owner:owner),ref=Self.ref(db,owner,id)
        let changed=try await db.runTransaction{tx,error->Any? in do{guard let fields=try tx.getDocument(ref).data() else{return true};let roster=try Self.json(fields);guard Self.valid(roster,id,owner) else{throw PrivateTeams.Failure.invalidRecord};let refs=roster["members"].array.map{Self.invite(db,$0["npub"].string,id)},snapshots=try refs.map{try tx.getDocument($0)};tx.updateData(["teamName":name],forDocument:ref);for(r,s)in zip(refs,snapshots) where s.exists{tx.updateData(["teamName":name],forDocument:r)};return true}catch let caught{error?.pointee=caught as NSError;return nil}}
        guard identity.npub == owner else{throw CancellationError()};return changed as? Bool ?? false
    }
    func add(id:String,members:[String],creatorName:String,identity:IdentityService)async throws->Bool{
        let owner=identity.npub,db=try await database(identity,owner:owner),ref=Self.ref(db,owner,id)
        let changed=try await db.runTransaction{tx,error->Any? in do{guard let fields=try tx.getDocument(ref).data() else{return false};let roster=try Self.json(fields);guard Self.valid(roster,id,owner) else{throw PrivateTeams.Failure.invalidRecord};let stamp=WebProgressContract.iso(Date()),existing=Set(roster["members"].array.map{$0["npub"].string}+[owner]);guard members.allSatisfy({PublicKey(npub:$0) != nil && !existing.contains($0)}) else{throw PrivateTeams.Failure.invalidMembers};let entries=members.map{JSONValue.object(["npub":.string($0),"status":.string("accepted"),"addedAt":.string(stamp),"name":.string("")])};tx.updateData(["members":try Self.fields(roster.setting("members",.array(roster["members"].array+entries)))["members"]!],forDocument:ref);for member in members{tx.setData(try Self.fields(Self.invitation(roster,id:id,creatorName:creatorName,stamp:stamp)),forDocument:Self.invite(db,member,id))};return true}catch let caught{error?.pointee=caught as NSError;return nil}}
        guard identity.npub == owner else{throw CancellationError()};return changed as? Bool ?? false
    }
    func delete(id:String,identity:IdentityService)async throws{
        let owner=identity.npub,db=try await database(identity,owner:owner),ref=Self.ref(db,owner,id)
        _=try await db.runTransaction{tx,error->Any? in do{guard let fields=try tx.getDocument(ref).data() else{return true};let roster=try Self.json(fields);guard Self.valid(roster,id,owner) else{throw PrivateTeams.Failure.invalidRecord};let refs=roster["members"].array.map{Self.invite(db,$0["npub"].string,id)},snapshots=try refs.map{try tx.getDocument($0)};tx.deleteDocument(ref);for(r,s)in zip(refs,snapshots) where s.exists{tx.deleteDocument(r)};return true}catch let caught{error?.pointee=caught as NSError;return nil}}
    }
    func leave(creator:String,id:String,identity:IdentityService)async throws{
        let owner=identity.npub,db=try await database(identity,owner:owner),invite=Self.invite(db,owner,id),ref=Self.ref(db,creator,id)
        // Relay-only teams may have no readable Firebase mirror.
        if let fields=try? await Self.serverFields(ref,database:db),let value=try? Self.json(fields),value["members"].array.contains(where:{$0["npub"].string == owner}){
            _=try await db.runTransaction{tx,error->Any? in do{guard let fields=try tx.getDocument(ref).data() else{tx.deleteDocument(invite);return true};let changed=try PrivateTeams.responding(Self.json(fields),member:owner,accept:false),raw=try Self.fields(changed);tx.updateData(["members":raw["members"]!,"_memberChange":raw["_memberChange"]!],forDocument:ref);tx.deleteDocument(invite);return true}catch let caught{error?.pointee=caught as NSError;return nil}}
        }else{try await invite.delete()}
    }
    func respond(_ invite:JSONValue,accept:Bool,identity:IdentityService)async throws{
        let owner=identity.npub,creator=invite["creatorNpub"].string,id=invite["teamId"].string
        guard PrivateTeams.npub(creator),PrivateTeams.identifier(id),invite["id"].string=="team_"+id,invite["nostr"] != .null else{throw PrivateTeams.Failure.invalidRecord}
        let db=try await database(identity,owner:owner),invitation=Self.invite(db,owner,id),ref=Self.ref(db,creator,id)
        _=try await db.runTransaction{tx,error->Any? in do{
            guard let fields=try tx.getDocument(invitation).data() else{throw PrivateTeams.Failure.missingMember}
            let actual=try Self.json(fields);guard actual["creatorNpub"].string==creator,actual["teamId"].string==id,["pending","accepted"].contains(actual["status"].string) else{throw PrivateTeams.Failure.missingMember}
            if let fields=try tx.getDocument(ref).data(){let roster=try Self.json(fields);guard Self.valid(roster,id,creator) else{throw PrivateTeams.Failure.invalidRecord};let changed=try PrivateTeams.responding(roster,member:owner,accept:accept),raw=try Self.fields(changed);tx.updateData(["members":raw["members"]!,"_memberChange":raw["_memberChange"]!],forDocument:ref)}else if accept{throw PrivateTeams.Failure.missingTeam}
            tx.updateData(["status":accept ? "accepted":"rejected"],forDocument:invitation);return true
        }catch let caught{error?.pointee=caught as NSError;return nil}}
        guard identity.npub==owner else{throw CancellationError()}
    }
    func stopWatching(){watchGeneration=UUID();listeners.forEach{$0.remove()};listeners=[]}
    func watch(_ teams:[JSONValue],invites:[JSONValue]=[],identity:IdentityService,onChange:@escaping @MainActor()->Void)async{
        stopWatching();let token=watchGeneration,owner=identity.npub
        guard let db=try? await database(identity,owner:owner),token==watchGeneration,identity.npub==owner else{return}
        for collection in ["teams","teamInvites"]{
            var first=true
            listeners.append(db.collection("users").document(owner).collection(collection).addSnapshotListener{[weak self] snapshot,error in
                Task{@MainActor in guard let self,self.watchGeneration==token,identity.npub==owner,snapshot != nil,error==nil else{return};if first{first=false;return};onChange()}
            })
        }
        for team in teams where team["createdBy"].string != owner{
            let creator=team["createdBy"].string,id=team["id"].string;guard PrivateTeams.npub(creator),PrivateTeams.identifier(id) else{continue};var first=true
            if team["nostr"] != .null,let invite=invites.first(where:{$0["creatorNpub"].string==creator && $0["teamId"].string==id}),!invite["createdAt"].string.isEmpty{
                listeners.append(Self.memberQuery(db,creator:creator,id:id,member:owner,stamp:invite["createdAt"].string).addSnapshotListener{[weak self] snapshot,error in
                    Task{@MainActor in guard let self,self.watchGeneration==token,identity.npub==owner,snapshot != nil,error==nil else{return};if first{first=false;return};onChange()}
                })
            }else{
                listeners.append(Self.ref(db,creator,id).addSnapshotListener{[weak self] snapshot,error in
                    Task{@MainActor in guard let self,self.watchGeneration==token,identity.npub==owner,snapshot != nil,error==nil else{return};if first{first=false;return};onChange()}
                })
            }
        }
    }
    func prune(_ ids:[String],identity:IdentityService)async{let owner=identity.npub;guard let db=try? await database(identity,owner:owner) else{return};for id in ids where identity.npub == owner{try? await Self.invite(db,owner,id).delete()}}
}
