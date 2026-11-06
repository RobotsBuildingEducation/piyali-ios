import XCTest
import SwiftUI
@testable import Piyali

@MainActor private class TeamControllerAccess:TeamsPanelAccess {
    var next=TeamsPanelSnapshot(),published:[JSONValue]=[]
    var watchCallbacks:[@MainActor()->Void]=[],inviteCallbacks:[@MainActor([JSONValue])->Void]=[],loads=0
    var delay:CheckedContinuation<Void,Never>?
    var pause=false,loadFails=false
    func load(_ app:AppModel)async throws->TeamsPanelSnapshot{loads += 1;if loadFails{throw URLError(.notConnectedToInternet)};let value=next;if pause{await withCheckedContinuation{delay=$0}};return value}
    func create(name:String,members:[String],app:AppModel)async throws{}
    func rename(_ team:JSONValue,name:String,app:AppModel)async throws->Bool{false}
    func add(_ team:JSONValue,members:[String],app:AppModel)async throws->Bool{false}
    func remove(_ team:JSONValue,app:AppModel)async throws{}
    func respond(_ invite:JSONValue,accept:Bool,app:AppModel)async throws{}
    func publish(_ app:AppModel)async throws{published.append(LearningTeams.snapshot(app.learner))}
    func feed(_ app:AppModel,force:Bool)async throws->[CommunityPost]{[]}
    func watch(_ teams:[JSONValue],app:AppModel,onChange:@escaping @MainActor()->Void)async{watchCallbacks.append(onChange)}
    func watchInvites(_ app:AppModel,onChange:@escaping @MainActor([JSONValue])->Void)async{inviteCallbacks.append(onChange)}
    func watchRoster(_ snapshot:TeamsPanelSnapshot,app:AppModel,onRecord:@escaping @MainActor(JSONValue)->Void,onInvalidate:@escaping @MainActor()->Void)async{await watchSnapshot(snapshot,app:app,onChange:onInvalidate)}
    func memberRows(_ team:JSONValue,app:AppModel)async throws->[JSONValue]{[]}
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


extension TeamsPanelControllerTests {
    private func settle(_ predicate:()->Bool)async throws {for _ in 0..<200 where !predicate(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(predicate())}
    func testWatchedChangeWhileReadIsHeldRefreshesAfterTheStaleReadFinishes()async throws {
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};access.next = .init(teams:[.object(["id":.string("old")])]);await model.reload(app);let update=try XCTUnwrap(access.watchCallbacks.first)
        access.pause=true;let loading=Task{await model.reload(app)};try await settle{access.delay != nil};access.next = .init(teams:[.object(["id":.string("latest")])]);for _ in 0..<5{update()};try await Task.sleep(for:.milliseconds(30));access.pause=false;access.delay?.resume();access.delay=nil;await loading.value
        try await Task.sleep(for:.milliseconds(150));XCTAssertEqual(model.snapshot.teams.first?["id"].string,"latest");XCTAssertEqual(access.loads,3)
    }
    func testWatchedChangeDuringFailedManagementStillArrivesWithoutHidingItsError()async throws {
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};access.next = .init(teams:[.object(["id":.string("old")])]);await model.reload(app);let update=try XCTUnwrap(access.watchCallbacks.first);var held:CheckedContinuation<Void,Never>?
        model.perform(app,action:{_ in await withCheckedContinuation{held=$0};throw URLError(.cannotConnectToHost)});try await settle{held != nil};access.next = .init(teams:[.object(["id":.string("live-update")])]);update();held?.resume();held=nil;try await settle{!model.working};try await Task.sleep(for:.milliseconds(150))
        XCTAssertEqual(model.snapshot.teams.first?["id"].string,"live-update");XCTAssertNotNil(model.error)
    }
    func testAlreadyQueuedWatchCallbackCannotReloadOrPublishAfterDrawerCloses()async throws {
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};access.next = .init(teams:[.object(["id":.string("public"),"createdBy":.string(app.identity.npub),"nostr":.object([:])])]);await model.reload(app);let update=try XCTUnwrap(access.watchCallbacks.first);model.cancel();let before=access.loads;update();try await Task.sleep(for:.milliseconds(950))
        XCTAssertEqual(access.loads,before);XCTAssertTrue(access.published.isEmpty,"A closed drawer's queued callback must not reopen its 700 ms progress publisher")
    }
}


extension TeamsPanelControllerTests {
    private func pending(_ id:String)->JSONValue{.object(["id":.string(id),"status":.string("pending"),"teamName":.string("Public fixture invitation")])}
    func testLiveInvitationsStayCurrentThroughAHeldReadAndFailedActionWithoutAFullReload()async throws {
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};access.pause=true;access.next = .init(teams:[.object(["id":.string("legacy")])],invites:[pending("old")]);let loading=Task{await model.reload(app)};try await settle{access.delay != nil && access.inviteCallbacks.count==1};let receive=access.inviteCallbacks[0]
        receive([pending("live")]);XCTAssertEqual(model.snapshot.invites.first?["id"].string,"live");access.pause=false;access.delay?.resume();access.delay=nil;await loading.value;XCTAssertEqual(model.snapshot.invites.first?["id"].string,"live")
        var held:CheckedContinuation<Void,Never>?;model.perform(app,action:{_ in await withCheckedContinuation{held=$0};throw URLError(.cannotConnectToHost)});try await settle{held != nil};let before=access.loads;receive([pending("live"),pending("new")]);XCTAssertEqual(model.snapshot.invites.count,2);XCTAssertEqual(access.loads,before);held?.resume();held=nil;try await settle{!model.working};XCTAssertEqual(model.snapshot.invites.count,2);XCTAssertNotNil(model.error)
        model.cancel();receive([pending("closed")]);XCTAssertEqual(model.snapshot.invites.count,2)
    }
    func testSameTeamNewAcceptedGrantTimestampReplacesTheRosterWatch()async throws {
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};let team:JSONValue = .object(["id":.string("same-team"),"createdBy":.string("public-creator"),"nostr":.object([:])]),grant:JSONValue = .object(["id":.string("team_same-team"),"teamId":.string("same-team"),"creatorNpub":.string("public-creator"),"status":.string("accepted"),"createdAt":.string("old-grant"),"nostr":.object([:])])
        access.next = .init(teams:[team],invites:[grant]);await model.reload(app);try await settle{access.inviteCallbacks.count==1};XCTAssertEqual(access.watchCallbacks.count,1);let changed=grant.setting("createdAt",.string("replacement-grant"));access.next = .init(teams:[team],invites:[changed]);access.inviteCallbacks[0]([changed]);try await settle{access.watchCallbacks.count==2};XCTAssertEqual(model.snapshot.invites.first?["createdAt"].string,"replacement-grant")
    }
    func testReimportingSameAccountKeyFencesOldReadWatchAndPublisherSession()async throws {
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};access.next = .init(teams:[.object(["id":.string("public"),"createdBy":.string(app.identity.npub),"nostr":.object([:])])]);await model.reload(app);let update=try XCTUnwrap(access.watchCallbacks.first),key=app.identity.exportKey();access.pause=true;access.next = .init(teams:[.object(["id":.string("stale-session")])]);let read=Task{await model.reload(app)};try await settle{access.delay != nil};try app.identity.importKey(key);access.pause=false;access.delay?.resume();access.delay=nil;await read.value;let before=access.loads;update();try await Task.sleep(for:.milliseconds(850));XCTAssertEqual(access.loads,before);XCTAssertEqual(model.snapshot.teams.first?["id"].string,"public");XCTAssertTrue(access.published.isEmpty)
    }
}


extension TeamsPanelControllerTests {
    func testSuccessfulWatchedRefreshClearsAReadFailureWhileActionErrorsRemainIndependent()async throws {
        let(app,access,model)=try context();defer{model.cancel();try? app.identity.disconnect()};access.next = .init(teams:[.object(["id":.string("cached")])]);await model.reload(app);let update=try XCTUnwrap(access.watchCallbacks.first)
        access.loadFails=true;await model.reload(app);XCTAssertNotNil(model.error);access.loadFails=false;access.next = .init(teams:[.object(["id":.string("recovered")])]);update();try await settle{model.snapshot.teams.first?["id"].string == "recovered"};XCTAssertNil(model.error)
    }
}

extension TeamsPanelControllerTests {
    func testManagementFailureEmitsToastKeepsEditorAndSurvivesDrawerCloseButNotSignOut()async throws {
        let(app,_,model)=try context();app.signedIn=true;defer{model.cancel();app.signOut()}
        await model.reload(app);var closed=false
        model.perform(app,action:{_ in throw AppError.message("Public rename rejection")},onSuccess:{closed=true})
        try await settle{!model.working};XCTAssertFalse(closed);XCTAssertEqual(model.error,"Public rename rejection")
        let notice=try XCTUnwrap(app.teamsNotices.notices.last);XCTAssertEqual(notice.title,"Error");XCTAssertEqual(notice.description,"Public rename rejection");XCTAssertEqual(notice.status,"error");XCTAssertEqual(notice.duration,5);XCTAssertFalse(notice.closable)
        model.cancel();XCTAssertEqual(app.teamsNotices.notices.last?.id,notice.id)
        app.signOut();XCTAssertTrue(app.teamsNotices.notices.isEmpty)
    }
    func testNoticeTimersKeepIdenticalMessagesIndependentAndFenceCancelledAccount()async throws {
        var waits:[CheckedContinuation<Void,Error>]=[],durations:[Double]=[]
        let center=TeamsNoticeCenter(wait:{duration in durations.append(duration);try await withCheckedThrowingContinuation{waits.append($0)}})
        let first=TeamsNotice(title:"Your ID was copied",duration:2,closable:true),second=TeamsNotice(title:"Your ID was copied",duration:2,closable:true)
        center.show(first,scope:"first");center.show(second,scope:"first");try await settle{waits.count==2};XCTAssertEqual(durations,[2,2]);XCTAssertEqual(center.notices.map(\.id),[first.id,second.id])
        waits[0].resume();try await settle{center.notices.count==1};XCTAssertEqual(center.notices.first?.id,second.id)
        center.bind("second");let replacement=TeamsNotice(title:"Team renamed");center.show(replacement,scope:"second");try await settle{waits.count==3};waits[1].resume();try await Task.sleep(for:.milliseconds(20));XCTAssertEqual(center.notices.map(\.id),[replacement.id]);XCTAssertEqual(durations,[2,2,5])
        center.dismiss(replacement.id);waits[2].resume();try await Task.sleep(for:.milliseconds(20));XCTAssertTrue(center.notices.isEmpty)
    }
}


extension TeamsPanelControllerTests {
    func testNoticePortalClosesItsOwnItemReleasesEmptyWindowAndKeepsCurrentKeyWindow()async throws {
        let(app,_,model)=try context();defer{model.cancel();app.signOut()}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),key=scene.windows.first{$0.isKeyWindow}
        let center=TeamsNoticeCenter(),coordinator=TeamsNoticePresenter.Coordinator();coordinator.scene=scene;coordinator.center=center
        let notice=TeamsNotice(title:"Your ID was copied",duration:2,closable:true);center.show(notice,scope:"public-fixture");coordinator.render()
        let portal=try XCTUnwrap(coordinator.portal);XCTAssertFalse(portal.canBecomeKey);XCTAssertFalse(portal.isHidden);XCTAssertTrue(scene.windows.first{$0.isKeyWindow} === key)
        let confirmation=UUID();center.cover(true,by:confirmation);coordinator.render();XCTAssertNil(coordinator.portal);XCTAssertTrue(portal.isHidden);XCTAssertEqual(center.notices.map(\.id),[notice.id])
        center.cover(false,by:confirmation);coordinator.render()
        let host=try XCTUnwrap(coordinator.portal?.rootViewController as? UIHostingController<TeamsNoticeStack>);host.rootView.dismiss(notice.id);XCTAssertTrue(center.notices.isEmpty)
        coordinator.render();XCTAssertNil(coordinator.portal);XCTAssertTrue(portal.isHidden);XCTAssertNil(portal.rootViewController);XCTAssertTrue(scene.windows.first{$0.isKeyWindow} === key)
    }
}


@MainActor private final class TeamStreamAccess:TeamControllerAccess {
    var rosterCallbacks:[@MainActor(JSONValue)->Void]=[]
    var heldRows:[CheckedContinuation<[JSONValue],Error>]=[]
    var rowLoads=0
    override func watchRoster(_ snapshot:TeamsPanelSnapshot,app:AppModel,onRecord:@escaping @MainActor(JSONValue)->Void,onInvalidate:@escaping @MainActor()->Void)async{rosterCallbacks.append(onRecord)}
    override func memberRows(_ team:JSONValue,app:AppModel)async throws->[JSONValue]{rowLoads += 1;return try await withCheckedThrowingContinuation{heldRows.append($0)}}
    func finish(_ result:Result<[JSONValue],Error>){guard !heldRows.isEmpty else{return};heldRows.removeFirst().resume(with:result)}
    func finishAll(){for row in heldRows{row.resume(throwing:CancellationError())};heldRows=[];delay?.resume();delay=nil}
}
extension TeamsPanelControllerTests {
    private func streamContext(publicTeam:Bool=false)throws->(AppModel,TeamStreamAccess,TeamsPanelController,JSONValue,String){
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")}
        let app=AppModel();try app.identity.create();let access=TeamStreamAccess()
        var team:JSONValue = .object(["id":.string("stream-team"),"createdBy":.string(app.identity.npub),"teamName":.string("Original"),"isCreator":.bool(true),"members":.array([])])
        if publicTeam{team=team.setting("nostr",.object(["id":.string("stream-team")]))}
        let key=LiveTeamsPanelAccess.key(team);access.next = .init(teams:[team],rows:[key:[.object(["name":.string("Previous rows")])]])
        return(app,access,TeamsPanelController(access:access),team,key)
    }
    func testCachedRosterStreamChangesTheCardImmediatelyWhileRowsAreHeldWithoutAFullReload()async throws {
        let(app,access,model,team,key)=try streamContext();defer{model.cancel();access.finishAll();app.signOut()};await model.reload(app);let emit=try XCTUnwrap(access.rosterCallbacks.first);model.error="Unrelated management error"
        emit(team.setting("teamName",.string("Cached peer name")).setting("isCreator",.bool(false)))
        XCTAssertEqual(model.snapshot.teams.first?["teamName"].string,"Cached peer name");XCTAssertEqual(model.snapshot.teams.first?["isCreator"],.bool(true),"Display snapshots cannot replace derived ownership")
        XCTAssertEqual(model.snapshot.rows[key]?.first?["name"].string,"Previous rows");XCTAssertFalse(model.loading);try await settle{access.heldRows.count==1};XCTAssertEqual(access.loads,1)
        access.finish(.success([.object(["name":.string("Fresh rows")])]));try await settle{model.snapshot.rows[key]?.first?["name"].string == "Fresh rows"};XCTAssertEqual(model.error,"Unrelated management error");XCTAssertTrue(model.rowErrors.isEmpty)
        emit(team.setting("id",.string("unknown")));emit(team.setting("createdBy",.string("wrong-owner")));emit(team.setting("nostr",.object([:])))
        XCTAssertEqual(model.snapshot.teams.count,1);XCTAssertEqual(model.snapshot.teams.first?["teamName"].string,"Cached peer name");XCTAssertEqual(access.rowLoads,1)
    }
    func testStreamBurstCoalescesLatestRowsAndAHeldFullReadCannotOverwriteNewerPresentation()async throws {
        let(app,access,model,team,key)=try streamContext();defer{model.cancel();access.finishAll();app.signOut()};await model.reload(app);let emit=try XCTUnwrap(access.rosterCallbacks.first)
        access.pause=true;let read=Task{await model.reload(app,preservingError:true)};try await settle{access.delay != nil}
        emit(team.setting("teamName",.string("First peer update")));try await settle{access.heldRows.count==1}
        for _ in 0..<5{emit(team.setting("teamName",.string("Latest peer update")))}
        access.finish(.success([.object(["name":.string("Stale rows")])]));try await settle{access.rowLoads==2 && access.heldRows.count==1};XCTAssertEqual(model.snapshot.rows[key]?.first?["name"].string,"Previous rows")
        access.finish(.success([.object(["name":.string("Latest rows")])]));try await settle{model.snapshot.rows[key]?.first?["name"].string == "Latest rows"}
        access.pause=false;access.delay?.resume();access.delay=nil;await read.value
        XCTAssertEqual(model.snapshot.teams.first?["teamName"].string,"Latest peer update");XCTAssertEqual(model.snapshot.rows[key]?.first?["name"].string,"Latest rows");XCTAssertEqual(access.loads,2);XCTAssertEqual(access.rowLoads,2)
    }
    func testFailedStreamMemberReadKeepsPreviousRowsAndManagementErrorUntilANewSnapshotRecovers()async throws {
        let(app,access,model,team,key)=try streamContext();defer{model.cancel();access.finishAll();app.signOut()};await model.reload(app);model.error="Action diagnostic";let emit=try XCTUnwrap(access.rosterCallbacks.first)
        emit(team.setting("teamName",.string("Peer changed")));try await settle{access.heldRows.count==1};access.finish(.failure(URLError(.notConnectedToInternet)));try await settle{model.rowErrors[key] != nil}
        XCTAssertEqual(model.snapshot.teams.first?["teamName"].string,"Peer changed");XCTAssertEqual(model.snapshot.rows[key]?.first?["name"].string,"Previous rows");XCTAssertEqual(model.error,"Action diagnostic");XCTAssertTrue(app.teamsNotices.notices.isEmpty)
        emit(team.setting("teamName",.string("Recovered peer")));try await settle{access.heldRows.count==1};access.finish(.success([.object(["name":.string("Recovered rows")])]));try await settle{model.rowErrors[key] == nil};XCTAssertEqual(model.snapshot.rows[key]?.first?["name"].string,"Recovered rows");XCTAssertEqual(model.error,"Action diagnostic")
    }
    func testOldGrantAndClosedStreamCallbacksCannotApplyOrFinishMemberRows()async throws {
        let(app,access,model,team,key)=try streamContext(publicTeam:true);defer{model.cancel();access.finishAll();app.signOut()}
        let grant:JSONValue = .object(["id":.string("team_stream-team"),"teamId":.string("stream-team"),"creatorNpub":team["createdBy"],"status":.string("accepted"),"createdAt":.string("old"),"nostr":.object([:])]);access.next.invites=[grant];await model.reload(app);let old=try XCTUnwrap(access.rosterCallbacks.first)
        old(team.setting("teamName",.string("Old grant peer")));try await settle{access.heldRows.count==1}
        let replacement=grant.setting("createdAt",.string("new"));access.next.invites=[replacement];access.next.teams=[team.setting("teamName",.string("Replacement grant"))];model.applyInvites([replacement],app:app);try await settle{access.rosterCallbacks.count==2};let current=access.rosterCallbacks[1]
        old(team.setting("teamName",.string("Queued old grant")));access.finish(.success([.object(["name":.string("Old grant rows")])]))
        try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(model.snapshot.teams.first?["teamName"].string,"Replacement grant");XCTAssertEqual(model.snapshot.rows[key]?.first?["name"].string,"Previous rows")
        current(team.setting("teamName",.string("Current peer")));try await settle{access.heldRows.count==1};model.cancel();current(team.setting("teamName",.string("Closed peer")));access.finish(.success([.object(["name":.string("Closed rows")])]))
        try await Task.sleep(for:.milliseconds(30));XCTAssertEqual(model.snapshot.teams.first?["teamName"].string,"Current peer");XCTAssertEqual(model.snapshot.rows[key]?.first?["name"].string,"Previous rows");XCTAssertTrue(access.published.isEmpty)
    }
}
