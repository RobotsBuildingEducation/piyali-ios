import Foundation
import NostrSDK

struct LearningTeam: Identifiable, Sendable {
    let id: String
    let creator: String
    let name: String
    let members: [String]
    let event: NostrEventPayload
    var teamID: String { String(event.tag("d").dropFirst("learning-team:".count)) }
}
@MainActor final class NostrTeamsService: ObservableObject {
    @Published private(set) var teams: [LearningTeam] = []
    @Published private(set) var progress: [String:JSONValue] = [:]
    @Published private(set) var profiles: [String:String] = [:]
    @Published var error: String?
    @Published private(set) var busy=false
    let client: NostrRelayClient
    private var generation=0
    private var account=""
    private var pending: Task<Void,Error>?
    private var acknowledged: [NostrEventPayload]=[]
    private let cacheDirectory: URL
    init(client: NostrRelayClient? = nil, cacheDirectory: URL? = nil) {
        var selected=client ?? NostrRelayClient(relays:LearningTeams.relays)
        #if DEBUG
        if client == nil,ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let relay=ProcessInfo.processInfo.environment["PIYALI_TEAM_TEST_RELAY"],let url=URL(string:relay),url.scheme == "ws",url.host == "127.0.0.1",url.port != nil,url.user == nil,url.password == nil,url.fragment == nil { selected=NostrRelayClient(relays:[relay]) }
        #endif
        self.client=selected
        var directory=cacheDirectory ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("PiyaliTeams",isDirectory:true)
        #if DEBUG
        if cacheDirectory == nil,ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",let scope=ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"],UUID(uuidString:scope) != nil { directory=FileManager.default.temporaryDirectory.appendingPathComponent("PiyaliTeamsTests/"+scope,isDirectory:true) }
        #endif
        self.cacheDirectory=directory
    }
    func cancel(clear: Bool = false) { generation += 1;pending?.cancel();pending=nil;busy=false;error=nil;if clear { account="";teams=[];progress=[:];profiles=[:];acknowledged=[] } }
    private func restoreAcknowledged(author: String) {
        let url=cacheDirectory.appendingPathComponent(author+".json")
        acknowledged=((try? Data(contentsOf:url)).flatMap { try? JSONDecoder().decode([NostrEventPayload].self,from:$0) } ?? []).filter { $0.pubkey == author && $0.kind == LearningTeams.kind && $0.tag("d").hasPrefix("learning-team:") && IdentityService.verify($0) }
        teams=latest(acknowledged).compactMap(Self.parse).filter { $0.members.contains(author) }.sorted { $0.name < $1.name }
    }
    private func remember(_ event: NostrEventPayload) {
        guard event.tag("d").hasPrefix("learning-team:") else { return }
        acknowledged=Array(latest(acknowledged+[event]).sorted { $0.created_at > $1.created_at }.prefix(200))
        teams.removeAll { $0.id == event.pubkey+":"+event.tag("d") }
        if let team=Self.parse(event) { teams.append(team);teams.sort { $0.name < $1.name } }
        try? FileManager.default.createDirectory(at:cacheDirectory,withIntermediateDirectories:true)
        if let data=try? JSONEncoder().encode(acknowledged) { try? data.write(to:cacheDirectory.appendingPathComponent(event.pubkey+".json"),options:.atomic) }
    }
    private func latest(_ events: [NostrEventPayload]) -> [NostrEventPayload] {
        var addresses:[String:NostrEventPayload]=[:]
        for event in events { let key=event.pubkey+":"+event.tag("d");if addresses[key].map({ $0.created_at < event.created_at || $0.created_at == event.created_at && event.id < $0.id }) ?? true { addresses[key]=event } }
        return Array(addresses.values)
    }
    private func valid(identity: IdentityService, author: String, version: Int) throws { try Task.checkCancellation();guard identity.hex == author,generation == version else { throw CancellationError() } }
    private func authenticate(identity: IdentityService, author: String) -> NostrRelayClient.Authenticate {
        { relay,challenge in guard await identity.hex == author else { throw CancellationError() };return try await identity.signEvent(kind:22242,tags:[["relay",relay],["challenge",challenge]],content:"",expectedAuthor:author) }
    }
    private func run(identity: IdentityService, action: @escaping @MainActor (String,Int) async throws -> Void) async throws {
        let author=identity.hex;guard !author.isEmpty else { throw AppError.message("Sign in first.") }
        if account != author { cancel(clear:true);account=author;restoreAcknowledged(author:author) }
        let version=generation
        while let pending { _=try? await pending.value;try valid(identity:identity,author:author,version:version) }
        try valid(identity:identity,author:author,version:version)
        let task=Task { @MainActor in
            defer { if self.generation == version { self.pending=nil;self.busy=false } }
            try await action(author,version)
        }
        pending=task;busy=true;error=nil
        do { try await task.value } catch { if generation == version,!(error is CancellationError) { self.error=error.localizedDescription };throw error }
    }
    nonisolated static func parse(_ event: NostrEventPayload) -> LearningTeam? {
        let identifier=event.tag("d")
        guard event.kind == LearningTeams.kind,identifier.hasPrefix("learning-team:"),identifier.count > "learning-team:".count,event.tag("t") == "learning-team",IdentityService.verify(event),!event.tags.contains(where:{ $0.first == "deleted" }) else { return nil }
        let body=try? JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8)),name=event.tag("name").isEmpty ? body?["name"].string ?? "" : event.tag("name")
        var seen=Set<String>()
        let members=event.tags.filter { $0.count > 1 && $0[0] == "p" && $0[1].range(of:"^[0-9a-f]{64}$",options:.regularExpression) != nil }.map { $0[1] }.filter { seen.insert($0).inserted }
        return LearningTeam(id:event.pubkey+":"+identifier,creator:event.pubkey,name:name.isEmpty ? "Team" : name,members:members,event:event)
    }
    private func active(_ team: LearningTeam, identity: IdentityService, author: String, version: Int) async throws -> LearningTeam {
        let events=try await client.query(filter:["kinds":[LearningTeams.kind],"#d":[LearningTeams.leaveIdentifier(creator:team.creator,id:team.teamID)],"limit":200],authenticate:authenticate(identity:identity,author:author))
        try valid(identity:identity,author:author,version:version)
        let departed=Set(events.filter { LearningTeams.memberLeft(teamCreatedAt:team.event.created_at,leaveCreatedAt:$0.created_at) }.map(\.pubkey))
        return LearningTeam(id:team.id,creator:team.creator,name:team.name,members:team.members.filter { !departed.contains($0) },event:team.event)
    }
    private func load(identity: IdentityService, author: String, version: Int) async throws {
        let events=try await client.query(filter:["kinds":[LearningTeams.kind],"#t":["learning-team"],"#p":[author],"limit":100],authenticate:authenticate(identity:identity,author:author))
        try valid(identity:identity,author:author,version:version)
        let parsed=latest(events+acknowledged).compactMap(Self.parse)
        let leaves=parsed.isEmpty ? [] : try await client.query(filter:["kinds":[LearningTeams.kind],"#d":parsed.map { LearningTeams.leaveIdentifier(creator:$0.creator,id:$0.teamID) },"limit":200],authenticate:authenticate(identity:identity,author:author))
        try valid(identity:identity,author:author,version:version)
        let rosters=parsed.compactMap { team -> LearningTeam? in
            let d=LearningTeams.leaveIdentifier(creator:team.creator,id:team.teamID)
            let departed=Set(leaves.filter { $0.tag("d") == d && LearningTeams.memberLeft(teamCreatedAt:team.event.created_at,leaveCreatedAt:$0.created_at) }.map(\.pubkey))
            guard !departed.contains(author),team.members.contains(author) else { return nil }
            return LearningTeam(id:team.id,creator:team.creator,name:team.name,members:team.members.filter { !departed.contains($0) },event:team.event)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let authors=Array(Set(rosters.flatMap(\.members)))
        var snapshots:[String:JSONValue]=[:],names:[String:String]=[:]
        if !authors.isEmpty {
            let published=(try? await client.query(filter:["kinds":[LearningTeams.kind],"authors":authors,"#d":["learning-progress"],"limit":authors.count],authenticate:authenticate(identity:identity,author:author))) ?? []
            try valid(identity:identity,author:author,version:version)
            for event in published { if let data=try? JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8)),case .object=data { snapshots[event.pubkey]=data } }
            let metadata=(try? await client.query(filter:["kinds":[0],"authors":authors,"limit":authors.count],authenticate:authenticate(identity:identity,author:author))) ?? []
            try valid(identity:identity,author:author,version:version)
            for event in metadata { if let data=try? JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8)),let name=[data["display_name"].string,data["displayName"].string,data["name"].string].map({ $0.trimmingCharacters(in:.whitespacesAndNewlines) }).first(where:{ !$0.isEmpty }) { names[event.pubkey]=String(name.prefix(80)) } }
        }
        teams=rosters;progress=snapshots;profiles=names
    }
    func refresh(identity: IdentityService) async { do { try await run(identity:identity) { author,version in try await self.load(identity:identity,author:author,version:version) } } catch { } }
    private func keys(_ members: String) throws -> [String] {
        let npubs=members.split(whereSeparator:{ $0.isWhitespace || $0 == "," }).map(String.init)
        guard !npubs.isEmpty else { throw AppError.message("Enter at least one teammate npub.") }
        return try npubs.map { npub in guard let key=PublicKey(npub:npub),key.dataRepresentation.count == 32 else { throw AppError.message("Invalid teammate npub.") };return key.hex }
    }
    private func checkedName(_ input: String) throws -> String { let name=input.trimmingCharacters(in:.whitespacesAndNewlines);guard !name.isEmpty,name.count <= 80 else { throw AppError.message("Enter a team name of 1–80 characters.") };return name }
    private func sign(_ template: JSONValue, identity: IdentityService, author:String) async throws -> NostrEventPayload { try await identity.signEvent(kind:LearningTeams.kind,tags:template["tags"].array.map { $0.array.map(\.string) },content:template["content"].string,createdAt:Int64(template["created_at"].number),expectedAuthor:author) }
    private func publish(_ template: JSONValue, identity: IdentityService, author: String, version: Int) async throws {
        try valid(identity:identity,author:author,version:version)
        let event=try await sign(template,identity:identity,author:author)
        try valid(identity:identity,author:author,version:version)
        try await client.publish(event,authenticate:authenticate(identity:identity,author:author))
        try valid(identity:identity,author:author,version:version)
        remember(event)
    }
    func create(name: String, members: String, identity: IdentityService, id:String?=nil, reload:Bool=true) async throws {
        let name=try checkedName(name),hexes=try keys(members)
        guard !hexes.contains(identity.hex) else { throw AppError.message("You are already included as the creator.") }
        try await run(identity:identity) { author,version in
            let id=id ?? UUID().uuidString.replacingOccurrences(of:"-",with:"").lowercased()
            try await self.publish(LearningTeams.teamTemplate(id:id,name:name,members:[author]+hexes,createdAt:Int64(Date().timeIntervalSince1970)),identity:identity,author:author,version:version)
            if reload {try await self.load(identity:identity,author:author,version:version)}
        }
    }
    private func current(_ team: LearningTeam, identity: IdentityService, author: String, version: Int) async throws -> LearningTeam {
        guard team.creator == author else { throw AppError.message("Only the team creator can edit this team.") }
        let events=try await client.query(filter:["kinds":[LearningTeams.kind],"authors":[author],"#d":[team.event.tag("d")],"limit":1],authenticate:authenticate(identity:identity,author:author))
        try valid(identity:identity,author:author,version:version)
        guard let event=latest(events+acknowledged.filter { $0.tag("d") == team.event.tag("d") }).first,let team=Self.parse(event) else { throw AppError.message("This team is no longer available.") }
        return try await active(team,identity:identity,author:author,version:version)
    }
    func rename(_ team: LearningTeam, name: String, identity: IdentityService) async throws {
        let name=try checkedName(name)
        try await run(identity:identity) { author,version in
            let latest=try await self.current(team,identity:identity,author:author,version:version)
            if latest.name != name { try await self.publish(LearningTeams.teamTemplate(id:latest.teamID,name:name,members:latest.members,createdAt:max(Int64(Date().timeIntervalSince1970),latest.event.created_at+1)),identity:identity,author:author,version:version) }
            try await self.load(identity:identity,author:author,version:version)
        }
    }
    func addMembers(_ team: LearningTeam, members: String, identity: IdentityService) async throws {
        let hexes=try keys(members)
        try await run(identity:identity) { author,version in
            let latest=try await self.current(team,identity:identity,author:author,version:version)
            guard !hexes.contains(where:{ latest.members.contains($0) || $0 == author }) else { throw AppError.message("One or more teammates are already on this team.") }
            try await self.publish(LearningTeams.teamTemplate(id:latest.teamID,name:latest.name,members:latest.members+hexes,createdAt:max(Int64(Date().timeIntervalSince1970),latest.event.created_at+1)),identity:identity,author:author,version:version)
            try await self.load(identity:identity,author:author,version:version)
        }
    }
    func leave(_ team: LearningTeam, identity: IdentityService) async throws {
        try await run(identity:identity) { author,version in
            if team.creator == author { let latest=try await self.current(team,identity:identity,author:author,version:version);try await self.publish(LearningTeams.teamTemplate(id:latest.teamID,name:latest.name,members:latest.members,createdAt:max(Int64(Date().timeIntervalSince1970),latest.event.created_at+1),deleted:true),identity:identity,author:author,version:version) }
            else { try await self.publish(LearningTeams.leaveTemplate(creator:team.creator,id:team.teamID,createdAt:max(Int64(Date().timeIntervalSince1970),team.event.created_at)),identity:identity,author:author,version:version) }
            try await self.load(identity:identity,author:author,version:version)
        }
    }
    func publishProgress(_ state: LearnerState, identity: IdentityService,reload:Bool=true) async throws {
        try await run(identity:identity) { author,version in
            let data=LearningTeams.snapshot(state)
            try await self.publish(.object(["created_at":data["updatedAt"],"content":.string(data.json),"tags":.array([["d","learning-progress"],["t","learning-progress"]].map { .array($0.map(JSONValue.string)) })]),identity:identity,author:author,version:version)
            if reload {try await self.load(identity:identity,author:author,version:version)}
        }
    }
    func row(member: String, team: LearningTeam, learner: LearnerState, viewer: String) -> JSONValue {
        var data=member == viewer ? LearningTeams.snapshot(learner) : progress[member] ?? .object([:])
        let name=member == viewer && !learner.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? learner.name.trimmingCharacters(in:.whitespacesAndNewlines) : profiles[member] ?? (data["name"].string == "Learner" ? "" : data["name"].string)
        data=data.setting("name",.string(name))
        return LearningTeams.progressRow(member:PublicKey(hex:member)?.npub ?? member,data:data,creator:member == team.creator)
    }
}
