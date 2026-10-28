import XCTest
@testable import Piyali

@MainActor private final class RecoveryProgress:LearnerProgressService {
    var importFails=true,imports=0,saves=0,holdImport=false,holdSave=false
    var resumeImport:CheckedContinuation<Void,Never>?,resumeSave:CheckedContinuation<Void,Never>?
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{local}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{true}
    func importAchievements(_ records:JSONValue,npub:String)async throws->[String:JSONValue]?{imports += 1;if holdImport{await withCheckedContinuation{resumeImport=$0}};if importFails{throw URLError(.notConnectedToInternet)};return records.object}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{saves += 1;if holdSave{await withCheckedContinuation{resumeSave=$0}};var result=state;result.pendingChanges=[];return result}
}
@MainActor final class AchievementRecoveryTests:XCTestCase {
    private func until(_ predicate:()->Bool)async throws{for _ in 0..<400{if predicate(){return};try await Task.sleep(for:.milliseconds(10))};XCTFail("Achievement recovery did not settle")}
    private func model(_ progress:RecoveryProgress,relay:LocalNostrRelay,timeout:Int=12000,fast:Bool=true,journal:MemoryAchievementJournal?=nil)throws->AppModel{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated local services required")}
        let worker=AchievementRetryController(journal:journal ?? MemoryAchievementJournal(),timeoutMilliseconds:timeout,sleep:{try await Task.sleep(for:.milliseconds($0==0 ? 1:fast ? 20:$0))}),service=NostrAchievementsService(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(1))),app=AppModel(progressService:progress,nostrAchievements:service,achievementRetries:worker);try app.identity.create();app.signedIn=true;app.learner=LearnerState();return app
    }
    private func records()->JSONValue{.object(["nosabos_flashcards_5":.object(["unlockedAt":.number(123),"source":.string("nosabos"),"catalogVersion":.number(8)])])}
    func testAuthorizedRelayPublicationAndLocalRestorationSurviveCloudImportFailure()async throws{
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{frame,c in if frame.first as?String=="REQ",let sub=frame[1]as?String{relay.send(["EOSE",sub],to:c)}else if frame.first as?String=="EVENT",let event=frame[1]as?[String:Any]{relay.send(["OK",event["id"]!,true,""],to:c)}}
        let progress=RecoveryProgress(),app=try model(progress,relay:relay);defer{app.setAchievementApplicationActive(false);try? app.identity.disconnect()};app.learner.achievementRecords=records().object;app.learner.shareNostrAchievements=true
        try await app.syncNostrAchievements(publish:true);try await until{progress.imports>0};XCTAssertTrue(app.achievementRetries.pending(.cloud));XCTAssertFalse(app.achievementRetries.pending(.relay));XCTAssertEqual(relay.frames().filter{$0.first as?String=="EVENT"}.count,1);XCTAssertEqual(app.learner.totalXP,0);XCTAssertTrue(app.achievementUnlock.queue.isEmpty)
        app.learner=LearnerState();app.loadLocal();XCTAssertEqual(app.learner.nostrAchievementRecords,records());progress.importFails=false;try await until{!app.achievementRetries.pending};XCTAssertGreaterThanOrEqual(progress.imports,2);XCTAssertEqual(app.learner.totalXP,0);XCTAssertTrue(app.achievementUnlock.queue.isEmpty)
    }
    func testIntentJournalFailureDoesNotMisreportRecordStorageLoss()async throws{
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{_,_ in};let journal=MemoryAchievementJournal();journal.writeFails=true;let progress=RecoveryProgress(),app=try model(progress,relay:relay,journal:journal);defer{app.setAchievementApplicationActive(false);try? app.identity.disconnect()};app.learner.nostrAchievementRecords=records();app.persist();await app.sync();XCTAssertTrue(app.achievementRetries.storageError);XCTAssertTrue(app.achievementSyncPending);XCTAssertFalse(app.localStorageUnavailable);progress.importFails=false;await app.sync();XCTAssertFalse(app.localStorageUnavailable)
    }
    func testFailedLocalProfileStillKeepsAuthorizedRemoteCopyAndWarningUntilFileRetry()async throws{
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{frame,c in if frame.first as?String=="REQ",let sub=frame[1]as?String{relay.send(["EOSE",sub],to:c)}else if frame.first as?String=="EVENT",let event=frame[1]as?[String:Any]{relay.send(["OK",event["id"]!,true,""],to:c)}}
        let progress=RecoveryProgress(),app=try model(progress,relay:relay);defer{app.setAchievementApplicationActive(false);try? app.identity.disconnect()};let path=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Piyali").appendingPathComponent(app.identity.npub+".json");try FileManager.default.createDirectory(at:path,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:path)};app.learner.achievementRecords=records().object;app.learner.shareNostrAchievements=true
        try await app.syncNostrAchievements(publish:true);XCTAssertEqual(relay.frames().filter{$0.first as?String=="EVENT"}.count,1);XCTAssertTrue(app.localStorageUnavailable);XCTAssertEqual(app.learner.nostrAchievementRecords,records());try FileManager.default.removeItem(at:path);progress.importFails=false;await app.sync();XCTAssertFalse(app.localStorageUnavailable);let saved=try JSONDecoder().decode(LearnerState.self,from:Data(contentsOf:path));XCTAssertEqual(saved.nostrAchievementRecords,records());XCTAssertEqual(saved.totalXP,0)
    }
    func testLostRelayAcknowledgmentRequeriesAcceptedRecordWithoutRepublishing()async throws{
        let relay=LocalNostrRelay();defer{relay.stop()};var stored:NostrEventPayload?
        try await relay.start{frame,c in
            if frame.first as?String=="REQ",let sub=frame[1]as?String{if let stored{relay.send(["EVENT",sub,wireEvent(stored)],to:c)};relay.send(["EOSE",sub],to:c)}
            else if frame.first as?String=="EVENT",frame.count>1,let bytes=try? JSONSerialization.data(withJSONObject:frame[1]){stored=try? JSONDecoder().decode(NostrEventPayload.self,from:bytes)}
        }
        let progress=RecoveryProgress();progress.importFails=false;let app=try model(progress,relay:relay);defer{app.setAchievementApplicationActive(false);try? app.identity.disconnect()};app.learner.achievementRecords=records().object;app.learner.shareNostrAchievements=true;app.resumeAchievementSync();try await until{relay.frames().filter{$0.first as?String=="REQ"}.count>=2 && !app.achievementRetries.pending};XCTAssertEqual(relay.frames().filter{$0.first as?String=="EVENT"}.count,1);XCTAssertEqual(app.learner.totalXP,0);XCTAssertTrue(app.achievementUnlock.queue.isEmpty)
    }
    func testSharingDisabledRetryRestoresWithoutPublishing()async throws{
        let relay=LocalNostrRelay();defer{relay.stop()};var attempts=0;try await relay.start{frame,c in if frame.first as?String=="REQ",let sub=frame[1]as?String{attempts += 1;if attempts==1{relay.send(["CLOSED",sub,"temporary offline fixture"],to:c)}else{relay.send(["EOSE",sub],to:c)}}}
        let progress=RecoveryProgress(),app=try model(progress,relay:relay);defer{app.setAchievementApplicationActive(false);try? app.identity.disconnect()};app.learner.achievementRecords=records().object;app.learner.shareNostrAchievements=false;progress.importFails=false;app.resumeAchievementSync();try await until{attempts>=2 && !app.achievementRetries.pending};XCTAssertTrue(relay.frames().filter{$0.first as?String=="EVENT"}.isEmpty);XCTAssertEqual(app.learner.totalXP,0)
    }
    func testLateOldAccountImportCannotOverwriteReplacementAccount()async throws{
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{_,_ in};let progress=RecoveryProgress();progress.importFails=false;progress.holdImport=true;let app=try model(progress,relay:relay);defer{app.setAchievementApplicationActive(false);try? app.identity.disconnect()};app.learner.nostrAchievementRecords=records();let old=app.identity.npub,task=Task{await app.sync()};try await until{progress.resumeImport != nil};app.signedIn=false;try app.identity.create();app.signedIn=true;app.learner=LearnerState();app.learner.xpByLanguage=[app.learner.target:77];app.syncStatus="New account";progress.resumeImport?.resume();await task.value;XCTAssertNotEqual(old,app.identity.npub);XCTAssertEqual(app.learner.totalXP,77);XCTAssertNil(app.learner.achievementRecords);XCTAssertFalse(app.achievementRetries.pending);XCTAssertEqual(app.syncStatus,"New account")
    }
    func testSignedOutImportCannotRepopulateCollectionOrChangeStatus()async throws{
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{_,_ in};let progress=RecoveryProgress();progress.importFails=false;progress.holdImport=true;let app=try model(progress,relay:relay);defer{app.setAchievementApplicationActive(false);try? app.identity.disconnect()};app.learner.nostrAchievementRecords=records();let task=Task{await app.sync()};try await until{progress.resumeImport != nil};app.signedIn=false;app.learner=LearnerState();app.syncStatus="Signed out";progress.resumeImport?.resume();await task.value;XCTAssertNil(app.learner.achievementRecords);XCTAssertFalse(app.achievementRetries.pending);XCTAssertEqual(app.syncStatus,"Signed out")
    }
    func testDeadlineCannotApplyLateCloudSnapshotOverNewerLocalWork()async throws{
        let relay=LocalNostrRelay();defer{relay.stop()};try await relay.start{_,_ in};let progress=RecoveryProgress();progress.holdSave=true;let app=try model(progress,relay:relay,timeout:40,fast:false);defer{app.setAchievementApplicationActive(false);try? app.identity.disconnect()};app.learner.award(5);await app.sync();XCTAssertTrue(app.achievementRetries.pending(.cloud));app.learner.award(2);let ids=app.learner.pendingChanges?.map(\.id);progress.resumeSave?.resume();try await Task.sleep(for:.milliseconds(40));XCTAssertEqual(app.learner.totalXP,7);XCTAssertEqual(app.learner.pendingChanges?.map(\.id),ids);XCTAssertEqual(app.syncStatus,"Saved on iPhone; cloud sync pending")
    }
}
