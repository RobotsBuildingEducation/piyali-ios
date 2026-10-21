import Foundation
import NostrSDK

struct NostrSessionCrypto:NIP44v2Encrypting {}

actor RemoteSignerService {
    private let peer:PublicKey
    private let keys:Keypair
    private var relays:[String]
    private let timeout:Duration
    private let allowLoopback:Bool
    private var sockets:[UUID:URLSessionWebSocketTask]=[:]
    init(signer:String,relays:[String],clientNsec:String,allowLoopback:Bool = false,timeout:Duration = .seconds(90)) throws {
        guard BunkerConnection.validKey(signer),let peer=PublicKey(hex:signer),let keys=Keypair(nsec:clientNsec),!relays.isEmpty,relays.count <= 8 else { throw BunkerConnection.Failure.invalidConnection }
        self.peer=peer;self.keys=keys;self.relays=try relays.map { try BunkerConnection.relay($0,allowLoopback:allowLoopback) };self.timeout=timeout;self.allowLoopback=allowLoopback
    }
    func cancel() { for socket in sockets.values { socket.cancel(with:.goingAway,reason:nil) };sockets=[:] }
    private func exchange(relay:String,event:NostrEventPayload,id:String,limit:Duration,onAuthorization:@escaping @Sendable (URL) async -> Void) async throws -> JSONValue {
        let socket=URLSession.shared.webSocketTask(with:URL(string:relay)!),ticket=UUID(),sub=UUID().uuidString
        sockets[ticket]=socket;socket.resume()
        let deadline=Task { try? await Task.sleep(for:limit);if !Task.isCancelled { socket.cancel(with:.goingAway,reason:nil) } }
        defer { deadline.cancel();socket.cancel(with:.normalClosure,reason:nil);sockets.removeValue(forKey:ticket) }
        return try await withTaskCancellationHandler {
            func send(_ frame:[Any]) async throws { try Task.checkCancellation();let data=try JSONSerialization.data(withJSONObject:frame,options:[.withoutEscapingSlashes]);try await socket.send(.string(String(decoding:data,as:UTF8.self))) }
            let filter:[String:Any]=["kinds":[24133],"authors":[peer.hex],"#p":[keys.publicKey.hex],"since":Int(Date().timeIntervalSince1970)-120]
            let request:[Any]=["REQ",sub,filter],publication:[Any]=["EVENT",try JSONSerialization.jsonObject(with:JSONEncoder().encode(event))]
            try await send(request);try await send(publication)
            var challenge:String?,authID:String?,authAttempts=0
            while true {
                try Task.checkCancellation();let received=try await socket.receive(),data:Data
                switch received { case .string(let text):data=Data(text.utf8);case .data(let bytes):data=bytes;@unknown default:continue }
                guard data.count <= 2_097_152,let frame=try? JSONSerialization.jsonObject(with:data) as? [Any],let type=frame.first as? String else { continue }
                if type == "AUTH",frame.count == 2,let value=frame[1] as? String,!value.isEmpty,value.utf8.count <= 4096 { challenge=value;continue }
                if type == "OK",frame.count >= 3,let eventID=frame[1] as? String {
                    if eventID == authID { guard frame[2] as? Bool == true else { throw AppError.message("Signer relay authentication was rejected.") };authID=nil;try await send(request);try await send(publication);continue }
                    if eventID != event.id || frame[2] as? Bool == true { continue }
                    let reason=frame.last as? String ?? "";guard reason.hasPrefix("auth-required:") else { throw AppError.message("The signer relay rejected the request.") }
                } else if type == "CLOSED",frame.count >= 3,frame[1] as? String == sub {
                    guard (frame.last as? String ?? "").hasPrefix("auth-required:") else { throw AppError.message("The signer relay closed this request.") }
                } else if type == "EVENT",frame.count == 3,frame[1] as? String == sub {
                    guard let bytes=try? JSONSerialization.data(withJSONObject:frame[2]),let response=try? JSONDecoder().decode(NostrEventPayload.self,from:bytes),response.kind == 24133,response.pubkey == peer.hex,response.tags.contains(["p",keys.publicKey.hex]),abs(Double(response.created_at)-Date().timeIntervalSince1970) <= 600,IdentityService.verify(response),let plaintext=try? NostrSessionCrypto().decrypt(payload:response.content,privateKeyA:keys.privateKey,publicKeyB:peer),let value=try? JSONDecoder().decode(JSONValue.self,from:Data(plaintext.utf8)),value["id"].string == id else { continue }
                    if value["result"].string == "auth_url" {
                        guard let url=URL(string:value["error"].string),url.scheme == "https",url.host != nil,url.user == nil,url.password == nil else { throw BunkerConnection.Failure.invalidResponse }
                        await onAuthorization(url);continue
                    }
                    guard value["error"] == .null || value["error"] == .string("") else { throw AppError.message("The remote signer declined this request.") }
                    guard value.object.keys.contains("result") else { throw BunkerConnection.Failure.invalidResponse };return value["result"]
                } else { continue } // EOSE ends stored history, not the live RPC subscription.
                guard let challenge,authAttempts < 2,authID == nil else { throw AppError.message("The signer relay requires authentication.") }
                let proof=try IdentityService.localEvent(keys:keys,kind:22242,tags:[["relay",relay],["challenge",challenge]],content:"");authID=proof.id;authAttempts += 1
                try await send(["AUTH",try JSONSerialization.jsonObject(with:JSONEncoder().encode(proof))])
            }
        } onCancel: { socket.cancel(with:.goingAway,reason:nil) }
    }
    func request(_ method:String,params:[String],onAuthorization:@escaping @Sendable (URL) async -> Void = { _ in },limit:Duration? = nil) async throws -> JSONValue {
        try Task.checkCancellation();let id=UUID().uuidString
        let plaintext:JSONValue = .object(["id":.string(id),"method":.string(method),"params":.array(params.map(JSONValue.string))])
        let ciphertext=try NostrSessionCrypto().encrypt(plaintext:plaintext.json,privateKeyA:keys.privateKey,publicKeyB:peer)
        let event=try IdentityService.localEvent(keys:keys,kind:24133,tags:[["p",peer.hex]],content:ciphertext)
        return try await withThrowingTaskGroup(of:JSONValue.self) { group in
            for relay in relays { group.addTask { try await self.exchange(relay:relay,event:event,id:id,limit:limit ?? self.timeout,onAuthorization:onAuthorization) } }
            var failure:Error=BunkerConnection.Failure.invalidResponse
            while !group.isEmpty {
                do { if let result=try await group.next() { group.cancelAll();return result } }
                catch { failure=error }
            }
            try Task.checkCancellation();throw failure
        }
    }
    func connected(_ connection:BunkerConnection,onAuthorization:@escaping @Sendable (URL) async -> Void) async throws -> RemoteSignerRecord {
        let metadata:JSONValue = .object(["name":.string("Piyali for iPhone"),"url":.string("https://piyali.app")])
        let connected=try await request("connect",params:[peer.hex,connection.secret ?? "","sign_event:27235,sign_event:22242,sign_event:30078,sign_event:1",metadata.json],onAuthorization:onAuthorization)
        guard connected.string == "ack" || connection.secret != nil && connected.string == connection.secret else { throw BunkerConnection.Failure.invalidResponse }
        let user=try await request("get_public_key",params:[],onAuthorization:onAuthorization)
        guard BunkerConnection.validKey(user.string),PublicKey(hex:user.string) != nil else { throw BunkerConnection.Failure.invalidResponse }
        // Older signers reject this optional method; their supplied relays remain usable.
        if let result=try? await request("switch_relays",params:[],onAuthorization:onAuthorization,limit:.seconds(5)) {
            let values=result.array.isEmpty ? (try? JSONDecoder().decode([String].self,from:Data(result.string.utf8))) ?? [] : result.array.map(\.string)
            if !values.isEmpty { guard values.count <= 8 else { throw BunkerConnection.Failure.invalidRelay };relays=try values.map { try BunkerConnection.relay($0,allowLoopback:allowLoopback) } }
        }
        try Task.checkCancellation();return RemoteSignerRecord(signer:peer.hex,user:user.string,relays:relays,clientNsec:keys.privateKey.nsec)
    }
    func sign(kind:Int,tags:[[String]],content:String,createdAt:Int64,user:String,onAuthorization:@escaping @Sendable (URL) async -> Void) async throws -> NostrEventPayload {
        let template:JSONValue = .object(["kind":.number(Double(kind)),"tags":.array(tags.map { .array($0.map(JSONValue.string)) }),"content":.string(content),"created_at":.number(Double(createdAt))])
        let result=try await request("sign_event",params:[template.json],onAuthorization:onAuthorization)
        guard let event=try? JSONDecoder().decode(NostrEventPayload.self,from:Data(result.string.utf8)),event.pubkey == user,event.kind == kind,event.tags == tags,event.content == content,event.created_at == createdAt,IdentityService.verify(event) else { throw BunkerConnection.Failure.invalidResponse };return event
    }
}
