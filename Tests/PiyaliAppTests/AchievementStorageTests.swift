import XCTest
@testable import Piyali

@MainActor final class AchievementStorageTests:XCTestCase {
 func testFailedLocalAwardSaveWarnsUntilAnActualSuccessfulRetry()throws{
  let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")}
  let app=AppModel();try app.identity.create();defer{try? app.identity.disconnect()}
  let path=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Piyali",isDirectory:true).appendingPathComponent(app.identity.npub+".json");XCTAssertFalse(FileManager.default.fileExists(atPath:path.path));try FileManager.default.createDirectory(at:path,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:path)}
  app.learner.achievementRecords=["piyali_tutor_complete_pre_a1":.object(["unlockedAt":.number(123)])];app.persist();XCTAssertTrue(app.localStorageUnavailable);XCTAssertNotNil(app.error);XCTAssertEqual(app.learner.achievementRecords?["piyali_tutor_complete_pre_a1"]?["unlockedAt"],.number(123))
  try FileManager.default.removeItem(at:path);app.persist();XCTAssertFalse(app.localStorageUnavailable);let saved=try JSONDecoder().decode(LearnerState.self,from:Data(contentsOf:path));XCTAssertEqual(saved.achievementRecords,app.learner.achievementRecords)
 }
}
