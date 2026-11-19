import XCTest
@testable import PiyaliCore
final class RPGEnvironmentTests:XCTestCase {
 private var root:URL{URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
 func testOriginalMainProductFrameTracesAndAllBundledWorldPlans()throws{
  let library=try ContentLibrary.decode(RPGEnvironmentLibrary.self,url:root.appendingPathComponent("Piyali/Resources/rpg-environment.json.gz")),fixture=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/rpg-environment.json.gz"));XCTAssertEqual(library.lookup.count,443);XCTAssertEqual(library.plans.count,443);XCTAssertEqual(fixture["traces"].array.count,49)
  var samples=0
  for trace in fixture["traces"].array{let plan=try XCTUnwrap(library.plans[trace["key"].string]);for sample in trace["samples"].array{let states=sample["states"].array;XCTAssertEqual(states.count,plan.layers.count);for(index,layer)in plan.layers.enumerated(){let actual=layer.frame(at:sample["time"].number),expected=states[index];for(key,value)in[("x",actual.x),("y",actual.y),("scaleX",actual.scaleX),("scaleY",actual.scaleY),("rotation",actual.rotation),("alpha",actual.alpha)]{XCTAssertEqual(value,expected[key].number,accuracy:1e-9,"\(trace["key"].string) \(index) \(key)")}};samples += 1}}
  XCTAssertEqual(samples,245)
  for plan in library.plans.values{let motes=plan.layers.filter{$0.motion?.kind == "mote"};XCTAssertTrue((18...36).contains(motes.count));XCTAssertTrue(plan.layers.allSatisfy{$0.width>0 && $0.height>0});XCTAssertFalse(plan.grade.isEmpty)}
 }
 func testOriginalCompanionTickDiscardRemainderAndWalkOnlyPets()throws{
  let fixture=try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/rpg-environment.json.gz"));for trace in fixture["clocks"].array{var clock=RPGPetAnimationClock();let pet=trace["type"].string;for step in trace["steps"].array{let frame=clock.advance(milliseconds:step["delta"].number,pet:pet);XCTAssertEqual(clock.milliseconds,step["ms"].number,accuracy:1e-9);XCTAssertEqual(clock.frame,Int(step["frame"].number));XCTAssertEqual(frame.map{[$0]} ?? [],step["frames"].array.map{Int($0.number)})};clock.walk();XCTAssertEqual(clock.displayedFrame(pet:pet),RPGPetAnimationClock.ambientTypes.contains(pet) ? clock.frame:1);clock.changedCompanion();XCTAssertEqual(clock.displayedFrame(pet:pet),RPGPetAnimationClock.ambientTypes.contains(pet) ? clock.frame:0)}
 }
 func testCompleteLongCycleRetainsGhostFloatAndSlimeHopRatherThanRepeatingSixFrames()throws{
  let library=try ContentLibrary.decode(RPGEnvironmentLibrary.self,url:root.appendingPathComponent("Piyali/Resources/rpg-environment.json.gz"));for pet in CompanionTypes.ordered{for dir in ["up","down","left","right"]{let frames=library.frames(pet:pet,direction:dir);XCTAssertEqual(frames.count,RPGPetAnimationClock.ambientTypes.contains(pet) ? 3600:6);if ["ghost","slime","axolotl"].contains(pet){XCTAssertGreaterThan(Set(frames).count,1);XCTAssertTrue((0..<3594).contains{frames[$0] != frames[$0+6]})}}}
 }
 func testWalkingPetsReturnToStandingWithoutLosingTheirNextStep(){
  for pet in ["dog","alien"]{var clock=RPGPetAnimationClock();clock.walk();XCTAssertEqual(clock.displayedFrame(pet:pet),1);clock.advance(milliseconds:100,pet:pet);XCTAssertEqual(clock.displayedFrame(pet:pet),1);clock.advance(milliseconds:140,pet:pet);XCTAssertEqual(clock.displayedFrame(pet:pet),1);clock.advance(milliseconds:260,pet:pet);XCTAssertEqual(clock.displayedFrame(pet:pet),0);clock.walk();XCTAssertEqual(clock.displayedFrame(pet:pet),2)}
 }
}
