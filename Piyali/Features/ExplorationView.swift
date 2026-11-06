import SwiftUI

/// Legacy connected-room play. The map, rather than a form of teleport buttons,
/// owns movement, doors, characters and item collection as in RPGGame/index.jsx.
struct ExplorationView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service=ExplorationService()
    @StateObject private var speech=SpeechService()
    @StateObject private var observations=RPGObjectController()
    @StateObject private var narration=RealtimeNarrationService()
    @StateObject private var music=RPGMusicPlayer()
    @StateObject private var help=HelpChatController()
    @AppStorage("piyali.rpgCompanion") private var selectedPet=""
    @State private var answer=""
@State private var translation=""
@State private var panel=""
@State private var loot=""
@State private var pickup=""
    @State private var showSelection=false
@State private var typedReply=false
@State private var speechArmed=false
    @State private var selectedItem:Int?
    @State private var dialogueHeight:CGFloat=44
    @State private var panelHeight:CGFloat=44
    @State private var toastTask:Task<Void,Never>?
    @FocusState private var editing:Bool
    var embedded=false
    var initialPanel=""
    private var scope:String {[app.identity.npub,app.learner.target,app.learner.support,app.learner.level].joined(separator:":")}
    private var run:ExplorationRun? {guard !showSelection,let saved=app.learner.explorationRuns?[app.learner.target],saved.support == app.learner.support,saved.scenario.level == app.learner.level else{return nil};return saved}
    private var light:Bool {scheme != .dark}
    private var paper:Color {PiyaliBrand.unitColor(light ? "fffaf1":"faf4e8")}
    private var ink:Color {PiyaliBrand.unitColor(light ? "4b3726":"1a202c")}
    private var muted:Color {PiyaliBrand.unitColor(light ? "826d54":"718096")}
    private var border:Color {PiyaliBrand.unitColor(light ? "e0b474":"fbd38d")}
    private var pet:String {CompanionTypes.effective(selectedPet.isEmpty ? app.learner.effectiveCompanionType:selectedPet,level:app.learner.companionLevel)}
    private var topInset:CGFloat {embedded ? 0:windowInsets.top}
    private var bottomInset:CGFloat {embedded ? 0:windowInsets.bottom}
    private var windowInsets:UIEdgeInsets {UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.flatMap(\.windows).first{$0.isKeyWindow}?.safeAreaInsets ?? .zero}
    private func t(_ key:String)->String {RPGArt.shared.copy(key,lang:app.learner.support)}
    private func search(_ key:String,_ args:[String]=[])->String {RPGArt.shared.searchCopy(key,lang:app.learner.support,args:args)}
    var body:some View {
        surface.toolbar(.hidden,for:.navigationBar).toolbar(.hidden,for:.tabBar).statusBarHidden(!embedded).ignoresSafeArea(.container)
            .task(id:scope){stop();panel=initialPanel;await service.load(app);configureObjects();startMusic();playDialogue()}
            .task(id:turnInKey){let key=turnInKey;guard !key.isEmpty else{return};try? await Task.sleep(for:.milliseconds(450));guard !Task.isCancelled,turnInKey == key else{return};edit{$0.completeTurnIn()}}
            .onChange(of:narrationKey){_,_ in playDialogue()}
            .onChange(of:run?.mapID){_,_ in observations.cancel();configureObjects();loot="";pickup=""}
            .onChange(of:run?.id){_,_ in configureObjects();startMusic()}
            .onChange(of:run?.completed){_,complete in if complete == true{music.stop();speech.stopAll();narration.stopAll()}}
            .onChange(of:speech.transcript){_,value in answer=value}
            .onChange(of:speech.recording){old,value in if old && !value,speechArmed,run?.talking == true,run?.mode == "speech",!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty{send()}}
            .onChange(of:phase){_,value in if value != .active{stop()}else{configureObjects();startMusic();playDialogue()}}
            .onChange(of:app.subscription.hasAccess){_,allowed in if !allowed{stop()}else{configureObjects()}}
            .onDisappear{stop()}
            .overlay {if panel == "help" {HelpChatView(controller:help,progress:.object(["targetLang":.string(app.learner.target),"supportLang":.string(app.learner.support)]),onClose:{panel=""})}}
            .toolbar{ToolbarItemGroup(placement:.keyboard){Spacer();Button("Done"){editing=false}}}
    }
    private var surface:some View {
        GeometryReader {g in ZStack {
            (light ? PiyaliBrand.unitColor("fff9ef"):PiyaliBrand.unitColor("1a1a2e")).ignoresSafeArea()
            if let run,let rendered=render(run) {
                RPGWorldView(run:rendered,pet:pet,markers:markers(run),onTile:tile).accessibilityIdentifier("explorationWorld").accessibilityValue("\(run.mapID)|\(run.position.x),\(run.position.y)")
                VStack{header(run);Spacer()}.padding(12).padding(.top,topInset)
                if !run.completed {actions.padding(.trailing,12).padding(.top,56+topInset).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topTrailing)}
                if run.talking,!run.completed {VStack{Spacer();dialogue(run,heightLimit:g.size.height*0.44).padding(.horizontal,12).padding(.bottom,16+bottomInset)}}
                if !run.talking,!run.completed {VStack(spacing:8){Spacer();if !pickup.isEmpty{Text("+  "+pickup).font(PiyaliBrand.productFont(14,700)).foregroundStyle(ink).padding(.horizontal,12).padding(.vertical,8).background(paper,in:RoundedRectangle(cornerRadius:8)).overlay(RoundedRectangle(cornerRadius:8).stroke(border))};if let observation=observations.observation{RPGObjectObservationView(observation:observation,target:run.target,support:run.support,lootText:loot)}}.padding(.horizontal,12).padding(.bottom,16+bottomInset).allowsHitTesting(false)}
                if run.completed{completed(run)}
                if ["quest","inventory","companion"].contains(panel){modal(run)}
            }else{selection}
        }.accessibilityHidden(panel == "help")}
    }
    private var selection:some View {
        ZStack(alignment:.topLeading){
            Button{dismiss()}label:{Image(systemName:"arrow.left").foregroundStyle(light ? ink:.white).padding(16)}.padding(.top,topInset).accessibilityLabel(t("back")).accessibilityIdentifier("explorationExit")
            VStack(spacing:24){
                if service.busy {GamePreparationView(preparation:loadingController,support:app.learner.support,pet:pet,embedded:true,onCancel:{service.cancel()}).frame(maxHeight:440)}
                else {
                    Text(t("newWorld")).font(PiyaliBrand.productFont(24,700)).foregroundStyle(light ? ink:PiyaliBrand.unitColor("faf089"))
                    Button{create()}label:{VStack(spacing:4){Text("✨").font(.system(size:30));Text(generatedWorldName).font(PiyaliBrand.productFont(16,700))}.frame(minWidth:92).padding(.horizontal,24).padding(.vertical,16).foregroundStyle(light ? ink:.white).background(light ? paper:.white.opacity(0.06),in:RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(light ? border:.white.opacity(0.16),lineWidth:2))}.disabled(service.library == nil).accessibilityIdentifier("explorationGenerate")
                }
                if let error=service.error {Text(error).font(PiyaliBrand.productFont(14)).foregroundStyle(light ? ink:.white).accessibilityIdentifier("explorationError")}
            }.padding(16).frame(maxWidth:.infinity,maxHeight:.infinity)
        }.buttonStyle(.plain)
    }
    @StateObject private var loadingController=GamePreparationController()
    private var generatedWorldName:String {let lang=app.learner.support;return ["en":"Generated World","es":"Mundo generado","pt":"Mundo gerado","it":"Mondo generato","fr":"Monde genere","ja":"生成された世界","hi":"बनाई गई दुनिया","ar":"العالم المتولّد","zh":"生成的世界","de":"Erstellte Welt"][lang] ?? "Generated World"}
    private func header(_ run:ExplorationRun)->some View {
        HStack(alignment:.top,spacing:8){
            Button{stop();showSelection=true;panel=""}label:{Image(systemName:"arrow.left").font(.system(size:14,weight:.semibold)).foregroundStyle(.white).frame(width:32,height:32).background(.black.opacity(0.62),in:Circle()).shadow(color:.black.opacity(0.8),radius:0,y:4)}.accessibilityLabel(t("back")).accessibilityIdentifier("explorationBack")
            Text(run.area?.name?.localized(run.support) ?? "").font(PiyaliBrand.productFont(12,700)).padding(.horizontal,12).padding(.vertical,8).foregroundStyle(light ? ink:.white).background(light ? paper:.black.opacity(0.64),in:Capsule()).accessibilityIdentifier("explorationLocation")
            Spacer(minLength:2)
            HStack(spacing:8){Text("\(run.stepIndex)/\(run.scenario.quest["steps"].array.count)").font(PiyaliBrand.productFont(14,700));ZStack(alignment:.leading){Capsule().fill(light ? PiyaliBrand.unitColor("332a20"):PiyaliBrand.unitColor("e2e8f0"));Capsule().fill(PiyaliBrand.unitColor("48bb78")).frame(width:60*Double(run.stepIndex)/Double(max(1,run.scenario.quest["steps"].array.count)))}.frame(width:60,height:8)}.padding(.horizontal,12).padding(.vertical,7).foregroundStyle(light ? ink:.white).background(light ? paper:.black.opacity(0.64),in:RoundedRectangle(cornerRadius:6)).accessibilityIdentifier("explorationStatus")
        }.buttonStyle(.plain)
    }
    private var actions:some View {
        VStack(spacing:16){
            Button{closeDialogue();panel="help"}label:{RPGArt.shared.image("RPGIconHelp").resizable().frame(width:20,height:20).frame(width:40,height:40).background(.white,in:Circle()).shadow(color:PiyaliBrand.unitColor("2b6cb0"),radius:0,y:2)}.accessibilityLabel(t("help")).accessibilityIdentifier("explorationHelp")
            action("RPGIconInventory",t("inventory"),"explorationInventory"){selectedItem=nil;panel="inventory"}
            action("RPGIconQuest",RPGArt.shared.quest("button",lang:app.learner.support),"explorationQuest"){panel="quest"}
            Button{panel="companion"}label:{RPGPetPreview(pet:pet,size:44).frame(width:40,height:40)}.accessibilityLabel(RPGArt.shared.data["customize"][app.learner.support]["gameCompanion"].string).accessibilityIdentifier("explorationCompanion")
            action(app.learner.settingsSnapshot["rpgMusicEnabled"].boolean ? "RPGIconMusicOn":"RPGIconMusicOff",t(app.learner.settingsSnapshot["rpgMusicEnabled"].boolean ? "disableMusic":"enableMusic"),"explorationMusic"){app.updateSettings(.object(["rpgMusicEnabled":.bool(!app.learner.settingsSnapshot["rpgMusicEnabled"].boolean),"rpgMusicPreferenceVersion":.number(2)]));startMusic()}
        }.buttonStyle(.plain)
    }
    private func action(_ image:String,_ label:String,_ id:String,_ work:@escaping()->Void)->some View {Button(action:work){RPGArt.shared.image(image).interpolation(.none).resizable().frame(width:64,height:64).frame(width:40,height:40)}.accessibilityLabel(label).accessibilityIdentifier(id)}
    private func dialogue(_ run:ExplorationRun,heightLimit:CGFloat)->some View {
        VStack(spacing:0){
            HStack(spacing:8){portrait(run);Text(run.npc["name"].string).font(PiyaliBrand.productFont(14,700));Spacer()}.padding(.leading,8).padding(.trailing,32).frame(height:100).background(light ? PiyaliBrand.unitColor("f9f0dd").opacity(0.94):PiyaliBrand.unitColor("fffaf0")).overlay(alignment:.bottom){Rectangle().fill(border.opacity(0.45)).frame(height:1)}.overlay(alignment:.topTrailing){Button{closeDialogue()}label:{Image(systemName:"xmark").font(.system(size:10,weight:.semibold)).frame(width:24,height:24)}.padding(8).accessibilityLabel(t("closeDialogue")).accessibilityIdentifier("explorationCloseDialogue")}
            ScrollView {VStack(alignment:.leading,spacing:8){
                HStack{Spacer();Button{let text=line(run),id=run.id,node=run.nodeID;Task{if let result=await service.translate(text,app:app),self.run?.id == id,self.run?.nodeID == node{translation=result}}}label:{RPGArt.shared.image("RPGIconHelp").renderingMode(.template).resizable().frame(width:14,height:14).foregroundStyle(PiyaliBrand.unitColor("466f9a")).frame(width:24,height:24).background(.white,in:RoundedRectangle(cornerRadius:6))}.disabled(service.busy).accessibilityLabel(t("translateText"))}
                RPGDialogueText(text:line(run),language:run.target,color:ink,animated:true).accessibilityIdentifier("explorationNode")
                if !translation.isEmpty{Text(translation).font(PiyaliBrand.productFont(14)).italic().foregroundStyle(PiyaliBrand.unitColor("2b6cb0"))}
                if let tip=run.tip,!tip.isEmpty{Text(tip).font(PiyaliBrand.productFont(12)).foregroundStyle(muted)}
                dialogueActions(run).disabled(run.pendingTurnIn == true)
            }.padding(.horizontal,12).padding(.top,4).padding(.bottom,12).background{GeometryReader{g in Color.clear.preference(key:ExplorationDialogueHeight.self,value:g.size.height)}}}.frame(height:min(max(44,dialogueHeight),max(44,heightLimit-100))).onPreferenceChange(ExplorationDialogueHeight.self){dialogueHeight=$0}.scrollBounceBehavior(.basedOnSize).scrollIndicators(.hidden)
        }.foregroundStyle(ink).background(paper,in:RoundedRectangle(cornerRadius:12)).clipShape(RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(border,lineWidth:2)).buttonStyle(.plain)
    }
    @ViewBuilder private func dialogueActions(_ run:ExplorationRun)->some View {
        if run.mode == "choice" {ForEach(Array(run.node["choices"].array.enumerated()),id:\.offset){index,choice in Button(choice["text"].string){edit{_=$0.choose(index)}}.buttonStyle(ExplorationChoiceStyle(ink:ink,paper:paper,border:border)).accessibilityIdentifier("explorationChoice-\(index)")}}
        else if run.mode == "speech" {
            if typedReply {TextField(t("response"),text:$answer,axis:.vertical).textFieldStyle(.roundedBorder).focused($editing).accessibilityIdentifier("explorationAnswer");Button(t("continue")){send()}.disabled(answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || service.busy).accessibilityIdentifier("explorationSpeechSubmit")}
            else {Button{if speech.recording{speech.stop()}else{speechArmed=true;Task{await speech.start(language:run.target)}}}label:{Image(systemName:speech.recording ? "stop.fill":"mic.fill").font(.system(size:28)).frame(width:56,height:56).background(PiyaliBrand.unitColor("48bb78"),in:Circle())}.frame(maxWidth:.infinity).disabled(service.busy).contextMenu{Button(t("response")){typedReply=true}}.accessibilityLabel(t(speech.recording ? "micStop":"micStart")).accessibilityIdentifier("explorationMicrophone")}
        }else if ["gather","objectSearch"].contains(run.mode){
            if !run.inventory.isEmpty {Text(search("chooseItem")).font(PiyaliBrand.productFont(12)).foregroundStyle(muted);LazyVGrid(columns:[GridItem(.adaptive(minimum:60))],spacing:8){ForEach(Array(run.inventory.enumerated()),id:\.element.id){index,item in Button{handIn(index)}label:{itemSprite(item.item,size:40).padding(8).background(paper,in:RoundedRectangle(cornerRadius:8)).overlay(RoundedRectangle(cornerRadius:8).stroke(border,lineWidth:2))}.accessibilityLabel(item.item["name"].string).accessibilityIdentifier("explorationHandIn-\(index)")}}}
            Button{closeDialogue()}label:{Text(search("continueSearching")).font(PiyaliBrand.productFont(14,700)).frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,12).padding(.vertical,8).overlay(Capsule().stroke(border,lineWidth:1))}.accessibilityIdentifier("explorationKeepSearching")
        }else{Button(t("continue")){edit{_=$0.continueDialogue()}}.buttonStyle(ExplorationChoiceStyle(ink:ink,paper:paper,border:border)).accessibilityIdentifier("explorationContinue")}
        if service.busy{ProgressView()};if let error=speech.error{Text(error).font(PiyaliBrand.productFont(12))}
    }
    private func portrait(_ run:ExplorationRun)->some View {let index=max(0,ExplorationTemplate.integer(run.step["npcIdx"])),kind=RPGArt.shared.data["npcs"].array[(index*5)%16]["type"].string,id=StoryCharacterAvatar.appearance.portraitPool(kind).first ?? "35",file=StoryCharacterAvatar.appearance.portraitFile(id);return Group{if let url=Bundle.main.url(forResource:file,withExtension:nil),let image=UIImage(contentsOfFile:url.path){Image(uiImage:image).resizable().interpolation(.none).scaledToFit()}else{RPGArt.shared.image("RPGNPC-0-0").resizable().scaledToFit()}}.frame(width:36,height:36)}
    private func line(_ run:ExplorationRun)->String {if !run.feedback.isEmpty{return run.feedback};return run.mode == "objectSearch" ? search("intro",[compact(run.requestedItem)]):run.node["npcLine"].string}
    private func primary(_ item:JSONValue)->String {let support=item["supportName"].string.trimmingCharacters(in:.whitespacesAndNewlines);return support.isEmpty ? item["name"].string.trimmingCharacters(in:.whitespacesAndNewlines):support}
    private func secondary(_ item:JSONValue)->[String] {var seen=Set([primary(item)]);return [item["transcription"].string,item["name"].string].map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty && seen.insert($0).inserted}}
    private func compact(_ item:JSONValue)->String {let value=primary(item);return secondary(item).first.map{value.isEmpty ? $0:value+" ("+$0+")"} ?? value}
    private func itemSprite(_ item:JSONValue,size:CGFloat)->some View {RPGArt.shared.image(RPGArt.shared.itemImage(item)).interpolation(.none).resizable().scaledToFit().frame(width:size,height:size)}
    private func modal(_ run:ExplorationRun)->some View {
        ZStack{Color.black.opacity(light ? 0.36:0.7).ignoresSafeArea().onTapGesture{panel=""}
            VStack(alignment:.leading,spacing:16){HStack{Text(panel == "inventory" ? t("inventory"):panel == "quest" ? RPGArt.shared.quest("title",lang:run.support):RPGArt.shared.data["customize"][run.support]["companion"].string).font(PiyaliBrand.productFont(16,700));Spacer();Button{panel=""}label:{Image(systemName:"xmark").frame(width:24,height:24)}.accessibilityLabel(t("close")).accessibilityIdentifier("explorationModalClose")}
                ScrollView {Group{if panel == "inventory"{inventory(run)}else if panel == "quest"{quest(run)}else{companions}}.background{GeometryReader{g in Color.clear.preference(key:ExplorationPanelHeight.self,value:g.size.height)}}}.frame(height:min(max(44,panelHeight),520)).onPreferenceChange(ExplorationPanelHeight.self){panelHeight=$0}.scrollIndicators(.hidden)
            }.padding(28).frame(maxWidth:384).foregroundStyle(ink).background(paper,in:RoundedRectangle(cornerRadius:48)).overlay(RoundedRectangle(cornerRadius:48).stroke(border,lineWidth:2)).padding(.horizontal,16).padding(.vertical,32)
        }.buttonStyle(.plain).accessibilityAddTraits(.isModal)
    }
    @ViewBuilder private func inventory(_ run:ExplorationRun)->some View {
        if run.inventory.isEmpty{Text(t("noItems")).font(PiyaliBrand.productFont(14)).foregroundStyle(muted).padding(.vertical,16).frame(maxWidth:.infinity)}
        else {VStack(spacing:12){LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:12),count:4),spacing:12){ForEach(Array(run.inventory.enumerated()),id:\.element.id){index,item in Button{selectedItem=selectedItem == index ? nil:index}label:{itemSprite(item.item,size:48).padding(8).background(selectedItem == index ? border.opacity(0.15):Color.clear,in:RoundedRectangle(cornerRadius:8)).overlay(RoundedRectangle(cornerRadius:8).stroke(selectedItem == index ? border:Color.clear,lineWidth:2))}.accessibilityLabel(item.item["name"].string).accessibilityIdentifier("explorationInventoryItem-\(index)")}}
            if let index=selectedItem,run.inventory.indices.contains(index){HStack(alignment:.top){VStack(alignment:.leading,spacing:2){Text(primary(run.inventory[index].item)).font(PiyaliBrand.productFont(14));Text(secondary(run.inventory[index].item).joined(separator:" · ")).font(PiyaliBrand.productFont(12)).foregroundStyle(muted)};Spacer();Button(t("dropItem")){edit{_=$0.drop(index)};selectedItem=nil}.font(PiyaliBrand.productFont(12,700)).foregroundStyle(.red).accessibilityIdentifier("explorationDrop-\(index)")}.padding(12).background(border.opacity(0.15),in:RoundedRectangle(cornerRadius:8))}
        }}
    }
    private func quest(_ run:ExplorationRun)->some View {
        let key=run.completed ? "complete":run.mode == "objectSearch" ? (run.inventory.contains{$0.stepKey == run.searchKey && $0.item["isCorrect"].boolean} ? "returnItem":run.searchStarted == run.searchKey ? "searchObjects":"startObjectSearch"):run.mode == "gather" ? "gatherSearch":run.mode == "choice" ? "choiceTask":run.mode == "speech" ? "speechTask":"continueTask"
        let args=key == "startObjectSearch" ? [run.npc["name"].string,compact(run.requestedItem)]:key == "returnItem" ? [compact(run.requestedItem),run.npc["name"].string]:[key == "gatherSearch" || key == "searchObjects" ? compact(run.requestedItem):run.npc["name"].string]
        return VStack(alignment:.leading,spacing:12){HStack{Text(RPGArt.shared.quest("currentTask",lang:run.support));Spacer();Text(RPGArt.shared.quest("progress",lang:run.support,[String(run.stepIndex),String(run.scenario.quest["steps"].array.count)]))}.font(PiyaliBrand.productFont(12,700));Text("1.  "+RPGArt.shared.quest(key,lang:run.support,args)).font(PiyaliBrand.productFont(14)).padding(12).frame(maxWidth:.infinity,alignment:.leading).background(border.opacity(0.1),in:RoundedRectangle(cornerRadius:8))}
    }
    private var companions:some View {VStack(alignment:.leading,spacing:16){Text(RPGArt.shared.data["customize"][app.learner.support]["rpgDescription"].string).font(PiyaliBrand.productFont(14));LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12){ForEach(CompanionTypes.ordered,id:\.self){value in let unlocked=CompanionTypes.available(level:app.learner.companionLevel).contains(value);Button{selectedPet=value;panel=""}label:{VStack{RPGPetPreview(pet:value,size:62);Text(RPGArt.shared.data["customize"][app.learner.support][value].string).font(PiyaliBrand.productFont(14,700));if !unlocked{Image(systemName:"lock.fill")}}.frame(maxWidth:.infinity).frame(height:128).overlay(RoundedRectangle(cornerRadius:8).stroke(pet == value ? Color.teal:border,lineWidth:2))}.disabled(!unlocked)}}}}
    private func completed(_ run:ExplorationRun)->some View {ZStack{Color.black.opacity(0.7).ignoresSafeArea();VStack(spacing:20){Text("✨").font(.system(size:36));Text(t("completed")).font(PiyaliBrand.productFont(20,700)).accessibilityIdentifier("explorationComplete");HStack(spacing:12){Button(t("playAgain")){replay(run)};Button(t("newWorld")){showSelection=true}}}.padding(28).foregroundStyle(ink).background(paper,in:RoundedRectangle(cornerRadius:16)).padding(24)}}
    private func markers(_ run:ExplorationRun)->[RPGWorldMarker] {guard run.gatherUnlocked else{return []};return run.scenario.gatherPlacements.indices.compactMap{index in let item=run.placement(index);guard item["mapId"].string == run.mapID,!run.collected.contains(run.placementKey(index)) else{return nil};return RPGWorldMarker(id:run.placementKey(index),point:ExplorationTemplate.position(item),image:RPGArt.shared.itemImage(item))}}
    private func render(_ run:ExplorationRun)->RPGRun? {guard let area=run.area,let key=RPGArt.shared.explorationKey(area) else{return nil};let indices=run.scenario.npcs.indices.filter{run.scenario.npcs[$0]["mapId"].string == run.mapID},npcs=indices.map{index in let value=run.scenario.npcs[index];return RPGNPC(name:value["name"].string,role:"",personality:value["personality"].string,tx:Int(value["tx"].number),ty:Int(value["ty"].number),appearance:RPGArt.shared.data["npcs"].array[(index*5)%16]["image"].string)},active=indices.firstIndex(of:ExplorationTemplate.integer(run.step["npcIdx"])) ?? -1,step=RPGStep(id:"legacy",npcIdx:active,title:"",weight:0,conceptLabel:"",expectedAnswer:"",primitive:"",nodes:[]),scenario=RPGScenario(id:area.id,name:run.scenario.name,emoji:"✨",npcs:npcs,quest:RPGQuest(title:"",intro:"",storySeed:"",steps:[step]),authoredEpisode:RPGEpisode(id:"legacy",level:run.scenario.level,maxBaseScore:0,unitGrounded:false),worldKey:key);var value=RPGRun(target:run.target,support:run.support,lessonID:nil,xpReward:0,scenario:scenario,world:area.world);value.id=run.id;value.position=run.position;if run.completed{value.stepIndex=1};return value}
    private var turnInKey:String {guard let run,run.pendingTurnIn == true else{return ""};return scope+":"+run.id.uuidString+":"+run.searchKey}
    private func handIn(_ index:Int){guard let run,run.inventory.indices.contains(index) else{return};let item=run.inventory[index].item;edit{value in
        let searchMode=value.mode == "objectSearch",success=searchMode ? search("success",[compact(value.requestedItem)]):nil
        if !value.handIn(index,successReply:success),searchMode{value.feedback=search("wrongItem",[compact(item),compact(value.requestedItem)])}
    }}
    private var narrationKey:String {guard let run,run.talking,!run.completed else{return ""};return [scope,run.id.uuidString,run.nodeID ?? "",line(run)].joined(separator:":")}
    private func playDialogue(){narration.stopAll();guard !Self.fixture,phase == .active,app.subscription.hasAccess,let run,run.talking,!run.completed else{return};let index=max(0,ExplorationTemplate.integer(run.step["npcIdx"])),kind=RPGArt.shared.data["npcs"].array[(index*5)%16]["type"].string,character=RPGArt.shared.data["voices"][kind],voice=character["voice"].string.isEmpty ? "ash":character["voice"].string,session=try? app.companionQuestPolicy?.run("ph_tts",.object(["language":.string(run.target),"voice":.string(voice),"personality":character["personality"]]));narration.play(RPGDialogue.split(line(run)).spoken,language:run.target,engine:app.companionQuestPolicy,voice:voice,sessionOverride:session)}
    private func edit(_ action:(inout ExplorationRun)->Void){guard !service.busy,var value=run else{return};narration.stopAll();speech.stopAll();action(&value);app.learner.saveExploration(value);app.persist();answer="";translation="";editing=false}
    private func tile(_ point:RPGPoint){guard !service.busy,var value=run else{return};let before=value.inventory.count,object=value.tap(point);if let object,let area=value.area{loot="";if value.searchStarted == value.searchKey,value.mode == "objectSearch" {if value.examine(object){pickup=compact(value.inventory.last?.item ?? .null);expirePickup()}else{loot=search("alreadyChecked")}};observations.examine(area.world.objects[object])};if value.inventory.count>before,object == nil {pickup=compact(value.inventory.last?.item ?? .null);expirePickup()};app.learner.saveExploration(value);app.persist();if value.talking{speech.stopAll()}}
    private func expirePickup(){toastTask?.cancel();toastTask=Task{try? await Task.sleep(for:.milliseconds(1600));if !Task.isCancelled{pickup=""}}}
    private func closeDialogue(){narration.stopAll();speechArmed=false;service.cancel();speech.stopAll();editing=false;typedReply=false;answer="";translation="";edit{$0.talking=false}}
    private func send(){speechArmed=false;let text=answer.trimmingCharacters(in:.whitespacesAndNewlines);guard !text.isEmpty,!service.busy else{return};speech.stopAll();editing=false;answer="";Task{await service.speak(text,app:app)}}
    private func replay(_ run:ExplorationRun){guard let fresh=try? ExplorationRun(target:run.target,support:run.support,scenario:run.scenario) else{return};stop();app.learner.saveExploration(fresh);app.persist();configureObjects();startMusic()}
    private func create(){stop();showSelection=true;Task{await service.prepare(app,theme:"",generated:app.subscription.hasAccess);if service.error == nil{showSelection=false;configureObjects();startMusic()}}}
    private func configureObjects(){guard let run,let area=run.area,let key=RPGArt.shared.explorationKey(area) else{return};let map=RPGArt.shared.world(key)["map"].setting("id",.string(area.id)).setting("name",area.name ?? .null),parameters:JSONValue = .object(["scenarioID":.string(run.scenario.id),"map":map,"target":.string(run.target),"support":.string(run.support),"level":.string(run.scenario.level),"reviewContext":.null,"user":app.learner.rpgObjectUser,"objects":(try? JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(area.world.objects))) ?? .array([])]);observations.configure(scope:scope+":"+run.id.uuidString+":"+area.id,parameters:parameters,objects:area.world.objects){prompt in guard app.subscription.hasAccess,!Self.fixture else{throw URLError(.notConnectedToInternet)};return try await app.ai.responsesText(prompt)}}
    private func startMusic(){let snapshot=app.learner.settingsSnapshot;let flagValid:Bool;if case .bool = snapshot["rpgMusicEnabled"]{flagValid=true}else{flagValid=false};if snapshot["rpgMusicPreferenceVersion"] != .number(2) || !flagValid{app.updateSettings(.object(["rpgMusicEnabled":.bool(false),"rpgMusicPreferenceVersion":.number(2)]))};music.apply(app.learner.settingsSnapshot["rpgMusicEnabled"].boolean && run?.completed == false)}
    private func stop(){narration.stopAll();speechArmed=false;speech.stopAll();service.cancel();observations.cancel();music.stop();help.stop();toastTask?.cancel();toastTask=nil;editing=false}
    private static var fixture:Bool {let e=ProcessInfo.processInfo.environment;return e["PIYALI_OFFLINE_TESTS"] == "1" && UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil}
}

private struct ExplorationChoiceStyle:ButtonStyle {
    let ink:Color,paper:Color,border:Color
    func makeBody(configuration:Configuration)->some View {configuration.label.font(PiyaliBrand.productFont(14)).foregroundStyle(ink).padding(10).frame(maxWidth:.infinity).background(paper,in:RoundedRectangle(cornerRadius:8)).overlay(RoundedRectangle(cornerRadius:8).stroke(border,lineWidth:2)).offset(y:configuration.isPressed ? 2:0)}
}

private struct ExplorationDialogueHeight:PreferenceKey {static var defaultValue:CGFloat=0;static func reduce(value:inout CGFloat,nextValue:()->CGFloat){value=max(value,nextValue())}}
private struct ExplorationPanelHeight:PreferenceKey {static var defaultValue:CGFloat=0;static func reduce(value:inout CGFloat,nextValue:()->CGFloat){value=max(value,nextValue())}}
