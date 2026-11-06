import SwiftUI

/// Shared bottom Help drawer for the root product and authored games.
struct HelpChatView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @ObservedObject var controller:HelpChatController
    @StateObject private var live=LiveTutorService()
    @StateObject private var narration=RealtimeNarrationService()
    @StateObject private var voiceDeadline=HelpChatVoiceDeadline()
    var progress:JSONValue?=nil
    let onClose:()->Void
    @State private var input=""
    @State private var sidebar=false
    @State private var replaying:String?
    @State private var audioGeneration=UUID()
    @State private var viewportWidth:CGFloat=402
    @FocusState private var focused:Bool
    private var light:Bool{scheme != .dark}
    private var brand:PiyaliBrand{.init(dark:!light)}
    private var snapshot:JSONValue{progress ?? app.learner.recipeUser["progress"].setting("targetLang",.string(app.learner.target)).setting("supportLang",.string(app.learner.support)).setting("level",.string(app.learner.level)).setting("helpRequest",app.learner.settingsSnapshot["progress"]["helpRequest"])}
    private var scope:String{app.identity.npub+snapshot.canonicalJSON+app.learner.support}
    private var voiceBusy:Bool{live.connected || live.connecting}
    private func c(_ hex:String)->Color{PiyaliBrand.unitColor(hex)}
    private func gray(_ shade:Int)->Color{c((light ? [100:"2f261d",500:"9b8875",600:"c5b19c",700:"e0d2bf",800:"f1e8dc",900:"fbf7f0"]:[100:"e5e7eb",500:"879bb4",600:"334155",700:"1f2937",800:"111827",900:"0b1220"])[shade] ?? "879bb4")}
    private func t(_ key:String)->String{controller.copy(key)}
    init(controller:HelpChatController,progress:JSONValue?=nil,initialSidebar:Bool=false,onClose:@escaping()->Void){self.controller=controller;self.progress=progress;self.onClose=onClose;_sidebar=State(initialValue:initialSidebar)}
    var body:some View {
        GeometryReader{g in
            ZStack(alignment:.bottom){
                Color.clear.contentShape(Rectangle()).ignoresSafeArea().onTapGesture(perform:onClose)
                VStack(spacing:0){
                    Capsule().fill((light ? c("2f261d"):Color.white).opacity(0.24)).frame(width:52,height:5).padding(.top,12).padding(.bottom,8)
                    header
                    content

                    if let error=live.error ?? narration.error{Text(error).font(.system(size:12)).padding(8).accessibilityIdentifier("helpAudioError")}
                }.frame(height:g.size.height*0.9).frame(maxWidth:.infinity).background(gray(900),in:MemoryDrawerShape(radius:48)).overlay{MemoryDrawerShape(radius:48).stroke(c(light ? "604d38":"94a3b8").opacity(light ? 0.3:0.42),lineWidth:3).padding(1.5).padding(.bottom,-3).allowsHitTesting(false)}.foregroundStyle(gray(100)).accessibilityElement(children:.contain).accessibilityIdentifier("helpDrawer").accessibilityHidden(sidebar)
                    .gesture(DragGesture(minimumDistance:30).onEnded{value in if value.startLocation.y < 28,value.translation.height>70{onClose()}})
                if sidebar{Color.clear.contentShape(Rectangle()).ignoresSafeArea().onTapGesture{sidebar=false};sideMenu.frame(width:min(280,g.size.width),height:g.size.height).frame(maxWidth:.infinity,alignment:.leading)}
                if let notice=controller.notice{HStack(spacing:12){Image(systemName:controller.noticeKind == "success" ? "checkmark.circle.fill":controller.noticeKind == "error" ? "exclamationmark.circle.fill":"info.circle.fill").font(.system(size:20));Text(notice).font(.system(size:16,weight:.bold)).frame(maxWidth:.infinity,alignment:.leading)}.padding(16).frame(maxWidth:min(300,g.size.width-24)).background(c(controller.noticeKind == "success" ? "2f855a":controller.noticeKind == "error" ? "c53030":"2b6cb0"),in:RoundedRectangle(cornerRadius:6)).foregroundStyle(.white).shadow(color:.black.opacity(0.15),radius:15,y:8).padding(.bottom,8).accessibilityIdentifier("helpNotice").onTapGesture{controller.notice=nil}}
            }.frame(width:g.size.width,height:g.size.height).onGeometryChange(for:CGFloat.self,of:{$0.size.width}){viewportWidth=$0}
        }.ignoresSafeArea(.container).environment(\.layoutDirection,.leftToRight).buttonStyle(HelpButtonStyle()).accessibilityElement(children:.contain).accessibilityAddTraits(.isModal)
            .task(id:scope){stopAudio();controller.configure(account:app.identity.npub,progress:snapshot,appLanguage:app.learner.support)}
            .onChange(of:phase){_,p in if p != .active{stopAudio()}}
            .onChange(of:app.subscription.hasAccess){_,allowed in if !allowed{controller.stop();stopAudio()}}
            .onChange(of:narration.playing){_,playing in if !playing && !narration.loading{replaying=nil}}
            .onDisappear{controller.stop();stopAudio()}
    }
    @ViewBuilder private var content:some View {
        if controller.messages.isEmpty{
            VStack(spacing:24){Text(t("emptyPrompt")).font(.system(size:20,weight:.medium)).padding(.vertical,max(0,30-UIFont.systemFont(ofSize:20,weight:.medium).lineHeight)/2).multilineTextAlignment(.center).accessibilityIdentifier("helpEmptyPrompt");composer.padding(.horizontal,16)}.padding(.horizontal,16).frame(maxWidth:.infinity,maxHeight:.infinity)
        }else{
            ScrollViewReader{proxy in
                ScrollView{LazyVStack(alignment:.leading,spacing:24){ForEach(controller.messages){message in row(message).id(message.id)};if voiceBusy,!live.assistantTurnText.isEmpty,controller.messages.last?.text != live.assistantTurnText{HelpMarkdown(text:live.assistantTurnText).id("live")}}.padding(16)}
                    .onChange(of:controller.messages){_,_ in if let id=controller.messages.last?.id{proxy.scrollTo(id,anchor:.bottom)}}
            }
            composer.padding(16).overlay(alignment:.top){Rectangle().fill(gray(800)).frame(height:1)}
        }
    }
    private var header:some View {
        HStack(spacing:12){
            Button{focused=false;sidebar=true}label:{HelpIcon(name:"bars",size:14).frame(width:32,height:32).contentShape(Rectangle())}.accessibilityLabel(t("menu")).accessibilityIdentifier("helpMenu")
            if controller.morphemes{Text(t("morphemes")).font(.system(size:12,weight:.bold)).padding(.horizontal,4).background(c("44337a")).foregroundStyle(c("e9d8fd"))}
            Spacer(minLength:0)
            Button{controller.save()}label:{HStack(spacing:8){HelpIcon(name:"save",size:14);Text(t("saveChat")).font(.system(size:14,weight:.semibold))}.padding(.horizontal,12).frame(height:32).contentShape(Rectangle())}.disabled(controller.messages.isEmpty).opacity(controller.messages.isEmpty ? 0.6:1).accessibilityIdentifier("helpSave")
            Button(action:onClose){MemoryIcon(name:"close",size:18).frame(width:32,height:32).contentShape(Rectangle()).overlay{Circle().stroke(.white)}}.accessibilityLabel(EntryCopy.ui(app.learner.support,"close")).accessibilityIdentifier("helpClose").padding(.trailing,8)
        }.padding(.horizontal,16).padding(.vertical,12).padding(.bottom,1).overlay(alignment:.bottom){Rectangle().fill(gray(800)).frame(height:1)}
    }
    private var composer:some View {
        HStack(alignment:.bottom,spacing:8){
            Button(action:toggleVoice){Group{if live.connecting{ProgressView().controlSize(.mini)}else if live.connected{HelpVoiceWave(level:live.voiceState == "listening" ? live.audioLevel:0)}else{HelpIcon(name:"microphone",size:14)}}.frame(width:32,height:32).contentShape(Rectangle()).background(live.connected ? c("319795"):.clear,in:Circle()).foregroundStyle(live.connected ? .white:gray(100))}.disabled(live.connecting || controller.busy).accessibilityLabel(t(live.connected ? "stopVoiceChat":"startVoiceChat")).accessibilityIdentifier("helpVoice")
            TextField("",text:$input,axis:.vertical).lineLimit(1...5).font(.system(size:16)).frame(minHeight:40).focused($focused).foregroundStyle(light ? brand.text:gray(100)).disabled(live.connected).submitLabel(.send).onSubmit(send).accessibilityLabel(t("askPlaceholder")).accessibilityIdentifier("assistantInput")
            Button{if controller.busy{controller.stop()}else{send()}}label:{HelpIcon(name:controller.busy ? "stop":"send",size:14).frame(width:32,height:32).contentShape(Rectangle()).foregroundStyle(sendInk).background(sendBackground,in:Circle()).shadow(color:!controller.busy && !empty ? (light ? c("0b5d57"):.gray):.clear,radius:0,y:4)}.disabled(!controller.busy && (input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || live.connected)).accessibilityLabel(t(controller.busy ? "stop":"send")).accessibilityIdentifier("helpSend")
        }.padding(9).background(light ? brand.surface:gray(800),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(light ? brand.border:gray(700))}
    }
    private var empty:Bool{input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || live.connected}
    private var sendInk:Color{controller.busy ? gray(100):(empty ? (light ? c("0f766e").opacity(0.54):c("6b7280")):(light ? c("fffaf3"):gray(900)))}
    private var sendBackground:Color{controller.busy ? gray(800):(empty ? (light ? c("0f766e").opacity(0.18):c("e5e7eb")):(light ? c("0f766e"):.white))}
    private func row(_ message:HelpChatMessage)->some View {
        HStack(alignment:.top,spacing:12){
            if message.role == "user"{Spacer(minLength:max(0,(viewportWidth-32)*0.2));HelpMarkdown(text:message.text,expand:false).padding(.horizontal,16).padding(.vertical,12).background(light ? c("6c5842"):gray(700),in:RoundedRectangle(cornerRadius:40)).foregroundStyle(light ? c("fffaf3"):.white).shadow(color:light ? c("6f5636").opacity(0.14):.clear,radius:10,y:10)}
            else{
                Button{play(message)}label:{Group{if replaying == message.id,narration.loading{ProgressView().controlSize(.mini)}else{HelpIcon(name:"volume",size:14)}}.frame(width:24,height:24).contentShape(Rectangle())}.padding(.top,4).disabled(message.text.isEmpty).accessibilityLabel(t("play")).accessibilityIdentifier("helpPlay-"+message.id)
                let split=(try? controller.run("split",.object(["text":.string(message.text)]))) ?? .object(["main":.string(message.text)])
                VStack(alignment:.leading,spacing:0){if !message.done && split["main"].string.isEmpty{Text("...").accessibilityLabel("Loading")};HelpMarkdown(text:split["main"].string);if !split["gloss"].string.isEmpty{HelpMarkdown(text:split["gloss"].string,size:14,paragraphBottom:0).opacity(0.7).padding(.leading,14).overlay(alignment:.leading){Rectangle().fill(gray(700)).frame(width:2)}.padding(.bottom,8)}}.frame(maxWidth:.infinity,alignment:.leading)
            }
        }.accessibilityIdentifier("helpMessage-"+message.id)
    }
    private var sideMenu:some View {
        VStack(alignment:.leading,spacing:0){
            Text(t("menu")).font(.system(size:14,weight:.semibold)).frame(height:21).padding(.horizontal,32).padding(.vertical,28).frame(maxWidth:.infinity,alignment:.leading).overlay(alignment:.bottom){Rectangle().fill(gray(800)).frame(height:1)}
            VStack(alignment:.leading,spacing:16){
                VStack(alignment:.leading,spacing:8){
                    Text(t("yourChats")).font(.system(size:12,weight:.bold)).frame(height:18).foregroundStyle(gray(500))
                    ScrollView{VStack(spacing:4){if controller.saved.isEmpty{Text(t("noSavedChats")).font(.system(size:12)).foregroundStyle(gray(600)).padding(.vertical,16).frame(maxWidth:.infinity)};ForEach(controller.saved){chat in savedRow(chat)}}}
                }
                Rectangle().fill(gray(700)).frame(height:1)
                HStack(spacing:8){VStack(alignment:.leading,spacing:0){Text(t("morphemeMode")).font(.system(size:14,weight:.medium)).frame(height:21);Text(t("breakDownWords")).font(.system(size:12)).frame(height:18).foregroundStyle(gray(500))}.frame(maxWidth:.infinity,alignment:.leading).contentShape(Rectangle()).onTapGesture{controller.setMorphemes(!controller.morphemes)};HelpSourceSwitch(label:t("morphemeMode"),isOn:Binding(get:{controller.morphemes},set:controller.setMorphemes),off:light ? c("5b4b3a"):c("b7c5d8")).accessibilityIdentifier("helpMorphemeMode")}.padding(13).background(gray(800),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(gray(700))}
                Button{stopAudio();controller.newChat();input="";sidebar=false}label:{HStack(spacing:8){HelpIcon(name:"plus",size:14);Text(t("newChat")).font(.system(size:14,weight:.semibold))}.frame(maxWidth:.infinity,minHeight:66).background(light ? brand.surface:.clear,in:Capsule()).overlay{Capsule().stroke(gray(600))}}.accessibilityIdentifier("helpNewChat").padding(.bottom,24)
            }.padding(28)
        }.background(gray(900),in:MemoryDrawerShape(radius:48)).overlay{MemoryDrawerShape(radius:48).stroke(c(light ? "604d38":"94a3b8").opacity(light ? 0.3:0.42),lineWidth:3).padding(1.5).padding(.bottom,-3).allowsHitTesting(false)}.foregroundStyle(gray(100)).accessibilityElement(children:.contain).accessibilityIdentifier("helpSidebar")
    }
    private func savedRow(_ chat:SavedHelpChat)->some View {
        HStack(spacing:8){Button{stopAudio();controller.load(chat);input="";sidebar=false}label:{HStack(spacing:8){Text(((try? controller.run("badge",.object(["target":.string(chat.targetLang)]))) ?? .object(["label":.string("ES")]))["label"].string).font(.system(size:9,weight:.bold)).foregroundStyle(.white).padding(.horizontal,6).padding(.vertical,2).background(badge(chat.targetLang),in:RoundedRectangle(cornerRadius:2));Text(chat.title).font(.system(size:14)).frame(minHeight:21).lineLimit(1);Spacer(minLength:0)}}.accessibilityIdentifier("helpLoad-"+chat.id);Button{controller.delete(chat.id)}label:{HelpIcon(name:"trash",size:10).foregroundStyle(gray(100).opacity(0.5)).frame(width:24,height:24).contentShape(Rectangle())}.accessibilityLabel(t("delete")).accessibilityIdentifier("helpDelete-"+chat.id)}.padding(8)
    }
    private func badge(_ target:String)->Color{let token=(try? controller.run("badge",.object(["target":.string(target)]))["bg"].string) ?? "yellow.500";return token.hasPrefix("var(") ? gray(500):c(["yellow.500":"d69e2e","blue.600":"2b6cb0","green.600":"2f855a","purple.600":"6b46c1","orange.600":"c05621","orange.500":"dd6b20","red.600":"c53030","orange.400":"ed8936","teal.600":"2c7a7b","cyan.600":"0987a0","blue.400":"4299e1","pink.600":"b83280","green.500":"38a169","purple.500":"805ad5"][token] ?? "d69e2e")}
    private func send(){guard app.subscription.hasAccess,!voiceBusy else{return};let text=input;guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return};input="";focused=false;controller.send(text,provider:.native(app.ai))}
    private func stopAudio(){audioGeneration=UUID();voiceDeadline.cancel();narration.stopAll();replaying=nil;Task{await live.stop()}}
    private func toggleVoice(){
        if voiceBusy{stopAudio();return};guard app.subscription.hasAccess,!controller.busy else{return};narration.stopAll();focused=false
        guard let session=try? controller.run("session") else{return};let token=UUID(),owner=scope;audioGeneration=token
        Task{guard audioGeneration == token,scope == owner else{return};await live.start(learner:app.learner,instructions:session["instructions"].string,openingPrompt:nil,inactivityTimeout:0,onInputTurn:{input in guard audioGeneration == token,scope == owner else{return};controller.voiceInput(input)},onAssistantTurn:{id,text in guard audioGeneration == token,scope == owner else{return};controller.voiceReply(id,text:text)},sessionConfiguration:session,onEvent:{event in guard audioGeneration == token,scope == owner else{return};voiceDeadline.receive(event)});if live.connected,audioGeneration == token{voiceDeadline.begin{stopAudio()}}}
    }
    private func play(_ message:HelpChatMessage){if replaying == message.id{narration.stopAll();replaying=nil;return};replaying=message.id;narration.play(message.text,language:app.learner.target,engine:app.companionQuestPolicy,onFinished:{replaying=nil})}
}
struct HelpIcon:View {
    let name:String,size:CGFloat
    var body:some View{if name == "stop"{RoundedRectangle(cornerRadius:2).frame(width:10,height:10)}else{Image("Help-"+name).renderingMode(.template).resizable().scaledToFit().frame(width:size,height:size)}}
}
private struct HelpMarkdown:View {
    let text:String
    var size:CGFloat=16
    var paragraphBottom:CGFloat=8
    var expand=true
    private struct Block {var kind:String;var lines:[String]}
    private var blocks:[Block] {
        let lines=text.components(separatedBy:"\n");var result:[Block]=[],i=0
        while i<lines.count {
            let line=lines[i],trim=line.trimmingCharacters(in:.whitespaces)
            if trim.isEmpty{i += 1;continue}
            if trim.hasPrefix("```"){i += 1;var code:[String]=[];while i<lines.count && !lines[i].hasPrefix("```"){code.append(lines[i]);i += 1};result.append(.init(kind:"code",lines:code));i += 1;continue}
            if i+1<lines.count,line.contains("|"),lines[i+1].contains("-"),lines[i+1].replacingOccurrences(of:"|",with:"").replacingOccurrences(of:":",with:"").trimmingCharacters(in:.whitespaces).allSatisfy({$0 == "-" || $0 == " "}){var table=[line];i += 2;while i<lines.count && lines[i].contains("|"){table.append(lines[i]);i += 1};result.append(.init(kind:"table",lines:table));continue}
            if trim.hasPrefix("### "){result.append(.init(kind:"h3",lines:[String(trim.dropFirst(4))]))}
            else if trim.hasPrefix("## "){result.append(.init(kind:"h2",lines:[String(trim.dropFirst(3))]))}
            else if trim.hasPrefix("# "){result.append(.init(kind:"h1",lines:[String(trim.dropFirst(2))]))}
            else if trim.hasPrefix("- ") || trim.hasPrefix("* "){result.append(.init(kind:"bullet",lines:[String(trim.dropFirst(2))]))}
            else if let range=trim.range(of:#"^\d+\. "#,options:.regularExpression){result.append(.init(kind:"ordered",lines:[String(trim[range]),String(trim[range.upperBound...])]))}
            else if trim.hasPrefix(">"){result.append(.init(kind:"quote",lines:[String(trim.dropFirst()).trimmingCharacters(in:.whitespaces)]))}
            else if trim == "---" || trim == "***"{result.append(.init(kind:"rule",lines:[]))}
            else if result.last?.kind == "p",i>0,!lines[i-1].trimmingCharacters(in:.whitespaces).isEmpty{result[result.count-1].lines.append(line)}
            else{result.append(.init(kind:"p",lines:[line]))};i += 1
        };return result
    }
    private func inline(_ text:String,_ font:Font?=nil,metricsSize:CGFloat?=nil)->some View{let point=metricsSize ?? size,leading=max(0,point*1.5-UIFont.systemFont(ofSize:point).lineHeight);return Text((try? AttributedString(markdown:"\u{202A}"+text+"\u{202C}",options:.init(interpretedSyntax:.inlineOnlyPreservingWhitespace))) ?? AttributedString(text)).font(font ?? .system(size:size)).lineSpacing(leading).padding(.vertical,leading/2).frame(maxWidth:expand ? .infinity:nil,alignment:.leading).textSelection(.enabled).fixedSize(horizontal:false,vertical:true)}
    var body:some View {
        VStack(alignment:.leading,spacing:0){ForEach(Array(blocks.enumerated()),id:\.offset){_,b in
            Group{switch b.kind {
            case "code":ScrollView(.horizontal){Text(b.lines.joined(separator:"\n")).font(.system(size:size*0.95,design:.monospaced)).padding(12)}.background(PiyaliBrand.unitColor("111827"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(PiyaliBrand.unitColor("374151"))}
            case "h1","h2","h3":inline(b.lines.joined(separator:" "),.system(size:b.kind == "h1" ? 30:b.kind == "h2" ? 24:20,weight:.bold),metricsSize:b.kind == "h1" ? 30:b.kind == "h2" ? 24:20).padding(.top,12)
            case "bullet":HStack(alignment:.top,spacing:8){Text("•").frame(width:12);inline(b.lines[0])}.padding(.leading,20)
            case "ordered":HStack(alignment:.top,spacing:4){Text(b.lines[0]);inline(b.lines[1])}.padding(.leading,20)
            case "quote":inline(b.lines.joined(separator:" ")).padding(.leading,12).overlay(alignment:.leading){Rectangle().fill(PiyaliBrand.unitColor("4b5563")).frame(width:3)}
            case "rule":Rectangle().fill(PiyaliBrand.unitColor("374151")).frame(height:1).padding(.vertical,12)
            case "table":ScrollView(.horizontal){VStack(alignment:.leading,spacing:0){ForEach(Array(b.lines.enumerated()),id:\.offset){row,line in HStack(alignment:.top,spacing:12){ForEach(Array(line.trimmingCharacters(in:CharacterSet(charactersIn:"|")).components(separatedBy:"|").enumerated()),id:\.offset){_,cell in inline(cell.trimmingCharacters(in:.whitespaces),.system(size:size,weight:row == 0 ? .bold:.regular)).frame(minWidth:100,alignment:.leading)}}.padding(.vertical,4).overlay(alignment:.bottom){Rectangle().fill(PiyaliBrand.unitColor("374151")).frame(height:1)}}}}
            default:inline(b.lines.joined(separator:" "))
            }}.padding(.bottom,b.kind == "bullet" || b.kind == "ordered" ? 0:paragraphBottom)
        }}
    }
}

private struct HelpVoiceWave:View {
    let level:Double
    @State private var levels=[0.0,0,0,0]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body:some View{TimelineView(.animation(minimumInterval:1/40,paused:reduceMotion)){time in Canvas{context,size in for i in 0..<4{let height=14*[0.45,1,0.75,0.45][i]*(0.28+levels[i]*1.05),rect=CGRect(x:Double(i)*4,y:(14-height)/2,width:2,height:height);context.fill(Path(roundedRect:rect,cornerRadius:1),with:.color(.white.opacity(0.65+levels[i]*0.35)))}}.onChange(of:time.date){_,_ in for i in 0..<4{let target=min(1,max(0,level)*[0.85,1.25,1.05,0.75][i]);levels[i]=target>levels[i] ? levels[i]+(target-levels[i])*0.7:levels[i]*0.8}}}.frame(width:14,height:14).accessibilityHidden(true)}
}

private struct HelpButtonStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View{configuration.label.opacity(configuration.isPressed ? 0.8:1)}
}
private struct HelpSourceSwitch:View {
    let label:String
    @Binding var isOn:Bool
    let off:Color
    var body:some View{Button{isOn.toggle()}label:{Capsule().fill(isOn ? PiyaliBrand.unitColor("805ad5"):off).frame(width:26,height:16).overlay(alignment:.leading){Circle().fill(.white).frame(width:12,height:12).offset(x:isOn ? 12:2)}.contentShape(Rectangle())}.accessibilityRepresentation{Toggle(label,isOn:$isOn)}}
}
