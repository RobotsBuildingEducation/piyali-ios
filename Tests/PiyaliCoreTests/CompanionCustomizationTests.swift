import XCTest
@testable import PiyaliCore
final class CompanionCustomizationTests:XCTestCase {
 func testOriginalBothHostSubmissionRulesAndLevelGates()throws{
  let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),f=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/companion-customization.json.gz"));XCTAssertEqual(f["cases"].array.count,672);XCTAssertEqual(CompanionTypes.ordered,f["types"].array.map(\.string))
  for r in f["cases"].array{let p=CompanionCustomization.partial(name:r["name"].string,type:r["type"].string,level:Int(r["level"].number));XCTAssertEqual(p["dailyGoalPetName"],r["expected"]["name"]);XCTAssertEqual(p["dailyGoalPetType"],r["expected"]["petType"])}
 }
 func testPartialOutboxRestorationInFlightRebaseAndLegacyIntentDoNotTouchOtherPreferences()throws{
  var state=LearnerState();state.target="es";state.xpByLanguage=["es":400];let xp=state.totalXP
  state.customizeCompanion(name:"  Cielo  ",type:"ROBOT");XCTAssertEqual(state.companionName,"Cielo");XCTAssertEqual(state.companionType,"robot");XCTAssertEqual(state.pendingSettingsChanges?.count,1);XCTAssertNil(state.preferencesModifiedAt);XCTAssertEqual(state.totalXP,xp)
  let fields:[String:Any]=["dailyGoalPetName":"Web","dailyGoalPetType":"alien","dailyGoalXp":80,"iosRecentEventIDs":[]],pending=WebProgressContract.imported(fields,native:state);XCTAssertEqual(pending.companionName,"Cielo");XCTAssertEqual(pending.companionType,"robot")
  let sent=state;state.customizeCompanion(name:"Luna",type:"alien");var ack=sent;ack.pendingSettingsChanges=[];ack.acknowledgedEventIDs=Set((sent.pendingSettingsChanges ?? []).map(\.id));ack.companionName="Cielo";let rebased=LearnerState.rebased(current:state,sent:sent,acknowledged:ack);XCTAssertEqual(rebased.companionName,"Luna");XCTAssertEqual(rebased.pendingSettingsChanges?.count,1)
  var legacy=LearnerState();legacy.companionCustomizationVersion=nil;legacy.companionName="Old offline name";legacy.preferencesModifiedAt=Date();let oldBytes=try JSONEncoder().encode(legacy);var replay=try JSONDecoder().decode(LearnerState.self,from:oldBytes);XCTAssertNil(replay.companionCustomizationVersion);legacy.migrateCompanionCustomization();legacy.migrateCompanionCustomization();replay.migrateCompanionCustomization();XCTAssertEqual(replay.pendingSettingsChanges?.first?.id,legacy.pendingSettingsChanges?.first?.id,"A migration retry uses the same durable receipt even before a new local snapshot is written");XCTAssertEqual(legacy.pendingSettingsChanges?.count,1);XCTAssertEqual(legacy.companionCustomizationVersion,1)
 }
}
