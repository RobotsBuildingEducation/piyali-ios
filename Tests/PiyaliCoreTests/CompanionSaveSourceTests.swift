import XCTest
@testable import PiyaliCore
final class CompanionSaveSourceTests:XCTestCase {
 func testOriginalCallbacksKeepOptimisticUpdatesAndOnlyReportActualWriteFailures()throws{
  let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),fixture=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/companion-save.json.gz"));XCTAssertEqual(fixture["rows"].array.count,120);XCTAssertEqual(fixture["duration"].number,5000)
  for row in fixture["rows"].array{let input=row["input"],payload=input["payload"],name=payload.object.isEmpty ? payload.string:payload["name"].string,type=payload.object.isEmpty ? input["fallback"].string:payload["petType"].string,partial=CompanionCustomization.partial(name:name,type:type,level:Int(input["level"].number)),events=row["events"].array;XCTAssertEqual(events.first?["action"].string,"patch");XCTAssertEqual(events.first?["value"],partial)
   if row["outcome"].string == "anonymous"{XCTAssertEqual(events.count,1)}else{XCTAssertEqual(events[1]["action"].string,"write");XCTAssertEqual(events[1]["value"]["dailyGoalPetName"],partial["dailyGoalPetName"]);XCTAssertEqual(events[1]["value"]["dailyGoalPetType"],partial["dailyGoalPetType"]);XCTAssertEqual(events[1]["value"]["updatedAt"].string,"2026-10-26T12:00:00.000Z");XCTAssertEqual(events[1]["options"]["merge"],.bool(true));if row["outcome"].string == "failure"{XCTAssertEqual(events.count,3);XCTAssertEqual(events[2]["action"].string,"toast");XCTAssertEqual(events[2]["value"]["status"].string,"error");XCTAssertFalse(events[2]["value"]["title"].string.isEmpty);XCTAssertEqual(events[2]["value"]["description"].string,"Cloud permission denied.")}else{XCTAssertEqual(events.count,2)}}
  }
 }
}
