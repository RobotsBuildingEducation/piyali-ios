import Foundation
import NostrSDK

struct TeamsPanelSnapshot:Equatable {
    var teams:[JSONValue]=[],invites:[JSONValue]=[],rows:[String:[JSONValue]]=[:]
    var warning:String?
}
@MainActor protocol TeamsPanelAccess:AnyObject {
    func load(_ app:AppModel)async throws->TeamsPanelSnapshot
    func create(name:String,members:[String],app:AppModel)async throws
    func rename(_ team:JSONValue,name:String,app:AppModel)async throws->Bool
    func add(_ team:JSONValue,members:[String],app:AppModel)async throws->Bool
    func remove(_ team:JSONValue,app:AppModel)async throws
    func respond(_ invite:JSONValue,accept:Bool,app:AppModel)async throws
    func publish(_ app:AppModel)async throws
    func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]
    func cancel()
    func watch(_ teams:[JSONValue],app:AppModel,onChange:@escaping @MainActor()->Void)async
    func watchSnapshot(_ snapshot:TeamsPanelSnapshot,app:AppModel,onChange:@escaping @MainActor()->Void)async
    func watchInvites(_ app:AppModel,onChange:@escaping @MainActor([JSONValue])->Void)async
}
extension TeamsPanelAccess {
    func watch(_ teams:[JSONValue],app:AppModel,onChange:@escaping @MainActor()->Void)async{}
    func watchSnapshot(_ snapshot:TeamsPanelSnapshot,app:AppModel,onChange:@escaping @MainActor()->Void)async{await watch(snapshot.teams,app:app,onChange:onChange)}
    func watchInvites(_ app:AppModel,onChange:@escaping @MainActor([JSONValue])->Void)async{}
}
@MainActor final class LiveTeamsPanelAccess:TeamsPanelAccess {
    let service:NostrTeamsService,mirror:TeamsMirrorService,legacy:PrivateTeamsService
    let policy:TeamsPanelPolicy?
    private var privateTeams:[PrivateTeam]=[]
    private var mirroredInvites:[JSONValue]=[]
    init(service:NostrTeamsService,mirror:TeamsMirrorService?=nil,legacy:PrivateTeamsService?=nil){self.service=service;self.mirror=mirror ?? TeamsMirrorService();self.legacy=legacy ?? PrivateTeamsService();policy=try? TeamsPanelPolicy()}
    private func publicTeam(_ value:JSONValue)throws->LearningTeam{guard let team=service.teams.first(where:{$0.teamID == value["id"].string && PublicKey(hex:$0.creator)?.npub == value["createdBy"].string}) else{throw AppError.message("This team is no longer available. Refresh teams.")};return team}
    private func privateTeam(_ value:JSONValue)throws->PrivateTeam{guard let team=privateTeams.first(where:{$0.teamID == value["id"].string && $0.creator == value["createdBy"].string}) else{throw PrivateTeams.Failure.missingTeam};return team}
    static func key(_ team:JSONValue)->String{team["createdBy"].string+":"+team["id"].string}
    private func publicRecord(_ team:LearningTeam,viewer:String)->JSONValue{
        let creator=PublicKey(hex:team.creator)?.npub ?? ""
        return .object(["id":.string(team.teamID),"name":.string(team.name),"createdBy":.string(creator),"identifier":.string(team.event.tag("d")),"createdAt":.number(Double(team.event.created_at)),"members":.array(team.members.compactMap{PublicKey(hex:$0)?.npub}.map(JSONValue.string))])
    }
    func load(_ app:AppModel)async throws->TeamsPanelSnapshot {
        let owner=app.identity.npub;mirroredInvites=[]
        async let publicRead:Void=service.refresh(identity:app.identity)
        async let mirrorRead:Result<TeamsMirrorService.Records,Error>=Result{try await mirror.read(identity:app.identity)}
        try? await legacy.refresh(identity:app.identity);await publicRead;let mirrors=await mirrorRead
        guard owner == app.identity.npub else{throw CancellationError()};privateTeams=legacy.teams
        var owned:[JSONValue]=[],joined:[JSONValue]=[],invites=legacy.invites.map{$0.data.setting("id",.string($0.id))},warning:String?
        switch mirrors{case .success(let r):owned=r.owned;joined=r.joined;mirroredInvites=r.invites;invites += r.invites;case .failure(let e):warning=e.localizedDescription}
        for team in privateTeams{let value=team.data.setting("id",.string(team.teamID)).setting("createdBy",.string(team.creator)).setting("isCreator",.bool(team.creator == owner));if team.creator == owner{owned.append(value)}else{joined.append(value)}}
        guard let policy else{throw PracticeRecipeFailure.unavailable}
        let merged=try policy.run("reconcile",.object(["createdTeams":.array(owned),"memberTeams":.array(joined),"nostrTeams":service.error == nil ? .array(service.teams.map{publicRecord($0,viewer:owner)}):.null,"userNpub":.string(owner)]))
        await mirror.prune(merged["pruned"].array.map(\.string),identity:app.identity)
        var records=merged["teams"].array,rows:[String:[JSONValue]]=[:]
        // Acknowledged relay-only groups remain visible while a refresh is unavailable.
        if service.error != nil{for team in service.teams{let input:JSONValue = .object(["nostrTeams":.array([publicRecord(team,viewer:owner)]),"userNpub":.string(owner)]);for value in try policy.run("reconcile",input)["teams"].array where !records.contains(where:{Self.key($0)==Self.key(value)}){records.append(value)}}}
        for record in records {
            let key=Self.key(record)
            if record["nostr"] != .null,let team=try? publicTeam(record){rows[key]=team.members.map{service.row(member:$0,team:team,learner:app.learner,viewer:app.identity.hex)}}
            else if let team=try? privateTeam(record){try? await legacy.loadProgress(team,identity:app.identity);guard owner == app.identity.npub else{throw CancellationError()};let members=[team.creator]+team.members.filter{$0["status"].string == "accepted"}.map{$0["npub"].string};rows[key]=members.map{npub in LearningTeams.progressRow(member:npub,data:npub == owner ? LearningTeams.snapshot(app.learner):legacy.progress[npub] ?? .object([:]),creator:npub == team.creator)}}
        }
        return .init(teams:records,invites:invites,rows:rows,warning:warning ?? service.error ?? legacy.error)
    }
    func create(name:String,members:[String],app:AppModel)async throws{
        let owner=app.identity.npub,id=UUID().uuidString.replacingOccurrences(of:"-",with:"").lowercased()
        try await service.create(name:name,members:members.joined(separator:","),identity:app.identity,id:id,reload:false)
        do{guard app.identity.npub == owner else{throw CancellationError()};try await mirror.create(id:id,name:name,members:members,creatorName:app.learner.name,identity:app.identity)}catch{if app.identity.npub == owner,let team=service.teams.first(where:{$0.teamID == id}){try? await service.leave(team,identity:app.identity)};throw error}
    }
    func rename(_ team:JSONValue,name:String,app:AppModel)async throws->Bool{
        if team["nostr"] == .null{try await legacy.rename(privateTeam(team),name:name,identity:app.identity);return true}
        let value=try publicTeam(team);try await service.rename(value,name:name,identity:app.identity);return (try? await mirror.rename(id:value.teamID,name:name,identity:app.identity)) ?? false
    }
    func add(_ team:JSONValue,members:[String],app:AppModel)async throws->Bool{
        if team["nostr"] == .null{try await legacy.add(to:privateTeam(team),members:members.joined(separator:","),creatorName:app.learner.name,identity:app.identity);return true}
        let value=try publicTeam(team);try await service.addMembers(value,members:members.joined(separator:","),identity:app.identity);return (try? await mirror.add(id:value.teamID,members:members,creatorName:app.learner.name,identity:app.identity)) ?? false
    }
    func remove(_ team:JSONValue,app:AppModel)async throws{
        if team["nostr"] == .null{try await legacy.leave(privateTeam(team),identity:app.identity);return}
        let value=try publicTeam(team);try await service.leave(value,identity:app.identity)
        if team["isCreator"].boolean{try await mirror.delete(id:value.teamID,identity:app.identity)}else{try await mirror.leave(creator:team["createdBy"].string,id:value.teamID,identity:app.identity)}
    }
    func respond(_ invite:JSONValue,accept:Bool,app:AppModel)async throws{if invite["nostr"] != .null{try await mirror.respond(invite,accept:accept,identity:app.identity)}else{try await legacy.respond(PrivateTeamInvite(id:invite["id"].string,data:invite),accept:accept,identity:app.identity)}}
    func watch(_ teams:[JSONValue],app:AppModel,onChange:@escaping @MainActor()->Void)async{await mirror.watch(teams,invites:mirroredInvites,identity:app.identity,onChange:onChange)}
    func watchSnapshot(_ snapshot:TeamsPanelSnapshot,app:AppModel,onChange:@escaping @MainActor()->Void)async{await mirror.watch(snapshot.teams,invites:snapshot.invites,identity:app.identity,includeInvites:false,onChange:onChange)}
    func watchInvites(_ app:AppModel,onChange:@escaping @MainActor([JSONValue])->Void)async{try? await mirror.watchInvitations(identity:app.identity,onChange:onChange)}
    func publish(_ app:AppModel)async throws{try await service.publishProgress(app.learner,identity:app.identity,reload:false)}
    func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]{await app.teamFeed.refresh(account:app.identity.npub,force:force);if let error=app.teamFeed.error{throw AppError.message(error)};return app.teamFeed.posts}
    func cancel(){mirror.stopWatching();mirror.stopWatchingInvitations();service.cancel();legacy.cancel()}
}

@MainActor final class TeamsPanelController:ObservableObject {
    @Published private(set) var snapshot=TeamsPanelSnapshot()
    @Published private(set) var posts:[CommunityPost]=[]
    @Published private(set) var loading=false
    @Published private(set) var working=false
    @Published private(set) var feedLoading=false
    @Published var error:String? {didSet{retainErrorOnWatch = error != nil}}
    @Published var sharingError:String?
    private let access:TeamsPanelAccess
    let policy:TeamsPanelPolicy?
    private var epoch=UUID(),work:Task<Void,Never>?,sharing:Task<Void,Never>?,refresh:Task<Void,Never>?,invitationWatch:Task<Void,Never>?
    private var owner="",ownerSession:UUID?,shareKey="",watchKey=""
    private var reloading=false,hasInitialSnapshot=false,closed=false,refreshNeeded=false,watchingInvites=false
    private var inviteRevision=0,retainErrorOnWatch=false
    init(access:TeamsPanelAccess,initial:TeamsPanelSnapshot = .init(),initialOwner:String=""){self.access=access;snapshot=initial;owner=initialOwner;hasInitialSnapshot = !initialOwner.isEmpty;policy=try? TeamsPanelPolicy()}
    private func owned(_ app:AppModel,_ token:UUID)->Bool {epoch == token && !closed && owner == app.identity.npub && ownerSession == app.identity.sessionRevision && !Task.isCancelled}
    private func bind(_ app:AppModel){
        if owner != app.identity.npub || ownerSession.map({$0 != app.identity.sessionRevision}) == true{cancel();snapshot = .init();posts=[];hasInitialSnapshot=false}
        owner=app.identity.npub;ownerSession=app.identity.sessionRevision;closed=false
    }
    func reload(_ app:AppModel,preservingError:Bool=false)async {
        if reloading,owner == app.identity.npub,ownerSession == app.identity.sessionRevision{refreshNeeded=true;return}
        bind(app);let token=epoch;reloading=true;loading = !preservingError && !hasInitialSnapshot;hasInitialSnapshot=false
        if !preservingError{error=nil}
        defer{if owned(app,token){reloading=false;loading=false;drainRefresh(app)}}
        installInvitations(app,token:token);let before=inviteRevision
        do{
            var value=try await access.load(app);guard owned(app,token) else{return}
            if inviteRevision != before{value.invites=snapshot.invites}
            snapshot=value;if let warning=value.warning{if !preservingError || !retainErrorOnWatch{error=warning;retainErrorOnWatch=false;showError(warning,app:app)}}else if !preservingError || !retainErrorOnWatch{error=nil}
            let grants=value.invites.filter{$0["nostr"] != .null && $0["status"].string == "accepted"}.map{$0["creatorNpub"].string+":"+$0["teamId"].string+":"+$0["createdAt"].string}.sorted()
            let key=owner+value.teams.map(LiveTeamsPanelAccess.key).sorted().joined(separator:",")+grants.joined(separator:",")
            if key != watchKey{watchKey=key;await access.watchSnapshot(value,app:app,onChange:{[weak self,weak app] in guard let self,let app,self.owned(app,token) else{return};self.requestRefresh(app)})}
            guard owned(app,token) else{return};scheduleSharing(app)
        }catch{if owned(app,token),!(error is CancellationError),!preservingError || !retainErrorOnWatch{self.error=error.localizedDescription;retainErrorOnWatch=false;showError(error.localizedDescription,app:app)}}
    }
    private func installInvitations(_ app:AppModel,token:UUID){
        guard !watchingInvites else{return};watchingInvites=true
        invitationWatch=Task{[weak self,weak app] in guard let self,let app,self.owned(app,token) else{return};await access.watchInvites(app,onChange:{[weak self,weak app] values in guard let self,let app,self.owned(app,token) else{return};self.applyInvites(values,app:app)})}
    }
    func applyInvites(_ values:[JSONValue],app:AppModel){
        guard !closed,owner == app.identity.npub,ownerSession == nil || ownerSession == app.identity.sessionRevision else{return}
        if ownerSession == nil{ownerSession=app.identity.sessionRevision}
        func grants(_ values:[JSONValue])->[String]{values.filter{$0["status"].string == "accepted"}.map{$0["creatorNpub"].string+":"+$0["teamId"].string+":"+$0["createdAt"].string}.sorted()}
        let changed=grants(values) != grants(snapshot.invites);inviteRevision += 1;snapshot.invites=values
        if changed{requestRefresh(app)}
    }
    private func requestRefresh(_ app:AppModel){refreshNeeded=true;drainRefresh(app)}
    private func drainRefresh(_ app:AppModel){
        guard refreshNeeded,!reloading,!working,!closed,refresh == nil else{return};let token=epoch
        refresh=Task{[weak self,weak app] in
            guard let self,let app else{return};defer{if self.epoch == token{self.refresh=nil}}
            while owned(app,token),refreshNeeded,!working,!reloading{refreshNeeded=false;await reload(app,preservingError:true)}
        }
    }
    func perform(_ app:AppModel,action:@escaping(TeamsPanelAccess)async throws->TeamsNotice?,errorTitle:String?=nil,onSuccess:@escaping()->Void={}){
        guard !working,!closed else{return};if owner.isEmpty{bind(app)};let token=epoch;guard owned(app,token) else{return}
        working=true;error=nil
        work=Task{[weak self] in
            guard let self else{return};defer{if owned(app,token){working=false;work=nil;drainRefresh(app)}}
            do{let message=try await action(access);guard owned(app,token) else{return};if let message{app.showTeamsNotice(message)};onSuccess();await reload(app)}
            catch{if owned(app,token),!(error is CancellationError){self.error=error.localizedDescription;showError(error.localizedDescription,app:app,title:errorTitle)}}
        }
    }
    private func showError(_ description:String,app:AppModel,title:String?=nil){let value=EntryCopy.ui(app.learner.support,"teams_view_error");app.showTeamsNotice(.init(title:title ?? (value.isEmpty || value == "teams_view_error" ? "Error":value),description:description,status:"error"))}
    func scheduleSharing(_ app:AppModel){
        guard !closed,owner == app.identity.npub,ownerSession == app.identity.sessionRevision else{return}
        guard snapshot.teams.contains(where:{$0["nostr"] != .null}) else{sharing?.cancel();shareKey="";return}
        let key=owner+LearningTeams.snapshot(app.learner).setting("updatedAt",.number(0)).canonicalJSON;guard key != shareKey else{return};shareKey=key;sharing?.cancel();let token=epoch
        sharing=Task{[weak self] in do{
            try await Task.sleep(for:.milliseconds(700));guard let self,self.owned(app,token) else{return};let progress=LearningTeams.snapshot(app.learner)
            for team in self.snapshot.teams{let key=LiveTeamsPanelAccess.key(team);if let index=self.snapshot.rows[key]?.firstIndex(where:{$0["npub"].string==self.owner}){self.snapshot.rows[key]?[index]=LearningTeams.progressRow(member:self.owner,data:progress,creator:team["createdBy"].string==self.owner)}}
            try await self.access.publish(app);guard self.owned(app,token) else{return};self.sharingError=nil
        }catch is CancellationError{}catch{if let self,self.owned(app,token){self.sharingError=error.localizedDescription}}}
    }
    func loadFeed(_ app:AppModel,force:Bool=false)async{
        guard !feedLoading,!closed else{return};if owner.isEmpty{bind(app)};let token=epoch;guard owned(app,token) else{return};feedLoading=true;error=nil
        defer{if owned(app,token){feedLoading=false}}
        do{let values=try await access.feed(app,force:force);guard owned(app,token) else{return};posts=values}catch{if owned(app,token),!(error is CancellationError){self.error=error.localizedDescription;retainErrorOnWatch=false}}
    }
    func cancel(){epoch=UUID();closed=true;work?.cancel();sharing?.cancel();refresh?.cancel();invitationWatch?.cancel();work=nil;sharing=nil;refresh=nil;invitationWatch=nil;loading=false;working=false;feedLoading=false;reloading=false;refreshNeeded=false;watchingInvites=false;inviteRevision=0;shareKey="";watchKey="";access.cancel()}
}

private extension Result where Success == TeamsMirrorService.Records,Failure == Error {
    init(_ action:()async throws->Success)async{do{self = .success(try await action())}catch{self = .failure(error)}}
}
