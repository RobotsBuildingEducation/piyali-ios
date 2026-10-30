import SwiftUI

/// The main Tutor surface opens directly into the authored voice lesson.
struct SourceTutorView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var tutor:TutorSessionController
    private var pathOpen:Bool{app.tutorPath?.owner == footerOwner}
    @State private var historyOpen=false
    @State private var previewSpeaking=false
    @State private var footerOwner=UUID()
    @StateObject private var replay=TutorReplayController()
    private let completionPendingChanged:(Bool)->Void
    private let focusedCompleted:()->Void
    init(controller:TutorSessionController?=nil,focus:TutorFocus?=nil,onCompletionPending:@escaping(Bool)->Void={_ in},onFocusedCompletion:@escaping()->Void={}) {
        _tutor=StateObject(wrappedValue:controller ?? TutorSessionController(focus:focus));completionPendingChanged=onCompletionPending;focusedCompleted=onFocusedCompletion
    }
    private var brand:PiyaliBrand {.init(dark:scheme == .dark)}
    private var latest:JSONValue {tutor.messages.last(where:{$0["role"].string == "assistant"}) ?? .null}
    private var reply:String {!tutor.live.assistantTurnText.isEmpty && tutor.live.connected ? tutor.live.assistantTurnText:latest["textFinal"].string}
    private var visibleReply:JSONValue {
        guard tutor.live.connected,!tutor.live.assistantTurnText.isEmpty,!tutor.live.assistantResponseID.isEmpty else{return latest}
        if latest["id"].string == tutor.live.assistantResponseID{return latest}
        return .object(["id":.string(tutor.live.assistantResponseID),"role":.string("assistant"),"textFinal":.string(reply),"lang":.string(tutor.currentReplyLanguage == "support" ? app.learner.support:app.learner.target)])
    }
    private var earned:Int {tutor.earnedXP(app)}
    private var percent:Int {min(100,max(0,Int((Double(earned)/Double(max(1,tutor.required))*100).rounded())))}
    private var revision:String {"\(tutor.live.connected)|\(tutor.live.connecting)|\(tutor.live.muted)|\(tutor.paused)|\(tutor.loading)|\(tutor.saving)|\(tutor.completionPending)|\(tutor.id)"}
    private func t(_ key:String)->String {let value=EntryCopy.ui(app.learner.support,key);return value == key ? ["ra_you":"You"][key] ?? key:value}
    var body:some View {
        Group {if TutorSessionController.fixture {surface}else{SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:tutor.completionPending){surface}}}
            .toolbar(.hidden,for:.navigationBar)
            .task(id:tutor.scope(app)){
                replay.stop()
                let account=app.identity.npub,target=app.learner.target,day=CalendarDay.key(Date()),owner=footerOwner,notify=completionPendingChanged
                if let path=app.tutorPath,path.owner == footerOwner,(path.account != account || path.target != target){app.tutorPath=nil}
                tutor.onCompletionPending={[weak app] active in app?.retainEarnedPractice(owner:owner,active:active,account:account,target:target,day:day);notify(active)}
                tutor.onFocusedCompletion=focusedCompleted;await tutor.prepare(app)
            }
            .activityFooter(owner:footerOwner,revision:revision,access:app.subscription,fixtureAllowed:TutorSessionController.fixture || tutor.completionPending) {ActivityFooterSurface(hasFeedback:false,feedback:{EmptyView()},actions:{controls})}
            .onChange(of:app.learner.userSettings){_,_ in tutor.live.setOutputGain(app.learner.settingsSnapshot["tutorVolume"] == .null ? 1:app.learner.settingsSnapshot["tutorVolume"].number)}
            .onChange(of:app.learner.tutorLessons){_,_ in tutor.refresh(app)}
            .onChange(of:phase){_,value in if value == .background{stop()}}
            .onChange(of:app.subscription.hasAccess){_,allowed in if !allowed,!tutor.completionPending{stop()}}
            .onDisappear{if pathOpen{app.tutorPath=nil};if !historyOpen{app.releaseEarnedPractice(owner:footerOwner);stop()}}
            .sheet(isPresented:$historyOpen){history.presentationDetents([.large]).presentationDragIndicator(.visible)}
            .overlay {if !pathOpen{TutorCompletionFlow(tutor:tutor)}}
    }
    private var surface:some View {
        ScrollView {
            VStack(spacing:4) {
                header.padding(.horizontal,16)
                VStack(spacing:2){
                    VoiceOrbView(state:previewSpeaking ? "speaking":tutor.live.voiceState,callActive:tutor.live.connected || previewSpeaking,feedback:tutor.feedback,audioLevel:tutor.live.audioLevel,dark:scheme == .dark,reducedMotion:reduceMotion,animating:phase == .active && !pathOpen && !historyOpen).frame(width:64,height:64).opacity(0.95).frame(width:112).contentShape(Rectangle()).onTapGesture{guard !tutor.live.connected else{return};previewSpeaking.toggle();if previewSpeaking{Task{try? await Task.sleep(for:.milliseconds(4500));previewSpeaking=false}}}.accessibilityElement(children:.ignore).accessibilityLabel("Tutor orb").accessibilityIdentifier("tutorOrb")
                    if tutor.paused || tutor.live.muted {
                        Text(tutor.paused ? "Paused":"Muted").font(PiyaliBrand.productFont(12,600)).tracking(0.8).textCase(.uppercase).padding(.horizontal,10).padding(.vertical,2).background((tutor.paused ? Color.yellow:Color.red).opacity(0.12),in:Capsule()).accessibilityIdentifier("tutorVoiceStatus")
                    }else if tutor.live.connected {
                        Text(tutor.statusLabel(app.learner.support)).font(PiyaliBrand.productFont(12)).foregroundStyle(scheme == .dark ? .white.opacity(0.8):brand.secondary).accessibilityIdentifier("tutorLiveStatus")
                    }
                }
                if !reply.isEmpty {bubble.padding(.horizontal,16).padding(.top,6)}
                if let error=tutor.error ?? tutor.live.error ?? replay.error {VStack(alignment:.leading,spacing:12){Text(error).font(PiyaliBrand.productFont(13));if tutor.completionPending {Button("Retry saving"){Task{await tutor.complete(app,ready:true)}}.accessibilityIdentifier("tutorRetrySaving")}}.padding(12).frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("fee2e2"):PiyaliBrand.unitColor("9b1c1c")).background(Color.red.opacity(0.08),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(Color.red.opacity(0.38))}.padding(.horizontal,16).accessibilityIdentifier("tutorError")}
                Color.clear.frame(height:app.activityFooterHeight+12)
            }.padding(.bottom,16).frame(maxWidth:672).frame(maxWidth:.infinity)
        }.background(brand.background).foregroundStyle(brand.text).accessibilityIdentifier("tutorSurface")
    }
    private var header:some View {
        VStack(spacing:12){
            HStack{Button{app.tutorPath = .init(owner:footerOwner,account:app.identity.npub,target:app.learner.target,tutor:tutor)}label:{Label(t("app_mode_path"),systemImage:"map").font(PiyaliBrand.productFont(12,500))}.padding(.horizontal,8).frame(height:24).background(scheme == .dark ? .clear:brand.surface.opacity(0.6),in:Capsule()).overlay{Capsule().stroke(scheme == .dark ? .clear:brand.border)}.opacity(0.8).disabled(tutor.completionPending).accessibilityIdentifier("tutorLessons");Spacer();Button{historyOpen=true}label:{Image(systemName:"ellipsis.message").font(.system(size:14)).frame(width:24,height:24).contentShape(Rectangle()).overlay{Circle().stroke(brand.border)}}.disabled(tutor.messages.isEmpty).opacity(tutor.messages.isEmpty ? 0.35:0.7).accessibilityLabel(t("ra_chat_log")).accessibilityIdentifier("tutorHistory")}.frame(height:24)
            if tutor.loading {ProgressView().frame(height:20)}else{Text(tutor.content["title"].string).font(PiyaliBrand.productFont(16,700)).multilineTextAlignment(.center).frame(maxWidth:.infinity,minHeight:24).accessibilityIdentifier("tutorLessonTitle")}
            VStack(spacing:6){HStack{Text(tutor.copy("Lesson progress",app.learner.support)).font(PiyaliBrand.productFont(12));Spacer();Text("\(percent)%").font(PiyaliBrand.productFont(10)).frame(minWidth:38,minHeight:24).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("81e6d9"):PiyaliBrand.unitColor("234e52")).background(brand.surface,in:RoundedRectangle(cornerRadius:4)).overlay{RoundedRectangle(cornerRadius:4).stroke(brand.border)}};FocusWaveBar(percent:Double(percent),height:14,start:"4aa8ff",end:"75f8ff",background:scheme == .dark ? .white.opacity(0.8):.white.opacity(0.9),border:brand.border.opacity(0.35)).accessibilityLabel(tutor.copy("Lesson progress",app.learner.support)).accessibilityValue("\(percent)%").accessibilityIdentifier("tutorLessonProgress")}
        }.buttonStyle(.plain).padding(8).frame(maxWidth:400).background{TutorPaperPanel(textured:true)}.overlay{RoundedRectangle(cornerRadius:16).stroke(scheme == .dark ? .white.opacity(0.06):brand.border)}
    }
    private var bubble:some View {
        replyView(visibleReply).frame(minHeight:150,alignment:.top)
    }
    private func replyView(_ message:JSONValue)->some View {
        TutorReplyView(primary:message["textFinal"].string,secondary:message["translation"].string,target:message["lang"].string.isEmpty ? app.learner.target:message["lang"].string,support:app.learner.support,pairs:message["pairs"],showSecondary:app.learner.recipeUser["progress"]["showTranslations"] != .bool(false),replaying:replay.activeID == message["id"].string,onReplay:{
            let messages=tutor.messages.contains(where:{$0["id"] == message["id"]}) ? tutor.messages:tutor.messages+[message]
            replay.play(message["id"].string,messages:messages,target:app.learner.target,voice:tutor.replayVoice(app),scope:tutor.clipScope(app),clips:tutor.clips,engine:app.companionQuestPolicy,live:tutor.live.connected,duck:{tutor.live.setPlaybackDucked($0)})
        })
    }
    @ViewBuilder private var controls:some View {
        if tutor.saving {ProgressView(tutor.copy("Saving Tutor progress...",app.learner.support)).frame(maxWidth:.infinity).font(PiyaliBrand.productFont(12))}
        else if tutor.live.connected || tutor.paused {
            HStack(spacing:12){
                control(tutor.live.muted ? "mic.slash.fill":"mic.fill",label:tutor.live.muted ? "Unmute microphone":"Mute microphone",selected:tutor.live.muted){tutor.live.setMuted(!tutor.live.muted)}.disabled(tutor.paused || !tutor.live.connected).accessibilityIdentifier("tutorMute")
                control(tutor.paused ? "play.fill":"pause.fill",label:tutor.paused ? "Resume tutor":"Pause tutor",selected:tutor.paused){Task{replay.stop();if tutor.paused{await tutor.start(app,resuming:true)}else{await tutor.pause(app)}}}.accessibilityIdentifier("tutorPause")
                control("phone.down.fill",label:"End tutor session",stop:true){stop()}.accessibilityIdentifier("tutorEnd")
            }.frame(maxWidth:288).frame(maxWidth:.infinity)
        }else{Button{Task{previewSpeaking=false;await tutor.start(app)}}label:{Label(t(tutor.live.connecting ? "ra_btn_starting":"ra_btn_start"),systemImage:"mic.fill")}.buttonStyle(ActivityPrimaryButtonStyle(tone:"speak")).disabled(tutor.live.connecting || tutor.loading || tutor.id.isEmpty || tutor.completionPending || tutor.focusedFinished).accessibilityIdentifier("tutorStart")}
    }
    private func control(_ icon:String,label:String,selected:Bool=false,stop:Bool=false,action:@escaping()->Void)->some View {Button(action:action){Image(systemName:icon).font(.system(size:17,weight:.semibold)).frame(maxWidth:.infinity,minHeight:40).contentShape(Rectangle()).foregroundStyle(stop ? .white:brand.text).background(stop ? PiyaliBrand.unitColor("b0005b"):selected ? brand.surface.opacity(0.88):.clear,in:RoundedRectangle(cornerRadius:18))}.buttonStyle(.plain).accessibilityLabel(label).accessibilityAddTraits(selected ? .isSelected:[])}
    private func stop(){replay.stop();tutor.live.setPlaybackDucked(false);Task{await tutor.stop(app)}}
    private func historyReply(_ message:JSONValue)->some View {replyView(message)}
    private var history:some View {NavigationStack{ScrollView{LazyVStack(alignment:.leading,spacing:12){ForEach(Array(tutor.messages.enumerated()),id:\.offset){_,message in HStack{if message["role"].string == "user"{Spacer(minLength:36)};VStack(alignment:.leading,spacing:8){if message["role"].string == "assistant"{historyReply(message)}else{Text(message["role"].string == "user" ? t("ra_you"):"Piyali").font(PiyaliBrand.productFont(11,600)).foregroundStyle(brand.secondary);Text(message["textFinal"].string).font(PiyaliBrand.productFont(16)).textSelection(.enabled);if !message["translation"].string.isEmpty{Text(message["translation"].string).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.secondary)}}}.padding(14).background(message["role"].string == "user" ? Color.cyan.opacity(0.1):brand.surface,in:RoundedRectangle(cornerRadius:16));if message["role"].string != "user"{Spacer(minLength:24)}}}}.padding(16)}.background(brand.background).foregroundStyle(brand.text).navigationTitle(t("ra_chat_log")).navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.confirmationAction){Button(tutor.pathCopy("close",app.learner.support)){historyOpen=false}.accessibilityIdentifier("tutorHistoryClose")}}}}
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
    @Environment(\.colorScheme) private var scheme
    let data:JSONValue
    let copy:(String)->String
    let onContinue:()->Void
    var body:some View {GeometryReader{geometry in
        let roomy=geometry.size.width>=400 && geometry.size.height>=740,padding:CGFloat=28,portrait:CGFloat=roomy ? 96:80
        ZStack{
            TutorDialogBackdrop(onClose:onContinue)
            VStack(spacing:0){
                VStack(spacing:roomy ? 20:16){
                    BrandArtwork(name:"story-portrait-27.webp").frame(width:portrait,height:portrait).padding(roomy ? 12:8).padding(2).background(.white.opacity(0.2),in:Circle()).overlay{Circle().stroke(.white.opacity(0.3),lineWidth:2)}.shadow(color:.black.opacity(0.18),radius:20,y:20)
                    VStack(spacing:4){OnboardingText(text:copy("Lesson Complete!"),size:roomy ? 30:24,weight:.bold,lineHeight:roomy ? 34.5:27.6);OnboardingText(text:data["title"].string,size:roomy ? 18:16,lineHeight:roomy ? 27:24).opacity(0.9)}
                    VStack(spacing:4){
                        OnboardingText(text:copy("XP Gained"),size:14,lineHeight:21).textCase(.uppercase).opacity(0.8)
                        Text("\(Int(data["xpEarned"].number))").font(PiyaliBrand.productFont(roomy ? 48:36,700)).foregroundStyle(PiyaliBrand.unitColor("faf089")).accessibilityIdentifier("tutorCompletionXP")
                        VStack(spacing:4){HStack{Text(EntryCopy.ui(app.learner.support,"ra_label_level")+" \(app.learner.companionLevel)").font(PiyaliBrand.productFont(14,700));Spacer();Text(EntryCopy.ui(app.learner.support,"ra_label_xp")+" \(app.learner.xp)").font(PiyaliBrand.productFont(12,800)).tracking(0.24).padding(.horizontal,10).padding(.vertical,4).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "dbe6f3":"6f5a47")).background(PiyaliBrand.unitColor(scheme == .dark ? "111827":"fffdf9").opacity(0.94),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(0.16))}};FocusWaveBar(percent:Double(app.learner.xp%100),height:14,background:.white.opacity(0.8),border:.white.opacity(0.35),insetBorder:true)}.padding(.top,12)
                    }.padding(.horizontal,roomy ? 28:20).padding(.vertical,roomy ? 20:16).padding(2).frame(maxWidth:.infinity).background(.white.opacity(0.2),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.4),lineWidth:2)}
                }.padding(.horizontal,padding).padding(.top,padding).padding(.bottom,12)
                Button(copy("Continue"),action:onContinue).font(PiyaliBrand.productFont(roomy ? 18:16,700)).foregroundStyle(PiyaliBrand.unitColor("6b46c1")).frame(maxWidth:.infinity,minHeight:roomy ? 58:50).background{Capsule().fill(.white).shadow(color:PiyaliBrand.unitColor("3182ce"),radius:0,y:4)}.buttonStyle(.plain).accessibilityIdentifier("tutorCompletionContinue").padding(.horizontal,padding).padding(.bottom,padding)
            }.multilineTextAlignment(.center).foregroundStyle(.white).background(LinearGradient(colors:[PiyaliBrand.unitColor("667eea"),PiyaliBrand.unitColor("764ba2")],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:48)).overlay{RoundedRectangle(cornerRadius:48).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3)}.shadow(color:.black.opacity(0.25),radius:25,y:25).frame(maxWidth:min(geometry.size.width-24,geometry.size.width>=480 ? 448:geometry.size.width-24)).frame(maxWidth:.infinity,maxHeight:.infinity)
        }
    }.environment(\.layoutDirection,.leftToRight).accessibilityElement(children:.contain).accessibilityAddTraits(.isModal).accessibilityIdentifier("tutorCompletionDialog")}
}
struct TutorDialogBackdrop:View {
    @Environment(\.colorScheme) private var scheme
    var onClose:()->Void
    var body:some View {(scheme == .dark ? PiyaliBrand.unitColor("020617").opacity(0.92):PiyaliBrand.unitColor("1c140c").opacity(0.82)).ignoresSafeArea().contentShape(Rectangle()).onTapGesture(perform:onClose)}
}
struct TutorSourceReview:View {
    @Environment(\.colorScheme) private var scheme
    @State private var contentHeight:CGFloat=700
    let data:JSONValue
    let copy:(String)->String
    let onContinue:()->Void
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    var body:some View {GeometryReader{geometry in
        ZStack{
            TutorDialogBackdrop(onClose:onContinue)
            VStack(spacing:0){
                VStack(alignment:.leading,spacing:8){OnboardingText(text:copy("Lesson Review"),size:24,weight:.bold,lineHeight:26.4);OnboardingText(text:data["title"].string,size:16,weight:.semibold,lineHeight:24).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("b7c5d8"):brand.secondary)}.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,32).padding(.top,28).padding(.bottom,28)
                ScrollView{VStack(spacing:12){ForEach(Array(data["items"].array.enumerated()),id:\.offset){_,item in HStack(alignment:.top,spacing:12){CoursePathIcon(name:"RiCheckLine").frame(width:14,height:14).foregroundStyle(item["completed"].boolean ? .white:PiyaliBrand.unitColor(scheme == .dark ? "d1d5db":"718096")).frame(width:22,height:22).background(item["completed"].boolean ? PiyaliBrand.unitColor(scheme == .dark ? "38b2ac":"319795"):(scheme == .dark ? .white.opacity(0.16):PiyaliBrand.unitColor("f7fafc")),in:Circle());VStack(alignment:.leading,spacing:4){OnboardingText(text:item["task"].string.capitalized,size:12,weight:.bold,lineHeight:18).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("a3b4c9"):brand.secondary);OnboardingText(text:item["phrase"].string,size:16,weight:.heavy,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(scheme == .dark ? .white:brand.text);if !item["meaning"].string.isEmpty,item["meaning"].string != item["phrase"].string{OnboardingText(text:item["meaning"].string,size:12,lineHeight:18).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("b7c5d8"):brand.secondary)}}.frame(maxWidth:.infinity,alignment:.leading)}.padding(.vertical,8).padding(.horizontal,4)}}.padding(17).background(scheme == .dark ? PiyaliBrand.unitColor("0f172a").opacity(0.68):.white.opacity(0.62),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(PiyaliBrand.unitColor(scheme == .dark ? "ffffff":"785e3d").opacity(scheme == .dark ? 0.08:0.14))}.padding(.horizontal,28).padding(.top,28).padding(.bottom,20).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){contentHeight=$0}}
                    .frame(height:min(contentHeight,max(100,geometry.size.height-48-114.4-84)))
                Button(copy("Continue"),action:onContinue).font(PiyaliBrand.productFont(18,900)).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:48).background{RoundedRectangle(cornerRadius:12).fill(PiyaliBrand.unitColor("319795")).shadow(color:PiyaliBrand.unitColor("008080"),radius:0,y:4)}.buttonStyle(.plain).accessibilityIdentifier("tutorReviewContinue").padding(.horizontal,28).padding(.top,8).padding(.bottom,28)
            }.foregroundStyle(brand.text).background(LinearGradient(colors:scheme == .dark ? [PiyaliBrand.unitColor("0c1220").opacity(0.98),PiyaliBrand.unitColor("040812").opacity(0.98)]:[PiyaliBrand.unitColor("fffbf5").opacity(0.98),PiyaliBrand.unitColor("f8efe2").opacity(0.98)],startPoint:.top,endPoint:.bottom),in:RoundedRectangle(cornerRadius:48)).overlay{RoundedRectangle(cornerRadius:48).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3)}.shadow(color:.black.opacity(scheme == .dark ? 0.45:0.22),radius:30,y:24).padding(.horizontal,12).frame(maxWidth:576).frame(maxWidth:.infinity,maxHeight:.infinity)
        }
    }.environment(\.layoutDirection,.leftToRight).accessibilityElement(children:.contain).accessibilityAddTraits(.isModal).accessibilityIdentifier("tutorReviewDialog")}
}

/// Completion and review remain above either the voice lesson or its path.
/// Earned-practice ownership blocks the daily-goal modal until review closes.
struct TutorCompletionFlow:View {
    @EnvironmentObject var app:AppModel
    @ObservedObject var tutor:TutorSessionController
    var body:some View {Group{if let data=tutor.completion{TutorSourceCompletion(data:data,copy:{tutor.copy($0,app.learner.support)},onContinue:tutor.closeCompletion)}else if let data=tutor.review{TutorSourceReview(data:data,copy:{tutor.copy($0,app.learner.support)},onContinue:{tutor.closeReview(app)})}}}
}
