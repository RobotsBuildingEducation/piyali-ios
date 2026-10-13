import XCTest
@testable import PiyaliCore

final class ResponsesOutputTests:XCTestCase {
    private func message(_ text:String,phase:String = "") -> JSONValue {
        .object(["type":.string("message"),"phase":.string(phase),"content":.array([.object(["type":.string("output_text"),"text":.string(text)])])])
    }
    func testFinalAnswerExcludesIntermediateJSONAndReasoning() throws {
        let body:JSONValue = .object(["status":.string("completed"),"output_text":.string("{\"draft\":true}{\"result\":true}"),"output":.array([message("{\"draft\":true}",phase:"commentary"),.object(["type":.string("reasoning"),"content":.array([.object(["text":.string("private reasoning")])])]),message("{\"result\":true}",phase:"final_answer")])])
        XCTAssertEqual(try ResponsesOutput.text(body,structured:true),"{\"result\":true}")
        XCTAssertEqual(try ResponsesOutput.text(body,structured:false),"{\"result\":true}")
    }
    func testSeparateJSONMessagesDoNotConcatenateButSegmentsDo() throws {
        let body:JSONValue = .object(["output":.array([message("{\"old\":true}"),.object(["type":.string("message"),"content":.array([.object(["type":.string("output_text"),"text":.string("{\"value\":" )]),.object(["type":.string("output_text"),"text":.string("1}")])])])])])
        XCTAssertEqual(try ResponsesOutput.text(body,structured:true),"{\"value\":1}")
        XCTAssertEqual(try ResponsesOutput.text(.object(["output_text":.string("fallback")]),structured:false),"fallback")
    }
    func testIncompleteRefusedAndEmptyCannotBecomePracticeAnswers() {
        XCTAssertThrowsError(try ResponsesOutput.text(.object(["status":.string("incomplete"),"output_text":.string("{\"unfinished\":" )]),structured:true))
        XCTAssertThrowsError(try ResponsesOutput.text(.object(["output":.array([.object(["type":.string("message"),"content":.array([.object(["type":.string("refusal"),"refusal":.string("No")])])])])]),structured:true))
        XCTAssertThrowsError(try ResponsesOutput.text(.object([:]),structured:false))
    }
}
