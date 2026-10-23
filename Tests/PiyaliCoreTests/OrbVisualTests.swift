import XCTest
@testable import PiyaliCore

final class OrbVisualTests:XCTestCase {
    private func visuals() throws ->JSONValue { try ContentLibrary.decode(JSONValue.self,url:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Piyali/Resources/orb-visuals.json.gz")) }
    private func fixtures() throws ->JSONValue { let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/orb-visuals.json");return try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url)) }
    func testNativeReactionsMatch120ExecutedSourcePosesIncludingReducedMotionAndWholeSpins() throws {
        let data=try visuals(),cases=try fixtures()["cases"].array;XCTAssertEqual(cases.count,120)
        for c in cases {
            let p=OrbVisuals.reaction(c["kind"].string,elapsed:c["elapsed"].number,amount:c["amount"].number,data:data),e=c["pose"]
            for (key,value) in [("x",p.x),("y",p.y),("squash",p.squash),("roll",p.roll),("turn",p.turn),("pitch",p.pitch),("burst",p.burst)] { XCTAssertEqual(value,e[key].number,accuracy:1e-10,"\(c["kind"].string) \(key)") }
        }
    }
    func testNativeMorphMatchesEverySourceEyeOutlineAndCriticallyDampedTrajectory() throws {
        let data=try visuals(),cases=try fixtures()["morphCases"].array;XCTAssertEqual(cases.count,16)
        for c in cases {
            var eyes=OrbVisuals.Eyes(mood:"sleepy",data:data)
            for step in c["steps"].array { eyes.advance(mood:c["mood"].string,state:c["state"].string,time:c["time"].number,dt:step.number) }
            XCTAssertEqual(eyes.values.count,263)
            for i in eyes.values.indices { XCTAssertEqual(eyes.values[i],c["values"].array[i].number,accuracy:1e-9);XCTAssertEqual(eyes.velocity[i],c["velocity"].array[i].number,accuracy:1e-9) }
        }
        var eyes=OrbVisuals.Eyes(mood:"joy",data:data);eyes.advance(mood:"sleepy",state:"idle",time:0,dt:0,immediate:true);XCTAssertEqual(eyes.values,OrbVisuals.expression("sleepy",data:data));XCTAssertTrue(eyes.velocity.allSatisfy{$0 == 0})
    }
}

extension OrbVisualTests {
    func testVoiceEnvelopeMatchesExecutedSourceThroughRoomNoiseSpeechAndSyllableGaps() throws {
        for c in try fixtures()["envelopeCases"].array { var envelope=TutorVoiceEnvelope(microphone:c["microphone"].boolean);for step in c["steps"].array {XCTAssertEqual(envelope.sample(step["amplitude"].number,elapsedMs:step["elapsedMs"].number),step["value"].number,accuracy:1e-10)} }
    }
}
