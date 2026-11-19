import XCTest
@testable import PiyaliCore

final class VoiceJourneyTests:XCTestCase {
    private var root:URL{URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    func testActualWebAESGCMEnvelopeOpensAndRejectsDifferentBindings()throws {
        let vector=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/journey-crypto.json"))),raw=vector["envelope"],envelope=JourneyEnvelope(wrappedKey:raw["wrappedKey"].string,iv:try XCTUnwrap(Data(base64Encoded:raw["iv"].string)),ciphertext:try XCTUnwrap(Data(base64Encoded:raw["ciphertext"].string))),key=try JourneyCryptography.key(vector["key"].string)
        XCTAssertEqual(try JourneyCryptography.open(envelope,key:key,account:vector["npub"].string,target:"es",milestone:5),vector["payload"])
        XCTAssertEqual(try JourneyCryptography.seal(vector["payload"],key:key,nonce:envelope.iv,account:vector["npub"].string,target:"es",milestone:5),envelope.ciphertext)
        for (account,target,milestone) in [("other","es",5),(vector["npub"].string,"fr",5),(vector["npub"].string,"es",1)]{XCTAssertThrowsError(try JourneyCryptography.open(envelope,key:key,account:account,target:target,milestone:milestone))}
        var tampered=envelope.ciphertext;tampered[0] ^= 1;XCTAssertThrowsError(try JourneyCryptography.open(.init(wrappedKey:envelope.wrappedKey,iv:envelope.iv,ciphertext:tampered),key:key,account:vector["npub"].string,target:"es",milestone:5))
    }
    @MainActor func testNativeMilestonesAgreeWithActualSourcePolicy()throws {
        let policy=try MemorySourcePolicy(source:root.appendingPathComponent("Piyali/Resources/memory-policy.js"))
        for count in 0...160{for records:JSONValue in [.object([:]),.object(["1":.object(["createdAt":.string("2026-10-20T12:00:00Z")]),"5":.object(["createdAt":.string("2026-10-19T12:00:00Z")])])]{
            let data=JSONValue.object(["completedQuests":.number(Double(count)),"recordings":records]),source=try policy.value("journey",.object(["data":data]));XCTAssertEqual(VoiceJourneyModel.count(data),Int(source["count"].number));XCTAssertEqual(VoiceJourneyModel.baseline(data),source["baseline"] == .null ? nil:Int(source["baseline"].number));XCTAssertEqual(VoiceJourneyModel.pending(data),source["pending"] == .null ? nil:Int(source["pending"].number))
            for row in source["milestones"].array{let n=Int(row["number"].number);XCTAssertEqual(VoiceJourneyModel.canRecord(data,n),row["ready"].boolean);XCTAssertEqual(VoiceJourneyModel.expired(data,n),row["expired"].boolean)}
        }}
        for prompted:JSONValue in [.string("5"),.string("garbage"),.number(5),.null,.bool(true)] {let data=JSONValue.object(["completedQuests":.number(5),"lastPromptedMilestone":prompted]),source=try policy.value("journey",.object(["data":data]));XCTAssertEqual(VoiceJourneyModel.pending(data),source["pending"] == .null ? nil:Int(source["pending"].number))}
        for n:JSONValue in [.string("5"),.bool(true),.null,.number(-2.5)]{let data=JSONValue.object(["completedQuests":n]);XCTAssertEqual(VoiceJourneyModel.count(data),Int(try policy.value("journey",.object(["data":data]))["count"].number))}
    }
}
