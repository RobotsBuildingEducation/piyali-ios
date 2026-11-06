import XCTest
@testable import PiyaliCore

final class ReadingCaptureTests:XCTestCase {
    func testNativeContinuousRecorderAgreesWithOriginalEventAndClockJourneys()throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/reading-capture.json.gz"),data=try ContentLibrary.decode(JSONValue.self,url:url)
        XCTAssertEqual(data["fixtures"].array.count,15)
        for fixture in data["fixtures"].array {
            var capture=ReadingSpeechCapture(),sessions:[[String:Int]]=[],timers:[ReadingSpeechCapture.Timer:(Int,Int)]=[:]
            func effects(_ effects:[ReadingSpeechCapture.Effect]) {
                for effect in effects { switch effect {
                case .begin(let id):XCTAssertEqual(id,sessions.count+1);sessions.append(["starts":1,"stops":0,"aborts":0])
                case .finish(let id):sessions[id-1]["stops",default:0] += 1
                case .abort(let id):sessions[id-1]["aborts",default:0] += 1
                case .schedule(let key,let token,let delay):timers[key]=(token,delay)
                case .cancel(let key):timers.removeValue(forKey:key)
                } }
            }
            for (index,step) in fixture["steps"].array.enumerated() {
                let values=step.array,id=Int(values.count>1 ? values[1].number : 0)
                switch values[0].string {
                case "start":effects(capture.start())
                case "stop":effects(capture.stop())
                case "cancel":effects(capture.cancel())
                case "result":effects(capture.result(session:id,text:values[2].string))
                case "end":effects(capture.ended(session:id))
                case "error":effects(capture.failed(session:id,code:values[2].string))
                case "tick":let pending=timers;for (key,(token,delay)) in pending where delay == id { if timers[key]?.0 == token { timers.removeValue(forKey:key);effects(capture.fired(key,token:token)) } }
                default:XCTFail("Unknown source event")
                }
                let actual:JSONValue = .object(["text":.string(capture.transcript),"phase":.string(capture.phase.rawValue),"issue":capture.issue.map(JSONValue.string) ?? .null,"timers":.array(timers.values.map { .number(Double($0.1)) }.sorted { $0.number < $1.number }),"sessions":.array(sessions.map { .object($0.mapValues { .number(Double($0)) }) })])
                XCTAssertEqual(actual,fixture["expected"].array[index],fixture["name"].string+" event \(index)")
            }
        }
        for sample in data["errors"].array { let feedback=ReadingSpeechCapture.feedback(sample["code"].string);XCTAssertEqual(feedback.title,sample["expected"]["title"].string);XCTAssertEqual(feedback.description,sample["expected"]["description"].string);XCTAssertEqual(feedback.status,sample["expected"]["status"].string) }
    }
    func testCancelledClockCannotStopANewerRecordingAndLongUnicodeTranscriptIsKept()throws {
        var capture=ReadingSpeechCapture();_=capture.start();let oldLimit=try XCTUnwrap(capture.pending[.limit]);_=capture.start()
        _=capture.fired(.limit,token:oldLimit);XCTAssertEqual(capture.phase,.listening)
        let text=String(repeating:"Ein längerer Satz mit Wörtern. ",count:180)+"Schlusswort."
        XCTAssertGreaterThan(text.count,4000);_=capture.result(session:try XCTUnwrap(capture.session),text:text);XCTAssertEqual(capture.transcript,text)
        let oversized=String(repeating:"言葉🌱",count:5000),bounded=ReadingSpeechCapture.boundedTranscript(oversized)
        XCTAssertLessThanOrEqual(bounded.utf8.count,16_000);XCTAssertFalse(bounded.contains("�"));XCTAssertTrue(oversized.hasPrefix(bounded))
    }
}
