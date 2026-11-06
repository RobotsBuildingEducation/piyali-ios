import XCTest
@testable import Piyali

@MainActor private final class FirstRunStore:LearnerProgressService {
    var acknowledgments:[(FirstRunAcknowledgment,String)]=[],fullSaves=0,failure=false,held=false
    var resume:CheckedContinuation<Void,Never>?
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{fullSaves+=1;return nil}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{false}
    func saveFirstRunAcknowledgment(_ acknowledgment:FirstRunAcknowledgment,npub:String)async throws{acknowledgments.append((acknowledgment,npub));if held{await withCheckedContinuation{resume=$0}};if failure{throw URLError(.notConnectedToInternet)}}
}
@MainActor final class FirstRunAcknowledgmentTests:XCTestCase {
    private func model(_ store:FirstRunStore)throws->AppModel{let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")};let app=AppModel(progressService:store);try app.identity.create();app.signedIn=true;app.learner=LearnerState();app.learner.onboardingComplete=true;return app}
    private func until(_ predicate:()->Bool)async throws{for _ in 0..<250{if predicate(){return};try await Task.sleep(for:.milliseconds(10))};XCTFail("Acknowledgment did not settle")}
    func testEachAcknowledgmentUsesNarrowWriteAndRestoresFlagsWithoutXPOrPreparingPlate()async throws{
        let store=FirstRunStore(),app=try model(store);defer{try? app.identity.disconnect()};let before=app.learner
        app.acknowledgeFirstRun(.paperPencil);app.acknowledgeFirstRun(.gettingStarted);try await until{store.acknowledgments.count==2};try await Task.sleep(for:.milliseconds(650));XCTAssertEqual(store.fullSaves,0);XCTAssertEqual(Set(store.acknowledgments.map{$0.0.rawValue}),["paperPencilModalShown","gettingStartedModalShown"]);XCTAssertTrue(store.acknowledgments.allSatisfy{$0.1==app.identity.npub});XCTAssertEqual(app.learner.totalXP,before.totalXP);XCTAssertEqual(app.learner.questPlans,before.questPlans);XCTAssertEqual(app.learner.pendingChanges?.map(\.id),before.pendingChanges?.map(\.id))
        app.learner=LearnerState();app.loadLocal();XCTAssertTrue(app.learner.paperPencilModalShown == true);XCTAssertTrue(app.learner.gettingStartedModalShown == true)
    }
    func testFailedWriteRemainsLocallyAcknowledgedForRelaunchAndGenericRetry()async throws{
        let store=FirstRunStore();store.failure=true;let app=try model(store);defer{try? app.identity.disconnect()};app.acknowledgeFirstRun(.paperPencil);try await until{app.syncStatus.contains("pending")};XCTAssertEqual(store.fullSaves,0);app.learner=LearnerState();app.loadLocal();XCTAssertTrue(app.learner.paperPencilModalShown == true);XCTAssertEqual(app.learner.totalXP,0);XCTAssertNil(app.error)
    }
    func testLateOldAccountFailureCannotChangeNewAccountOrSyncMessage()async throws{
        let store=FirstRunStore();store.held=true;store.failure=true;let app=try model(store);defer{try? app.identity.disconnect()};let old=app.identity.npub;app.acknowledgeFirstRun(.paperPencil);try await until{store.resume != nil};app.signedIn=false;try app.identity.create();app.signedIn=true;app.learner=LearnerState();app.syncStatus="New account";store.resume?.resume();store.resume=nil;try await Task.sleep(for:.milliseconds(100));XCTAssertEqual(store.acknowledgments.first?.1,old);XCTAssertNil(app.learner.paperPencilModalShown);XCTAssertEqual(app.syncStatus,"New account")
    }
}
