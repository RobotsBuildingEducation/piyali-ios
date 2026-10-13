import XCTest
@testable import Piyali

@MainActor final class NostrAchievementTests: XCTestCase {
    private func identity() throws -> IdentityService {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Use scripts/test-nostr.sh for isolated Keychain identities.") }
        let identity=IdentityService();try identity.create();return identity
    }
    func testOptInLiveRelayReadDoesNotPublishCollection() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_NOSTR"] == "1" else { throw XCTSkip("Set TEST_RUNNER_PIYALI_LIVE_NOSTR=1 with scripts/test-nostr.sh for public relay reads.") }
        let identity=try identity(),service=NostrAchievementsService()
        let result=try await service.read(identity:identity)
        XCTAssertTrue(result.events.allSatisfy { $0.pubkey == identity.hex && IdentityService.verify($0) })
        // A fresh isolated key has no published collection; this method only reads and performs ephemeral AUTH if required.
        XCTAssertTrue(result.records.object.isEmpty)
    }
    func testParserRequiresMatchingAuthorAddressKindAndSignature() throws {
        let event=try testNostrEvent(content:"{\"unlocked\":{\"legacy-slot\":{\"unlockedAt\":1}}}")
        XCTAssertEqual(NostrAchievementsService.parse(event,author:event.pubkey)?["legacy-slot"]["unlockedAt"].number,1)
        XCTAssertNil(NostrAchievementsService.parse(event,author:String(repeating:"f",count:64)))
        let unrelated=try testNostrEvent(tags:[["d","unrelated"]]);XCTAssertNil(NostrAchievementsService.parse(unrelated,author:unrelated.pubkey))
        let wrongKind=try testNostrEvent(kind:1);XCTAssertNil(NostrAchievementsService.parse(wrongKind,author:wrongKind.pubkey))
        let tampered=NostrEventPayload(id:event.id,pubkey:event.pubkey,created_at:event.created_at,kind:event.kind,tags:event.tags,content:"tampered",sig:event.sig)
        XCTAssertNil(NostrAchievementsService.parse(tampered,author:event.pubkey))
    }
    func testRestoreAndPublishPreserveLegacyOtherHostAndAwardsEarnedDuringImport() async throws {
        let identity=try identity(),relay=LocalNostrRelay();defer { relay.stop() }
        func signed(_ d: String,_ records: [String:Any]) throws -> NostrEventPayload { try identity.sign(kind:30078,tags:[["d",d],["t","learning-achievements"]],content:JSONValue.foundation(["unlocked":records]).json,createdAt:100) }
        let events=[try signed("learning-achievements",["legacy-slot":["unlockedAt":4],"robots_full_curriculum_v4":["unlockedAt":5,"source":"robotsbuildingeducation"]]),try signed("learning-achievements:nosabos",["piyali_tutor_complete_b2":["unlockedAt":10,"source":"nosabos"]])]
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String { for event in events { relay.send(["EVENT",sub,wireEvent(event)],to:connection) };relay.send(["EOSE",sub],to:connection) }
            else if frame.first as? String == "EVENT",let event=frame[1] as? [String:Any] { relay.send(["OK",event["id"]!,true,""],to:connection) }
        }
        let service=NostrAchievementsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        var local=JSONValue.foundation(["piyali_full_curriculum_v4":["unlockedAt":20,"source":"nosabos"]]),persisted=false
        let restored=try await service.synchronize(identity:identity,publish:true,current:{ local },persist:{ records in
            persisted=true;local=NostrAchievementCollection.merging([records,JSONValue.foundation(["nosabos_phonics_decks_1":["unlockedAt":30,"source":"nosabos"]])])
        })
        XCTAssertTrue(persisted);XCTAssertEqual(restored["two_worlds_complete_v4"]["unlockedAt"].number,20)
        XCTAssertEqual(restored["legacy-slot"]["unlockedAt"].number,4);XCTAssertEqual(restored["nosabos_phonics_decks_1"]["unlockedAt"].number,30)
        let frame=try XCTUnwrap(relay.frames().first { $0.first as? String == "EVENT" }),payload=try JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:frame[1]))
        XCTAssertTrue(IdentityService.verify(payload));XCTAssertEqual(payload.pubkey,identity.hex);XCTAssertEqual(payload.tag("d"),"learning-achievements:nosabos");XCTAssertGreaterThan(payload.created_at,100)
        XCTAssertEqual(NostrAchievementsService.parse(payload,author:identity.hex),restored)
        XCTAssertFalse(service.busy);XCTAssertNil(service.error)
    }
    func testUnchangedOwnCollectionDoesNotPublishAgain() async throws {
        let identity=try identity(),relay=LocalNostrRelay();defer { relay.stop() }
        let records=JSONValue.foundation(["legacy-slot":["unlockedAt":7,"source":"nosabos","catalogVersion":8]])
        let event=try identity.sign(kind:30078,tags:[["d","learning-achievements:nosabos"]],content:NostrAchievementCollection.body(records,createdAt:100).json,createdAt:100)
        try await relay.start { frame,connection in guard frame.first as? String == "REQ",let sub=frame[1] as? String else { return };relay.send(["EVENT",sub,wireEvent(event)],to:connection);relay.send(["EOSE",sub],to:connection) }
        let service=NostrAchievementsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        _=try await service.synchronize(identity:identity,publish:true,current:{ records },persist:{ _ in })
        XCTAssertTrue(relay.frames().filter { $0.first as? String == "EVENT" }.isEmpty)
    }
    func testOverlappingRequestsSerializePersistence() async throws {
        let identity=try identity(),relay=LocalNostrRelay();defer { relay.stop() }
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String { relay.send(["EOSE",sub],to:connection) }
        }
        let service=NostrAchievementsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        var active=0,maximum=0,completed=0
        let tasks=(0..<3).map { _ in Task { @MainActor in
            try await service.synchronize(identity:identity,publish:false,current:{ .object([:]) },persist:{ _ in
                active += 1;maximum=max(maximum,active)
                try await Task.sleep(for:.milliseconds(100))
                active -= 1;completed += 1
            })
        }}
        for task in tasks { _=try await task.value }
        XCTAssertEqual(maximum,1);XCTAssertEqual(completed,3);XCTAssertFalse(service.busy)
    }
    func testAccountSwitchCancelsPendingReadWithoutImportOrPublication() async throws {
        let identity=try identity(),relay=LocalNostrRelay(),requested=expectation(description:"Read reached local relay");defer { relay.stop() }
        try await relay.start { frame,_ in if frame.first as? String == "REQ" { requested.fulfill() } }
        let service=NostrAchievementsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        var imported=false
        let task=Task { try await service.synchronize(identity:identity,publish:true,current:{ .object([:]) },persist:{ _ in imported=true }) }
        await fulfillment(of:[requested],timeout:2);service.cancel();try identity.create()
        do { _=try await task.value;XCTFail("Cancelled account operation must not finish") } catch { }
        XCTAssertFalse(imported);XCTAssertFalse(service.busy);XCTAssertNil(service.error)
        XCTAssertTrue(relay.frames().filter { $0.first as? String == "EVENT" }.isEmpty)
    }
}
