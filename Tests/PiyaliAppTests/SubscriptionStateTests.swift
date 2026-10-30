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
 private func context(now:@escaping()->Date = Date.init,cookie:Bool=false)throws->(IdentityService,SubscriptionService){guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated local membership tests required")};let identity=IdentityService();try identity.create();let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[MembershipProtocol.self];if cookie{let web=AppConfiguration().web;var properties:[HTTPCookiePropertyKey:Any]=[.name:"__session",.value:"auth-session.protocol-fixture",.domain:web.host!, .path:"/"];if web.scheme == "https"{properties[.secure]="TRUE"};config.httpCookieStorage?.setCookie(try XCTUnwrap(HTTPCookie(properties:properties)))};let service=SubscriptionService(webSession:URLSession(configuration:config),now:now);service.bind(identity);service.updatePracticeXP(300);return(identity,service)}
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

 func testActualHTTPRestoreCookieBindsForcedRefreshToCurrentKeyAndBypassesCachedStatus()async throws{
  let(identity,_)=try context();defer{try? identity.disconnect()};let server=LocalMembershipServer();try await server.start();defer{server.stop()}
  server.status(["authorized":true,"linked":true,"subscription":["status":"active"]]);server.forceStatus(["authorized":false,"linked":true,"subscription":["status":"payment_issue"]])
  let service=SubscriptionService(configuration:AppConfiguration(values:["WebBaseURL":server.url]));service.bind(identity);service.updatePracticeXP(300)
  try await service.restoreWeb();XCTAssertTrue(service.hasAccess);try await service.refreshWeb(force:true);XCTAssertFalse(service.hasAccess);XCTAssertEqual(service.statusPayload["subscription"]["status"],.string("payment_issue"))
  let calls=server.requests(),forced=try XCTUnwrap(calls.first{($0["path"] as? String)?.hasSuffix("/refresh-status") == true}),headers=try XCTUnwrap(forced["headers"] as? String)
  XCTAssertTrue(headers.hasPrefix("POST "));XCTAssertTrue(headers.contains("__session=auth-session.local-fixture"));XCTAssertTrue(headers.lowercased().contains("x-piyali-npub: "+identity.npub))
  let signed=try XCTUnwrap(calls.first{($0["path"] as? String)?.hasSuffix("/key-status") == true}?["body"] as? [String:Any]),event=try JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:try XCTUnwrap(signed["signedEvent"])));XCTAssertTrue(IdentityService.verify(event));XCTAssertEqual(event.pubkey,identity.hex)
 }
 func testConcurrentForceWaitsForCachedRestoreThenSharesOneFreshCheck()async throws{
  let(identity,service)=try context(cookie:true);defer{try? identity.disconnect()};let owner=identity.npub;var restores=0,forces=0
  MembershipProtocol.install{request in switch request.url!.lastPathComponent{case "link-challenge":return MembershipProtocol.challenge("restore");case "key-status":restores += 1;return nil;case "refresh-status":forces += 1;XCTAssertEqual(request.httpMethod,"POST");XCTAssertEqual(request.value(forHTTPHeaderField:"X-Piyali-Npub"),owner);XCTAssertEqual(request.cachePolicy,.reloadIgnoringLocalCacheData);return .init(value:["authorized":false,"linked":true,"subscription":["status":"inactive"]]);default:XCTFail("Unexpected membership request");return .init(status:500,value:[:])}}
  let restore=Task{try await service.restoreWeb()};await settle{MembershipProtocol.heldCount == 1};let first=Task{try await service.refreshWeb(force:true)},second=Task{try await service.refreshWeb(force:true)};await Task.yield();MembershipProtocol.releaseHeld(.init(value:["authorized":true,"linked":true]));try await restore.value;try await first.value;try await second.value
  XCTAssertEqual(restores,1);XCTAssertEqual(forces,1);XCTAssertFalse(service.hasAccess);XCTAssertEqual(service.statusPayload["subscription"]["status"],.string("inactive"))
 }
 func testForegroundRenewalsKeepPaidAccessAcrossFourOriginalLeaseBoundariesWithoutResigning()async throws{
  var date=Date();let(identity,service)=try context(now:{date},cookie:true);defer{try? identity.disconnect()};let owner=identity.npub;var signatures=0,passive=0
  MembershipProtocol.install{request in if request.url!.lastPathComponent == "link-challenge"{signatures += 1;return MembershipProtocol.challenge("restore")};if request.url!.lastPathComponent == "status"{passive += 1;XCTAssertEqual(request.httpMethod,"GET");XCTAssertEqual(request.value(forHTTPHeaderField:"X-Piyali-Npub"),owner)};return .init(value:["authorized":true,"linked":true,"subscription":["status":"active"]])}
  try await service.restoreWeb();service.setApplicationActive(true)
  for _ in 0..<4{date=date.addingTimeInterval(14*60);await service.maintainWebAccess();service.checkExpiry();XCTAssertTrue(service.hasAccess)}
  XCTAssertEqual(signatures,1);XCTAssertEqual(passive,4);service.setApplicationActive(false);date=date.addingTimeInterval(16*60);await service.maintainWebAccess();XCTAssertEqual(passive,4);XCTAssertFalse(service.hasAccess)
 }
 func testRenewalOutageBacksOffAndNeverExtendsAnExpiredGrant()async throws{
  var date=Date();let(identity,service)=try context(now:{date},cookie:true);defer{try? identity.disconnect()};var attempts=0
  MembershipProtocol.install{request in if request.url!.lastPathComponent == "link-challenge"{return MembershipProtocol.challenge("restore")};if request.url!.lastPathComponent == "status"{attempts += 1;return .init(status:503,value:["error":"patreon_unavailable"])};return .init(value:["authorized":true,"linked":true])}
  try await service.restoreWeb();service.setApplicationActive(true);date=date.addingTimeInterval(14*60);await service.maintainWebAccess();XCTAssertTrue(service.hasAccess);XCTAssertEqual(service.statusError,"unavailable")
  date=date.addingTimeInterval(30);await service.maintainWebAccess();XCTAssertEqual(attempts,1);date=date.addingTimeInterval(31);await service.maintainWebAccess();XCTAssertEqual(attempts,2);XCTAssertFalse(service.hasAccess);XCTAssertFalse(service.webAuthorized)
 }
 func testRateLimitMetadataDoesNotBootstrapOrProlongAccessAndDelaysAutomaticRetry()async throws{
  var date=Date();let(identity,service)=try context(now:{date},cookie:true);defer{try? identity.disconnect()};var passive=0
  MembershipProtocol.install{request in switch request.url!.lastPathComponent{case "link-challenge":return MembershipProtocol.challenge("restore");case "refresh-status":return .init(status:429,value:["authorized":true,"linked":true,"retryAfterMs":120000,"subscription":["status":"active"]]);case "status":passive += 1;return .init(value:["authorized":true,"linked":true]);default:return .init(value:["authorized":true,"linked":true])}}
  try await service.refreshWeb(force:true);XCTAssertFalse(service.hasAccess,"A cached 429 cannot create a grant")
  try await service.restoreWeb();service.setApplicationActive(true);date=date.addingTimeInterval(14*60+58);try await service.refreshWeb(force:true);XCTAssertTrue(service.hasAccess);date=date.addingTimeInterval(3);service.checkExpiry();XCTAssertFalse(service.hasAccess)
  await service.maintainWebAccess();XCTAssertEqual(passive,0);date=date.addingTimeInterval(120);await service.maintainWebAccess();XCTAssertEqual(passive,1);XCTAssertTrue(service.hasAccess)
 }
 func testDisconnectCancelsDelayedRenewalAndQueuedForceWithoutRestoringOldAccess()async throws{
  let(identity,service)=try context(cookie:true);defer{try? identity.disconnect()};var disconnected=false
  MembershipProtocol.install{request in let path=request.url!.lastPathComponent;if path == "link-challenge"{return MembershipProtocol.challenge(MembershipProtocol.body(request)["action"] as? String ?? "")};if path == "status"{return nil};if path == "disconnect"{disconnected=true;return .init(value:["ok":true])};return .init(value:["authorized":!disconnected,"linked":!disconnected])}
  try await service.restoreWeb();let renewal=Task{try await service.refreshWeb()};await settle{MembershipProtocol.heldCount == 1};var forceStarted=false;let forced=Task{forceStarted=true;try await service.refreshWeb(force:true)};await settle{forceStarted};await Task.yield();await service.disconnectWeb();MembershipProtocol.releaseHeld(.init(value:["authorized":true,"linked":true]));_=try? await renewal.value;_=try? await forced.value
  XCTAssertTrue(disconnected);XCTAssertFalse(service.webAuthorized);XCTAssertFalse(service.hasAccess);XCTAssertFalse(service.statusPayload["linked"].boolean)
 }

 func testRemoteSignerRenewsThroughCookieWithoutFurtherSigningAndStopsWhenCookieIsMissing()async throws{
  let(identity,_)=try context();defer{try? identity.disconnect()};let signer=LocalRemoteSigner();try await signer.start();defer{signer.stop()};try await identity.connect(signer.token)
  let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[MembershipProtocol.self];config.httpCookieStorage?.setCookie(try XCTUnwrap(HTTPCookie(properties:[.name:"__session",.value:"auth-session.remote-fixture",.domain:AppConfiguration().web.host!,.path:"/",.secure:"TRUE"])))
  var date=Date(),reads=0;let service=SubscriptionService(webSession:URLSession(configuration:config),now:{date});service.bind(identity);service.updatePracticeXP(300)
  MembershipProtocol.install{request in let path=request.url!.lastPathComponent;if path == "link-challenge"{return MembershipProtocol.challenge("restore")};if path == "status"{reads += 1};return .init(value:["authorized":true,"linked":true])}
  try await service.restoreWeb();let signed=signer.methods().filter{$0 == "sign_event"}.count;XCTAssertEqual(signed,1);service.setApplicationActive(true);date=date.addingTimeInterval(14*60);await service.maintainWebAccess();XCTAssertTrue(service.hasAccess);XCTAssertEqual(reads,1)
  for cookie in config.httpCookieStorage?.cookies ?? []{config.httpCookieStorage?.deleteCookie(cookie)}
  date=date.addingTimeInterval(16*60);await service.maintainWebAccess();XCTAssertEqual(reads,1);XCTAssertEqual(signer.methods().filter{$0 == "sign_event"}.count,signed);XCTAssertFalse(service.hasAccess)
 }

}
