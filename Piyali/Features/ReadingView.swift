import SwiftUI

/// The source passage card, sentence audio, randomized review and action area.
struct ReadingView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @StateObject private var service=ReadingService()
    @StateObject private var audio=ReadingPlaybackService()
    @StateObject private var recorder=ReadingSpeechRecorder()
    let lesson:Lesson?
    var onComplete:(()->Void)? = nil
    var embedded=false
    var startsFresh=false
    @State private var footerOwner=UUID()
    @State private var appeared=false
    @State private var refresh=0
    @State private var keyboardOpen=false
    @State private var showTranslation=false
    private var activeSentence:Int? { audio.activeSentence }
    private var readingAll:Bool { audio.readingAll }
    @State private var recordingScope:String?
    @State private var active=false
    @FocusState private var answering:Bool
    private static let keyboard=(try? WritingKeyboard()) ?? WritingKeyboard(data:.null)
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var hasAccess:Bool { app.subscription.hasAccess || ReadingService.fixture }
    private var recordingNow:Bool { recorder.phase == .listening }
    private var finalizing:Bool { recorder.phase == .stopping }
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,app.learner.level,lesson?.id ?? "free",String(refresh)].joined(separator:"|") }
    private var run:ReadingRun? { guard !service.generating,!service.suppressedPrevious,let run=app.learner.reading,run.support == app.learner.support,run.lessonID == lesson?.id else { return nil };return run }
    private func t(_ key:String)->String { EntryCopy.ui(app.learner.support,key) }
    var body:some View {
        Group { if ReadingService.fixture { activity } else { SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:app.preserveEarnedGoalLesson(lesson)) { activity } } }
            .activityFooter(owner:footerOwner,revision:footerRevision,access:app.subscription,fixtureAllowed:ReadingService.fixture,correct:run?.correct) { footer }
            .navigationTitle(embedded ? lesson?.title.localized(app.learner.support) ?? t("reading_title") : t("reading_title"))
            .task(id:scope) { stop();showTranslation=false;let fresh=refresh > 0 || startsFresh && !appeared;appeared=true;await service.prepare(app,lesson:lesson,fresh:fresh);guard !Task.isCancelled else { return };recorder.restore(run?.method == "speech" && run?.awarded == false ? run?.answer ?? "" : "") }
            .task(id:run?.id) {if let run {await service.ensureReviewQuestion(app,run:run)}}
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button(t("proficiency_modal_done")) { answering=false }.accessibilityIdentifier("readingKeyboardDone") } }
            .onChange(of:recorder.phase) { previous,value in if previous != .idle,value == .idle { saveTranscript() } }
            .onChange(of:run?.id) { _,_ in closeReviewKeyboard();stop();recorder.restore(run?.method == "speech" && run?.awarded == false ? run?.answer ?? "" : "") }
            .onChange(of:run?.awarded) { _,value in if value == true { closeReviewKeyboard();stop() } }
            .onAppear { active=true }
            .onChange(of:hasAccess) { _,value in if !value { closeReviewKeyboard();stop();service.cancel() } }
            .onChange(of:phase) { _,value in if value == .background { closeReviewKeyboard();saveTranscript();stop();service.cancel() } else if value == .active,run == nil { refresh += 1 } }
            .onDisappear { active=false;closeReviewKeyboard();saveTranscript();service.cancel();stop() }
    }
    private var activity:some View {
        VStack(spacing:0) {
            ScrollView {
                VStack(alignment:.leading,spacing:12) {
                    Label {OnboardingText(text:t("reading_title"),size:16,weight:.semibold,lineHeight:24)}
                    icon:{PracticeIcon(name:"MdMenuBook",size:16)}
                    if service.generating,let draft=service.draft {
                        draftPassage(draft)
                    } else if let run {
                        VStack(alignment:.leading,spacing:16) {
                            readingTitle(run.title,target:run.target)
                            ReadingAudioControls(support:app.learner.support,loading:audio.readingAll && audio.loading,stopActive:readingAll,read:{stop();audio.play(run.text,language:run.target)},stop:stop)
                            passage(run)
                            VStack(alignment:.leading,spacing:12) {
                                Divider().opacity(0.2)
                                if run.method == "question" { question(run) }
                                else { recording(run) }
                            }
                            takeaways(run.takeaways,support:run.support)
                        }.modifier(ReadingCardSurface())
                    } else if let error=service.error { generationError(error) }
                    else {
                        ReadingLoadingSkeleton(status:t(service.generating ? "reading_generating":"reading_loading"),kind:.passage)
                            .modifier(ReadingCardSurface())
                    }
                    if run != nil,let error=service.error { Text(error).foregroundStyle(brand.questionError) }
                }.padding(.horizontal,12).padding(.top,6).padding(.bottom,8).frame(maxWidth:1100).frame(maxWidth:.infinity)
            }
            Color.clear.frame(height:app.activityFooterHeight)
        }.font(PiyaliBrand.productFont(16)).foregroundStyle(brand.text).background(brand.background)
    }
    private func generationError(_ message:String)->some View {
        let leading=max(0,24-UIFont.systemFont(ofSize:16).lineHeight)
        return VStack(alignment:.leading,spacing:12) {
            Text(message).font(PiyaliBrand.productFont(16)).lineSpacing(leading).padding(.vertical,leading/2).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("readingGenerationError")
            Button(t("try_again")) {refresh += 1}.buttonStyle(ReadingRetryButtonStyle()).disabled(service.busy).accessibilityIdentifier("readingRetry")
        }.modifier(ReadingCardSurface())
            .accessibilityElement(children:.contain)
            .accessibilityIdentifier("readingGenerationErrorCard")
    }
    private func draftPassage(_ draft:ReadingStreamDraft)->some View {
        let sentences=Reading.displaySentences(draft.text)
        return VStack(alignment:.leading,spacing:16) {
            (Text(draft.title).font(PiyaliBrand.productFont(18,700)) + Text(" ("+t("reading_generating")+")").font(PiyaliBrand.productFont(14)).foregroundColor(brand.secondary))
                .frame(maxWidth:.infinity,minHeight:27,alignment:.leading)
                .environment(\.layoutDirection,textDirection(app.learner.target))
                .accessibilityIdentifier("readingDraftTitle")
            ReadingAudioControls(support:app.learner.support,loading:false,stopActive:readingAll,enabled:false,read:{},stop:stop)
            VStack(alignment:.leading,spacing:14) {
                if !sentences.isEmpty {
                    ReadingSentenceText(sentences:sentences,active:activeSentence,dark:scheme == .dark,onSelect:{index in stop();audio.play(sentences[index],language:app.learner.target,sentence:index)})
                        .accessibilityIdentifier("readingDraftPassage").environment(\.layoutDirection,app.learner.target == "ar" ? .rightToLeft:.leftToRight)
                }
                if app.learner.settingsSnapshot["progress"]["showTranslations"] != .bool(false) {
                    HStack {Spacer();Button(t("history_translate")) {}.font(PiyaliBrand.productFont(13,600)).padding(.horizontal,12).padding(.vertical,10).foregroundStyle(.white).background(Color(red:64/255,green:103/255,blue:96/255),in:RoundedRectangle(cornerRadius:10)).buttonStyle(.plain).accessibilityIdentifier("readingDraftTranslate")}
                }
            }.modifier(ReadingPassageSurface())
            takeaways(draft.takeaways,support:app.learner.support)
        }.modifier(ReadingCardSurface())
    }
    private func textDirection(_ language:String)->LayoutDirection { language == "ar" ? .rightToLeft:.leftToRight }
    private func readingTitle(_ title:String,target:String)->some View {
        OnboardingText(text:title,size:18,weight:.bold,lineHeight:27)
            .frame(maxWidth:.infinity,alignment:.leading)
            .environment(\.layoutDirection,textDirection(target))
    }
    @ViewBuilder private func takeaways(_ lines:[String],support:String)->some View {
        if !lines.isEmpty {
            VStack(alignment:.leading,spacing:6) {
                OnboardingText(text:t("reading_takeaways_heading"),size:14,weight:.semibold,lineHeight:21).opacity(0.9)
                ForEach(Array(lines.enumerated()),id:\.offset) { _,line in
                    OnboardingText(text:"• "+line,size:14,lineHeight:21)
                        .frame(maxWidth:.infinity,alignment:.leading)
                        .environment(\.layoutDirection,textDirection(support))
                }
            }.padding(.top,48)
        }
    }
    private func passage(_ run:ReadingRun)->some View {
        let sentences=Reading.displaySentences(run.text)
        return VStack(alignment:.leading,spacing:14) {
            if !showTranslation {
                ReadingSentenceText(sentences:sentences,active:activeSentence,dark:scheme == .dark,onSelect:{ index in stop();audio.play(sentences[index],language:run.target,sentence:index) }).accessibilityIdentifier("readingPassage").environment(\.layoutDirection,run.target == "ar" ? .rightToLeft : .leftToRight)
            } else { VStack(alignment:.leading,spacing:8) {
                ForEach(Array(sentences.enumerated()),id:\.offset) { index,sentence in
                    VStack(alignment:.leading,spacing:4) {
                        Button { stop();audio.play(sentence,language:run.target,sentence:index) } label:{
                            Text(sentence).font(PiyaliBrand.productFont(16)).lineSpacing(max(0,24-UIFont.systemFont(ofSize:16).lineHeight)).multilineTextAlignment(.leading)
                                .padding(.horizontal,4).padding(.vertical,max(0,24-UIFont.systemFont(ofSize:16).lineHeight)/2).foregroundStyle(brand.text)
                                .background {RoundedRectangle(cornerRadius:2).fill(activeSentence == index ? PiyaliBrand.unitColor("38b2ac").opacity(0.35):sentenceColor(index).opacity(0.12)).shadow(color:activeSentence == index ? PiyaliBrand.unitColor("008080"):sentenceColor(index).opacity(0.3),radius:0,y:4)}
                                .overlay {RoundedRectangle(cornerRadius:2).stroke(activeSentence == index ? PiyaliBrand.unitColor("38b2ac"):.white.opacity(0.12),lineWidth:1)}
                        }.buttonStyle(.plain).accessibilityIdentifier("readingSentence-\(index)")
                        if showTranslation,let lines=service.translationLines(for:run.id) ?? run.lineTranslations,lines.indices.contains(index),!lines[index].isEmpty { Text(lines[index]).font(PiyaliBrand.productFont(14)).italic().lineSpacing(max(0,21-UIFont.systemFont(ofSize:14).lineHeight)).padding(.vertical,max(0,21-UIFont.systemFont(ofSize:14).lineHeight)/2).padding(.horizontal,4).padding(.bottom,12).foregroundStyle(.white.opacity(0.8)).opacity(0.9).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("readingTranslation-\(index)").environment(\.layoutDirection,run.support == "ar" ? .rightToLeft : .leftToRight) }
                    }
                }
            }.environment(\.layoutDirection,run.target == "ar" ? .rightToLeft : .leftToRight) }
            if showTranslation,run.lineTranslations == nil,let translation=run.translation { Text(translation).font(PiyaliBrand.productFont(14)).italic().foregroundStyle(brand.secondary) }
            if app.learner.settingsSnapshot["progress"]["showTranslations"] != .bool(false) {
                let hasTranslation=run.translation != nil || !(service.translationLines(for:run.id) ?? run.lineTranslations ?? []).isEmpty
                HStack { Spacer();Button {
                    if hasTranslation {showTranslation.toggle()}
                    else if !sentences.isEmpty {
                        let requestedScope=scope;showTranslation=true
                        Task {
                            let success=await service.translate(app,run:run)
                            guard requestedScope == scope,self.run?.id == run.id else{return}
                            if !success,let visible=service.translationVisibility(for:run.id) {showTranslation=visible}
                        }
                    }
                } label:{
                    HStack(spacing:6) {
                        if service.translationLoading {ProgressView().tint(.white)}
                        Text(t(service.translationLoading ? "history_translating" : !hasTranslation ? "history_translate" : showTranslation ? "history_hide_translation":"history_show_translation"))
                    }
                }.buttonStyle(ReadingRetryButtonStyle(size:14,height:32,horizontal:13,background:hasTranslation && showTranslation ? "48379c":"406760",edge:hasTranslation && showTranslation ? "0d012c":"39534f"))
                    .disabled(service.translationLoading).accessibilityIdentifier("readingTranslate")
                }.padding(.top,2)
            }
        }.modifier(ReadingPassageSurface())
    }
    private func sentenceColor(_ index:Int)->Color { [PiyaliBrand.unitColor("38b2ac"),Color(red:128/255,green:90/255,blue:213/255),Color(red:237/255,green:137/255,blue:54/255),Color(red:99/255,green:179/255,blue:237/255),Color(red:246/255,green:173/255,blue:85/255)][index%5] }
    @ViewBuilder private func question(_ run:ReadingRun)->some View {
        if run.pendingQuestionType != nil {
            if service.questionGenerating {ReadingLoadingSkeleton(status:t("history_generating_question"),kind:.question)}
        } else {
            OnboardingText(text:run.question.question,size:14,lineHeight:22.4)
                .frame(maxWidth:.infinity,alignment:.leading)
                .environment(\.layoutDirection,textDirection(run.support))
                .accessibilityIdentifier("readingQuestion")
            if run.question.type == "mc" {
                VStack(spacing:8) {
                    ForEach(Array(run.question.options.enumerated()),id:\.offset) { index,option in
                        let selected=run.answer == option
                        Button {
                            changeReviewAnswer(option,for:run.id)
                        } label: {
                            ReadingAnswerOption(letter:UnicodeScalar(65+index).map(String.init) ?? "",text:option,direction:textDirection(run.support),selected:selected)
                        }.buttonStyle(.plain).disabled(service.busy || run.awarded)
                            .accessibilityLabel(option)
                            .accessibilityAddTraits(selected ? .isSelected:[])
                            .accessibilityIdentifier("readingOption-\(index)")
                    }
                }
            } else {
                typedReview(run)
            }
        }
    }
    private func typedReview(_ review:ReadingRun)->some View {
        let placeholder=t(review.question.type == "fill" ? "history_fill_blank_placeholder" : "history_answer_placeholder")
        return VStack(alignment:.leading,spacing:12) {
            TextField(placeholder,text:Binding(
                get:{self.run?.id == review.id ? self.run?.answer ?? "" : ""},
                set:{changeReviewAnswer($0,for:review.id)}
            ))
            .font(PiyaliBrand.productFont(14))
            .padding(.horizontal,12)
            .frame(minHeight:32)
            .overlay {EntryCornerShape(radius:6).stroke(answering ? PiyaliBrand.unitColor("3182ce") : brand.border,lineWidth:answering ? 2:1)}
            .focused($answering)
            .submitLabel(.go)
            .onSubmit {submitReview(review.id)}
            .disabled(service.busy || review.awarded)
            .accessibilityIdentifier("readingAnswer")
            .frame(maxWidth:400)

            if Self.keyboard.supported(review.target),!review.awarded {
                if keyboardOpen {
                    WritingVirtualKeyboard(language:review.target,support:review.support,keyboard:Self.keyboard,onKey:{key in
                        guard let current=editableReview(review.id) else {return}
                        changeReviewAnswer(WritingKeyboard.press(key,text:current.answer,disabled:false),for:review.id)
                    },onClose:{keyboardOpen=false})
                    .disabled(service.busy)
                }
                Button {
                    answering=false
                    keyboardOpen.toggle()
                } label:{
                    Label {Text(t(keyboardOpen ? "history_keyboard_close":"history_keyboard_open"))}
                    icon:{PracticeIcon(name:"MdKeyboard",size:16)}
                    .font(PiyaliBrand.productFont(14,600))
                    .padding(.horizontal,12)
                    .frame(minHeight:44)
                    .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .disabled(service.busy)
                    .accessibilityIdentifier("readingKeyboardToggle")
            }
        }
    }
    private func editableReview(_ id:UUID)->ReadingRun? {
        guard hasAccess,active,phase == .active,!service.busy,let run,run.id == id,
              run.method == "question",run.pendingQuestionType == nil,!run.awarded else {return nil}
        return run
    }
    private func changeReviewAnswer(_ answer:String,for id:UUID) {
        guard var current=editableReview(id),current.answer != answer else {return}
        current.answer=answer
        current.correct=nil
        current.feedback=""
        app.learner.saveReading(current)
        app.persist()
    }
    private func submitReview(_ id:UUID) {
        guard let current=editableReview(id),!current.answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else {return}
        answering=false
        stop()
        Task {await service.check(app,run:current,answer:current.answer,speech:false,lesson:lesson)}
    }
    private func closeReviewKeyboard() {
        answering=false
        keyboardOpen=false
    }
    @ViewBuilder private func recording(_ run:ReadingRun)->some View {
        if !run.awarded {
            if recordingNow {
                VStack(spacing:4) {
                    PublicVoiceOrb(animating:active && phase == .active,size:75).frame(width:75,height:75).accessibilityIdentifier("readingListeningOrb")
                    Text(t("history_speech_listening")).font(PiyaliBrand.productFont(12,600)).tracking(0.48).opacity(0.8)
                }.frame(maxWidth:.infinity)
            }
            if !recorder.transcript.isEmpty {
                OnboardingText(text:recorder.transcript,size:12,lineHeight:21.6).italic().opacity(0.9)
                    .frame(maxWidth:.infinity,alignment:.leading)
                    .environment(\.layoutDirection,textDirection(run.target))
                    .accessibilityIdentifier("readingSpeechTranscript")
            }
            if let code=recorder.issue { let copy=ReadingSpeechCapture.feedback(code);Text(t(copy.title)+". "+t(copy.description)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).accessibilityIdentifier("readingRecordingError") }
        }
    }
    private var footerRevision:String { [scope,run?.id.uuidString ?? "",String(run?.awarded ?? false),String(describing:run?.correct),run?.feedback ?? "",String(lessonPercent ?? -1),run?.explanation ?? "",run?.answer ?? "",String(service.busy),String(service.generating),String(service.translationLoading),String(service.questionGenerating),String(service.questionFailed),run?.pendingQuestionType ?? "",String(service.suppressedPrevious),service.error ?? "",recorder.phase.rawValue,recorder.transcript,recorder.issue ?? ""].joined(separator:"|") }
    private var lessonPercent:Int? { guard let lesson,lesson.id != IntroTutorial.lessonID,lesson.xpReward > 0 else { return nil };let work=app.learner.lessonWork?[app.learner.completionKey(lesson.id)];return Int((work?.fraction(goal:lesson.xpReward) ?? 0)*100+0.5) }
    private var footer:some View {
        ActivityFooterSurface(feedbackLimit:run?.method == "speech" ? UIScreen.main.bounds.height*0.45 : nil,hasFeedback:run?.feedback.isEmpty == false || run?.awarded == true,feedback:{
            if let run,run.method == "speech",run.awarded {
                ReadingSpeechFeedbackView(feedback:run.speechFeedback ?? ReadingSpeechFeedback(.object(["summary":.string(run.feedback)])) ?? .unavailable(support:run.support),support:run.support,reward:run.reward,progress:lessonPercent)
            } else if let run {
                VStack(alignment:.leading,spacing:12) {
                    if !run.feedback.isEmpty { Text(run.feedback).font(PiyaliBrand.productFont(15,600)).foregroundStyle(run.awarded ? brand.questionSuccess : brand.questionError).accessibilityIdentifier("readingFeedback") }
                    if run.method == "question",run.correct != nil {
                        if let explanation=run.explanation { Text(explanation).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).accessibilityIdentifier("readingExplanation") }
                        else { Button(t("history_explain_answer")) { Task { await service.explain(app,run:run) } }.font(PiyaliBrand.productFont(14,600)).disabled(service.busy).accessibilityIdentifier("readingExplain") }
                    }
                    if run.awarded { Text(t("reading_xp_awarded_line").replacingOccurrences(of:"{xp}",with:String(run.reward)).replacingOccurrences(of:"{reason}",with:"")).font(PiyaliBrand.productFont(14,600)).foregroundStyle(brand.questionSuccess).accessibilityIdentifier("readingCompleted") }
                }.padding(.vertical,6)
            }
        },actions:{
            if let onComplete { Button(t("reading_skip")) { stop();onComplete();if !embedded { dismiss() } }.font(PiyaliBrand.productFont(14,600)).foregroundStyle(brand.secondary).accessibilityIdentifier("skipLessonActivity") }
            if let run { primary(run) }
            else { Button {} label:{ProgressView().tint(.white).frame(maxWidth:.infinity,minHeight:40)}.buttonStyle(ActivityPrimaryButtonStyle()).disabled(true).accessibilityLabel(t("reading_loading")).accessibilityIdentifier("readingWaiting") }
        })
    }
    @ViewBuilder private func primary(_ run:ReadingRun)->some View {
        if run.awarded {
            Button(t("reading_btn_next")) { guard hasAccess else { return };stop();if let onComplete { onComplete();if !embedded { dismiss() } } else { refresh += 1 } }.buttonStyle(ActivityPrimaryButtonStyle(tone:"success")).accessibilityIdentifier("readingContinue")
        } else if run.method == "question",run.pendingQuestionType != nil {
            Button {Task {await service.ensureReviewQuestion(app,run:run,retry:true)}} label:{if service.questionGenerating {ProgressView().tint(.white)} else {Text(t("history_generate_review"))}}.buttonStyle(ActivityPrimaryButtonStyle()).disabled(service.questionGenerating || run.text.isEmpty).accessibilityIdentifier("readingGenerateQuestion")
        } else if run.method == "question" {
            Button {submitReview(run.id)} label:{
                if service.busy {ProgressView().tint(.white)} else {Text(t("quiz_submit"))}
            }.buttonStyle(ActivityPrimaryButtonStyle())
                .disabled(service.busy || run.answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("readingCheck")
        } else {
            if !recorder.transcript.isEmpty,!recordingNow,!finalizing { Button(t("history_speech_start_over")) { guard hasAccess else { return };stop();recorder.restore("");update { $0.answer="" } }.font(PiyaliBrand.productFont(14,600)).disabled(service.busy).accessibilityIdentifier("readingSpeechStartOver") }
            Button {
                guard hasAccess,active,phase == .active,!finalizing,!service.busy,app.learner.reading?.id == run.id,app.learner.target == run.target,app.learner.support == run.support else { return }
                if recordingNow { recorder.stop() }
                else if !recorder.transcript.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { let words=recorder.transcript;Task { await service.check(app,run:run,answer:words,speech:true,lesson:lesson) } }
                else { stop();recordingScope=app.identity.npub+":"+run.id.uuidString;recorder.start(language:run.target) }
            } label:{ if service.busy || finalizing { ProgressView().tint(.white) } else { Label(t(recordingNow ? "history_speech_stop_mic" : recorder.transcript.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? "history_speech_start_mic" : "history_speech_submit"),systemImage:recordingNow ? "stop.fill" : "mic.fill") } }.buttonStyle(ActivityPrimaryButtonStyle(tone:recordingNow ? "stop" : recorder.transcript.isEmpty ? "speak" : "primary")).disabled(service.busy || finalizing).accessibilityIdentifier("readingMicrophone").accessibilityValue(recorder.phase.rawValue)
        }
    }
    private func saveTranscript() { guard let run,run.method == "speech",!run.awarded,recordingScope == app.identity.npub+":"+run.id.uuidString else { return };let words=ReadingSpeechCapture.boundedTranscript(recorder.transcript);guard words != run.answer else { return };update { $0.answer=words } }
    private func stop() { saveTranscript();recordingScope=nil;recorder.cancel();audio.stop() }
    private func update(_ action:(inout ReadingRun)->Void) { guard var current=app.learner.reading,current.id == run?.id else { return };action(&current);app.learner.saveReading(current);app.persist() }
}

/// The source theme's default blue Retry control, including its four-point edge.
private struct ReadingCardSurface:ViewModifier {
    func body(content:Content)->some View {
        content.padding(13)
            .frame(maxWidth:.infinity,minHeight:280,alignment:.topLeading)
            .background {EntryCornerShape(radius:12).fill(.white.opacity(0.05))}
            .overlay {EntryCornerShape(radius:12).stroke(.white.opacity(0.1),lineWidth:1)}
    }
}

private struct ReadingPassageSurface:ViewModifier {
    @Environment(\.layoutDirection) private var direction
    var padding:CGFloat=12
    var opacity=0.15
    private let teal=PiyaliBrand.unitColor("38b2ac")
    func body(content:Content)->some View {
        content.padding(padding)
            .padding(direction == .rightToLeft ? .trailing:.leading,3)
            .background(teal.opacity(opacity))
            .overlay(alignment:direction == .rightToLeft ? .trailing:.leading) {Rectangle().fill(teal).frame(width:3)}
            .clipShape(EntryCornerShape(radius:8))
    }
}

private struct ReadingAnswerOption:View {
    let letter:String,text:String,direction:LayoutDirection,selected:Bool
    @Environment(\.colorScheme) private var scheme
    private let teal=PiyaliBrand.unitColor("38b2ac")
    private var dark:Bool {scheme == .dark}
    private var paperInk:Color {PiyaliBrand.unitColor("5a4736")}
    var body:some View {
        HStack(spacing:12) {
            Text(letter).font(PiyaliBrand.productFont(12,700))
                .foregroundStyle(selected || dark ? .white:PiyaliBrand.unitColor("2f261d"))
                .frame(width:28,height:28)
                .background(selected ? teal:.clear,in:Circle())
                .overlay {Circle().strokeBorder(selected ? teal:dark ? .white.opacity(0.16):paperInk.opacity(0.42),lineWidth:2)}
            OnboardingText(text:text,size:14,lineHeight:21)
                .environment(\.layoutDirection,direction)
            Spacer(minLength:0)
        }
        .padding(13)
        .background {
            EntryCornerShape(radius:8).fill(selected ? teal.opacity(0.12):dark ? .clear:PiyaliBrand.unitColor("fffaf1").opacity(0.38))
        }
        .overlay {
            EntryCornerShape(radius:8).stroke(selected ? teal:dark ? .white.opacity(0.08):paperInk.opacity(0.28),lineWidth:1)
        }
        .contentShape(EntryCornerShape(radius:8))
    }
}

private struct ReadingLoadingSkeleton:View {
    enum Kind {case passage,question}
    let status:String,kind:Kind
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started=Date()
    private var brand:PiyaliBrand {.init(dark:scheme == .dark)}
    private let teal=PiyaliBrand.unitColor("38b2ac")
    var body:some View {
        TimelineView(.animation(minimumInterval:1/20,paused:reduceMotion || phase != .active)) { clock in
            let elapsed=max(0,clock.date.timeIntervalSince(started))
            let pulse=reduceMotion || phase != .active ? 0:0.5-0.5*cos(.pi*elapsed/0.8)
            VStack(spacing:kind == .passage ? 16:12) {
                if kind == .passage {passage(pulse)}
                else {question(pulse)}
                HStack(spacing:8) {
                    OnboardingText(text:status,size:12,weight:.medium,lineHeight:18)
                        .foregroundStyle(brand.secondary)
                    HStack(spacing:6) {
                        ForEach(0..<3) { index in
                            let t=max(0,elapsed-Double(index)*0.14)
                            let strength=reduceMotion || phase != .active ? 0.5:0.5-0.5*cos(2 * .pi*t/0.9)
                            Circle().fill(teal).frame(width:6,height:6)
                                .opacity(0.28+0.72*strength).offset(y:-3*strength)
                        }
                    }.frame(minHeight:24)
                }.frame(maxWidth:.infinity).padding(.top,kind == .passage ? 8:4).opacity(0.75)
            }.padding(.vertical,4)
        }
        .accessibilityElement(children:.ignore)
        .accessibilityLabel(status)
        .accessibilityIdentifier(kind == .passage ? "readingPassageLoading":"readingQuestionLoading")
    }
    private func bar(width:CGFloat=1,height:CGFloat,radius:CGFloat,pulse:Double)->some View {
        GeometryReader { bounds in
            RoundedRectangle(cornerRadius:radius)
                .fill(PiyaliBrand.unitColor(brand.dark ? "182031":"efe4d5"))
                .overlay {RoundedRectangle(cornerRadius:radius).fill(brand.surface.opacity(pulse))}
                .frame(width:bounds.size.width*width)
                .frame(maxWidth:.infinity,alignment:.leading)
        }.frame(height:height)
    }
    private func passage(_ pulse:Double)->some View {
        VStack(spacing:16) {
            bar(width:0.6,height:28,radius:6,pulse:pulse)
            HStack(spacing:16) {
                ForEach([CGFloat(48),36],id:\.self) { width in
                    VStack(spacing:4) {
                        bar(height:32,radius:16,pulse:pulse).frame(width:32)
                        bar(height:10,radius:2,pulse:pulse).frame(width:width)
                    }
                }
            }.padding(.vertical,4).frame(maxWidth:.infinity)
            VStack(spacing:10) {
                ForEach(Array([0.96,0.90,0.72,0.94,0.86,0.58].enumerated()),id:\.offset) { index,width in
                    bar(width:width,height:16,radius:2,pulse:pulse).padding(.bottom,index == 2 ? 8:0)
                }
            }.modifier(ReadingPassageSurface(padding:16,opacity:0.12))
        }
    }
    private func question(_ pulse:Double)->some View {
        VStack(spacing:10) {
            bar(width:0.75,height:18,radius:6,pulse:pulse).padding(.bottom,6)
            ForEach(0..<3) { _ in bar(height:44,radius:8,pulse:pulse) }
        }.padding(17)
            .background(brand.surface,in:EntryCornerShape(radius:12))
            .overlay {EntryCornerShape(radius:12).stroke(brand.border,lineWidth:1)}
    }
}

private struct ReadingRetryButtonStyle:ButtonStyle {
    var size:CGFloat=16,height:CGFloat=40,horizontal:CGFloat=17
    var background="5dade2",edge="2f7cf7"
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(PiyaliBrand.productFont(size,600)).foregroundStyle(.white)
            .padding(.horizontal,horizontal).frame(minWidth:height,minHeight:height)
            .background{EntryCornerShape().fill(PiyaliBrand.unitColor(background))}
            .compositingGroup()
            .shadow(color:PiyaliBrand.unitColor(edge),radius:0,y:configuration.isPressed ? 2:4)
            .offset(y:configuration.isPressed ? 2:0).opacity(enabled ? 1:0.4)
            .frame(minHeight:44,alignment:.top).contentShape(Rectangle())
            .animation(reduceMotion ? nil:.easeOut(duration:0.12),value:configuration.isPressed)
    }
}

/// Native text flow preserves inline sentence boundaries while each link plays one sentence.
private struct ReadingSentenceText:UIViewRepresentable {
    let sentences:[String]
    let active:Int?
    let dark:Bool
    let onSelect:(Int)->Void
    func makeCoordinator()->Coordinator { Coordinator(onSelect:onSelect) }
    func makeUIView(context:Context)->UITextView {
        let view=UITextView();view.isEditable=false;view.isSelectable=false;view.isScrollEnabled=false;view.backgroundColor = .clear;view.textContainerInset = .zero;view.textContainer.lineFragmentPadding=0;view.setContentCompressionResistancePriority(.defaultLow,for:.horizontal)
        view.addGestureRecognizer(UITapGestureRecognizer(target:context.coordinator,action:#selector(Coordinator.tap(_:))))
        return view
    }
    func updateUIView(_ view:UITextView,context:Context) {
        context.coordinator.onSelect=onSelect
        let text=NSMutableAttributedString(string:""),colors:[UIColor]=[.init(red:56/255,green:178/255,blue:172/255,alpha:1),.init(red:128/255,green:90/255,blue:213/255,alpha:1),.init(red:237/255,green:137/255,blue:54/255,alpha:1),.init(red:99/255,green:179/255,blue:237/255,alpha:1),.init(red:246/255,green:173/255,blue:85/255,alpha:1)]
        let paragraph=NSMutableParagraphStyle();paragraph.lineSpacing=13;paragraph.baseWritingDirection=context.environment.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        for (index,sentence) in sentences.enumerated() {
            text.append(NSAttributedString(string:sentence,attributes:[.font:UIFont.systemFont(ofSize:16),.foregroundColor:dark ? UIColor(red:229/255,green:231/255,blue:235/255,alpha:1) : UIColor(red:47/255,green:38/255,blue:29/255,alpha:1),.backgroundColor:colors[index%colors.count].withAlphaComponent(active == index ? 0.35 : 0.12),NSAttributedString.Key("piyaliSentence"):index,.paragraphStyle:paragraph]))
            text.append(NSAttributedString(string:" ",attributes:[.font:UIFont.systemFont(ofSize:16),.paragraphStyle:paragraph]))
        }
        if !view.attributedText.isEqual(to:text) { view.attributedText=text }
        view.accessibilityIdentifier="readingPassage"
        view.isAccessibilityElement=true;view.accessibilityLabel=sentences.joined(separator:" ")
        view.accessibilityValue=active.flatMap {sentences.indices.contains($0) ? sentences[$0] : nil}
        view.accessibilityCustomActions=sentences.enumerated().map { index,sentence in UIAccessibilityCustomAction(name:sentence) { _ in context.coordinator.onSelect(index);return true } }
    }
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UITextView,context:Context)->CGSize? { guard let width=proposal.width else { return nil };return uiView.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude)) }
    final class Coordinator:NSObject {
        var onSelect:(Int)->Void
        init(onSelect:@escaping(Int)->Void) { self.onSelect=onSelect }
        @objc func tap(_ recognizer:UITapGestureRecognizer) {
            guard let view=recognizer.view as? UITextView,view.attributedText.length > 0 else{return}
            var point=recognizer.location(in:view);point.x -= view.textContainerInset.left;point.y -= view.textContainerInset.top
            let manager=view.layoutManager,glyph=manager.glyphIndex(for:point,in:view.textContainer)
            guard glyph < manager.numberOfGlyphs,manager.boundingRect(forGlyphRange:NSRange(location:glyph,length:1),in:view.textContainer).insetBy(dx:-2,dy:-4).contains(point) else{return}
            let character=manager.characterIndexForGlyph(at:glyph)
            guard character < view.attributedText.length,let index=view.attributedText.attribute(NSAttributedString.Key("piyaliSentence"),at:character,effectiveRange:nil) as? Int else{return}
            onSelect(index)
        }
    }
}
