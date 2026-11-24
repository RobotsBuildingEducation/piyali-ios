import XCTest
@testable import PiyaliCore

final class GeminiTutorBridgeTests:XCTestCase {
    func testOriginalBridgeTracesForTurnOrderingPlaybackInputAndReset()throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/gemini-bridge.json.gz"),traces=try ContentLibrary.decode([JSONValue].self,url:url)
        XCTAssertEqual(traces.count,9)
        for trace in traces{
            let bridge=GeminiTutorBridge();var events:[JSONValue]=[],sent:[JSONValue]=[],audio:[JSONValue]=[],autoRequest=false,clock=10000.0
            bridge.onEvent={event in events.append(event);if event["type"].string == "conversation.item.input_audio_transcription.completed",autoRequest{bridge.request("App-directed reply")}}
            bridge.onText={sent.append(.object(["type":.string("text"),"text":.string($0),"complete":.bool(true)]))}
            bridge.onInput={sent.append(.object(["type":.string("input"),"mimeType":.string("audio/pcm;rate=16000"),"data":.string($0.base64EncodedString())]))}
            bridge.onAudio={data,_ in audio.append(.object(["bytes":.string(data.base64EncodedString()),"stopped":.bool(false)]))}
            bridge.onStopAudio={for i in audio.indices where audio[i]["played"] != .bool(true){audio[i]=audio[i].setting("stopped",.bool(true))}}
            bridge.onReset={sent.append(.object(["type":.string("close")]));sent.append(.object(["type":.string("connect")]))}
            for row in trace["steps"].array{
                let c=row["command"],expected=row["expected"],context=trace["name"].string+" "+c.canonicalJSON
                switch c["op"].string{
                case "request":bridge.request(c["text"].string.isEmpty ? "Teach now":c["text"].string,metadata:c["metadata"] == .null ? .object([:]):c["metadata"])
                case "server":bridge.receive(c["message"])
                case "input":bridge.setInputEnabled(c["enabled"].boolean)
                case "pcm":clock+=c["advance"].number;bridge.inputPCM(Data(base64Encoded:c["data"].string)!,nowMilliseconds:clock)
                case "play":let index=Int(c["index"].number);if audio.indices.contains(index){audio[index]=audio[index].setting("played",.bool(true))};bridge.played(index+1)
                case "cancel":bridge.cancel()
                case "clear":bridge.clearInput()
                case "gain":bridge.setOutputGain(c["value"].number)
                case "timeout":if let id=bridge.snapshot["pending"].array.first?.string{bridge.responseTimedOut(id)}
                case "resetReady":bridge.resetReady()
                case "autoRequest":autoRequest=c["enabled"].boolean
                case "context":break
                case "close":let connected = !bridge.resetting;bridge.close();if connected{sent.append(.object(["type":.string("close")]))}
                default:XCTFail(context)
                }
                XCTAssertEqual(events,expected["events"].array,context);XCTAssertEqual(sent,expected["sent"].array,context)
                XCTAssertEqual(audio.map{.object($0.object.filter{$0.key != "played"})},expected["audio"].array,context)
                if bridge.closed {XCTAssertFalse(bridge.inputEnabled,context)}else{XCTAssertEqual(bridge.snapshot,expected["state"],context)}
            }
        }
    }
}
