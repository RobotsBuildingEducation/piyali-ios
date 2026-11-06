import Foundation
import NostrSDK

struct CommunityPost:Identifiable {
    let event:NostrEventPayload
    let name:String
    let npub:String
    let milestone:CommunityMilestone?
    var id:String { event.id }
}
@MainActor final class CommunityFeedService:ObservableObject {
    @Published private(set) var posts:[CommunityPost]=[]
    @Published private(set) var busy=false
    @Published var error:String?
    let client:NostrRelayClient
    private let clock:()->Date
    private var cachedAt:Date?
    private var cachedContainsNotes=false
    private var account=""
    private var generation=0
    private var pending:Task<Void,Never>?
    init(client:NostrRelayClient? = nil,clock:@escaping()->Date={Date()}) {
        self.clock=clock
        var selected=client ?? NostrRelayClient(relays:LearningTeams.relays)
        #if DEBUG
        if client == nil,ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let relay=ProcessInfo.processInfo.environment["PIYALI_TEAM_TEST_RELAY"],let url=URL(string:relay),url.scheme == "ws",url.host == "127.0.0.1",url.port != nil,url.user == nil,url.password == nil,url.fragment == nil { selected=NostrRelayClient(relays:[relay]) }
        #endif
        self.client=selected
    }
    func cancel(clear:Bool=false) { generation += 1;pending?.cancel();pending=nil;busy=false;if clear { posts=[];cachedAt=nil;cachedContainsNotes=false;account="";error=nil } }
    /// A successful empty cache is distinct from a feed that has never loaded.
    func cachedPosts(account:String)->[CommunityPost]? { self.account == account && cachedAt != nil ? posts:nil }
    func refresh(account:String,force:Bool=false,now:Date?=nil,failureAsEmpty:Bool=false) async {
        if self.account != account { cancel(clear:true);self.account=account }
        if let pending { await pending.value;return }
        if !force,let cachedAt,(now ?? clock()).timeIntervalSince(cachedAt) < (cachedContainsNotes ? 120 : 15) { error=nil;return }
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
                let metadata:[NostrEventPayload]
                if authors.isEmpty{metadata=[]}
                else if failureAsEmpty{
                    // The original main-product adapter resolves note and profile fetches
                    // together; failed metadata setup resolves the entire result to [].
                    metadata=try await self.client.query(filter:["kinds":[0],"authors":authors,"limit":authors.count])
                }else{metadata=(try? await self.client.query(filter:["kinds":[0],"authors":authors,"limit":authors.count])) ?? []}
                try Task.checkCancellation();guard version == self.generation,self.account == account else { return }
                var names:[String:String]=[:]
                for event in metadata.sorted(by:{ $0.created_at == $1.created_at ? $0.id > $1.id : $0.created_at < $1.created_at }) { if let json=try? JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8)) { names[event.pubkey]=json["name"].string.isEmpty ? "New Private User" : String(json["name"].string.prefix(80)) } }
                self.posts=sorted.compactMap { event in
                    let name=names[event.pubkey] ?? "New Private User"
                    guard CommunityMilestone.isFeedAuthorVisible(name),let npub=PublicKey(hex:event.pubkey)?.npub else { return nil }
                    return CommunityPost(event:event,name:name,npub:npub,milestone:CommunityMilestone.parse(content:event.content,tags:event.tags,name:name))
                };self.cachedAt=now ?? self.clock();self.cachedContainsNotes = !sorted.isEmpty
            } catch { if version == self.generation,!(error is CancellationError) {
                self.error=error.localizedDescription
                // The main product's original Nostr adapter catches fetch failures and
                // resolves []; its shared cache treats that as a successful empty result.
                if failureAsEmpty{self.posts=[];self.cachedAt=now ?? self.clock();self.cachedContainsNotes=false}
            } }
        };pending=request;await request.value
    }
    func publishProfile(name:String,identity:IdentityService,expectedAuthor:String)async throws {
        guard !expectedAuthor.isEmpty,identity.hex == expectedAuthor else{throw CancellationError()}
        let version=generation,content=JSONValue.object(["name":.string(name),"about":.string("A student onboarded with Robots Building Education")]).canonicalJSON
        let event=try await identity.signEvent(kind:0,tags:[],content:content,expectedAuthor:expectedAuthor)
        guard identity.hex == expectedAuthor,version == generation,!Task.isCancelled else{throw CancellationError()}
        try await client.publish(event,authenticate:{relay,challenge in try await identity.signEvent(kind:22242,tags:[["relay",relay],["challenge",challenge]],content:"",expectedAuthor:expectedAuthor)})
        guard identity.hex == expectedAuthor,version == generation,!Task.isCancelled else{throw CancellationError()}
    }
    func publish(_ state:LearnerState,identity:IdentityService,expectedAuthor:String,totalXP:Int?=nil,languageLabel:String?=nil,refreshAfter:Bool=true) async throws {
        guard !expectedAuthor.isEmpty,identity.hex == expectedAuthor else { throw CancellationError() }
        let author=expectedAuthor,version=generation,post=CommunityMilestone.progress(state,totalXP:totalXP,languageLabel:languageLabel)
        let event=try await identity.signEvent(kind:1,tags:post.tags,content:post.content,expectedAuthor:author)
        guard identity.hex == author,version == generation else { throw CancellationError() }
        try await client.publish(event,authenticate:{ relay,challenge in try await identity.signEvent(kind:22242,tags:[["relay",relay],["challenge",challenge]],content:"",expectedAuthor:author) })
        guard identity.hex == author,version == generation else { throw CancellationError() }
        if refreshAfter{await refresh(account:identity.npub,force:true)}
    }
}
