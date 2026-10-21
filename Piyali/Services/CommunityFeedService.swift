import Foundation
import NostrSDK

struct CommunityPost:Identifiable {
    let event:NostrEventPayload
    let name:String
    let npub:String
    let milestone:CommunityMilestone
    var id:String { event.id }
}
@MainActor final class CommunityFeedService:ObservableObject {
    @Published private(set) var posts:[CommunityPost]=[]
    @Published private(set) var busy=false
    @Published var error:String?
    let client:NostrRelayClient
    private var cachedAt:Date?
    private var account=""
    private var generation=0
    private var pending:Task<Void,Never>?
    init(client:NostrRelayClient? = nil) {
        var selected=client ?? NostrRelayClient(relays:LearningTeams.relays)
        #if DEBUG
        if client == nil,ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let relay=ProcessInfo.processInfo.environment["PIYALI_TEAM_TEST_RELAY"],let url=URL(string:relay),url.scheme == "ws",url.host == "127.0.0.1",url.port != nil,url.user == nil,url.password == nil,url.fragment == nil { selected=NostrRelayClient(relays:[relay]) }
        #endif
        self.client=selected
    }
    func cancel(clear:Bool=false) { generation += 1;pending?.cancel();pending=nil;busy=false;if clear { posts=[];cachedAt=nil;account="";error=nil } }
    func refresh(account:String,force:Bool=false,now:Date=Date()) async {
        if self.account != account { cancel(clear:true);self.account=account }
        if let pending { await pending.value;return }
        if !force,let cachedAt,now.timeIntervalSince(cachedAt) < (posts.isEmpty ? 15 : 120) { return }
        let version=generation;busy=true;error=nil
        let request=Task { @MainActor in
            defer { if version == self.generation { self.busy=false;self.pending=nil } }
            do {
                // Both spellings matter: the web query uses title case but its XP publisher emits lowercase.
                let notes=try await self.client.querySnapshots(filter:["kinds":[1],"#t":["LearnWithNostr","learnwithnostr"],"limit":50])
                try Task.checkCancellation()
                var unique:[String:NostrEventPayload]=[:];for event in notes where event.content.utf8.count <= 65536 { unique[event.id]=event }
                let sorted=unique.values.sorted { $0.created_at == $1.created_at ? $0.id < $1.id : $0.created_at > $1.created_at }.prefix(50)
                let authors=Array(Set(sorted.map(\.pubkey)))
                let metadata=authors.isEmpty ? [] : (try? await self.client.query(filter:["kinds":[0],"authors":authors,"limit":authors.count])) ?? []
                try Task.checkCancellation();guard version == self.generation,self.account == account else { return }
                var names:[String:String]=[:]
                for event in metadata { if let json=try? JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8)),!json["name"].string.isEmpty { names[event.pubkey]=String(json["name"].string.prefix(80)) } }
                self.posts=sorted.compactMap { event in
                    let name=names[event.pubkey] ?? "New Private User"
                    guard let milestone=CommunityMilestone.parse(content:event.content,tags:event.tags,name:name),let npub=PublicKey(hex:event.pubkey)?.npub else { return nil }
                    return CommunityPost(event:event,name:name,npub:npub,milestone:milestone)
                };self.cachedAt=now
            } catch { if version == self.generation,!(error is CancellationError) { self.error=error.localizedDescription } }
        };pending=request;await request.value
    }
    func publish(_ state:LearnerState,identity:IdentityService,expectedAuthor:String) async throws {
        guard !expectedAuthor.isEmpty,identity.hex == expectedAuthor else { throw CancellationError() }
        let author=expectedAuthor,version=generation,post=CommunityMilestone.progress(state)
        let event=try await identity.signEvent(kind:1,tags:post.tags,content:post.content,expectedAuthor:author)
        guard identity.hex == author,version == generation else { throw CancellationError() }
        try await client.publish(event,authenticate:{ relay,challenge in try await identity.signEvent(kind:22242,tags:[["relay",relay],["challenge",challenge]],content:"",expectedAuthor:author) })
        guard identity.hex == author,version == generation else { throw CancellationError() }
        await refresh(account:identity.npub,force:true)
    }
}
