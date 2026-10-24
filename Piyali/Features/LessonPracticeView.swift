import SwiftUI

struct LessonPracticeView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var service:PracticeService
    @StateObject private var speech=SpeechService()
    let module:PracticeRecipeModule
    let lesson:Lesson?
    var onNext:(()->Void)?=nil
    var startsFresh=false
    var embedded=false
    init(module:PracticeRecipeModule,lesson:Lesson?,onNext:(()->Void)?=nil,startsFresh:Bool=false,embedded:Bool=false,service:PracticeService?=nil) {
        self.module=module;self.lesson=lesson;self.onNext=onNext;self.startsFresh=startsFresh;self.embedded=embedded;_service=StateObject(wrappedValue:service ?? PracticeService())
    }
    private var quiz:Bool { lesson?.isFinalQuiz == true }
    @State private var showTranscript=false
    @State private var noteSaved=false
    @State private var showDeck=false
    @State private var active=false
    @State private var appeared=false
    @FocusState private var answering:Bool
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private var key:String { PracticeRun.key(target:app.learner.target,lesson:lesson?.id,module:module) }
    private var scope:String { app.identity.npub+":"+key+":"+app.learner.support }
    private var run:PracticeRun? { guard let run=app.learner.practiceRuns?[key],run.question.support == app.learner.support else { return nil };return run }
    private func copy(_ key:String)->String { EntryCopy.ui(app.learner.support,key) }
    private func questionCopy(_ run:PracticeRun,_ key:String,fallback:String="")->String {
        let flashcard=run.question.kind == "flashcard"
        let sourceKey=flashcard ? ["inputPlaceholder":"type_placeholder","nextQuestion":"next"][key] ?? key : key
        return PracticeCopy.text(variant:flashcard ? "flashcard" : run.question.variant,language:run.question.support,key:sourceKey,fallback:fallback)
    }
    var body:some View {
        SubscriptionRequiredView(service:app.subscription,preserveEarnedWork:app.preserveEarnedGoalLesson(lesson)) {
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    if let run {
                        question(run)
                        controls(run).disabled(service.busy || run.correct == true || quiz && run.correct != nil)
                        tools(run)
                        if let correct=run.correct {
                            Text(quiz ? copy(correct ? "correct" : "try_again") : copy(module == .grammar ? (correct ? "grammar_result_correct" : "grammar_result_try_again") : (correct ? "vocab_result_correct" : "vocab_result_try_again")).replacingOccurrences(of:"{xp}",with:String(run.earnedXP))).font(PiyaliBrand.productFont(17,600)).foregroundStyle(correct ? brand.questionSuccess : brand.questionError).accessibilityIdentifier("practiceVerdict")
                            if !run.explanation.isEmpty { Text(run.explanation).font(PiyaliBrand.productFont(15)).textSelection(.enabled) }
                            if correct || quiz {
                                Button(questionCopy(run,"nextQuestion",fallback:copy("grammar_next"))) { speech.stopAll();showTranscript=false;noteSaved=false;if let onNext { onNext() } else { Task { await service.prepare(app,module:module,lesson:lesson,fresh:true) } } }.buttonStyle(QuestionPrimaryButtonStyle()).disabled(service.busy).accessibilityIdentifier("nextTypedQuestion")
                            }
                        }
                        if run.correct == nil || !quiz && run.correct != true {
                            Button(questionCopy(run,"submit",fallback:copy(module == .grammar ? "grammar_submit" : "vocab_submit"))) { answering=false;speech.stop();Task { await service.check(app,run:run,confidence:speech.confidence,audio:speech.audioMetrics) } }.buttonStyle(QuestionPrimaryButtonStyle()).disabled(service.busy || !service.ready(run)).accessibilityIdentifier("checkTypedAnswer")
                        }
                    } else if !service.busy { Button("Start practice") { Task { await service.prepare(app,module:module,lesson:lesson) } }.buttonStyle(BrandButtonStyle()) }
                    if service.busy { ProgressView().frame(maxWidth:.infinity).accessibilityIdentifier("typedPracticeBusy") }
                    if let error=service.error { Text(error).foregroundStyle(.red);Button("Try again") { Task { if run == nil { await service.prepare(app,module:module,lesson:lesson,fresh:true) } else if let run { await service.check(app,run:run) } } }.disabled(service.busy) }
                    if let error=speech.error { Text(error).font(PiyaliBrand.productFont(13)).foregroundStyle(.red) }
                    if let onNext,!quiz { Button(PracticeCopy.text(variant:"flashcard",language:app.learner.support,key:"skip")) { speech.stopAll();onNext() }.font(PiyaliBrand.productFont(14,600)).foregroundStyle(brand.secondary).accessibilityIdentifier("skipLessonActivity") }
                }.padding(24).frame(maxWidth:640).frame(maxWidth:.infinity,alignment:.center)
            }.background(brand.background).foregroundStyle(brand.text)
        }.navigationTitle(embedded ? lesson?.title.localized(app.learner.support) ?? "" : module == .grammar ? "Grammar" : "Vocabulary")
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { answering=false }.accessibilityIdentifier("practiceKeyboardDone") } }
            .sheet(isPresented:$showDeck) { PracticeDeckView(cards:app.learner.practiceDecks?[app.learner.practiceDeckKey(module)] ?? [],support:app.learner.support) }
            .task(id:scope) { speech.stopAll();showDeck=false;let fresh=startsFresh && !appeared;appeared=true;await service.prepare(app,module:module,lesson:lesson,fresh:fresh) }
            .onAppear { active=true }
            .onChange(of:speech.transcript) { _,text in if active { updateResponse("text",.string(text)) } }
            .onChange(of:speech.recording) { wasRecording,recording in
                if active,scenePhase == .active,wasRecording,!recording,let run,["speak","flashcard"].contains(run.question.kind),!speech.transcript.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty {
                    updateResponse("text",.string(speech.transcript))
                    if let current=self.run { Task { await service.check(app,run:current,confidence:speech.confidence,audio:speech.audioMetrics) } }
                }
            }
            .onChange(of:scenePhase) { _,phase in if phase != .active { service.cancel();speech.stopAll() } }
            .onDisappear { active=false;service.cancel();speech.stopAll() }
    }
    @ViewBuilder private func question(_ run:PracticeRun)->some View {
        let q=run.question,p=q.payload
        VStack(alignment:.leading,spacing:16) {
            if q.isDelight {
                Text(questionCopy(run,"title")).font(PiyaliBrand.productFont(20,800))
                Text(questionCopy(run,"instruction",fallback:questionCopy(run,"description",fallback:p["instruction"].string))).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary)
            } else if ["fill","mc","ma","match","speak"].contains(q.kind) {
                Text(copy((module == .grammar ? "grammar_btn_" : "vocab_btn_")+q.kind)).font(PiyaliBrand.productFont(20,700))
            }
            if q.kind == "flashcard" {
                flashcard(run)
            } else if q.kind == "repeat",q.options["isListening"].boolean {
                Button { speech.speak(q.audioText,language:q.audioLanguage) } label:{ Image(systemName:"speaker.wave.2.fill").font(.system(size:30)).frame(maxWidth:.infinity,minHeight:100) }.buttonStyle(.plain).foregroundStyle(PiyaliBrand.teal).accessibilityLabel(copy("vocab_listen_question"))
                if showTranscript { Text(q.audioText).font(PiyaliBrand.productFont(24,500)) }
            } else if q.kind == "speak" {
                Text(p["prompt"].string).font(PiyaliBrand.productFont(16))
                Text(p["display"].string.isEmpty ? p["target"].string : p["display"].string).font(PiyaliBrand.productFont(26,500))
            } else if !q.isDelight { Text(q.questionText).font(PiyaliBrand.productFont(18,700)).textSelection(.enabled) }
            else { delightPrompt(run) }
            if !p["translation"].string.isEmpty { Text(p["translation"].string).font(PiyaliBrand.productFont(15)).foregroundStyle(brand.secondary) }
        }.frame(maxWidth:.infinity,alignment:.leading).padding(22).background(brand.surface,in:RoundedRectangle(cornerRadius:24)).overlay { RoundedRectangle(cornerRadius:24).stroke(brand.border) }.accessibilityElement(children:.contain).accessibilityIdentifier("typedQuestionPrompt")
    }
    private func flashcard(_ run:PracticeRun)->some View {
        let flipped=run.showAnswer == true
        return VStack(alignment:.leading,spacing:14) {
            Button {
                guard var current=self.run else { return };withAnimation(.easeInOut(duration:0.2)) { current.showAnswer = !(current.showAnswer ?? false);app.learner.savePractice(current) };app.persist()
            } label:{
                VStack(alignment:.leading,spacing:12) {
                    Text(flipped ? questionCopy(run,"answer_label") : questionCopy(run,"translate_to").replacingOccurrences(of:"{language}",with:copy("language_"+run.question.target))).font(PiyaliBrand.productFont(12,500)).foregroundStyle(brand.secondary)
                    Text(flipped ? run.question.payload["answer"].string : run.question.payload["concept"].string).font(PiyaliBrand.productFont(24,800)).foregroundStyle(brand.text)
                    Text(questionCopy(run,flipped ? "tap_to_flip" : "show_answer")).font(PiyaliBrand.productFont(12,600)).foregroundStyle(brand.questionTool)
                }.frame(maxWidth:.infinity,minHeight:140,alignment:.leading).padding(18).background(brand.questionChipBackground,in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) }
            }.buttonStyle(.plain).disabled(service.busy).accessibilityIdentifier("flipLessonFlashcard")
            if flipped { Button { speech.speak(run.question.payload["answer"].string,language:run.question.target) } label:{ Label(questionCopy(run,"listen"),systemImage:"speaker.wave.2.fill") }.foregroundStyle(brand.questionTool).accessibilityIdentifier("listenLessonFlashcard") }
            HStack {
                let collected=(app.learner.practiceDecks?[app.learner.practiceDeckKey(module)] ?? []).contains { $0.id == run.question.id }
                Button(questionCopy(run,collected ? "collected" : "collect")) { app.learner.collectPracticeCard(run);app.persist() }.disabled(collected).accessibilityIdentifier("collectLessonFlashcard")
                Spacer()
                Button(questionCopy(run,"deck_label")+" (\((app.learner.practiceDecks?[app.learner.practiceDeckKey(module)] ?? []).count))") { speech.stopAll();showDeck=true }.accessibilityIdentifier("openLessonFlashcardDeck")
            }.font(PiyaliBrand.productFont(14,600)).foregroundStyle(brand.questionTool)
        }
    }
    @ViewBuilder private func controls(_ run:PracticeRun)->some View {
        let q=run.question
        if q.isDelight { delightControls(run) }
        else {
            switch q.kind {
            case "mc":choices(run.bank,selected:run.response["indices"].array.map { Int($0.number) }) { i in updateResponse("indices",.array([.number(Double(i))])) }
            case "ma":wordBank(run,field:"indices",words:run.bank)
            case "translate","repeat":wordBank(run,field:"indices",words:run.bank)
            case "match":matching(run)
            default:answerField(run)
            }
        }
    }
    private func answerField(_ run:PracticeRun)->some View {
        VStack(alignment:.leading,spacing:14) {
            TextField(questionCopy(run,"inputPlaceholder",fallback:questionCopy(run,"placeholder",fallback:copy("grammar_input_placeholder_answer"))),text:Binding(get:{ run.response["text"].string },set:{ updateResponse("text",.string($0)) }),axis:.vertical).font(PiyaliBrand.productFont(18)).padding(18).frame(minHeight:72,alignment:.topLeading).background(brand.surface,in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(brand.border) }.textInputAutocapitalization(.sentences).autocorrectionDisabled().focused($answering).accessibilityIdentifier("typedPracticeAnswer")
            Button { if speech.recording { speech.stop() } else { Task { await speech.start(language:run.question.answerLanguage) } } } label:{ Label(copy(speech.recording ? "vocab_speak_stop" : "vocab_speak_record"),systemImage:speech.recording ? "stop.circle.fill" : "mic.fill") }.buttonStyle(.bordered).tint(PiyaliBrand.teal).accessibilityIdentifier("typedPracticeMicrophone")
        }
    }
    private func choices(_ words:[String],selected:[Int],action:@escaping(Int)->Void)->some View {
        VStack(spacing:12) { ForEach(Array(words.enumerated()),id:\.offset) { index,text in
            Button { action(index) } label:{ HStack(spacing:14) { Image(systemName:selected.contains(index) ? "checkmark.circle.fill" : "circle").foregroundStyle(selected.contains(index) ? brand.questionChoice : brand.muted);Text(text).multilineTextAlignment(.leading);Spacer() }.font(PiyaliBrand.productFont(18,500)).padding(18).frame(maxWidth:.infinity,minHeight:62).background(selected.contains(index) ? brand.questionChoiceBackground : brand.surface,in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(selected.contains(index) ? brand.questionChoice : brand.border,lineWidth:2) } }.buttonStyle(.plain).accessibilityIdentifier("typedChoice-"+String(index)).accessibilityAddTraits(selected.contains(index) ? .isSelected : [])
        } }
    }
    private func wordBank(_ run:PracticeRun,field:String,words:[String])->some View {
        let chosen=run.response[field].array.map { Int($0.number) }
        return VStack(alignment:.leading,spacing:18) {
            PracticeFlowLayout(spacing:8) {
                ForEach(Array(chosen.enumerated()),id:\.offset) { position,index in
                    if words.indices.contains(index) { chip(words[index],selected:true) { var next=chosen;next.remove(at:position);updateResponse(field,.array(next.map { .number(Double($0)) })) }.accessibilityIdentifier("typedSelected-"+String(position)) }
                }
                if chosen.isEmpty { Text("…").font(PiyaliBrand.productFont(22)).frame(minWidth:50,minHeight:40).foregroundStyle(brand.muted) }
            }.frame(minHeight:70,alignment:.leading).frame(maxWidth:.infinity,alignment:.leading).padding(14).background(brand.surface,in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(brand.border,style:StrokeStyle(lineWidth:1,dash:[5])) }
            PracticeFlowLayout(spacing:8) { ForEach(Array(words.enumerated()),id:\.offset) { index,text in
                chip(text,selected:false) { updateResponse(field,.array((chosen+[index]).map { .number(Double($0)) })) }.opacity(chosen.contains(index) ? 0.3 : 1).disabled(chosen.contains(index)).accessibilityIdentifier("typedWord-"+String(index))
            } }
        }
    }
    private func chip(_ text:String,selected:Bool,action:@escaping()->Void)->some View {
        Button(action:action) { Text(text).font(PiyaliBrand.productFont(17,500)).padding(.horizontal,15).padding(.vertical,12).background(selected ? brand.questionChipBackground : brand.surface,in:RoundedRectangle(cornerRadius:14)).overlay { RoundedRectangle(cornerRadius:14).stroke(selected ? brand.questionChip : brand.border,lineWidth:1.5) } }.buttonStyle(.plain)
    }
    private func matching(_ run:PracticeRun)->some View {
        VStack(spacing:14) { ForEach(Array(run.question.strings("left").enumerated()),id:\.offset) { index,left in
            HStack { Text(left).font(PiyaliBrand.productFont(18,500)).frame(maxWidth:.infinity,alignment:.leading)
                Picker("Match "+left,selection:Binding(get:{ run.response["pairs"][String(index)] == .null ? -1 : Int(run.response["pairs"][String(index)].number) },set:{ value in
                    var pairs=run.response["pairs"].object;pairs=pairs.filter { Int($0.value.number) != value };if value >= 0 { pairs[String(index)] = .number(Double(value)) };updateResponse("pairs",.object(pairs))
                })) { Text("…").tag(-1);ForEach(run.rightOrder ?? Array(run.question.strings("right").indices),id:\.self) { i in Text(run.question.strings("right")[i]).tag(i) } }.pickerStyle(.menu).tint(PiyaliBrand.teal).accessibilityIdentifier("typedMatch-"+String(index))
            }.padding(16).background(brand.surface,in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(brand.border) }
        } }
    }
    @ViewBuilder private func delightPrompt(_ run:PracticeRun)->some View {
        let q=run.question,p=q.payload
        switch q.variant {
        case "dialogue_fork":Text(p["speaker"].string).font(PiyaliBrand.productFont(13,600)).foregroundStyle(brand.secondary);Text(p["line"].string).font(PiyaliBrand.productFont(24,500))
        case "sentence_shapeshifter":Text(p["source"].string).font(PiyaliBrand.productFont(24,500));Text(p["constraint"].string).font(PiyaliBrand.productFont(16,600)).foregroundStyle(PiyaliBrand.teal)
        case "morphology_forge","natural_or_weird":Text(p["sentence"].string).font(PiyaliBrand.productFont(24,500))
        case "three_word_challenge":PracticeFlowLayout(spacing:8) { ForEach(q.strings("cues"),id:\.self) { Text($0).font(PiyaliBrand.productFont(20,600)).padding(10).background(PiyaliBrand.teal.opacity(0.1),in:RoundedRectangle(cornerRadius:12)) } }
        case "three_clue_mystery":ForEach(Array(q.strings("clues").prefix(run.revealedClues).enumerated()),id:\.offset) { index,clue in Text("\(index+1). "+clue).font(PiyaliBrand.productFont(18)) }
        case "listen_difference":Button { speech.speak(q.audioText,language:q.target) } label:{ Image(systemName:"speaker.wave.2.fill").font(.system(size:30)).frame(maxWidth:.infinity,minHeight:90) }.buttonStyle(.plain).foregroundStyle(PiyaliBrand.teal).accessibilityLabel(copy("vocab_listen_question"))
        default:EmptyView()
        }
    }
    @ViewBuilder private func delightControls(_ run:PracticeRun)->some View {
        let q=run.question,p=q.payload,r=run.response
        switch q.variant {
        case "sentence_detective":
            PracticeFlowLayout(spacing:8) { ForEach(Array(q.strings("tokens").enumerated()),id:\.offset) { index,word in
                chip(word,selected:r["tokenIndex"] == .number(Double(index))) {
                    if index == Int(p["incorrectIndex"].number) { updateResponse(.object(["tokenIndex":.number(Double(index)),"replacement":.string(""),"rejectedTokenIndices":.array([])])) }
                    else { let rejected=Array(Set(r["rejectedTokenIndices"].array.map { Int($0.number) }+[index])).sorted();updateResponse(.object(["tokenIndex":.null,"replacement":.string(""),"rejectedTokenIndices":.array(rejected.map { .number(Double($0)) })])) }
                }.foregroundStyle(r["rejectedTokenIndices"].array.contains(.number(Double(index))) ? .orange : brand.text)
            } }
            if r["tokenIndex"] != .null { choices(q.strings("replacements"),selected:q.strings("replacements").indices.filter { q.strings("replacements")[$0] == r["replacement"].string }) { updateResponse("replacement",.string(q.strings("replacements")[$0])) } }
        case "dialogue_fork","listen_difference":choices(q.strings("options"),selected:r["selectedIndex"] == .null ? [] : [Int(r["selectedIndex"].number)]) { updateResponse("selectedIndex",.number(Double($0))) }
        case "morphology_forge":wordBank(run,field:"pieceIndices",words:q.strings("pieces"))
        case "word_neighborhoods":
            let groups=p["groups"].array,words=groups.flatMap { $0["items"].array.map(\.string) }.sorted()
            ForEach(words,id:\.self) { word in
                HStack { Text(word).font(PiyaliBrand.productFont(18,500));Spacer();Picker(word,selection:Binding(get:{ r["assignments"][word] == .null ? -1 : Int(r["assignments"][word].number) },set:{ index in var assignments=r["assignments"].object;if index < 0 { assignments.removeValue(forKey:word) } else { assignments[word] = .number(Double(index)) };updateResponse("assignments",.object(assignments)) })) { Text("…").tag(-1);ForEach(Array(groups.enumerated()),id:\.offset) { index,group in Text(group["label"].string).tag(index) } }.tint(PiyaliBrand.teal) }.padding(16).background(brand.surface,in:RoundedRectangle(cornerRadius:18))
            }
        case "natural_or_weird":choices([questionCopy(run,"soundsWeird"),questionCopy(run,"soundsNatural")],selected:r["choice"] == .null ? [] : [r["choice"].boolean ? 1 : 0]) { updateResponse("choice",.bool($0 == 1)) }
        case "three_clue_mystery":
            if run.revealedClues < q.strings("clues").count { Button(questionCopy(run,"revealNext")) { guard var current=self.run else { return };current.revealedClues += 1;current.assisted=true;app.learner.savePractice(current);app.persist() }.buttonStyle(.bordered).tint(brand.questionChoice) }
            answerField(run)
        default:answerField(run)
        }
    }
    private func tools(_ run:PracticeRun)->some View {
        VStack(alignment:.leading,spacing:14) {
            HStack(spacing:20) {
                if !run.question.audioText.isEmpty { Button { speech.speak(run.question.audioText,language:run.question.audioLanguage) } label:{ Image(systemName:"speaker.wave.2") }.accessibilityLabel(copy("vocab_listen_question")) }
                if !quiz { Button { Task { await service.explain(app,run:run) } } label:{ Label(questionCopy(run,"askForHelp",fallback:copy("vocab_ask_assistant")),systemImage:"sparkles") }.disabled(service.busy) }
                Spacer()
                if !quiz || run.correct != nil { Button { app.learner.notes.insert(Note(title:run.question.questionText,body:[run.answerText,run.expected,run.explanation].filter { !$0.isEmpty }.joined(separator:"\n\n")),at:0);app.persist();noteSaved=true } label:{ Image(systemName:noteSaved ? "checkmark" : "note.text.badge.plus") }.disabled(noteSaved).accessibilityLabel(copy(noteSaved ? "vocab_note_saved" : "vocab_create_note")) }
            }.font(PiyaliBrand.productFont(14,500)).foregroundStyle(brand.questionTool)
            if run.question.kind == "repeat",run.question.options["isListening"].boolean { Button(showTranscript ? "Hide transcript" : "Show transcript") { showTranscript.toggle() }.font(PiyaliBrand.productFont(13)).foregroundStyle(brand.secondary) }
            if run.correct == nil,!run.explanation.isEmpty { Text(run.explanation).font(PiyaliBrand.productFont(15)) }
        }
    }
    private func updateResponse(_ field:String,_ value:JSONValue) { guard let run else { return };updateResponse(run.response.setting(field,value)) }
    private func updateResponse(_ response:JSONValue) { guard var run,run.correct != true,(!quiz || run.correct == nil),!service.busy else { return };run.response=response;run.correct=nil;app.learner.savePractice(run);app.persist() }
}

struct PracticeFlowLayout:Layout {
    var spacing:CGFloat=8
    func sizeThatFits(proposal:ProposedViewSize,subviews:Subviews,cache:inout())->CGSize { arrange(width:proposal.width ?? 320,subviews:subviews).size }
    func placeSubviews(in bounds:CGRect,proposal:ProposedViewSize,subviews:Subviews,cache:inout()) {
        let result=arrange(width:bounds.width,subviews:subviews)
        for (index,point) in result.points.enumerated() { subviews[index].place(at:CGPoint(x:bounds.minX+point.x,y:bounds.minY+point.y),proposal:ProposedViewSize(subviews[index].sizeThatFits(.unspecified))) }
    }
    private func arrange(width:CGFloat,subviews:Subviews)->(size:CGSize,points:[CGPoint]) {
        var x:CGFloat=0,y:CGFloat=0,rowHeight:CGFloat=0,points:[CGPoint]=[]
        for view in subviews { let size=view.sizeThatFits(.unspecified);if x > 0,x+size.width > width { x=0;y += rowHeight+spacing;rowHeight=0 };points.append(CGPoint(x:x,y:y));x += size.width+spacing;rowHeight=max(rowHeight,size.height) }
        return(CGSize(width:width,height:y+rowHeight),points)
    }
}
