import SwiftUI

struct RPGLibraryView: View {
    @EnvironmentObject var app:AppModel
    @StateObject private var service=RPGService()
    var body: some View {
        List {
            Section("Exploration worlds") {
                NavigationLink("Explore connected rooms") { ExplorationView() }.accessibilityIdentifier("explorationLink")
                Text("Travel through rooms, search objects, collect items and help the characters with their quest.").font(.footnote)
            }
            Text("Explore an authored episode, talk to its characters and finish six tasks plus a finale. Unit Game Reviews award lesson XP; free adventures are practice.")
            if let library=service.library {
                Section("Episodes · "+app.learner.level) {
                    ForEach(library.scenarios(level:app.learner.level,support:app.learner.support),id:\.authoredEpisode.id) { scenario in
                        NavigationLink(scenario.emoji+" "+scenario.name.localized(app.learner.support)) { RPGView(lesson:nil,episode:scenario.authoredEpisode.id) }
                    }
                }
                Section("Unit reviews") {
                    ForEach(app.units) { unit in
                        if let lesson=unit.lessons.first(where:{ $0.modes.contains("game") }) {
                            NavigationLink(unit.title.localized(app.learner.support)) { RPGView(lesson:lesson,episode:nil) }.accessibilityIdentifier("rpgReview-"+lesson.id)
                        }
                    }
                }
            }
            if service.busy { ProgressView("Loading authored episodes…") }
            if let error=service.error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Adventure").task(id:app.learner.target) { await service.load(target:app.learner.target) }.onDisappear { service.cancel() }
    }
}
struct RPGView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.scenePhase) private var phase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    let lesson:Lesson?,episode:String?
    var onTutorialComplete:(()->Void)?=nil,onTutorComplete:(()->Void)?=nil,onReviewComplete:(()->Void)?=nil
    var tutor=false,embedded=false
    var initialPanel=""
    @StateObject private var service=RPGService()
    @StateObject private var speech=SpeechService()
    @StateObject private var narration=RealtimeNarrationService()
    @StateObject private var music=RPGMusicPlayer()
    @StateObject private var observations=RPGObjectController()
    @StateObject private var help=HelpChatController()
    @AppStorage("piyali.rpgCompanion") private var selectedPet=""
    @State private var dialogueContentHeight:CGFloat=0
    @State private var talking=false
    @State private var typedReply=false
    @State private var showExample=false
    @State private var translating=false
    @State private var speechArmed=false
    @State private var answer=""
    @State private var panel=""
    @State private var translation:[String]=[]
    @FocusState private var focused:Bool
    private var run:RPGRun?{guard let value=app.learner.rpgRuns?[app.learner.target],value.support == app.learner.support,(value.tutor == true) == tutor,value.lessonID == lesson?.id,episode == nil || value.scenario.authoredEpisode.id == episode else{return nil};return value}
    private var scope:String{[app.identity.npub,app.learner.target,app.learner.support,tutor ? app.learner.tutorLevel:app.learner.level].joined(separator:":")}
    private var chromeInset:CGFloat{embedded ? 0:(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.flatMap(\.windows).first{$0.isKeyWindow}?.safeAreaInsets.top ?? 0)}
    private var bottomInset:CGFloat{embedded ? 0:(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.flatMap(\.windows).first{$0.isKeyWindow}?.safeAreaInsets.bottom ?? 0)}
    private var light:Bool{scheme != .dark}
    private var ink:Color{PiyaliBrand.unitColor(light ? "4b3726":"1a202c")}
    private var paper:Color{PiyaliBrand.unitColor(light ? "fffaf1":"faf4e8")}
    private var border:Color{PiyaliBrand.unitColor(light ? "e0b474":"fbd38d")}
    private var pet:String{CompanionTypes.effective(selectedPet.isEmpty ? app.learner.effectiveCompanionType:selectedPet,level:app.learner.companionLevel)}
    private func t(_ key:String)->String{RPGArt.shared.copy(key,lang:app.learner.support)}
    var body:some View {
        Group{if Self.fixture{surface}else{SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:run?.completed == true){surface}}}.accessibilityHidden(panel == "help")
            .toolbar(.hidden,for:.navigationBar).statusBarHidden(!embedded).ignoresSafeArea(.container)
            .task(id:scope){stop();panel=initialPanel;talking=false;await service.prepare(app,lesson:lesson,episode:episode,tutor:tutor);configureObjects();startMusic()}
            .onChange(of:run?.id){_,_ in configureObjects()}
            .onChange(of:run?.completed){_,completed in if completed == true{music.stop()}}
            .onChange(of:speech.transcript){_,text in answer=text}
            .onChange(of:speech.recording){old,value in if old && !value,speechArmed,talking,!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty{sendSpeech()}}
            .onChange(of:phase){_,value in if value != .active{stop(clearObservations:false)}else{configureObjects();startMusic()}}
            .onChange(of:app.subscription.hasAccess){_,allowed in if !allowed{stop()}else{configureObjects();startMusic()}}
            .onDisappear{stop()}
            .toolbar{ToolbarItemGroup(placement:.keyboard){Spacer();Button("Done"){focused=false}.accessibilityIdentifier("rpgKeyboardDone")}}
            .overlay{if panel == "help"{HelpChatView(controller:help,progress:.object(["targetLang":.string(app.learner.target),"supportLang":.string(app.learner.support)]),onClose:{panel=""})}}
    }
    @ViewBuilder private var surface:some View {
        GeometryReader{g in ZStack {
            if let run {
                RPGWorldView(run:run,pet:pet,onTile:tile).ignoresSafeArea(.container)
                VStack{top(run);Spacer()}.padding(12).padding(.top,chromeInset)
                if !run.completed{actions.padding(.trailing,12).padding(.top,56+chromeInset).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topTrailing)}
                if talking,let node=run.node,!run.completed{VStack{Spacer();dialogue(run,node:node,heightLimit:g.size.height*0.44).padding(.horizontal,12).padding(.bottom,16+max(g.safeAreaInsets.bottom,bottomInset))}}
                if !talking,!run.completed,let observation=observations.observation{VStack{Spacer();RPGObjectObservationView(observation:observation,target:run.target,support:run.support).padding(.horizontal,12).padding(.bottom,16+max(g.safeAreaInsets.bottom,bottomInset))}.allowsHitTesting(false)}
                if run.completed{completion(run)}
                if ["quest","inventory","companion"].contains(panel){modal(run)}
            }else{
                paper.ignoresSafeArea()
                VStack(spacing:20){
                    RPGArt.shared.image("RPGPet-ghost-down-0").interpolation(.none).resizable().scaledToFit().frame(width:60,height:80)
                    if service.busy{ProgressView(t("loadingGeneratingGame"))}
                    else{
                        Button(t("playAgain")){Task{await service.prepare(app,lesson:lesson,episode:episode,tutor:tutor)}}
                        Button(t("back")){dismiss()}
                    }
                }.padding(24)
            }
            if service.busy,run != nil{ProgressView().padding(14).background(paper,in:Capsule()).frame(maxHeight:.infinity,alignment:.top).padding(.top,56)}
            if let error=service.error,run == nil{Text(error).font(PiyaliBrand.productFont(12)).padding(12).background(paper,in:RoundedRectangle(cornerRadius:10)).padding(12).frame(maxHeight:.infinity,alignment:.bottom).allowsHitTesting(false)}
        }.frame(width:g.size.width,height:g.size.height).foregroundStyle(ink).buttonStyle(.plain)}
    }
    private func top(_ run:RPGRun)->some View {
        HStack(alignment:.top,spacing:8){
            Button{stop();if run.tutorial == true{onTutorialComplete?()}else{dismiss()}}label:{Image(systemName:run.tutorial == true ? "forward.end.fill":"arrow.left").font(.system(size:14,weight:.semibold)).foregroundStyle(.white).frame(width:32,height:32).background(.black.opacity(0.62),in:Circle()).shadow(color:.black.opacity(0.6),radius:0,y:3)}.accessibilityLabel(t(run.tutorial == true ? "skip":"back")).accessibilityIdentifier("rpgBack")
            Text(RPGArt.shared.data["worlds"][run.scenario.worldKey]["name"].localized(app.learner.support)).font(PiyaliBrand.productFont(12,700)).padding(.horizontal,12).padding(.vertical,8).foregroundStyle(hudInk).background(hudPaper,in:Capsule())
            Spacer(minLength:2)
            HStack(spacing:8){Text("\(run.stepIndex)/\(run.scenario.quest.steps.count)").font(PiyaliBrand.productFont(14,700));ZStack(alignment:.leading){Capsule().fill(light ? PiyaliBrand.unitColor("332a20"):PiyaliBrand.unitColor("e2e8f0"));Capsule().fill(PiyaliBrand.unitColor("48bb78")).frame(width:60*Double(run.stepIndex)/Double(max(1,run.scenario.quest.steps.count)))}.frame(width:60,height:8)}.padding(.horizontal,12).padding(.vertical,7).foregroundStyle(hudInk).background(hudPaper,in:RoundedRectangle(cornerRadius:6)).accessibilityElement(children:.combine).accessibilityIdentifier("rpgStatus")
        }.environment(\.layoutDirection,.leftToRight)
    }
    private var hudPaper:Color{light ? paper:Color.black.opacity(0.64)}
    private var hudInk:Color{light ? ink:.white}
    private var actions:some View {
        VStack(spacing:16){
            Button{panel="help"}label:{RPGArt.shared.image("RPGIconHelp").resizable().frame(width:20,height:20).frame(width:40,height:40).background(.white,in:Circle()).shadow(color:PiyaliBrand.unitColor("2b6cb0"),radius:0,y:2)}.accessibilityLabel(t("help")).accessibilityIdentifier("rpgHelp")
            quick("RPGIconInventory",label:t("inventory"),id:"rpgInventory"){panel="inventory"}
            quick("RPGIconQuest",label:RPGArt.shared.quest("button",lang:app.learner.support),id:"rpgQuest"){panel="quest"}
            Button{panel="companion"}label:{RPGPetPreview(pet:pet,size:44).frame(width:40,height:40)}.accessibilityLabel(RPGArt.shared.data["customize"][app.learner.support]["gameCompanion"].string).accessibilityIdentifier("rpgCompanion")
            quick(app.learner.settingsSnapshot["rpgMusicEnabled"].boolean ? "RPGIconMusicOn":"RPGIconMusicOff",label:t(app.learner.settingsSnapshot["rpgMusicEnabled"].boolean ? "disableMusic":"enableMusic"),id:"rpgMusic"){let enabled = !app.learner.settingsSnapshot["rpgMusicEnabled"].boolean;app.updateSettings(.object(["rpgMusicEnabled":.bool(enabled),"rpgMusicPreferenceVersion":.number(2)]));music.apply(enabled)}
        }
    }
    private func quick(_ image:String,label:String,id:String,action:@escaping()->Void)->some View {Button(action:action){RPGArt.shared.image(image).interpolation(.none).resizable().frame(width:64,height:64).frame(width:40,height:40)}.accessibilityLabel(label).accessibilityIdentifier(id)}

    private func dialogue(_ run:RPGRun,node:RPGNode,heightLimit:CGFloat)->some View {
        VStack(spacing:0){
            HStack(spacing:8){RPGArt.shared.image(run.npc?.appearance ?? "RPGNPC-0-0").interpolation(.none).resizable().scaledToFit().frame(width:30,height:36);Text(run.npc?.name ?? "").font(PiyaliBrand.productFont(14,700));if run.resolved{Image(systemName:"checkmark.circle.fill").foregroundStyle(.green)}else if run.attempts>0{Image(systemName:"exclamationmark.circle.fill").foregroundStyle(.orange)};Spacer();Button{closeDialogue()}label:{Image(systemName:"xmark").font(.system(size:10,weight:.semibold)).frame(width:26,height:26)}.accessibilityLabel(t("closeDialogue")).accessibilityIdentifier("rpgCloseDialogue")}.padding(.horizontal,8).background(PiyaliBrand.unitColor("f9f0dd")).overlay(alignment:.bottom){Rectangle().fill(border.opacity(0.45)).frame(height:1)}
            ScrollView {VStack(alignment:.leading,spacing:8){
                HStack{Spacer();Button{translate(run,node:node)}label:{if translating{ProgressView().scaleEffect(0.7)}else{Image(systemName:translation.isEmpty ? "person.crop.circle.badge.questionmark":"arrow.uturn.backward").font(.system(size:14)).frame(width:24,height:24).background(.white,in:RoundedRectangle(cornerRadius:5))}}.accessibilityLabel(t(translation.isEmpty ? "translateText":"undoTranslation")).accessibilityIdentifier("rpgTranslation")}
                let text=run.feedback.isEmpty ? node.npcLine:run.feedback
                Text(RPGDialogue.split(text).spoken).font(PiyaliBrand.productFont(run.feedback.isEmpty ? 16:14,run.feedback.isEmpty ? 700:400)).foregroundStyle(run.feedback.isEmpty ? ink:PiyaliBrand.unitColor("9b5d2d")).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier(run.feedback.isEmpty ? "rpgPrompt":"rpgFeedback")
                if let first=translation.first,!first.isEmpty{Text(first).font(PiyaliBrand.productFont(14)).italic().foregroundStyle(PiyaliBrand.unitColor("466f9a"))}
                if !run.tip.isEmpty{Text(run.tip).font(PiyaliBrand.productFont(13)).italic()}
                if !run.resolved, node.responseMode == "choice" {ForEach(Array(node.choices.enumerated()),id:\.offset){index,choice in Button{narration.stopAll();speech.stopAll();change{$0.choose(index)};translation=[];if let value=self.run{play(value.feedback,target:value.target)}}label:{VStack(alignment:.leading,spacing:2){Text(String(UnicodeScalar(65+index)!)+". "+choice.text).font(PiyaliBrand.productFont(14));if translation.indices.contains(index+1){Text(translation[index+1]).font(PiyaliBrand.productFont(12)).italic().foregroundStyle(PiyaliBrand.unitColor("466f9a"))}}.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,12).padding(.vertical,8).background(PiyaliBrand.unitColor("fffdf9"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(PiyaliBrand.unitColor("c8ad88"))}.shadow(color:PiyaliBrand.unitColor("d2c1a9"),radius:0,y:3)}.accessibilityIdentifier("rpgChoice-\(index)")}}
                if !run.resolved,node.responseMode == "speech"{speechControls(run,node:node)}
                if run.resolved{Button(t("continue")){narration.stopAll();speech.stopAll();change{$0.advance()};closeDialogue()}.font(PiyaliBrand.productFont(14,600)).frame(maxWidth:.infinity).padding(.vertical,8).overlay{RoundedRectangle(cornerRadius:6).stroke(border)}.accessibilityIdentifier("rpgContinue")}
            }.padding(.horizontal,12).padding(.top,4).padding(.bottom,12).environment(\.layoutDirection,run.target == "ar" ? .rightToLeft:.leftToRight).background{GeometryReader{geometry in Color.clear.preference(key:RPGDialogueHeight.self,value:geometry.size.height)}}}.frame(height:min(max(44,dialogueContentHeight),max(44,heightLimit-36))).onPreferenceChange(RPGDialogueHeight.self){value in if abs(value-dialogueContentHeight)>0.5{dialogueContentHeight=value}}.scrollIndicators(.hidden)
        }.background(paper,in:RoundedRectangle(cornerRadius:12)).clipShape(RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(border,lineWidth:2)}.shadow(color:.black.opacity(0.25),radius:18,y:12)
    }
    private func speechControls(_ run:RPGRun,node:RPGNode)->some View {
        VStack(alignment:.leading,spacing:8){
            Text("💡 "+t("speechIdea")+": "+(node.speechExample ?? node.expectedAnswer)).font(PiyaliBrand.productFont(12)).foregroundStyle(PiyaliBrand.unitColor("8a745c"))
            HStack{Spacer();Button{narration.stopAll();if speech.recording{speech.stop()}else{answer="";speechArmed=true;Task{await speech.start(language:run.target)}}}label:{Image(systemName:speech.recording ? "stop.fill":"mic.fill").font(.system(size:16)).foregroundStyle(.white).frame(width:32,height:32).background(PiyaliBrand.unitColor("319795"),in:RoundedRectangle(cornerRadius:6))}.disabled(service.busy).accessibilityLabel(t(speech.recording ? "micStop":"micStart")).accessibilityIdentifier("rpgMicrophone").contextMenu{Button(t("response")){typedReply=true}}}
            if !answer.isEmpty{Text(t("heardYou")+": "+answer).font(PiyaliBrand.productFont(12))}
            if typedReply{TextField(t("response"),text:$answer).font(PiyaliBrand.productFont(16)).textFieldStyle(.roundedBorder).focused($focused).submitLabel(.send).onSubmit{sendSpeech()}.accessibilityIdentifier("rpgReply");Button(t("continue")){sendSpeech()}.disabled(answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || service.busy).accessibilityIdentifier("rpgSend")}
        }
    }
    private func completion(_ run:RPGRun)->some View {ZStack{(light ? PiyaliBrand.unitColor("4c3c28").opacity(0.24):Color.black.opacity(0.8));VStack(spacing:16){Text(run.scenario.storyTitle ?? "Congratulations! You've completed the review.").font(PiyaliBrand.productFont(20,700));if let epilogue=run.scenario.storyEpilogue{Text(epilogue["target"].string).font(PiyaliBrand.productFont(14));Text(epilogue["support"].string).font(PiyaliBrand.productFont(12)).italic()};Text(String(repeating:"★",count:run.stars)).font(.system(size:30)).foregroundStyle(.yellow);Text("\(Int((Double(run.score)/800*100).rounded()))%").font(PiyaliBrand.productFont(18,700));FocusWaveBar(percent:Double(run.score)/8,height:12)
        if tutor || run.tutorial == true || run.lessonID != nil{Button(t("continue")){if tutor{onTutorComplete?()}else if run.tutorial == true{onTutorialComplete?()}else{_=app.learner.completeRPG(run);app.persist();if let onReviewComplete{onReviewComplete()}else{dismiss()}}}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,20).padding(.vertical,10).overlay{RoundedRectangle(cornerRadius:6).stroke(ink)}.accessibilityIdentifier(tutor ? "tutorGameComplete":"rpgComplete").disabled(run.claimed)}else{HStack{Button(t("playAgain")){fresh()};Button(t("newWorld")){dismiss()}}}
    }.padding(32).frame(maxWidth:400).foregroundStyle(light ? ink:.white).background(light ? paper:PiyaliBrand.unitColor("0b1220"),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(light ? border:PiyaliBrand.unitColor("ecc94b"),lineWidth:3)}.padding(16).multilineTextAlignment(.center)}}
    private var replyInk:Color{PiyaliBrand.unitColor(light ? "9b5d2d":"c05621")}
    private var panelFrame:Color{PiyaliBrand.unitColor(light ? "604d38":"94a3b8").opacity(light ? 0.3:0.42)}
    private func customize(_ key:String)->String{RPGArt.shared.data["customize"][app.learner.support][key].string}
    private func modal(_ run:RPGRun)->some View {
        let companion=panel == "companion",rtl=run.support == "ar"
        let bg=companion && !light ? PiyaliBrand.unitColor("0b1220"):paper
        return ZStack {
            (companion ? (light ? PiyaliBrand.unitColor("4c3c28").opacity(0.36):Color.black.opacity(0.64)):(light ? PiyaliBrand.unitColor("1c140c").opacity(0.82):PiyaliBrand.unitColor("020617").opacity(0.92))).ignoresSafeArea().onTapGesture{panel=""}
            VStack(alignment:.leading,spacing:0){
                Text(companion ? customize("companion"):panel == "quest" ? RPGArt.shared.quest("title",lang:run.support):t("inventory"))
                    .font(PiyaliBrand.productFont(companion ? 20:16,700)).foregroundStyle(companion ? (light ? ink:.white):replyInk)
                    .frame(maxWidth:.infinity,alignment:rtl && !companion ? .trailing:.leading).frame(height:companion ? 30:24).padding(.horizontal,32).padding(.vertical,28)
                VStack(alignment:.leading,spacing:companion ? 16:12){
                    if panel == "quest"{
                        HStack{Text(RPGArt.shared.quest("currentTask",lang:run.support)).fontWeight(.semibold);Spacer();Text(RPGArt.shared.quest("progress",lang:run.support,[String(run.stepIndex),String(run.scenario.quest.steps.count)])).fontWeight(.bold).foregroundStyle(replyInk)}.font(PiyaliBrand.productFont(12)).padding(.horizontal,12).padding(.vertical,8).background(light ? PiyaliBrand.unitColor("f9f0dd"):PiyaliBrand.unitColor("fffaf0"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(border.opacity(0.52))}
                        HStack(alignment:.top,spacing:12){Text("1.").fontWeight(.bold).foregroundStyle(replyInk);Text(run.step.map{step in RPGArt.shared.quest(step.nodes.first?.responseMode == "speech" ? "speechTask":"choiceTask",lang:run.support,[run.npc?.name ?? ""])} ?? RPGArt.shared.quest("complete",lang:run.support)).frame(maxWidth:.infinity,alignment:rtl ? .trailing:.leading).multilineTextAlignment(rtl ? .trailing:.leading)}.font(PiyaliBrand.productFont(14)).padding(.horizontal,12).padding(.vertical,8).background(light ? PiyaliBrand.unitColor("fffdf9"):Color.white.opacity(0.92),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(border.opacity(0.52))}
                    }else if panel == "inventory"{
                        Text(t("noItems")).font(PiyaliBrand.productFont(14)).foregroundStyle(PiyaliBrand.unitColor(light ? "6b553f":"4a5568")).frame(maxWidth:.infinity,minHeight:53)
                    }else{
                        Text(customize("rpgDescription")).font(PiyaliBrand.productFont(14)).foregroundStyle(PiyaliBrand.unitColor(light ? "6b553f":"cbd5e0")).lineSpacing(4).fixedSize(horizontal:false,vertical:true)
                        LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12){ForEach(CompanionTypes.ordered,id:\.self){value in
                            let allowed=CompanionTypes.effective(value,level:app.learner.companionLevel) == value,level=CompanionTypes.unlocks[value,default:1],active=value == pet
                            let levelText=level<=1 ? customize("starter"):customize("unlockLevel").replacingOccurrences(of:"{level}",with:String(level))
                            Button{selectedPet=value;panel=""}label:{VStack(spacing:4){RPGPetPreview(pet:value,size:62,animated:true);Text(customize(value)).font(PiyaliBrand.productFont(14,700));HStack(spacing:4){if !allowed{Image(systemName:"lock").font(.system(size:10))};Text(allowed ? levelText:customize("locked")+" · "+levelText).font(PiyaliBrand.productFont(10,700))}.foregroundStyle(PiyaliBrand.unitColor(allowed ? (light ? "285e61":"b2f5ea"):(light ? "c05621":"faf089"))) }.frame(maxWidth:.infinity).frame(height:132).background(active ? PiyaliBrand.unitColor("3f9f9b").opacity(0.12):.clear,in:Capsule()).overlay{Capsule().stroke(active ? PiyaliBrand.unitColor(light ? "319795":"81e6d9"):(light ? border.opacity(0.52):Color.white.opacity(0.24)),lineWidth:2)}.opacity(allowed ? 1:(light ? 0.58:0.46))}.buttonStyle(RPGPetChoiceStyle()).disabled(!allowed).accessibilityLabel(customize(value)+", "+(allowed ? "":customize("locked")+", ")+levelText).accessibilityIdentifier("rpgPet-"+value)
                        }}.foregroundStyle(light ? ink:.white)
                    }
                }.padding(.horizontal,28).padding(.top,28).padding(.bottom,28)
            }.background(bg,in:RoundedRectangle(cornerRadius:48,style:.continuous)).overlay{RoundedRectangle(cornerRadius:48,style:.continuous).strokeBorder(panelFrame,lineWidth:3)}
                .overlay(alignment:.topTrailing){if !companion{Button{panel=""}label:{Image(systemName:"xmark").font(.system(size:14,weight:.semibold)).frame(width:32,height:32)}.foregroundStyle(PiyaliBrand.unitColor(light ? "8a745c":"4a5568")).padding(20).accessibilityLabel(t("closeDialogue")).accessibilityIdentifier("rpgPanelClose")}}
                .padding(.horizontal,companion ? 16:9)
        }.environment(\.layoutDirection,.leftToRight)
    }
    private func tile(_ point:RPGPoint){guard let run,!talking,!run.completed,!service.busy,panel.isEmpty else{return};if let object=observations.hit(point){observations.examine(object);return};if let index=run.scenario.npcs.firstIndex(where:{$0.tx == point.x && $0.ty == point.y}){guard index == run.step?.npcIdx else{return};if abs(run.position.x-point.x)+abs(run.position.y-point.y)<=1{talking=true;translation=[];answer="";play(run.node?.npcLine ?? "",target:run.target);return}};let movement=RPGSpatial.step(from:run.position,toward:point,world:run.world,npcs:run.scenario.npcs);if movement.moved{change{$0.position=movement.position;$0.updatedAt=Date()}}}
    private func change(_ action:(inout RPGRun)->Void){guard !service.busy,var value=run else{return};action(&value);app.learner.saveRPG(value);app.persist()}
    private func closeDialogue(){speechArmed=false;narration.stopAll();speech.stopAll();talking=false;dialogueContentHeight=0;typedReply=false;answer="";translation=[];focused=false;showExample=false}
    private func fresh(){closeDialogue();Task{await service.prepare(app,lesson:lesson,episode:episode,fresh:true,tutor:tutor)}}
    private func sendSpeech(){let text=answer.trimmingCharacters(in:.whitespacesAndNewlines);guard !text.isEmpty,!service.busy else{return};speechArmed=false;speech.stopAll();narration.stopAll();focused=false;Task{await service.speak(text,app:app);if let value=run{play(value.feedback,target:value.target)}}}
    private func play(_ text:String,target:String){guard !Self.fixture else{return};let character=RPGArt.shared.data["voices"][run?.npc?.characterKind ?? "frog"],voice=character["voice"].string.isEmpty ? "ash":character["voice"].string;let session=try? app.companionQuestPolicy?.run("ph_tts",.object(["language":.string(target),"voice":.string(voice),"personality":character["personality"]]));narration.play(RPGDialogue.split(text).spoken,language:target,engine:app.companionQuestPolicy,voice:voice,sessionOverride:session)}
    private func translate(_ run:RPGRun,node:RPGNode){if !translation.isEmpty{translation=[];return};guard !translating else{return};translating=true;let id=run.id,step=run.stepIndex,scope=self.scope;Task{let result=await service.translate(run:run,app:app);guard self.scope == scope,self.run?.id == id,self.run?.stepIndex == step,talking else{translating=false;return};translation=result ?? [];translating=false}}
    private func configureObjects(){
        guard let run,let policy=try? RPGObjectPolicy() else{return}
        let review:JSONValue
        if run.tutorial == true{review=app.introLibrary?.games[run.scenario.authoredEpisode.level]?.context ?? .null}
        else if let id=run.lessonID,let value=service.library?.reviews[id]?.context{review=value}
        else{review=(try? policy.run("review",.object(["lesson":lesson.map(PracticeCurriculum.lessonData) ?? .null,"target":.string(run.target),"level":.string(run.scenario.authoredEpisode.level)]))) ?? .null}
        let map=RPGArt.shared.map(run.scenario)
        let parameters:JSONValue = .object(["scenarioID":.string(run.scenario.id),"map":map,"target":.string(run.target),"support":.string(run.support),"level":.string(run.scenario.authoredEpisode.level),"reviewContext":review,"user":app.learner.rpgObjectUser,"objects":(try? JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(run.world.objects))) ?? .array([])])
        observations.configure(scope:scope+":"+run.id.uuidString,parameters:parameters,objects:run.world.objects){prompt in
            if Self.fixture{throw URLError(.notConnectedToInternet)}
            return try await app.ai.responsesText(prompt)
        }
    }
    private func startMusic(){
        guard run?.completed != true else{music.stop();return}
        let snapshot=app.learner.settingsSnapshot
        let validFlag:Bool;if case .bool = snapshot["rpgMusicEnabled"]{validFlag=true}else{validFlag=false}
        if snapshot["rpgMusicPreferenceVersion"] != .number(2) || !validFlag{app.updateSettings(.object(["rpgMusicEnabled":.bool(false),"rpgMusicPreferenceVersion":.number(2)]))}
        music.apply(app.learner.settingsSnapshot["rpgMusicEnabled"].boolean)
    }
    private func stop(clearObservations:Bool=true){if clearObservations{observations.cancel()};speechArmed=false;service.cancel();speech.stopAll();narration.stopAll();music.stop();focused=false}
    private static var fixture:Bool {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment;return env["PIYALI_OFFLINE_TESTS"] == "1" && UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil
        #else
        return false
        #endif
    }
}

private struct RPGDialogueHeight:PreferenceKey {static var defaultValue:CGFloat=0;static func reduce(value:inout CGFloat,nextValue:()->CGFloat){value=max(value,nextValue())}}
private struct RPGPetChoiceStyle:ButtonStyle {func makeBody(configuration:Configuration)->some View{configuration.label.opacity(configuration.isPressed ? 0.85:1)}}
