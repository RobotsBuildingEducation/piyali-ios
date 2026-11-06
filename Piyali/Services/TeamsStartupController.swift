import Foundation
import Combine

@MainActor protocol TeamsStartupAccess:AnyObject {
    func preload(_ app:AppModel)async throws->TeamsPanelSnapshot
    func watchInvites(_ app:AppModel,onChange:@escaping @MainActor([JSONValue])->Void,onFailure:@escaping @MainActor(Error)->Void)async throws
    func preloadFeed(_ app:AppModel)async
    func cancel()
}

@MainActor final class LiveTeamsStartupAccess:TeamsStartupAccess {
    private let reader:LiveTeamsPanelAccess
    private let invitations:TeamsMirrorService
    init(reader:LiveTeamsPanelAccess?=nil,invitations:TeamsMirrorService?=nil){
        var service=NostrTeamsService()
        #if DEBUG
        if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",ProcessInfo.processInfo.environment["PIYALI_TEAM_TEST_RELAY"] == nil{service=NostrTeamsService(client:NostrRelayClient(relays:[]))}
        #endif
        self.reader=reader ?? LiveTeamsPanelAccess(service:service);self.invitations=invitations ?? TeamsMirrorService()
    }
    private var disabled:Bool {
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        return e["PIYALI_OFFLINE_TESTS"] == "1" && e["PIYALI_PRIVATE_TEAMS_TEST_EMULATOR"] != "1" && e["PIYALI_TEAM_TEST_RELAY"] == nil
        #else
        return false
        #endif
    }
    func preload(_ app:AppModel)async throws->TeamsPanelSnapshot {if disabled{return .init()};return try await reader.load(app)}
    func watchInvites(_ app:AppModel,onChange:@escaping @MainActor([JSONValue])->Void,onFailure:@escaping @MainActor(Error)->Void)async throws {if disabled{onChange([]);return};try await invitations.watchInvitations(identity:app.identity,onChange:onChange,onFailure:onFailure)}
    func preloadFeed(_ app:AppModel)async {
        #if DEBUG
        if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",ProcessInfo.processInfo.environment["PIYALI_TEAM_TEST_RELAY"] == nil{return}
        #endif
        if !disabled{await app.teamFeed.refresh(account:app.identity.npub,failureAsEmpty:true)}
    }
    func cancel(){reader.cancel();invitations.stopWatchingInvitations()}
}

/// Startup reads and invitation attention outlive each mounted drawer. They never publish.
@MainActor final class TeamsStartupController:ObservableObject {
    @Published private(set) var attention=TeamInviteAttention()
    @Published private(set) var initial:TeamsPanelSnapshot?
    @Published private(set) var invites:[JSONValue]?
    private(set) var owner=""
    private var session:UUID?,generation=UUID(),inviteVersion=UUID(),jobs:[String:Task<Void,Never>]=[:]
    private var loading=false,watching=false,loadFailed=false
    private let access:TeamsStartupAccess
    init(access:TeamsStartupAccess?=nil){self.access=access ?? LiveTeamsStartupAccess()}
    func bind(_ app:AppModel){
        guard app.signedIn,!app.identity.npub.isEmpty else{cancel();return}
        let account=app.identity.npub,revision=app.identity.sessionRevision
        guard owner != account || session != revision else{return}
        cancel();owner=account;session=revision;let token=generation
        launchReads(app,token:token)
        jobs["feed"]=Task{[weak self,weak app] in guard let self,let app,self.owns(app,token) else{return};await access.preloadFeed(app);if owns(app,token){jobs["feed"]=nil}}
    }
    func resumeAfterForeground(_ app:AppModel){
        guard owner == app.identity.npub,session == app.identity.sessionRevision,app.signedIn else{bind(app);return}
        launchReads(app,token:generation)
    }
    private func launchReads(_ app:AppModel,token:UUID){
        if !loading,(initial == nil || loadFailed) {
            loading=true;loadFailed=false
            jobs["teams"]=Task{[weak self,weak app] in
                guard let self,let app else{return};defer{if owns(app,token){loading=false;jobs["teams"]=nil}}
                do{let value=try await access.preload(app);guard owns(app,token) else{return};initial=value;loadFailed=value.warning != nil}
                catch{if owns(app,token),!(error is CancellationError){if initial == nil{initial = .init(warning:error.localizedDescription)};loadFailed=true}}
            }
        }
        if !watching {
            watching=true;inviteVersion=UUID();let version=inviteVersion
            jobs["invites"]=Task{[weak self,weak app] in
                guard let self,let app else{return};defer{if owns(app,token),inviteVersion == version{jobs["invites"]=nil}}
                do{try await access.watchInvites(app,onChange:{[weak self,weak app] values in guard let self,let app,self.owns(app,token),self.inviteVersion == version else{return};self.invites=values;self.attention.receive(values)},onFailure:{[weak self,weak app] _ in guard let self,let app,self.owns(app,token),self.inviteVersion == version else{return};self.watching=false})}
                catch{if owns(app,token),inviteVersion == version{watching=false}}
            }
        }
    }
    private func owns(_ app:AppModel,_ token:UUID)->Bool {generation == token && owner == app.identity.npub && session == app.identity.sessionRevision && app.signedIn && !Task.isCancelled}
    func snapshot(_ app:AppModel)->TeamsPanelSnapshot? {guard owner == app.identity.npub,session == app.identity.sessionRevision else{return nil};guard var value=initial else{return nil};if let invites{value.invites=invites};return value}
    func viewed(_ app:AppModel){guard owner == app.identity.npub,session == app.identity.sessionRevision else{return};attention.viewed()}
    func cancel(){generation=UUID();jobs.values.forEach{$0.cancel()};jobs=[:];loading=false;watching=false;loadFailed=false;inviteVersion=UUID();access.cancel();owner="";session=nil;initial=nil;invites=nil;attention=TeamInviteAttention()}
}
