import XCTest
import FirebaseCore
import FirebaseFirestore
import FirebaseAppCheck
import NostrSDK
@testable import Piyali

@MainActor final class TeamsPanelFailureTests:XCTestCase {
    func testRejectedFirebaseMirrorRollsBackNewSignedRoster()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_RULES_EMULATOR_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated rules emulator on 8280 required")}
        let name="TeamsDeniedMirrorContract"
        if FirebaseApp.app(name:name)==nil{let options=FirebaseOptions(googleAppID:"1:123456789012:ios:0123456789abcdef012345",gcmSenderID:"123456789012");options.apiKey="emulator-only-not-a-production-key";options.projectID="demo-piyali-ios-auth";AppCheck.setAppCheckProviderFactory(TeamFailureFactory());FirebaseApp.configure(name:name,options:options)}
        let db=Firestore.firestore(app:FirebaseApp.app(name:name)!);db.useEmulator(withHost:"127.0.0.1",port:8280);let settings=db.settings;settings.cacheSettings=MemoryCacheSettings();settings.isSSLEnabled=false;db.settings=settings
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{frame,connection in if frame.first as? String == "REQ",let sub=frame[1] as? String{relay.send(["EOSE",sub],to:connection)}else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String{relay.send(["OK",id,true,""],to:connection)}}
        let app=AppModel();try app.identity.create();defer{try? app.identity.disconnect()};let service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),cacheDirectory:FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)),access=LiveTeamsPanelAccess(service:service,mirror:TeamsMirrorService(database:db),legacy:PrivateTeamsService(database:db))
        do{try await access.create(name:"Rollback",members:[Keypair()!.publicKey.npub],app:app);XCTFail("A denied mirror write must fail team creation")}catch{XCTAssertEqual((error as NSError).code,FirestoreErrorCode.permissionDenied.rawValue)}
        XCTAssertTrue(service.teams.isEmpty);let events=try relay.frames().filter{$0.first as? String == "EVENT"}.map{try JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:$0[1]))};XCTAssertEqual(events.count,2);XCTAssertTrue(events.allSatisfy{IdentityService.verify($0)});XCTAssertEqual(events.first?.tag("d"),events.last?.tag("d"));XCTAssertFalse(events[0].tags.contains(["deleted"]));XCTAssertTrue(events[1].tags.contains(["deleted"]))
    }
}
private final class TeamFailureProvider:NSObject,AppCheckProvider{func getToken(completion:@escaping(AppCheckToken?,Error?)->Void){completion(AppCheckToken(token:"local-emulator-token",expirationDate:Date().addingTimeInterval(3600)),nil)}}
private final class TeamFailureFactory:NSObject,AppCheckProviderFactory{func createProvider(with app:FirebaseApp)->AppCheckProvider?{TeamFailureProvider()}}
