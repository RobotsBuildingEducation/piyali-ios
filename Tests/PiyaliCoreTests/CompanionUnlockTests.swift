import XCTest
@testable import PiyaliCore
final class CompanionUnlockTests:XCTestCase {
 func testQueueAndQuietTimingMatchActualSourceTimersAndLateHydration()throws{
  let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),f=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/companion-unlocks.json.gz"));XCTAssertEqual(f["traces"].array.count,12)
  for trace in f["traces"].array{var state=CompanionUnlockState();state.bind("public-alice");let names:JSONValue = .object(["alien":.string("Alien"),"robot":.string("Robot")]);state.enqueue(types:["alien","robot"],level:5,names:names,celebrated:[],expectsModal:trace["expectsModal"].boolean);state.enqueue(types:["alien"],level:5,names:names,celebrated:[],expectsModal:false);XCTAssertEqual(state.pending.map(\.type),["alien","robot"])
   let scenario=trace["scenario"],until=scenario["until"].number;var shown:[JSONValue]=[]
   _=state.poll(now:0,blocked:["dom","dailyGoal","pendingLesson"].contains(scenario["name"].string)&&0<until,celebrated:[])
   for status in trace["statuses"].array{let now=status["at"].number,blocked=["dom","dailyGoal","pendingLesson"].contains(scenario["name"].string)&&now<until,seen:Set<String>=scenario["lateSeen"].boolean&&now>=200 ? ["alien"]:[];if let item=state.poll(now:now,blocked:blocked,celebrated:seen){shown.append(.object(["at":.number(now),"type":.string(item.type)]))};XCTAssertEqual(state.visible?.type,status["visible"].string.isEmpty ? nil:status["visible"].string)}
   XCTAssertEqual(shown,trace["shown"].array.map{.object(["at":$0["at"],"type":$0["type"]])})
  }
 }
 func testLevelCrossingAccountFenceFIFOAndSeenGuard(){
  XCTAssertEqual(CompanionUnlockState.newlyUnlocked(previous:1,next:40),["alien","robot","slime","dog","axolotl"]);XCTAssertEqual(CompanionUnlockState.newlyUnlocked(previous:40,next:1),[])
  var state=CompanionUnlockState();state.bind("alice");state.enqueue(types:["ALIEN","robot"],level:5,names:.object([:]),celebrated:[],expectsModal:false);_=state.poll(now:0,blocked:false,celebrated:[]);let first=state.poll(now:160,blocked:false,celebrated:[])!;state.dismiss(first);_=state.poll(now:200,blocked:false,celebrated:[]);XCTAssertEqual(state.poll(now:360,blocked:false,celebrated:[])?.type,"robot");state.bind("bob");XCTAssertNil(state.visible);XCTAssertTrue(state.pending.isEmpty);state.dismiss(first);XCTAssertEqual(state.account,"bob")
 }
 func testCelebratedFlagsMergeWithoutClearingOtherDevicesOrForeignValues()throws{
  let original:JSONValue = .object(["companionUnlocksCelebrated":.object(["alien":.bool(true),"futureCompanion":.string("preserve")]),"progress":.object(["tutorVoice":.string("Kore")])])
  let change=SettingsChange(partial:.object(["companionUnlocksCelebrated":.object(["robot":.bool(true),"alien":.bool(false),"slime":.number(1),"bogus":.bool(true)])]))
  let applied=LearnerSettings.applying(change,to:original)
  XCTAssertEqual(applied["companionUnlocksCelebrated"],.object(["alien":.bool(true),"futureCompanion":.string("preserve"),"robot":.bool(true),"slime":.bool(true)]));XCTAssertEqual(applied["progress"],original["progress"])
  let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent();let policy=try SettingsSourcePolicy(url:root.appendingPathComponent("Piyali/Resources/settings-policy.js"));XCTAssertEqual(try LearnerSettings.patch(change,fields:original,policy:policy),.object(["companionUnlocksCelebrated":.object(["robot":.bool(true),"slime":.bool(true)])]))
  for flags:JSONValue in [.object([:]),.object(["alien":.bool(false),"bogus":.bool(true)])]{XCTAssertEqual(try LearnerSettings.patch(.init(partial:.object(["companionUnlocksCelebrated":flags])),fields:original,policy:policy),.object([:]))}
 }

}
