import XCTest
@testable import Piyali

@MainActor private final class TeamControllerAccess:TeamsPanelAccess {
    var next=TeamsPanelSnapshot(),published:[JSONValue]=[]
    var delay:CheckedContinuation<Void,Never>?
    var pause=false
    func load(_ app:AppModel)async throws->TeamsPanelSnapshot{let value=next;if pause{await withCheckedContinuation{delay=$0}};return value}
    func create(name:String,members:[String],app:AppModel)async throws{}
    func rename(_ team:JSONValue,name:String,app:AppModel)async throws->Bool{false}
    func add(_ team:JSONValue,members:[String],app:AppModel)async throws->Bool{false}
    func remove(_ team:JSONValue,app:AppModel)async throws{}
    func respond(_ invite:JSONValue,accept:Bool,app:AppModel)async throws{}
    func publish(_ app:AppModel)async throws{published.append(LearningTeams.snapshot(app.learner))}
    func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]{[]}
    func cancel(){}
}
@MainActor final class TeamsPanelControllerTests:XCTestCase {
    private func context()throws->(AppModel,TeamControllerAccess,TeamsPanelController){let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")};let app=AppModel();try app.identity.create();let access=TeamControllerAccess(),model=TeamsPanelController(access:access);return(app,access,model)}
    func testOriginalDebouncePublishesLatestSnapshotUpdatesOwnRowAndCancelsOnClose()async throws{
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};let team:JSONValue = .object(["id":.string("public"),"createdBy":.string(app.identity.npub),"nostr":.object([:])]);access.next = .init(teams:[team],rows:[LiveTeamsPanelAccess.key(team):[LearningTeams.progressRow(member:app.identity.npub,data:LearningTeams.snapshot(app.learner),creator:true)]])
        await model.reload(app);try await Task.sleep(for:.milliseconds(100));app.learner.name="Latest learner";model.scheduleSharing(app);try await Task.sleep(for:.milliseconds(400));XCTAssertTrue(access.published.isEmpty);try await Task.sleep(for:.milliseconds(450));XCTAssertEqual(access.published.count,1);XCTAssertEqual(access.published.first?["name"],.string("Latest learner"));XCTAssertEqual(model.snapshot.rows[LiveTeamsPanelAccess.key(team)]?.first?["name"],.string("Latest learner"));model.scheduleSharing(app);try await Task.sleep(for:.milliseconds(750));XCTAssertEqual(access.published.count,1)
        app.learner.name="Closed";model.scheduleSharing(app);model.cancel();try await Task.sleep(for:.milliseconds(750));XCTAssertEqual(access.published.count,1)
    }
    func testLegacyOnlyTeamsDoNotPublishAndLateLoadCannotRestoreClosedAccountData()async throws{
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};access.next = .init(teams:[.object(["id":.string("legacy"),"createdBy":.string(app.identity.npub)])]);await model.reload(app);try await Task.sleep(for:.milliseconds(750));XCTAssertTrue(access.published.isEmpty)
        access.pause=true;access.next.teams=[.object(["id":.string("stale")])];let loading=Task{await model.reload(app)};while access.delay==nil{await Task.yield()};model.cancel();access.delay?.resume();await loading.value;XCTAssertEqual(model.snapshot.teams.first?["id"],.string("legacy"))
    }
}
