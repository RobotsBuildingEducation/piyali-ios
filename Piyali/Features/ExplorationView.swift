import SwiftUI

struct ExplorationView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.scenePhase) private var phase
    @StateObject private var service=ExplorationService()
    @StateObject private var speech=SpeechService()
    @State private var theme="home"
    @State private var answer=""
    @State private var translation=""
    @State private var replacing=false
    @State private var generated=false
    @State private var searchObjects=false
    @State private var examinedObject:String?
    @FocusState private var editing:Bool
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,app.learner.level].joined(separator:":") }
    private var run:ExplorationRun? { guard let saved=app.learner.explorationRuns?[app.learner.target],saved.support == app.learner.support,saved.scenario.level == app.learner.level else { return nil };return saved }
    var body:some View {
        ScrollViewReader { proxy in Form {
            if let run {
                overview(run)
                if run.completed { Section { Text("Exploration quest complete").font(.headline).accessibilityIdentifier("explorationComplete");Text("Free exploration is practice. It does not award lesson XP or change your Score.") } }
                else { if run.talking { dialogue(run).id("explorationDialogue") };navigation(run);characters(run);portals(run);objects(run);gathering(run);inventory(run) }
            }
            Section(run == nil ? "Choose a world" : "Start another quest") {
                Picker("World family",selection:$theme) { ForEach(["home","market","library","transit","nature","civic","lab","festival"],id:\.self) { Text($0.capitalized).tag($0) } }.accessibilityIdentifier("explorationTheme")
                Toggle("Find items inside objects",isOn:$searchObjects).accessibilityIdentifier("explorationObjectSearch")
                if ["es","en"].contains(app.learner.target) { Button("Play a local quest") { start(false) }.disabled(service.busy || service.library == nil).accessibilityIdentifier("explorationLocal") }
                if app.subscription.hasAccess { Button("Generate a new quest") { start(true) }.disabled(service.busy || service.library == nil).accessibilityIdentifier("explorationGenerate") }
                else { NavigationLink("Subscription for generated quests") { SubscriptionView(service:app.subscription) };Text("Saved local Spanish and English exploration quests are available offline. Generation can reauthor a quest in any practice language at your selected level. Authored adventures remain available offline in all practice languages.").font(.footnote) }
            }
            if service.busy { ProgressView("Preparing exploration…") }
            if let error=service.error { Text(error).foregroundStyle(.red).accessibilityIdentifier("explorationError") }
            if let error=speech.error { Text(error).foregroundStyle(.red) }
        }.onChange(of:run?.talking) { _,open in if open == true { withAnimation { proxy.scrollTo("explorationDialogue",anchor:.top) } } }
        }.navigationTitle("Exploration")
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { editing=false } } }
            .task(id:scope) { stop();await service.load(app) }
            .onChange(of:speech.transcript) { _,text in answer=text }
            .onChange(of:phase) { _,state in if state != .active { stop() } }
            .onChange(of:app.subscription.hasAccess) { _,allowed in if !allowed { stop() } }
            .onDisappear { stop() }
            .confirmationDialog("Replace the saved exploration quest for this language?",isPresented:$replacing,titleVisibility:.visible) { Button("Start another quest") { create() } }
    }
    private func stop() { speech.stopAll();service.cancel();editing=false }
    private func start(_ online:Bool) { generated=online;if run != nil { replacing=true } else { create() } }
    private func create() { stop();answer="";translation="";Task { await service.prepare(app,theme:theme,generated:generated,searchObjects:searchObjects) } }
    private func edit(_ action:(inout ExplorationRun)->Void) { guard !service.busy,var current=run else { return };speech.stopAll();action(&current);app.learner.saveExploration(current);app.persist();answer="";translation="" }
    private func title(_ map:ExplorationMap,_ run:ExplorationRun) -> String { let name=map.name?.localized(run.support) ?? "";return name.isEmpty ? map.id == run.scenario.startMapId ? "Main area" : "Side room" : name }
    @ViewBuilder private func overview(_ run:ExplorationRun) -> some View {
        Section(run.scenario.name.localized(run.support)) {
            Text(run.scenario.quest["intro"].string);Text(run.scenario.quest["storySeed"].string)
            Text("Chapter \(min(run.stepIndex+1,run.scenario.quest["steps"].array.count)) / \(run.scenario.quest["steps"].array.count)").accessibilityIdentifier("explorationStatus")
            if !run.completed { Text("Next: "+run.npc["name"].string+" · "+run.step["title"].string) }
            if run.mode == "objectSearch" { Text("Search the objects in these rooms to find "+run.requestedItem["name"].string+".").accessibilityIdentifier("explorationObjectSearchActive") }
        }
    }
    @ViewBuilder private func navigation(_ run:ExplorationRun) -> some View {
        if let area=run.area { Section("Your location") {
            Text(title(area,run)).font(.headline).accessibilityIdentifier("explorationLocation")
            Text("Position \(run.position.x), \(run.position.y)")
            HStack {
                Button("North") { edit { _=$0.move(dx:0,dy:-1) } };Button("South") { edit { _=$0.move(dx:0,dy:1) } };Button("West") { edit { _=$0.move(dx:-1,dy:0) } };Button("East") { edit { _=$0.move(dx:1,dy:0) } }
            }.buttonStyle(.bordered).disabled(service.busy)
        } }
    }
    @ViewBuilder private func characters(_ run:ExplorationRun) -> some View {
        Section("Characters") {
            if run.npc["mapId"].string != run.mapID,let destination=run.scenario.map(run.npc["mapId"].string) { Text(run.npc["name"].string+" is in "+title(destination,run)+". Travel there to continue.") }
            ForEach(Array(run.scenario.npcs.enumerated()),id:\.offset) { index,npc in
                if npc["mapId"].string == run.mapID {
                    Text(npc["name"].string+" · \(Int(npc["tx"].number)), \(Int(npc["ty"].number))")
                    if index == Int(run.step["npcIdx"].number) {
                        Button("Walk to "+npc["name"].string) { edit { _=$0.approach(ExplorationTemplate.position(npc)) } }.disabled(service.busy).accessibilityIdentifier("explorationApproachNPC")
                        Button("Talk to "+npc["name"].string) { edit { _=$0.talk() } }.disabled(service.busy || !run.nearby(ExplorationTemplate.position(npc))).accessibilityIdentifier("explorationTalk")
                    } else { Text("Visit the current quest character first.").font(.footnote) }
                }
            }
        }
    }
    @ViewBuilder private func portals(_ run:ExplorationRun) -> some View {
        if let area=run.area { Section("Rooms and portals") {
            ForEach(Array(area.portals.enumerated()),id:\.offset) { index,portal in
                let label=portal["label"].localized(run.support)
                VStack(alignment:.leading) {
                    Text(label.isEmpty ? "Connected room" : label)
                    HStack { Button("Walk to entrance") { edit { _=$0.approach(ExplorationTemplate.position(portal)) } }.accessibilityIdentifier("explorationApproachPortal-\(index)")
                        Button("Enter") { edit { _=$0.enter(index) } }.disabled(!run.nearby(ExplorationTemplate.position(portal))).accessibilityIdentifier("explorationEnterPortal-\(index)") }
                }.buttonStyle(.bordered).disabled(service.busy)
            }
        } }
    }
    @ViewBuilder private func objects(_ run:ExplorationRun) -> some View {
        if let area=run.area { Section("Objects to examine") {
            ForEach(Array(area.world.objects.enumerated()),id:\.offset) { index,object in
                let key=ExplorationRun.objectKey(mapID:area.id,object:object),saved=run.objectNotes?[key],note=saved ?? service.localObjectNote(object.type,run:run)
                VStack(alignment:.leading,spacing:6) {
                    Text(note["name"].string)
                    HStack {
                        Button("Walk over") { edit { _=$0.approach(RPGPoint(x:object.tx,y:object.ty)) } }.disabled(area.world.path(from:run.position,to:RPGPoint(x:object.tx,y:object.ty)) == nil).accessibilityIdentifier("explorationApproachObject-\(index)")
                        if run.mode == "objectSearch" { Button("Search") { examinedObject=key;edit { _=$0.examine(index) } }.accessibilityIdentifier("explorationSearchObject-\(index)") }
                        else { Button("Examine") { examinedObject=key } }
                    }.buttonStyle(.bordered).disabled(service.busy)
                    if examinedObject == key {
                        Text(note["description"].string);Text(note["translation"].string).font(.footnote)
                        Button("Listen") { speech.speak(note["description"].string,language:run.target) }
                        if app.subscription.hasAccess,saved == nil { Button("Generate description") { Task { await service.describe(index,app:app) } }.disabled(service.busy) }
                    }
                }
            }
        } }
    }
    @ViewBuilder private func gathering(_ run:ExplorationRun) -> some View {
        if run.gatherUnlocked { Section("Find the requested item") {
            Text(run.node["gatherItem"]["name"].string);Text(run.node["gatherItem"]["hint"].string)
            ForEach(run.scenario.gatherPlacements.indices,id:\.self) { index in
                let item=run.placement(index)
                if item["mapId"].string == run.mapID,!run.collected.contains(run.placementKey(index)) {
                    Text(item["name"].string)
                    HStack { Button("Walk to item") { edit { _=$0.approach(ExplorationTemplate.position(item)) } }.accessibilityIdentifier("explorationApproachItem-\(index)")
                        Button("Pick up") { edit { _=$0.pickUp(index) } }.disabled(!run.nearby(ExplorationTemplate.position(item))).accessibilityIdentifier("explorationPickUp-\(index)") }.buttonStyle(.bordered).disabled(service.busy)
                }
            }
        } }
    }
    @ViewBuilder private func inventory(_ run:ExplorationRun) -> some View {
        Section("Inventory (\(run.inventory.count))") {
            if run.inventory.isEmpty { Text("Your inventory is empty.") }
            ForEach(Array(run.inventory.enumerated()),id:\.element.id) { index,item in
                Text(item.item["name"].string).accessibilityIdentifier("explorationInventoryItem")
                HStack { Button("Hand in") { edit { _=$0.handIn(index) } }.disabled(!run.talking || !["gather","objectSearch"].contains(run.mode)).accessibilityIdentifier("explorationHandIn-\(index)")
                    Button("Drop") { edit { _=$0.drop(index) } } }.buttonStyle(.bordered).disabled(service.busy)
            }
        }
    }
    @ViewBuilder private func dialogue(_ run:ExplorationRun) -> some View {
        Section(run.npc["name"].string) {
            Text(run.node["npcLine"].string).accessibilityIdentifier("explorationNode")
            Button("Listen to character") { speech.speak(run.node["npcLine"].string,language:run.target) }
            if app.subscription.hasAccess { Button("Translate") { let id=run.node["id"].string;Task { if let result=await service.translate(run.node["npcLine"].string,app:app),self.run?.id == run.id,self.run?.node["id"].string == id { translation=result } } } }
            if !translation.isEmpty { Text(translation).font(.footnote) }
            if !run.feedback.isEmpty { Text(run.feedback) };if let tip=run.tip,!tip.isEmpty { Text(tip).font(.footnote) }
            if run.mode == "choice" { ForEach(Array(run.node["choices"].array.enumerated()),id:\.offset) { index,choice in Button(choice["text"].string) { edit { _=$0.choose(index) } }.disabled(service.busy).accessibilityIdentifier("explorationChoice-\(index)") } }
            else if run.mode == "speech" {
                TextField("Your reply",text:$answer,axis:.vertical).focused($editing).accessibilityIdentifier("explorationAnswer")
                Button(speech.recording ? "Stop recording" : "Record reply") { if speech.recording { speech.stop() } else { Task { await speech.start(language:run.target) } } }.disabled(service.busy)
                Button("Send reply") { speech.stopAll();editing=false;let text=answer;answer="";Task { await service.speak(text,app:app) } }.disabled(service.busy || answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityIdentifier("explorationSpeechSubmit")
            } else if run.mode == "none" { Button("Continue") { edit { _=$0.continueDialogue() } }.disabled(service.busy).accessibilityIdentifier("explorationContinue") }
            else { Text("Find an item and return here to hand it in from your inventory.") }
            Button("Explore the world") { edit { $0.talking=false } }.disabled(service.busy)
        }
    }
}
