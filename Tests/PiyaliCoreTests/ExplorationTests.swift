import XCTest
@testable import PiyaliCore

final class ExplorationTests:XCTestCase {
    private var root:URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    private func sample() throws -> ExplorationTemplate { try JSONDecoder().decode(ExplorationTemplate.self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/exploration.json"))) }
    private func travel(_ run:inout ExplorationRun,to target:String) throws {
        for _ in 0..<8 where run.mapID != target {
            let area=try XCTUnwrap(run.area),direct=area.portals.firstIndex { $0["toMapId"].string == target }
            let index=try XCTUnwrap(direct ?? area.portals.firstIndex { $0["toMapId"].string == run.scenario.startMapId })
            XCTAssertTrue(run.approach(ExplorationTemplate.position(area.portals[index])));XCTAssertTrue(run.enter(index))
        };XCTAssertEqual(run.mapID,target)
    }
    private func talk(_ run:inout ExplorationRun) throws { try travel(&run,to:run.npc["mapId"].string);XCTAssertTrue(run.approach(ExplorationTemplate.position(run.npc)));XCTAssertTrue(run.talk()) }
    func testEverySourceTemplateHasReachableRoomsNPCsAndQuestPaths() throws {
        let library=try ContentLibrary.decode(ExplorationLibrary.self,url:root.appendingPathComponent("Piyali/Resources/exploration.json.gz"))
        XCTAssertEqual(library.templates.count,224);XCTAssertEqual(Set(library.templates.map(\.theme)).count,8)
        for template in library.templates {
            _=try template.validated();XCTAssertEqual(template.maps.count,4)
            if let step=template.quest["steps"].array.firstIndex(where:{ $0["nodes"].array.contains { $0["responseMode"].string == "gather" } }) {
                var search=try ExplorationRun(target:template.baseLanguage,support:"en",scenario:template.searchingObjects());search.stepIndex=step;search.nodeID=search.step["nodes"].array.first { $0["responseMode"].string == "objectSearch" }?["id"].string
                let key=try XCTUnwrap(search.objectAssignments.first { $0.value["isCorrect"].boolean }?.key)
                let area=try XCTUnwrap(template.maps.first { map in map.world.objects.contains { ExplorationRun.objectKey(mapID:map.id,object:$0) == key } }),object=try XCTUnwrap(area.world.objects.first { ExplorationRun.objectKey(mapID:area.id,object:$0) == key })
                try talk(&search);try travel(&search,to:area.id)
                let index=try XCTUnwrap(area.world.objects.firstIndex(of:object));XCTAssertTrue(search.examine(index),"Unsearchable item: "+template.theme+"/"+template.level+"/"+key)
            }
        }
        for lang in ["es","en"] { for level in LearningLanguages.levels { for theme in Set(library.templates.map(\.theme)) {
            let variants=library.templates.filter { $0.baseLanguage == lang && $0.level == level && $0.theme == theme }
            XCTAssertEqual(variants.count,2);XCTAssertEqual(variants.filter { $0.quest["steps"].array.contains { $0["nodes"].array.contains { $0["responseMode"].string == "gather" } } }.count,1)
        } } }
    }
    func testWholeQuestInventoryWrongItemDropPortalsAndMidQuestRestoration() throws {
        var run=try ExplorationRun(target:"es",support:"en",scenario:sample()),usedInventory=false,wrongItem=false,iterations=0
        while !run.completed,iterations < 100 {
            iterations += 1;try talk(&run)
            switch run.mode {
            case "choice":XCTAssertTrue(run.choose(0))
            case "speech":XCTAssertTrue(run.speak("Estoy listo.",reply:run.node["speechContinueReply"].string))
            case "none":XCTAssertTrue(run.continueDialogue())
            case "gather":
                if !wrongItem {
                    let bad=try XCTUnwrap(run.scenario.gatherPlacements.firstIndex { !$0["isCorrect"].boolean })
                    let placement=run.placement(bad);try travel(&run,to:placement["mapId"].string);XCTAssertTrue(run.approach(ExplorationTemplate.position(placement)));XCTAssertTrue(run.pickUp(bad))
                    try talk(&run);let count=run.inventory.count;XCTAssertFalse(run.handIn(0));XCTAssertEqual(run.inventory.count,count-1);XCTAssertFalse(run.collected.contains(run.placementKey(bad)));wrongItem=true
                }
                let name=run.node["gatherItem"]["name"],index=try XCTUnwrap(run.scenario.gatherPlacements.firstIndex { $0["name"] == name }),item=run.placement(index)
                try travel(&run,to:item["mapId"].string);XCTAssertTrue(run.approach(ExplorationTemplate.position(item)));XCTAssertTrue(run.pickUp(index))
                run=try JSONDecoder().decode(ExplorationRun.self,from:JSONEncoder().encode(run));XCTAssertEqual(run.inventory.first?.item["name"],name)
                try talk(&run);XCTAssertTrue(run.handIn(0));usedInventory=true
            default:XCTFail("Unplayable quest mode");return
            }
        }
        XCTAssertTrue(run.completed);XCTAssertTrue(usedInventory);XCTAssertTrue(wrongItem)
        var learner=LearnerState();let xp=learner.totalXP;learner.saveExploration(run);XCTAssertEqual(learner.totalXP,xp);XCTAssertTrue(learner.pendingChanges?.isEmpty ?? true)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(learner));XCTAssertEqual(restored.explorationRuns?["es"],run)
    }
    func testCanvasMovementAndAutomaticRoomEntryMatchActualSourceClosure()throws {
        struct Case:Decodable {struct Expected:Decodable{let moved:Bool;let mapID:String;let position:RPGPoint};let template:Int;let mapID:String;let from:RPGPoint;let target:RPGPoint;let expected:Expected}
        struct Fixture:Decodable{let cases:[Case]}
        let library=try ContentLibrary.decode(ExplorationLibrary.self,url:root.appendingPathComponent("Piyali/Resources/exploration.json.gz")),fixture=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/exploration-controls.json")))
        XCTAssertGreaterThan(fixture.cases.count,2000)
        for (index,entry) in fixture.cases.enumerated(){var run=try ExplorationRun(target:library.templates[entry.template].baseLanguage,support:"en",scenario:library.templates[entry.template]);run.mapID=entry.mapID;run.position=entry.from;XCTAssertNil(run.tap(entry.target),"Unexpected object hit \(index)");XCTAssertEqual(run.mapID,entry.expected.mapID,"Source room case \(index)");XCTAssertEqual(run.position,entry.expected.position,"Source position case \(index)")}
    }
    func testDistantSearchInventoryDropAndDurableSuccessKeepOnlyCurrentQuestOwnership()throws {
        var run=try ExplorationRun(target:"es",support:"ar",scenario:sample().searchingObjects());run.stepIndex=try XCTUnwrap(run.scenario.quest["steps"].array.firstIndex{$0["nodes"].array.contains{$0["responseMode"].string == "objectSearch"}});run.nodeID=try XCTUnwrap(run.step["nodes"].array.first{$0["responseMode"].string == "objectSearch"})["id"].string
        let assignments=run.objectAssignments
        func find(_ correct:Bool)throws->(ExplorationMap,Int){let key=try XCTUnwrap(assignments.first{$0.value["isCorrect"].boolean == correct}?.key),map=try XCTUnwrap(run.scenario.maps.first{m in m.world.objects.contains{ExplorationRun.objectKey(mapID:m.id,object:$0)==key}});return(map,try XCTUnwrap(map.world.objects.firstIndex{ExplorationRun.objectKey(mapID:map.id,object:$0)==key}))}
        let (wrongArea,wrongIndex)=try find(false),(rightArea,rightIndex)=try find(true)
        run.mapID=wrongArea.id;run.position=wrongArea.world.start;XCTAssertFalse(run.examine(wrongIndex));XCTAssertTrue(run.inventory.isEmpty)
        try talk(&run);run.talking=false;run.mapID=wrongArea.id;run.position=wrongArea.world.start;let before=run.position,object=wrongArea.world.objects[wrongIndex]
        XCTAssertEqual(run.tap(.init(x:object.tx,y:object.ty)),wrongIndex);XCTAssertEqual(run.position,before);XCTAssertTrue(run.examine(wrongIndex));XCTAssertFalse(run.examine(wrongIndex))
        try talk(&run);XCTAssertFalse(run.handIn(0));XCTAssertEqual(run.inventory.count,1);XCTAssertTrue(run.drop(0));run.mapID=wrongArea.id;XCTAssertTrue(run.examine(wrongIndex))
        run.mapID=rightArea.id;run.position=rightArea.world.start;XCTAssertTrue(run.examine(rightIndex));XCTAssertEqual(run.inventory.count,2);try talk(&run)
        let step=run.stepIndex;XCTAssertTrue(run.handIn(1,successReply:"Perfect."));XCTAssertEqual(run.pendingTurnIn,true);XCTAssertEqual(run.stepIndex,step);XCTAssertFalse(run.handIn(0));run.talking=false;run=try JSONDecoder().decode(ExplorationRun.self,from:JSONEncoder().encode(run));XCTAssertEqual(run.feedback,"Perfect.");run.completeTurnIn();XCTAssertEqual(run.stepIndex,step+1);XCTAssertTrue(run.inventory.isEmpty);XCTAssertFalse(run.searched.contains{$0.hasPrefix(run.scenario.id+":object-search:"+String(step)+":")});run.completeTurnIn();XCTAssertEqual(run.stepIndex,step+1)
        var learner=LearnerState();learner.saveExploration(run);XCTAssertEqual(learner.totalXP,0);XCTAssertTrue(learner.pendingChanges?.isEmpty ?? true)
    }
    func testLocalizationPreservesGraphPlaceholdersAndConsistentItems() throws {
        let original=try sample(),protected=ExplorationText.protectedQuest(original)
        _=try ExplorationText.applying(protected,to:original,target:"es")
        _=try ExplorationText.applying(protected.setting("intro",.string("Una visita con __NPC_1__.")),to:original,target:"es")
        var steps=protected["steps"].array,nodes=steps[0]["nodes"].array;nodes[0]=nodes[0].setting("id",.string("changed"));steps[0]=steps[0].setting("nodes",.array(nodes))
        XCTAssertThrowsError(try ExplorationText.applying(protected.setting("steps",.array(steps)),to:original,target:"es"))
        let stripped=ExplorationText.transform(protected) { $0.replacingOccurrences(of:"__NPC_0__",with:"__NPC_99__") }
        XCTAssertThrowsError(try ExplorationText.applying(stripped,to:original,target:"es"))
        var items=protected["gatherData"]["all"].array;items[0]=items[0].setting("name",.string("different item"))
        XCTAssertThrowsError(try ExplorationText.applying(protected.setting("gatherData",protected["gatherData"].setting("all",.array(items))),to:original,target:"es"))
        XCTAssertThrowsError(try ExplorationText.applying(protected,to:original,target:"ja"))
    }
    func testObjectSearchMatchesActualClientAssignmentsAndDroppedItemsCanBeFoundAgain() throws {
        let fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/exploration-search.json")))
        var run=try ExplorationRun(target:"es",support:"en",scenario:sample().searchingObjects());run.stepIndex=Int(fixture["stepIndex"].number)
        run.nodeID=run.step["nodes"].array.first { $0["responseMode"].string == "objectSearch" }?["id"].string
        guard case .object(let expected)=fixture["assignments"] else { return XCTFail("Missing source assignments") }
        XCTAssertEqual(Set(run.objectAssignments.keys),Set(expected.keys))
        for (key,item) in expected { XCTAssertEqual(run.objectAssignments[key]?["name"],item["name"]);XCTAssertEqual(run.objectAssignments[key]?["isCorrect"],item["isCorrect"]) }
        try talk(&run)
        let winner=try XCTUnwrap(run.objectAssignments.first { $0.value["isCorrect"].boolean }?.key)
        let area=try XCTUnwrap(run.scenario.maps.first { area in area.world.objects.contains { ExplorationRun.objectKey(mapID:area.id,object:$0) == winner } })
        let index=try XCTUnwrap(area.world.objects.firstIndex { ExplorationRun.objectKey(mapID:area.id,object:$0) == winner }),object=area.world.objects[index]
        try travel(&run,to:area.id);XCTAssertTrue(run.approach(RPGPoint(x:object.tx,y:object.ty)));XCTAssertTrue(run.examine(index));XCTAssertFalse(run.examine(index))
        XCTAssertEqual(run.inventory.first?.item["name"],run.requestedItem["name"]);XCTAssertTrue(run.drop(0));XCTAssertTrue(run.examine(index))
        try talk(&run);let step=run.stepIndex;XCTAssertTrue(run.handIn(0));XCTAssertEqual(run.stepIndex,step+1);XCTAssertTrue(run.inventory.isEmpty)
    }
    func testOfflineObjectLabelsAndSentencesMatchTheActualWebFallbacks() throws {
        let library=try ContentLibrary.decode(ExplorationLibrary.self,url:root.appendingPathComponent("Piyali/Resources/exploration.json.gz")),copy=try XCTUnwrap(library.objectCopy)
        let samples=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/exploration-objects.json")))
        XCTAssertEqual(samples.count,12)
        for sample in samples {
            let note=ExplorationObjects.note(type:sample["type"].string,target:sample["lang"].string,support:"en",copy:copy)
            XCTAssertEqual(note["name"],sample["expected"]["supportName"]);XCTAssertEqual(note["description"],sample["expected"]["supportText"])
        }
    }
    func testGeneratedSettingRenamesCharactersAndRoomsWithoutChangingTheWorldGraph() throws {
        let base=try sample(),setting:JSONValue = .object(["title":.string("La visita"),"supportTitle":.string("The visit"),"npcs":.array(base.npcs.indices.map { .object(["name":.string("Alex\($0)"),"personality":.string("Warm and curious")]) }),"rooms":.array(base.maps.indices.map { .object(["title":.string("Sala \($0)"),"supportTitle":.string("Room \($0)")]) })])
        let result=try ExplorationText.setting(setting,on:base,target:"es",support:"en")
        XCTAssertEqual(result.name.localized("en"),"The visit");XCTAssertEqual(result.maps.map(\.world),base.maps.map(\.world));XCTAssertEqual(result.maps.map(\.id),base.maps.map(\.id))
        XCTAssertTrue(result.quest["intro"].string.contains("Alex0"));XCTAssertEqual(result.npcs.first?["name"],.string("Alex0"))
        for map in result.maps { for portal in map.portals { XCTAssertEqual(portal["label"],result.map(portal["toMapId"].string)?.name) } }
        XCTAssertThrowsError(try ExplorationText.setting(setting.setting("npcs",.array([])),on:base,target:"es",support:"en"))
    }
    func testReachingAnObjectSearchNodeStartsTheSearchWithoutReopeningDialogue() throws {
        var run=try ExplorationRun(target:"es",support:"en",scenario:sample().searchingObjects())
        run.stepIndex=try XCTUnwrap(run.scenario.quest["steps"].array.firstIndex { $0["nodes"].array.contains { $0["responseMode"].string == "objectSearch" } })
        try talk(&run)
        for _ in 0..<12 where run.mode != "objectSearch" {
            if run.mode == "speech" { XCTAssertTrue(run.speak("Estoy listo.",reply:"Gracias.")) } else if run.mode == "choice" { XCTAssertTrue(run.choose(0)) } else { XCTFail("The search node was not reached");return }
        }
        XCTAssertEqual(run.mode,"objectSearch");XCTAssertEqual(run.searchStarted,run.searchKey)
        let key=try XCTUnwrap(run.objectAssignments.first { $0.value["isCorrect"].boolean }?.key)
        let area=try XCTUnwrap(run.scenario.maps.first { area in area.world.objects.contains { ExplorationRun.objectKey(mapID:area.id,object:$0) == key } })
        let index=try XCTUnwrap(area.world.objects.firstIndex { ExplorationRun.objectKey(mapID:area.id,object:$0) == key })
        try travel(&run,to:area.id);XCTAssertTrue(run.examine(index));XCTAssertEqual(run.inventory.count,1)
    }
}
