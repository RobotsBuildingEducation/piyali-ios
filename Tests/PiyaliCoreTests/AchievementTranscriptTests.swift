import XCTest
@testable import PiyaliCore

final class AchievementTranscriptTests:XCTestCase {
 private var root:URL{URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
 func testSourcePartitionAndSeriesOrderForBothHostsAndEveryLocale()throws{
  let data=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Piyali/Resources/achievement-transcript.json.gz")),transcript=AchievementTranscript(data:data),fixtures=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/achievement-transcript.json.gz"))
  XCTAssertEqual(data["items"]["en"].array.count,104);XCTAssertEqual(transcript.items(language:"en",host:"nosabos").count,76);XCTAssertEqual(transcript.items(language:"ar",host:"robotsbuildingeducation").count,29)
  for language in data["items"].object.keys{for fixture in fixtures["fixtures"].array{let sections=transcript.sections(language:language,host:fixture["host"].string,unlocked:fixture["unlocked"]);XCTAssertEqual(sections.count,2);for(section,expected)in zip(sections,fixture["sections"].array){XCTAssertEqual(section["status"],expected["status"]);XCTAssertEqual(section["count"],expected["count"]);XCTAssertEqual(section["items"].array.map{$0["id"]},expected["ids"].array)}}}
  XCTAssertEqual(transcript.number(76,language:"ar"),"٧٦");XCTAssertEqual(transcript.text("collectionLabel",language:"en",values:["count":"3","total":"76"]),"3 of 76 collected")
 }
 func testAllOriginalCharacterReactionsMatchSourceAndKeepTheirDistinctPoses()throws{
  let fixtures=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/achievement-transcript.json.gz")),policy=try AchievementOrbPolicy(source:String(contentsOf:root.appendingPathComponent("Piyali/Resources/achievement-orb-policy.js")));XCTAssertEqual(fixtures["poses"].array.count,504)
  for row in fixtures["voiceCases"].array{XCTAssertEqual(policy.voiceLevel(row["time"].number),row["expected"].number,accuracy:1e-12)}
  for p in fixtures["poses"].array{let actual=try policy.pose(kind:p["kind"].string,elapsed:p["elapsed"].number,amount:p["amount"].number);for(key,value)in p["expected"].object{XCTAssertEqual(actual[key].number,value.number,accuracy:1e-12,p["kind"].string+":"+key)}}
 }
}
