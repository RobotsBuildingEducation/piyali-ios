import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct VoiceJourneyView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @StateObject private var journey=VoiceJourneyController()
    @State private var recording:Int?
    @State private var confirmDelete:Int?
    var embedded=false
    private var language:String{app.learner.support}
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var count:Int{VoiceJourneyModel.count(journey.data)}
    private func t(_ key:String,_ n:Int?=nil)->String {MemoryUI.journey(language,key,values:n.map{.object(["n":.number(Double($0))])} ?? .object([:]))}
    var body:some View {
        Group{if embedded{content}else{ScrollView{content.padding(16)}.background(BrandBackground()).navigationTitle(t("journey"))}}
            .task(id:app.identity.npub+":"+app.learner.target){await journey.bind(app)}
            .onDisappear{journey.close()}
            .overlay{if let recording{JourneyRecordingView(journey:journey,milestone:recording,onClose:{self.recording=nil}).environmentObject(app)}}
            .accessibilityElement(children:.contain).accessibilityIdentifier("memoryJourney")
    }
    @ViewBuilder private var content:some View {
        if journey.loading{HStack(spacing:8){ProgressView();Text(t("loading")).font(PiyaliBrand.productFont(14))}.frame(maxWidth:.infinity).padding(.vertical,32)}
        else if journey.failed{VStack(spacing:16){Text(t("error"));Button(t("retry")){Task{await journey.bind(app)}}.buttonStyle(SessionToolButtonStyle())}.frame(maxWidth:.infinity).padding(.vertical,32)}
        else{VStack(alignment:.leading,spacing:24){
            VStack(alignment:.leading,spacing:0){OnboardingText(text:t("title"),size:20,weight:.bold,lineHeight:24);HStack{Text(t("sessions",count)).font(PiyaliBrand.productFont(14,600));Spacer();MemoryIcon(name:"mic")}.padding(.top,20).padding(.bottom,8)
                let next=VoiceJourneyModel.milestones.first{$0>count},maximum=next ?? max(150,count)
                GeometryReader{g in ZStack(alignment:.leading){brand.surface;Capsule().fill(PiyaliBrand.unitColor("319795")).frame(width:g.size.width*min(1,Double(count)/Double(maximum)))}}.frame(height:8).clipShape(Capsule())
                if next == nil{OnboardingText(text:t("allUnlocked"),size:12,lineHeight:18).foregroundStyle(brand.secondary).padding(.top,8)}
                OnboardingText(text:t("rule"),size:12,lineHeight:18).foregroundStyle(brand.muted).padding(.top,12)
                if count == 0{OnboardingText(text:t("empty"),size:14,lineHeight:21).padding(.top,12)}
            }.memoryCard(padding:16,background:MemoryPaint.surface(scheme),border:brand.border).overlay(alignment:.topTrailing){Circle().fill(PiyaliBrand.unitColor("38b2ac").opacity(0.08)).frame(width:180,height:180).offset(x:30,y:-60).allowsHitTesting(false)}.clipShape(RoundedRectangle(cornerRadius:16))
            VStack(spacing:0){ForEach(VoiceJourneyModel.milestones,id:\.self){n in milestone(n)}}
            LegacyJourneyRecordingsView().padding(.bottom,48)
        }}
    }
    private func milestone(_ n:Int)->some View {
        let saved=VoiceJourneyModel.saved(journey.data,n),ready=VoiceJourneyModel.canRecord(journey.data,n),expired=VoiceJourneyModel.expired(journey.data,n),active=journey.selected == n
        return HStack(alignment:.top,spacing:14){
            VStack(spacing:0){MemoryIcon(name:saved ? "check":ready ? "mic":"lock").foregroundStyle(saved || ready ? .white:brand.muted).frame(width:36,height:36).background(saved || ready ? PiyaliBrand.unitColor("2c7a7b"):brand.surface,in:Circle()).overlay{Circle().stroke(ready || saved ? PiyaliBrand.unitColor("319795"):brand.border)}.padding(.top,8);if n != VoiceJourneyModel.milestones.last{JourneyTimelineLine().stroke(count>=n ? PiyaliBrand.unitColor("319795").opacity(0.5):brand.border.opacity(0.5),style:StrokeStyle(lineWidth:2,dash:[4,4])).frame(width:2).frame(maxHeight:.infinity)}}.frame(width:36)
            VStack(alignment:.leading,spacing:0){
                ViewThatFits(in:.horizontal){
                    HStack(alignment:.top){milestoneHeading(n,saved:saved,ready:ready,expired:expired).fixedSize();Spacer(minLength:8);milestoneAction(n,saved:saved,ready:ready,active:active).fixedSize()}
                    VStack(alignment:.leading,spacing:8){milestoneHeading(n,saved:saved,ready:ready,expired:expired);milestoneAction(n,saved:saved,ready:ready,active:active)}
                }
                if saved{let date=WebProgressContract.date(journey.data["recordings"][String(n)]["createdAt"].string) ?? .distantPast;OnboardingText(text:date.formatted(Date.FormatStyle(calendar:CalendarDay.gregorian()).year().month(.abbreviated).day().locale(Locale(identifier:language)))+" · "+t("captured",Int(journey.data["recordings"][String(n)]["capturedSession"].number)),size:12,lineHeight:18).foregroundStyle(brand.muted).padding(.top,8)}
                if active,let current=journey.current{VStack(alignment:.leading,spacing:16){OnboardingText(text:current["prompt"].string,size:14,lineHeight:21);if let first=journey.first{OnboardingText(text:t("compare"),size:12,lineHeight:18).foregroundStyle(brand.muted);JourneyAudioView(payload:first,label:t("first"),language:language);Text(t(first["support"].string == "hints" ? "hints":"independent")).font(PiyaliBrand.productFont(12,700))};JourneyAudioView(payload:current,label:t("session",n),language:language);Text(t(current["support"].string == "hints" ? "hints":"independent")).font(PiyaliBrand.productFont(12,700))}.padding(.top,20)}
                if active,let key=journey.errorKey{Text(t(key)).font(PiyaliBrand.productFont(14)).foregroundStyle(.red).padding(.top,12)}
                if active,saved{VStack(alignment:.leading,spacing:8){if confirmDelete == n{Text(t("deleteConfirm")).font(PiyaliBrand.productFont(14));HStack{Button(t("delete")){Task{await journey.remove(n,app);confirmDelete=nil}}.foregroundStyle(.red).disabled(journey.busy).accessibilityIdentifier("journeyDeleteConfirm");Button(t("cancel")){confirmDelete=nil}.disabled(journey.busy)}}else{Button{confirmDelete=n}label:{Label(t("delete"),systemImage:"trash").font(PiyaliBrand.productFont(12,600)).foregroundStyle(brand.muted)}.accessibilityIdentifier("journeyDelete")}}.padding(.top,16)}
            }.memoryCard(padding:12,background:MemoryPaint.surface(scheme),border:ready ? PiyaliBrand.unitColor("319795"):brand.border).padding(.bottom,24).accessibilityElement(children:.contain).accessibilityIdentifier("journeyMilestone-\(n)").accessibilityValue(saved ? "Saved":ready ? "Ready":expired ? "Expired":"Locked")
        }.fixedSize(horizontal:false,vertical:true)
    }
    private func milestoneHeading(_ n:Int,saved:Bool,ready:Bool,expired:Bool)->some View {
        VStack(alignment:.leading,spacing:4){OnboardingText(text:t("session",n),size:16,weight:.semibold,lineHeight:24);OnboardingText(text:t(saved ? "saved":ready ? "ready":expired ? "expired":"locked"),size:12,lineHeight:18).foregroundStyle(brand.muted)}
    }
    @ViewBuilder private func milestoneAction(_ n:Int,saved:Bool,ready:Bool,active:Bool)->some View {
        if saved {Button{Task{await journey.listen(n,app)}}label:{HStack(spacing:8){if journey.busy,active{ProgressView()}else{MemoryIcon(name:"play")};Text(t("listen"))}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,12).frame(height:32).background{Capsule().stroke(brand.border)}}.accessibilityIdentifier("journeyListen-\(n)")}
        else if ready {Button{journey.clearSelection();if embedded{app.journeyRecording = .init(controller:journey,milestone:n,account:app.identity.npub,target:app.learner.target)}else{recording=n}}label:{Label{Text(t("record"))}icon:{MemoryIcon(name:"mic")}}.buttonStyle(JourneyButtonStyle(color:"00b5d8",edge:"086f83",small:true)).accessibilityIdentifier("journeyRecord-\(n)")}
    }

}
struct JourneyButtonStyle:ButtonStyle {
    let color:String,edge:String
    var small=false
    var large=false
    func makeBody(configuration:Configuration)->some View {configuration.label.font(PiyaliBrand.productFont(small ? 14:large ? 18:16,600)).padding(.horizontal,small ? 12:16).frame(minHeight:small ? 32:large ? 48:40).foregroundStyle(.white).background{Capsule().fill(PiyaliBrand.unitColor(color)).shadow(color:PiyaliBrand.unitColor(edge),radius:0,y:configuration.isPressed ? 1:4)}.offset(y:configuration.isPressed ? 3:0)}
}
struct JourneyRecordingView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var journey:VoiceJourneyController
    let milestone:Int,onClose:()->Void
    var onOpenJourney:(()->Void)?=nil
    @StateObject private var recorder=JourneyRecorder()
    @State private var selected=0
    @State private var height:CGFloat=530
    private var n:Int{selected == 0 ? milestone:selected}
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var saved:Bool{VoiceJourneyModel.saved(journey.data,n)}
    private var busy:Bool{recorder.starting || recorder.stopping || recorder.recording || journey.busy}
    private func t(_ key:String,_ number:Int?=nil)->String {MemoryUI.journey(app.learner.support,key,values:number.map{.object(["n":.number(Double($0))])} ?? .object([:]))}
    var body:some View {
        GeometryReader{geometry in ZStack{PiyaliBrand.unitColor(scheme == .dark ? "020617":"1c140c").opacity(scheme == .dark ? 0.92:0.82).ignoresSafeArea()
            ScrollView{VStack(alignment:.leading,spacing:0){
                OnboardingText(text:t("yourJourney"),size:24,weight:.bold,lineHeight:28.8).padding(.horizontal,32).padding(.vertical,28)
                VStack(alignment:.leading,spacing:20){
                VStack(alignment:.leading,spacing:8){Label{Text(t("session",n)+" · "+t("journey"))}icon:{MemoryIcon(name:"seedling",size:20).foregroundStyle(PiyaliBrand.unitColor("38b2ac"))}.font(PiyaliBrand.productFont(12,600)).frame(minHeight:20).foregroundStyle(brand.muted);OnboardingText(text:t("title"),size:18,weight:.bold,lineHeight:27);OnboardingText(text:t("intro"),size:14,lineHeight:21).foregroundStyle(brand.secondary)}.memoryCard(padding:20,background:MemoryPaint.surface(scheme),border:brand.border)
                SessionToolFlow(spacing:8){ForEach(VoiceJourneyModel.milestones,id:\.self){number in Button{recorder.clear();selected=number;if VoiceJourneyModel.saved(journey.data,number){Task{await journey.listen(number,app)}}}label:{HStack(spacing:3){if VoiceJourneyModel.saved(journey.data,number){Image(systemName:"checkmark").font(.system(size:10))};Text("\(number)")}.font(PiyaliBrand.productFont(12,700)).padding(.horizontal,11.5).frame(minWidth:36,minHeight:32).background(number == n ? PiyaliBrand.unitColor("14b8a6").opacity(0.08):.clear,in:Capsule()).overlay{Capsule().stroke(number == n ? PiyaliBrand.unitColor("319795"):brand.border,lineWidth:1.5)}}.disabled(number>VoiceJourneyModel.count(journey.data) || busy).opacity(number>VoiceJourneyModel.count(journey.data) ? 0.35:1)}}
                if saved{VStack(alignment:.leading,spacing:12){Label(t("saved"),systemImage:"checkmark").font(PiyaliBrand.productFont(14,600));if let current=journey.current,journey.selected == n{JourneyAudioView(payload:current,label:t("ownVoice"),language:app.learner.support)}else if journey.busy{ProgressView()}else{Button(t("listen")){Task{await journey.listen(n,app)}}}}.memoryCard(padding:16,background:MemoryPaint.surface(scheme),border:brand.border,radius:12)}
                else if let audio=recorder.draft{VStack(spacing:16){JourneyAudioView(payload:.object(["audio":.string(audio.base64EncodedString()),"mimeType":.string(recorder.mime),"duration":.number(recorder.seconds)]),label:t("preview"),language:app.learner.support);HStack(spacing:12){Button(t("again")){recorder.clear()}.buttonStyle(SessionToolButtonStyle(secondary:true));Button(t(journey.busy ? "saving":"save")){Task{if await journey.save(audio:audio,mime:recorder.mime,duration:recorder.seconds,prompt:t("prompt"),support:"independent",milestone:n,app:app){recorder.clear();await journey.listen(n,app)}}}.buttonStyle(JourneyButtonStyle(color:"319795",edge:"234e52")).disabled(journey.busy).accessibilityIdentifier("journeySave")}}.memoryCard(padding:16,background:MemoryPaint.surface(scheme),border:brand.border,radius:12)}
                else{VStack(spacing:8){if recorder.recording{Text(t("recording",Int(ceil(recorder.seconds)))).font(PiyaliBrand.productFont(16,600)).foregroundStyle(.red)};Button{if recorder.recording{recorder.stop()}else{Task{await recorder.start()}}}label:{HStack{if recorder.starting || recorder.stopping{ProgressView()};Label{Text(t(recorder.recording ? "stop":"record"))}icon:{MemoryIcon(name:recorder.recording ? "stop":"mic",size:20)}}.frame(maxWidth:.infinity)}.buttonStyle(JourneyButtonStyle(color:recorder.recording ? "e53e3e":"00b5d8",edge:recorder.recording ? "822727":"086f83",large:true)).disabled(recorder.starting || recorder.stopping).accessibilityIdentifier("journeyCapture")}}
                if let key=recorder.errorKey ?? journey.errorKey{Text(t(key)).font(PiyaliBrand.productFont(14)).foregroundStyle(.red)}
                HStack{Button(t(saved ? "done":"later"),action:onClose).font(PiyaliBrand.productFont(14,600)).frame(minHeight:32).padding(.horizontal,12).accessibilityIdentifier("journeyRecordingClose");Spacer();Button(t("view"),action:onOpenJourney ?? onClose).font(PiyaliBrand.productFont(14,600)).underline()}.disabled(busy).padding(.top,12)
            }.padding(28)
            }.frame(maxWidth:.infinity).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){height=$0}}.frame(height:min(height,geometry.size.height*0.9)).background(scheme == .dark ? brand.surface:PiyaliBrand.unitColor("fffdf9"),in:RoundedRectangle(cornerRadius:48)).overlay(alignment:.top){HStack{Spacer();Button(action:onClose){MemoryIcon(name:"close",size:20).frame(width:32,height:32)}.disabled(busy).padding(20).accessibilityLabel(t("done"))}.environment(\.layoutDirection,.leftToRight)}.overlay{RoundedRectangle(cornerRadius:48).strokeBorder(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).allowsHitTesting(false)}.padding(.horizontal,16)
        }.frame(width:geometry.size.width,height:geometry.size.height)}.foregroundStyle(brand.text).ignoresSafeArea(.container).buttonStyle(.plain).onDisappear{recorder.clear();journey.clearSelection()}.onChange(of:scenePhase){_,phase in if phase != .active{recorder.stop()}}.accessibilityElement(children:.contain).accessibilityIdentifier("journeyRecordingDialog")
    }
}
@MainActor private final class JourneyPlayback:NSObject,ObservableObject,AVAudioPlayerDelegate {
    @Published var position=0.0
    @Published var playing=false
    @Published var failed=false
    private var player:AVAudioPlayer?,ticker:Task<Void,Never>?
    private static weak var active:JourneyPlayback?
    var duration:Double{player?.duration ?? 0}
    func load(_ data:Data){stop();do{player=try AVAudioPlayer(data:data);player?.delegate=self;player?.prepareToPlay();failed=false}catch{failed=true}}
    func toggle(){guard let player else{return};if player.isPlaying{player.pause();playing=false;ticker?.cancel()}else{if let other=Self.active,other !== self{other.pause()};Self.active=self;if player.currentTime>=player.duration{player.currentTime=0};do{try AVAudioSession.sharedInstance().setCategory(.playback,mode:.spokenAudio);try AVAudioSession.sharedInstance().setActive(true);playing=player.play()}catch{failed=true};ticker=Task{while !Task.isCancelled,playing{position=player.currentTime;try? await Task.sleep(for:.milliseconds(100))}}}}
    func seek(_ value:Double){position=value;player?.currentTime=value}
    private func pause(){player?.pause();playing=false;ticker?.cancel()}
    func stop(){if Self.active === self{Self.active=nil};ticker?.cancel();player?.stop();player=nil;playing=false;position=0}
    nonisolated func audioPlayerDidFinishPlaying(_ player:AVAudioPlayer,successfully flag:Bool){Task{@MainActor in playing=false;position=duration;ticker?.cancel();if !flag{failed=true}}}
}
private struct JourneyAudioDocument:FileDocument {
    static var readableContentTypes:[UTType]{[.audio]}
    var data:Data
    init(data:Data){self.data=data}
    init(configuration:ReadConfiguration)throws{data=configuration.file.regularFileContents ?? Data()}
    func fileWrapper(configuration:WriteConfiguration)throws->FileWrapper{FileWrapper(regularFileWithContents:data)}
}
struct JourneyAudioView:View {
    let payload:JSONValue,label:String,language:String
    @StateObject private var player=JourneyPlayback()
    @State private var exporting=false
    private var outputType:UTType{let mime=payload["mimeType"].string;return mime.contains("wav") ? .wav:mime.contains("mp4") ? .mpeg4Audio:mime.contains("mpeg") ? .mp3:UTType(filenameExtension:mime.contains("ogg") ? "ogg":"webm") ?? .audio}
    private var audio:Data{Data(base64Encoded:payload["audio"].string) ?? Data()}
    private func time(_ value:Double)->String{let n=max(0,Int(value));return "\(n/60):"+String(format:"%02d",n%60)}
    var body:some View {
        VStack(alignment:.leading,spacing:8){
            Text(label).font(PiyaliBrand.productFont(12,600))
            HStack(spacing:12){
                Button{player.toggle()}label:{MemoryIcon(name:player.playing ? "pause":"play").frame(width:32,height:32)}.disabled(player.failed).accessibilityLabel(player.playing ? "Pause":MemoryUI.journey(language,"listen"))
                Text(time(player.position)).font(.system(size:12,design:.monospaced)).frame(minWidth:30)
                Slider(value:Binding(get:{player.position},set:{player.seek($0)}),in:0...max(0.01,player.duration)).tint(PiyaliBrand.unitColor("319795")).disabled(player.failed).accessibilityLabel("Audio progress")
                Text(player.duration>0 ? time(player.duration):"--:--").font(.system(size:12,design:.monospaced)).frame(minWidth:30)
                Button{exporting=true}label:{MemoryIcon(name:"download").frame(width:32,height:32)}.accessibilityLabel(MemoryUI.journey(language,"download"))
            }.padding(12).background(PiyaliBrand.unitColor("8f806e").opacity(0.08),in:Capsule()).overlay{Capsule().stroke(PiyaliBrand.unitColor("8f806e").opacity(0.18))}
            if player.failed{Text(MemoryUI.journey(language,"playbackError")).font(PiyaliBrand.productFont(12)).foregroundStyle(.red)}
        }
            .task(id:payload["audio"].string.hashValue){player.load(audio)}.onDisappear{player.stop()}.fileExporter(isPresented:$exporting,document:JourneyAudioDocument(data:audio),contentType:outputType,defaultFilename:"piyali-voice"){_ in}.accessibilityElement(children:.contain).accessibilityIdentifier("journeyAudio")
    }
}

/// Keeps recordings made by the first native build reachable without uploading or overwriting them.
private struct LegacyJourneyRecordingsView:View {
    @EnvironmentObject var app:AppModel
    @State private var selected:String?
    private var records:[(String,String)] {(app.learner.journeyRecordings ?? [:]).filter{$0.key.hasPrefix(app.learner.target+":")}.sorted{$0.key.localizedStandardCompare($1.key) == .orderedAscending}.map{($0.key,$0.value)}}
    private func payload(_ file:String)->JSONValue? {
        guard file == URL(fileURLWithPath:file).lastPathComponent else{return nil}
        let root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Piyali/Recordings/"+app.identity.npub)
        guard let data=try? Data(contentsOf:root.appendingPathComponent(file)) else{return nil}
        return .object(["audio":.string(data.base64EncodedString()),"mimeType":.string("audio/mp4")])
    }
    var body:some View {if !records.isEmpty{DisclosureGroup("Saved on this iPhone"){VStack(alignment:.leading,spacing:16){ForEach(records,id:\.0){key,file in VStack(alignment:.leading,spacing:8){Button{selected=selected == key ? nil:key}label:{Label(MemoryUI.journey(app.learner.support,"session",values:.object(["n":.number(Double(key.split(separator:":").last.flatMap{Int($0)} ?? 0))])),systemImage:"play.circle")};if selected == key{if let clip=payload(file){JourneyAudioView(payload:clip,label:MemoryUI.journey(app.learner.support,"ownVoice"),language:app.learner.support)}else{Text(MemoryUI.journey(app.learner.support,"error"))}}}}}.padding(.top,12)}}}
}

private struct JourneyTimelineLine:Shape {func path(in rect:CGRect)->Path {var p=Path();p.move(to:CGPoint(x:rect.midX,y:0));p.addLine(to:CGPoint(x:rect.midX,y:rect.maxY));return p}}
