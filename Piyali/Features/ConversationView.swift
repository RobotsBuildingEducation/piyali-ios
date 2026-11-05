import SwiftUI

struct ConversationView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var conversation=ConversationService()
    @StateObject private var speech=SpeechService()
    @StateObject private var live:LiveTutorService
    @State private var showStarter=false
    @State private var showSettings=false
    @State private var showHistory=false
    @State private var historyContentHeight:CGFloat=300
    @State private var archivePrevious:ConversationVisibleReply?
    @State private var archive:ConversationArchive?
    @State private var archiveHiddenID:String?
    @State private var archivePulse=false
    @State private var archiveTextFrame=CGRect.zero
    @State private var archiveButtonFrame=CGRect.zero
    @State private var archiveWork:Task<Void,Never>?
    @State private var showSummary=false
    @State private var paused=false
    @State private var pausedMuted=false
    @State private var active=false
    @State private var starterPlaying=false
    @State private var pausedReply=""
    @State private var pausedSpeech:String?
    @State private var pauseWork:Task<Void,Never>?
    @State private var connectionEpoch=UUID()
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
    private var showTranslations:Bool { app.learner.settingsSnapshot["progress"]["showTranslations"] != .bool(false) }
    private func translation(_ message:ConversationMessage)->String { conversation.translationDrafts[message.id] ?? message.translation(for:app.learner.support) ?? "" }
    private func pairs(_ message:ConversationMessage)->JSONValue {message.translationLang == app.learner.support ? message.pairs ?? .array([]) : .array([])}
    private func translationAction(_ message:ConversationMessage?)->(()->Void)? {guard let message else{return nil};return {Task {await conversation.translate(message,app:app)}}}
    private var reply:String { !live.assistantTurnText.isEmpty ? live.assistantTurnText : paused && !pausedReply.isEmpty ? pausedReply : latest?.text ?? "" }
    private var visibleReply:ConversationVisibleReply? {
        guard !reply.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return nil}
        let id = !live.assistantTurnText.isEmpty && !live.assistantResponseID.isEmpty ? live.assistantResponseID : (latest?.providerID ?? latest?.id.uuidString ?? "")
        return id.isEmpty ? nil:ConversationVisibleReply(id:id,text:reply)
    }
    private var footerRevision:String { "\(live.connected)|\(live.connecting)|\(live.muted)|\(paused)|\(conversation.busy)|\(draft.goal?.id.uuidString ?? "")" }
    private var settingsRevision:String { (draft.challengeLevel ?? "")+"|"+draft.interests }
    private var allowed:Bool { app.subscription.hasAccess || conversation.fixture }
    var body:some View {
        Group { if conversation.fixture { content } else { SubscriptionRequiredView(service:app.subscription) { content } } }
            .navigationTitle(t("course_conversation","Conversation")).navigationBarTitleDisplayMode(.inline)
            .task(id:app.identity.npub+":"+app.learner.target+":"+app.learner.support+":"+String(allowed)) {
                active=false;resetArchive();connectionEpoch=UUID();conversation.cancel();speech.stopAll();paused=false;pausedReply="";pausedSpeech=nil;pauseWork=nil;showStarter=false;starterPlaying=false
                await live.stop(clearTranscript:true);guard !Task.isCancelled else { return };active=true;archivePrevious=visibleReply;await conversation.prepare(app)
            }
            .activityFooter(owner:footerOwner,revision:footerRevision,access:app.subscription,fixtureAllowed:conversation.fixture) { ActivityFooterSurface(hasFeedback:false,feedback:{EmptyView()},actions:{controls}) }
            .onChange(of:scenePhase) { _,phase in if phase == .background { stop() } }
            .onChange(of:app.subscription.hasAccess) { _,access in if !access { stop() } }
            .onChange(of:draft.goal?.id) { _,_ in stopStarter();showStarter=false;Task { await live.updateConversation(app.learner.conversation,learner:app.learner) } }
            .onChange(of:app.plateCourseCompletion?.id){_,_ in if app.plateCourseCompletion?.kind == "conversation"{stop()}}
            .onChange(of:visibleReply) { _,value in updateArchive(value) }
            .onDisappear { resetArchive();stop() }
            .sheet(isPresented:$showSettings,onDismiss:settingsClosed) { settingsSheet.presentationDetents([.fraction(0.8)]).presentationDragIndicator(.visible) }
            .fullScreenCover(isPresented:$showHistory) { historySheet.presentationBackground(.clear) }
            .fullScreenCover(isPresented:$showSummary) { summaryDialog.presentationBackground(.clear) }
    }
    private var content:some View {
        ScrollView {
            VStack(spacing:6) {
                goalCard.padding(.horizontal,16)
                VStack(spacing:2) {
                    VoiceOrbView(state:OrbVisuals.conversationState(live.voiceState),callActive:live.connected,feedback:conversation.orbFeedback,audioLevel:live.audioLevel,dark:scheme == .dark,reducedMotion:reduceMotion,animating:scenePhase == .active && !showSummary && !showSettings && !showHistory).frame(width:64,height:64).opacity(0.95).frame(width:112).accessibilityElement(children:.ignore).accessibilityLabel("Tutor orb").accessibilityValue(scheme == .dark ? "Blue animated sphere" : "Mint animated sphere").accessibilityIdentifier("conversationOrb")
                    if paused || live.connected {
                        Text(paused ? "Paused" : live.muted ? "Muted" : t("proficiency_"+live.voiceState,live.voiceState.capitalized)).font(PiyaliBrand.productFont(12,paused || live.muted ? 600 : 400)).tracking(paused || live.muted ? 0.8 : 0).textCase(paused || live.muted ? .uppercase : nil).padding(.horizontal,10).padding(.vertical,2).background((paused ? Color.yellow : live.muted ? Color.red : .clear).opacity(0.12),in:Capsule()).accessibilityIdentifier("conversationVoiceStatus")
                    }
                }
                if !reply.isEmpty { replyBubble.padding(.horizontal,16).padding(.top,6) }
                if let error=conversation.error ?? live.error { Text(error).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.questionError).padding(12).frame(maxWidth:.infinity,alignment:.leading).background(brand.surface,in:RoundedRectangle(cornerRadius:8)).padding(.horizontal,16).accessibilityIdentifier("conversationError") }
                Color.clear.frame(height:app.activityFooterHeight+12)
            }.padding(.top,8).padding(.bottom,12).frame(maxWidth:672).frame(maxWidth:.infinity)
        }.background(brand.background).foregroundStyle(brand.text)
            .overlay {if let archive {ConversationArchiveView(archive:archive,dark:scheme == .dark)}}
            .coordinateSpace(name:"conversationArchive")
    }
    private var goalCard:some View {
        VStack(spacing:12) {
            HStack {
                Button { settingsKey=settingsRevision;showSettings=true } label:{ Label(t("ra_conversation_settings","Conversation settings"),systemImage:"gearshape").font(PiyaliBrand.productFont(12,500)) }.opacity(0.7).accessibilityIdentifier("conversationSettings")
                Spacer()
                Button { showHistory=true } label:{ Image(systemName:"bubble.left.and.bubble.right").font(.system(size:14)).frame(width:26,height:26).foregroundStyle(scheme == .dark ? (archivePulse ? Color.white:brand.text):PiyaliBrand.unitColor(archivePulse ? "69533d":"8b755f"))
                    .background(scheme == .dark ? Color.clear:PiyaliBrand.unitColor("fffaf1").opacity(archivePulse ? 0.96:0.58),in:RoundedRectangle(cornerRadius:6))
                    .overlay {if scheme != .dark {RoundedRectangle(cornerRadius:6).strokeBorder(PiyaliBrand.unitColor(archivePulse ? "6ec1d6":"bfa88b").opacity(archivePulse ? 0.56:0.34))}}
                    .shadow(color:PiyaliBrand.unitColor(scheme == .dark ? "3b82f6":"6ec1d6").opacity(archivePulse ? 0.35:0),radius:archivePulse ? 9:0).scaleEffect(archivePulse ? 1.015:1)
                }.buttonStyle(.plain).animation(.easeOut(duration:0.22),value:archivePulse).disabled(draft.messages.isEmpty).accessibilityLabel(t("ra_chat_log","Chat log")).accessibilityValue(conversation.fixture && archivePulse ? "Archiving":"").accessibilityIdentifier("conversationHistory").onGeometryChange(for:CGRect.self,of:{$0.frame(in:.named("conversationArchive"))}){archiveButtonFrame=$0}
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
    private func resetArchive() {archiveWork?.cancel();archiveWork=nil;archivePrevious=nil;archive=nil;archiveHiddenID=nil;archivePulse=false;archiveTextFrame = .zero;archiveButtonFrame = .zero}
    private func updateArchive(_ next:ConversationVisibleReply?) {
        guard let next else{return}
        defer {archivePrevious=next}
        guard let previous=archivePrevious,previous.id != next.id,active,!reduceMotion,!showHistory,!showSummary,let flight=ConversationArchive(text:previous.text,source:archiveTextFrame,target:archiveButtonFrame) else{return}
        archiveWork?.cancel();archive=flight;archiveHiddenID=next.id;archivePulse=true
        archiveWork=Task { @MainActor in
            do {try await Task.sleep(for:.milliseconds(170));guard !Task.isCancelled,archive?.id == flight.id else{return};archiveHiddenID=nil
                try await Task.sleep(for:.milliseconds(1180));guard !Task.isCancelled,archive?.id == flight.id else{return};archive=nil;archivePulse=false;archiveWork=nil
            } catch {return}
        }
    }
    private var replyBubble:some View {
        let message:ConversationMessage? = if !live.assistantResponseID.isEmpty,conversation.liveReply?.providerID == live.assistantResponseID,!live.assistantTurnText.isEmpty {conversation.liveReply} else if !live.assistantResponseID.isEmpty,latest?.providerID == live.assistantResponseID,!live.assistantTurnText.isEmpty {latest} else {latest?.text == reply ? latest:nil}
        return TutorReplyView(primary:reply,secondary:message.map(translation) ?? "",target:app.learner.target,support:app.learner.support,pairs:message.map(pairs) ?? .array([]),showSecondary:showTranslations,replayAvailable:false,showPairCards:false,conversationAppearance:true,primaryIdentifier:"conversationLatestReply",secondaryIdentifier:"conversationTranslation",translating:message.map {conversation.translating.contains($0.id)} ?? false,onTranslate:showTranslations ? translationAction(message):nil,archiveHidden:archiveHiddenID != nil && archiveHiddenID == visibleReply?.id,onPrimaryFrame:{archiveTextFrame=$0},onReplay:{})
            .frame(maxWidth:.infinity,minHeight:150,alignment:.topLeading)
    }
    @ViewBuilder private var controls:some View {
        if live.connected || paused {
            HStack(spacing:12) {
                callButton(live.muted ? "mic.slash.fill" : "mic.fill",label:live.muted ? "Unmute microphone" : "Mute microphone",selected:live.muted) { live.setMuted(!live.muted) }.disabled(paused || !live.connected).accessibilityIdentifier("conversationMute")
                callButton(paused ? "play.fill" : "pause.fill",label:paused ? "Resume conversation" : "Pause conversation",selected:paused) { if paused { start(resuming:true) } else { pause() } }.accessibilityIdentifier("conversationPause")
                callButton("phone.down.fill",label:"End conversation",stop:true) { end() }.accessibilityIdentifier("conversationEnd")
            }.frame(maxWidth:288).frame(maxWidth:.infinity)
        } else {
            Button { start() } label:{ Label(live.connecting ? t("ra_btn_starting","Starting...") : t("ra_btn_start","Start"),systemImage:"mic.fill") }.buttonStyle(ActivityPrimaryButtonStyle(tone:"speak")).disabled(live.connecting || conversation.busy || draft.goal == nil).accessibilityIdentifier("conversationStart")
        }
    }
    private func callButton(_ icon:String,label:String,selected:Bool=false,stop:Bool=false,action:@escaping()->Void)->some View {
        Button(action:action) { Image(systemName:icon).font(.system(size:17,weight:.semibold)).frame(maxWidth:.infinity,minHeight:40).foregroundStyle(stop ? .white : brand.text).background { RoundedRectangle(cornerRadius:18).fill(stop ? AnyShapeStyle(LinearGradient(colors:[PiyaliBrand.unitColor("b0005b"),PiyaliBrand.unitColor("880046")],startPoint:.topLeading,endPoint:.bottomTrailing)) : AnyShapeStyle(selected ? brand.surface.opacity(0.88) : Color.clear)) } }.buttonStyle(.plain).accessibilityLabel(label).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func start(resuming:Bool=false) {
        guard !live.connecting,(!conversation.busy || resuming),allowed,let _=draft.goal else { return }
        active=true;starterPlaying=false;speech.stopAll();showSummary=false
        if !resuming { baseXP=draft.earnedXP;baseTurns=draft.turns;baseGoals=draft.goalsCompleted;pausedMuted=false }
        var context=draft;if !resuming { context.messages=[] }
        let account=app.identity.npub,target=app.learner.target,support=app.learner.support,session=draft.id
        let interrupted=resuming ? pausedSpeech:nil,waiting=pauseWork,token=UUID();connectionEpoch=token;paused=false
        if !resuming {pausedSpeech=nil;pausedReply=""}
        Task {
            if resuming {await waiting?.value}
            guard active,connectionEpoch == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session,allowed else{return}
            await live.start(learner:app.learner,conversationDraft:context,initiallyMuted:resuming && pausedMuted,resumeInterrupted:interrupted,onInputTurn:{ input in
            guard active,connectionEpoch == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session,allowed else { return }
            Task { await conversation.voiceTurn(input.text,answered:input.answered,reply:"",id:UUID(),app:app,providerID:input.id,beforeResponseID:input.responseID);guard active,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session else { return };await live.updateConversation(app.learner.conversation,learner:app.learner) }
        },onAssistantTurn:{ id,text in
            guard active,connectionEpoch == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session,allowed else { return }
            conversation.assistantReply(text,providerID:id,app:app)
        },onAssistantProgress:{ id,text in
            guard active,connectionEpoch == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session,allowed else{return}
            conversation.observeLiveReply(text,providerID:id,app:app)
        },onAssistantInterrupted:{ id,text in
            guard active,connectionEpoch == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session,allowed else{return}
            conversation.preserveInterruptedReply(text,providerID:id,app:app)
            })
            guard active,connectionEpoch == token,app.identity.npub == account,app.learner.target == target,app.learner.support == support,app.learner.conversation.id == session else{return}
            if live.connected {pausedSpeech=nil;pauseWork=nil} else if resuming {paused=true}
        }
    }
    private func playStarter(_ text:String) {
        if starterPlaying { stopStarter();return }
        let cleaned=text.replacingOccurrences(of:"_+",with:" ",options:.regularExpression).replacingOccurrences(of:"\\s{2,}",with:" ",options:.regularExpression).replacingOccurrences(of:"\\s+([.,!?;:])",with:"$1",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return };starterPlaying=true;live.setPlaybackDucked(true)
        speech.speakSeries([cleaned],language:app.learner.target,onInterrupted:{stopStarter()},keepsVoiceSession:live.connected,onFinished:{stopStarter()})
    }
    private func stopStarter() { speech.stopAll();starterPlaying=false;live.setPlaybackDucked(false) }
    private func pause() {
        guard live.connected else{return};starterPlaying=false;pausedMuted=live.muted;pausedReply=reply;pausedSpeech=live.hasPendingAssistant ? (live.outputPending ? live.assistantTurnText : "") : nil
        if live.outputPending,!live.assistantTurnText.isEmpty {conversation.preserveInterruptedReply(live.assistantTurnText,providerID:live.assistantResponseID,app:app)}
        connectionEpoch=UUID();paused=true;speech.stopAll();pauseWork=Task {await live.stop()}
    }
    private func end() {if live.outputPending,!live.assistantTurnText.isEmpty {conversation.preserveInterruptedReply(live.assistantTurnText,providerID:live.assistantResponseID,app:app)};connectionEpoch=UUID();paused=false;pausedSpeech=nil;starterPlaying=false;speech.stopAll();let waiting=pauseWork;pauseWork=nil;Task {await waiting?.value;await live.stop();var transaction=Transaction();transaction.disablesAnimations=true;withTransaction(transaction) {showSummary=true}}}
    private func stop() { connectionEpoch=UUID();starterPlaying=false;active=false;paused=false;pausedSpeech=nil;pauseWork=nil;conversation.cancel();speech.stopAll();Task { await live.stop() } }
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
        GeometryReader { geometry in
            ZStack(alignment:.top) {
                (scheme == .dark ? PiyaliBrand.unitColor("020617").opacity(0.92):PiyaliBrand.unitColor("1c140c").opacity(0.82)).ignoresSafeArea().onTapGesture {showHistory=false}
                VStack(alignment:.leading,spacing:0) {
                    HStack(spacing:12) {
                        Text(t("ra_conversation_log","Conversation log")).font(PiyaliBrand.productFont(20,700)).accessibilityIdentifier("conversationHistoryTitle")
                            .contextMenu {Button("Save transcript to notes") { app.learner.notes.insert(.init(title:"Conversation · "+app.learner.target,body:draft.transcript),at:0);app.persist() }.accessibilityIdentifier("conversationSave")}
                        Spacer(minLength:0)
                        Button {showHistory=false} label:{Image(systemName:"xmark").font(.system(size:15,weight:.medium)).frame(width:32,height:32).contentShape(Rectangle())}.buttonStyle(.plain).accessibilityLabel(t("close","Close")).accessibilityIdentifier("conversationHistoryClose")
                    }.padding(.leading,32).padding(.trailing,20).padding(.vertical,24)
                    ScrollView {
                        LazyVStack(alignment:.leading,spacing:12) {
                            ForEach(Array(draft.messages.reversed())) { message in HStack(alignment:.top,spacing:0) {
                                if message.role == "user" { Spacer(minLength:0);ViewThatFits(in:.horizontal) { historyUser(message).fixedSize(horizontal:true,vertical:false);historyUser(message) }.frame(maxWidth:max(0,(geometry.size.width-80)*0.95),alignment:.trailing) }
                                else { ViewThatFits(in:.horizontal) {historyReply(message).fixedSize(horizontal:true,vertical:false);historyReply(message)}.frame(maxWidth:max(0,(geometry.size.width-80)*0.95),alignment:.leading);Spacer(minLength:0) }
                            } }
                        }.padding(.horizontal,28).padding(.top,28).padding(.bottom,28)
                            .onGeometryChange(for:CGFloat.self,of:{$0.size.height}){historyContentHeight=$0}
                    }.frame(height:min(max(historyContentHeight,1),max(1,geometry.size.height-168)))
                }.foregroundStyle(scheme == .dark ? .white:PiyaliBrand.unitColor("2f261d"))
                    .background(PiyaliBrand.unitColor(scheme == .dark ? "111827":"f1e8dc"),in:RoundedRectangle(cornerRadius:48,style:.continuous))
                    .overlay {RoundedRectangle(cornerRadius:48,style:.continuous).strokeBorder(scheme == .dark ? PiyaliBrand.unitColor("94a3b8").opacity(0.3):PiyaliBrand.unitColor("604d38").opacity(0.3),lineWidth:3).allowsHitTesting(false)}
                    .clipShape(RoundedRectangle(cornerRadius:48,style:.continuous)).padding(.horizontal,12).padding(.top,64)
            }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.top).ignoresSafeArea()
        }
    }
    private func historyUser(_ message:ConversationMessage)->some View {
        ConversationUserBubble(text:message.text,language:app.learner.target).accessibilityIdentifier("conversationHistoryUser-\(message.id.uuidString)")
    }
    private func historyReply(_ message:ConversationMessage)->some View {
        TutorReplyView(primary:message.text,secondary:translation(message),target:app.learner.target,support:app.learner.support,pairs:pairs(message),showSecondary:showTranslations,replayAvailable:false,showPairCards:false,conversationAppearance:true,primaryIdentifier:"conversationHistoryReply-\(message.id.uuidString)",secondaryIdentifier:"conversationHistoryTranslation-\(message.id.uuidString)",translateIdentifier:"conversationHistoryTranslate-\(message.id.uuidString)",translating:conversation.translating.contains(message.id),onTranslate:showTranslations ? translationAction(message):nil,onReplay:{})
    }
    private func closeSummary() { var transaction=Transaction();transaction.disablesAnimations=true;withTransaction(transaction) {showSummary=false} }
    private var summaryDialog:some View {
        GeometryReader { geometry in
            ZStack {
                (scheme == .dark ? Color(red:2/255,green:6/255,blue:23/255).opacity(0.92) : Color(red:28/255,green:20/255,blue:12/255).opacity(0.82)).ignoresSafeArea().contentShape(Rectangle()).onTapGesture { closeSummary() }
                ScrollView {
                    VStack(spacing:0) {
                        Color.clear.frame(minHeight:12,maxHeight:.infinity).contentShape(Rectangle()).onTapGesture {closeSummary()}
                        summaryCard.frame(maxWidth:448)
                        Color.clear.frame(minHeight:12,maxHeight:.infinity).contentShape(Rectangle()).onTapGesture {closeSummary()}
                    }.frame(minHeight:geometry.size.height)
                }.frame(width:geometry.size.width*0.95).scrollBounceBehavior(.basedOnSize)
            }.frame(maxWidth:.infinity,maxHeight:.infinity).accessibilityElement(children:.contain).accessibilityIdentifier("conversationSummaryDialog")
        }.ignoresSafeArea().accessibilityAction(.escape) { closeSummary() }
    }
    private var summaryCard:some View {
        VStack(spacing:16) {
            BrandArtwork(name:StoryCharacterAvatar.appearance.portraitFile("34")).frame(width:76,height:76).padding(10).background(.white.opacity(0.2),in:Circle()).overlay { Circle().stroke(.white.opacity(0.3),lineWidth:2) }
            Text(summary("title")).font(PiyaliBrand.productFont(24,700)).multilineTextAlignment(.center)
            VStack(spacing:16) {
                VStack(spacing:4) { Text(summary("xpEarned").uppercased()).font(PiyaliBrand.productFont(14)).frame(height:21).opacity(0.82);Text("+\(max(0,draft.earnedXP-baseXP))").font(PiyaliBrand.productFont(36,700)).frame(height:36).foregroundStyle(PiyaliBrand.unitColor("f6e05e")) }.accessibilityElement(children:.combine).accessibilityIdentifier("conversationSummaryXP")
                HStack(spacing:12) { summaryMetric(max(0,draft.goalsCompleted-baseGoals),summary("goalsCompleted"),id:"conversationSummaryGoals");summaryMetric(max(0,draft.turns-baseTurns),summary("speakingTurns"),id:"conversationSummaryTurns") }
                VStack(spacing:4) {
                    HStack { Text(t("ra_label_level","Level")+" \(app.learner.xp/100+1)").font(PiyaliBrand.productFont(14,700));Spacer();Text(t("ra_label_xp","XP")+" \(app.learner.xp)").font(PiyaliBrand.productFont(12,800)).tracking(0.24).frame(height:18).padding(.horizontal,10).padding(.vertical,5).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("dbe6f3") : PiyaliBrand.unitColor("6f5a47")).background(scheme == .dark ? PiyaliBrand.unitColor("111827").opacity(0.92) : PiyaliBrand.unitColor("fffdf9").opacity(0.96),in:RoundedRectangle(cornerRadius:6)) }
                    ConversationXPBar(value:Double(app.learner.xp%100))
                }.padding(.top,4)
            }.padding(.horizontal,22).padding(.vertical,18).background(.white.opacity(0.18),in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.38),lineWidth:2) }
            Button(summary("done")) { closeSummary() }.font(PiyaliBrand.productFont(18,700)).foregroundStyle(PiyaliBrand.unitColor("6b46c1")).frame(maxWidth:.infinity,minHeight:48).background(.white,in:RoundedRectangle(cornerRadius:12)).accessibilityIdentifier("conversationSummaryDone")
        }.padding(.horizontal,28).padding(.vertical,28).frame(maxWidth:.infinity).foregroundStyle(.white).background(LinearGradient(colors:[PiyaliBrand.unitColor("667eea"),PiyaliBrand.unitColor("764ba2")],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:48,style:.continuous)).shadow(color:.black.opacity(0.28),radius:25,y:20)
    }
    private func summaryMetric(_ value:Int,_ label:String,id:String)->some View { VStack(spacing:4) { Text("\(value)").font(PiyaliBrand.productFont(24,700));Text(label).font(PiyaliBrand.productFont(12)).multilineTextAlignment(.center) }.frame(maxWidth:.infinity,minHeight:63).background(.white.opacity(0.12),in:RoundedRectangle(cornerRadius:8)).accessibilityElement(children:.combine).accessibilityIdentifier(id) }
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

private struct ConversationXPBar:View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value:Double
    @State private var fill=0.0
    var body:some View {
        GeometryReader { geometry in
            ZStack(alignment:.leading) {
                Capsule().fill(.white.opacity(0.8))
                LinearGradient(colors:[PiyaliBrand.unitColor("43e97b"),PiyaliBrand.unitColor("38f9d7")],startPoint:.leading,endPoint:.trailing).opacity(0.9).frame(width:geometry.size.width*fill)
            }.clipShape(Capsule()).overlay { Capsule().stroke(PiyaliBrand.unitColor("ededed")) }
        }.frame(height:15).task(id:value) { withAnimation(reduceMotion ? nil : .timingCurve(0.22,1,0.36,1,duration:0.8)) {fill=max(0,min(100,value))/100} }.accessibilityLabel("Experience progress").accessibilityValue("\(Int(value)) percent")
    }
}

/// Source Conversation UserBubble: text only, 28-point radius, themed fill.
struct ConversationUserBubble:View {
    let text:String,language:String
    @Environment(\.colorScheme) private var scheme
    private var dark:Bool { scheme == .dark }
    var body:some View {
        Text(text).font(PiyaliBrand.productFont(16)).lineSpacing(max(0,25-UIFont.systemFont(ofSize:16).lineHeight)).padding(.vertical,max(0,25-UIFont.systemFont(ofSize:16).lineHeight)/2).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading).textSelection(.enabled)
            .environment(\.layoutDirection,["ar","he","fa","ur"].contains(language) ? .rightToLeft:.leftToRight)
            .foregroundStyle(dark ? .white:PiyaliBrand.unitColor("2f261d"))
            .padding(12).padding(1)
            .background(dark ? PiyaliBrand.unitColor("3182ce"):PiyaliBrand.unitColor("6cb6bf").opacity(0.16),in:RoundedRectangle(cornerRadius:28))
            .overlay { RoundedRectangle(cornerRadius:28).strokeBorder(dark ? .white.opacity(0.08):PiyaliBrand.unitColor("6cb6bf").opacity(0.22)) }
            .shadow(color:dark ? .black.opacity(0.25):PiyaliBrand.unitColor("6f5636").opacity(0.08),radius:dark ? 10:9,y:dark ? 6:8)
    }
}

private struct ConversationVisibleReply:Equatable {let id:String,text:String}
