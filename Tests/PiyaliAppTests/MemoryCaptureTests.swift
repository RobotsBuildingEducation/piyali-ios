import XCTest
@testable import Piyali

@MainActor final class MemoryCaptureTests:XCTestCase {
    func testRepeatedCaptureGetsNewIdentityAndOldExpiryCannotClearIt()async throws {
        var waits:[CheckedContinuation<Void,Error>]=[]
        let capture=MemoryCaptureController(sleep:{_ in try await withCheckedThrowingContinuation{waits.append($0)}})
        capture.capture("owner:es:en");let old=try XCTUnwrap(capture.event?.id)
        for _ in 0..<100 where waits.count<1{await Task.yield()}
        capture.capture("owner:es:en");let next=try XCTUnwrap(capture.event?.id);XCTAssertNotEqual(old,next)
        for _ in 0..<100 where waits.count<2{await Task.yield()};XCTAssertEqual(waits.count,2)
        waits[0].resume();for _ in 0..<20{await Task.yield()};XCTAssertEqual(capture.event?.id,next)
        waits[1].resume();for _ in 0..<100 where capture.event != nil{await Task.yield()};XCTAssertNil(capture.event)
    }
    func testCaptureScopeReplacementAndActualSourceLifetime()async throws {
        let capture=MemoryCaptureController();capture.capture("owner:es:en");XCTAssertNotNil(capture.current(in:"owner:es:en"));XCTAssertNil(capture.current(in:"other:es:en"))
        capture.bind("owner:es:ar");XCTAssertNil(capture.event)
        XCTAssertEqual(MemoryCaptureDesign.data["lifetimeMS"].number,3070);capture.capture("owner:es:ar")
        try await Task.sleep(for:.milliseconds(2800));XCTAssertNotNil(capture.event)
        try await Task.sleep(for:.milliseconds(400));XCTAssertNil(capture.event)
    }
}
