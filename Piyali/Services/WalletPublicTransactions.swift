import Foundation
import NostrSDK

struct WalletPublicTransaction:Identifiable,Equatable {
    let id:String,createdAt:Int64,sender:String,recipient:String,amount:Double,unit:String,note:String
    /// Receipt display only. Never imports or redeems proofs from this public feed.
    static func parse(_ event:NostrEventPayload)->Self? {
        guard event.kind == 9321,IdentityService.verify(event),event.tags.filter({$0.first == "p"}).count == 1,event.tags.filter({$0.first == "u"}).count == 1,event.tags.filter({$0.first == "e"}).count <= 1,!event.pubkey.isEmpty,!event.tag("p").isEmpty else{return nil}
        let tags=event.tags.filter{$0.first == "proof"}
        let proofs:[JSONValue]
        if !tags.isEmpty{var parsed:[JSONValue]=[];for tag in tags{guard tag.count>1,let proof=try? JSONDecoder().decode(JSONValue.self,from:Data(tag[1].utf8)) else{return nil};parsed.append(proof)};proofs=parsed}
        else{guard let legacy=try? JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8)),case .array(let values)=legacy else{return nil};proofs=values}
        guard !proofs.isEmpty,proofs.allSatisfy({if case .number(let n)=$0["amount"]{return n.isFinite && n>0};return false}) else{return nil}
        let total=proofs.reduce(0.0){$0+$1["amount"].number};guard total.isFinite,total>0 else{return nil}
        let unit=event.tag("unit"),comment=event.tag("comment")
        return .init(id:event.id,createdAt:event.created_at,sender:event.pubkey,recipient:event.tag("p"),amount:total,unit:unit.isEmpty || unit.hasPrefix("msat") ? "sat":unit,note:(comment.isEmpty ? event.content:comment).trimmingCharacters(in:.whitespacesAndNewlines))
    }
}
@MainActor final class WalletPublicTransactions:ObservableObject {
    @Published private(set) var rows:[WalletPublicTransaction]=[]
    @Published private(set) var profiles:[String:String]=[:]
    @Published private(set) var loading=true
    @Published private(set) var failed=false
    private let client:NostrRelayClient
    private let now:()->Date
    private var generation=UUID()
    private var task:Task<Void,Never>?
    init(client:NostrRelayClient?=nil,now:@escaping()->Date=Date.init){self.client=client ?? Self.defaultClient();self.now=now}
    private static func defaultClient()->NostrRelayClient{
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil{
            if let value=env["PIYALI_WALLET_TEST_RELAY"],let url=URL(string:value),
               ["localhost","127.0.0.1","::1"].contains(url.host ?? ""),
               let relay=try? BunkerConnection.relay(value,allowLoopback:true){
                return NostrRelayClient(relays:[relay],timeout:.seconds(6))
            }
            return NostrRelayClient(relays:[])
        }
        #endif
        return NostrRelayClient(relays:["wss://relay.ditto.pub","wss://relay.primal.net","wss://nos.lol"])
    }
    func cancel(){generation=UUID();task?.cancel();task=nil;loading=false}
    func name(_ key:String)->String {if let profile=profiles[key],!profile.isEmpty{return profile};let value=PublicKey(hex:key)?.npub ?? key;return value.count<18 ? (value.isEmpty ? "unknown":value):String(value.prefix(10))+"…"+String(value.suffix(6))}
    func load()async {
        task?.cancel()
        let epoch=UUID();generation=epoch;loading=true;failed=false
        let request=Task{await read(epoch)}
        task=request
        await withTaskCancellationHandler{await request.value}onCancel:{request.cancel()}
    }
    private func read(_ epoch:UUID)async{
        defer{if generation == epoch{loading=false;task=nil}}
        do{
            let since=Int64(now().timeIntervalSince1970)-30*24*60*60
            let events=try await client.querySnapshots(filter:["kinds":[9321],"since":since,"limit":100],collectUntilDeadline:true)
            try Task.checkCancellation();guard generation == epoch else{return}
            var seen=Set<String>()
            let result=events.filter{$0.created_at>=since && seen.insert($0.id).inserted}
                .compactMap(WalletPublicTransaction.parse).filter{$0.note == WalletCopy.publicNote}.sorted{$0.createdAt>$1.createdAt}
            rows=Array(result.prefix(100))
            let authors=Array(Set(rows.flatMap{[$0.sender,$0.recipient]}))
            guard !authors.isEmpty else{profiles=[:];return}
            // Missing/malformed metadata does not hide a valid receipt.
            let metadata=(try? await client.querySnapshots(filter:["kinds":[0],"authors":authors,"limit":authors.count],collectUntilDeadline:true)) ?? []
            try Task.checkCancellation();guard generation == epoch else{return}
            var latest:[String:NostrEventPayload]=[:];for event in metadata where latest[event.pubkey].map({$0.created_at<event.created_at}) ?? true{latest[event.pubkey]=event}
            profiles=latest.reduce(into:[:]){names,pair in guard let data=try? JSONDecoder().decode(JSONValue.self,from:Data(pair.value.content.utf8)) else{return};let name=[data["displayName"].string,data["display_name"].string,data["name"].string,data["nip05"].string].first{!$0.isEmpty};if let name{names[pair.key]=name}}
        }catch is CancellationError{}catch{if generation == epoch{failed=true}}
    }
}
