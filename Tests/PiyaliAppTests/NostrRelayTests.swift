import XCTest
import Network
@testable import Piyali

final class NostrRelayTests: XCTestCase {
    func testEveryRelaySnapshotSurvivesAddressDedupAndForgedEventsAreIgnored() async throws {
        let older=try testNostrEvent(content:"{\"unlocked\":{\"legacy-one\":{\"unlockedAt\":1}}}",createdAt:100),newer=try testNostrEvent(content:"{\"unlocked\":{\"legacy-two\":{\"unlockedAt\":2}}}",createdAt:101)
        let a=LocalNostrRelay(),b=LocalNostrRelay();defer { a.stop();b.stop() }
        try await a.start { frame,connection in guard frame.first as? String == "REQ",let sub=frame[1] as? String else { return };a.send(["EVENT",sub,wireEvent(older)],to:connection);a.send(["EOSE",sub],to:connection) }
        try await b.start { frame,connection in guard frame.first as? String == "REQ",let sub=frame[1] as? String else { return };var forged=wireEvent(newer);forged["content"]="tampered";b.send(["EVENT",sub,forged],to:connection);b.send(["EVENT",sub,wireEvent(newer)],to:connection);b.send(["EOSE",sub],to:connection) }
        let client=NostrRelayClient(relays:[a.url,b.url],timeout:.seconds(2)),filter:[String:Any]=["kinds":[30078],"authors":[older.pubkey],"#d":["learning-achievements:nosabos"]]
        let snapshots=try await client.querySnapshots(filter:filter)
        XCTAssertEqual(Set(snapshots.map(\.id)),[older.id,newer.id])
        let latest=try await client.query(filter:filter);XCTAssertEqual(latest.map(\.id),[newer.id])
    }
    func testAuthenticationUsesSignedEphemeralProofThenRetriesQuery() async throws {
        let event=try testNostrEvent(),relay=LocalNostrRelay();defer { relay.stop() }
        var authenticated=false
        try await relay.start { frame,connection in
            if frame.first as? String == "REQ",let sub=frame[1] as? String {
                if authenticated { relay.send(["EVENT",sub,wireEvent(event)],to:connection);relay.send(["EOSE",sub],to:connection) }
                else { relay.send(["AUTH","local-challenge"],to:connection);relay.send(["CLOSED",sub,"auth-required: local test"],to:connection) }
            } else if frame.first as? String == "AUTH",let object=frame[1] as? [String:Any],let proof=try? JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:object)) {
                authenticated=proof.kind==22242 && proof.tag("relay")==relay.url && proof.tag("challenge")=="local-challenge" && proof.pubkey==event.pubkey && IdentityService.verify(proof)
                relay.send(["OK",proof.id,authenticated,""],to:connection)
            }
        }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2))
        let results=try await client.querySnapshots(filter:["kinds":[30078],"authors":[event.pubkey]],authenticate:{ url,challenge in try testNostrEvent(kind:22242,tags:[["relay",url],["challenge",challenge]]) })
        XCTAssertEqual(results.map(\.id),[event.id]);XCTAssertEqual(relay.frames().filter { $0.first as? String == "AUTH" }.count,1)
    }
    func testPublicationAuthenticatesThroughAUTHWithoutBroadcastingProof() async throws {
        let event=try testNostrEvent(),relay=LocalNostrRelay();defer { relay.stop() }
        var authenticated=false
        try await relay.start { frame,connection in
            if frame.first as? String == "EVENT",let object=frame[1] as? [String:Any],let id=object["id"] as? String {
                if authenticated { relay.send(["OK",id,true,""],to:connection) }
                else { relay.send(["AUTH","publication-challenge"],to:connection);relay.send(["OK",id,false,"auth-required: test"],to:connection) }
            } else if frame.first as? String == "AUTH",let object=frame[1] as? [String:Any],let proof=try? JSONDecoder().decode(NostrEventPayload.self,from:JSONSerialization.data(withJSONObject:object)) {
                authenticated=proof.kind==22242 && proof.pubkey==event.pubkey && proof.tag("challenge")=="publication-challenge" && proof.tag("relay")==relay.url && IdentityService.verify(proof)
                relay.send(["OK",proof.id,authenticated,""],to:connection)
            }
        }
        let client=NostrRelayClient(relays:[relay.url],timeout:.seconds(2))
        try await client.publish(event,authenticate:{ url,challenge in try testNostrEvent(kind:22242,tags:[["relay",url],["challenge",challenge]]) })
        XCTAssertEqual(relay.frames().filter { $0.first as? String == "AUTH" }.count,1)
        XCTAssertFalse(relay.frames().contains { $0.first as? String == "EVENT" && ($0[1] as? [String:Any])?["kind"] as? Int == 22242 })
    }
    func testUnrelatedAcknowledgmentAndMalformedEOSECannotConfirmPublication() async throws {
        let relay=LocalNostrRelay();defer { relay.stop() }
        try await relay.start { frame,connection in guard frame.first as? String == "EVENT" else { return };relay.send(["OK",String(repeating:"f",count:64),true,""],to:connection);relay.send(["EOSE",NSNull()],to:connection) }
        let client=NostrRelayClient(relays:[relay.url],timeout:.milliseconds(300))
        do { try await client.publish(try testNostrEvent());XCTFail("Missing matching acknowledgment must fail") } catch { }
    }
    func testPublicationReturnsOnFirstMatchingAcknowledgmentAndCancelsSlowRelay() async throws {
        let good=LocalNostrRelay(),slow=LocalNostrRelay();defer { good.stop();slow.stop() }
        try await good.start { frame,connection in guard frame.first as? String == "EVENT",let event=frame[1] as? [String:Any],let id=event["id"] as? String else { return };good.send(["OK",id,true,""],to:connection) }
        try await slow.start { _,_ in }
        let client=NostrRelayClient(relays:[good.url,slow.url],timeout:.seconds(4)),start=Date()
        try await client.publish(try testNostrEvent());XCTAssertLessThan(Date().timeIntervalSince(start),2)
    }
    func testEmptyCompletedReadIsSuccessAndUnrelatedSignedAuthorIsIgnored() async throws {
        let relay=LocalNostrRelay(),other=try testNostrEvent(keyHex:String(repeating:"0",count:63)+"2");defer { relay.stop() }
        try await relay.start { frame,connection in guard frame.first as? String == "REQ",let sub=frame[1] as? String else { return };relay.send(["EVENT",sub,wireEvent(other)],to:connection);relay.send(["EOSE",sub],to:connection) }
        let own=try testNostrEvent(),client=NostrRelayClient(relays:[relay.url,"ws://127.0.0.1:1"],timeout:.seconds(1))
        let results=try await client.querySnapshots(filter:["kinds":[30078],"authors":[own.pubkey]])
        XCTAssertTrue(results.isEmpty)
    }
}
