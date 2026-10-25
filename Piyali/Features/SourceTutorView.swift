import SwiftUI

/// The main Tutor surface opens directly into the authored voice lesson.
struct SourceTutorView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var tutor:TutorSessionController
    @State private var pathOpen=false
    @State private var historyOpen=false
    @State private var previewSpeaking=false
    @State private var footerOwner=UUID()
    @State private var activePair:Int?
    @StateObject private var narration=RealtimeNarrationService()
    init(controller:TutorSessionController?=nil){_tutor=StateObject(wrappedValue:controller ?? TutorSessionController())}
    private var brand:PiyaliBrand {.init(dark:scheme == .dark)}
    private var latest:JSONValue {tutor.messages.last(where:{$0["role"].string == "assistant"}) ?? .null}
    private var reply:String {!tutor.live.assistantTurnText.isEmpty && tutor.live.connected ? tutor.live.assistantTurnText:latest["textFinal"].string}
    private var earned:Int {Int(tutor.record(app)["earnedXp"].number)}
    private var percent:Int {min(100,max(0,Int((Double(earned)/Double(max(1,tutor.required))*100).rounded())))}
    private var revision:String {"\(tutor.live.connected)|\(tutor.live.connecting)|\(tutor.live.muted)|\(tutor.paused)|\(tutor.loading)|\(tutor.saving)|\(tutor.completionPending)|\(tutor.id)"}
    private func t(_ key:String)->String {let value=EntryCopy.ui(app.learner.support,key);return value == key ? ["ra_you":"You"][key] ?? key:value}
    var body:some View {
        Group {if TutorSessionController.fixture {surface}else{SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:tutor.completionPending){surface}}}
            .toolbar(.hidden,for:.navigationBar)
            .task(id:tutor.scope(app)){await tutor.prepare(app)}
            .activityFooter(owner:footerOwner,revision:revision,access:app.subscription,fixtureAllowed:TutorSessionController.fixture || tutor.completionPending) {ActivityFooterSurface(hasFeedback:false,feedback:{EmptyView()},actions:{controls})}
            .onChange(of:app.learner.tutorLessons){_,_ in tutor.refresh(app)}
            .onChange(of:narration.error){_,value in if value != nil{tutor.live.setPlaybackDucked(false)}}
            .onChange(of:phase){_,value in if value == .background{stop()}}
            .onChange(of:app.subscription.hasAccess){_,allowed in if !allowed,!tutor.completionPending{stop()}}
            .onDisappear{if !pathOpen && !historyOpen{stop()}}
            .fullScreenCover(isPresented:$pathOpen){TutorSourcePathView(tutor:tutor,onClose:{pathOpen=false})}
            .sheet(isPresented:$historyOpen){history.presentationDetents([.large]).presentationDragIndicator(.visible)}
            .overlay {if let data=tutor.completion{TutorSourceCompletion(data:data,copy:{tutor.copy($0,app.learner.support)},onContinue:{tutor.closeCompletion()})}else if let data=tutor.review{TutorSourceReview(data:data,copy:{tutor.copy($0,app.learner.support)},onContinue:{tutor.closeReview()})}}
    }
    private var surface:some View {
        ScrollView {
            VStack(spacing:4) {
                header.padding(.horizontal,16)
                VStack(spacing:2){
                    VoiceOrbView(state:previewSpeaking ? "speaking":tutor.live.voiceState,callActive:tutor.live.connected || previewSpeaking,feedback:tutor.feedback,audioLevel:tutor.live.audioLevel,dark:scheme == .dark,reducedMotion:reduceMotion,animating:phase == .active && !pathOpen && !historyOpen).frame(width:64,height:64).opacity(0.95).frame(width:112).contentShape(Rectangle()).onTapGesture{guard !tutor.live.connected else{return};previewSpeaking.toggle();if previewSpeaking{Task{try? await Task.sleep(for:.milliseconds(4500));previewSpeaking=false}}}.accessibilityElement(children:.ignore).accessibilityLabel("Tutor orb").accessibilityIdentifier("tutorOrb")
                    if tutor.paused || tutor.live.muted {
                        Text(tutor.paused ? "Paused":"Muted").font(PiyaliBrand.productFont(12,600)).tracking(0.8).textCase(.uppercase).padding(.horizontal,10).padding(.vertical,2).background((tutor.paused ? Color.yellow:Color.red).opacity(0.12),in:Capsule()).accessibilityIdentifier("tutorVoiceStatus")
                    }
                }
                if !reply.isEmpty {bubble.padding(.horizontal,16).padding(.top,6)}
                if let error=tutor.error ?? tutor.live.error ?? narration.error {VStack(alignment:.leading,spacing:12){Text(error).font(PiyaliBrand.productFont(13));if tutor.completionPending {Button("Retry saving"){Task{await tutor.complete(app,ready:true)}}.accessibilityIdentifier("tutorRetrySaving")}}.padding(12).frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("fee2e2"):PiyaliBrand.unitColor("9b1c1c")).background(Color.red.opacity(0.08),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(Color.red.opacity(0.38))}.padding(.horizontal,16).accessibilityIdentifier("tutorError")}
                Color.clear.frame(height:app.activityFooterHeight+12)
            }.padding(.bottom,16).frame(maxWidth:672).frame(maxWidth:.infinity)
        }.background(brand.background).foregroundStyle(brand.text).accessibilityIdentifier("tutorSurface")
    }
    private var header:some View {
        VStack(spacing:12){
            HStack{Button{pathOpen=true}label:{Label(t("app_mode_path"),systemImage:"map").font(PiyaliBrand.productFont(12,500))}.padding(.horizontal,8).frame(height:24).background(scheme == .dark ? .clear:brand.surface.opacity(0.6),in:Capsule()).overlay{Capsule().stroke(scheme == .dark ? .clear:brand.border)}.opacity(0.8).disabled(tutor.completionPending).accessibilityIdentifier("tutorLessons");Spacer();Button{historyOpen=true}label:{Image(systemName:"ellipsis.message").font(.system(size:14)).frame(width:24,height:24).contentShape(Rectangle()).overlay{Circle().stroke(brand.border)}}.disabled(tutor.messages.isEmpty).opacity(tutor.messages.isEmpty ? 0.35:0.7).accessibilityLabel(t("ra_chat_log")).accessibilityIdentifier("tutorHistory")}.frame(height:24)
            if tutor.loading {ProgressView().frame(height:20)}else{Text(tutor.content["title"].string).font(PiyaliBrand.productFont(16,700)).multilineTextAlignment(.center).frame(maxWidth:.infinity,minHeight:24).accessibilityIdentifier("tutorLessonTitle")}
            VStack(spacing:6){HStack{Text(tutor.copy("Lesson progress",app.learner.support)).font(PiyaliBrand.productFont(12));Spacer();Text("\(percent)%").font(PiyaliBrand.productFont(10)).frame(minWidth:38,minHeight:24).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("81e6d9"):PiyaliBrand.unitColor("234e52")).background(brand.surface,in:RoundedRectangle(cornerRadius:4)).overlay{RoundedRectangle(cornerRadius:4).stroke(brand.border)}};FocusWaveBar(percent:Double(percent),height:14,start:"4aa8ff",end:"75f8ff",background:scheme == .dark ? .white.opacity(0.8):.white.opacity(0.9),border:brand.border.opacity(0.35)).accessibilityLabel(tutor.copy("Lesson progress",app.learner.support)).accessibilityValue("\(percent)%").accessibilityIdentifier("tutorLessonProgress")}
        }.buttonStyle(.plain).padding(8).frame(maxWidth:400).background{TutorPaperPanel(textured:true)}.overlay{RoundedRectangle(cornerRadius:16).stroke(scheme == .dark ? .white.opacity(0.06):brand.border)}
    }
    private var bubble:some View {
        VStack(alignment:.leading,spacing:4){
            HStack(alignment:.top,spacing:8){
                Button{
                    tutor.live.setPlaybackDucked(true)
                    narration.play(reply,language:latest["lang"].string.isEmpty ? app.learner.target:latest["lang"].string,engine:app.companionQuestPolicy,voice:"marin",onFinished:{tutor.live.setPlaybackDucked(false)})
                }label:{Group{if narration.playing || narration.loading{ProgressView().controlSize(.mini)}else{Image(systemName:"speaker.wave.2").font(.system(size:14))}}.frame(width:24,height:24)}
                    .buttonStyle(.plain).disabled(narration.playing || narration.loading).opacity(0.7).padding(.top,2).accessibilityLabel(t("ra_btn_replay")).accessibilityIdentifier("tutorReplay")
                Text(aligned(reply,side:"lhs")).font(PiyaliBrand.productFont(16)).lineSpacing(6).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading).textSelection(.enabled).accessibilityIdentifier("tutorLatestReply")
            }
            if latest["textFinal"].string == reply,!latest["translation"].string.isEmpty {Text(aligned(latest["translation"].string,side:"rhs")).font(PiyaliBrand.productFont(12)).lineSpacing(4.5).foregroundStyle(brand.secondary).accessibilityIdentifier("tutorTranslation")}
        }.padding(12).frame(maxWidth:.infinity,alignment:.topLeading).background(scheme == .dark ? Color.clear:PiyaliBrand.unitColor("f1e4d3").opacity(0.98),in:RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).stroke(scheme == .dark ? .white.opacity(0.06):PiyaliBrand.unitColor("8e714f").opacity(0.26))}.shadow(color:.black.opacity(scheme == .dark ? 0.35:0.06),radius:14,y:scheme == .dark ? 14:8).frame(minHeight:150,alignment:.top)
            .environment(\.openURL,OpenURLAction{url in if url.scheme == "tutor-token",let i=Int(url.host ?? ""){activePair=activePair == i ? nil:i;return .handled};return .systemAction})
    }
    private func aligned(_ text:String,side:String)->AttributedString {
        var result=AttributedString(text)
        for (i,pair) in latest["pairs"].array.enumerated(){let phrase=pair[side].string;guard !phrase.isEmpty,let range=result.range(of:phrase,options:.caseInsensitive) else{continue};result[range].link=URL(string:"tutor-token://\(i)");result[range].foregroundColor=brand.text;result[range].underlineStyle=activePair == i ? .single:[];if activePair == i{result[range].backgroundColor=Color.cyan.opacity(0.14)}}
        return result
    }
    @ViewBuilder private var controls:some View {
        if tutor.saving {ProgressView(tutor.copy("Saving Tutor progress...",app.learner.support)).frame(maxWidth:.infinity).font(PiyaliBrand.productFont(12))}
        else if tutor.live.connected || tutor.paused {
            HStack(spacing:12){
                control(tutor.live.muted ? "mic.slash.fill":"mic.fill",label:tutor.live.muted ? "Unmute microphone":"Mute microphone",selected:tutor.live.muted){tutor.live.setMuted(!tutor.live.muted)}.disabled(tutor.paused || !tutor.live.connected).accessibilityIdentifier("tutorMute")
                control(tutor.paused ? "play.fill":"pause.fill",label:tutor.paused ? "Resume tutor":"Pause tutor",selected:tutor.paused){Task{narration.stopAll();if tutor.paused{await tutor.start(app,resuming:true)}else{await tutor.pause(app)}}}.accessibilityIdentifier("tutorPause")
                control("phone.down.fill",label:"End tutor session",stop:true){stop()}.accessibilityIdentifier("tutorEnd")
            }.frame(maxWidth:288).frame(maxWidth:.infinity)
        }else{Button{Task{previewSpeaking=false;await tutor.start(app)}}label:{Label(t(tutor.live.connecting ? "ra_btn_starting":"ra_btn_start"),systemImage:"mic.fill")}.buttonStyle(ActivityPrimaryButtonStyle(tone:"speak")).disabled(tutor.live.connecting || tutor.loading || tutor.id.isEmpty || tutor.completionPending).accessibilityIdentifier("tutorStart")}
    }
    private func control(_ icon:String,label:String,selected:Bool=false,stop:Bool=false,action:@escaping()->Void)->some View {Button(action:action){Image(systemName:icon).font(.system(size:17,weight:.semibold)).frame(maxWidth:.infinity,minHeight:40).contentShape(Rectangle()).foregroundStyle(stop ? .white:brand.text).background(stop ? PiyaliBrand.unitColor("b0005b"):selected ? brand.surface.opacity(0.88):.clear,in:RoundedRectangle(cornerRadius:18))}.buttonStyle(.plain).accessibilityLabel(label).accessibilityAddTraits(selected ? .isSelected:[])}
    private func stop(){narration.stopAll();tutor.live.setPlaybackDucked(false);Task{await tutor.stop(app)}}
    private var history:some View {NavigationStack{ScrollView{LazyVStack(alignment:.leading,spacing:12){ForEach(Array(tutor.messages.enumerated()),id:\.offset){_,message in HStack{if message["role"].string == "user"{Spacer(minLength:36)};VStack(alignment:.leading,spacing:8){Text(message["role"].string == "user" ? t("ra_you"):"Piyali").font(PiyaliBrand.productFont(11,600)).foregroundStyle(brand.secondary);Text(message["textFinal"].string).font(PiyaliBrand.productFont(16)).textSelection(.enabled);if !message["translation"].string.isEmpty{Text(message["translation"].string).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.secondary)}}.padding(14).background(message["role"].string == "user" ? Color.cyan.opacity(0.1):brand.surface,in:RoundedRectangle(cornerRadius:16));if message["role"].string != "user"{Spacer(minLength:24)}}}}.padding(16)}.background(brand.background).foregroundStyle(brand.text).navigationTitle(t("ra_chat_log")).navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.confirmationAction){Button(tutor.pathCopy("close",app.learner.support)){historyOpen=false}}}}}
}

struct TutorPaperPanel:View {
    @Environment(\.colorScheme) private var scheme
    var radius:CGFloat=16
    var textured=false
    var body:some View {
        GeometryReader{geometry in
            let dark=scheme == .dark,w=max(geometry.size.width,geometry.size.height)
            ZStack{
                LinearGradient(colors:dark ? [PiyaliBrand.unitColor(textured ? "02060e":"111827"),PiyaliBrand.unitColor(textured ? "01030a":"050914")]:[PiyaliBrand.unitColor(textured ? "fff9f2":"fffaf3"),PiyaliBrand.unitColor(textured ? "f8f1e8":"f7eddf")],startPoint:.top,endPoint:.bottom)
                if textured {
                    RadialGradient(colors:[PiyaliBrand.unitColor(dark ? "1e40af":"ac8e6e").opacity(0.12),.clear],center:.init(x:dark ? 0.2:0.18,y:dark ? 0.15:0.16),startRadius:0,endRadius:w*0.42)
                    RadialGradient(colors:[PiyaliBrand.unitColor(dark ? "065f46":"d9c0a4").opacity(dark ? 0.1:0.12),.clear],center:.init(x:0.82,y:dark ? 0.25:0.2),startRadius:0,endRadius:w*0.4)
                    if dark {RadialGradient(colors:[PiyaliBrand.unitColor("0f172a").opacity(0.52),.clear],center:.bottom,startRadius:0,endRadius:w*0.62)}
                    Canvas{context,size in
                        var horizontal=Path(),vertical=Path()
                        for y in stride(from:CGFloat(0),through:size.height,by:28){horizontal.move(to:.init(x:0,y:y));horizontal.addLine(to:.init(x:size.width,y:y))}
                        for x in stride(from:CGFloat(0),through:size.width,by:28){vertical.move(to:.init(x:x,y:0));vertical.addLine(to:.init(x:x,y:size.height))}
                        let color=PiyaliBrand.unitColor(dark ? "94a3b8":"9b8770")
                        context.stroke(horizontal,with:.color(color.opacity(dark ? 0.06:0.05)),lineWidth:1)
                        context.stroke(vertical,with:.color(color.opacity(dark ? 0.05:0.04)),lineWidth:1)
                    }.opacity(dark ? 0.45:0.24).blendMode(dark ? .screen:.multiply)
                }
            }.clipShape(RoundedRectangle(cornerRadius:radius))
        }
    }
}

struct TutorSourceCompletion:View {
    @EnvironmentObject var app:AppModel
    let data:JSONValue
    let copy:(String)->String
    let onContinue:()->Void
    var body:some View {ZStack{Color.black.opacity(0.72).ignoresSafeArea();VStack(spacing:20){BrandArtwork(name:"story-portrait-27.webp").frame(width:160,height:160).padding(12).background(.white.opacity(0.2),in:Circle()).overlay{Circle().stroke(.white.opacity(0.3),lineWidth:2)};VStack(spacing:4){Text(copy("Lesson Complete!")).font(PiyaliBrand.productFont(30,700));Text(data["title"].string).font(PiyaliBrand.productFont(18))};VStack(spacing:6){Text(copy("XP Gained")).font(PiyaliBrand.productFont(14)).textCase(.uppercase).opacity(0.8);Text("\(Int(data["xpEarned"].number))").font(PiyaliBrand.productFont(48,700)).foregroundStyle(PiyaliBrand.unitColor("faf089")).accessibilityIdentifier("tutorCompletionXP");HStack{Text(EntryCopy.ui(app.learner.support,"ra_label_level")+" \(app.learner.companionLevel)");Spacer();Text("XP \(app.learner.xp)")}.font(PiyaliBrand.productFont(12));ActivityProgressBar(value:app.learner.xp%100,label:"XP")}.padding(20).background(.white.opacity(0.2),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.4),lineWidth:2)};Button(copy("Continue"),action:onContinue).font(PiyaliBrand.productFont(16,700)).foregroundStyle(PiyaliBrand.unitColor("553c9a")).frame(maxWidth:.infinity,minHeight:48).background(.white,in:RoundedRectangle(cornerRadius:12)).accessibilityIdentifier("tutorCompletionContinue")}.padding(24).foregroundStyle(.white).background(LinearGradient(colors:[PiyaliBrand.unitColor("667eea"),PiyaliBrand.unitColor("764ba2")],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:16)).padding(12)}.accessibilityElement(children:.contain).accessibilityIdentifier("tutorCompletionDialog")}
}
struct TutorSourceReview:View {
    @Environment(\.colorScheme) private var scheme
    let data:JSONValue
    let copy:(String)->String
    let onContinue:()->Void
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    var body:some View {ZStack{Color.black.opacity(0.72).ignoresSafeArea();VStack(alignment:.leading,spacing:16){HStack{Text(copy("Lesson Review")).font(PiyaliBrand.productFont(20,700));Spacer();Button(action:onContinue){Image(systemName:"xmark")}.accessibilityLabel("Close")};Text(data["title"].string).font(PiyaliBrand.productFont(16,700));Text(data["subtitle"].string).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary);ScrollView{VStack(alignment:.leading,spacing:14){ForEach(Array(data["items"].array.enumerated()),id:\.offset){_,item in HStack(alignment:.top,spacing:12){Image(systemName:"checkmark.circle.fill").foregroundStyle(.teal);VStack(alignment:.leading,spacing:3){Text(item["task"].string).font(PiyaliBrand.productFont(14));if !item["phrase"].string.isEmpty{Text(item["phrase"].string).font(PiyaliBrand.productFont(16,600))};if !item["meaning"].string.isEmpty{Text(item["meaning"].string).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary)}}}}}}.frame(maxHeight:330);Button(copy("Continue"),action:onContinue).buttonStyle(QuestionPrimaryButtonStyle()).accessibilityIdentifier("tutorReviewContinue")}.padding(20).foregroundStyle(brand.text).background{TutorPaperPanel()}.overlay{RoundedRectangle(cornerRadius:16).stroke(brand.border)}.padding(12)}.accessibilityElement(children:.contain).accessibilityIdentifier("tutorReviewDialog")}
}
