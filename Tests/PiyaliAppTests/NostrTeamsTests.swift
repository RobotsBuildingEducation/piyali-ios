import XCTest
import NostrSDK
@testable import Piyali

@MainActor final class NostrTeamsTests: XCTestCase {
    private func identity() throws -> IdentityService {
        guard ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Use scripts/test-nostr.sh for isolated Keychain identities.") }
        let identity=IdentityService();try identity.create();return identity
    }
    private func npub(_ key: String) throws -> String { try XCTUnwrap(PublicKey(hex:key)?.npub) }
    private func relay(events initial: [NostrEventPayload] = [], rejectPublication: Bool = false) async throws -> LocalNostrRelay {
        let relay=LocalNostrRelay();var events=initial
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String { for event in events { relay.send(["EVENT",sub,wireEvent(event)],to:connection) };relay.send(["EOSE",sub],to:connection) }
            else if frame.first as? String == "EVENT",let data=frame[1] as? [String:Any],let bytes=try? JSONSerialization.data(withJSONObject:data),let event=try? JSONDecoder().decode(NostrEventPayload.self,from:bytes) {
                let accepted=IdentityService.verify(event) && !rejectPublication
                if accepted { events.append(event) };relay.send(["OK",event.id,accepted,accepted ? "" : "blocked: local fixture"],to:connection)
            }
        }
        return relay
    }
    func testCreationConcurrentRenameAndAddReadLatestRosterBeforeSigning() async throws {
        let identity=try identity(),member=try testNostrEvent(keyHex:String(repeating:"0",count:63)+"2"),extra=try testNostrEvent(keyHex:String(repeating:"0",count:63)+"3")
        let profile=try testNostrEvent(kind:0,tags:[],content:"{\"display_name\":\" Bea \"}",createdAt:102,keyHex:String(repeating:"0",count:63)+"2")
        let old=try testNostrEvent(tags:[["d","learning-progress"]],content:"{\"schemaVersion\":1,\"name\":\"Old\"}",createdAt:100,keyHex:String(repeating:"0",count:63)+"2")
        let progress=try testNostrEvent(tags:[["d","learning-progress"]],content:"{\"schemaVersion\":2,\"name\":\"Published\",\"scoreScale\":\"0-100\",\"score\":42,\"targetLang\":\"es\",\"xp\":321}",createdAt:101,keyHex:String(repeating:"0",count:63)+"2")
        let relay=try await relay(events:[profile,old,progress]);defer { relay.stop() }
        let service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        try await service.create(name:"Weekend",members:try npub(member.pubkey),identity:identity)
        let initial=try XCTUnwrap(service.teams.first);XCTAssertEqual(Set(initial.members),[identity.hex,member.pubkey])
        async let rename:Void=service.rename(initial,name:"New name",identity:identity)
        async let add:Void=service.addMembers(initial,members:try npub(extra.pubkey),identity:identity)
        _=try await(rename,add)
        let updated=try XCTUnwrap(service.teams.first);XCTAssertEqual(updated.name,"New name");XCTAssertEqual(Set(updated.members),[identity.hex,member.pubkey,extra.pubkey]);XCTAssertGreaterThan(updated.event.created_at,initial.event.created_at)
        let row=service.row(member:member.pubkey,team:updated,learner:LearnerState(),viewer:identity.hex)
        XCTAssertEqual(row["name"].string,"Bea");XCTAssertEqual(row["score"].number,42);XCTAssertEqual(row["totalXp"].number,321)
        let published=relay.frames().filter { $0.first as? String == "EVENT" }.compactMap { try? JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:$0[1])) }
        XCTAssertEqual(published.count,3);XCTAssertTrue(published.allSatisfy { IdentityService.verify($0) && $0.pubkey == identity.hex && $0.tag("d") == initial.event.tag("d") });XCTAssertFalse(service.busy)
        do { try await service.addMembers(updated,members:try npub(member.pubkey),identity:identity);XCTFail("Duplicate membership must not publish") } catch { }
        XCTAssertEqual(relay.frames().filter { $0.first as? String == "EVENT" }.count,3)
        try await service.leave(updated,identity:identity);XCTAssertTrue(service.teams.isEmpty)
        let deletion=try JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:relay.frames().last { $0.first as? String == "EVENT" }![1]))
        XCTAssertTrue(deletion.tags.contains(["deleted"]));XCTAssertGreaterThan(deletion.created_at,updated.event.created_at)
    }
    func testOtherMembersLeaveIsFilteredAndNewerInvitationRestoresMembership() async throws {
        let identity=try identity(),creator=try testNostrEvent(),other=try testNostrEvent(keyHex:String(repeating:"0",count:63)+"2"),id="local-team"
        let tags=[["d",LearningTeams.teamIdentifier(id)],["t","learning-team"],["name","Study"],["p",creator.pubkey],["p",identity.hex],["p",other.pubkey]]
        let team=try testNostrEvent(tags:tags,createdAt:100)
        let departure=try testNostrEvent(tags:[["d",LearningTeams.leaveIdentifier(creator:creator.pubkey,id:id)],["t","learning-team-left"]],createdAt:101,keyHex:String(repeating:"0",count:63)+"2")
        let relay=try await relay(events:[team,departure]);defer { relay.stop() }
        let service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        await service.refresh(identity:identity);let current=try XCTUnwrap(service.teams.first)
        XCTAssertFalse(current.members.contains(other.pubkey));XCTAssertTrue(current.members.contains(identity.hex))
        do { try await service.rename(current,name:"Unauthorized",identity:identity);XCTFail("Member cannot rename") } catch { }
        try await service.leave(current,identity:identity);XCTAssertTrue(service.teams.isEmpty)
        let published=try JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:relay.frames().last { $0.first as? String == "EVENT" }![1]))
        XCTAssertTrue(IdentityService.verify(published));XCTAssertEqual(published.tag("a"),"30078:\(creator.pubkey):learning-team:local-team");XCTAssertEqual(published.content,"")
        let reInvite=try testNostrEvent(tags:tags,createdAt:published.created_at+1)
        try await NostrRelayClient(relays:[relay.url],timeout:.seconds(2)).publish(reInvite)
        await service.refresh(identity:identity);XCTAssertEqual(Set(try XCTUnwrap(service.teams.first).members),[creator.pubkey,identity.hex,other.pubkey])
    }
    func testRefreshAuthenticatesAndAccountChangeClearsOldRoster() async throws {
        let identity=try identity(),initial=identity.hex,relay=LocalNostrRelay();defer { relay.stop() }
        var authenticated=false
        let event=try identity.sign(kind:30078,tags:[["d","learning-team:local"],["t","learning-team"],["p",initial]],content:"{}",createdAt:100)
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String {
                if authenticated { relay.send(["EVENT",sub,wireEvent(event)],to:connection);relay.send(["EOSE",sub],to:connection) }
                else { relay.send(["AUTH","team-challenge"],to:connection);relay.send(["CLOSED",sub,"auth-required: test"],to:connection) }
            } else if frame.first as? String == "AUTH",let object=frame[1] as? [String:Any],let proof=try? JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:object)) {
                authenticated=proof.pubkey == initial && proof.kind == 22242 && proof.tag("relay") == relay.url && proof.tag("challenge") == "team-challenge" && IdentityService.verify(proof)
                relay.send(["OK",proof.id,authenticated,""],to:connection)
            }
        }
        let service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        await service.refresh(identity:identity);XCTAssertEqual(service.teams.count,1);XCTAssertTrue(authenticated)
        try identity.create();await service.refresh(identity:identity);XCTAssertTrue(service.teams.isEmpty);XCTAssertTrue(service.progress.isEmpty);XCTAssertTrue(service.profiles.isEmpty)
        XCTAssertFalse(relay.frames().contains { $0.first as? String == "EVENT" })
    }
    func testAccountSwitchDuringRelayReadCannotRestorePreviousAccountRoster() async throws {
        let identity=try identity(),author=identity.hex,relay=LocalNostrRelay();defer { relay.stop() }
        let event=try identity.sign(kind:30078,tags:[["d","learning-team:delayed"],["t","learning-team"],["p",author]],content:"{}",createdAt:100)
        try await relay.start { frame,connection in
            guard frame.first as? String == "REQ",let sub=frame[1] as? String else { return }
            Task { try? await Task.sleep(for:.milliseconds(300));relay.send(["EVENT",sub,wireEvent(event)],to:connection);relay.send(["EOSE",sub],to:connection) }
        }
        let service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        let task=Task { await service.refresh(identity:identity) }
        let deadline=Date().addingTimeInterval(2)
        while relay.frames().isEmpty && Date() < deadline { try await Task.sleep(for:.milliseconds(20)) }
        XCTAssertFalse(relay.frames().isEmpty);try identity.create();await task.value
        XCTAssertTrue(service.teams.isEmpty);XCTAssertTrue(service.progress.isEmpty);XCTAssertFalse(service.busy);XCTAssertNil(service.error)
    }
    func testAcknowledgedOwnTeamSurvivesRelayIndexingDelayAndRestart() async throws {
        let identity=try identity(),member=try testNostrEvent(),relay=LocalNostrRelay();defer { relay.stop() }
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String { relay.send(["EOSE",sub],to:connection) }
            else if frame.first as? String == "EVENT",let object=frame[1] as? [String:Any],let id=object["id"] as? String { relay.send(["OK",id,true,""],to:connection) }
        }
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent("PiyaliTeamCache-"+UUID().uuidString,isDirectory:true)
        defer { try? FileManager.default.removeItem(at:directory) }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),service=NostrTeamsService(client:client,cacheDirectory:directory)
        try await service.create(name:"Indexed later",members:try npub(member.pubkey),identity:identity)
        let team=try XCTUnwrap(service.teams.first)
        let restored=NostrTeamsService(client:client,cacheDirectory:directory);await restored.refresh(identity:identity)
        XCTAssertEqual(restored.teams.first?.id,team.id)
        try await restored.rename(team,name:"Renamed",identity:identity);XCTAssertEqual(restored.teams.first?.name,"Renamed")
        try await restored.leave(try XCTUnwrap(restored.teams.first),identity:identity);XCTAssertTrue(restored.teams.isEmpty)
        let deleted=NostrTeamsService(client:client,cacheDirectory:directory);await deleted.refresh(identity:identity);XCTAssertTrue(deleted.teams.isEmpty)
    }
    func testOptInLiveTeamReadDoesNotPublish() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_NOSTR"] == "1" else { throw XCTSkip("Set TEST_RUNNER_PIYALI_LIVE_NOSTR=1 for public team relay reads.") }
        let identity=try identity(),service=NostrTeamsService()
        await service.refresh(identity:identity)
        XCTAssertNil(service.error);XCTAssertTrue(service.teams.isEmpty);XCTAssertTrue(service.progress.isEmpty)
    }
    func testUnavailableProgressDoesNotRemoveVerifiedTeamMembership() async throws {
        let identity=try identity(),creator=try testNostrEvent(),relay=LocalNostrRelay();defer { relay.stop() }
        let event=try testNostrEvent(tags:[["d","learning-team:available"],["t","learning-team"],["p",creator.pubkey],["p",identity.hex]],createdAt:100)
        try await relay.start { frame,connection in
            guard frame.first as? String == "REQ",let sub=frame[1] as? String,let filter=frame.last as? [String:Any] else { return }
            if filter["#d"] as? [String] == ["learning-progress"] { relay.send(["CLOSED",sub,"blocked: progress temporarily unavailable"],to:connection) }
            else { relay.send(["EVENT",sub,wireEvent(event)],to:connection);relay.send(["EOSE",sub],to:connection) }
        }
        let service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        await service.refresh(identity:identity)
        let team=try XCTUnwrap(service.teams.first);XCTAssertEqual(Set(team.members),[identity.hex,creator.pubkey]);XCTAssertNil(service.error)
        XCTAssertEqual(service.row(member:creator.pubkey,team:team,learner:LearnerState(),viewer:identity.hex)["score"],.null)
    }
    func testExplicitProgressPublicationSignsOnlyPublicSnapshotFields() async throws {
        let identity=try identity(),relay=try await relay();defer { relay.stop() }
        let service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        var state=LearnerState();state.name="Ada";state.dailyGoal=30;state.dailyXP=20;state.notes=[Note(title:"Private",body:"Secret note")]
        var draft=ConversationDraft();draft.append(.init(role:"user",text:"Private conversation"));state.saveConversation(draft)
        await service.refresh(identity:identity);XCTAssertTrue(relay.frames().filter { $0.first as? String == "EVENT" }.isEmpty)
        try await service.publishProgress(state,identity:identity)
        let frame=try XCTUnwrap(relay.frames().first { $0.first as? String == "EVENT" }),event=try JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:frame[1]))
        XCTAssertTrue(IdentityService.verify(event));XCTAssertEqual(event.pubkey,identity.hex);XCTAssertEqual(event.tag("d"),"learning-progress");XCTAssertEqual(event.tag("t"),"learning-progress")
        let body=try JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8))
        XCTAssertEqual(body["schemaVersion"].number,2);XCTAssertEqual(body["progressPercent"].number,67);XCTAssertEqual(body["name"].string,"Ada");XCTAssertEqual(body["scoreScale"].string,"0-100")
        XCTAssertFalse(event.content.contains("Secret note"));XCTAssertFalse(event.content.contains("Private conversation"));XCTAssertNil(body.object["notes"]);XCTAssertNil(body.object["conversationDrafts"])
    }
    func testRejectedPublicationAndForgedTeamCannotEnterRoster() async throws {
        let identity=try identity(),member=try testNostrEvent(),valid=try identity.sign(kind:30078,tags:[["d","learning-team:local"],["t","learning-team"],["p",identity.hex]],content:"{}",createdAt:100)
        let forged=NostrEventPayload(id:valid.id,pubkey:valid.pubkey,created_at:valid.created_at,kind:valid.kind,tags:valid.tags,content:"tampered",sig:valid.sig)
        XCTAssertNil(NostrTeamsService.parse(forged))
        let relay=try await relay(events:[forged],rejectPublication:true);defer { relay.stop() }
        let service=NostrTeamsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)))
        do { try await service.create(name:"Study",members:try npub(member.pubkey),identity:identity);XCTFail("Rejection must not appear successful") } catch { }
        XCTAssertTrue(service.teams.isEmpty);XCTAssertNotNil(service.error);XCTAssertFalse(service.busy)
        await service.refresh(identity:identity);XCTAssertTrue(service.teams.isEmpty)
    }
}
