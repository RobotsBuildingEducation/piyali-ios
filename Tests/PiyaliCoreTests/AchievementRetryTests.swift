import XCTest
@testable import PiyaliCore
final class AchievementRetryTests:XCTestCase {
    func testOriginalWorkerPublicIntentTimersAndGenerationTraces()throws{
        let rows=try JSONDecoder().decode([[JSONValue]].self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/achievement-retry.json")))
        XCTAssertEqual(rows.count,10)
        for trace in rows{var state=AchievementRetry(),timer:Int?,sent:Int?,starts=0
            for row in trace{let action=row["action"].string
                switch action{
                case "schedule":if let delay=state.schedule(){timer=delay}
                case "resume":if let delay=state.resume(){timer=delay}
                case "pause":state.pause();timer=nil
                case "fire":if timer != nil{timer=nil;if let generation=state.begin(){sent=generation;starts += 1}}
                case "success","failure":if let generation=sent{sent=nil;if let delay=state.finish(sent:generation,failed:action=="failure"){timer=delay}}
                default:XCTFail(action)
                }
                XCTAssertEqual(state.pending,row["pending"].boolean,row.json);XCTAssertEqual(starts,Int(row["starts"].number),row.json);XCTAssertEqual(state.running,row["running"].boolean,row.json);XCTAssertEqual(timer.map{[$0]} ?? [],row["delays"].array.map{Int($0.number)},row.json)
            }
        }
    }
}
