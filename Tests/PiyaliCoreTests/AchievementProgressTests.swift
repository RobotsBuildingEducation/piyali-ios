import XCTest
@testable import PiyaliCore

final class AchievementProgressTests: XCTestCase {
    private func fixture() throws -> JSONValue {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/achievements.json")
        return try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
    }
    func testAllProgressionRequirementsMatchReferenceIncludingHigherLevelProof() throws {
        let fixtures=try fixture()["requirements"].array;XCTAssertEqual(fixtures.count,576)
        for test in fixtures { XCTAssertEqual(AchievementProgress.meets(test["requirement"],evidence:test["evidence"]),test["expected"].boolean,test["id"].string+test["evidence"].json) }
    }
    func testFlashcardsRequireSavedSuccessAndKeepLanguagesSeparate() throws {
        let cases=try fixture()["cards"].array;XCTAssertEqual(cases.count,63)
        for test in cases { XCTAssertEqual(AchievementProgress.flashcardEvent(language:test["language"].string,id:test["id"].string,progress:test["progress"]) ?? .null,test["expected"],test.json) }
    }
    func testGoalRepairAndImmersionProofsMatchConfirmedSource() throws {
        for test in try fixture()["proofs"].array {
            let i=test["input"],proof=AchievementProgress.completionProof(profile:i["profile"],summary:i["summary"],quest:i["quest"],language:i["language"].string,day:i["dayKey"].string)
            XCTAssertEqual(proof.events,test["expected"]["events"].array)
            XCTAssertEqual(proof.evidence,test["expected"]["evidence"])
        }
    }
    func testPhonicsRequiresEveryCardAndCountsDistinctDecks() throws {
        for test in try fixture()["phonics"].array {
            let proof=AchievementProgress.phonicsProof(language:test["language"].string,base:test["base"].array,documents:test["documents"].array)
            XCTAssertEqual(proof.events,test["expected"]["events"].array)
            let actual=proof.evidence["sets"]["phonics_cards"],expected=test["expected"]["evidence"]["sets"]["phonics_cards"]
            XCTAssertEqual(Set(actual["required"].array.map(\.string)),Set(expected["required"].array.map(\.string)));XCTAssertEqual(Set(actual["completed"].array.map(\.string)),Set(expected["completed"].array.map(\.string)))
        }
    }
    func testLedgerUnionIsIdempotentAndIgnoresInvalidOrRetiredEntries() {
        let a=JSONValue.foundation(["goals:b1":["one":1],"flashcards_completed:es":["a1-one":1],"retired":["x":1]])
        let b=JSONValue.foundation(["goals:b1":["one":1,"two":1,"invalid":-1],"flashcards_completed:fr":["a1-one":1]])
        let allowed:Set<String>=["goals","flashcards_completed"]
        let merged=AchievementProgress.mergedLedger([a,b],allowed:allowed)
        XCTAssertEqual(merged["goals:b1"].object.count,2);XCTAssertNil(merged.object["retired"])
        XCTAssertEqual(AchievementProgress.mergedLedger([merged,a,b],allowed:allowed),merged)
        let snap=AchievementProgress.snapshot(ledger:merged,evidence:.object([:]))
        XCTAssertEqual(snap["levelCounts"]["goals"]["b1"].number,2)
        XCTAssertEqual(snap["counters"]["flashcards_completed:es"].number,1)
    }
}
