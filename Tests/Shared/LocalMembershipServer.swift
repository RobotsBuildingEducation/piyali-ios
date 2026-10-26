import Foundation
import Network

/// Inert loopback issuer for full native subscription journeys. No provider I/O.
final class LocalMembershipServer:@unchecked Sendable {
 private let queue=DispatchQueue(label:"Piyali.membership.fixture."+UUID().uuidString)
 private var listener:NWListener?,connections:[NWConnection]=[]
 private var payload:[String:Any]=["authorized":false,"linked":false,"configured":true]
 private var calls:[[String:Any]]=[]
 private var forcedPayload:[String:Any]?
 private var forcedCode=200
 private(set) var url=""
 func status(_ value:[String:Any]){queue.sync{payload=value}}
 func requests()->[[String:Any]]{queue.sync{calls}}
 func forceStatus(_ value:[String:Any],code:Int=200){queue.sync{forcedPayload=value;forcedCode=code}}
 func start()async throws{
  let params=NWParameters.tcp;params.requiredLocalEndpoint = .hostPort(host:"127.0.0.1",port:.any);let server=try NWListener(using:params);listener=server
  server.newConnectionHandler={[weak self] c in guard let self else{return};self.connections.append(c);c.start(queue:self.queue);self.read(c,data:Data())}
  try await withCheckedThrowingContinuation{(continuation:CheckedContinuation<Void,Error>)in var finished=false;server.stateUpdateHandler={[weak self] state in guard !finished else{return};switch state{case .ready:finished=true;self?.url="http://127.0.0.1:\(server.port!.rawValue)";continuation.resume();case .failed(let error):finished=true;continuation.resume(throwing:error);default:break}};server.start(queue:queue)}
 }
 private func read(_ c:NWConnection,data:Data){c.receive(minimumIncompleteLength:1,maximumLength:65536){[weak self] bytes,_,done,error in guard let self,error == nil else{return};var input=data;if let bytes{input.append(bytes)};guard input.count <= 131072 else{c.cancel();return};if let end=input.range(of:Data("\r\n\r\n".utf8)),let header=String(data:input[..<end.lowerBound],encoding:.utf8){let length=header.split(separator:"\r\n").compactMap{line->Int? in let pair=line.split(separator:":",maxSplits:1);return pair.first?.lowercased() == "content-length" ? Int(pair.last!.trimmingCharacters(in:.whitespaces)):nil}.first ?? 0;if input.count >= end.upperBound+length{self.respond(c,header:header,body:input.subdata(in:end.upperBound..<(end.upperBound+length)));return}};if done{c.cancel()}else{self.read(c,data:input)}}}
 private func respond(_ c:NWConnection,header:String,body:Data){
  let path=String(header.split(separator:"\r\n").first?.split(separator:" ").dropFirst().first ?? ""),json=(try? JSONSerialization.jsonObject(with:body)) as? [String:Any] ?? [:];calls.append(["path":path,"body":json,"headers":header]);var output:Data,contentType="application/json",code=200,cookie=""
  if path == "/authorize"{payload=["authorized":false,"linked":false,"configured":true,"checkoutRequired":true,"connected":true];contentType="text/html";output=Data("<html><meta name='viewport' content='width=device-width,initial-scale=1'><body><h1>Local membership authorization</h1><p>No real account was connected. Close this browser to return to Piyali.</p></body></html>".utf8)}
  else if path == "/checkout"{payload=["authorized":true,"linked":true,"configured":true,"subscription":["status":"active","entitledAmountCents":800,"lastVerifiedAtMs":1793000000000]];contentType="text/html";output=Data("<html><meta name='viewport' content='width=device-width,initial-scale=1'><body><h1>Local checkout completed</h1><p>No payment was made. Close this browser to return to Piyali.</p></body></html>".utf8)}
  else{var value:[String:Any]=payload
   if path.hasSuffix("/link-challenge"){let action=json["action"] as? String ?? "",challenge=String(repeating:"c",count:32),f=ISO8601DateFormatter();f.formatOptions=[.withInternetDateTime,.withFractionalSeconds];value=["challengeId":challenge,"eventTemplate":["kind":27235,"created_at":Int64(Date().timeIntervalSince1970),"tags":[["action",action],["challenge",challenge],["expires",f.string(from:Date().addingTimeInterval(120))]],"content":"Authorize Piyali Patreon \(action): "+String(repeating:"n",count:43)]]}
   else if path.hasSuffix("/link-start"){value=["authorizeUrl":url+"/authorize"]}
   else if path.hasSuffix("/refresh-status"),let forcedPayload{value=forcedPayload;code=forcedCode}
   else if path.hasSuffix("/disconnect"){forcedPayload=nil;payload=["authorized":false,"linked":false,"configured":true];value=["ok":true]}
   else if path.hasSuffix("/cancel-replacement"){payload=["authorized":false,"linked":false,"configured":true];value=["ok":true]}
   else if !path.hasSuffix("/key-status") && !path.hasSuffix("/refresh-status") && !path.hasSuffix("/status"){code=404;value=["error":"Unknown fixture route"]}
   if path.hasSuffix("/key-status"),value["authorized"] as? Bool == true{cookie="Set-Cookie: __session=auth-session.local-fixture; Path=/; HttpOnly; SameSite=Lax\r\n"}
   output=(try? JSONSerialization.data(withJSONObject:value)) ?? Data()
  }
  var response=Data("HTTP/1.1 \(code) OK\r\nContent-Type: \(contentType)\r\nContent-Length: \(output.count)\r\nCache-Control: no-store\r\n\(cookie)Connection: close\r\n\r\n".utf8);response.append(output);c.send(content:response,completion:.contentProcessed{_ in c.cancel()})
 }
 func stop(){queue.sync{connections.forEach{$0.cancel()};connections=[];listener?.cancel();listener=nil}}
}
