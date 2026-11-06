import XCTest
@testable import Piyali

@MainActor final class AchievementDeliveryTests:XCTestCase {
 func testConfirmedDeliveryIsSessionScopedKeepsFIFOAndNeverAwardsXPOrReplaysRestoration()throws{
  let e=ProcessInfo.processInfo.environment;guard e["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated account required")}
  let app=AppModel();try app.identity.create();app.signedIn=true;defer{try? app.identity.disconnect()};let account=app.identity.npub,xp=app.learner.totalXP,ids=["nosabos_tutor_lessons_5","nosabos_tutor_lessons_10"],records=JSONValue.object(Dictionary(uniqueKeysWithValues:ids.map{($0,.object(["unlockedAt":.number(123)]))}))
  app.receiveConfirmedAchievement(.init(account:"different",records:records,ids:ids));XCTAssertTrue(app.achievementUnlock.queue.isEmpty)
  app.receiveConfirmedAchievement(.init(account:account,records:.object([:]),ids:ids));XCTAssertTrue(app.achievementUnlock.queue.isEmpty)
  app.receiveConfirmedAchievement(.init(account:account,records:records,ids:ids));app.receiveConfirmedAchievement(.init(account:account,records:records,ids:ids));XCTAssertEqual(app.achievementUnlock.queue.map(\.achievementID),ids);XCTAssertEqual(app.learner.totalXP,xp)
  let first=try XCTUnwrap(app.achievementUnlock.current);app.learner.support="ar";XCTAssertEqual(app.achievementUnlock.language,"ar");XCTAssertEqual(app.achievementUnlock.current?.id,first.id);app.dismissAchievement(first.id);XCTAssertEqual(app.achievementUnlock.current?.achievementID,ids[1])
  app.loadLocal();XCTAssertEqual(app.achievementUnlock.queue.count,1,"Loading permanent records never enqueues celebrations")
  try app.identity.create();app.signedIn=true;XCTAssertTrue(app.achievementUnlock.queue.isEmpty);app.receiveConfirmedAchievement(.init(account:account,records:records,ids:ids));XCTAssertTrue(app.achievementUnlock.queue.isEmpty)
  app.receiveConfirmedAchievement(.init(account:app.identity.npub,records:records,ids:[ids[1]]));let newKey=try XCTUnwrap(app.achievementUnlock.current?.id);app.dismissAchievement(first.id);XCTAssertEqual(app.achievementUnlock.current?.id,newKey);app.signedIn=false;XCTAssertTrue(app.achievementUnlock.queue.isEmpty)
 }
}
