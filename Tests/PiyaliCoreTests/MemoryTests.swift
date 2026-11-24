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
        state.localizeMemory(state.companionMemory!["es"]![0],fields:.object(["mistake":.string("A useful explanation")]),support:"en",now:now)
        state.companionMemory?["es"]?[0].fields["tip"] = .string("Web enrichment")
        for index in 1...4 { state.captureMemory(mode:"grammar",concept:"verb order",answer:"later",expected:"correct",feedback:"",now:now.addingTimeInterval(Double(index))) }
        XCTAssertEqual(state.companionMemory?["es"]?.count,1)
        let note = state.companionMemory?["es"]?.first
        XCTAssertEqual(note?.id,id); XCTAssertEqual(note?.severity,3)
        XCTAssertEqual(note?.text("mistake"),"A useful explanation"); XCTAssertEqual(note?.text("tip"),"Web enrichment")
        XCTAssertEqual(note?.text("userAnswer"),"later"); XCTAssertEqual(state.xp,0)
        XCTAssertEqual(state.pendingMemoryChanges?.filter{$0.action == .capture}.count,5)
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
        XCTAssertEqual(state.companionMemory?["es"]?.first?.text("mistake"),"")
        XCTAssertEqual(state.companionMemory?["es"]?.first?.fields["enriched"],.bool(false))
        XCTAssertEqual(state.companionMemory?["es"]?.first?.text("tip"),"")
    }
}


extension MemoryTests {
    func testPendingEnrichmentRetainsFullContextAcrossAckAndANewerSlipReplacesItsVersion()throws {
        let now=Date();var state=LearnerState();let concept=String(repeating:"x",count:241)
        state.captureMemory(mode:"grammar",concept:concept,answer:"first",expected:"hola",feedback:"private",now:now)
        let note=try XCTUnwrap(state.companionMemory?["es"]?.first),intent=try XCTUnwrap(state.queueMemoryEnrichment(account:"public-owner",note:note,concept:concept)),sent=state
        var ack=sent;ack.pendingMemoryChanges=[];ack.pendingMemoryEnrichments=nil
        let first=LearnerState.rebased(current:state,sent:sent,acknowledged:ack),firstRestored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(first))
        XCTAssertEqual(firstRestored.pendingMemoryEnrichments?.first?.id,intent.id);XCTAssertEqual(firstRestored.pendingMemoryEnrichments?.first?.concept,concept);XCTAssertEqual(firstRestored.pendingMemoryEnrichments?.first?.note.text("userAnswer"),"first")
        state.captureMemory(mode:"grammar",concept:String(concept.prefix(240)),answer:"second",expected:"new fix",feedback:"private",now:now.addingTimeInterval(1))
        let newer=try XCTUnwrap(state.companionMemory?["es"]?.first),latest=try XCTUnwrap(state.queueMemoryEnrichment(account:"public-owner",note:newer,concept:String(concept.prefix(240))));XCTAssertNotEqual(latest.id,intent.id)
        let restored=LearnerState.rebased(current:state,sent:sent,acknowledged:ack)
        XCTAssertEqual(restored.pendingMemoryEnrichments?.count,1);XCTAssertEqual(restored.pendingMemoryEnrichments?.first?.id,latest.id);XCTAssertEqual(restored.pendingMemoryEnrichments?.first?.note.text("userAnswer"),"second");XCTAssertEqual(restored.companionMemory?["es"]?.first?.text("expectedAnswer"),"hola");XCTAssertEqual(restored.totalXP,0)
    }
    func testFinishedFailureAndCompletedEnrichmentCannotBeResurrectedByAnOlderAcknowledgment()throws {
        for success in [false,true] {
            let now=Date();var state=LearnerState();state.captureMemory(mode:"grammar",concept:"A greeting",answer:"ola",expected:"hola",feedback:"",now:now)
            let note=try XCTUnwrap(state.companionMemory?["es"]?.first),intent=try XCTUnwrap(state.queueMemoryEnrichment(account:"public-owner",note:note,concept:"A greeting")),sent=state
            if success{state.localizeMemory(note,fields:.object(["mistake":.string("The h was missing."),"tip":.string("Start with hola.")]),support:"en",now:now.addingTimeInterval(1))}else{XCTAssertTrue(state.finishMemoryEnrichment(intent.id))}
            let restored=LearnerState.rebased(current:state,sent:sent,acknowledged:sent)
            XCTAssertTrue(restored.pendingMemoryEnrichments?.isEmpty == true);XCTAssertEqual(restored.companionMemory?["es"]?.first?.fields["enriched"],.bool(success));XCTAssertEqual(restored.totalXP,0);XCTAssertNil(restored.gradedByLanguage)
            XCTAssertFalse(state.finishMemoryEnrichment(intent.id))
        }
    }
    func testEnrichmentPrivateSchemaIsOptionalAndStaleNoteVersionsRetire()throws {
        var state=LearnerState();state.captureMemory(mode:"grammar",concept:"A greeting",answer:"ola",expected:"hola",feedback:"",now:now);let note=try XCTUnwrap(state.companionMemory?["es"]?.first)
        _=state.queueMemoryEnrichment(account:"public-owner",note:note,concept:"A greeting")
        var raw=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as? [String:Any]);raw.removeValue(forKey:"pendingMemoryEnrichments");let legacy=try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:raw));XCTAssertNil(legacy.pendingMemoryEnrichments)
        state.companionMemory?["es"]?[0].fields["supportLang"] = .string("ar");state.reconcileMemoryEnrichments();XCTAssertTrue(state.pendingMemoryEnrichments?.isEmpty == true)
        let replacement=try XCTUnwrap(state.companionMemory?["es"]?.first);_=state.queueMemoryEnrichment(account:"public-owner",note:replacement,concept:"تحية");XCTAssertEqual(state.pendingMemoryEnrichments?.count,1);state.companionMemory=["es":[]];state.reconcileMemoryEnrichments();XCTAssertTrue(state.pendingMemoryEnrichments?.isEmpty == true)
    }
}
