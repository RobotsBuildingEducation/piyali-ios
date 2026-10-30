import XCTest
@testable import PiyaliCore
final class RPGSpatialTests:XCTestCase {
    func testOriginalSingleTapCollisionAndLessonSpawnCases()throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/rpg-spatial.json.gz"),rows=try ContentLibrary.decode([JSONValue].self,url:url)
        XCTAssertGreaterThan(rows.count,1000)
        for row in rows{let p=row["input"],world=try JSONDecoder().decode(RPGWorld.self,from:JSONEncoder().encode(p["world"])),npcs=try JSONDecoder().decode([RPGNPC].self,from:JSONEncoder().encode(p["npcs"])),expected=row["expected"]
            if row["operation"].string == "spawn"{XCTAssertEqual(RPGSpatial.start(world:world,npcs:npcs,center:p["center"].boolean),RPGPoint(x:Int(expected["x"].number),y:Int(expected["y"].number)))}else{let move=RPGSpatial.step(from:.init(x:Int(p["position"]["x"].number),y:Int(p["position"]["y"].number)),toward:.init(x:Int(p["target"]["x"].number),y:Int(p["target"]["y"].number)),world:world,npcs:npcs);XCTAssertEqual(move.position,RPGPoint(x:Int(expected["x"].number),y:Int(expected["y"].number)));XCTAssertEqual(move.moved,expected["moved"].boolean);XCTAssertEqual(move.direction,expected["direction"].string)}
        }
    }
}
