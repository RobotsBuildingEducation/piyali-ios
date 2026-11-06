import XCTest
@testable import Piyali

@MainActor final class MemoryAchievementJournal:AchievementSyncJournal {
    var data:[String:[String:Bool]]=[:],readFails=false,writeFails=false
    func read(_ account:String)throws->[String:Bool]{if readFails{throw URLError(.cannotOpenFile)};return data[account] ?? [:]}
    func write(_ flags:[String:Bool],account:String)throws{if writeFails{throw URLError(.cannotWriteToFile)};data[account]=flags}
}
@MainActor final class AchievementRetryControllerTests:XCTestCase {
    private func until(_ predicate:()->Bool)async throws{for _ in 0..<300{if predicate(){return};try await Task.sleep(for:.milliseconds(10))};XCTFail("Retry worker did not settle")}
    func testIndependentDestinationsRetryWithoutAnotherLearningAction()async throws{
        let journal=MemoryAchievementJournal(),worker=AchievementRetryController(journal:journal,sleep:{try await Task.sleep(for:.milliseconds($0==0 ? 1:20))});var cloud=0,relay=0
        worker.configure(cloud:{_ in cloud += 1;if cloud==1{throw URLError(.notConnectedToInternet)}},relay:{_ in relay += 1});worker.setAccount("one");worker.resume();try await until{cloud==2 && relay==1 && !worker.pending};XCTAssertEqual(journal.data["one"],["cloud":false,"relay":false]);worker.pause()
    }
    func testNewGenerationDuringSaveCannotBeAcknowledgedByItsOlderSnapshot()async throws{
        let journal=MemoryAchievementJournal(),worker=AchievementRetryController(journal:journal);var cloud=0,active=0,maximum=0,resume:CheckedContinuation<Void,Never>?
        worker.configure(cloud:{_ in cloud += 1;active += 1;maximum=max(maximum,active);await withCheckedContinuation{resume=$0};active -= 1},relay:{_ in});worker.setAccount("one")
        let first=Task{try await worker.runNow(.cloud)};try await until{resume != nil};worker.schedule(.cloud);let old=resume;resume=nil;old?.resume();try await first.value;try await until{cloud==2 && resume != nil};XCTAssertTrue(worker.pending(.cloud));XCTAssertEqual(journal.data["one"]?["cloud"],true);resume?.resume();resume=nil;try await until{!worker.pending};XCTAssertEqual(maximum,1);worker.pause()
    }
    func testAtomicJournalRestoresBothChannelsAndOnlyResumesCurrentAccount()async throws{
        let root=FileManager.default.temporaryDirectory.appendingPathComponent("achievement-retry-"+UUID().uuidString),journal=FileAchievementSyncJournal(root:root);defer{try? FileManager.default.removeItem(at:root)}
        let first=AchievementRetryController(journal:journal);first.configure(cloud:{_ in throw URLError(.notConnectedToInternet)},relay:{_ in throw URLError(.notConnectedToInternet)});first.setAccount("one");do{try await first.runNow(.cloud)}catch{};do{try await first.runNow(.relay)}catch{};first.pause();XCTAssertEqual(try journal.read("one"),["cloud":true,"relay":true])
        let restored=AchievementRetryController(journal:journal);var accounts:[String]=[];restored.configure(cloud:{accounts.append("cloud:"+$0)},relay:{accounts.append("relay:"+$0)});restored.setAccount("one");XCTAssertTrue(restored.pending);restored.setAccount("two");restored.resume();try await until{accounts.count==2 && !restored.pending};XCTAssertEqual(Set(accounts),["cloud:two","relay:two"]);XCTAssertEqual(try journal.read("one"),["cloud":true,"relay":true]);restored.setAccount("one");restored.resume();try await until{accounts.count==4 && !restored.pending};XCTAssertEqual(try journal.read("one"),["cloud":false,"relay":false]);restored.pause()
    }
    func testFailedIntentJournalWritesRetainFailureUntilActualSuccessfulWrite()async throws{
        let journal=MemoryAchievementJournal();journal.readFails=true;journal.writeFails=true;let worker=AchievementRetryController(journal:journal);worker.configure(cloud:{_ in},relay:{_ in});worker.setAccount("one");XCTAssertTrue(worker.storageError);XCTAssertTrue(worker.pending);try await worker.runNow(.cloud);XCTAssertTrue(worker.storageError);journal.writeFails=false;try await worker.runNow(.relay);XCTAssertFalse(worker.storageError);XCTAssertEqual(journal.data["one"],["cloud":false,"relay":false]);worker.pause()
    }
    func testDeadlineReleasesNonCooperativeOperationWithoutClearingDurableIntent()async throws{
        let journal=MemoryAchievementJournal(),worker=AchievementRetryController(journal:journal,timeoutMilliseconds:40);var resume:CheckedContinuation<Void,Never>?
        worker.configure(cloud:{_ in await withCheckedContinuation{resume=$0}},relay:{_ in});worker.setAccount("one");do{try await worker.runNow(.cloud);XCTFail("Expected deadline")}catch{XCTAssertEqual(error.localizedDescription,"Achievement sync timed out")};XCTAssertTrue(worker.pending(.cloud));worker.pause();resume?.resume();try await Task.sleep(for:.milliseconds(30));XCTAssertTrue(worker.pending(.cloud));XCTAssertEqual(journal.data["one"]?["cloud"],true)
    }
    func testPausedOldAccountCompletionCannotClearNewAccountIntent()async throws{
        let journal=MemoryAchievementJournal(),worker=AchievementRetryController(journal:journal);var resume:CheckedContinuation<Void,Never>?
        worker.configure(cloud:{_ in await withCheckedContinuation{resume=$0}},relay:{_ in});worker.setAccount("one");let first=Task{try await worker.runNow(.cloud)};try await until{resume != nil};worker.setAccount("two");worker.pause();worker.schedule(.cloud);resume?.resume();try await first.value;XCTAssertTrue(worker.pending(.cloud));XCTAssertEqual(journal.data["two"]?["cloud"],true);XCTAssertEqual(journal.data["one"]?["cloud"],false)
    }
}
