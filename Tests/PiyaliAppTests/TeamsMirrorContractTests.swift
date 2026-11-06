import XCTest
import FirebaseFirestore
import NostrSDK
@testable import Piyali

@MainActor final class TeamsMirrorContractTests:XCTestCase {
    func testActualFirebaseSDKPublicMirrorCreationMembershipRenameAddsAndDeparture()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated Firestore emulator opt-in required")}
        let db=PrivateTeamTestDatabase.database(),mirror=TeamsMirrorService(database:db),a=IdentityService(),b=IdentityService(),c=IdentityService();try a.create();try b.create();try c.create();defer{try? a.disconnect();try? b.disconnect();try? c.disconnect()};let id=UUID().uuidString.lowercased()
        try await mirror.create(id:id,name:"Weekend",members:[b.npub],creatorName:"Ada",identity:a)
        let joined=try await mirror.read(identity:b);XCTAssertEqual(joined.joined.count,1);XCTAssertEqual(joined.invites.first?["status"],.string("accepted"));XCTAssertEqual(joined.joined.first?["members"].array.first?["npub"],.string(b.npub))
        let renamedOK=try await mirror.rename(id:id,name:"Evening",identity:a);XCTAssertTrue(renamedOK);let renamed=try await mirror.read(identity:b);XCTAssertEqual(renamed.invites.first?["teamName"],.string("Evening"))
        let addedOK=try await mirror.add(id:id,members:[c.npub],creatorName:"Ada",identity:a);XCTAssertTrue(addedOK);let added=try await mirror.read(identity:c);XCTAssertEqual(added.joined.first?["members"].array.count,2)
        try await mirror.leave(creator:a.npub,id:id,identity:b);let departed=try await mirror.read(identity:b);XCTAssertTrue(departed.joined.isEmpty);let retained=try await mirror.read(identity:a);XCTAssertEqual(retained.owned.first?["members"].array.map{$0["npub"].string},[c.npub])
        try await mirror.delete(id:id,identity:a);let removed=try await mirror.read(identity:a),revoked=try await mirror.read(identity:c);XCTAssertTrue(removed.owned.isEmpty);XCTAssertTrue(revoked.invites.isEmpty)
    }
}


extension TeamsMirrorContractTests {
    func testActualFirebaseFirstWatchSnapshotCatchesARosterChangeAfterItsInitialRead()async throws {
        let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated local SDK required")}
        let db=PrivateTeamTestDatabase.database(),mirror=TeamsMirrorService(database:db),a=IdentityService(),b=IdentityService();try a.create();try b.create();defer{mirror.stopWatching();try? a.disconnect();try? b.disconnect()};let id=UUID().uuidString.lowercased()
        try await mirror.create(id:id,name:"Initial roster",members:[b.npub],creatorName:"Public creator",identity:a);let initial=try await mirror.read(identity:a)
        _=try await mirror.rename(id:id,name:"Changed before watch",identity:a);try await db.disableNetwork();var updates=0
        await mirror.watch(initial.owned,identity:a){updates += 1}
        for _ in 0..<100 where updates==0{try await Task.sleep(for:.milliseconds(10))};XCTAssertGreaterThan(updates,0,"The source onSnapshot applies its first snapshot, including changes after the initial read")
        mirror.stopWatching();try await db.enableNetwork();try await mirror.delete(id:id,identity:a)
    }
}

extension TeamsMirrorContractTests {
    func testOpenNativeCachedRosterShowsFirstMirrorSnapshotWithoutAServerRead()async throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated emulator and identity required")}
        let db=PrivateTeamTestDatabase.database(),app=AppModel();try app.identity.create();app.signedIn=true
        let relay=LocalNostrRelay();defer{relay.stop();app.signOut()};var events:[NostrEventPayload]=[]
        try await relay.start{frame,connection in
            guard frame.first as? String == "REQ",let id=frame[1] as? String else{return};for event in events{relay.send(["EVENT",id,wireEvent(event)],to:connection)};relay.send(["EOSE",id],to:connection)
        }
        let id=UUID().uuidString.lowercased(),member="npub10xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqpkge6d",template=LearningTeams.teamTemplate(id:id,name:"Signed initial",members:[app.identity.hex,try XCTUnwrap(PublicKey(npub:member)).hex],createdAt:1700000000)
        events=[try await app.identity.signEvent(kind:LearningTeams.kind,tags:template["tags"].array.map{$0.array.map(\.string)},content:template["content"].string,createdAt:1700000000,expectedAuthor:app.identity.hex)]
        let mirror=TeamsMirrorService(database:db),legacy=PrivateTeamsService(database:db),service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(1)),cacheDirectory:FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)),access=LiveTeamsPanelAccess(service:service,mirror:mirror,legacy:legacy)
        try await mirror.create(id:id,name:"Signed initial",members:[member],creatorName:"Public creator",identity:app.identity)
        let initial=try await access.load(app);XCTAssertEqual(initial.teams.first?["teamName"].string,"Signed initial")
        let renamed=try await mirror.rename(id:id,name:"Cached peer change",identity:app.identity);XCTAssertTrue(renamed)
        let confirmed=try await db.collection("users").document(app.identity.npub).collection("teams").document(id).getDocument(source:.server)
        XCTAssertEqual(confirmed.data()?["teamName"] as? String,"Cached peer change","Prime the actual changed document before testing a cache-only delivery")
        try await db.disableNetwork()
        let cached=try await db.collection("users").document(app.identity.npub).collection("teams").getDocuments(source:.cache)
        XCTAssertEqual(cached.documents.first?.data()["teamName"] as? String,"Cached peer change")
        var direct:[JSONValue]=[],invalidations=0
        await mirror.watch(initial.teams,identity:app.identity,includeInvites:false,onRoster:{direct.append($0)},onChange:{invalidations += 1})
        for _ in 0..<100 where direct.isEmpty{try await Task.sleep(for:.milliseconds(10))}
        XCTAssertEqual(direct.first?["teamName"].string,"Cached peer change","Typed SDK delivery must preserve cached snapshot data")
        mirror.stopWatching()
        let model=TeamsPanelController(access:access,initial:initial,initialOwner:app.identity.npub)
        var presented:[String]=[];let observation=model.$snapshot.sink{presented.append($0.teams.first?["teamName"].string ?? "none")};defer{observation.cancel()}
        await model.reload(app)
        for _ in 0..<200 where model.snapshot.teams.first?["teamName"].string != "Cached peer change"{try await Task.sleep(for:.milliseconds(10))}
        let trace:[String:Any] = ["direct":direct.map{$0["teamName"].string},"invalidations":invalidations,"presented":presented,"error":model.error ?? "","rowErrors":model.rowErrors,"signedNames":service.teams.map(\.name),"requests":relay.frames().filter{$0.first as? String == "REQ"}.map{$0.last as? [String:Any] ?? [:]}]
        let evidence=XCTAttachment(data:try JSONSerialization.data(withJSONObject:trace,options:[.sortedKeys]),uniformTypeIdentifier:"public.json");evidence.name="Cached native roster delivery trace";evidence.lifetime = .keepAlways;add(evidence)
        XCTAssertEqual(model.snapshot.teams.first?["teamName"].string,"Cached peer change","The original TeamView applies the cached snapshot directly while fresh reads are unavailable")
        XCTAssertEqual(service.teams.first?.name,"Signed initial","A Firebase display patch must not rewrite signed roster authority")
        model.cancel();try await db.enableNetwork();try await mirror.delete(id:id,identity:app.identity)
    }
}
