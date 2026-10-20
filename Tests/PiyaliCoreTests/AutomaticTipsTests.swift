import XCTest
@testable import PiyaliCore

final class AutomaticTipsTests:XCTestCase {
    private func event(_ amount:Int) -> PracticeChange { PracticeChange(dayKey:"2026-10-20",target:"es",level:"A1",amount:amount,source:.practice) }
    func testDisabledByDefaultAndOnlyPositiveNewEventsAreEligible() {
        var journal=AutomaticTipJournal();let earned=event(10)
        journal.enqueue([earned],available:10);XCTAssertTrue(journal.queue.isEmpty)
        journal.configure(enabled:true,recipient:"recipient",maximumFee:0);journal.enqueue([event(0),event(-1),earned,earned],available:10);XCTAssertEqual(journal.queue.map(\.id),[earned.id.uuidString.lowercased()])
    }
    func testFeeBudgetBoundsQueueAndNoFundsNeverAccumulateDebt() {
        var journal=AutomaticTipJournal();journal.configure(enabled:true,recipient:"recipient",maximumFee:1)
        journal.enqueue((0..<10).map { _ in event(5) },available:5);XCTAssertEqual(journal.queue.count,2)
        var empty=AutomaticTipJournal();empty.configure(enabled:true,recipient:"recipient",maximumFee:0);empty.enqueue([event(5)],available:0);XCTAssertTrue(empty.queue.isEmpty);XCTAssertEqual(empty.handled.count,1)
    }
    func testHandledEventSurvivesRelaunchAndConfigurationChangeDoesNotRetargetQueuedMoney() throws {
        var journal=AutomaticTipJournal();journal.configure(enabled:true,recipient:"first",maximumFee:0);let a=event(5),b=event(10)
        journal.enqueue([a,b],available:10);journal.complete(a.id.uuidString.lowercased())
        var restored=try JSONDecoder().decode(AutomaticTipJournal.self,from:JSONEncoder().encode(journal));restored.enqueue([a,b],available:10);XCTAssertEqual(restored.queue.count,1)
        restored.configure(enabled:true,recipient:"second",maximumFee:1);restored.enqueue([a,b],available:10);XCTAssertTrue(restored.queue.isEmpty)
        let fresh=event(5);restored.enqueue([fresh],available:10);XCTAssertEqual(restored.queue[0].recipient,"second");XCTAssertEqual(restored.queue[0].maximumFee,1)
    }
    func testDisableAndPauseCancelQueuedTipsWithoutReplayingThemLater() {
        var journal=AutomaticTipJournal();journal.configure(enabled:true,recipient:"recipient",maximumFee:0);let earned=event(5);journal.enqueue([earned],available:10)
        journal.pause("Receiving setup unavailable");XCTAssertFalse(journal.enabled);XCTAssertTrue(journal.queue.isEmpty);XCTAssertNotNil(journal.pauseReason)
        journal.configure(enabled:true,recipient:"recipient",maximumFee:0);journal.enqueue([earned],available:10);XCTAssertTrue(journal.queue.isEmpty)
    }
}
