import Foundation

actor NostrRelayClient {
    typealias Authenticate = @Sendable (String,String) async throws -> NostrEventPayload
    let relays: [String]
    private let timeout: Duration
    private let session: URLSession
    init(relays: [String] = ["wss://relay.primal.net","wss://relay.ditto.pub","wss://nos.lol","wss://relay.damus.io"], timeout: Duration = .seconds(6), session: URLSession = .shared) { self.relays=relays;self.timeout=timeout;self.session=session }
    private func matches(_ event: NostrEventPayload, filter: [String:Any]) -> Bool {
        if let kinds=filter["kinds"] as? [Int],!kinds.contains(event.kind) { return false }
        if let authors=filter["authors"] as? [String],!authors.contains(where:{ event.pubkey.hasPrefix($0) }) { return false }
        if let ids=filter["ids"] as? [String],!ids.contains(where:{ event.id.hasPrefix($0) }) { return false }
        for (key,values) in filter where key.hasPrefix("#") { if let values=values as? [String],!event.tags.contains(where:{ $0.count >= 2 && $0[0] == String(key.dropFirst()) && values.contains($0[1]) }) { return false } }
        return true
    }
    func exchange(url: String, message: [Any], subscription: String? = nil, authenticate: Authenticate? = nil) async throws -> [NostrEventPayload] {
        guard let endpoint=URL(string:url),endpoint.user == nil,endpoint.password == nil,endpoint.fragment == nil,endpoint.host != nil,endpoint.scheme == "wss" || endpoint.scheme == "ws" && ["localhost","127.0.0.1","::1"].contains(endpoint.host!) else { throw AppError.message("Invalid Nostr relay URL.") }
        let socket=session.webSocketTask(with:endpoint);socket.resume()
        let deadline=Task { try? await Task.sleep(for:timeout);if !Task.isCancelled { socket.cancel(with:.goingAway,reason:nil) } }
        defer { deadline.cancel();socket.cancel(with:.normalClosure,reason:nil) }
        return try await withTaskCancellationHandler {
            func send(_ frame: [Any]) async throws { try Task.checkCancellation();let bytes=try JSONSerialization.data(withJSONObject:frame,options:[.withoutEscapingSlashes]);try await socket.send(.string(String(decoding:bytes,as:UTF8.self))) }
            try await send(message)
            let filter=subscription == nil ? [:] : message.last as? [String:Any] ?? [:]
            let published=(message.count > 1 ? message[1] as? [String:Any] : nil)?["id"] as? String
            var events:[NostrEventPayload]=[],challenge:String?,authID:String?,authenticated=false,retries=0
            while true {
                try Task.checkCancellation()
                let received=try await socket.receive(),data:Data
                switch received { case .string(let text):data=Data(text.utf8);case .data(let bytes):data=bytes;@unknown default:continue }
                guard data.count <= 2_097_152,let parts=try? JSONSerialization.jsonObject(with:data) as? [Any],let type=parts.first as? String else { continue }
                if type == "AUTH",parts.count == 2,let value=parts[1] as? String,!value.isEmpty,value.utf8.count <= 4096 { challenge=value;authenticated=false;continue }
                if type == "OK",parts.count >= 3,let id=parts[1] as? String {
                    if id == authID { guard parts[2] as? Bool == true else { throw AppError.message("Relay authentication was rejected.") };authenticated=true;authID=nil;try await send(message);continue }
                    guard id == published else { continue }
                    if parts[2] as? Bool == true { return [] }
                    let reason=parts.last as? String ?? "Relay rejected update."
                    if !reason.hasPrefix("auth-required:") { throw AppError.message(reason) }
                } else if type == "CLOSED",parts.count >= 3,subscription != nil,parts[1] as? String == subscription {
                    let reason=parts.last as? String ?? "Relay closed subscription."
                    if !reason.hasPrefix("auth-required:") { throw AppError.message(reason) }
                } else if type == "EOSE",parts.count > 1,subscription != nil,parts[1] as? String == subscription { return events }
                else if type == "EVENT",parts.count >= 3,subscription != nil,parts[1] as? String == subscription {
                    let encoded=try JSONSerialization.data(withJSONObject:parts[2]);guard let event=try? JSONDecoder().decode(NostrEventPayload.self,from:encoded),IdentityService.verify(event),matches(event,filter:filter) else { continue }
                    if events.count < 2048 { events.append(event) };continue
                } else { continue }
                guard let challenge,let authenticate,!authenticated,authID == nil,retries < 2 else { throw AppError.message("Relay requires authentication or access is restricted.") }
                let signed=try await authenticate(url,challenge)
                guard signed.kind == 22242,signed.tag("relay") == url,signed.tag("challenge") == challenge,abs(Double(signed.created_at)-Date().timeIntervalSince1970) < 600,IdentityService.verify(signed) else { throw AppError.message("Invalid relay authentication proof.") }
                retries += 1;authID=signed.id
                try await send(["AUTH",try JSONSerialization.jsonObject(with:JSONEncoder().encode(signed))])
            }
        } onCancel: { socket.cancel(with:.goingAway,reason:nil) }
    }
    /// Keep all responding relay versions. Achievement collections union their records before selecting an address to publish.
    func querySnapshots(filter: [String:Any], authenticate: Authenticate? = nil) async throws -> [NostrEventPayload] {
        let id=UUID().uuidString;var events:[NostrEventPayload]=[],successes=0
        await withTaskGroup(of:[NostrEventPayload]?.self) { group in
            for relay in relays { group.addTask { try? await self.exchange(url:relay,message:["REQ",id,filter],subscription:id,authenticate:authenticate) } }
            for await result in group { if let result { successes += 1;events += result } }
        }
        try Task.checkCancellation();guard successes > 0 else { throw AppError.message("No Nostr relay completed the request. Try again.") };return events
    }
    func query(filter: [String:Any], authenticate: Authenticate? = nil) async throws -> [NostrEventPayload] {
        let events=try await querySnapshots(filter:filter,authenticate:authenticate)
        var addresses:[String:NostrEventPayload]=[:]
        for event in events { let address="\(event.kind):\(event.pubkey):\(event.tag("d"))";if addresses[address].map({ $0.created_at < event.created_at || $0.created_at == event.created_at && event.id < $0.id }) ?? true { addresses[address]=event } }
        return Array(addresses.values)
    }
    func publish(_ event: NostrEventPayload, authenticate: Authenticate? = nil) async throws {
        guard IdentityService.verify(event) else { throw AppError.message("Invalid Nostr event signature.") }
        let object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(event))
        let accepted=await withTaskGroup(of:Bool.self,returning:Bool.self) { group in
            for relay in relays { group.addTask { (try? await self.exchange(url:relay,message:["EVENT",object],authenticate:authenticate)) != nil } }
            for await value in group { if value { group.cancelAll();return true } };return false
        }
        try Task.checkCancellation();guard accepted else { throw AppError.message("No relay acknowledged this update.") }
    }
}
