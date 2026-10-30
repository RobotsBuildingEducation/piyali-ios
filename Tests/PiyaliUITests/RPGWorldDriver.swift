import XCTest

struct RPGPlayPoint:Codable,Hashable {let x:Int,y:Int}
struct RPGPlayFixture:Decodable {
        struct Step:Decodable {let npc:Int,mode:String,correct:Int,example:String}
        struct World:Decodable {struct Object:Decodable{let type:String,tx:Int,ty:Int};let width:Int,height:Int,tiles:[Int],solidTiles:[Int],objects:[Object]}
        let lessonID:String,world:World,npcs:[RPGPlayPoint],steps:[Step]
    }

@MainActor extension XCTestCase {
    private func position(_ world:XCUIElement)throws->RPGPlayPoint{let parts=(world.value as? String ?? "").split(separator:",").compactMap{Int($0)};XCTAssertEqual(parts.count,2);guard parts.count == 2 else{throw NSError(domain:"RPG position",code:1)};return RPGPlayPoint(x:parts[0],y:parts[1])}
    func rpgExamineCounterFromDistance(_ fixture:RPGPlayFixture,_ app:XCUIApplication)throws {
        let surface=app.otherElements["rpgWorld"],start=try position(surface),tile=surface.frame.height/10
        surface.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:surface.frame.width/2,dy:surface.frame.height/2-0.88*tile)).tap()
        let expected=RPGPlayPoint(x:start.x,y:start.y-1)
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","\(expected.x),\(expected.y)"),object:surface)],timeout:5),.completed)
        let target=try XCTUnwrap(fixture.world.objects.first{$0.type == "counter"}),now=try position(surface)
        XCTAssertGreaterThan(abs(target.tx-now.x)+abs(target.ty-now.y),1)
        surface.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:surface.frame.width/2+CGFloat(target.tx-now.x)*tile,dy:surface.frame.height/2+(CGFloat(target.ty-now.y)+0.12)*tile)).tap()
        let text=app.staticTexts["rpgObjectText"];XCTAssertTrue(text.waitForExistence(timeout:5));XCTAssertEqual(text.label,"You notice counter.");XCTAssertEqual(try position(surface),now)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native RPG ambient object examination";shot.lifetime = .keepAlways;add(shot)
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:text)],timeout:6),.completed)
        XCTAssertTrue(app.descendants(matching:.any)["rpgStatus"].label.contains("0/3"));XCTAssertFalse(app.buttons["rpgComplete"].exists)
    }
    func rpgApproach(_ step:RPGPlayFixture.Step,_ fixture:RPGPlayFixture,_ app:XCUIApplication)throws {
        let surface=app.otherElements["rpgWorld"],start=try position(surface),target=fixture.npcs[step.npc],occupied=Set(fixture.npcs),solid=Set(fixture.world.solidTiles)
        func adjacent(_ p:RPGPlayPoint)->Bool{abs(p.x-target.x)+abs(p.y-target.y)==1}
        var queue=[start],parents:[RPGPlayPoint:RPGPlayPoint]=[:],visited:Set<RPGPlayPoint>=[start],end:RPGPlayPoint?,cursor=0
        while cursor<queue.count{let p=queue[cursor];cursor+=1;if adjacent(p){end=p;break};for delta in [RPGPlayPoint(x:1,y:0),RPGPlayPoint(x:-1,y:0),RPGPlayPoint(x:0,y:1),RPGPlayPoint(x:0,y:-1)]{let n=RPGPlayPoint(x:p.x+delta.x,y:p.y+delta.y);if n.x>=0,n.y>=0,n.x<fixture.world.width,n.y<fixture.world.height,!solid.contains(fixture.world.tiles[n.y*fixture.world.width+n.x]),!occupied.contains(n),visited.insert(n).inserted{parents[n]=p;queue.append(n)}}}
        var route:[RPGPlayPoint]=[],next=try XCTUnwrap(end);while next != start{route.insert(next,at:0);next=try XCTUnwrap(parents[next])}
        func touch(_ point:RPGPlayPoint)throws{let p=try position(surface),frame=surface.frame,tile=frame.height/10;surface.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:frame.width/2+CGFloat(point.x-p.x)*tile,dy:frame.height/2+(CGFloat(point.y-p.y)+0.12)*tile)).tap()}
        for next in route{
            try touch(next);let wait=XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","\(next.x),\(next.y)"),object:surface),result=XCTWaiter.wait(for:[wait],timeout:5)
            if result != .completed{let shot=XCTAttachment(screenshot:app.screenshot());shot.name="RPG map movement timeout";shot.lifetime = .keepAlways;add(shot);let hierarchy=XCTAttachment(string:app.debugDescription);hierarchy.name="RPG movement timeout hierarchy";hierarchy.lifetime = .keepAlways;add(hierarchy)}
            XCTAssertEqual(result,.completed,"Expected \(next.x),\(next.y); actual \(surface.value as? String ?? "missing")")
        }
        try touch(target);XCTAssertTrue(app.buttons["rpgCloseDialogue"].waitForExistence(timeout:5))
    }
}
