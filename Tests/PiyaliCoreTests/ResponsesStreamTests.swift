import XCTest
@testable import PiyaliCore

final class ResponsesStreamTests:XCTestCase {
    @discardableResult private func event(_ value:JSONValue,to stream:inout ResponsesStream)throws->String? {
        XCTAssertNil(try stream.receive(line:"event: ignored-envelope-name"))
        XCTAssertNil(try stream.receive(line:"data: "+value.json));return try stream.receive(line:"")
    }
    private func added(_ phase:String="",index:Int=0)->JSONValue{.object(["type":.string("response.output_item.added"),"output_index":.number(Double(index)),"item":.object(["type":.string("message"),"phase":.string(phase)])])}
    private func delta(_ text:String,index:Int=0,part:Int=0)->JSONValue{.object(["type":.string("response.output_text.delta"),"output_index":.number(Double(index)),"content_index":.number(Double(part)),"delta":.string(text),"obfuscation":.string("never-display")])}
    private func completed(_ text:String,status:String="completed")->JSONValue{.object(["type":.string("response.completed"),"response":.object(["status":.string(status),"output_text":.string(text)])])}
    func testDeltasAppearBeforeCompletionWithoutDuplicatingFinalText()throws {
        var stream=ResponsesStream()
        XCTAssertNil(try stream.receive(line:": keepalive"));XCTAssertNil(try stream.receive(line:""))
        try event(added(),to:&stream)
        XCTAssertEqual(try event(delta("اسأل "),to:&stream),"اسأل ")
        XCTAssertThrowsError(try stream.finish())
        XCTAssertEqual(try event(delta("بثقة 🌍"),to:&stream),"اسأل بثقة 🌍")
        XCTAssertNil(try event(.object(["type":.string("response.output_text.done"),"text":.string("اسأل بثقة 🌍")]),to:&stream))
        XCTAssertNil(try event(completed("اسأل بثقة 🌍"),to:&stream))
        XCTAssertTrue(stream.completed);XCTAssertEqual(try stream.finish(),"اسأل بثقة 🌍")
    }
    func testCommentaryAndReasoningStayOutOfHeadlineAndCanonicalFinalWins()throws {
        var stream=ResponsesStream()
        try event(added("commentary"),to:&stream)
        XCTAssertNil(try event(delta("hidden commentary"),to:&stream))
        XCTAssertNil(try event(.object(["type":.string("response.reasoning_text.delta"),"delta":.string("hidden reasoning")]),to:&stream))
        try event(added("final_answer",index:2),to:&stream)
        XCTAssertEqual(try event(delta("Second",index:2,part:1),to:&stream),"Second")
        XCTAssertEqual(try event(delta("First ",index:2,part:0),to:&stream),"First Second")
        XCTAssertEqual(try event(completed("Canonical final"),to:&stream),"Canonical final")
        XCTAssertEqual(try stream.finish(),"Canonical final")
    }
    func testFailedRefusedMalformedAndTruncatedStreamsCannotBeCached()throws {
        for type in ["response.failed","response.incomplete","error","response.refusal.delta","response.refusal.done"] {
            var stream=ResponsesStream();try event(added(),to:&stream);try event(delta("partial"),to:&stream)
            XCTAssertThrowsError(try event(.object(["type":.string(type)]),to:&stream));XCTAssertThrowsError(try stream.finish())
        }
        var stream=ResponsesStream()
        try stream.receive(line:"data: [DONE]");try stream.receive(line:"");XCTAssertThrowsError(try stream.finish())
        try stream.receive(line:"data: {broken");XCTAssertThrowsError(try stream.receive(line:""))
        XCTAssertThrowsError(try event(completed("partial",status:"incomplete"),to:&stream))
        XCTAssertThrowsError(try event(completed(""),to:&stream))
        XCTAssertThrowsError(try event(added().setting("output_index",.number(1e30)),to:&stream))
    }
    func testMultilineDataAndFrameLimits()throws {
        var stream=ResponsesStream()
        try stream.receive(line:"data: {\"type\":\"response.created\",")
        try stream.receive(line:"data: \"response\":{}}")
        XCTAssertNil(try stream.receive(line:""))
        XCTAssertThrowsError(try stream.receive(line:"data: "+String(repeating:"x",count:1_048_576)))
    }
    func testRawTransportPreservesEmptyFramesUTF8AndAllSSELineEndings()throws {
        for separator in ["\n","\r\n","\r"] {
            var stream=ResponsesStream(),updates:[String]=[]
            let wire="\u{FEFF}: keepalive"+separator+separator+[added(),delta("اسأل 🌍"),delta(" بثقة"),completed("اسأل 🌍 بثقة")].map{"event: sample"+separator+"data: "+$0.json+separator+separator}.joined()
            for byte in wire.utf8{if let update=try stream.receive(byte:byte){updates.append(update)}}
            XCTAssertEqual(updates,["اسأل 🌍","اسأل 🌍 بثقة"]);XCTAssertEqual(try stream.finish(),"اسأل 🌍 بثقة")
        }
        var broken=ResponsesStream();try broken.receive(byte:0xFF);XCTAssertThrowsError(try broken.receive(byte:10))
    }
}
