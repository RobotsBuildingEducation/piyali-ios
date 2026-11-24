import XCTest
import FirebaseCore
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFirestore
@testable import Piyali

/// Opt-in ephemeral Firebase mirrors; this test never opens a public Nostr connection.
@MainActor final class TeamsMirrorLiveTests:XCTestCase {
    func testDeployedPublicMirrorMembershipRenameAddsAndRevocation()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_LIVE_API_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Explicit isolated live Firebase opt-in required")}
        XCTAssertNil(env["PIYALI_PRIVATE_TEAMS_TEST_EMULATOR"])
        if FirebaseApp.app()==nil{AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory());FirebaseApp.configure()};XCTAssertEqual(FirebaseApp.app()?.options.projectID,"piyali-ios")
        let a=IdentityService(),b=IdentityService(),c=IdentityService();try a.create();try b.create();try c.create();let identities=[a,b,c],mirror=TeamsMirrorService(database:Firestore.firestore()),id="parity-"+UUID().uuidString.lowercased()
        var sessions:[String:FirebaseAuth.User]=[:]
        func activate(_ identity:IdentityService)async throws{if let user=sessions[identity.npub]{try await Auth.auth().updateCurrentUser(user)}else{try await FirebaseIdentityService.shared.ensure(identity);sessions[identity.npub]=try XCTUnwrap(Auth.auth().currentUser)}}
        defer{FirebaseIdentityService.shared.clearSession();for identity in identities{try? identity.disconnect()}}
        do{
            try await activate(a);try await mirror.create(id:id,name:"Parity fixture",members:[b.npub],creatorName:"Ephemeral learner",identity:a)
            try await activate(b);let member=try await mirror.read(identity:b);XCTAssertEqual(member.joined.first?["teamName"],.string("Parity fixture"));XCTAssertEqual(member.invites.first?["status"],.string("accepted"))
            do{_=try await Firestore.firestore().collection("users").document(a.npub).getDocument(source:.server);XCTFail("A roster must not grant access to the learner root")}catch{XCTAssertEqual((error as NSError).code,FirestoreErrorCode.permissionDenied.rawValue)}
            try await activate(c);do{_=try await Firestore.firestore().collection("users").document(a.npub).collection("teams").document(id).getDocument(source:.server);XCTFail("An uninvited learner read the roster")}catch{XCTAssertEqual((error as NSError).code,FirestoreErrorCode.permissionDenied.rawValue)}
            try await activate(a);let renamed=try await mirror.rename(id:id,name:"Renamed parity fixture",identity:a),added=try await mirror.add(id:id,members:[c.npub],creatorName:"Ephemeral learner",identity:a);XCTAssertTrue(renamed);XCTAssertTrue(added)
            try await activate(c);let joined=try await mirror.read(identity:c)
            let joinedTeam=try XCTUnwrap(joined.joined.first);XCTAssertEqual(joinedTeam["teamName"],.string("Renamed parity fixture"));XCTAssertEqual(joinedTeam["members"].array.count,2)
            let query=TeamsMirrorService.memberQuery(Firestore.firestore(),creator:a.npub,id:id,member:c.npub,stamp:joined.invites[0]["createdAt"].string),fresh=try await query.getDocuments(source:.server);XCTAssertEqual(fresh.documents.count,1)
            let watch=expectation(description:"New member roster watch is authorized"),changed=expectation(description:"Creator update reaches member's live subscription");var ready=false,updated=false,watchError:Error?
            let listener=query.addSnapshotListener(includeMetadataChanges:true){snapshot,error in
                if let error{watchError=error;if !ready{ready=true;watch.fulfill()};if !updated{updated=true;changed.fulfill()}}
                else if let snapshot,!snapshot.metadata.isFromCache{
                    let name=snapshot.documents.first?.data()["teamName"] as? String
                    if name=="Renamed parity fixture",!ready{ready=true;watch.fulfill()}
                    if name=="Watched parity fixture",!updated{updated=true;changed.fulfill()}
                }
            };await fulfillment(of:[watch],timeout:5);if let watchError{listener.remove();throw watchError}
            let creatorSession=try XCTUnwrap(sessions[a.npub]),token=try await creatorSession.getIDToken(),base="projects/piyali-ios/databases/(default)/documents/",paths=["users/"+a.npub+"/teams/"+id]+[b,c].map{"users/"+$0.npub+"/teamInvites/team_"+id}
            var rename=URLRequest(url:URL(string:"https://firestore.googleapis.com/v1/"+String(base.dropLast())+":commit")!);rename.httpMethod="POST";rename.setValue("Bearer "+token,forHTTPHeaderField:"Authorization");rename.setValue("application/json",forHTTPHeaderField:"Content-Type");for(key,value)in try await FirebaseService.shared.appCheckHeaders(){rename.setValue(value,forHTTPHeaderField:key)}
            rename.httpBody=try JSONSerialization.data(withJSONObject:["writes":paths.map{["update":["name":base+$0,"fields":["teamName":["stringValue":"Watched parity fixture"]]],"updateMask":["fieldPaths":["teamName"]]]}]);let(_,response)=try await URLSession.shared.data(for:rename);XCTAssertEqual((response as? HTTPURLResponse)?.statusCode,200)
            await fulfillment(of:[changed],timeout:5);listener.remove();if let watchError{throw watchError};XCTAssertEqual(Auth.auth().currentUser?.uid,c.npub)
            try await activate(b);try await mirror.leave(creator:a.npub,id:id,identity:b);let left=try await mirror.read(identity:b);XCTAssertTrue(left.joined.isEmpty);XCTAssertTrue(left.invites.isEmpty)
            try await activate(a);try await mirror.delete(id:id,identity:a);try await activate(c);let revoked=try await mirror.read(identity:c);XCTAssertTrue(revoked.invites.isEmpty);XCTAssertTrue(revoked.joined.isEmpty)
            for identity in identities{try await activate(identity);XCTAssertEqual(Auth.auth().currentUser?.uid,identity.npub);try await Auth.auth().currentUser?.delete();FirebaseIdentityService.shared.clearSession()};print("LIVE TEAMS MIRRORS: accepted invitation, name propagation, add, leave, outsider/learner-root denial and deletion/revocation passed; test rosters, invitations and Auth identities removed; no Nostr publication")
        }catch{
            try? await activate(a);try? await mirror.delete(id:id,identity:a);for identity in identities{try? await activate(identity);if Auth.auth().currentUser?.uid==identity.npub{try? await Auth.auth().currentUser?.delete()};FirebaseIdentityService.shared.clearSession()};throw error
        }
    }
}
