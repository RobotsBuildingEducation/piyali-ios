import XCTest
@testable import Piyali
@MainActor final class CompanionUnlockFlowTests:XCTestCase {
 private func model(progressService:(any LearnerProgressService)?=nil)throws->AppModel{
  let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")}
  let app=AppModel(progressService:progressService);try app.identity.create();app.signedIn=true;app.learner = LearnerState();app.learner.xpByLanguage=[app.learner.target:99];app.learner.companionName="Cielo";app.learner.onboardingComplete=true;return app
 }
 func testEarnedCrossingWaitsForModalMarksAtPresentationAndKeepRestoresQuietly()throws{
  let app=try model();defer{try? app.identity.disconnect()};app.learner.companionProgress = .object(["dailyGoalPetHealth":.number(37)]);app.learner.award(1);let xp=app.learner.totalXP,health=app.learner.companionHealth;XCTAssertEqual(health,37)
  XCTAssertEqual(app.pendingCompanionUnlocks.map(\.type),["alien"]);XCTAssertNil(app.pollCompanionUnlock(now:0,blocked:true));XCTAssertNil(app.pollCompanionUnlock(now:90,blocked:true));XCTAssertNil(app.companionUnlock)
  let item=try XCTUnwrap(app.pollCompanionUnlock(now:180,blocked:false));XCTAssertEqual(item.type,"alien");XCTAssertEqual(app.learner.settingsSnapshot["companionUnlocksCelebrated"]["alien"],.bool(true));XCTAssertTrue(UserDefaults.standard.bool(forKey:"companionUnlockCelebrated:"+app.identity.npub+":alien"));XCTAssertEqual(app.learner.totalXP,xp);XCTAssertEqual(app.learner.companionHealth,health);XCTAssertEqual(app.learner.companionType,"ghost")
  app.finishCompanionUnlock(item,equip:false);XCTAssertNil(app.companionUnlock);XCTAssertEqual(app.learner.companionType,"ghost");app.loadLocal();XCTAssertTrue(app.pendingCompanionUnlocks.isEmpty);XCTAssertNil(app.pollCompanionUnlock(now:2000,blocked:false))
 }
 func testEquipKeepsCurrentNameAndOldAccountCallbackCannotEquip()throws{
  let app=try model();defer{try? app.identity.disconnect()};app.learner.award(1);_=app.pollCompanionUnlock(now:0,blocked:false);let item=try XCTUnwrap(app.pollCompanionUnlock(now:1000,blocked:false));app.learner.companionName="New name after queue";let xp=app.learner.totalXP;app.finishCompanionUnlock(item,equip:true);XCTAssertEqual(app.learner.companionName,"New name after queue");XCTAssertEqual(app.learner.companionType,"alien");XCTAssertEqual(app.learner.totalXP,xp)
  app.signedIn=false;try app.identity.create();app.signedIn=true;app.learner.companionType="ghost";app.finishCompanionUnlock(item,equip:true);XCTAssertEqual(app.learner.companionType,"ghost");XCTAssertNil(app.companionUnlock)
 }
 func testHydratedCloudFlagSkipsQueuedUnlockAndResourceIncludesEverySupportedLanguage()throws{
  let app=try model();defer{try? app.identity.disconnect()};app.learner.award(1);app.learner.changeSettings(.object(["companionUnlocksCelebrated":.object(["alien":.bool(true)])]));_=app.pollCompanionUnlock(now:0,blocked:false);XCTAssertNil(app.pollCompanionUnlock(now:1000,blocked:false));XCTAssertTrue(app.pendingCompanionUnlocks.isEmpty)
  for language in ["en","es","fr","pt","it","de","ja","hi","zh","ar"]{let copy=CompanionUnlockUI.copy(language);for key in ["title","subtitle","equip","keep","saveFailed"]{XCTAssertFalse(copy[key].string.isEmpty,"\(language) \(key)")};for type in ["alien","robot","slime","dog","axolotl"]{XCTAssertFalse(copy["names"][type].string.isEmpty)}}
 }
 func testPresentationIsRememberedEvenWhenProcessRestartsBeforeChoosing()throws{
  let app=try model();defer{try? app.identity.disconnect()};app.learner.award(1);_=app.pollCompanionUnlock(now:0,blocked:false);_=try XCTUnwrap(app.pollCompanionUnlock(now:1000,blocked:false));XCTAssertNotNil(app.companionUnlock)
  let restored=AppModel();XCTAssertEqual(restored.identity.npub,app.identity.npub);XCTAssertTrue(restored.signedIn);XCTAssertEqual(restored.learner.settingsSnapshot["companionUnlocksCelebrated"]["alien"],.bool(true));XCTAssertEqual(restored.learner.companionType,"ghost");XCTAssertNil(restored.companionUnlock);XCTAssertTrue(restored.pendingCompanionUnlocks.isEmpty)
 }

 func testOngoingCloudXPCrossingQueuesButPreviouslyCelebratedHydrationDoesNot()async throws{
  let service=CompanionUnlockProgressDouble(),app=try model(progressService:service);defer{try? app.identity.disconnect()};app.learner.changeSettings(.object(["allowPosts":.bool(false)]));var cloud=app.learner;cloud.xpByLanguage=[cloud.target:400];cloud.pendingSettingsChanges=[];service.next=cloud;await app.sync()
  XCTAssertEqual(app.pendingCompanionUnlocks.map(\.type),["alien","robot"]);XCTAssertNil(app.companionUnlock);XCTAssertEqual(app.learner.companionLevel,5)
  app.loadLocal();XCTAssertEqual(app.pendingCompanionUnlocks.map(\.type),["alien","robot"],"Restoration itself cannot append unlocks")
  cloud.changeSettings(.object(["companionUnlocksCelebrated":.object(["alien":.bool(true),"robot":.bool(true)])]));cloud.pendingSettingsChanges=[];service.next=cloud;await app.sync();_=app.pollCompanionUnlock(now:0,blocked:false);XCTAssertNil(app.pollCompanionUnlock(now:1000,blocked:false));XCTAssertTrue(app.pendingCompanionUnlocks.isEmpty)
 }

}

@MainActor private final class CompanionUnlockProgressDouble:LearnerProgressService {
 var next:LearnerState?
 func load(npub:String,local:LearnerState?)async throws->LearnerState?{next}
 func save(_ state:LearnerState,npub:String)async throws->LearnerState?{next}
}
