import XCTest
import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import FirebaseFirestore
@testable import Piyali
@MainActor private final class CompanionSaveDouble:LearnerProgressService {
    var calls:[SettingsChange]=[],failure=true,genericFailure=false,held=false
    var resume:CheckedContinuation<Void,Never>?
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{if genericFailure{throw AppError.message("Unrelated practice failure.")};return nil}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{calls.append(change);if held{await withCheckedContinuation{resume=$0}};if failure{throw AppError.message("Cloud permission denied.")};return true}
}
@MainActor final class CompanionSaveTests:XCTestCase {
 private func model(_ service:any LearnerProgressService)throws->AppModel{let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")};let app=AppModel(progressService:service);try app.identity.create();app.signedIn=true;app.learner=LearnerState();app.learner.support="es";app.learner.xpByLanguage=[app.learner.target:100];app.learner.onboardingComplete=true;app.learner.companionProgress = .object(["dailyGoalPetHealth":.number(37)]);return app}
 private func until(_ predicate:()->Bool)async throws{for _ in 0..<250{if predicate(){return};try await Task.sleep(for:.milliseconds(20))};XCTFail("Companion save did not settle")}
 func testFailureKeepsOptimisticChoiceOneReceiptAndCapturedLocaleWithoutRepeatingOnGenericRetry()async throws{
  let store=CompanionSaveDouble(),app=try model(store);defer{try? app.identity.disconnect()};let xp=app.learner.totalXP;app.customizeCompanion(name:"  Cielo  ",type:"ALIEN");app.learner.support="de"
  XCTAssertEqual(app.learner.companionName,"Cielo");XCTAssertEqual(app.learner.companionType,"alien");XCTAssertEqual(app.learner.pendingSettingsChanges?.filter{$0.partial["dailyGoalPetType"] != .null}.count,1);XCTAssertEqual(app.learner.totalXP,xp);XCTAssertEqual(app.learner.companionHealth,37);XCTAssertNil(app.error)
  try await until{app.companionSaveNotices.count==1};let notice=try XCTUnwrap(app.companionSaveNotices.first);XCTAssertEqual(notice.title,"Error al guardar");XCTAssertEqual(notice.description,"Cloud permission denied.");XCTAssertEqual(store.calls.count,1)
  store.genericFailure=true;await app.sync();app.persist();try await Task.sleep(for:.milliseconds(650));XCTAssertEqual(app.companionSaveNotices.count,1);XCTAssertEqual(store.calls.count,1);XCTAssertEqual(app.learner.companionName,"Cielo");XCTAssertTrue(app.learner.pendingSettingsChanges?.isEmpty == false);XCTAssertNil(app.error)
  try await until{app.companionSaveNotices.isEmpty};XCTAssertEqual(app.learner.companionName,"Cielo")
 }
 func testRealSDKDeniedWriteRetainsOptimisticChoiceAndPendingReceipt()async throws{
  guard ProcessInfo.processInfo.environment["PIYALI_RULES_EMULATOR_TESTS"] == "1" else{throw XCTSkip("Explicit strict rules emulator required")};let name="CompanionSaveDeniedContract"
  if FirebaseApp.app(name:name)==nil{let options=FirebaseOptions(googleAppID:"1:123456789012:ios:0123456789abcdef012345",gcmSenderID:"123456789012");options.projectID="demo-piyali-ios-auth";options.apiKey="emulator-only-not-a-production-key";AppCheck.setAppCheckProviderFactory(CompanionDeniedFactory());FirebaseApp.configure(name:name,options:options);let db=Firestore.firestore(app:FirebaseApp.app(name:name)!);db.useEmulator(withHost:"127.0.0.1",port:8280);let settings=db.settings;settings.cacheSettings=MemoryCacheSettings();settings.isSSLEnabled=false;db.settings=settings}
  let db=Firestore.firestore(app:FirebaseApp.app(name:name)!),store=CompanionSDKRecorder(service:FirebaseService(database:db)),app=try model(store);defer{try? app.identity.disconnect()};app.customizeCompanion(name:"Saved locally",type:"alien");try await until{app.companionSaveNotices.count==1};let failure=try XCTUnwrap(store.failure);XCTAssertEqual(failure.code,FirestoreErrorCode.permissionDenied.rawValue);XCTAssertTrue(failure.domain.contains("Firestore"));XCTAssertEqual(app.companionSaveNotices[0].description,failure.localizedDescription);XCTAssertFalse(app.companionSaveNotices[0].renderedDescription.hasPrefix("\n"));XCTAssertEqual(app.learner.companionName,"Saved locally");XCTAssertEqual(app.learner.companionType,"alien");XCTAssertEqual(app.learner.companionHealth,37);XCTAssertEqual(app.learner.pendingSettingsChanges?.filter{$0.partial["dailyGoalPetName"] != .null}.count,1);XCTAssertNil(app.error)
 }

 func testPortalRemainsNonKeyPassesOutsideHitsAndAbsorbsToastHitsAboveFullScreenCover()async throws{
  let store=CompanionSaveDouble(),app=try model(store);defer{try? app.identity.disconnect()};let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene),host=UIHostingController(rootView:Color.clear.background(CompanionSaveNoticePresenter().environmentObject(app)));window.rootViewController=host;window.makeKeyAndVisible();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
  app.customizeCompanion(name:"Cielo",type:"alien");try await until{app.companionSaveNotices.count==1};try await Task.sleep(for:.milliseconds(100));let portal=try XCTUnwrap(scene.windows.compactMap{$0 as? CompanionSaveNoticePresenter.Portal}.first{!$0.isHidden});try await until{!portal.regions.isEmpty};let bounds=try XCTUnwrap(portal.regions.values.first);XCTAssertFalse(portal.canBecomeKey);XCTAssertFalse(portal.isKeyWindow);XCTAssertTrue(window.isKeyWindow);XCTAssertNotNil(portal.hitTest(CGPoint(x:bounds.midX,y:bounds.midY),with:nil));XCTAssertNil(portal.hitTest(CGPoint(x:20,y:40),with:nil));let cover=UIViewController();cover.modalPresentationStyle = .fullScreen;host.present(cover,animated:false);try await Task.sleep(for:.milliseconds(100));XCTAssertFalse(portal.isHidden,"The toast portal must survive temporary root detachment during covers");XCTAssertNil(portal.hitTest(CGPoint(x:10,y:700),with:nil));XCTAssertNotNil(portal.hitTest(CGPoint(x:bounds.midX,y:bounds.midY),with:nil));host.dismiss(animated:false);app.signedIn=false;try await Task.sleep(for:.milliseconds(50));XCTAssertTrue(portal.isHidden)
 }

 func testSuccessfulAndUnchangedSavesEachSubmitOneIntentAndDoNotCreateFeedbackOnRestore()async throws{
  let store=CompanionSaveDouble();store.failure=false;let app=try model(store);defer{try? app.identity.disconnect()};app.customizeCompanion(name:"Nova",type:"alien");try await until{store.calls.count==1};app.customizeCompanion(name:"Nova",type:"alien");try await until{store.calls.count==3};XCTAssertEqual(store.calls[0].id,store.calls[1].id,"The second request confirms its existing predecessor before its own intent");XCTAssertNotEqual(store.calls[0].id,store.calls[2].id);XCTAssertEqual(app.learner.pendingSettingsChanges?.count,2);XCTAssertTrue(app.companionSaveNotices.isEmpty)
  let restored=AppModel(progressService:store);XCTAssertEqual(restored.learner.companionName,"Nova");XCTAssertTrue(restored.companionSaveNotices.isEmpty);await restored.sync();XCTAssertEqual(store.calls.count,3)
 }
 func testOldAccountFailureAndCanceledRequestCannotShowFeedbackOrChangeNewCompanion()async throws{
  let store=CompanionSaveDouble();store.held=true;let app=try model(store);defer{try? app.identity.disconnect()};app.customizeCompanion(name:"Alice choice",type:"alien");try await until{store.resume != nil};app.signedIn=false;try app.identity.create();app.signedIn=true;app.learner.companionName="Bob choice";store.resume?.resume();store.resume=nil;try await Task.sleep(for:.milliseconds(100));XCTAssertTrue(app.companionSaveNotices.isEmpty);XCTAssertEqual(app.learner.companionName,"Bob choice")
 }
 func testEquipUsesSameFailedSaveFeedbackWhileKeepMakesNoRequest()async throws{
  let store=CompanionSaveDouble(),app=try model(store);defer{try? app.identity.disconnect()};app.learner.xpByLanguage=[app.learner.target:99];app.learner.companionName="Current name";app.learner.award(1);_=app.pollCompanionUnlock(now:0,blocked:false);let first=try XCTUnwrap(app.pollCompanionUnlock(now:1000,blocked:false));app.finishCompanionUnlock(first,equip:true);XCTAssertNil(app.companionUnlock);XCTAssertEqual(app.learner.companionName,"Current name");XCTAssertEqual(app.learner.companionType,"alien");try await until{app.companionSaveNotices.count==1};XCTAssertEqual(store.calls.count,1)
  app.learner.xpByLanguage=[app.learner.target:400];_=app.pollCompanionUnlock(now:2000,blocked:false);let second=try XCTUnwrap(app.pollCompanionUnlock(now:3000,blocked:false));app.finishCompanionUnlock(second,equip:false);try await Task.sleep(for:.milliseconds(100));XCTAssertEqual(store.calls.count,1);XCTAssertEqual(app.learner.companionType,"alien")
 }
}

private final class CompanionDeniedCheck:NSObject,AppCheckProvider{func getToken(completion:@escaping(AppCheckToken?,Error?)->Void){completion(AppCheckToken(token:"local-emulator-token",expirationDate:Date().addingTimeInterval(3600)),nil)}}
private final class CompanionDeniedFactory:NSObject,AppCheckProviderFactory{func createProvider(with app:FirebaseApp)->AppCheckProvider?{CompanionDeniedCheck()}}

@MainActor private final class CompanionSDKRecorder:LearnerProgressService {
 let service:FirebaseService
 var failure:NSError?
 init(service:FirebaseService){self.service=service}
 func load(npub:String,local:LearnerState?)async throws->LearnerState?{try await service.load(npub:npub,local:local)}
 func save(_ state:LearnerState,npub:String)async throws->LearnerState?{try await service.save(state,npub:npub)}
 func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{do{return try await service.saveCompanionCustomization(change,npub:npub)}catch{failure=error as NSError;throw error}}
}
