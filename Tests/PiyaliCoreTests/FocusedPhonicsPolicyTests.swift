import XCTest
@testable import PiyaliCore

final class FocusedPhonicsPolicyTests:XCTestCase {
    @MainActor func testOriginalAsyncFocusedDeckCanonicalLocalizationRolesAndCompletion()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),fixture=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/focused-phonics.json.gz")),engine=try CompanionQuestPolicy(source:root.appendingPathComponent("Piyali/Resources/companion-quest-policy.js"))
        XCTAssertEqual(fixture["rows"].array.count,23)
        for row in fixture["rows"].array {
            let actual=try engine.run("focusedPhonicsDeck",row["input"].setting("decks",fixture["decks"]))
            XCTAssertEqual(actual,row["expected"],row["name"].string)
            XCTAssertEqual(try engine.run("focusedPhonicsCapture",row["captureInput"]),row["capture"],row["name"].string)
            let completion=try engine.run("focusedPhonicsCompletion",.object(["artifact":actual,"goal":.bool(row["input"]["focus"]["blueprint"] != .null)]))
            XCTAssertEqual(completion,row["completion"],row["name"].string)
        }
    }
    @MainActor func testPendingRepairStepKeepsPlateBonusBehindAcknowledgmentIncludingLegacyReceipt()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),engine=try CompanionQuestPolicy(source:root.appendingPathComponent("Piyali/Resources/companion-quest-policy.js")),day=CalendarDay.key(Date()),plan:JSONValue = .object(["targetLang":.string("es"),"dayKey":.string(day),"target":.number(1),"items":.array([.object(["memoryId":.string("phonics"),"concept":.string("casa"),"mode":.string("phonics"),"errorType":.string("phonics")])])])
        let step=try JSONDecoder().decode(RepairStep.self,from:Data(engine.run("next",.object(["plan":plan,"completedCount":.number(0)])).json.utf8));var state=LearnerState();state.target="es";state.questPlans=["es":.init(day:day,kinds:["repair","review"])];state.questProgress = .object(["dailyQuestFirstSeen":.bool(true),"dailyQuestFirstDayKey":.string(CalendarDay.shift(day,by:-1)),"flashcardDailyActivity":.object(["es":.object([day:.number(5)])])]);state.storeCompanionBlueprint(.object(["status":.string("ready"),"repair":plan]),target:"es",day:day)
        XCTAssertTrue(state.completeRepairStep(step,summary:.object([:]),observation:"original and transfer pronounced after a model",support:"modeled"));XCTAssertEqual(state.plateProgress["repairDailyActivity"]["es"][day].number,1);XCTAssertEqual(state.confirmedPlateProgress["repairDailyActivity"]["es"][day].number,0);XCTAssertFalse(state.claimPlate(user:"public-phonics-fixture"))
        state.pendingChanges?[0].repairStepIndex=nil;state=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertEqual(state.confirmedPlateProgress["repairDailyActivity"]["es"][day].number,0);XCTAssertFalse(state.claimPlate(user:"public-phonics-fixture"))
        state.pendingChanges=[];state.pendingRepairEvidence=[];XCTAssertTrue(state.claimPlate(user:"public-phonics-fixture"));XCTAssertEqual(state.totalXP,25);XCTAssertFalse(state.claimPlate(user:"public-phonics-fixture"))
    }

}
