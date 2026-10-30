import XCTest
import FirebaseFirestore
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
