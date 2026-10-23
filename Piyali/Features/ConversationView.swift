import SwiftUI

struct ConversationView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var conversation=ConversationService()
    @StateObject private var speech=SpeechService()
    @StateObject private var live:LiveTutorService
    @State private var showStarter=false
    @State private var showSettings=false
    @State private var showHistory=false
    @State private var showSummary=false
    @State private var paused=false
    @State private var pausedMuted=false
    @State private var active=false
    @State private var starterPlaying=false
    @State private var pausedReply=""
    @State private var settingsKey=""
    @State private var baseXP=0
    @State private var baseTurns=0
    @State private var baseGoals=0
    @State private var footerOwner=UUID()
    init() { _live=StateObject(wrappedValue:ConversationVoiceFixture.service()) }
    private var draft:ConversationDraft { app.learner.conversation }
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private static let copy=(try? ContentLibrary.load(JSONValue.self,name:"conversation-ui")) ?? .null
    private func t(_ key:String,_ fallback:String)->String { let value=EntryCopy.ui(app.learner.support,key);return value == key ? fallback : value }
    private func setting(_ key:String)->String { let copy=Self.copy["settings"][app.learner.support];return (copy == .null ? Self.copy["settings"]["en"] : copy)[key].string }
    private func summary(_ key:String)->String { let copy=Self.copy["summary"][app.learner.support];return (copy == .null ? Self.copy["summary"]["en"] : copy)[key].string }
    private var latest:ConversationMessage? { draft.messages.last { $0.role == "assistant" } }
    private var reply:String { !live.assistantTurnText.isEmpty ? live.assistantTurnText : paused && !pausedReply.isEmpty ? pausedReply : latest?.text ?? "" }
    private var footerRevision:String { "\(live.connected)|\(live.connecting)|\(live.muted)|\(paused)|\(conversation.busy)|\(draft.goal?.id.uuidString ?? "")" }
    private var settingsRevision:String { (draft.challengeLevel ?? "")+"|"+draft.interests }
    private var allowed:Bool { app.subscription.hasAccess || conversation.fixture }
    var body:some View {
        Group { if conversation.fixture { content } else { SubscriptionRequiredView(service:app.subscription) { content } } }
            .navigationTitle(t("course_conversation","Conversation")).navigationBarTitleDisplayMode(.inline)
            .task(id:app.identity.npub+":"+app.learner.target+":"+app.learner.support+":"+String(allowed)) { active=true;await conversation.prepare(app) }
            .activityFooter(owner:footerOwner,revision:footerRevision,access:app.subscription,fixtureAllowed:conversation.fixture) { ActivityFooterSurface(hasFeedback:false,feedback:{EmptyView()},actions:{controls}) }
            .onChange(of:app.learner.target) { _,_ in stop() }
            .onChange(of:app.learner.support) { _,_ in stop() }
            .onChange(of:app.identity.npub) { _,_ in stop() }
            .onChange(of:scenePhase) { _,phase in if phase == .background { stop() } }
            .onChange(of:app.subscription.hasAccess) { _,access in if !access { stop() } }
            .onChange(of:draft.goal?.id) { _,_ in stopStarter();showStarter=false;Task { await live.updateConversation(app.learner.conversation,learner:app.learner) } }
            .onDisappear { stop() }
            .sheet(isPresented:$showSettings,onDismiss:settingsClosed) { settingsSheet.presentationDetents([.fraction(0.8)]).presentationDragIndicator(.visible) }
            .sheet(isPresented:$showHistory) { historySheet.presentationDetents([.large]).presentationDragIndicator(.visible) }
            .sheet(isPresented:$showSummary) { summarySheet.presentationDetents([.height(570)]).presentationDragIndicator(.visible) }
    }
    private var content:some View {
        ScrollView {
            VStack(spacing:6) {
                goalCard.padding(.horizontal,16)
                VStack(spacing:2) {
                    BrandArtwork(name:"piyali-orb.png").frame(width:52,height:52).frame(width:64,height:64).opacity(0.95).frame(width:112).accessibilityLabel("Tutor orb").accessibilityIdentifier("conversationOrb")
                    if paused || live.connected {
                        Text(paused ? "Paused" : live.muted ? "Muted" : t("proficiency_"+live.voiceState,live.voiceState.capitalized)).font(PiyaliBrand.productFont(12,paused || live.muted ? 600 : 400)).tracking(paused || live.muted ? 0.8 : 0).textCase(paused || live.muted ? .uppercase : nil).padding(.horizontal,10).padding(.vertical,2).background((paused ? Color.yellow : live.muted ? Color.red : .clear).opacity(0.12),in:Capsule()).accessibilityIdentifier("conversationVoiceStatus")
                    }
                }
                if !reply.isEmpty { replyBubble.padding(.horizontal,16).padding(.top,6) }
                if let error=conversation.error ?? live.error { Text(error).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.questionError).padding(12).frame(maxWidth:.infinity,alignment:.leading).background(brand.surface,in:RoundedRectangle(cornerRadius:8)).padding(.horizontal,16).accessibilityIdentifier("conversationError") }
                Color.clear.frame(height:app.activityFooterHeight+12)
            }.padding(.top,8).padding(.bottom,12).frame(maxWidth:672).frame(maxWidth:.infinity)
        }.background(brand.background).foregroundStyle(brand.text)
    }
    private var goalCard:some View {
        VStack(spacing:12) {
            HStack {
                Button { settingsKey=settingsRevision;showSettings=true } label:{ Label(t("ra_conversation_settings","Conversation settings"),systemImage:"gearshape").font(PiyaliBrand.productFont(12,500)) }.opacity(0.7).accessibilityIdentifier("conversationSettings")
                Spacer()
                Button { showHistory=true } label:{ Image(systemName:"bubble.left.and.bubble.right").font(.system(size:14)).frame(width:26,height:26) }.disabled(draft.messages.isEmpty).accessibilityLabel(t("ra_chat_log","Chat log")).accessibilityIdentifier("conversationHistory")
            }
            HStack(spacing:8) {
                Button { showStarter=false;Task { await conversation.shuffleTopic(app) } } label:{ Image(systemName:"dice").font(.system(size:14)).frame(width:26,height:26) }.opacity(0.7).disabled(conversation.busy || live.connected || live.connecting).accessibilityLabel(t("ra_new_topic","New topic")).accessibilityIdentifier("conversationShuffle")
                if let goal=draft.goal {
                    Text(goal.text.localized(app.learner.support)).font(PiyaliBrand.productFont(14,500)).multilineTextAlignment(.center).frame(maxWidth:.infinity).strikethrough(goal.completed).opacity(goal.completed ? 0.6 : 1).accessibilityIdentifier("conversationGoal")
                    if goal.completed { Image(systemName:"checkmark.circle.fill").foregroundStyle(scheme == .dark ? Color.green : PiyaliBrand.unitColor("5f9d8a")).font(.system(size:20)).accessibilityLabel("Goal completed") }
                } else { ProgressView(t("ra_generating_topic","Generating new topic...")).font(PiyaliBrand.productFont(13)).frame(maxWidth:.infinity) }
            }
            if ["Pre-A1","A1"].contains(PerformanceScore.level(score:app.learner.score)),draft.goal?.completed == false {
                Button(showStarter ? t("ra_starter_hide","Hide phrase") : t("ra_starter_show","Help me")) { showStarter.toggle();if showStarter,draft.goal?.starter == nil { Task { await conversation.starter(app) } } }.font(PiyaliBrand.productFont(12,500)).padding(.horizontal,12).padding(.vertical,5).background(brand.surface.opacity(0.6),in:RoundedRectangle(cornerRadius:6)).overlay { RoundedRectangle(cornerRadius:6).stroke(brand.border) }.disabled(conversation.busy).accessibilityIdentifier("conversationStarter")
                if showStarter {
                    HStack(spacing:6) { if let starter=draft.goal?.starter { Button { playStarter(starter) } label:{ Image(systemName:starterPlaying ? "stop.fill" : "speaker.wave.2").font(.system(size:14)) }.accessibilityLabel(t("story_listen","Listen"));Text(starter).font(PiyaliBrand.productFont(14,600)).accessibilityIdentifier("conversationStarterPhrase") } else { ProgressView() } }.padding(.horizontal,12).padding(.vertical,8).background(brand.surface,in:RoundedRectangle(cornerRadius:8)).overlay { RoundedRectangle(cornerRadius:8).stroke(brand.border) }
                    if let translated=draft.goal?.starterSupport,!translated.isEmpty { Text(translated).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary).multilineTextAlignment(.center).accessibilityIdentifier("conversationStarterSupport") }
                }
            }
            if !conversation.feedback.isEmpty,draft.goal?.completed == false {
                Text(conversation.feedback.components(separatedBy:" · +").first ?? conversation.feedback).font(PiyaliBrand.productFont(12)).multilineTextAlignment(.center).padding(.horizontal,12).padding(.vertical,6).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("feb2b2") : PiyaliBrand.unitColor("8f4a5e")).background(Color.red.opacity(0.12),in:RoundedRectangle(cornerRadius:6)).overlay { RoundedRectangle(cornerRadius:6).stroke(Color.red.opacity(0.25)) }.accessibilityIdentifier("conversationFeedback")
            }
        }.buttonStyle(.plain).padding(8).frame(maxWidth:400).background { ConversationGoalSurface(light:scheme != .dark) }.overlay { RoundedRectangle(cornerRadius:16).stroke(brand.border.opacity(scheme == .dark ? 0.3 : 1)) }
    }
    private var replyBubble:some View {
        VStack(alignment:.leading,spacing:10) {
            Text(reply).font(PiyaliBrand.productFont(16)).lineSpacing(6).fixedSize(horizontal:false,vertical:true).textSelection(.enabled).accessibilityIdentifier("conversationLatestReply")
            if let translation=latest?.translation { Text(translation).font(PiyaliBrand.productFont(12)).lineSpacing(4.5).foregroundStyle(brand.secondary).accessibilityIdentifier("conversationTranslation") }
            if let latest,latest.text == reply,latest.translation == nil {
                Button { Task { await conversation.translate(latest,app:app) } } label:{ Label(t("ra_btn_translate","Translate"),systemImage:"character.bubble").font(PiyaliBrand.productFont(12)) }.disabled(conversation.busy).accessibilityIdentifier("conversationTranslate")
            }
        }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background { ConversationGoalSurface(light:scheme != .dark,radius:28) }.overlay { RoundedRectangle(cornerRadius:28,style:.continuous).stroke(scheme == .dark ? .white.opacity(0.06) : brand.border) }.shadow(color:.black.opacity(scheme == .dark ? 0.35 : 0.06),radius:14,y:scheme == .dark ? 14 : 8).frame(maxWidth:.infinity,minHeight:150,alignment:.topLeading)
    }
    @ViewBuilder private var controls:some View {
        if live.connected || paused {
            HStack(spacing:12) {
                callButton(live.muted ? "mic.slash.fill" : "mic.fill",label:live.muted ? "Unmute microphone" : "Mute microphone",selected:live.muted) { live.setMuted(!live.muted) }.disabled(paused || !live.connected).accessibilityIdentifier("conversationMute")
                callButton(paused ? "play.fill" : "pause.fill",label:paused ? "Resume conversation" : "Pause conversation",selected:paused) { if paused { start(resuming:true) } else { pause() } }.accessibilityIdentifier("conversationPause")
                callButton("phone.down.fill",label:"End conversation",stop:true) { paused=false;starterPlaying=false;speech.stopAll();Task { await live.stop();showSummary=true } }.accessibilityIdentifier("conversationEnd")
            }.frame(maxWidth:288).frame(maxWidth:.infinity)
        } else {
            Button { start() } label:{ Label(live.connecting ? t("ra_btn_starting","Starting...") : t("ra_btn_start","Start"),systemImage:"mic.fill") }.buttonStyle(ActivityPrimaryButtonStyle(tone:"speak")).disabled(live.connecting || conversation.busy || draft.goal == nil).accessibilityIdentifier("conversationStart")
        }
    }
    private func callButton(_ icon:String,label:String,selected:Bool=false,stop:Bool=false,action:@escaping()->Void)->some View {
        Button(action:action) { Image(systemName:icon).font(.system(size:17,weight:.semibold)).frame(maxWidth:.infinity,minHeight:40).foregroundStyle(stop ? .white : brand.text).background { RoundedRectangle(cornerRadius:18).fill(stop ? AnyShapeStyle(LinearGradient(colors:[PiyaliBrand.unitColor("b0005b"),PiyaliBrand.unitColor("880046")],startPoint:.topLeading,endPoint:.bottomTrailing)) : AnyShapeStyle(selected ? brand.surface.opacity(0.88) : Color.clear)) } }.buttonStyle(.plain).accessibilityLabel(label).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func start(resuming:Bool=false) {
        guard !live.connecting,!conversation.busy,allowed,let _=draft.goal else { return }
        active=true;starterPlaying=false;speech.stopAll();showSummary=false;pausedReply=""
        if !resuming { baseXP=draft.earnedXP;baseTurns=draft.turns;baseGoals=draft.goalsCompleted;pausedMuted=false }
        var context=draft;if !resuming { context.messages=[] }
        let account=app.identity.npub,target=app.learner.target,support=app.learner.support,session=draft.id
        paused=false
        Task { await live.start(learner:app.learner,conversationDraft:context,initiallyMuted:resuming && pausedMuted,onInputTurn:{ input in
            guard active,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session,allowed else { return }
            Task { await conversation.voiceTurn(input.text,answered:input.answered,reply:"",id:UUID(),app:app,providerID:input.id,beforeResponseID:input.responseID);guard active,app.identity.npub == account,app.learner.target == target,app.learner.conversation.id == session else { return };await live.updateConversation(app.learner.conversation,learner:app.learner) }
        },onAssistantTurn:{ id,text in
            guard active,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session,allowed else { return }
            conversation.assistantReply(text,providerID:id,app:app)
        }) }
    }
    private func playStarter(_ text:String) {
        if starterPlaying { stopStarter();return }
        let cleaned=text.replacingOccurrences(of:"_+",with:" ",options:.regularExpression).replacingOccurrences(of:"\\s{2,}",with:" ",options:.regularExpression).replacingOccurrences(of:"\\s+([.,!?;:])",with:"$1",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return };starterPlaying=true;live.setPlaybackDucked(true)
        speech.speakSeries([cleaned],language:app.learner.target,onInterrupted:{stopStarter()},keepsVoiceSession:live.connected,onFinished:{stopStarter()})
    }
    private func stopStarter() { speech.stopAll();starterPlaying=false;live.setPlaybackDucked(false) }
    private func pause() { starterPlaying=false;pausedMuted=live.muted;pausedReply=reply;paused=true;speech.stopAll();Task { await live.stop() } }
    private func stop() { starterPlaying=false;active=false;paused=false;conversation.cancel();speech.stopAll();Task { await live.stop() } }
    private func settingsClosed() { if settingsRevision != settingsKey { showStarter=false;Task { await conversation.shuffleTopic(app);await live.updateConversation(app.learner.conversation,learner:app.learner) } } }
    private func change(_ update:(inout ConversationDraft)->Void) { var next=draft;update(&next);app.learner.saveConversation(next);app.persist();Task { await live.updateConversation(app.learner.conversation,learner:app.learner) } }
    private var settingsSheet:some View {
        NavigationStack {
            ScrollView { VStack(alignment:.leading,spacing:24) {
                VStack(alignment:.leading,spacing:8) { Text(setting("proficiencyLabel")).font(PiyaliBrand.productFont(14,600));Text(setting("proficiencyHint")).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary)
                    Menu { ForEach(Self.copy["levels"].array,id:\.json) { level in Button { change { $0.challengeLevel=level["level"].string } } label:{ Text(level["level"].string+" · "+level["name"].localized(app.learner.support)) } } } label:{ let level=Self.copy["levels"].array.first { $0["level"].string == (draft.challengeLevel ?? "Pre-A1") } ?? .null
                        HStack { Text(level["level"].string == "Pre-A1" ? "A0" : level["level"].string).font(PiyaliBrand.productFont(14,700)).foregroundStyle(.white).padding(6).background(PiyaliBrand.unitColor(level["color"].string),in:RoundedRectangle(cornerRadius:6));VStack(alignment:.leading,spacing:3) { Text(level["name"].localized(app.learner.support)).font(PiyaliBrand.productFont(14,500));Text(level["description"].localized(app.learner.support)).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary) };Spacer();Image(systemName:"chevron.down") }.padding(12).background(brand.background,in:RoundedRectangle(cornerRadius:10))
                    }.accessibilityIdentifier("conversationLevel")
                }
                Toggle(isOn:Binding(get:{draft.pronunciation},set:{value in change {$0.pronunciation=value}})) { VStack(alignment:.leading,spacing:5) { Text(setting("pronunciationLabel")).font(PiyaliBrand.productFont(14,600));Text(setting("pronunciationHint")).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary) } }.tint(PiyaliBrand.unitColor("00b5d8")).accessibilityIdentifier("conversationPronunciation")
                VStack(alignment:.leading,spacing:8) { Text(setting("subjectLabel")).font(PiyaliBrand.productFont(14,600));Text(setting("subjectHint")).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary);TextField(setting("subjectPlaceholder"),text:Binding(get:{draft.interests},set:{value in change {$0.interests=String(value.prefix(600))}}),axis:.vertical).lineLimit(5...8).font(PiyaliBrand.productFont(16)).padding(12).background(brand.background,in:RoundedRectangle(cornerRadius:10)).accessibilityIdentifier("conversationTopics") }
            }.padding(20) }.background(brand.surface).foregroundStyle(brand.text).navigationTitle(t("ra_conversation_settings","Conversation settings")).navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.confirmationAction) { Button(setting("close")) { showSettings=false } } }
        }
    }
    private var historySheet:some View {
        NavigationStack { ScrollView { LazyVStack(alignment:.leading,spacing:12) {
            ForEach(draft.messages) { message in HStack { if message.role == "user" { Spacer(minLength:36) };VStack(alignment:.leading,spacing:8) { Text(message.role == "user" ? t("ra_you","You") : "Piyali").font(PiyaliBrand.productFont(11,600)).foregroundStyle(brand.secondary);Text(message.text).font(PiyaliBrand.productFont(16)).textSelection(.enabled);if let translated=message.translation { Text(translated).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.secondary) };if message.role == "assistant",message.translation == nil { Button(t("ra_btn_translate","Translate")) { Task { await conversation.translate(message,app:app) } }.disabled(conversation.busy) } }.padding(14).background(message.role == "user" ? Color.cyan.opacity(0.1) : brand.surface,in:RoundedRectangle(cornerRadius:16));if message.role != "user" { Spacer(minLength:24) } } }
            Button("Save transcript to notes") { app.learner.notes.insert(.init(title:"Conversation · "+app.learner.target,body:draft.transcript),at:0);app.persist() }.buttonStyle(.bordered).accessibilityIdentifier("conversationSave")
        }.padding(16) }.background(brand.background).foregroundStyle(brand.text).navigationTitle(t("ra_conversation_log","Conversation log")).navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { showHistory=false } } } }
    }
    private var summarySheet:some View {
        VStack(spacing:20) {
            StoryCharacterAvatar(name:"Piyali",portraitID:"34",size:76).padding(8).background(.white.opacity(0.2),in:Circle()).overlay { Circle().stroke(.white.opacity(0.3),lineWidth:2) }
            Text(summary("title")).font(PiyaliBrand.productFont(26,700)).multilineTextAlignment(.center)
            VStack(spacing:16) {
                VStack(spacing:4) { Text(summary("xpEarned").uppercased()).font(PiyaliBrand.productFont(14)).opacity(0.82);Text("+\(max(0,draft.earnedXP-baseXP))").font(PiyaliBrand.productFont(44,700)).foregroundStyle(PiyaliBrand.unitColor("f6e05e")) }.accessibilityElement(children:.combine).accessibilityIdentifier("conversationSummaryXP")
                HStack(spacing:12) { summaryMetric(max(0,draft.goalsCompleted-baseGoals),summary("goalsCompleted"),id:"conversationSummaryGoals");summaryMetric(max(0,draft.turns-baseTurns),summary("speakingTurns"),id:"conversationSummaryTurns") }
                HStack { Text(t("ra_label_level","Level")+" \(app.learner.xp/100+1)");Spacer();Text(t("ra_label_xp","XP")+" \(app.learner.xp)") }.font(PiyaliBrand.productFont(12,600))
                ProgressView(value:Double(app.learner.xp%100),total:100).tint(.yellow)
            }.padding(20).background(.white.opacity(0.18),in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.38),lineWidth:2) }
            Button(summary("done")) { showSummary=false }.font(PiyaliBrand.productFont(17,700)).foregroundStyle(PiyaliBrand.unitColor("805ad5")).frame(maxWidth:.infinity,minHeight:48).background(.white,in:RoundedRectangle(cornerRadius:12)).accessibilityIdentifier("conversationSummaryDone")
        }.padding(24).frame(maxWidth:.infinity,maxHeight:.infinity).foregroundStyle(.white).background(LinearGradient(colors:[PiyaliBrand.unitColor("667eea"),PiyaliBrand.unitColor("764ba2")],startPoint:.topLeading,endPoint:.bottomTrailing))
    }
    private func summaryMetric(_ value:Int,_ label:String,id:String)->some View { VStack(spacing:4) { Text("\(value)").font(PiyaliBrand.productFont(24,700));Text(label).font(PiyaliBrand.productFont(12)).multilineTextAlignment(.center) }.frame(maxWidth:.infinity,minHeight:64).background(.white.opacity(0.12),in:RoundedRectangle(cornerRadius:8)).accessibilityElement(children:.combine).accessibilityIdentifier(id) }
}

private struct ConversationGoalSurface:View {
    let light:Bool
    var radius:CGFloat=16
    var body:some View {
        ZStack {
            LinearGradient(colors:light ? [PiyaliBrand.unitColor("fff9f2"),PiyaliBrand.unitColor("f8f1e8")] : [PiyaliBrand.unitColor("02060e"),PiyaliBrand.unitColor("01030a")],startPoint:.top,endPoint:.bottom)
            RadialGradient(colors:[(light ? Color.brown : Color.blue).opacity(0.12),.clear],center:.init(x:0.2,y:0.15),startRadius:0,endRadius:180)
            Canvas { context,size in var grid=Path();for x in stride(from:CGFloat(0),to:size.width,by:28) { grid.move(to:.init(x:x,y:0));grid.addLine(to:.init(x:x,y:size.height)) };for y in stride(from:CGFloat(0),to:size.height,by:28) { grid.move(to:.init(x:0,y:y));grid.addLine(to:.init(x:size.width,y:y)) };context.stroke(grid,with:.color((light ? Color.brown : Color.gray).opacity(light ? 0.012 : 0.025)),lineWidth:1) }
        }.clipShape(RoundedRectangle(cornerRadius:radius,style:.continuous))
    }
}
