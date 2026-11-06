import XCTest
@testable import PiyaliCore

final class AchievementUnlockTests:XCTestCase {
 func testSessionQueueMatchesOriginalTracesAndCommittedRecordTransitions()throws{
  let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),data=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Piyali/Resources/achievement-transcript.json.gz")),fixture=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/achievement-delivery.json.gz")),ids=Set(data["items"]["en"].array.map{$0["id"].string});XCTAssertEqual(fixture["traces"].array.count,24)
  for trace in fixture["traces"].array{var state=AchievementUnlockState(catalog:ids);for step in trace.array{let op=step["operation"];switch op["type"].string{case "identity":state.setIdentity(op["identity"].string);case "language":state.setLanguage(op["language"].string);case "records":state.recordsChanged();case "enqueue":state.enqueue(identity:op["identity"].string,id:op["id"].string,test:op["test"].boolean,preview:op["preview"].boolean);case "dismiss":state.dismiss(op["first"].boolean ? state.current?.id ?? -1:Int(op["key"].number));default:XCTFail("Unknown source operation")};let expected=step["expected"];XCTAssertEqual(state.identity,expected["identity"].string);XCTAssertEqual(state.language,expected["language"].string);XCTAssertEqual(state.revision,Int(expected["revision"].number));XCTAssertEqual(state.queue.map{JSONValue.object(["id":.number(Double($0.id)),"achievementID":.string($0.achievementID),"test":.bool($0.test),"preview":.bool($0.preview)])},expected["queue"].array)}}
  for row in fixture["deltas"].array{XCTAssertEqual(AchievementUnlockState.notifiable(before:row["before"],after:row["after"],order:row["order"].array.map(\.string),catalog:ids,notify:row["notify"].boolean),row["expected"].array.map(\.string))}
 }
}
