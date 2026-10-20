import Foundation
import CryptoKit
import NostrSDK
import Network

private struct RemoteFixtureCrypto:ContentSigning,EventVerifying,NIP44v2Encrypting {}
/// Simulated signer with distinct transport/user keys. No requests reach public relays.
final class LocalRemoteSigner:@unchecked Sendable {
    let relay=LocalNostrRelay()
    let peer:Keypair
    let user:Keypair
    init(peer:Keypair = Keypair(hex:String(repeating:"0",count:63)+"1")!,user:Keypair = Keypair(hex:String(repeating:"0",count:63)+"2")!) { self.peer=peer;self.user=user }
    var token:String { "bunker://"+peer.publicKey.hex+"?relay="+relay.url+"&secret=fixture-secret" }
    var alterSignedContent=false
    var wrongUser=false
    var denySigning=false
    var challenge=false
    var delaySigning=false
    var injectNoise=false
    var authorizationURL="https://signer.example/approve"
    private var subscriptions:[ObjectIdentifier:String]=[:]
    private let lock=NSLock()
    private var calls:[String]=[]
    private var held:[()->Void]=[]
    func methods() -> [String] { lock.lock();defer { lock.unlock() };return calls }
    func release() { lock.lock();let values=held;held=[];lock.unlock();for value in values { value() } }
    func stop() { relay.stop() }
    private func signed(_ template:[String:Any],keys:Keypair) throws -> [String:Any] {
        let kind=template["kind"] as! Int,tags=template["tags"] as! [[String]],content=template["content"] as! String,date=(template["created_at"] as! NSNumber).int64Value
        let bytes=try JSONSerialization.data(withJSONObject:[0,keys.publicKey.hex,date,kind,tags,content],options:[.withoutEscapingSlashes])
        let id=SHA256.hash(data:bytes).map { String(format:"%02x",$0) }.joined()
        return ["id":id,"pubkey":keys.publicKey.hex,"created_at":date,"kind":kind,"tags":tags,"content":content,"sig":try RemoteFixtureCrypto().signatureForContent(id,privateKey:keys.privateKey.hex)]
    }
    private func reply(id:String,result:Any,error:String? = nil,client:PublicKey,sub:String,connection:NWConnection,noise:Int = 0) throws {
        var body:[String:Any]=["id":id,"result":result];if let error { body["error"]=error }
        let plaintext=String(decoding:try JSONSerialization.data(withJSONObject:body),as:UTF8.self)
        let cipher=try RemoteFixtureCrypto().encrypt(plaintext:plaintext,privateKeyA:peer.privateKey,publicKeyB:client)
        var event=try signed(["kind":24133,"tags":[["p",noise == 2 ? user.publicKey.hex : client.hex]],"content":cipher,"created_at":noise == 4 ? 100 : Int64(Date().timeIntervalSince1970)],keys:noise == 3 ? user : peer)
        if noise == 5 { event["sig"]=String(repeating:"0",count:128) }
        relay.send(["EVENT",sub,event],to:connection)
    }
    func start() async throws {
        try await relay.start { [weak self] frame,connection in
            guard let self else { return }
            if frame.first as? String == "REQ",let sub=frame[1] as? String { self.subscriptions[ObjectIdentifier(connection)]=sub;self.relay.send(["EOSE",sub],to:connection);return }
            guard frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let client=PublicKey(hex:event["pubkey"] as? String ?? ""),let cipher=event["content"] as? String,let sub=self.subscriptions[ObjectIdentifier(connection)] else { return }
            do {
                let id=event["id"] as! String;try RemoteFixtureCrypto().verifySignature(event["sig"] as! String,for:id,withPublicKey:client.hex)
                self.relay.send(["OK",id,true,""],to:connection)
                let text=try RemoteFixtureCrypto().decrypt(payload:cipher,privateKeyA:self.peer.privateKey,publicKeyB:client)
                let request=try JSONSerialization.jsonObject(with:Data(text.utf8)) as! [String:Any],requestID=request["id"] as! String,method=request["method"] as! String,params=request["params"] as! [String]
                self.lock.lock();self.calls.append(method);self.lock.unlock()
                let result:Any
                switch method {
                case "connect":guard params.count == 4,params[0] == self.peer.publicKey.hex,params[1] == "fixture-secret" else { throw NSError(domain:"fixture-connect",code:1) };result="ack"
                case "get_public_key":result=self.user.publicKey.hex
                case "switch_relays":result=NSNull()
                case "nip44_encrypt", "nip44_decrypt":
                    guard params.count == 2,params[0] == self.user.publicKey.hex else { throw NSError(domain:"fixture-wallet-key",code:1) }
                    if self.denySigning { try self.reply(id:requestID,result:"",error:"permission denied",client:client,sub:sub,connection:connection);return }
                    result = method == "nip44_encrypt" ? try RemoteFixtureCrypto().encrypt(plaintext:params[1],privateKeyA:self.user.privateKey,publicKeyB:self.user.publicKey) : try RemoteFixtureCrypto().decrypt(payload:params[1],privateKeyA:self.user.privateKey,publicKeyB:self.user.publicKey)
                case "sign_event":
                    if self.denySigning { try self.reply(id:requestID,result:"",error:"permission denied",client:client,sub:sub,connection:connection);return }
                    var unsigned=try JSONSerialization.jsonObject(with:Data(params[0].utf8)) as! [String:Any]
                    if self.alterSignedContent { unsigned["content"]="altered" }
                    let signed=try self.signed(unsigned,keys:self.wrongUser ? self.peer : self.user)
                    result=String(decoding:try JSONSerialization.data(withJSONObject:signed),as:UTF8.self)
                    if self.challenge { try self.reply(id:requestID,result:"auth_url",error:self.authorizationURL,client:client,sub:sub,connection:connection) }
                    if self.injectNoise { for mode in 1...5 { try self.reply(id:mode == 1 ? UUID().uuidString : requestID,result:"bad",client:client,sub:sub,connection:connection,noise:mode) } }
                default:result="pong"
                }
                let deliver:()->Void = { [weak self] in _ = try? self?.reply(id:requestID,result:result,client:client,sub:sub,connection:connection) }
                if ["sign_event","nip44_encrypt","nip44_decrypt"].contains(method),self.delaySigning { self.lock.lock();self.held.append(deliver);self.lock.unlock() }
                else { deliver() }
            } catch { self.relay.send(["NOTICE","local signer fixture rejected input"],to:connection) }
        }
    }
}
