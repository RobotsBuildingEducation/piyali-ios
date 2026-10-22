import SwiftUI

/// The source passage card, sentence audio, randomized review and action area.
struct ReadingView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @StateObject private var service=ReadingService()
    @StateObject private var speech=SpeechService()
    let lesson:Lesson?
    var onComplete:(()->Void)? = nil
    var embedded=false
    var startsFresh=false
    @State private var footerOwner=UUID()
    @State private var appeared=false
    @State private var refresh=0
    @State private var answer=""
    @State private var showTranslation=false
    @State private var activeSentence:Int?
    @State private var readingAll=false
    @FocusState private var answering:Bool
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var scope:String { [app.identity.npub,app.learner.target,app.learner.support,app.learner.level,lesson?.id ?? "free",String(refresh)].joined(separator:"|") }
    private var run:ReadingRun? { guard let run=app.learner.reading,run.support == app.learner.support,run.lessonID == lesson?.id else { return nil };return run }
    private func t(_ key:String)->String { EntryCopy.ui(app.learner.support,key) }
    var body:some View {
        Group { if ReadingService.fixture { activity } else { SubscriptionRequiredView(service:app.subscription) { activity } } }
            .activityFooter(owner:footerOwner,revision:footerRevision,access:app.subscription,fixtureAllowed:ReadingService.fixture,correct:run?.correct) { footer }
            .navigationTitle(embedded ? lesson?.title.localized(app.learner.support) ?? t("reading_title") : t("reading_title"))
            .task(id:scope) { stop();answer="";showTranslation=false;let fresh=refresh > 0 || startsFresh && !appeared;appeared=true;await service.prepare(app,lesson:lesson,fresh:fresh);answer=run?.answer ?? "" }
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button(t("proficiency_modal_done")) { answering=false }.accessibilityIdentifier("readingKeyboardDone") } }
            .onChange(of:phase) { _,value in if value != .active { stop();service.cancel() } else if run == nil { refresh += 1 } }
            .onDisappear { service.cancel();stop() }
    }
    private var activity:some View {
        VStack(spacing:0) {
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    Label(t("reading_title"),systemImage:"book").font(PiyaliBrand.productFont(16,600))
                    if let run {
                        VStack(alignment:.leading,spacing:18) {
                            Text(run.title).font(PiyaliBrand.productFont(19,700)).frame(maxWidth:.infinity,alignment:.leading)
                            HStack(spacing:30) {
                                audioTool(t("history_read_all"),symbol:"bolt.fill",id:"readingListen") { stop();readingAll=true;speech.speakSeries([run.text],language:run.target) { readingAll=false } }
                                audioTool(t("history_stop"),symbol:"stop.fill",id:"readingStop") { stop() }.disabled(!readingAll && activeSentence == nil)
                            }.frame(maxWidth:.infinity)
                            passage(run)
                            Divider().opacity(0.3)
                            if run.method == "question" { question(run) }
                            else { recording(run) }
                            VStack(alignment:.leading,spacing:7) {
                                Text(t("reading_takeaways_heading")).font(PiyaliBrand.productFont(14,600))
                                ForEach(Array(run.takeaways.enumerated()),id:\.offset) { _,value in Text("• "+value).font(PiyaliBrand.productFont(14)).frame(maxWidth:.infinity,alignment:.leading) }
                            }.padding(.top,24)
                        }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(brand.surface.opacity(0.68),in:RoundedRectangle(cornerRadius:16)).overlay { RoundedRectangle(cornerRadius:16).stroke(brand.border) }
                    } else if service.busy { ProgressView(t("reading_generating")).frame(maxWidth:.infinity,minHeight:280) }
                    if let error=service.error { Text(error).foregroundStyle(brand.questionError);Button(t("try_again")) { refresh += 1 }.disabled(service.busy) }
                    if let error=speech.error { Text(error).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.questionError) }
                }.padding(.horizontal,12).padding(.top,8).padding(.bottom,30).frame(maxWidth:640).frame(maxWidth:.infinity)
            }
            Color.clear.frame(height:app.activityFooterHeight)
        }.font(PiyaliBrand.productFont(16)).foregroundStyle(brand.text).background(brand.background)
    }
    private func audioTool(_ label:String,symbol:String,id:String,action:@escaping()->Void)->some View {
        Button(action:action) { VStack(spacing:6) { Image(systemName:symbol).font(.system(size:18)).frame(width:40,height:32);Text(label).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.muted) } }.buttonStyle(.plain).foregroundStyle(PiyaliBrand.teal).accessibilityIdentifier(id)
    }
    private func passage(_ run:ReadingRun)->some View {
        let sentences=Reading.displaySentences(run.text)
        return VStack(alignment:.leading,spacing:14) {
            if !showTranslation {
                ReadingSentenceText(sentences:sentences,active:activeSentence,dark:scheme == .dark,onSelect:{ index in stop();activeSentence=index;speech.speakSeries([sentences[index]],language:run.target) { activeSentence=nil } }).accessibilityIdentifier("readingPassage").environment(\.layoutDirection,run.target == "ar" ? .rightToLeft : .leftToRight)
            } else { VStack(alignment:.leading,spacing:12) {
                ForEach(Array(sentences.enumerated()),id:\.offset) { index,sentence in
                    VStack(alignment:.leading,spacing:7) {
                        Button { stop();activeSentence=index;speech.speakSeries([sentence],language:run.target) { activeSentence=nil } } label:{
                            Text(sentence).font(PiyaliBrand.productFont(16)).lineSpacing(6).multilineTextAlignment(.leading).padding(.horizontal,5).padding(.vertical,4).foregroundStyle(brand.text).background(sentenceColor(index).opacity(activeSentence == index ? 0.35 : 0.12),in:RoundedRectangle(cornerRadius:5)).overlay { RoundedRectangle(cornerRadius:5).stroke(sentenceColor(index).opacity(0.2)) }
                        }.buttonStyle(.plain).accessibilityIdentifier("readingSentence-\(index)")
                        if showTranslation,let lines=run.lineTranslations,lines.indices.contains(index) { Text(lines[index]).font(PiyaliBrand.productFont(14)).italic().foregroundStyle(brand.secondary).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("readingTranslation-\(index)").environment(\.layoutDirection,run.support == "ar" ? .rightToLeft : .leftToRight) }
                    }
                }
            }.environment(\.layoutDirection,run.target == "ar" ? .rightToLeft : .leftToRight) }
            if showTranslation,run.lineTranslations == nil,let translation=run.translation { Text(translation).font(PiyaliBrand.productFont(14)).italic().foregroundStyle(brand.secondary) }
            HStack { Spacer();Button {
                if showTranslation { showTranslation=false }
                else { showTranslation=true;Task { await service.translate(app,run:run) } }
            } label:{ HStack(spacing:6) { if service.busy { ProgressView().tint(.white) };Text(t(showTranslation ? "history_hide_translation" : run.translation == nil && run.lineTranslations == nil ? "history_translate" : "history_show_translation")) }.font(PiyaliBrand.productFont(13,600)).padding(.horizontal,12).padding(.vertical,10).foregroundStyle(.white).background(showTranslation ? Color(red:72/255,green:55/255,blue:156/255) : Color(red:64/255,green:103/255,blue:96/255),in:RoundedRectangle(cornerRadius:10)) }.buttonStyle(.plain).disabled(service.busy).accessibilityIdentifier("readingTranslate") }
        }.padding(12).background(PiyaliBrand.teal.opacity(0.15),in:RoundedRectangle(cornerRadius:12)).overlay(alignment:.leading) { UnevenRoundedRectangle(topLeadingRadius:3,bottomLeadingRadius:3).fill(PiyaliBrand.teal).frame(width:3) }
    }
    private func sentenceColor(_ index:Int)->Color { [PiyaliBrand.teal,Color(red:128/255,green:90/255,blue:213/255),Color(red:237/255,green:137/255,blue:54/255),Color(red:99/255,green:179/255,blue:237/255),Color(red:246/255,green:173/255,blue:85/255)][index%5] }
    @ViewBuilder private func question(_ run:ReadingRun)->some View {
        Text(run.question.question).font(PiyaliBrand.productFont(14)).lineSpacing(5).accessibilityIdentifier("readingQuestion")
        if run.question.type == "mc" {
            VStack(spacing:10) { ForEach(Array(run.question.options.enumerated()),id:\.offset) { index,option in
                let selected=answer == option || answer.isEmpty && run.answer == option
                Button { answer=option;update { $0.answer=option;$0.correct=nil;$0.feedback="" } } label:{ HStack(spacing:10) { Image(systemName:selected ? "checkmark.circle.fill" : "circle");Text(option).multilineTextAlignment(.leading);Spacer(minLength:0) }.font(PiyaliBrand.productFont(15,500)).padding(13).frame(maxWidth:.infinity,minHeight:48).foregroundStyle(selected ? brand.questionChoice : brand.text).background(selected ? brand.questionChoiceBackground : brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(selected ? brand.questionChoice : brand.border) } }.buttonStyle(.plain).disabled(service.busy || run.awarded).accessibilityIdentifier("readingOption-\(index)")
            } }
        } else {
            TextField(t(run.question.type == "fill" ? "history_fill_blank_placeholder" : "history_answer_placeholder"),text:Binding(get:{ answer },set:{ value in answer=value;update { $0.answer=value;$0.correct=nil;$0.feedback="" } }),axis:.vertical).font(PiyaliBrand.productFont(16)).padding(14).background(brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(brand.border) }.focused($answering).disabled(service.busy || run.awarded).accessibilityIdentifier("readingAnswer")
        }
    }
    @ViewBuilder private func recording(_ run:ReadingRun)->some View {
        if speech.recording { Image(systemName:"waveform.circle.fill").font(.system(size:64)).foregroundStyle(PiyaliBrand.teal).frame(maxWidth:.infinity);Text(t("history_speech_listening")).font(PiyaliBrand.productFont(12,600)).frame(maxWidth:.infinity) }
        if !speech.transcript.isEmpty { Text(speech.transcript).font(PiyaliBrand.productFont(13)).italic() }
    }
    private var footerRevision:String { [scope,run?.id.uuidString ?? "",String(run?.awarded ?? false),String(describing:run?.correct),run?.feedback ?? "",run?.explanation ?? "",answer,String(service.busy),service.error ?? "",String(speech.recording),speech.transcript].joined(separator:"|") }
    private var footer:some View {
        ActivityFooterSurface(hasFeedback:run?.feedback.isEmpty == false || run?.awarded == true,feedback:{
            if let run {
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
            else if service.error != nil { Button(t("try_again")) { refresh += 1 }.buttonStyle(ActivityPrimaryButtonStyle()).disabled(service.busy) }
            else { ProgressView().frame(maxWidth:.infinity,minHeight:40) }
        })
    }
    @ViewBuilder private func primary(_ run:ReadingRun)->some View {
        if run.awarded {
            Button(t("reading_btn_finish")) { stop();if let onComplete { onComplete();if !embedded { dismiss() } } else { refresh += 1 } }.buttonStyle(ActivityPrimaryButtonStyle(tone:"success")).accessibilityIdentifier("readingContinue")
        } else if run.method == "question" {
            Button { answering=false;stop();Task { await service.check(app,run:run,answer:answer.isEmpty ? run.answer : answer,speech:false) } } label:{ if service.busy { ProgressView().tint(.white) } else { Text(t("quiz_submit")) } }.buttonStyle(ActivityPrimaryButtonStyle()).disabled(service.busy || (answer.isEmpty && run.answer.isEmpty)).accessibilityIdentifier("readingCheck")
        } else {
            if !speech.transcript.isEmpty,!speech.recording { Button(t("history_speech_start_over")) { stop();speech.transcript="" }.font(PiyaliBrand.productFont(14,600)).disabled(service.busy) }
            Button {
                if speech.recording { speech.stop() }
                else if !speech.transcript.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { let words=speech.transcript;Task { await service.check(app,run:run,answer:words,speech:true) } }
                else { Task { await speech.start(language:run.target) } }
            } label:{ if service.busy { ProgressView().tint(.white) } else { Label(t(speech.recording ? "history_speech_stop_mic" : speech.transcript.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? "history_speech_start_mic" : "history_speech_submit"),systemImage:speech.recording ? "stop.fill" : "mic.fill") } }.buttonStyle(ActivityPrimaryButtonStyle(tone:speech.recording ? "stop" : speech.transcript.isEmpty ? "speak" : "primary")).disabled(service.busy).accessibilityIdentifier("readingMicrophone")
        }
    }
    private func stop() { speech.stopAll();readingAll=false;activeSentence=nil }
    private func update(_ action:(inout ReadingRun)->Void) { guard var current=app.learner.reading,current.id == run?.id else { return };action(&current);app.learner.saveReading(current);app.persist() }
}

/// Native text flow preserves inline sentence boundaries while each link plays one sentence.
private struct ReadingSentenceText:UIViewRepresentable {
    let sentences:[String]
    let active:Int?
    let dark:Bool
    let onSelect:(Int)->Void
    func makeCoordinator()->Coordinator { Coordinator(onSelect:onSelect) }
    func makeUIView(context:Context)->UITextView {
        let view=UITextView();view.isEditable=false;view.isScrollEnabled=false;view.backgroundColor = .clear;view.textContainerInset = .zero;view.textContainer.lineFragmentPadding=0;view.delegate=context.coordinator;view.linkTextAttributes=[:];view.setContentCompressionResistancePriority(.defaultLow,for:.horizontal);return view
    }
    func updateUIView(_ view:UITextView,context:Context) {
        context.coordinator.onSelect=onSelect
        let text=NSMutableAttributedString(string:""),colors:[UIColor]=[.init(red:56/255,green:178/255,blue:172/255,alpha:1),.init(red:128/255,green:90/255,blue:213/255,alpha:1),.init(red:237/255,green:137/255,blue:54/255,alpha:1),.init(red:99/255,green:179/255,blue:237/255,alpha:1),.init(red:246/255,green:173/255,blue:85/255,alpha:1)]
        let paragraph=NSMutableParagraphStyle();paragraph.lineSpacing=13;paragraph.baseWritingDirection=context.environment.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        for (index,sentence) in sentences.enumerated() {
            text.append(NSAttributedString(string:sentence,attributes:[.font:UIFont.systemFont(ofSize:16),.foregroundColor:dark ? UIColor(red:229/255,green:231/255,blue:235/255,alpha:1) : UIColor(red:47/255,green:38/255,blue:29/255,alpha:1),.backgroundColor:colors[index%colors.count].withAlphaComponent(active == index ? 0.35 : 0.12),.link:URL(string:"piyali-reading://sentence/\(index)")!,.paragraphStyle:paragraph]))
            text.append(NSAttributedString(string:" ",attributes:[.font:UIFont.systemFont(ofSize:16),.paragraphStyle:paragraph]))
        }
        if !view.attributedText.isEqual(to:text) { view.attributedText=text }
        view.accessibilityIdentifier="readingPassage"
    }
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UITextView,context:Context)->CGSize? { guard let width=proposal.width else { return nil };return uiView.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude)) }
    final class Coordinator:NSObject,UITextViewDelegate {
        var onSelect:(Int)->Void
        init(onSelect:@escaping(Int)->Void) { self.onSelect=onSelect }
        func textView(_ textView:UITextView,shouldInteractWith url:URL,in characterRange:NSRange,interaction:UITextItemInteraction)->Bool { if url.scheme == "piyali-reading",let index=Int(url.lastPathComponent) { onSelect(index) };return false }
    }
}
