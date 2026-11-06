import XCTest
@testable import Piyali

@MainActor final class CommunityFeedTests:XCTestCase {
    func testSignedPostsKeepMultipleNotesPerAuthorFilterMetadataAndCache() async throws {
        let relay=LocalNostrRelay();defer { relay.stop() }
        let posts=try [testNostrEvent(kind:1,tags:[["t","LearnWithNostr"]],content:"Finished question 30",createdAt:100),testNostrEvent(kind:1,tags:[["t","learnwithnostr"],["purpose","nosaboProgress"],["total_xp","123"],["daily_goal_percent","125"]],content:"I just reached 123 XP",createdAt:102),testNostrEvent(kind:1,tags:[["t","unrelated"]],content:"question 90",createdAt:103)]
        let old=try testNostrEvent(kind:0,tags:[["d","metadata-ignores-this"]],content:"{\"name\":\"test\"}",createdAt:1),profile=try testNostrEvent(kind:0,tags:[],content:"{\"name\":\"Ada\"}",createdAt:2)
        try await relay.start { frame,connection in
            guard frame.first as? String == "REQ",let sub=frame[1] as? String else { return }
            for event in posts+[old,profile,posts[0]] { relay.send(["EVENT",sub,wireEvent(event)],to:connection) }
            var forged=wireEvent(posts[0]);forged["content"]="question 120 tampered";relay.send(["EVENT",sub,forged],to:connection);relay.send(["EOSE",sub],to:connection)
        }
        let service=CommunityFeedService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(1))),date=Date()
        async let a:Void=service.refresh(account:"one",now:date)
        async let b:Void=service.refresh(account:"one",now:date)
        _=await(a,b)
        XCTAssertEqual(service.cachedPosts(account:"one")?.count,2);XCTAssertNil(service.cachedPosts(account:"two"));XCTAssertEqual(service.posts.map(\.id),[posts[1].id,posts[0].id]);XCTAssertEqual(service.posts.map(\.name),["Ada","Ada"])
        XCTAssertEqual(service.posts[0].milestone.goalPercent,100);XCTAssertEqual(service.posts[1].milestone.questionPercent,25)
        XCTAssertEqual(relay.frames().count,2)
        await service.refresh(account:"one",now:date.addingTimeInterval(119));XCTAssertEqual(relay.frames().count,2)
        await service.refresh(account:"one",force:true);XCTAssertEqual(relay.frames().count,4)
        relay.stop();await service.refresh(account:"one",force:true);XCTAssertNotNil(service.error);XCTAssertEqual(service.posts.count,2)
        await service.refresh(account:"one",now:date);XCTAssertNil(service.error,"A still-valid cache is a successful load after a failed forced refresh")
        await service.refresh(account:"two",force:true);XCTAssertNotNil(service.error);XCTAssertTrue(service.posts.isEmpty)
    }
    func testCancellationCannotPopulateAnotherAccountOrKeepBusy() async throws {
        let relay=LocalNostrRelay();defer { relay.stop() };try await relay.start { _,_ in }
        let service=CommunityFeedService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        let task=Task { await service.refresh(account:"one") };try await Task.sleep(for:.milliseconds(80));service.cancel(clear:true);await task.value
        XCTAssertFalse(service.busy);XCTAssertTrue(service.posts.isEmpty);XCTAssertNil(service.error)
    }
    func testPublicationCannotUseAChangedPreviewIdentity() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Use isolated Keychain test environment.") }
        let identity=IdentityService();try identity.create();defer { try? identity.disconnect() }
        let oldAuthor=identity.hex;try identity.create()
        let relay=LocalNostrRelay();defer { relay.stop() };try await relay.start { _,_ in }
        let service=CommunityFeedService(client:NostrRelayClient(relays:[relay.url],timeout:.milliseconds(200)))
        do { try await service.publish(LearnerState(),identity:identity,expectedAuthor:oldAuthor);XCTFail("Stale preview must fail") } catch is CancellationError { }
        XCTAssertTrue(relay.frames().isEmpty)
    }
    func testEmptyFeedExpiresQuicklyAndDoesNotFetchAllProfiles() async throws {
        let relay=LocalNostrRelay();defer { relay.stop() }
        try await relay.start { frame,connection in if frame.first as? String == "REQ",let sub=frame[1] as? String { relay.send(["EOSE",sub],to:connection) } }
        let service=CommunityFeedService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(1))),date=Date()
        XCTAssertNil(service.cachedPosts(account:"one"));await service.refresh(account:"one",now:date);XCTAssertEqual(service.cachedPosts(account:"one")?.count,0);await service.refresh(account:"one",now:date.addingTimeInterval(14));XCTAssertEqual(relay.frames().count,1)
        await service.refresh(account:"one",now:date.addingTimeInterval(16));XCTAssertEqual(relay.frames().count,2)
        XCTAssertFalse(relay.frames().contains { $0.first as? String == "EVENT" })
    }
}


extension CommunityFeedTests {
    func testMainProductNostrFailureResolvesToCachedEmptyLikeOriginalAdapterWithoutErasingDiagnostics()async throws {
        let relay=LocalNostrRelay();defer{relay.stop()};var failure=false
        let post=try testNostrEvent(kind:1,tags:[["t","LearnWithNostr"]],content:"Finished question 30")
        try await relay.start{frame,connection in guard frame.first as? String == "REQ",let id=frame[1] as? String else{return};if failure{relay.send(["CLOSED",id,"Public relay unavailable"],to:connection)}else{relay.send(["EVENT",id,wireEvent(post)],to:connection);relay.send(["EOSE",id],to:connection)}}
        let service=CommunityFeedService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(1))),date=Date()
        await service.refresh(account:"main-product",now:date,failureAsEmpty:true);XCTAssertEqual(service.posts.count,1)
        failure=true;await service.refresh(account:"main-product",force:true,now:date.addingTimeInterval(1),failureAsEmpty:true);XCTAssertTrue(service.posts.isEmpty);XCTAssertNotNil(service.error);XCTAssertEqual(service.cachedPosts(account:"main-product")?.count,0)
        let before=relay.frames().count;await service.refresh(account:"main-product",now:date.addingTimeInterval(15),failureAsEmpty:true);XCTAssertEqual(relay.frames().count,before);XCTAssertNil(service.error)
        await service.refresh(account:"main-product",now:date.addingTimeInterval(17),failureAsEmpty:true);XCTAssertGreaterThan(relay.frames().count,before);XCTAssertTrue(service.posts.isEmpty);XCTAssertNotNil(service.error)
    }
}
