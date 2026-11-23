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
    @State private var feedbackPortrait=PracticeQuestionAppearance.portrait
    @State private var roleResult:StorySpeechResult?
    @State private var pendingSpeaking:(id:UUID,target:String,metadata:JSONValue)?
    @State private var provisionalTranslations:[String:String]=[:]
    @State private var pendingSegmentPlayback=false
    private var hasAccess:Bool { app.subscription.hasAccess || StoryService.fixtureMode != nil }
    @State private var active=false
    @State private var autoplayKey:String?
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var appearance:StoryAppearance { StoryCharacterAvatar.appearance }
    private var content:JSONValue { lesson?.content["stories"] ?? .null }
    private var saved:StoryRun? { guard let value=app.learner.story,value.support == app.learner.support,value.lessonID == lesson?.id else { return nil };return value }
    private var mode:StoryMode? { StoryService.fixtureMode ?? (content["topic"].string == "tutorial" ? .speaking : StoryMode(rawValue:content["storyMode"].string)) ?? chosen ?? saved?.mode }
    private var run:StoryRun? {
        if let provisional=service.provisional,provisional.mode == mode {return provisional}
        guard let saved,saved.mode == mode,saved.id == service.activeRunID else { return nil };return saved
    }
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,app.learner.level,lesson?.id ?? "free",(try? StoryService.contextID(lesson,learnerLevel:app.learner.level)) ?? "invalid",mode?.rawValue ?? "pending",String(refresh)].joined(separator:"|") }
    private var recordingNow:Bool { speech.recorder.recording }
    private func t(_ key:String)->String { appearance.text(key,language:app.learner.support) }
    private var narrationUser:JSONValue { app.learner.settingsSnapshot.setting("name",.string(app.learner.name)) }
    private func ui(_ key:String)->String { EntryCopy.ui(app.learner.support,key) }
    var body:some View {
        Group { if StoryService.fixtureMode != nil { activity } else { SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:app.preserveEarnedGoalLesson(lesson)) { activity } } }
            .navigationTitle(embedded ? lesson?.title.localized(app.learner.support) ?? t("story") : t("story"))
            .activityFooter(owner:footerOwner,revision:footerRevision,access:app.subscription,fixtureAllowed:StoryService.fixtureMode != nil,enabled:run != nil || onComplete != nil,correct:feedbackCorrect) { footer }
            .onChange(of:app.learner.settingsSnapshot["progress"]["voice"]){_,_ in stop()}
            .onChange(of:app.learner.name){_,_ in stop()}
            .task(id:scope) {
                stop();autoplayKey=nil;translations=[];translating=[];roleResult=nil;pendingSpeaking=nil;provisionalTranslations=[:];pendingSegmentPlayback=false
                guard let mode else { chosen=StoryMode.choose(content:content,random:Double.random(in:0..<1));return }
                let fresh=refresh > 0 || startsFresh && !appeared;appeared=true
                let prepared=await service.prepare(app,lesson:lesson,mode:mode,fresh:fresh)
                guard app.goalPracticeIsCurrent(lesson),prepared,!Task.isCancelled,active,hasAccess else { pendingSpeaking=nil;return }
                if let run,let pending=pendingSpeaking,pending.id == run.id,pending.target == run.currentSentence?.target {
                    pendingSpeaking=nil;_=app.learner.practiceStoryLine(words:pending.metadata["recognizedText"].string,confidence:pending.metadata["confidence"].number,audio:nil,goalFocus:app.goalMemoryFocus(lesson));app.persist()
                } else {pendingSpeaking=nil}
                if let run,!provisionalTranslations.isEmpty,run.id == app.learner.story?.id {update {value in value.translations.merge(provisionalTranslations){_,new in new}};provisionalTranslations=[:]}
                if let run,run.atEnd { if !run.completed { finish() } else if let onComplete { onComplete() } else { newStory() } }
                else if let run { if pendingSegmentPlayback,run.mode != .speaking {pendingSegmentPlayback=false;startPlayback(run)} else {autoplaySentence(run)} }
            }
            .onAppear { active=true }
            .onChange(of:feedbackCorrect){_,correct in if correct == true{feedbackPortrait=PracticeQuestionAppearance.portrait}}
            .onChange(of:hasAccess){_,access in if !access{stop();pendingSpeaking=nil;service.cancel()}}
            .onChange(of:service.provisional?.id) { old,new in
                if let old,old != new,service.activeRunID != old {
                    stop();pendingSpeaking=nil;provisionalTranslations=[:];translations=[];autoplayKey=nil;pendingSegmentPlayback=false
                }
            }
            .onChange(of:service.provisional?.currentSentence?.target) {_,_ in
                if let run=service.provisional {
                    if let pending=pendingSpeaking,pending.id != run.id || pending.target != run.currentSentence?.target {pendingSpeaking=nil}
                    autoplaySentence(run)
                }
            }
            .onChange(of:service.provisional?.currentSegment?.turns.count) {_,_ in
                if pendingSegmentPlayback,let run=service.provisional,run.currentSegment?.turns.isEmpty == false {pendingSegmentPlayback=false;startPlayback(run)}
            }
            .onChange(of:phase) { _,value in if value == .background { stop();pendingSpeaking=nil;service.cancel() } else if value == .active,active,service.activeRunID == nil { refresh += 1 } }
            .onDisappear { active=false;stop();pendingSpeaking=nil;service.cancel() }
    }
    private var activity:some View {
        ScrollViewReader { reader in
            VStack(spacing:0) {
                ScrollView {
                    VStack(alignment:.leading,spacing:20) {
                        if let run,(!service.busy || service.provisional != nil) {
                            Text(title(run)).font(PiyaliBrand.productFont(16,600)).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("storyProgress").accessibilityValue("\(min(run.index+1,run.count)) / \(run.count)")
                            if run.mode == .speaking,run.earnedXP > 0 { Text("+\(run.earnedXP)").font(PiyaliBrand.productFont(13,600)).foregroundStyle(PiyaliBrand.teal).frame(maxWidth:.infinity,alignment:.trailing) }
                            if run.completed { completed(run) }
                            else if run.mode == .speaking { sentenceConversation(run) }
                            else {
                                if run.mode == .radio { radio(run) } else { conversation(run) }
                                if audio.phase == .awaitingSpeech,let turn=audio.currentTurn { userTurn(run,turn:turn) }
                                if run.heard.contains(run.index),run.questionAvailable,let question=run.currentSegment?.question { checkpoint(run,question:question).id("story-question") }
                            }
                            if audio.phase == .failed || audio.previewError { Text(t("audioError")).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.questionError).accessibilityIdentifier("storyAudioError") }
                        } else if service.error != nil {
                            generationFailure
                        } else {
                            StoryPreparationSkeleton(mode:mode ?? .speaking,status:t("loading"))
                        }
                        if let error=speech.recorder.error { Text(speechError(error)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.questionError).accessibilityIdentifier("storyRecordingError") }
                    }.padding(.horizontal,12).padding(.vertical,8).padding(.bottom,18).frame(maxWidth:760).frame(maxWidth:.infinity)
                }.onChange(of:run?.index) { _,_ in withAnimation { reader.scrollTo("story-current",anchor:.top) };if let run { autoplaySentence(run) } }
                Color.clear.frame(height:app.activityFooterHeight)
            }
        }.font(PiyaliBrand.productFont(16)).foregroundStyle(brand.text).background(brand.background)
    }
    private var generationFailure:some View {
        VStack(spacing:16) {
            Text(t("generationError")).font(PiyaliBrand.productFont(16,600))
                .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
                .accessibilityIdentifier("storyGenerationError")
                .onAppear { UIAccessibility.post(notification:.announcement,argument:t("generationError")) }
            Button(t("retry")) {
                if mode == .speaking { refresh += 1 }
                else { newStory() }
            }
            .font(PiyaliBrand.productFont(16,600)).foregroundStyle(.white)
            .padding(.horizontal,24).frame(minHeight:40)
            .background(PiyaliBrand.unitColor("319795"),in:Capsule())
            .shadow(color:PiyaliBrand.unitColor(brand.dark ? "284a51":"255b59"),radius:0,y:4)
            .buttonStyle(.plain).accessibilityIdentifier("storyGenerationRetry")
        }
        .padding(.horizontal,16).frame(maxWidth:440)
        .frame(maxWidth:.infinity,minHeight:mode == .speaking ? 320 : UIScreen.main.bounds.height*0.60)
    }
    private func title(_ run:StoryRun)->String {
        let prefixes=["sentence practice","practice","call","story",t("call"),t("practice"),t("story"),t("speaking")]
        var value=run.title
        for prefix in prefixes where value.lowercased().hasPrefix(prefix.lowercased()+":") { value=String(value.dropFirst(prefix.count+1)).trimmingCharacters(in:.whitespacesAndNewlines);break }
        if prefixes.contains(where:{ value.caseInsensitiveCompare($0) == .orderedSame }) { value="" }
        return t(run.mode == .radio ? "call" : run.mode == .speaking ? "practice" : "story")+(value.isEmpty ? "" : ": "+value)
    }
    private func panel<Content:View>(gradient:Bool=false,inset:CGFloat=16,@ViewBuilder content:()->Content)->some View {
        content().padding(inset).frame(maxWidth:.infinity,alignment:.leading).background { RoundedRectangle(cornerRadius:24).fill(LinearGradient(colors:gradient ? [brand.surface,PiyaliBrand.unitColor(scheme == .dark ? "182031" : "efe4d5")] : [brand.surface,brand.surface],startPoint:.topLeading,endPoint:.bottomTrailing)) }.overlay { RoundedRectangle(cornerRadius:24).stroke(brand.border) }
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
                StoryRadioSignal(active:audio.phase == .playing || audio.previewPlaying || recordingNow).frame(width:96,height:32).accessibilityElement(children:.ignore).accessibilityIdentifier("storyRadioSignal").accessibilityLabel(audio.active || audio.previewPlaying ? t("onAir") : t("ready"))
                if audio.hasPlayed || run.heard.contains(run.index) { replay(run) }
            }.padding(.vertical,12).frame(maxWidth:.infinity)
        }.id("story-current")
    }
    private func conversation(_ run:StoryRun)->some View {
        let speakers=(run.episode?.segments.flatMap { $0.turns.map(\.speaker) } ?? []).reduce(into:[String]()) { names,speaker in
            if !names.contains(speaker) { names.append(speaker) }
        }
        let secondSpeaker=speakers.dropFirst().first
        return VStack(alignment:.leading,spacing:20) {
            if let episode=run.episode { ForEach(0..<min(episode.segments.count,run.index+1),id:\.self) { index in
                VStack(spacing:16) {
                    ForEach(Array(episode.segments[index].turns.enumerated()),id:\.offset) { offset,turn in
                        bubble(turn,run:run,key:"\(index)-\(offset)",right:turn.speaker == secondSpeaker)
                    }
                    if index == run.index,run.result == true,let q=run.currentSegment?.question,q.type == "reply",let answer=q.answer.first,q.options.indices.contains(answer) {
                        bubble(.init(speaker:"You",target:q.options[answer],support:q.explanation),run:run,key:"\(index)-reply",right:true)
                    }
                }.opacity(index < run.index ? 0.7 : 1)
                    .id(index == run.index ? "story-current" : "story-part-\(index)")
            } }
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
                if translations.contains(key),let text=run.translations[key] ?? provisionalTranslations[key] ?? turn.support,!text.isEmpty { Text(text).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).environment(\.layoutDirection,run.support == "ar" ? .rightToLeft : .leftToRight) }
            }.padding(.horizontal,12).padding(.vertical,8).background((right ? Color(red:99/255,green:102/255,blue:241/255) : PiyaliBrand.teal).opacity(0.15),in:RoundedRectangle(cornerRadius:12)).overlay(alignment:right ? .trailing : .leading) { Rectangle().fill(accent).frame(width:3) }.clipShape(RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(current ? accent.opacity(0.6) : .clear,lineWidth:2) }.opacity(current ? 1 : 0.85)
            if right { linePlay(turn,run:run,accent:current ? accent : brand.border);StoryCharacterAvatar(name:turn.speaker,portraitID:run.portraitIDs?[turn.speaker],size:36,speaking:audio.previewPlaying && audio.previewTurn?.target == turn.target,accent:accent) }
        }.frame(maxWidth:max(200,(UIScreen.main.bounds.width-72)*0.85))
    }
    private func linePlay(_ turn:StoryTurn,run:StoryRun,accent:Color)->some View {
        Button { audio.preview(turn,language:run.target,user:narrationUser) } label:{ Image(systemName:"speaker.wave.2").font(.system(size:13)).foregroundStyle(brand.text).frame(width:25,height:25).overlay { RoundedRectangle(cornerRadius:6).stroke(accent) } }.buttonStyle(.plain).padding(.top,4).accessibilityLabel(t("play")+": "+turn.speaker)
    }
    private func bubble(_ turn:StoryTurn,run:StoryRun,key:String,right:Bool)->some View {
        let activeSpeaker=audio.previewPlaying ? audio.previewTurn?.speaker:audio.phase == .playing ? audio.currentTurn?.speaker:nil
        let speaking=activeSpeaker == turn.speaker
        let speaker=StoryAppearance.isUser(turn.speaker,learnerName:app.learner.name) ? t("you"):turn.speaker
        let visible=translations.contains(key)
        let avatar=StoryCharacterAvatar(name:turn.speaker,portraitID:run.portraitIDs?[turn.speaker],speaking:speaking,accent:right ? PiyaliBrand.unitColor("9f7aea"):PiyaliBrand.teal)
        return HStack(alignment:.top,spacing:12) {
            if !right { avatar }
            VStack(alignment:.leading,spacing:10) {
                HStack {
                    Text(speaker).font(PiyaliBrand.productFont(12,700)).foregroundStyle(brand.secondary)
                    Spacer()
                    HStack(spacing:4) {
                        Button { playPreview(turn,run:run) } label:{
                            PracticeIcon(name:"FiVolume2",size:17).frame(width:32,height:32)
                        }
                        .disabled(audio.active && !run.heard.contains(run.index))
                        .accessibilityLabel(t("play")+": "+speaker).accessibilityIdentifier("storyDialoguePlay-"+key)
                        Button { translate(turn,run:run,key:key) } label:{ storyTranslationIcon }.foregroundStyle(visible ? PiyaliBrand.teal:brand.secondary)
                            .accessibilityLabel(t(visible ? "hideTranslation":"translation")).accessibilityIdentifier("storyTranslate-"+key)
                    }.buttonStyle(.plain)
                }
                Text(turn.target).font(PiyaliBrand.productFont(18,500)).lineSpacing(6).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,run.target == "ar" ? .rightToLeft : .leftToRight).accessibilityIdentifier("storyDialogue-"+key)
                if visible {
                    if translating.contains(key) { ProgressView() }
                    else if let text=run.translations[key] ?? provisionalTranslations[key] ?? turn.support,!text.isEmpty { Text(text).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,run.support == "ar" ? .rightToLeft : .leftToRight) }
                }
            }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(brand.surface,in:RoundedRectangle(cornerRadius:24)).overlay { RoundedRectangle(cornerRadius:24).stroke(speaking ? PiyaliBrand.teal:brand.border) }
            if right { avatar }
        }
    }

    private var storyTranslationIcon:some View {
        Image("ConversationTranslate").resizable().renderingMode(.template).frame(width:18,height:18)
            .frame(width:32,height:32)
            .contentShape(Rectangle())
    }
    private func replay(_ run:StoryRun)->some View {
        Button {
            if audio.phase == .awaitingSpeech {
                speech.cancel()
                audio.replaySpeechContext(user:narrationUser)
            } else {
                startPlayback(run,replay:run.heard.contains(run.index))
            }
        } label:{
            Label(t("replay"),systemImage:"arrow.counterclockwise")
        }
        .font(PiyaliBrand.productFont(14,600)).buttonStyle(.plain)
        .disabled(audio.active).accessibilityIdentifier("storyReplay")
    }

    private func playPreview(_ turn:StoryTurn,run:StoryRun) {
        if audio.phase == .awaitingSpeech { speech.cancel() }
        audio.preview(turn,language:run.target,user:narrationUser)
    }

    private func userTurn(_ run:StoryRun,turn:StoryTurn)->some View {
        let key="role-\(run.index)-\(audio.roleIndex ?? 0)"
        let visible=translations.contains(key)
        return panel(inset:20) {
            VStack(alignment:.leading,spacing:12) {
                HStack {
                    Text(t("yourTurn")+":").font(PiyaliBrand.productFont(16,700))
                    Spacer()
                    HStack(spacing:4) {
                        Button { playPreview(turn,run:run) } label:{
                            PracticeIcon(name:"FiVolume2",size:17).frame(width:32,height:32)
                        }.accessibilityLabel(t("play")+": "+t("you")).accessibilityIdentifier("storyRolePlay")
                        Button { translate(turn,run:run,key:key) } label:{
                            storyTranslationIcon
                        }
                        .foregroundStyle(visible ? PiyaliBrand.teal:brand.secondary)
                        .accessibilityLabel(t(visible ? "hideTranslation":"translation"))
                        .accessibilityAddTraits(visible ? .isSelected:[])
                        .accessibilityIdentifier("storyRoleTranslate")
                    }.buttonStyle(.plain)
                }
                Text(turn.target).font(PiyaliBrand.productFont(18,500))
                    .accessibilityIdentifier("storyRoleTarget")
                    .environment(\.layoutDirection,run.target == "ar" ? .rightToLeft:.leftToRight)
                if visible {
                    if translating.contains(key) { ProgressView() }
                    else if let text=run.translations[key] ?? provisionalTranslations[key] ?? turn.support,!text.isEmpty {
                        Text(text).font(PiyaliBrand.productFont(16)).foregroundStyle(brand.secondary)
                            .accessibilityIdentifier("storyRoleTranslation")
                            .environment(\.layoutDirection,run.support == "ar" ? .rightToLeft:.leftToRight)
                    }
                }
            }
        }
    }
    private func checkpoint(_ run:StoryRun,question:StoryQuestion)->some View {
        let chosen=run.answers[String(run.index)] ?? [],listening=["select_words","order_words"].contains(question.type)
        return panel {
            VStack(alignment:.leading,spacing:16) {
                Text(question.prompt).font(PiyaliBrand.productFont(18,600)).accessibilityIdentifier("storyQuestion")
                if listening,let index=question.audioTurn,let turns=run.currentSegment?.turns,turns.indices.contains(index) { Button { playPreview(turns[index],run:run) } label:{ Label(t("listen"),systemImage:"speaker.wave.2") }.buttonStyle(.bordered).accessibilityIdentifier("storyListenExcerpt") }
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
    private var footerRevision:String { [scope,String(describing:phase),String(active),String(feedbackPortrait),run?.id.uuidString ?? "",String(run?.index ?? 0),String(describing:run?.result),String(describing:run?.speechResult),String(describing:roleResult),String(run?.completed ?? false),run?.answers[String(run?.index ?? 0)]?.description ?? "",String(run?.heard.contains(run?.index ?? 0) ?? false),String(run?.questionAvailable ?? false),audio.phase.rawValue,String(audio.previewError),String(audio.roleIndex ?? -1),String(recordingNow),String(speech.recorder.connecting),String(speech.recorder.evaluating),speech.recorder.error ?? "",String(service.busy),String(service.provisional?.count ?? 0),String(pendingSpeaking != nil),service.error ?? ""].joined(separator:"|") }
    private var footer:some View {
        let result=run?.mode == .speaking ? run?.speechResult : roleResult
        return ActivityFooterSurface(hasFeedback:result != nil || run?.result != nil,feedback:{
            if let run {
                if let result {
                    let percent=Int((Double(run.index)+(result.pass ? (run.mode == .speaking ? 1:0.5):0))/Double(max(1,run.count))*100.0+0.5)
                    let tips=(try? StoryFeedbackPolicy.shared?.tips(result.reasons,language:run.support,targetLabel:ui("language_"+run.target))) ?? []
                    StoryFeedbackView(correct:result.pass,label:run.mode == .speaking ? ui(result.pass ? "story_well_done":"story_almost"):t(result.pass ? "correct":"speechIncorrect"),subtext:run.mode == .speaking && result.pass ? ui("story_score")+": \(result.score)%":"",explanation:result.pass ? "":tips.joined(separator:run.mode == .speaking ? " ":"\n\n"),progress:percent,progressLabel:ui("story_progress"),xp:run.mode == .speaking && result.pass ? 2:0,portrait:feedbackPortrait,speaking:true)
                } else if let correct=run.result,let question=run.currentSegment?.question {
                    let percent=Int(Double(run.index+(correct ? 1:0))/Double(max(1,run.count))*100.0+0.5)
                    StoryFeedbackView(correct:correct,label:t(correct ? "correct":"incorrect"),subtext:"",explanation:correct ? "":question.incorrectFeedback,progress:percent,progressLabel:ui("story_progress"),portrait:feedbackPortrait)
                }
            }
        },actions:{
            if let run,(!service.busy || service.provisional != nil) {
                if pendingSpeaking != nil {ProgressView().frame(maxWidth:.infinity,minHeight:40).accessibilityIdentifier("storyPendingAssessment")} else {primary(run)}
            }
            else { skip;Spacer(minLength:0) }
        })
    }
    @ViewBuilder private func primary(_ run:StoryRun)->some View {
        if run.mode == .speaking,run.speechResult?.pass == false {
            skip
            Button { update { $0.speechResult=nil;$0.lastWords="" };record(run) } label:{ StoryRecordLabel(recorder:speech.recorder,speaking:true,record:t("record"),connecting:t("connectingMic")) }.buttonStyle(ActivityPrimaryButtonStyle(tone:"stop")).disabled(speech.recorder.connecting || speech.recorder.evaluating).accessibilityLabel(t("record")).accessibilityIdentifier("storyRecord")
        } else if let verdict=run.mode == .speaking ? run.speechResult : roleResult {
            Button { if verdict.pass { if run.mode == .speaking { advance(run) } else { roleResult=nil;audio.continueSpeech() } } else { if run.mode == .speaking { update { $0.speechResult=nil;$0.lastWords="" } } else { audio.stopPreview();speech.cancel();roleResult=nil } } } label:{ HStack(spacing:8){Text(run.mode == .speaking && verdict.pass ? ui(run.index == run.count-1 ? "stories_finish":"stories_next_sentence"):t(verdict.pass ? "next":"retry"));PracticeIcon(name:"FiArrowRight",size:14)} }.buttonStyle(ActivityPrimaryButtonStyle(tone:verdict.pass ? "success" : "stop")).accessibilityIdentifier(verdict.pass ? "storyNext" : "storySpeechRetry")
        } else if run.result != nil {
            Button { advance(run) } label:{ HStack(spacing:8){Text(t(run.index == run.count-1 ? "finish":"next"));PracticeIcon(name:"FiArrowRight",size:14)} }.buttonStyle(ActivityPrimaryButtonStyle(tone:run.result == true ? "success" : "stop")).accessibilityIdentifier("storyNext")
        } else if run.completed {
            Button(t("back")) { newStory() }.buttonStyle(ActivityPrimaryButtonStyle()).accessibilityIdentifier("storyNew")
        } else {
            skip
            if run.mode != .speaking,run.isProvisional != true,!run.questionAvailable,run.heard.contains(run.index) {
                Button(t("check")) {}.buttonStyle(ActivityPrimaryButtonStyle()).disabled(true).accessibilityIdentifier("storyCheck")
            } else if run.mode != .speaking,run.isProvisional == true,(run.atEnd || run.heard.contains(run.index) && !run.questionAvailable) {
                ProgressView().frame(maxWidth:.infinity,minHeight:40).accessibilityIdentifier("storyPendingSegment")
            } else if run.mode == .speaking || audio.phase == .awaitingSpeech {
                Button { record(run) } label:{ StoryRecordLabel(recorder:speech.recorder,speaking:run.mode == .speaking,record:t("record"),connecting:t("connectingMic")) }.buttonStyle(ActivityPrimaryButtonStyle(tone:"speak")).disabled(speech.recorder.connecting || speech.recorder.evaluating).accessibilityLabel(t("record")).accessibilityValue(speech.recorder.connecting ? t("connectingMic"):recordingNow ? t("stopRecording"):"").accessibilityIdentifier("storyRecord")
            } else if run.heard.contains(run.index) {
                Button(t("check")) { audio.cancel();update { $0.check() } }.buttonStyle(ActivityPrimaryButtonStyle()).disabled(!run.readyToCheck).accessibilityIdentifier("storyCheck")
            } else {
                Button { startPlayback(run) } label:{ if audio.active { ProgressView().tint(.white) } else { Label(t(audio.phase == .failed ? "retry" : "play"),systemImage:"play") } }.buttonStyle(ActivityPrimaryButtonStyle()).disabled(audio.active).accessibilityIdentifier("storyPlay")
            }
        }
    }
    @ViewBuilder private var skip:some View {
        if let onComplete {
            Button(t("skip")) {
                stop()
                service.cancel()
                onComplete()
                if !embedded { dismiss() }
            }
            .font(PiyaliBrand.productFont(14,600)).foregroundStyle(brand.text)
            .padding(.horizontal,8).frame(minHeight:40).buttonStyle(.plain)
            .accessibilityIdentifier("skipLessonActivity")
        }
    }
    private func update(_ change:(inout StoryRun)->Void) {
        guard hasAccess,let current=run else{return}
        if current.isProvisional == true {service.updateProvisional(current.id,change);return}
        guard var value=app.learner.story,value.id == current.id,value.support == app.learner.support else{return};change(&value);app.learner.saveStory(value);app.persist()
    }
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
            guard app.identity.npub == account,self.run?.id == run.id,self.run?.index == run.index else { return };update { $0.heard.insert(run.index) }
        }
    }
    private func advance(_ run:StoryRun) {
        guard hasAccess,self.run?.id == run.id,self.run?.index == run.index else { return }
        stop();roleResult=nil;update { $0.advance() }
        guard let current=self.run,current.id == run.id else { return }
        if current.atEnd {
            if current.isProvisional == true {
                if current.mode != .speaking,service.retainFinishedEpisode(app,lesson:lesson,id:current.id) {finish()} else {pendingSegmentPlayback=true}
            } else {finish()}
        } else if current.isProvisional == true && current.currentSegment?.turns.isEmpty == true {pendingSegmentPlayback=true}
        else if current.mode != .speaking {startPlayback(current)}
    }
    private func finish() { guard hasAccess else { stop();return };stop();_=app.learner.finishStory();app.persist();if let onComplete { onComplete();if !embedded { dismiss() } } else { newStory() } }
    private func newStory() { stop();chosen=(mode ?? .speaking).next(content:content,random:Double.random(in:0..<1));refresh += 1 }
    private func record(_ run:StoryRun){
        guard hasAccess,app.goalPracticeIsCurrent(lesson) else{stop();return}
        if recordingNow{speech.stop();return};guard !speech.recorder.connecting,!speech.recorder.evaluating else{return}
        let role=run.mode == .speaking ? nil:audio.roleIndex,target=run.mode == .speaking ? run.currentSentence?.target:audio.currentTurn?.target
        guard let target,!target.isEmpty else{return};audio.stopPreview();roleResult=nil
        speech.start(app,run:run,target:target,role:role,allowed:{active && phase == .active && hasAccess && app.goalPracticeIsCurrent(lesson) && (run.mode == .speaking || audio.phase == .awaitingSpeech && audio.roleIndex == role)},currentRun:{self.run}){metadata in
            if run.mode == .speaking {
                if service.provisional?.id == run.id {pendingSpeaking=(run.id,target,metadata)}
                else { _=app.learner.practiceStoryLine(words:metadata["recognizedText"].string,confidence:metadata["confidence"].number,audio:nil,goalFocus:app.goalMemoryFocus(lesson));app.persist() }
            }
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
        guard run.translations[key] == nil,provisionalTranslations[key] == nil,turn.support?.isEmpty != false,!translating.contains(key) else { return }
        translating.insert(key);let account=app.identity.npub
        Task { defer { translating.remove(key) };do { let value=try await app.ai.conversationTranslation(turn.target,support:run.support);guard app.identity.npub == account,self.run?.id == run.id else { return };if service.provisional?.id == run.id {provisionalTranslations[key]=value} else {update { $0.translations[key]=value }} } catch { service.error=error.localizedDescription } }
    }
    private func stop() { speech.cancel();audio.cancel() }
}
private struct StoryRadioSignal:View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var active:Bool
    var body:some View { TimelineView(.animation(minimumInterval:0.08,paused:!active || reduceMotion)) { time in HStack(alignment:.center,spacing:4) { ForEach(0..<12,id:\.self) { index in RoundedRectangle(cornerRadius:2).fill(PiyaliBrand.teal.opacity(0.65)).frame(width:4,height:active && !reduceMotion ? 5+abs(sin(time.date.timeIntervalSinceReferenceDate*5+Double(index)))*23 : 5) } } } }
}

private struct StoryPreparationSkeleton:View {
    let mode:StoryMode
    let status:String
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started=Date()
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var muted:Color { PiyaliBrand.unitColor(brand.dark ? "182031":"efe4d5") }
    private let teal=PiyaliBrand.unitColor("2dd4bf")
    private let indigo=PiyaliBrand.unitColor("6366f1")

    var body:some View {
        let paused=reduceMotion || phase != .active
        TimelineView(.animation(minimumInterval:1/20,paused:paused)) { clock in
            let elapsed=paused ? 0:max(0,clock.date.timeIntervalSince(started))
            let pulse=0.5-0.5*cos(.pi*elapsed/0.8)
            VStack(alignment:.leading,spacing:16) {
                HStack(spacing:8) {
                    Text(status).font(PiyaliBrand.productFont(12,500)).foregroundStyle(brand.secondary)
                        .accessibilityIdentifier("storyLoading")
                    HStack(spacing:6) {
                        ForEach(0..<3) { index in
                            let time=max(0,elapsed-Double(index)*0.14)
                            let lift=paused ? 0.5:0.5-0.5*cos(2 * .pi*time/0.9)
                            Circle().fill(teal).frame(width:6,height:6)
                                .opacity(0.28+0.72*lift).offset(y:-3*lift)
                        }
                    }.accessibilityHidden(true)
                }
                .frame(maxWidth:.infinity,minHeight:24).opacity(0.75)
                placeholders(pulse).accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder private func placeholders(_ pulse:Double)->some View {
        let titleWidth:CGFloat=mode == .radio ? 180:mode == .conversation ? 200:220
        VStack(alignment:.leading,spacing:20) {
            block(width:titleWidth,height:22,radius:6,pulse:pulse)
            switch mode {
            case .radio:
                radioPanel(pulse)
                VStack(spacing:12) {
                    transcript(right:false,avatar:32,name:50,main:0.90,detail:0.65,fill:brand.surface,pulse:pulse)
                    transcript(right:true,avatar:32,name:40,main:0.85,detail:0.50,fill:teal.opacity(0.12),pulse:pulse)
                }
                quiz(prompt:0.65,pulse:pulse)
            case .conversation:
                VStack(spacing:16) {
                    transcript(right:false,avatar:36,name:55,main:0.90,detail:0.60,fill:muted,pulse:pulse)
                    transcript(right:true,avatar:36,name:45,main:0.85,detail:0.50,fill:indigo.opacity(0.12),pulse:pulse)
                    transcript(right:false,avatar:36,name:60,main:0.95,detail:nil,fill:muted,pulse:pulse)
                }.padding(20).background { card(radius:24) }
                quiz(prompt:0.60,pulse:pulse)
            case .speaking:
                VStack(spacing:16) {
                    transcript(right:false,avatar:36,name:60,main:0.85,detail:0.55,fill:teal.opacity(0.15),pulse:pulse)
                    transcript(right:true,avatar:36,name:50,main:0.90,detail:0.60,fill:indigo.opacity(0.15),pulse:pulse)
                }.padding(24).background { card(radius:20) }
                block(width:160,height:56,radius:28,pulse:pulse)
                    .padding(.top,16).frame(maxWidth:.infinity)
            }
        }
    }

    private func radioPanel(_ pulse:Double)->some View {
        VStack(spacing:24) {
            HStack {
                block(width:88,height:22,radius:11,pulse:pulse)
                Spacer()
                block(width:64,height:18,radius:6,pulse:pulse)
            }
            HStack(spacing:8) {
                ForEach([28,44,32,48,24,38,20],id:\.self) { height in
                    Capsule().fill(teal.opacity(0.2+0.3*pulse)).frame(width:6,height:CGFloat(height))
                }
            }.frame(height:50)
            HStack(spacing:12) {
                block(width:36,height:36,radius:18,pulse:pulse)
                VStack(alignment:.leading,spacing:6) {
                    block(width:70,height:14,radius:2,pulse:pulse)
                    block(width:45,height:10,radius:2,pulse:pulse)
                }
            }
        }.padding(24).background {
            RoundedRectangle(cornerRadius:24)
                .fill(LinearGradient(colors:[brand.surface,muted],startPoint:.topLeading,endPoint:.bottomTrailing))
                .overlay { RoundedRectangle(cornerRadius:24).strokeBorder(brand.border,lineWidth:1) }
        }
    }

    private func transcript(right:Bool,avatar:CGFloat,name:CGFloat,main:CGFloat,
                            detail:CGFloat?,fill:Color,pulse:Double)->some View {
        let voice=mode == .speaking
        let accent=right ? indigo:teal
        let inset:CGFloat=voice ? 12:14
        let voiceControl:CGFloat=voice ? 40:0
        let detailHeight:CGFloat=detail == nil ? 0:20
        return GeometryReader { geometry in
            let available=geometry.size.width
            let rowWidth=mode == .radio ? available*0.85:available
            let limit:CGFloat=right ? 0.75:detail == nil ? 0.82:0.78
            let maxBubbleWidth=mode == .radio && right ? name+2*inset:mode == .conversation ? rowWidth*limit:rowWidth
            let width=max(0,min(rowWidth-avatar-12-voiceControl,maxBubbleWidth))
            HStack(alignment:.top,spacing:12) {
                if !right { speakerControls(avatar:avatar,pulse:pulse) }
                VStack(alignment:.leading,spacing:6) {
                    block(width:name,height:voice ? 14:12,radius:3,pulse:pulse).padding(.bottom,2)
                    line(main,height:voice ? 18:16,pulse:pulse)
                    if let detail { line(detail,height:14,pulse:pulse) }
                }
                .padding(inset)
                .frame(width:width)
                .background(fill,in:RoundedRectangle(cornerRadius:mode == .conversation ? 16:12))
                .overlay(alignment:right ? .trailing:.leading) {
                    if voice { Capsule().fill(accent.opacity(0.5)).frame(width:3) }
                }
                .overlay {
                    if mode == .radio {
                        RoundedRectangle(cornerRadius:12).stroke(right ? teal.opacity(0.25):brand.border)
                    }
                }
                if right { speakerControls(avatar:avatar,pulse:pulse,reversed:true) }
            }
            .frame(maxWidth:.infinity,alignment:right ? .trailing:.leading)
        }.frame(height:2*inset+(voice ? 40:36)+detailHeight)
    }

    private func speakerControls(avatar:CGFloat,pulse:Double,reversed:Bool=false)->some View {
        HStack(alignment:.top,spacing:12) {
            if reversed,mode == .speaking { block(width:28,height:28,radius:6,pulse:pulse).padding(.top,4) }
            block(width:avatar,height:avatar,radius:avatar/2,pulse:pulse)
            if !reversed,mode == .speaking { block(width:28,height:28,radius:6,pulse:pulse).padding(.top,4) }
        }
    }

    private func quiz(prompt:CGFloat,pulse:Double)->some View {
        VStack(spacing:10) {
            line(prompt,height:18,pulse:pulse).padding(.bottom,6)
            ForEach(0..<2) { _ in line(1,height:48,radius:12,pulse:pulse) }
        }.padding(16).background { card(radius:24) }
    }

    private func block(width:CGFloat,height:CGFloat,radius:CGFloat,pulse:Double)->some View {
        RoundedRectangle(cornerRadius:radius)
            .fill(muted)
            .overlay { RoundedRectangle(cornerRadius:radius).fill(brand.surface.opacity(pulse)) }
            .frame(width:width,height:height)
    }

    private func line(_ fraction:CGFloat,height:CGFloat,radius:CGFloat=4,pulse:Double)->some View {
        GeometryReader { geometry in
            block(width:geometry.size.width*fraction,height:height,radius:radius,pulse:pulse)
        }.frame(height:height)
    }

    private func card(radius:CGFloat)->some View {
        RoundedRectangle(cornerRadius:radius).fill(brand.surface)
            .overlay { RoundedRectangle(cornerRadius:radius).strokeBorder(brand.border,lineWidth:1) }
    }
}
