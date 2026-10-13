import XCTest
@testable import PiyaliCore

final class MemoryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970:1_792_080_000)
    func testOverlappingSyncDoesNotReplayAlreadyCommittedPracticeOrMemory() {
        var sent = LearnerState(); sent.award(10)
        var current = sent; current.award(5)
        current.captureMemory(mode:"grammar",concept:"a concept",answer:"x",expected:"y",feedback:"")
        var cloud = current
        cloud.acknowledgedEventIDs = Set((current.pendingChanges ?? []).map(\.id) + (current.pendingMemoryChanges ?? []).map(\.id))
        cloud.pendingChanges = []; cloud.pendingMemoryChanges = []
        let merged = LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(merged.xp,15); XCTAssertEqual(merged.companionMemory?["es"]?.first?.severity,1)
        XCTAssertTrue(merged.pendingChanges?.isEmpty == true); XCTAssertTrue(merged.pendingMemoryChanges?.isEmpty == true)
    }
    func testRepeatedSlipsStrengthenOneMemoryAndPreserveEnrichment() {
        var state = LearnerState()
        state.captureMemory(mode:"grammar",concept:"  Verb   order ",answer:"first",expected:"correct",feedback:"A useful explanation",now:now)
        let id = state.companionMemory?["es"]?.first?.id
        state.companionMemory?["es"]?[0].fields["tip"] = .string("Web enrichment")
        for index in 1...4 { state.captureMemory(mode:"grammar",concept:"verb order",answer:"later",expected:"correct",feedback:"",now:now.addingTimeInterval(Double(index))) }
        XCTAssertEqual(state.companionMemory?["es"]?.count,1)
        let note = state.companionMemory?["es"]?.first
        XCTAssertEqual(note?.id,id); XCTAssertEqual(note?.severity,3)
        XCTAssertEqual(note?.text("mistake"),"A useful explanation"); XCTAssertEqual(note?.text("tip"),"Web enrichment")
        XCTAssertEqual(note?.text("userAnswer"),"later"); XCTAssertEqual(state.xp,0)
        XCTAssertEqual(state.pendingMemoryChanges?.count,5)
    }
    func testTargetLanguageIsolationAndReinforcementLifecycle() {
        var state = LearnerState()
        state.captureMemory(mode:"flashcard",concept:"word",answer:"wrong",expected:"word",feedback:"",now:now)
        let id = state.companionMemory!["es"]![0].id
        state.target = "fr"; state.captureMemory(mode:"flashcard",concept:"word",answer:"wrong",expected:"word",feedback:"",now:now)
        XCTAssertEqual(state.companionMemory?["es"]?.count,1); XCTAssertEqual(state.companionMemory?["fr"]?.count,1)
        state.target = "es"; state.reinforceMemory(id:id,now:now)
        let note = state.companionMemory!["es"]![0], today = CalendarDay.key(now)
        XCTAssertFalse(note.active(on:today)); XCTAssertEqual(note.text("status"),"reinforced")
        XCTAssertEqual(note.text("usedInQuestDayKey"),today)
        XCTAssertEqual(state.companionMemory?["fr"]?.first?.text("status"),"captured")
    }
    func testWindowExpiresAtDayTwoAndLimitsRecentNotes() {
        var notes: [MemoryNote] = []
        for index in 0..<45 {
            let date = now.addingTimeInterval(Double(index))
            let note = MemoryContract.capture(target:"es",support:"en",level:"A1",mode:"grammar",concept:"concept \(index)",answer:"x",expected:"y",feedback:"",now:date)
            notes = MemoryContract.applying(MemoryChange(action:.capture,target:"es",date:date,dayKey:CalendarDay.key(now),note:note),to:notes,today:CalendarDay.key(now))
        }
        XCTAssertEqual(notes.count,40); XCTAssertEqual(notes.first?.text("concept"),"concept 44")
        XCTAssertTrue(notes[0].active(on:CalendarDay.shift(CalendarDay.key(now),by:1)))
        XCTAssertFalse(notes[0].active(on:CalendarDay.shift(CalendarDay.key(now),by:2)))
    }
    func testSyncReplaysOnlyMemoryCapturedWhileRequestWasInFlight() {
        let date = Date()
        var sent = LearnerState(); sent.captureMemory(mode:"flashcard",concept:"first",answer:"x",expected:"y",feedback:"",now:date)
        var current = sent; current.captureMemory(mode:"grammar",concept:"second",answer:"x",expected:"y",feedback:"",now:date.addingTimeInterval(1))
        var cloud = sent; cloud.pendingMemoryChanges = []
        cloud.captureMemory(mode:"reading",concept:"other device",answer:"x",expected:"y",feedback:"",now:date); cloud.pendingMemoryChanges = []
        let merged = LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(Set(merged.companionMemory!["es"]!.map { $0.text("concept") }),["first","second","other device"])
        XCTAssertEqual(merged.pendingMemoryChanges?.count,1)
    }
    func testSupportLanguageChangeClearsOldLocalizedTip() {
        var state = LearnerState()
        state.captureMemory(mode:"grammar",concept:"word",answer:"x",expected:"y",feedback:"English explanation",now:now)
        state.companionMemory?["es"]?[0].fields["tip"] = .string("English tip")
        state.support = "fr"
        state.captureMemory(mode:"grammar",concept:"word",answer:"x",expected:"y",feedback:"Explication",now:now.addingTimeInterval(1))
        XCTAssertEqual(state.companionMemory?["es"]?.first?.text("mistake"),"Explication")
        XCTAssertEqual(state.companionMemory?["es"]?.first?.text("tip"),"")
    }
}
