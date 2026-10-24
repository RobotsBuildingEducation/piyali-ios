import SwiftUI

/// Native renderer of the curriculum's RealTimeTest goal, distinct from free chat.
struct RealtimeLessonView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var service=RealtimeLessonService()
    @StateObject private var live=LiveTutorService()
    @StateObject private var speech=SpeechService()
    let lesson:Lesson
    var onNext:(()->Void)?=nil
    var startsFresh=false
    @State private var showStarter=false
    @State private var showHistory=false
    @State private var paused=false
    @State private var hasAppeared=false
    @State private var active=false
    @State private var inlineError:String?
    private var key:String { RealtimeLessonRun.key(target:app.learner.target,lesson:lesson.id) }
    private var run:RealtimeLessonRun? { app.learner.realtimeLessonRuns?[key] }
    private var latestReply:String { !live.assistantTurnText.isEmpty ? live.assistantTurnText : run?.messages.last(where:{$0.role == "assistant"})?.text ?? "" }
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private func t(_ key:String,_ fallback:String)->String { let result=EntryCopy.ui(app.learner.support,key);return result == key ? fallback : result }
    var body:some View {
        SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:app.preserveEarnedGoalLesson(lesson)) {
            ScrollView {
                VStack(spacing:12) {
                    goalCard
                    BrandArtwork(name:"piyali-orb.png").frame(width:132,height:132).scaleEffect(live.connected && !live.muted ? 1.02 : 1).animation(.easeInOut(duration:0.8).repeatCount(1),value:live.connected).accessibilityHidden(true)
                    if live.connected || paused { Text(paused ? "Paused" : live.muted ? "Muted" : t("proficiency_listening","Listening")).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary) }
                    if !latestReply.isEmpty { VStack(alignment:.leading,spacing:8) { Text(LearningLanguages.names[app.learner.target] ?? app.learner.target).font(PiyaliBrand.productFont(12,600));Text(latestReply).font(PiyaliBrand.productFont(18)).textSelection(.enabled);Button(t("story_listen","Listen")) { speech.speak(latestReply,language:app.learner.target) }.disabled(live.connected) }.frame(maxWidth:.infinity,alignment:.leading).padding(16).background(brand.surface,in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) } }
                    if live.autoStopped { Text(t("ra_auto_stop_desc","The session closed automatically after 30 seconds.").replacingOccurrences(of:"15",with:"30")).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.secondary) }
                    if let error=service.error ?? live.error ?? inlineError { Text(error).foregroundStyle(.red).font(PiyaliBrand.productFont(13)).accessibilityIdentifier("realtimeError") }
                }.padding(16)
            }.background(brand.background)
                .safeAreaInset(edge:.bottom) { controls.padding(16).padding(.bottom,78).background(brand.background) }
        }.task(id:app.identity.npub+":"+key+":"+app.learner.support) { active=true;let fresh=startsFresh && !hasAppeared;hasAppeared=true;await service.prepare(app,lesson:lesson,fresh:fresh) }
            .onChange(of:run?.completed) { _,completed in if completed == true { Task { await live.stop() };paused=false } }
            .onChange(of:app.identity.npub) { _,_ in stop() }
            .onChange(of:app.learner.target) { _,_ in stop() }
            .onChange(of:app.learner.support) { _,_ in stop() }
            .onChange(of:app.subscription.hasAccess) { _,allowed in if !allowed { stop() } }
            .onChange(of:scenePhase) { _,phase in if phase == .background { stop() } }
            .onDisappear { stop() }
            .sheet(isPresented:$showHistory) { NavigationStack { List { ForEach(run?.messages ?? []) { message in VStack(alignment:.leading,spacing:8) { Text(message.role == "user" ? t("ra_you","You") : "Piyali").font(.caption);Text(message.text).textSelection(.enabled);Button(t("story_listen","Listen")) { speech.speak(message.text,language:app.learner.target) }.buttonStyle(.borderless) } };if let run,!run.messages.isEmpty { Button("Save transcript to notes") { app.learner.notes.insert(.init(title:run.title,body:run.messages.map { ($0.role == "user" ? "You: " : "Piyali: ")+$0.text }.joined(separator:"\n")),at:0);app.persist() } } }.navigationTitle(t("ra_chat_log","Chat log")).toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { showHistory=false } } } }.presentationDetents([.large]) }
    }
    private var goalCard:some View {
        VStack(alignment:.leading,spacing:10) {
            HStack(alignment:.top,spacing:8) {
                Button { Task { await live.stop();showStarter=false;await service.prepare(app,lesson:lesson,fresh:true) } } label:{ Image(systemName:"dice").frame(width:28,height:28) }.disabled(service.busy || live.connected || live.connecting).accessibilityLabel(t("ra_new_goal","New goal"))
                if let run { Text(run.title).font(PiyaliBrand.productFont(15,600)).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("realtimeGoal") } else { ProgressView(t("ra_generating_topic","Generating new topic...")).frame(maxWidth:.infinity,alignment:.leading) }
                Button { showHistory=true } label:{ Image(systemName:"bubble.left.and.bubble.right").frame(width:28,height:28) }.disabled(run?.messages.isEmpty != false || live.connected).accessibilityLabel(t("ra_chat_log","Chat log"))
            }
            if let run {
                Text(t("ra_goal_criteria","Criteria:")+" "+run.rubric).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.secondary)
                if ["Pre-A1","A1"].contains(run.questionLevel),!run.completed {
                    HStack { Spacer();Button(showStarter ? t("ra_starter_hide","Hide phrase") : t("ra_starter_show","Help me")) { showStarter.toggle();if showStarter { Task { await service.starter(app,lesson:lesson,run:run) } } }.buttonStyle(.bordered).disabled(service.busy || live.connected);Spacer() }
                    if showStarter,let phrase=run.starter { VStack(spacing:6) { HStack { Button { speech.speak(phrase["target"].string,language:run.target) } label:{ Image(systemName:"speaker.wave.2") }.accessibilityLabel(t("story_listen","Listen"));Text(phrase["target"].string).font(PiyaliBrand.productFont(15,600)) };Text(phrase["support"].string).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.secondary) }.frame(maxWidth:.infinity).padding(12).background(brand.background,in:RoundedRectangle(cornerRadius:12)) }
                }
                if !run.feedback.isEmpty { Label(run.feedback,systemImage:run.completed ? "checkmark.circle.fill" : "arrow.clockwise").foregroundStyle(run.completed ? PiyaliBrand.teal : brand.secondary).font(PiyaliBrand.productFont(14)).accessibilityIdentifier("realtimeFeedback") }
                if run.completed { Text("+\(run.earnedXP) XP").font(PiyaliBrand.productFont(13,600)).foregroundStyle(PiyaliBrand.teal) }
            }
            if service.busy { ProgressView().frame(maxWidth:.infinity) }
        }.padding(12).foregroundStyle(brand.text).background(brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay { RoundedRectangle(cornerRadius:16).stroke(brand.border) }.accessibilityElement(children:.contain)
    }
    @ViewBuilder private var controls:some View {
        if live.connected || paused {
            HStack(spacing:12) {
                Button { live.setMuted(!live.muted) } label:{ Image(systemName:live.muted ? "mic.slash.fill" : "mic.fill").frame(maxWidth:.infinity,minHeight:44) }.disabled(paused).accessibilityLabel(live.muted ? "Unmute microphone" : "Mute microphone")
                Button { if paused { start() } else { paused=true;Task { await live.stop() } } } label:{ Image(systemName:paused ? "play.fill" : "pause.fill").frame(maxWidth:.infinity,minHeight:44) }.accessibilityLabel(paused ? "Resume session" : "Pause session")
                Button { paused=false;Task { await live.stop() } } label:{ Image(systemName:"phone.down.fill").frame(maxWidth:.infinity,minHeight:44).foregroundStyle(.white).background(Color(red:0.63,green:0.35,blue:0.40),in:RoundedRectangle(cornerRadius:18)) }.accessibilityLabel("End session")
            }.buttonStyle(.bordered).disabled(live.connecting)
        } else if run?.completed == true {
            Button(t("ra_btn_next","Next")) { if let onNext { onNext() } else { Task { await service.prepare(app,lesson:lesson,fresh:true) } } }.buttonStyle(RealtimeActionButtonStyle(success:true)).accessibilityIdentifier("realtimeNext")
        } else {
            HStack(spacing:12) {
                Button(t("ra_btn_skip","Skip")) { stop();if let onNext { onNext() } else { Task { await service.prepare(app,lesson:lesson,fresh:true) } } }.buttonStyle(.bordered).accessibilityIdentifier("realtimeSkip")
                Button { start() } label:{ Label(live.connecting ? t("ra_btn_starting","Starting...") : t("ra_btn_start","Start"),systemImage:"mic.fill") }.buttonStyle(RealtimeActionButtonStyle()).disabled(run == nil || service.busy || live.connecting).accessibilityIdentifier("realtimeStart")
            }
        }
    }
    private func start() {
        guard let run,!run.completed,!live.connecting,!service.busy else { return }
        active=true;speech.stopAll();inlineError=nil;paused=false
        do {
            let instructions=try service.instructions(app,lesson:lesson,run:run),account=app.identity.npub
            Task { await live.start(learner:app.learner,onConversationTurn:{ utterance,_,reply in
                guard active,app.identity.npub == account,app.learner.target == run.target,app.learner.support == run.support,app.learner.realtimeLessonRuns?[run.key]?.id == run.id,app.subscription.hasAccess else { return }
                Task { guard active else { return };await service.receive(utterance,reply:reply,turnID:UUID(),app:app,lesson:lesson,runID:run.id) }
            },instructions:instructions,openingPrompt:nil,inactivityTimeout:30) }
        } catch { inlineError=error.localizedDescription }
    }
    private func stop() { active=false;service.cancel();speech.stopAll();paused=false;Task { await live.stop() } }
}

private struct RealtimeActionButtonStyle:ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    var success=false
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(PiyaliBrand.productFont(16,600)).frame(maxWidth:.infinity,minHeight:48).foregroundStyle(.white)
            .background { Capsule().fill(success ? Color(red:49/255,green:151/255,blue:149/255) : Color(red:0,green:181/255,blue:216/255)).shadow(color:success ? Color(red:35/255,green:78/255,blue:82/255) : Color(red:8/255,green:111/255,blue:131/255),radius:0,y:configuration.isPressed ? 2 : 4) }.opacity(enabled ? 1 : 0.45)
    }
}
