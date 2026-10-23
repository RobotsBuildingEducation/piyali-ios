import XCTest
@testable import PiyaliCore

final class PlateHeadlineTests:XCTestCase {
    private var root:URL {URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    @MainActor func testOriginalSummaryPromptCleaningAndCacheCasesRunInJavaScriptCore() throws {
        let cases=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/plate-headline-policy.json"))),policy=try PlateHeadlinePolicy(source:root.appendingPathComponent("Piyali/Resources/plate-headline-policy.js"))
        XCTAssertEqual(cases.count,60)
        for row in cases {
            XCTAssertEqual(try policy.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string+" "+row["input"].json)
            if row["operation"].string == "stored" {
                let p=row["input"];var state=WebProgressContract.imported(p["user"].foundation as? [String:Any] ?? [:]);state.target=p["targetLang"].string;state.support=p["appLanguage"].string
                XCTAssertEqual(state.plateHeadline(day:p["dayKey"].string),row["expected"] == .null ? nil : row["expected"].string,"The actual native cache getter must agree with the source too.")
            }
        }
    }
    func testHeadlinesAreScopedCachedWithoutChangingProgressAndSurviveOldJSON() throws {
        var state=LearnerState();state.xpByLanguage=["es":42];state.dailyXP=12;state.dailyKey="2026-10-23"
        let before=state;let entry=PlateHeadline(dayKey:"2026-10-23",appLanguage:"en",text:"  Ask about plans.  ");state.storePlateHeadline(entry,target:"es")
        XCTAssertEqual(state.plateHeadline(day:"2026-10-23"),"Ask about plans.");state.target=" ES ";state.support=" EN ";XCTAssertEqual(state.plateHeadline(day:"2026-10-23"),"Ask about plans.");state.target="es";state.support="en";XCTAssertNil(state.plateHeadline(day:"2026-10-24"));state.support="fr";XCTAssertNil(state.plateHeadline(day:"2026-10-23"));state.support="en";state.target="fr";XCTAssertNil(state.plateHeadline(day:"2026-10-23"))
        XCTAssertEqual(state.totalXP,before.totalXP);XCTAssertEqual(state.dailyXP,before.dailyXP);XCTAssertEqual(state.pendingChanges?.map(\.id),before.pendingChanges?.map(\.id));XCTAssertEqual(state.preferencesModifiedAt,before.preferencesModifiedAt)
        let data=try JSONEncoder().encode(state),restored=try JSONDecoder().decode(LearnerState.self,from:data);XCTAssertEqual(restored.pendingPlateHeadlines?["es"],entry)
        var old=try JSONDecoder().decode(JSONValue.self,from:data).object;old.removeValue(forKey:"plateHeadlines");old.removeValue(forKey:"pendingPlateHeadlines");let legacy=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(JSONValue.object(old)));XCTAssertNil(legacy.plateHeadlines)
    }
    func testCanonicalImportAndAcknowledgmentKeepOnlyNewerLocalHeadlines() {
        let day="2026-10-23",first=PlateHeadline(dayKey:"2026-10-23",appLanguage:"en",text:"First"),french=PlateHeadline(dayKey:"2026-10-23",appLanguage:"fr",text:"Nouveau"),tomorrow=PlateHeadline(dayKey:"2026-10-24",appLanguage:"en",text:"Tomorrow")
        var sent=LearnerState();sent.storePlateHeadline(first,target:"es")
        var current=sent;current.storePlateHeadline(french,target:"es");current.storePlateHeadline(first,target:"fr")
        let acknowledged=WebProgressContract.imported(["dailyPlateHeadline":["es":first.fields]])
        let rebased=LearnerState.rebased(current:current,sent:sent,acknowledged:acknowledged);XCTAssertEqual(rebased.pendingPlateHeadlines,["es":french,"fr":first]);XCTAssertEqual(rebased.plateHeadlines?["es"]?.cached(day:day,support:"fr"),"Nouveau")
        let synced=LearnerState.rebased(current:sent,sent:sent,acknowledged:acknowledged);XCTAssertTrue(synced.pendingPlateHeadlines?.isEmpty == true);XCTAssertEqual(synced.plateHeadlines?["es"],first)
        let imported=WebProgressContract.imported(["dailyPlateHeadline":["es":tomorrow.fields]],native:sent);XCTAssertEqual(imported.plateHeadlines?["es"],first,"An unsynced local intent is retained until acknowledged, including across different device-local dates.")
        XCTAssertEqual(WebProgressContract.imported(["dailyPlateHeadline":[:]],native:synced).plateHeadlines,[:],"iosStateJSON is not a second authority for removed canonical entries.")
    }
}
