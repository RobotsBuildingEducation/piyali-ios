import Foundation

public struct ExplorationMap:Codable,Equatable,Sendable {
    public let id:String
    public let name:JSONValue?
    public let world:RPGWorld
    public let portals:[JSONValue]
    public var worldKey:String?
}
public struct ExplorationTemplate:Codable,Equatable,Sendable {
    public let id:String
    public let theme:String
    public let level:String
    public var baseLanguage:String
    public var name:JSONValue
    public let startMapId:String
    public var maps:[ExplorationMap]
    public var npcs:[JSONValue]
    public var quest:JSONValue
    public var gatherPlacements:[JSONValue]
    public func map(_ id:String) -> ExplorationMap? { maps.first { $0.id == id } }
    public func searchingObjects() throws -> Self {
        var result=self,steps=quest["steps"].array
        guard let index=steps.firstIndex(where:{ $0["nodes"].array.contains { $0["responseMode"].string == "gather" } }) else { throw ExplorationFailure.invalidScenario }
        var nodes=steps[index]["nodes"].array
        guard let nodeIndex=nodes.firstIndex(where:{ $0["responseMode"].string == "gather" }) else { throw ExplorationFailure.invalidScenario }
        let correct=quest["gatherData"]["correct"].array;guard !correct.isEmpty else { throw ExplorationFailure.invalidScenario }
        let requested=correct[index % correct.count],prior=nodes[nodeIndex]["gatherItem"]["name"].string
        nodes=nodes.map { ExplorationText.transform($0) { $0.replacingOccurrences(of:prior,with:requested["name"].string) } }
        nodes[nodeIndex]=nodes[nodeIndex].setting("responseMode",.string("objectSearch")).setting("gatherItem",requested)
        steps[index]=steps[index].setting("nodes",.array(nodes));result.quest=quest.setting("steps",.array(steps));return try result.validated()
    }
    public func validated() throws -> Self {
        guard (1...8).contains(maps.count),Set(maps.map(\.id)).count == maps.count,map(startMapId) != nil,(1...8).contains(npcs.count),(1...12).contains(quest["steps"].array.count),quest.json.utf8.count < 100_000 else { throw ExplorationFailure.invalidScenario }
        for area in maps {
            let world=area.world
            guard (6...64).contains(world.width),(6...64).contains(world.height),world.tiles.count == world.width*world.height,world.walkable(world.start),area.portals.count <= 8,world.objects.count <= 64 else { throw ExplorationFailure.invalidScenario }
            for portal in area.portals {
                guard let target=map(portal["toMapId"].string),target.world.walkable(Self.point(portal["spawn"])),world.path(from:world.start,to:Self.position(portal)) != nil else { throw ExplorationFailure.invalidScenario }
            }
        }
        for npc in npcs { guard let area=map(npc["mapId"].string),!npc["name"].string.isEmpty,area.world.path(from:area.world.start,to:Self.position(npc)) != nil else { throw ExplorationFailure.invalidScenario } }
        for step in quest["steps"].array {
            let nodes=step["nodes"].array,ids=Set(nodes.map { $0["id"].string })
            guard npcs.indices.contains(Self.integer(step["npcIdx"])),(1...16).contains(nodes.count),ids.count == nodes.count,!ids.contains("") else { throw ExplorationFailure.invalidScenario }
            var reachesEnd=Set(nodes.filter { $0["terminal"].boolean }.map { $0["id"].string })
            for node in nodes {
                guard ["choice","speech","gather","objectSearch","none"].contains(node["responseMode"].string) else { throw ExplorationFailure.invalidScenario }
                let next=Self.links(node)
                guard node["terminal"].boolean || !next.isEmpty && next.allSatisfy({ ids.contains($0) }),node["responseMode"].string != "choice" || (1...8).contains(node["choices"].array.count) else { throw ExplorationFailure.invalidScenario }
            }
            for _ in nodes.indices { for node in nodes where !reachesEnd.contains(node["id"].string) { let next=Self.links(node);if !next.isEmpty,next.allSatisfy({ reachesEnd.contains($0) }) { reachesEnd.insert(node["id"].string) } } }
            guard reachesEnd.count == nodes.count else { throw ExplorationFailure.invalidScenario }
        }
        let items=quest["gatherData"]["all"].array
        guard items.count <= 64,Set(items.map { $0["name"].string }).count == items.count,gatherPlacements.count <= 64 else { throw ExplorationFailure.invalidScenario }
        for item in gatherPlacements { guard let area=map(item["mapId"].string),items.contains(where:{ $0["name"] == item["name"] }),area.world.path(from:area.world.start,to:Self.position(item)) != nil else { throw ExplorationFailure.invalidScenario } }
        return self
    }
    public static func integer(_ value:JSONValue) -> Int { let n=value.number;return n.isFinite && abs(n) <= 100_000 && n.rounded(.down) == n ? Int(n) : -100_000 }
    public static func point(_ value:JSONValue) -> RPGPoint { RPGPoint(x:integer(value["x"]),y:integer(value["y"])) }
    public static func position(_ value:JSONValue) -> RPGPoint { RPGPoint(x:integer(value["tx"]),y:integer(value["ty"])) }
    public static func links(_ node:JSONValue) -> [String] {
        if node["terminal"].boolean { return [] }
        return node["responseMode"].string == "choice" ? node["choices"].array.map { $0["nextNodeId"].string } : [node["nextNodeId"].string]
    }
}
public enum ExplorationFailure:LocalizedError { case invalidScenario,invalidQuest,unavailable
    public var errorDescription:String? { switch self { case .invalidScenario:"The exploration world has an invalid or unreachable quest. Try another world.";case .invalidQuest:"The generated quest changed its paths or items. The saved adventure was preserved.";case .unavailable:"This action is not available at your current location." } }
}
public struct ExplorationLibrary:Codable,Sendable { public let templates:[ExplorationTemplate];public let objectCopy:JSONValue? }
public enum ExplorationObjects {
    public static func note(type:String,target:String,support:String,copy:JSONValue) -> JSONValue {
        let words=type.replacingOccurrences(of:"([a-z])([A-Z])",with:"$1 $2",options:.regularExpression).replacingOccurrences(of:"[_-]+",with:" ",options:.regularExpression).lowercased()
        func label(_ lang:String) -> String { let value=copy["labels"][lang][type].string;return value.isEmpty ? copy["labels"]["en"][type].string.isEmpty ? words : copy["labels"]["en"][type].string : value }
        func sentence(_ lang:String) -> String { let format=copy["sentences"][lang].string;return (format.isEmpty ? "You notice {{object}}." : format).replacingOccurrences(of:"{{object}}",with:label(lang)) }
        return .object(["name":.string(label(target)),"description":.string(sentence(target)),"translation":.string(sentence(support))])
    }
}
public struct ExplorationItem:Codable,Equatable,Identifiable,Sendable {
    public let id:String
    public var item:JSONValue
    public let source:String
    public let stepKey:String?
}
public struct ExplorationRun:Codable,Equatable,Identifiable,Sendable {
    public var id=UUID()
    public let target:String
    public let support:String
    public var scenario:ExplorationTemplate
    public var mapID:String
    public var position:RPGPoint
    public var stepIndex=0
    public var nodeID:String?
    public var talking=false
    public var inventory:[ExplorationItem]=[]
    public var collected=Set<String>()
    public var drops:[String:JSONValue]=[:]
    public var searched=Set<String>()
    public var searchStarted:String?
    public var dialogue:[String]=[]
    public var pendingTurnIn:Bool?
    public var feedback=""
    public var tip:String?
    public var objectNotes:[String:JSONValue]?
    public var updatedAt=Date()
    public init(target:String,support:String,scenario:ExplorationTemplate) throws {
        self.scenario=try scenario.validated();self.target=target;self.support=support;mapID=scenario.startMapId
        guard let area=scenario.map(mapID) else { throw ExplorationFailure.invalidScenario };position=area.world.start
    }
    public var area:ExplorationMap? { scenario.map(mapID) }
    public var completed:Bool { stepIndex >= scenario.quest["steps"].array.count }
    public var step:JSONValue { scenario.quest["steps"].array.indices.contains(stepIndex) ? scenario.quest["steps"].array[stepIndex] : .null }
    public var node:JSONValue { step["nodes"].array.first { $0["id"].string == nodeID } ?? step["nodes"].array.first ?? .null }
    public var npc:JSONValue { let i=ExplorationTemplate.integer(step["npcIdx"]);return !completed && scenario.npcs.indices.contains(i) ? scenario.npcs[i] : .null }
    public var mode:String { node["responseMode"].string }
    public var searchKey:String { scenario.id+":object-search:"+String(stepIndex) }
    public var gatherUnlocked:Bool { !completed && mode == "gather" }
    public var requestedItem:JSONValue {
        guard mode == "objectSearch" else { return node["gatherItem"] }
        let correct=scenario.quest["gatherData"]["correct"].array;return correct.isEmpty ? scenario.quest["gatherData"]["all"].array.first ?? .null : correct[stepIndex % correct.count]
    }
    public func nearby(_ point:RPGPoint) -> Bool { abs(position.x-point.x)+abs(position.y-point.y) <= 1 }
    private mutating func log(_ text:String) { if !text.isEmpty { dialogue.append(String(text.prefix(1500)));dialogue=Array(dialogue.suffix(24)) };updatedAt=Date() }
    public mutating func move(dx:Int,dy:Int) -> Bool {
        guard abs(dx)+abs(dy) == 1,let area else { return false };let next=RPGPoint(x:position.x+dx,y:position.y+dy)
        guard area.world.walkable(next),!scenario.npcs.contains(where:{ $0["mapId"].string == mapID && Self.npcPosition($0) == next }) else { return false }
        position=next;talking=false;updatedAt=Date()
        if let index=area.portals.firstIndex(where:{ ExplorationTemplate.position($0) == next }) { _=enter(index) }
        if gatherUnlocked { for index in scenario.gatherPlacements.indices where placement(index)["mapId"].string == mapID && ExplorationTemplate.position(placement(index)) == position { _=pickUp(index) } }
        return true
    }
    private static func npcPosition(_ npc:JSONValue)->RPGPoint { ExplorationTemplate.position(npc) }
    /// Canvas taps follow the source primary-axis/secondary-axis one-step movement.
    /// Object examination is returned to the presentation layer and never moves the player.
    public mutating func tap(_ point:RPGPoint)->Int? {
        guard pendingTurnIn != true,!completed,!talking,let area else { return nil }
        if let object=area.world.objects.firstIndex(where:{ $0.tx == point.x && $0.ty == point.y }) { return object }
        if let index=scenario.npcs.firstIndex(where:{ $0["mapId"].string == mapID && Self.npcPosition($0) == point }) {
            guard index == ExplorationTemplate.integer(step["npcIdx"]) else { return nil }
            if nearby(point) { _=talk();return nil }
        }
        let dx=point.x-position.x,dy=point.y-position.y
        let horizontal=(dx.signum(),0),vertical=(0,dy.signum())
        let candidates=abs(dx)>=abs(dy) ? [horizontal,vertical]:[vertical,horizontal]
        for (x,y) in candidates where x != 0 || y != 0 { if move(dx:x,dy:y) { break } }
        return nil
    }
    public mutating func approach(_ point:RPGPoint) -> Bool {
        guard let path=area?.world.path(from:position,to:point),let end=path.last else { return false };position=end;talking=false;updatedAt=Date();return true
    }
    public mutating func enter(_ index:Int) -> Bool {
        guard let area,area.portals.indices.contains(index) else { return false };let portal=area.portals[index]
        guard nearby(ExplorationTemplate.position(portal)),let destination=scenario.map(portal["toMapId"].string) else { return false }
        mapID=destination.id;position=ExplorationTemplate.point(portal["spawn"]);talking=false;updatedAt=Date();return true
    }
    public mutating func talk() -> Bool {
        guard !completed,npc["mapId"].string == mapID,nearby(ExplorationTemplate.position(npc)) else { return false }
        talking=true;feedback="";tip=nil;if mode == "objectSearch" { searchStarted=searchKey };log(node["npcLine"].string);return true
    }
    private mutating func next(_ id:String) {
        if step["nodes"].array.contains(where:{ $0["id"].string == id }) { nodeID=id;if mode == "objectSearch" { searchStarted=searchKey } }
        else { finishStep() };updatedAt=Date()
    }
    public mutating func finishStep() {
        guard (talking || pendingTurnIn == true),!completed else { return }
        let finishedSearch=mode == "objectSearch" ? searchKey:nil
        if let finishedSearch { inventory.removeAll { $0.stepKey == finishedSearch };searched=searched.filter { !$0.hasPrefix(finishedSearch+":") } }
        pendingTurnIn=nil;stepIndex += 1;nodeID=nil;talking=false;searchStarted=nil;feedback="";updatedAt=Date()
    }
    public mutating func choose(_ index:Int) -> Bool {
        guard talking,mode == "choice",node["choices"].array.indices.contains(index) else { return false };let choice=node["choices"].array[index]
        log(choice["text"].string);log(choice["npcReply"].string);feedback=choice["npcReply"].string;next(choice["nextNodeId"].string);appendNextInstruction();return true
    }
    public mutating func speak(_ answer:String,reply:String) -> Bool {
        guard talking,mode == "speech",!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return false }
        log(answer);log(reply);feedback=reply;next(node["nextNodeId"].string);appendNextInstruction();return true
    }
    private mutating func appendNextInstruction(){if talking,mode != "speech",!feedback.isEmpty,!node["npcLine"].string.isEmpty{feedback += "\n\n"+node["npcLine"].string}}
    public mutating func continueDialogue() -> Bool {
        guard talking,mode == "none" else { return false };if node["terminal"].boolean { finishStep() } else { next(node["nextNodeId"].string) };return true
    }
    public func placementKey(_ index:Int) -> String { "gather:"+String(index) }
    public func placement(_ index:Int) -> JSONValue { guard scenario.gatherPlacements.indices.contains(index) else { return .null };return drops[placementKey(index)] ?? scenario.gatherPlacements[index] }
    public mutating func pickUp(_ index:Int) -> Bool {
        let item=placement(index),key=placementKey(index)
        guard gatherUnlocked,inventory.count < 64,!collected.contains(key),item["mapId"].string == mapID,nearby(ExplorationTemplate.position(item)) else { return false }
        inventory.append(ExplorationItem(id:key,item:item,source:"gather",stepKey:nil));collected.insert(key);updatedAt=Date();return true
    }
    public static func objectKey(mapID:String,object:RPGObject) -> String { mapID+":\(object.tx),\(object.ty):"+object.type }
    /// This rotation and target selection follow currentObjectSearchQuest in the reference client.
    public var objectAssignments:[String:JSONValue] {
        guard mode == "objectSearch",requestedItem != .null else { return [:] };let items=scenario.quest["gatherData"]["all"].array,target=requestedItem
        var objects:[(map:String,object:RPGObject)]=[]
        for area in scenario.maps { for object in area.world.objects { objects.append((area.id,object)) } }
        objects.sort { a,b in
            if a.map != b.map { return a.map < b.map }
            if a.object.ty != b.object.ty { return a.object.ty < b.object.ty }
            if a.object.tx != b.object.tx { return a.object.tx < b.object.tx }
            return a.object.type < b.object.type
        }
        guard !objects.isEmpty else { return [:] };let seed=searchKey.utf16.reduce(0) { $0+Int($1) },winner=seed % objects.count,decoys=items.filter { $0["name"] != target["name"] }
        var result:[String:JSONValue]=[:]
        for (i,value) in objects.enumerated() {
            let key=Self.objectKey(mapID:value.map,object:value.object),decoyIndex=i < winner ? i : i-1
            let item:JSONValue=i == winner ? target : decoys.isEmpty ? target.setting("name",.string("?")) : decoys[(decoyIndex+seed%decoys.count)%decoys.count]
            result[key]=item.setting("isCorrect",.bool(i == winner))
        };return result
    }
    public mutating func examine(_ index:Int) -> Bool {
        guard searchStarted == searchKey,mode == "objectSearch",inventory.count < 64,let area,area.world.objects.indices.contains(index) else { return false }
        let object=area.world.objects[index],key=Self.objectKey(mapID:mapID,object:object),searchID=searchKey+":"+key
        guard !searched.contains(searchID),let item=objectAssignments[key] else { return false }
        inventory.append(ExplorationItem(id:searchID,item:item,source:key,stepKey:searchKey));searched.insert(searchID);updatedAt=Date();return true
    }
    public mutating func drop(_ index:Int) -> Bool {
        guard inventory.indices.contains(index),let area else { return false };let item=inventory.remove(at:index)
        if item.source == "gather" {
            collected.remove(item.id)
            let candidates=[RPGPoint(x:position.x+1,y:position.y),RPGPoint(x:position.x-1,y:position.y),RPGPoint(x:position.x,y:position.y+1),RPGPoint(x:position.x,y:position.y-1)]
            let point=candidates.first(where:{ area.world.walkable($0) }) ?? position
            drops[item.id]=item.item.setting("mapId",.string(mapID)).setting("tx",.number(Double(point.x))).setting("ty",.number(Double(point.y)))
        } else { searched.remove(item.id) };updatedAt=Date();return true
    }
    public mutating func completeTurnIn(){guard pendingTurnIn == true else{return};finishStep()}
    public mutating func handIn(_ index:Int,successReply:String?=nil) -> Bool {
        guard pendingTurnIn != true,talking,["gather","objectSearch"].contains(mode),inventory.indices.contains(index) else { return false };let item=inventory[index]
        let valid=item.item["isCorrect"].boolean && (mode == "objectSearch" ? item.stepKey == searchKey : item.item["name"] == node["gatherItem"]["name"])
        guard valid else { feedback=node["gatherWrongItemTemplate"].string.replacingOccurrences(of:"{{wrongItem}}",with:item.item["name"].string).replacingOccurrences(of:"{{correctItem}}",with:node["gatherItem"]["name"].string);if item.source == "gather" { _=drop(index) };return false }
        inventory.remove(at:index)
        if mode == "objectSearch" {if let successReply{feedback=successReply;pendingTurnIn=true;updatedAt=Date()}else{finishStep()}} else { feedback="";next(node["nextNodeId"].string) };return true
    }
}
public extension LearnerState {
    mutating func saveExploration(_ run:ExplorationRun) {
        if explorationRuns == nil { explorationRuns=[:] };explorationRuns?[run.target]=run
        for key in (explorationRuns ?? [:]).sorted(by:{ $0.value.updatedAt > $1.value.updatedAt }).dropFirst(2).map(\.key) { explorationRuns?.removeValue(forKey:key) }
    }
}
