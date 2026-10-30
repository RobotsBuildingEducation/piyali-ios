import XCTest
@testable import PiyaliCore

@MainActor final class StoryGenerationCoordinatorTests:XCTestCase {
    private func run(_ title:String)throws->StoryRun {
        let payload:JSONValue = .object(["title":.string(title),"sentences":.array([.object(["speaker":.string("Sheilfer"),"target":.string("Hola.")]),.object(["speaker":.string("You"),"target":.string("Buenos días.")])])])
        return try StoryRun(payload:payload,mode:.speaking,target:"es",support:"en",level:"Pre-A1",lessonID:nil,worth:.null,tutorial:true)
    }
    func testMalformedOptionalRewriteCannotDiscardUsableStory() async throws {
        var requests=0
        let result=try await StoryGenerationCoordinator.generate(prompt:"original",mode:.speaking,generate:{ _,revision in requests += 1;return revision ? "invalid" : "first" },validate:{ raw in if raw == "invalid" { throw StoryFailure.invalid };return try self.run(raw) },issues:{ _ in ["change the opening"] },review:{ _ in [] },revision:{ _,_,_ in "rewrite" })
        XCTAssertEqual(result.title,"first");XCTAssertEqual(requests,2)
    }
    func testStyleOpinionDoesNotCauseMoreThanOneRewriteAndKeepsBetterCandidate() async throws {
        var requests=0
        let result=try await StoryGenerationCoordinator.generate(prompt:"original",mode:.radio,generate:{ _,_ in requests += 1;return requests == 1 ? "first" : "second" },validate:{ try self.run($0) },issues:{ $0.title == "first" ? ["a"] : ["a","b"] },review:{ _ in ["style"] },revision:{ _,_,_ in "rewrite" })
        XCTAssertEqual(result.title,"first");XCTAssertEqual(requests,2)
    }
    func testInvalidInitialCandidatesMustRecoverWithinSourceAttemptBudget() async throws {
        var requests=0
        let result=try await StoryGenerationCoordinator.generate(prompt:"original",mode:.speaking,generate:{ _,_ in requests += 1;return requests == 3 ? "valid" : "invalid" },validate:{ raw in if raw == "invalid" { throw StoryFailure.invalid };return try self.run(raw) },issues:{ _ in [] },review:{ _ in [] },revision:{ _,_,_ in "repair" })
        XCTAssertEqual(result.title,"valid");XCTAssertEqual(requests,3)
        requests=0
        do {
            _=try await StoryGenerationCoordinator.generate(prompt:"original",mode:.radio,generate:{ _,_ in requests += 1;return "invalid" },validate:{ _ in throw StoryFailure.invalid },issues:{ _ in [] },review:{ _ in [] },revision:{ _,_,_ in "repair" })
            XCTFail("Invalid episodes must not become usable stories")
        } catch { XCTAssertEqual(requests,2) }
    }
    func testUncooperativeLateReviewerCannotHoldUpOrReplaceValidStory() async throws {
        let start=Date()
        let result=try await StoryGenerationCoordinator.generate(prompt:"original",mode:.speaking,generate:{ _,_ in "first" },validate:{ try self.run($0) },issues:{ _ in [] },review:{ _ in
            await withCheckedContinuation { continuation in Task { @MainActor in try? await Task.sleep(for:.milliseconds(400));continuation.resume(returning:["late opinion"]) } }
        },revision:{ _,_,_ in XCTFail("A late review must not rewrite the story");return "" },reviewTimeout:0.02)
        XCTAssertEqual(result.title,"first");XCTAssertLessThan(Date().timeIntervalSince(start),0.3)
    }
    func testCancellationDuringValidationCannotReturnAnEarlierCandidate() async throws {
        let work=Task { @MainActor in
            var requests=0
            return try await StoryGenerationCoordinator.generate(prompt:"original",mode:.speaking,generate:{ _,_ in requests += 1;return requests == 1 ? "first" : "second" },validate:{ raw in
                if raw == "second" { withUnsafeCurrentTask { $0?.cancel() };throw StoryFailure.invalid }
                return try self.run(raw)
            },issues:{ _ in ["change opening"] },review:{ _ in [] },revision:{ _,_,_ in "rewrite" })
        }
        do { _=try await work.value;XCTFail("Cancellation must win over an older usable candidate") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

}
