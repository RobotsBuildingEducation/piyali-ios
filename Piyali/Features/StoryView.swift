import SwiftUI

/// Source-selected Speak/Radio/Conversation, with a shared fixed action footer.
struct StoryView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @StateObject private var service=StoryService()
    @StateObject private var audio=StoryPlaybackService()
    @StateObject private var speech=StorySpeechController()
    let lesson:Lesson?
    var onComplete:(()->Void)? = nil
    var embedded=false
    var startsFresh=false
    @State private var chosen:StoryMode?
    @State private var appeared=false
    @State private var refresh=0
    @State private var footerOwner=UUID()
    @State private var translations=Set<String>()
    @State private var translating=Set<String>()
    @State private var roleResult:StorySpeechResult?
    private var hasAccess:Bool { app.subscription.hasAccess || StoryService.fixtureMode != nil }
    @State private var active=false
    @State private var autoplayKey:String?
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var appearance:StoryAppearance { StoryCharacterAvatar.appearance }
    private var content:JSONValue { lesson?.content["stories"] ?? .null }
    private var saved:StoryRun? { guard let value=app.learner.story,value.support == app.learner.support,value.lessonID == lesson?.id else { return nil };return value }
    private var mode:StoryMode? { StoryService.fixtureMode ?? (content["topic"].string == "tutorial" ? .speaking : StoryMode(rawValue:content["storyMode"].string)) ?? chosen ?? saved?.mode }
    private var run:StoryRun? { guard let saved,saved.mode == mode,saved.id == service.activeRunID else { return nil };return saved }
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,app.learner.level,lesson?.id ?? "free",(try? StoryService.contextID(lesson,learnerLevel:app.learner.level)) ?? "invalid",mode?.rawValue ?? "pending",String(refresh)].joined(separator:"|") }
    private var recordingNow:Bool { speech.recorder.recording }
    private func t(_ key:String)->String { appearance.text(key,language:app.learner.support) }
    private var narrationUser:JSONValue { app.learner.settingsSnapshot.setting("name",.string(app.learner.name)) }
    private func ui(_ key:String)->String { EntryCopy.ui(app.learner.support,key) }
    var body:some View {
        Group { if StoryService.fixtureMode != nil { activity } else { SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:app.preserveEarnedGoalLesson(lesson)) { activity } } }
            .navigationTitle(embedded ? lesson?.title.localized(app.learner.support) ?? t("story") : t("story"))
            .activityFooter(owner:footerOwner,revision:footerRevision,access:app.subscription,fixtureAllowed:StoryService.fixtureMode != nil,correct:feedbackCorrect) { footer }
            .onChange(of:app.learner.settingsSnapshot["progress"]["voice"]){_,_ in stop()}
            .onChange(of:app.learner.name){_,_ in stop()}
            .task(id:scope) {
                stop();autoplayKey=nil;translations=[];translating=[];roleResult=nil
                guard let mode else { chosen=StoryMode.choose(content:content,random:Double.random(in:0..<1));return }
                let fresh=refresh > 0 || startsFresh && !appeared;appeared=true
                let prepared=await service.prepare(app,lesson:lesson,mode:mode,fresh:fresh)
                guard prepared,!Task.isCancelled,active,hasAccess else { return }
                if let run,run.atEnd { if !run.completed { finish() } else if let onComplete { onComplete() } else { newStory() } }
                else if let run { autoplaySentence(run) }
            }
            .onAppear { active=true }
            .onChange(of:hasAccess){_,access in if !access{stop()}}
            .onChange(of:phase) { _,value in if value == .background { stop();service.cancel() } else if value == .active,active,service.activeRunID == nil { refresh += 1 } }
            .onDisappear { active=false;stop();service.cancel() }
    }
    private var activity:some View {
        ScrollViewReader { reader in
            VStack(spacing:0) {
                ScrollView {
                    VStack(alignment:.leading,spacing:20) {
                        if let run,!service.busy {
                            Text(title(run)).font(PiyaliBrand.productFont(16,600)).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("storyProgress").accessibilityValue("\(min(run.index+1,run.count)) / \(run.count)")
                            if run.mode == .speaking,run.earnedXP > 0 { Text("+\(run.earnedXP)").font(PiyaliBrand.productFont(13,600)).foregroundStyle(PiyaliBrand.teal).frame(maxWidth:.infinity,alignment:.trailing) }
                            if run.completed { completed(run) }
                            else if run.mode == .speaking { sentenceConversation(run) }
                            else {
                                if run.mode == .radio { radio(run) } else { conversation(run) }
                                if audio.phase == .awaitingSpeech,let turn=audio.currentTurn { userTurn(run,turn:turn).id("story-current") }
                                if run.heard.contains(run.index),let question=run.currentSegment?.question { checkpoint(run,question:question).id("story-question") }
                            }
                            if audio.phase == .failed || audio.previewError { Text(t("audioError")).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.questionError).accessibilityIdentifier("storyAudioError") }
                        } else { VStack(spacing:14) { ProgressView();Text(t("loading")).accessibilityIdentifier("storyLoading");Text(t("loadingSub")).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.muted) }.frame(maxWidth:.infinity,minHeight:260) }
                        if let error=service.error { Text(error).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.questionError) }
                        if let error=speech.recorder.error { Text(speechError(error)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.questionError).accessibilityIdentifier("storyRecordingError") }
                    }.padding(.horizontal,12).padding(.vertical,8).padding(.bottom,18).frame(maxWidth:760).frame(maxWidth:.infinity)
                }.onChange(of:run?.index) { _,_ in withAnimation { reader.scrollTo("story-current",anchor:.top) };if let run { autoplaySentence(run) } }
                Color.clear.frame(height:app.activityFooterHeight)
            }
        }.font(PiyaliBrand.productFont(16)).foregroundStyle(brand.text).background(brand.background)
    }
    private func title(_ run:StoryRun)->String {
        let prefixes=["sentence practice","practice","call","story",t("call"),t("practice"),t("story"),t("speaking")]
        var value=run.title
        for prefix in prefixes where value.lowercased().hasPrefix(prefix.lowercased()+":") { value=String(value.dropFirst(prefix.count+1)).trimmingCharacters(in:.whitespacesAndNewlines);break }
        if prefixes.contains(where:{ value.caseInsensitiveCompare($0) == .orderedSame }) { value="" }
        return t(run.mode == .radio ? "call" : run.mode == .speaking ? "practice" : "story")+(value.isEmpty ? "" : ": "+value)
    }
    private func panel<Content:View>(gradient:Bool=false,@ViewBuilder content:()->Content)->some View {
        content().padding(16).frame(maxWidth:.infinity,alignment:.leading).background { RoundedRectangle(cornerRadius:24).fill(LinearGradient(colors:gradient ? [brand.surface,PiyaliBrand.unitColor(scheme == .dark ? "182031" : "efe4d5")] : [brand.surface,brand.surface],startPoint:.topLeading,endPoint:.bottomTrailing)) }.overlay { RoundedRectangle(cornerRadius:24).stroke(brand.border) }
    }
    private func radio(_ run:StoryRun)->some View {
        let speakers=Array((run.episode?.segments.first?.turns.map(\.speaker) ?? []).reduce(into:[String]()) { if !$0.contains($1) { $0.append($1) } }.prefix(2))
        return panel(gradient:true) {
            VStack(spacing:28) {
                HStack(alignment:.top,spacing:28) { ForEach(Array(speakers.enumerated()),id:\.offset) { index,name in
                    let playing=(audio.previewTurn ?? audio.currentTurn)?.speaker == name && (audio.active || audio.previewPlaying || audio.phase == .awaitingSpeech)
                    VStack(spacing:12) {
                        StoryCharacterAvatar(name:name,portraitID:run.portraitIDs?[name],size:64,speaking:playing,accent:index == 0 ? PiyaliBrand.teal : brand.questionChoice,indicator:index == 0 ? "mic" : "headphones")
                        Text(StoryAppearance.isUser(name,learnerName:app.learner.name) ? t("you") : name).font(PiyaliBrand.productFont(16,playing ? 700 : 600))
                        if playing { Text(audio.phase == .awaitingSpeech && !audio.previewPlaying ? t("yourTurn") : t("speakingNow")).font(PiyaliBrand.productFont(10,700)).padding(.horizontal,8).padding(.vertical,4).background((index == 0 ? PiyaliBrand.teal : brand.questionChoice),in:Capsule()).foregroundStyle(.white) }
                    }.opacity((audio.active || audio.previewPlaying) && !playing ? 0.38 : 1).scaleEffect(playing ? 1.08 : 1)
                } }.frame(maxWidth:.infinity)
                if (audio.active || audio.previewPlaying),let turn=audio.previewTurn ?? audio.currentTurn {
                    VStack(spacing:7) { Text(turn.speaker.uppercased()).font(PiyaliBrand.productFont(12,700)).foregroundStyle(PiyaliBrand.teal);Text(turn.target).font(PiyaliBrand.productFont(18,600)).multilineTextAlignment(.center) }.padding(14).frame(maxWidth:.infinity).background(brand.background,in:RoundedRectangle(cornerRadius:16))
                }
                StoryRadioSignal(active:audio.phase == .playing || audio.previewPlaying || recordingNow).frame(width:96,height:32).accessibilityElement(children:.ignore).accessibilityIdentifier("storyRadioSignal").accessibilityLabel(audio.active ? t("onAir") : t("ready"))
                if audio.hasPlayed || run.heard.contains(run.index) { replay(run) }
            }.padding(.vertical,12).frame(maxWidth:.infinity)
        }
    }
    private func conversation(_ run:StoryRun)->some View {
        VStack(alignment:.leading,spacing:20) {
            if let episode=run.episode { ForEach(0..<min(episode.segments.count,run.index+1),id:\.self) { index in
                VStack(spacing:16) { ForEach(Array(episode.segments[index].turns.enumerated()),id:\.offset) { offset,turn in
                    bubble(turn,run:run,key:"\(index)-\(offset)",right:offset%2 == 1,identifier:index == run.index ? "story-current" : nil)
                } }.opacity(index < run.index ? 0.7 : 1)
            } }
            if run.result == true,let q=run.currentSegment?.question,q.type == "reply",let index=q.answer.first,q.options.indices.contains(index) { bubble(.init(speaker:"You",target:q.options[index],support:q.explanation),run:run,key:"\(run.index)-reply",right:true) }
            replay(run)
        }
    }
    private func sentenceConversation(_ run:StoryRun)->some View {
        VStack(spacing:16) { ForEach(0..<min(run.sentences.count,run.index+1),id:\.self) { index in
            speakingBubble(run.sentences[index],run:run,index:index).frame(maxWidth:.infinity,alignment:index%2 == 1 ? .trailing : .leading).id(index == run.index ? "story-current" : "sentence-\(index)")
        } }.padding(24).frame(maxWidth:.infinity).background(brand.surface,in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) }
    }
    private func speakingBubble(_ turn:StoryTurn,run:StoryRun,index:Int)->some View {
        let right=index%2 == 1,current=index == run.index,key="sentence-\(index)",accent=right ? Color(red:159/255,green:122/255,blue:234/255) : PiyaliBrand.teal
        return HStack(alignment:.top,spacing:12) {
            if !right { StoryCharacterAvatar(name:turn.speaker,portraitID:run.portraitIDs?[turn.speaker],size:36,speaking:audio.previewPlaying && audio.previewTurn?.target == turn.target);linePlay(turn,run:run,accent:current ? accent : brand.border) }
            VStack(alignment:.leading,spacing:7) {
                HStack(alignment:.top,spacing:8) {
                    Text(StoryAppearance.isUser(turn.speaker,learnerName:app.learner.name) ? t("you") : turn.speaker).font(PiyaliBrand.productFont(14,700)).foregroundStyle(accent)
                    Spacer(minLength:0)
                    Button { translate(turn,run:run,key:key) } label:{ if translating.contains(key) { ProgressView() } else { Image(systemName:"character.bubble").font(.system(size:15)).frame(width:25,height:25) } }.buttonStyle(.plain).foregroundStyle(translations.contains(key) ? PiyaliBrand.teal : brand.secondary).accessibilityLabel(t(translations.contains(key) ? "hideTranslation" : "translation")).accessibilityIdentifier("storyTranslate-"+key)
                }
                Text(turn.target).font(PiyaliBrand.productFont(18,500)).lineSpacing(6).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,run.target == "ar" ? .rightToLeft : .leftToRight).accessibilityIdentifier(current ? "storyTarget" : "storySentence-\(index)")
                if translations.contains(key),let text=run.translations[key] ?? turn.support,!text.isEmpty { Text(text).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).environment(\.layoutDirection,run.support == "ar" ? .rightToLeft : .leftToRight) }
            }.padding(.horizontal,12).padding(.vertical,8).background((right ? Color(red:99/255,green:102/255,blue:241/255) : PiyaliBrand.teal).opacity(0.15),in:RoundedRectangle(cornerRadius:12)).overlay(alignment:right ? .trailing : .leading) { Rectangle().fill(accent).frame(width:3) }.clipShape(RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(current ? accent.opacity(0.6) : .clear,lineWidth:2) }.opacity(current ? 1 : 0.85)
            if right { linePlay(turn,run:run,accent:current ? accent : brand.border);StoryCharacterAvatar(name:turn.speaker,portraitID:run.portraitIDs?[turn.speaker],size:36,speaking:audio.previewPlaying && audio.previewTurn?.target == turn.target,accent:accent) }
        }.frame(maxWidth:max(200,(UIScreen.main.bounds.width-72)*0.85))
    }
    private func linePlay(_ turn:StoryTurn,run:StoryRun,accent:Color)->some View {
        Button { audio.preview(turn,language:run.target,user:narrationUser) } label:{ Image(systemName:"speaker.wave.2").font(.system(size:13)).foregroundStyle(brand.text).frame(width:25,height:25).overlay { RoundedRectangle(cornerRadius:6).stroke(accent) } }.buttonStyle(.plain).padding(.top,4).accessibilityLabel(t("play")+": "+turn.speaker)
    }
    private func bubble(_ turn:StoryTurn,run:StoryRun,key:String,right:Bool,identifier:String?=nil)->some View {
        HStack(alignment:.top,spacing:12) {
            if !right { StoryCharacterAvatar(name:turn.speaker,portraitID:run.portraitIDs?[turn.speaker],size:run.mode == .speaking ? 36 : 42,speaking:(audio.phase == .playing && audio.currentTurn?.speaker == turn.speaker) || (audio.previewPlaying && audio.previewTurn?.speaker == turn.speaker)) }
            VStack(alignment:.leading,spacing:10) {
                HStack {
                    Text(StoryAppearance.isUser(turn.speaker,learnerName:app.learner.name) ? t("you") : turn.speaker).font(PiyaliBrand.productFont(12,700)).foregroundStyle(brand.secondary)
                    Spacer()
                    Button { audio.preview(turn,language:run.target,user:narrationUser) } label:{ Image(systemName:"speaker.wave.2").frame(width:28,height:28) }.buttonStyle(.plain).disabled(audio.active && !run.heard.contains(run.index)).accessibilityLabel(t("play")+": "+turn.speaker)
                    Button { translate(turn,run:run,key:key) } label:{ if translating.contains(key) { ProgressView() } else { Image(systemName:"character.bubble").frame(width:28,height:28) } }.buttonStyle(.plain).foregroundStyle(translations.contains(key) ? PiyaliBrand.teal : brand.secondary).accessibilityLabel(t(translations.contains(key) ? "hideTranslation" : "translation")).accessibilityIdentifier("storyTranslate-"+key)
                }
                Text(turn.target).font(PiyaliBrand.productFont(18,500)).lineSpacing(6).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,run.target == "ar" ? .rightToLeft : .leftToRight).accessibilityIdentifier(run.mode == .speaking && key == "sentence-\(run.index)" ? "storyTarget" : "storyDialogue-"+key)
                if translations.contains(key),let text=run.translations[key] ?? turn.support,!text.isEmpty { Text(text).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,run.support == "ar" ? .rightToLeft : .leftToRight) }
            }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(brand.surface,in:RoundedRectangle(cornerRadius:24)).overlay { RoundedRectangle(cornerRadius:24).stroke(brand.border) }
            if right { StoryCharacterAvatar(name:turn.speaker,portraitID:run.portraitIDs?[turn.speaker],size:run.mode == .speaking ? 36 : 42,speaking:(audio.phase == .playing && audio.currentTurn?.speaker == turn.speaker) || (audio.previewPlaying && audio.previewTurn?.speaker == turn.speaker),accent:brand.questionChoice) }
        }.id(identifier ?? key)
    }
    private func replay(_ run:StoryRun)->some View {
        Button { startPlayback(run,replay:run.heard.contains(run.index)) } label:{ Label(t("replay"),systemImage:"arrow.counterclockwise") }.font(PiyaliBrand.productFont(14,600)).buttonStyle(.plain).disabled(audio.active).accessibilityIdentifier("storyReplay")
    }
    private func userTurn(_ run:StoryRun,turn:StoryTurn)->some View {
        panel { VStack(alignment:.leading,spacing:12) { HStack { Text(t("yourTurn")+":").font(PiyaliBrand.productFont(16,700));Spacer();Button { audio.preview(turn,language:run.target,user:narrationUser) } label:{ Image(systemName:"speaker.wave.2") }.accessibilityLabel(t("play"));Button { translate(turn,run:run,key:"role-\(run.index)") } label:{ Image(systemName:"character.bubble") }.accessibilityLabel(t("translation")) };Text(turn.target).font(PiyaliBrand.productFont(18,500)).accessibilityIdentifier("storyRoleTarget");if translations.contains("role-\(run.index)"),let text=run.translations["role-\(run.index)"] ?? turn.support { Text(text).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary) } } }
    }
    private func checkpoint(_ run:StoryRun,question:StoryQuestion)->some View {
        let chosen=run.answers[String(run.index)] ?? [],listening=["select_words","order_words"].contains(question.type)
        return panel {
            VStack(alignment:.leading,spacing:16) {
                Text(question.prompt).font(PiyaliBrand.productFont(18,600)).accessibilityIdentifier("storyQuestion")
                if listening,let index=question.audioTurn,let turns=run.currentSegment?.turns,turns.indices.contains(index) { Button { audio.preview(turns[index],language:run.target) } label:{ Label(t("listen"),systemImage:"speaker.wave.2") }.buttonStyle(.bordered).accessibilityIdentifier("storyListenExcerpt") }
                if question.type == "order_words" {
                    PracticeFlowLayout(spacing:8) { ForEach(Array(chosen.enumerated()),id:\.offset) { position,index in Button(question.options[index]) { update { $0.select(index) } }.buttonStyle(.bordered).disabled(run.result != nil).accessibilityIdentifier("storySelected-\(position)").accessibilityHint(t("answer")) } }.frame(minHeight:60,alignment:.leading).frame(maxWidth:.infinity,alignment:.leading).padding(12).overlay { RoundedRectangle(cornerRadius:12).stroke(brand.border) }
                }
                LazyVGrid(columns:listening ? [GridItem(.flexible()),GridItem(.flexible())] : [GridItem(.flexible())],spacing:12) { ForEach(Array(question.options.enumerated()),id:\.offset) { index,option in
                    let selected=chosen.contains(index),correct=run.result != nil && question.answer.contains(index),wrong=run.result != nil && selected && !correct
                    let accent=correct ? brand.questionSuccess : wrong ? brand.questionError : selected ? brand.questionChoice : brand.border
                    Button { update { $0.select(index) } } label:{ HStack(spacing:12) { Image(systemName:wrong ? "xmark.circle.fill" : correct || selected ? "checkmark.circle.fill" : "circle").font(.system(size:22)).foregroundStyle(accent);Text(option).font(PiyaliBrand.productFont(16,selected || correct ? 600 : 500)).multilineTextAlignment(.leading).foregroundStyle(brand.text);Spacer(minLength:0) }.padding(.horizontal,14).padding(.vertical,14).frame(maxWidth:.infinity,minHeight:54).background(selected || correct || wrong ? accent.opacity(0.16) : brand.surface,in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(accent,lineWidth:2) }.opacity(run.result != nil && !selected && !correct ? 0.55 : 1) }.buttonStyle(.plain).disabled(run.result != nil || question.type == "order_words" && selected).accessibilityIdentifier("storyOption-\(index)").accessibilityLabel(option).accessibilityAddTraits(selected ? .isSelected : [])
                } }
            }
        }
    }
    private func completed(_ run:StoryRun)->some View {
        panel { VStack(alignment:.leading,spacing:12) { Text(t("complete")).font(PiyaliBrand.productFont(20,700)).accessibilityIdentifier("storyCompleted");Text("\(run.earnedXP) \(t("xp"))");Button(t("back")) { newStory() }.buttonStyle(ActivityPrimaryButtonStyle(tone:"success")) } }
    }
    private var feedbackCorrect:Bool? { (run?.mode == .speaking ? run?.speechResult : roleResult)?.pass ?? run?.result }
    private var footerRevision:String { [scope,String(describing:phase),String(active),run?.id.uuidString ?? "",String(run?.index ?? 0),String(describing:run?.result),String(describing:run?.speechResult),String(describing:roleResult),String(run?.completed ?? false),run?.answers[String(run?.index ?? 0)]?.description ?? "",String(run?.heard.contains(run?.index ?? 0) ?? false),audio.phase.rawValue,String(audio.previewError),String(audio.roleIndex ?? -1),String(recordingNow),String(speech.recorder.connecting),String(speech.recorder.evaluating),speech.recorder.error ?? "",String(service.busy),service.error ?? ""].joined(separator:"|") }
    private var footer:some View {
        let result=run?.mode == .speaking ? run?.speechResult : roleResult
        return ActivityFooterSurface(hasFeedback:result != nil || run?.result != nil,feedback:{
            if let run {
                VStack(alignment:.leading,spacing:12) {
                    if let result { Text(result.pass ? t("correct") : t("speechIncorrect")).font(PiyaliBrand.productFont(16,700)).foregroundStyle(brand.text).accessibilityIdentifier("storySpeechFeedback");if result.pass,run.mode == .speaking { Text("+2 XP").font(PiyaliBrand.productFont(14,600)).foregroundStyle(brand.questionSuccess).accessibilityIdentifier("storySpeechXP") };if !run.lastWords.isEmpty { Text(run.lastWords).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary) } }
                    else if let correct=run.result,let question=run.currentSegment?.question { Text(t(correct ? "correct" : "incorrect")).font(PiyaliBrand.productFont(16,700)).foregroundStyle(brand.text).accessibilityIdentifier("storyFeedback");if !correct { Text(question.answer.map { question.options[$0] }.joined(separator:question.type == "order_words" ? " " : " · ")).font(PiyaliBrand.productFont(14,600)) };Text(question.explanation).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary) }
                    let percent=Int((Double(run.index)+(result?.pass == true && run.mode != .speaking ? 0.5 : run.result == true || result?.pass == true ? 1 : 0))/Double(max(1,run.count))*100.0+0.5)
                    VStack(spacing:8) {
                        HStack { Text(ui("story_progress"));Spacer();Text("\(percent)%") }.font(PiyaliBrand.productFont(12,600)).foregroundStyle(brand.secondary)
                        ActivityProgressBar(value:percent,label:ui("story_progress"))
                    }
                }.padding(.vertical,6)
            }
        },actions:{
            if let run,!service.busy { primary(run) }
            else {
                skip
                if service.error != nil { Button(t("retry")) { refresh += 1 }.buttonStyle(ActivityPrimaryButtonStyle()).disabled(service.busy) }
                else { ProgressView().frame(maxWidth:.infinity,minHeight:40) }
            }
        })
    }
    @ViewBuilder private func primary(_ run:StoryRun)->some View {
        if run.mode == .speaking,run.speechResult?.pass == false {
            skip
            Button { update { $0.speechResult=nil;$0.lastWords="" };record(run) } label:{ StoryRecordLabel(recorder:speech.recorder,speaking:true,record:t("record"),connecting:t("connectingMic")) }.buttonStyle(ActivityPrimaryButtonStyle(tone:"stop")).disabled(speech.recorder.connecting || speech.recorder.evaluating).accessibilityLabel(t("record")).accessibilityIdentifier("storyRecord")
        } else if let verdict=run.mode == .speaking ? run.speechResult : roleResult {
            Button(run.mode == .speaking && verdict.pass ? ui(run.index == run.count-1 ? "stories_finish" : "stories_next_sentence") : t(verdict.pass ? "next" : "retry")) { if verdict.pass { if run.mode == .speaking { advance(run) } else { roleResult=nil;audio.continueSpeech() } } else { if run.mode == .speaking { update { $0.speechResult=nil;$0.lastWords="" } } else { roleResult=nil } } }.buttonStyle(ActivityPrimaryButtonStyle(tone:verdict.pass ? "success" : "stop")).accessibilityIdentifier(verdict.pass ? "storyNext" : "storySpeechRetry")
        } else if run.result != nil {
            Button(t(run.index == run.count-1 ? "finish" : "next")) { advance(run) }.buttonStyle(ActivityPrimaryButtonStyle(tone:run.result == true ? "success" : "stop")).accessibilityIdentifier("storyNext")
        } else if run.completed {
            Button(t("back")) { newStory() }.buttonStyle(ActivityPrimaryButtonStyle()).accessibilityIdentifier("storyNew")
        } else {
            skip
            if run.mode == .speaking || audio.phase == .awaitingSpeech {
                Button { record(run) } label:{ StoryRecordLabel(recorder:speech.recorder,speaking:run.mode == .speaking,record:t("record"),connecting:t("connectingMic")) }.buttonStyle(ActivityPrimaryButtonStyle(tone:"speak")).disabled(speech.recorder.connecting || speech.recorder.evaluating).accessibilityLabel(t("record")).accessibilityValue(speech.recorder.connecting ? t("connectingMic"):recordingNow ? t("stopRecording"):"").accessibilityIdentifier("storyRecord")
            } else if run.heard.contains(run.index) {
                Button(t("check")) { audio.cancel();update { $0.check() } }.buttonStyle(ActivityPrimaryButtonStyle()).disabled(!run.readyToCheck).accessibilityIdentifier("storyCheck")
            } else {
                Button { startPlayback(run) } label:{ if audio.active { ProgressView().tint(.white) } else { Label(t(audio.phase == .failed ? "retry" : "play"),systemImage:"play") } }.buttonStyle(ActivityPrimaryButtonStyle()).disabled(audio.active).accessibilityIdentifier("storyPlay")
            }
        }
    }
    @ViewBuilder private var skip:some View { if let onComplete { Button(t("skip")) { stop();onComplete();if !embedded { dismiss() } }.font(PiyaliBrand.productFont(14,600)).foregroundStyle(brand.secondary).accessibilityIdentifier("skipLessonActivity") } }
    private func update(_ change:(inout StoryRun)->Void) { guard hasAccess,var value=app.learner.story,value.id == run?.id,value.support == app.learner.support else { return };change(&value);app.learner.saveStory(value);app.persist() }
    private func autoplaySentence(_ run:StoryRun) {
        guard active,hasAccess,run.mode == .speaking,!recordingNow,run.speechResult?.pass != true,let turn=run.currentSentence else { return }
        let key=run.id.uuidString+":"+String(run.index)
        guard autoplayKey != key else { return };autoplayKey=key
        audio.preview(turn,language:run.target,user:narrationUser)
    }
    private func startPlayback(_ run:StoryRun,replay:Bool=false) {
        guard hasAccess else { return }
        speech.cancel();roleResult=nil
        guard let segment=run.currentSegment else { return };let account=app.identity.npub
        audio.start(segment.turns,language:run.target,learnerName:app.learner.name,replay:replay,user:narrationUser) {
            guard app.identity.npub == account,app.learner.story?.id == run.id,app.learner.story?.index == run.index else { return };update { $0.heard.insert(run.index) }
        }
    }
    private func advance(_ run:StoryRun) {
        guard hasAccess,app.learner.story?.id == run.id,app.learner.story?.index == run.index else { return }
        stop();roleResult=nil;update { $0.advance() }
        guard let current=app.learner.story,current.id == run.id else { return }
        if current.atEnd { finish() } else if current.mode != .speaking { startPlayback(current) }
    }
    private func finish() { guard hasAccess else { stop();return };stop();_=app.learner.finishStory();app.persist();if let onComplete { onComplete();if !embedded { dismiss() } } else { newStory() } }
    private func newStory() { stop();chosen=(mode ?? .speaking).next(content:content,random:Double.random(in:0..<1));refresh += 1 }
    private func record(_ run:StoryRun){
        guard hasAccess else{stop();return}
        if recordingNow{speech.stop();return};guard !speech.recorder.connecting,!speech.recorder.evaluating else{return}
        let role=run.mode == .speaking ? nil:audio.roleIndex,target=run.mode == .speaking ? run.currentSentence?.target:audio.currentTurn?.target
        guard let target,!target.isEmpty else{return};audio.stopPreview();roleResult=nil
        speech.start(app,run:run,target:target,role:role,allowed:{active && phase == .active && hasAccess && (run.mode == .speaking || audio.phase == .awaitingSpeech && audio.roleIndex == role)}){metadata in
            if run.mode == .speaking{_=app.learner.practiceStoryLine(words:metadata["recognizedText"].string,confidence:metadata["confidence"].number,audio:nil);app.persist()}
            else{roleResult=StorySpeech.evaluate(recognized:metadata["recognizedText"].string,target:target,lang:run.target,confidence:metadata["confidence"].number,audio:nil)}
        }
    }
    private func speechError(_ code:String)->String{
        if code == "mic-denied"{return t("micDenied")}
        let kind=code == "no-speech" ? "no_speech":code.hasPrefix("connection-") ? "connection":code == "transcription-failed" ? "transcription":"recording"
        return ui("speech_"+kind+"_error_desc")
    }
    private func translate(_ turn:StoryTurn,run:StoryRun,key:String) {
        guard hasAccess else { return }
        if translations.contains(key) { translations.remove(key);return };translations.insert(key)
        guard run.translations[key] == nil,turn.support?.isEmpty != false,!translating.contains(key) else { return }
        translating.insert(key);let account=app.identity.npub
        Task { defer { translating.remove(key) };do { let value=try await app.ai.conversationTranslation(turn.target,support:run.support);guard app.identity.npub == account,app.learner.story?.id == run.id else { return };update { $0.translations[key]=value } } catch { service.error=error.localizedDescription } }
    }
    private func stop() { speech.cancel();audio.cancel() }
}
private struct StoryRadioSignal:View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var active:Bool
    var body:some View { TimelineView(.animation(minimumInterval:0.08,paused:!active || reduceMotion)) { time in HStack(alignment:.center,spacing:4) { ForEach(0..<12,id:\.self) { index in RoundedRectangle(cornerRadius:2).fill(PiyaliBrand.teal.opacity(0.65)).frame(width:4,height:active && !reduceMotion ? 5+abs(sin(time.date.timeIntervalSinceReferenceDate*5+Double(index)))*23 : 5) } } } }
}
