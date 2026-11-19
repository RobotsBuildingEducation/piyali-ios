import XCTest
@testable import Piyali

@MainActor final class ReadingSpeechRecorderTests:XCTestCase {
    @MainActor private final class Driver {
        var callbacks:[Int:@MainActor (ReadingRecognitionEvent)->Void]=[:]
        var begun:[Int]=[],finished:[Int]=[],aborted:[Int]=[]
        var authorization:()async throws->Void = {}
        var client:ReadingRecognitionClient { .init(authorize:{ try await self.authorization() },begin:{ id,_,callback in self.begun.append(id);self.callbacks[id]=callback },finish:{ self.finished.append($0) },abort:{ self.aborted.append($0) },release:{}) }
        func send(_ event:ReadingRecognitionEvent,_ id:Int) { callbacks[id]?(event) }
    }
    private func started(_ driver:Driver,_ count:Int) async {
        for _ in 0..<100 { if driver.begun.count >= count { return };await Task.yield() };XCTFail("Expected native recognition start")
    }
    func testStopFinishesBufferedAudioAndAcceptsItsLateFinalWords() async {
        let driver=Driver(),recorder=ReadingSpeechRecorder(client:driver.client);defer { recorder.cancel() }
        recorder.start(language:"es");await started(driver,1);driver.send(.result("Una fr"),1);recorder.stop()
        XCTAssertEqual(recorder.phase,.stopping);XCTAssertEqual(driver.finished,[1]);XCTAssertTrue(driver.aborted.isEmpty)
        driver.send(.result("Una frase completa."),1);driver.send(.ended,1)
        XCTAssertEqual(recorder.phase,.idle);XCTAssertEqual(recorder.transcript,"Una frase completa.");XCTAssertTrue(recorder.capture.pending.isEmpty)
        driver.send(.result("Old replay"),1);XCTAssertEqual(recorder.transcript,"Una frase completa.")
    }
    func testUtteranceRestartKeepsEarlierTextAndDoesNotArchiveDuplicateCallbacks() async throws {
        let driver=Driver(),recorder=ReadingSpeechRecorder(client:driver.client);defer { recorder.cancel() }
        recorder.start(language:"es");await started(driver,1);driver.send(.result("Primera frase."),1);driver.send(.ended,1);driver.send(.ended,1)
        XCTAssertEqual(recorder.phase,.listening);try await Task.sleep(for:.milliseconds(140));await started(driver,2)
        driver.send(.result("Segunda fr"),2);XCTAssertEqual(recorder.transcript,"Primera frase. Segunda fr")
        recorder.stop();driver.send(.result("Segunda frase."),2);driver.send(.ended,2)
        XCTAssertEqual(recorder.transcript,"Primera frase. Segunda frase.");XCTAssertEqual(recorder.phase,.idle)
    }
    func testMissingFinalCallbackRecoversAfterTheSourceCutoff() async throws {
        let driver=Driver(),recorder=ReadingSpeechRecorder(client:driver.client);defer { recorder.cancel() }
        recorder.start(language:"es");await started(driver,1);driver.send(.result("Last available words"),1);recorder.stop()
        XCTAssertEqual(recorder.phase,.stopping);try await Task.sleep(for:.milliseconds(1650))
        XCTAssertEqual(recorder.phase,.idle);XCTAssertEqual(driver.aborted,[1]);XCTAssertEqual(recorder.transcript,"Last available words");XCTAssertNil(recorder.issue)
    }
    func testReplacedPermissionRequestCannotOpenAnOldMicrophoneSession() async throws {
        let driver=Driver();var permission:[CheckedContinuation<Void,Error>]=[]
        driver.authorization={ try await withCheckedThrowingContinuation { permission.append($0) } }
        let recorder=ReadingSpeechRecorder(client:driver.client);defer { recorder.cancel() }
        recorder.start(language:"es");for _ in 0..<100 { if permission.count == 1 { break };await Task.yield() };XCTAssertEqual(permission.count,1)
        recorder.start(language:"fr");for _ in 0..<100 { if permission.count == 2 { break };await Task.yield() };XCTAssertEqual(permission.count,2)
        guard permission.count == 2 else { permission.forEach { $0.resume() };return }
        permission[1].resume();await started(driver,1);permission[0].resume();for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(driver.begun,[2]);recorder.cancel();driver.send(.result("Late words"),2);XCTAssertEqual(recorder.phase,.idle);XCTAssertTrue(recorder.transcript.isEmpty)
    }
    func testCancellationKeepsDisplayedPartialAndIgnoresLateErrors() async {
        let driver=Driver(),recorder=ReadingSpeechRecorder(client:driver.client)
        recorder.start(language:"es");await started(driver,1);driver.send(.result("Visible words"),1);recorder.cancel();let saved=recorder.capture
        driver.send(.result("Late words"),1);driver.send(.failed("network"),1);driver.send(.ended,1)
        XCTAssertEqual(recorder.capture,saved);XCTAssertEqual(recorder.transcript,"Visible words");XCTAssertNil(recorder.issue);XCTAssertEqual(driver.aborted,[1])
    }
    func testAppleTaskErrorsKeepSilencePermissionsTransportAndServiceFailuresDistinct() {
        for (domain,code,expected) in [("kAFAssistantErrorDomain",1110,"no-speech"),("kAFAssistantErrorDomain",1700,"mic-denied"),("kLSRErrorDomain",201,"mic-denied"),("kLSRErrorDomain",301,"aborted"),("kAFAssistantErrorDomain",1107,"recording-failed"),("kAFAssistantErrorDomain",203,"recording-failed"),(NSURLErrorDomain,NSURLErrorNetworkConnectionLost,"network"),(NSURLErrorDomain,NSURLErrorCancelled,"aborted")] {
            XCTAssertEqual(AppleReadingRecognition.code(NSError(domain:domain,code:code)),expected)
        }
    }
}
