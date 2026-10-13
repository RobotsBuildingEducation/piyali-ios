import XCTest
@testable import PiyaliCore

final class ProgressTests: XCTestCase {
    func testAwardTracksLanguageAndCapsNegativeXP() {
        var state = LearnerState(); state.award(10); state.award(-20)
        XCTAssertEqual(state.xp, 10)
        state.target = "fr"; state.award(20)
        XCTAssertEqual(state.xp, 20); XCTAssertEqual(state.totalXP, 30)
    }
    func testLessonCompletionIsIdempotentAndLanguageScoped() throws {
        let json = #"{"id":"lesson-1","title":{"en":"Hello"},"description":{"en":"Greetings"},"xpReward":30,"modes":["reading"],"agenda":{},"content":{}}"#
        let lesson = try JSONDecoder().decode(Lesson.self, from: Data(json.utf8))
        var state = LearnerState()
        XCTAssertTrue(state.complete(lesson)); XCTAssertFalse(state.complete(lesson)); XCTAssertEqual(state.xp, 30)
        state.target = "fr"; XCTAssertTrue(state.complete(lesson)); XCTAssertEqual(state.xp, 30)
    }
    func testStreakAcrossMidnightAndMissedDay() {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        var state = LearnerState(); state.dailyGoal = 20
        state.award(20, now: day, calendar: calendar); state.award(10, now: day, calendar: calendar)
        XCTAssertEqual(state.streak, 1)
        state.award(20, now: day.addingTimeInterval(86400), calendar: calendar); XCTAssertEqual(state.streak, 2)
        state.rollDay(now: day.addingTimeInterval(86400*3), calendar: calendar); XCTAssertEqual(state.streak, 0); XCTAssertEqual(state.dailyXP, 0)
    }
    func testAccentDistinctionAndWhitespace() {
        XCTAssertTrue(AnswerMatcher.matches("  ¡Hola! ", "hola"))
        XCTAssertFalse(AnswerMatcher.matches("si", "sí"))
        XCTAssertFalse(AnswerMatcher.matches("", ""))
    }
    func testPersistenceRoundTrip() throws {
        var state = LearnerState(); state.award(10); state.notes = [Note(title:"Remember",body:"Bonjour")]
        let restored = try JSONDecoder().decode(LearnerState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.xp, 10); XCTAssertEqual(restored.notes.first?.body,"Bonjour")
    }
    func testBundledCurriculaAndDecksDecode() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Piyali/Resources")
        for lang in ["es","en","pt","fr","it","nl","nah","ja","ru","de","el","pl","ga","yua"] {
            let levels = try ContentLibrary.decode([String:[LearningUnit]].self, url: root.appendingPathComponent("curriculum-\(lang).json.gz"))
            XCTAssertEqual(Set(levels.keys),Set(LearningLanguages.levels))
            for units in levels.values { XCTAssertFalse(units.isEmpty); XCTAssertTrue(units.allSatisfy { !$0.lessons.isEmpty }) }
        }
        let cards = try ContentLibrary.decode([Flashcard].self, url: root.appendingPathComponent("flashcards.json.gz"))
        XCTAssertEqual(cards.count,1150); XCTAssertEqual(Set(cards.map(\.id)).count,cards.count)
        let phonics = try ContentLibrary.decode([String:[PhonicsCard]].self,url:root.appendingPathComponent("phonics.json.gz"))
        XCTAssertEqual(phonics.count,1190); XCTAssertFalse(phonics["es:en:Pre-A1"]!.isEmpty)
    }
}
