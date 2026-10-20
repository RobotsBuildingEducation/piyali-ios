import XCTest
import FirebaseCore
import FirebaseFirestore
import FirebaseAppCheck
import NostrSDK
@testable import Piyali

@MainActor final class PrivateTeamsContractTests:XCTestCase {
    private func context() throws -> (Firestore,IdentityService,IdentityService,IdentityService) {
        guard ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_TESTS"] == "1",ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { throw XCTSkip("Use the isolated private-team Firestore emulator script.") }
        let db=PrivateTeamTestDatabase.database()
        let a=IdentityService(),b=IdentityService(),c=IdentityService();try a.create();try b.create();try c.create();return(db,a,b,c)
    }
    func testInviteAcceptProgressRenameConcurrentAddsLeaveAndDeleteUseActualSDK() async throws {
        let (db,a,b,c)=try context(),owner=PrivateTeamsService(database:db),member=PrivateTeamsService(database:db)
        defer { try? a.disconnect();try? b.disconnect();try? c.disconnect() }
        try await owner.create(name:" Weekend ",members:b.npub,creatorName:"Ada",identity:a)
        var team=try XCTUnwrap(owner.teams.first);XCTAssertEqual(team.name,"Weekend");XCTAssertEqual(team.members.first?["status"],.string("pending"))
        try await member.refresh(identity:b);XCTAssertEqual(member.teams.count,0);let invite=try XCTUnwrap(member.invites.first)
        try await member.respond(invite,accept:true,identity:b);XCTAssertEqual(member.teams.count,1);XCTAssertTrue(member.invites.isEmpty)
        let creatorRef=db.collection("users").document(a.npub).collection("teams").document(team.teamID)
        try await creatorRef.setData(["legacyMarker":["keep":true]],merge:true)
        var learner=LearnerState();learner.name="Bob";learner.xpByLanguage["es"]=75
        try await member.shareProgress(learner,in:team,identity:b);try await owner.loadProgress(team,identity:a)
        XCTAssertEqual(owner.progress[b.npub]?["name"],.string("Bob"));XCTAssertEqual(owner.progress[b.npub]?["xp"],.number(75));XCTAssertEqual(owner.progressTeamID,team.id)
        try await owner.rename(team,name:"Evening",identity:a);try await member.refresh(identity:b);XCTAssertEqual(member.teams.first?.name,"Evening")
        let renamedInvite=try await db.collection("users").document(b.npub).collection("teamInvites").document(invite.id).getDocument(source:.server);XCTAssertEqual(renamedInvite.data()?["teamName"] as? String,"Evening")
        let d=IdentityService();try d.create();defer { try? d.disconnect() }
        let otherOwner=PrivateTeamsService(database:db)
        async let first:Void=owner.add(to:team,members:c.npub,creatorName:"Ada",identity:a)
        async let second:Void=otherOwner.add(to:team,members:d.npub,creatorName:"Ada",identity:a)
        _=try await(first,second);try await owner.refresh(identity:a);team=try XCTUnwrap(owner.teams.first)
        XCTAssertEqual(Set(team.members.map { $0["npub"].string }),Set([b.npub,c.npub,d.npub]));XCTAssertEqual(team.data["legacyMarker"]["keep"],.bool(true))
        try await member.leave(team,identity:b);XCTAssertTrue(member.teams.isEmpty);try await owner.refresh(identity:a)
        XCTAssertFalse(owner.teams.first!.members.contains { $0["npub"].string == b.npub })
        let progress=try await creatorRef.collection("progress").document(b.npub).getDocument(source:.server);XCTAssertFalse(progress.exists)
        let inviteAfter=try await db.collection("users").document(b.npub).collection("teamInvites").document(invite.id).getDocument(source:.server);XCTAssertFalse(inviteAfter.exists)
        try await owner.leave(try XCTUnwrap(owner.teams.first),identity:a);XCTAssertTrue(owner.teams.isEmpty)
        for identity in [c,d] { let snapshot=try await db.collection("users").document(identity.npub).collection("teamInvites").document("team_"+team.teamID).getDocument(source:.server);XCTAssertFalse(snapshot.exists) }
    }
    func testLegacyInvitesDeclineWithoutChangingOtherMembersAndRejectInvalidOrStaleRoster() async throws {
        let (db,a,b,c)=try context(),owner=PrivateTeamsService(database:db),member=PrivateTeamsService(database:db)
        defer { try? a.disconnect();try? b.disconnect();try? c.disconnect() }
        try await owner.create(name:"Legacy",members:b.npub+","+c.npub,creatorName:"Ada",identity:a);let team=try XCTUnwrap(owner.teams.first)
        let ref=db.collection("users").document(a.npub).collection("teams").document(team.teamID)
        let invitation=db.collection("users").document(b.npub).collection("teamInvites").document("team_"+team.teamID)
        try await invitation.updateData(["member":FieldValue.delete()]) // The browser's older record has no native validation copy.
        try await member.refresh(identity:b);try await member.respond(try XCTUnwrap(member.invites.first),accept:false,identity:b)
        try await owner.refresh(identity:a);XCTAssertEqual(owner.teams.first?.members.map { $0["npub"].string },[c.npub])
        let changed=try await invitation.getDocument(source:.server);XCTAssertEqual(changed.data()?["status"] as? String,"rejected")
        do { try await member.add(to:team,members:a.npub,creatorName:"Bob",identity:b);XCTFail("A member edited the creator roster") } catch { }
        do { try await owner.add(to:team,members:c.npub,creatorName:"Ada",identity:a);XCTFail("A stale snapshot permitted a duplicate member") } catch { }
        try await owner.add(to:team,members:b.npub,creatorName:"Ada",identity:a);try await member.refresh(identity:b)
        let stale=try XCTUnwrap(member.invites.first);try await ref.delete()
        do { try await member.respond(stale,accept:true,identity:b);XCTFail("A missing team was accepted") } catch { }
        let retained=try await invitation.getDocument(source:.server);XCTAssertEqual(retained.data()?["status"] as? String,"pending")
        try await member.respond(stale,accept:false,identity:b);XCTAssertTrue(member.invites.isEmpty)
    }
}

// Simulator UI tests use this same demo project and loopback endpoint when explicitly enabled.
@MainActor enum PrivateTeamTestDatabase {
    static func database() -> Firestore {
        let name="PiyaliPrivateTeamContract"
        if FirebaseApp.app(name:name) == nil {
            let options=FirebaseOptions(googleAppID:"1:123456789012:ios:0123456789abcdef012345",gcmSenderID:"123456789012")
            options.apiKey="emulator-only-not-a-production-key";options.projectID="demo-piyali-ios"
            AppCheck.setAppCheckProviderFactory(PrivateTeamEmulatorFactory());FirebaseApp.configure(name:name,options:options)
            let db=Firestore.firestore(app:FirebaseApp.app(name:name)!);db.useEmulator(withHost:"127.0.0.1",port:8180)
            let settings=db.settings;settings.cacheSettings=MemoryCacheSettings();settings.isSSLEnabled=false;db.settings=settings
        };return Firestore.firestore(app:FirebaseApp.app(name:name)!)
    }
}
private final class PrivateTeamEmulatorProvider:NSObject,AppCheckProvider {
    func getToken(completion:@escaping(AppCheckToken?,Error?)->Void) { completion(AppCheckToken(token:"local-emulator-token",expirationDate:Date().addingTimeInterval(3600)),nil) }
}
private final class PrivateTeamEmulatorFactory:NSObject,AppCheckProviderFactory {
    func createProvider(with app:FirebaseApp)->AppCheckProvider? { PrivateTeamEmulatorProvider() }
}
