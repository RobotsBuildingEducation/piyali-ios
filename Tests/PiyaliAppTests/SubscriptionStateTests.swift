import XCTest
@testable import Piyali

private final class MembershipProtocol:URLProtocol {
 struct Reply{var status=200;var value:[String:Any]}
 private static let lock=NSLock()
 private static var handler:((URLRequest)->Reply?)?
 private static var held:[MembershipProtocol]=[]
 private var stopped=false
 static func install(_ value:@escaping(URLRequest)->Reply?){lock.lock();handler=value;held=[];lock.unlock()}
 static func releaseHeld(_ reply:Reply){lock.lock();let rows=held;held=[];lock.unlock();for row in rows{row.respond(reply)}}
 static var heldCount:Int{lock.lock();defer{lock.unlock()};return held.count}
 override class func canInit(with request:URLRequest)->Bool{true}
 override class func canonicalRequest(for request:URLRequest)->URLRequest{request}
 override func startLoading(){Self.lock.lock();let handler=Self.handler;Self.lock.unlock();if let reply=handler?(request){respond(reply)}else{Self.lock.lock();Self.held.append(self);Self.lock.unlock()}}
 override func stopLoading(){Self.lock.lock();stopped=true;Self.lock.unlock()}
 private func respond(_ reply:Reply){Self.lock.lock();let stopped=self.stopped;Self.lock.unlock();guard !stopped else{return};let data=try! JSONSerialization.data(withJSONObject:reply.value),response=HTTPURLResponse(url:request.url!,statusCode:reply.status,httpVersion:nil,headerFields:["Content-Type":"application/json"])!;client?.urlProtocol(self,didReceive:response,cacheStoragePolicy:.notAllowed);client?.urlProtocol(self,didLoad:data);client?.urlProtocolDidFinishLoading(self)}
 static func body(_ request:URLRequest)->[String:Any]{var data=request.httpBody;if data == nil,let stream=request.httpBodyStream{stream.open();defer{stream.close()};var bytes=Data(),buffer=[UInt8](repeating:0,count:4096);while stream.hasBytesAvailable && bytes.count < 65536{let count=stream.read(&buffer,maxLength:buffer.count);if count <= 0{break};bytes.append(contentsOf:buffer.prefix(count))};data=bytes};return (data.flatMap{try? JSONSerialization.jsonObject(with:$0)}) as? [String:Any] ?? [:]}
 static func challenge(_ action:String)->Reply{.init(value:["challengeId":String(repeating:"c",count:32),"eventTemplate":["kind":27235,"created_at":Int64(Date().timeIntervalSince1970),"tags":[["action",action],["challenge",String(repeating:"c",count:32)],["expires",WebProgressContract.iso(Date().addingTimeInterval(120))]],"content":"Authorize Piyali Patreon \(action): "+String(repeating:"n",count:43)]])}
 static func valid(_ request:URLRequest,action:String,author:String)->Bool{let body=body(request);guard let value=body["signedEvent"],let event=try? JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:value)) else{return false};return body["challengeId"] as? String == String(repeating:"c",count:32) && event.pubkey == author && event.kind == 27235 && event.tag("action") == action && event.content == "Authorize Piyali Patreon \(action): "+String(repeating:"n",count:43) && IdentityService.verify(event)}
}
@MainActor final class SubscriptionStateTests:XCTestCase {
 private func context()throws->(IdentityService,SubscriptionService){guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated local membership tests required")};let identity=IdentityService();try identity.create();let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[MembershipProtocol.self];let service=SubscriptionService(webSession:URLSession(configuration:config));service.bind(identity);service.updatePracticeXP(300);return(identity,service)}
 private func settle(_ condition:()->Bool)async{for _ in 0..<200{if condition(){return};try? await Task.sleep(for:.milliseconds(10))};XCTFail("Membership state did not settle")}
 func testSignedRestorePreservesFullMembershipAndConcurrentChecksShareOneProof()async throws{
  let(identity,service)=try context();defer{try? identity.disconnect()};let author=identity.hex;var challenges=0,checks=0
  MembershipProtocol.install{request in if request.url?.lastPathComponent == "link-challenge"{challenges += 1;return MembershipProtocol.challenge("restore")};checks += 1;XCTAssertTrue(MembershipProtocol.valid(request,action:"restore",author:author));return nil}
  let first=Task{try await service.restoreWeb()},second=Task{try await service.restoreWeb()};await settle{MembershipProtocol.heldCount == 1};MembershipProtocol.releaseHeld(.init(value:["authorized":true,"configured":true,"linked":true,"subscription":["status":"active","entitledAmountCents":800,"lastVerifiedAtMs":1793000000000,"stale":true]]));try await first.value;try await second.value
  XCTAssertEqual(challenges,1);XCTAssertEqual(checks,1);XCTAssertTrue(service.authorized);XCTAssertTrue(service.hasAccess);XCTAssertEqual(service.statusPayload["subscription"]["entitledAmountCents"],.number(800));XCTAssertTrue(service.statusPayload["subscription"]["stale"].boolean);XCTAssertTrue(service.statusResolved)
 }
 func testLateOldAccountRestoreCannotGrantNewKeyAccess()async throws{
  let(identity,service)=try context();defer{try? identity.disconnect()};let firstAuthor=identity.hex
  MembershipProtocol.install{request in if request.url?.lastPathComponent == "link-challenge"{return MembershipProtocol.challenge("restore")};if MembershipProtocol.valid(request,action:"restore",author:firstAuthor){return nil};return .init(value:["authorized":false,"linked":false,"configured":true])}
  let old=Task{try await service.restoreWeb()};await settle{MembershipProtocol.heldCount == 1};try identity.create();service.bind(identity);service.updatePracticeXP(300);try await service.restoreWeb();MembershipProtocol.releaseHeld(.init(value:["authorized":true,"linked":true]));_=try? await old.value
  XCTAssertFalse(service.webAuthorized);XCTAssertFalse(service.hasAccess);XCTAssertEqual(service.statusPayload["linked"],.bool(false));XCTAssertNil(service.browser)
 }
 func testConnectSignsLinkAndReturningRestoresReplacementBeforeExplicitMove()async throws{
  let(identity,service)=try context();defer{try? identity.disconnect()};let author=identity.hex;var actions:[String]=[],start:[String:Any]=[:]
  let url="https://www.patreon.com/oauth2/authorize?response_type=code&client_id=local&redirect_uri=https%3A%2F%2Fpiyali.app%2Fapi%2Fpatreon%2Fcallback&scope=identity&state="+String(repeating:"s",count:43)
  MembershipProtocol.install{request in let path=request.url!.lastPathComponent,body=MembershipProtocol.body(request);if path == "link-challenge"{return MembershipProtocol.challenge(body["action"] as? String ?? "")};let action=path == "link-start" ? "link":path == "replace-link" ? "replace":"restore";XCTAssertTrue(MembershipProtocol.valid(request,action:action,author:author));actions.append(action);if path == "link-start"{start=body;return .init(value:["authorizeUrl":url])};if path == "replace-link"{return .init(value:["authorized":true,"linked":true,"subscription":["status":"active"]])};return .init(value:["authorized":false,"linked":false,"replacementRequired":true])}
  await service.connect(language:"ar");XCTAssertEqual(service.browser?.url.absoluteString,url);XCTAssertEqual(start["supportLanguage"] as? String,"ar");XCTAssertEqual(start["plan"] as? String,"annual");XCTAssertTrue(service.awaiting);XCTAssertFalse(service.hasAccess)
  service.browserClosed();await settle{service.replacementRequired};XCTAssertFalse(service.hasAccess);XCTAssertEqual(actions,["link","restore"]);await service.replaceLinkedKey();XCTAssertTrue(service.webAuthorized);XCTAssertTrue(service.hasAccess);XCTAssertEqual(actions,["link","restore","replace"])
 }
 func testDisconnectFailureKeepsLinkedStateAndSuccessRequiresSignedProof()async throws{
  let(identity,service)=try context();defer{try? identity.disconnect()};let author=identity.hex;var rejected=true
  MembershipProtocol.install{request in let path=request.url!.lastPathComponent,body=MembershipProtocol.body(request);if path == "link-challenge"{return MembershipProtocol.challenge(body["action"] as? String ?? "")};if path == "disconnect"{XCTAssertTrue(MembershipProtocol.valid(request,action:"disconnect",author:author));return rejected ? .init(status:401,value:["error":"not_authenticated"]):.init(value:["ok":true])};return .init(value:["authorized":true,"linked":true,"subscription":["status":"active"]])}
  try await service.restoreWeb();await service.disconnectWeb();XCTAssertTrue(service.webAuthorized);XCTAssertTrue(service.statusPayload["linked"].boolean);XCTAssertEqual(service.statusError,"not_authenticated");rejected=false;await service.disconnectWeb();XCTAssertFalse(service.webAuthorized);XCTAssertFalse(service.hasAccess);XCTAssertFalse(service.statusPayload["linked"].boolean)
 }
 func testUnsafeServerURLAndWrongActionChallengeNeverOpenBrowserOrSubmitLink()async throws{
  let(identity,service)=try context();defer{try? identity.disconnect()};var starts=0
  MembershipProtocol.install{request in if request.url?.lastPathComponent == "link-challenge"{return MembershipProtocol.challenge("disconnect")};starts += 1;return .init(value:["authorizeUrl":"https://evil.invalid/"])}
  await service.connect(language:"en");XCTAssertEqual(starts,0);XCTAssertNil(service.browser);XCTAssertFalse(service.hasAccess)
  let web=URL(string:"https://piyali.app")!
  for raw in["https://evil.invalid/oauth2/authorize","javascript:alert(1)","https://www.patreon.com@evil.invalid/oauth2/authorize","http://www.patreon.com/oauth2/authorize"]{XCTAssertThrowsError(try SubscriptionBrowserRequest.authorizeURL(raw,web:web))}
 }
 func testCheckAfterCheckoutReverifiesWithPatreonWhenSafariHasNotLinkedTheKey()async throws{
  let(identity,service)=try context();defer{try? identity.disconnect()};var starts=0,paid=false
  let url="https://www.patreon.com/oauth2/authorize?response_type=code&client_id=local&redirect_uri=https%3A%2F%2Fpiyali.app%2Fapi%2Fpatreon%2Fcallback&scope=identity&state="+String(repeating:"s",count:43)
  MembershipProtocol.install{request in let path=request.url!.lastPathComponent;if path == "link-challenge"{return MembershipProtocol.challenge(MembershipProtocol.body(request)["action"] as? String ?? "")};if path == "link-start"{starts += 1;return .init(value:["authorizeUrl":url])};return .init(value:["authorized":paid,"linked":paid,"configured":true])}
  await service.connect(language:"en");service.browserClosed();await settle{service.statusResolved};XCTAssertFalse(service.hasAccess);await service.checkMembership(language:"en");XCTAssertEqual(starts,2);XCTAssertNotNil(service.browser);XCTAssertFalse(service.hasAccess);paid=true;service.browserClosed();await settle{service.webAuthorized};XCTAssertTrue(service.hasAccess)
 }

}
