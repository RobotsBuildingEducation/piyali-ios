import SwiftUI

struct LessonPracticeView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var service:PracticeService
    @StateObject private var speech=SpeechService()
    @StateObject private var assistance:PracticeAssistanceController
    @StateObject private var oral:LessonSpeechController
    @StateObject private var writing:WritingSpeechController
    @State private var footerOwner=UUID()
    @State private var portrait=PracticeQuestionAppearance.portrait
    let module:PracticeRecipeModule
    let lesson:Lesson?
    var onNext:(()->Void)?=nil
    var startsFresh=false
    var embedded=false
    var allowsQuestionAutoFocus=true
    var writingKeyboardInitiallyOpen=false
    init(module:PracticeRecipeModule,lesson:Lesson?,onNext:(()->Void)?=nil,startsFresh:Bool=false,embedded:Bool=false,service:PracticeService?=nil,assistance:PracticeAssistanceController?=nil,feedbackPortrait:Int?=nil,writing:WritingSpeechController?=nil,oral:LessonSpeechController?=nil,allowsQuestionAutoFocus:Bool=true,writingKeyboardInitiallyOpen:Bool=false) {
        self.module=module;self.lesson=lesson;self.onNext=onNext;self.startsFresh=startsFresh;self.embedded=embedded;self.allowsQuestionAutoFocus=allowsQuestionAutoFocus;self.writingKeyboardInitiallyOpen=writingKeyboardInitiallyOpen;_writing=StateObject(wrappedValue:writing ?? WritingSpeechController());_oral=StateObject(wrappedValue:oral ?? LessonSpeechController());_service=StateObject(wrappedValue:service ?? PracticeService());_assistance=StateObject(wrappedValue:assistance ?? PracticeAssistanceController());_portrait=State(initialValue:feedbackPortrait ?? PracticeQuestionAppearance.portrait)
    }
    private var quiz:Bool { lesson?.isFinalQuiz == true }
    @State private var showStandardKeyboard=false
    @State private var questionAudioPlaying=false
    @State private var noteSaved=false
    @State private var noteCreating=false
    @State private var showDeck=false
    @State private var deckOwner:String?
    @State private var preparationTask:Task<Void,Never>?
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
            VStack(spacing:0) {
                ScrollView {
                    VStack(alignment:.leading,spacing:16) {
                        if service.preparingKind == "flashcard",service.preparing || service.preparationFailed {LessonFlashcardPreparation(loading:service.preparing,deckCount:(app.learner.practiceDecks?[app.learner.practiceDeckKey(module)] ?? []).count,support:app.learner.support,openDeck:openDeck)}
                        else if service.preparing {ProgressView().frame(maxWidth:.infinity,minHeight:240).accessibilityIdentifier("typedPracticeBusy")}
                        else if !service.preparationFailed,let run {
                            if run.question.variant == "natural_or_weird" {
                                NaturalOrWeirdQuestion(sentence:run.question.payload["sentence"].string,title:questionCopy(run,"title"),instruction:questionCopy(run,"instruction"),weird:questionCopy(run,"soundsWeird"),natural:questionCopy(run,"soundsNatural"),audioLabel:questionCopy(run,"playAudio"),helpLabel:questionCopy(run,"askForHelp"),selected:run.response["choice"] == .null ? nil:run.response["choice"].boolean,locked:service.busy || run.correct == true || quiz && run.correct != nil,assistantOpen:assistance.assistantOpen,assistantBusy:assistance.assistantBusy,help:{assistance.ask(app,run:run)},listen:{speech.speak(run.question.audioText,language:run.question.audioLanguage)},select:{updateResponse("choice",.bool($0))},showHelp:!quiz)
                            } else if WritingPracticeQuestion.variants.contains(run.question.variant) {
                                writingQuestion(run)
                            } else if AdvancedPracticeQuestion.variants.contains(run.question.variant) {
                                advancedQuestion(run)
                            } else if StandardPracticeQuestion.variants.contains(run.question.kind) {
                                standardQuestion(run)
                            } else if WordBankPracticeQuestion.variants.contains(run.question.kind) {
                                wordBankQuestion(run)
                            } else if run.question.kind == "speak" {
                                SpokenPracticeQuestion(question:run.question,assistantOpen:assistance.assistantOpen,assistantBusy:assistance.assistantBusy,playing:questionAudioPlaying,help:{assistance.ask(app,run:run)},listen:{playOralAudio(run,answer:false)})
                            } else if run.question.kind == "flashcard" {
                                lessonFlashcard(run)
                            }
                        }
                        if let error=service.error {Text(error).foregroundStyle(brand.questionError);Button(copy("try_again")){Task{if let run,!service.preparing,!service.preparationFailed{await service.check(app,run:run)}else{startPreparation(fresh:true)}}}.disabled(service.busy)}
                        if let error=oral.recorder.error {Text(oralError(error)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.questionError).accessibilityIdentifier("lessonSpeechError");if error == "mic-denied"{Link(copy("settings"),destination:URL(string:UIApplication.openSettingsURLString)!).accessibilityIdentifier("lessonSpeechSettings")}}
                        if let error=speech.error {Text(error).font(PiyaliBrand.productFont(13)).foregroundStyle(brand.questionError)}
                    }.padding(.horizontal,8).padding(.top,22).padding(.bottom,24).frame(maxWidth:720).frame(maxWidth:.infinity)
                }
                Color.clear.frame(height:app.activityFooterHeight)
            }.background(brand.background).foregroundStyle(brand.text)
        }.overlay(alignment:.top){if !assistance.clipboardNotice.isEmpty{PracticeCopyNotice(text:assistance.clipboardNotice,closeLabel:copy("app_close"),dismiss:assistance.dismissClipboardNotice).padding(.top,8)}}.activityFooter(owner:footerOwner,revision:footerRevision,access:app.subscription,enabled:!(service.preparingKind == "flashcard" && (service.preparing || service.preparationFailed)),correct:assistance.assistantOpen || service.busy || service.preparationFailed ? nil:run?.correct,tone:assistance.assistantOpen ? "assistant":nil){questionFooter}
            .navigationTitle(embedded ? lesson?.title.localized(app.learner.support) ?? "" : module == .grammar ? "Grammar" : "Vocabulary")
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { answering=false }.accessibilityIdentifier("practiceKeyboardDone") } }
            .fullScreenCover(isPresented:$showDeck) { PracticeDeckView(cards:app.learner.practiceDecks?[app.learner.practiceDeckKey(module)] ?? [],support:app.learner.support,target:app.learner.target).presentationBackground(.clear) }
            .task(id:scope) { if deckOwner == scope{deckOwner=nil;return};deckOwner=nil;questionAudioPlaying=false;answering=false;showStandardKeyboard=false;writing.clear();oral.clear();speech.stopAll();assistance.clear();showDeck=false;appeared=true;startPreparation(fresh:startsFresh);await preparationTask?.value }
            .onChange(of:run?.question.id){_,_ in questionAudioPlaying=false;noteSaved=false;noteCreating=false;portrait=PracticeQuestionAppearance.portrait;if let run {assistance.bind(app,run:run);writing.bind(app,run:run);oral.bind(app,run:run)}}
            .onChange(of:run?.response){_,_ in if let run,!WordBankPracticeQuestion.variants.contains(run.question.kind),!StandardPracticeQuestion.variants.contains(run.question.kind){assistance.responseChanged()}}
            .onAppear { active=true }
            .onChange(of:scenePhase) { _,phase in if phase != .active { preparationTask?.cancel();preparationTask=nil;questionAudioPlaying=false;writing.clear();oral.clear();service.cancel();assistance.cancel();speech.stopAll() } }
            .onDisappear {active=false;questionAudioPlaying=false;if showDeck{oral.recorder.cancel();speech.stopAll()}else{preparationTask?.cancel();preparationTask=nil;writing.clear();oral.clear();service.cancel();assistance.cancel();speech.stopAll()}}
    }
    private func wordBankQuestion(_ run:PracticeRun)->some View {
        let capturedScope=scope
        return WordBankPracticeQuestion(run:run,locked:service.busy || run.correct == true || quiz && run.correct != nil,assistantOpen:assistance.assistantOpen,assistantBusy:assistance.assistantBusy,playing:questionAudioPlaying,help:{assistance.ask(app,run:run)},listen:{let id=run.question.id;speech.speakSeries([run.question.audioText],language:run.question.audioLanguage,onStarted:{if self.run?.question.id == id{questionAudioPlaying=true}},onInterrupted:{questionAudioPlaying=false},onFinished:{questionAudioPlaying=false})},change:{response in
            guard scope == capturedScope,var current=self.run,current.question.id == run.question.id,current.correct != true,(!quiz || current.correct == nil),!service.busy else{return};current.response=response;app.learner.savePractice(current);app.persist()
        }).id(run.question.id)
    }
    private func standardQuestion(_ run:PracticeRun)->some View {
        let capturedScope=scope
        return StandardPracticeQuestion(run:run,locked:service.busy || run.correct == true || quiz && run.correct != nil,assistantOpen:assistance.assistantOpen,assistantBusy:assistance.assistantBusy,playing:questionAudioPlaying,help:{assistance.ask(app,run:run)},listen:{text,index in
            let id=run.question.id;speech.speakSeries([text],language:run.question.target,onStarted:{if self.run?.question.id == id{questionAudioPlaying=true}},onInterrupted:{questionAudioPlaying=false},onFinished:{questionAudioPlaying=false})
        },change:{response in guard scope == capturedScope,self.run?.question.id == run.question.id else{return};updateStandardResponse(response)},keyboardOpen:$showStandardKeyboard,focus:$answering).id(run.question.id)
    }
    private func writingQuestion(_ run:PracticeRun)->some View {
        let capturedScope=scope
        return WritingPracticeQuestion(question:run.question,text:Binding(get:{self.run?.response["text"].string ?? ""},set:{text in guard scope == capturedScope,self.run?.question.id == run.question.id,let current=self.run else{return};updateResponse(WritingExerciseRules.response(current.response,text:text,variant:run.question.variant))}),locked:service.busy || run.correct == true || quiz && run.correct != nil,canSubmit:service.ready(run),assistantOpen:assistance.assistantOpen,assistantBusy:assistance.assistantBusy,revealedClues:run.revealedClues,recorder:writing.recorder,copy:{questionCopy(run,$0)},help:{assistance.ask(app,run:run)},listen:{speech.speakSeries([run.question.audioText],language:run.question.target,onStarted:{questionAudioPlaying=true},onInterrupted:{questionAudioPlaying=false},onFinished:{questionAudioPlaying=false})},toggleSpeech:{speech.stopAll();questionAudioPlaying=false;assistance.responseChanged();writing.toggle(app,run:run,service:service)},reveal:{
            guard scope == capturedScope,var current=self.run,current.question.id == run.question.id,current.correct != true,!service.busy else{return};current.revealedClues=WritingExerciseRules.clues(current.question.strings("clues"),revealed:current.revealedClues,locked:false).next;current.assisted=true;app.learner.savePractice(current);app.persist()
        },submit:{if let current=self.run{submit(current)}},showHelp:!quiz,playing:questionAudioPlaying,allowsAutoFocus:allowsQuestionAutoFocus,keyboardInitiallyOpen:writingKeyboardInitiallyOpen,focus:$answering).id(run.question.id)
    }
    private func advancedQuestion(_ run:PracticeRun)->some View {
        let capturedScope=scope
        return AdvancedPracticeQuestion(question:run.question,response:run.response,locked:service.busy || run.correct == true || quiz && run.correct != nil,assistantOpen:assistance.assistantOpen,assistantBusy:assistance.assistantBusy,copy:{questionCopy(run,$0)},help:{assistance.ask(app,run:run)},listen:{
            let id=run.question.id
            speech.speakSeries([run.question.audioText],language:run.question.target,onStarted:{if self.run?.question.id == id{questionAudioPlaying=true}},onInterrupted:{questionAudioPlaying=false},onFinished:{questionAudioPlaying=false})
        },change:{response in guard scope == capturedScope,self.run?.question.id == run.question.id else{return};updateResponse(response)},showHelp:!quiz,playing:questionAudioPlaying).id(run.question.id)
    }
    private func playOralAudio(_ run:PracticeRun,answer:Bool){let id=run.question.id;let text=answer ? run.question.payload["answer"].string:run.question.audioText;speech.speakSeries([text],language:run.question.target,onStarted:{if self.run?.question.id == id{questionAudioPlaying=true}},onInterrupted:{questionAudioPlaying=false},onFinished:{questionAudioPlaying=false})}
    private func lessonFlashcard(_ run:PracticeRun)->some View {
        let capturedScope=scope
        return LessonFlashcardQuestion(run:run,busy:service.busy,playing:questionAudioPlaying,recorder:oral.recorder,change:{text in guard scope == capturedScope,let current=self.run,current.question.id == run.question.id,current.correct == nil,!service.busy else{return};updateResponse(current.response.setting("text",.string(text)).setting("typedText",.string(text)).setting("inputSource",.string("text")))},flip:{guard scope == capturedScope,var current=self.run,current.question.id == run.question.id else{return};current.showAnswer = !(current.showAnswer ?? false);app.learner.savePractice(current);app.persist()},listen:{playOralAudio(run,answer:true)},record:{toggleOral(run)},submit:{if let current=self.run{submit(current)}},focus:$answering,keyboardInitiallyOpen:writingKeyboardInitiallyOpen).id(run.question.id)
    }
    private func openDeck(){speech.stopAll();oral.recorder.cancel();deckOwner=scope;showDeck=true}
    private func startPreparation(fresh:Bool){preparationTask?.cancel();preparationTask=Task{await service.prepare(app,module:module,lesson:lesson,fresh:fresh);guard !Task.isCancelled,let run=self.run else{return};assistance.bind(app,run:run);writing.bind(app,run:run);oral.bind(app,run:run)}}
    private func toggleOral(_ run:PracticeRun){answering=false;speech.stopAll();questionAudioPlaying=false;assistance.responseChanged();oral.toggle(app,run:run,service:service)}
    private func oralError(_ code:String)->String{if code == "mic-denied"{return copy("flashcard_mic_denied_title")+" "+copy("flashcard_mic_denied_desc")};let kind=code == "no-speech" ? "no_speech":code.hasPrefix("connection-") ? "connection":code == "transcription-failed" ? "transcription":"recording";return copy("speech_"+kind+"_error_title")+" "+copy("speech_"+kind+"_error_desc")}
    private func retryLessonCard(){guard var current=run,current.question.kind == "flashcard",current.correct == false,!service.busy else{return};oral.clear();assistance.responseChanged();current.correct=nil;current.lastMissedAnswer=nil;current.response=LessonCardRules.retry(current.response);app.learner.savePractice(current);app.persist()}
    private var footerRevision:String {[scope,run?.question.id.uuidString ?? "",run?.response.canonicalJSON ?? "",String(describing:run?.correct),String(run?.earnedXP ?? 0),String(service.busy),String(service.preparing),service.preparingKind ?? "",String(service.preparationFailed),assistance.assistantText,assistance.explanationText,String(assistance.assistantOpen),String(assistance.assistantBusy),String(assistance.explanationBusy),String(noteSaved),String(noteCreating),String(showStandardKeyboard),String(oral.recorder.connecting),String(oral.recorder.recording),String(oral.recorder.evaluating),oral.recorder.error ?? "",String(lessonEarned)].joined(separator:"|")}
    private var lessonEarned:Int {if lesson?.isGoal == true{return Int(GoalLessonProgress.earned(app.learner.goalBucket))};return lesson.flatMap{app.learner.lessonWork?[app.learner.completionKey($0.id)]?.earnedXP} ?? 0}
    private var lessonPercent:Int? {guard let lesson,lesson.id != IntroTutorial.lessonID,!quiz,lesson.xpReward>0 else{return nil};return Int(floor(min(100,Double(lessonEarned)/Double(lesson.xpReward)*100)+0.5))}
    private var questionFooter:some View {
        let palette=brand,dark=scheme == .dark
        return ActivityFooterSurface(feedbackLimit:assistance.assistantOpen ? min(UIScreen.main.bounds.height*0.34,260):nil,preserveEmptyFeedback:run.map{["fill","mc","ma","match","translate","repeat","speak"].contains($0.question.kind)} ?? false,actionHeight:run.map{["fill","mc","ma","match","translate","repeat","speak"].contains($0.question.kind)} == true ? 44:40,showsActions:!(service.busy && run.map{["speak","flashcard"].contains($0.question.kind)} == true),hasFeedback:!service.preparing && !service.preparationFailed && (assistance.assistantOpen || service.busy || run?.correct != nil),feedback:{
            if !service.preparing,!service.preparationFailed,assistance.assistantOpen {
                VStack(alignment:.leading,spacing:8){HStack(spacing:10){PracticeIcon(name:"MdOutlineSupportAgent",size:22).foregroundStyle(palette.questionTool);Text(copy("vocab_assistant")).font(PiyaliBrand.productFont(16,700)).foregroundStyle(PiyaliBrand.unitColor(dark ? "e0f2fe":"1e3a8a"));Spacer();Button{assistance.closeAssistant()}label:{PracticeIcon(name:"FiX")}.frame(width:32,height:32).accessibilityLabel(copy("app_close")).accessibilityIdentifier("closeTypedAssistant")};if assistance.assistantBusy,assistance.assistantText.isEmpty{FocusHeadlineDots().frame(maxWidth:.infinity,alignment:.leading)}else{PracticeFeedbackMarkdown(text:assistance.assistantText,assistant:true).accessibilityIdentifier("typedAssistantText")}}.padding(.horizontal,4).padding(.top,8).padding(.bottom,4)
            } else if service.busy,!service.preparing {HStack(spacing:8){VoiceOrbView(state:"thinking",dark:dark,showShadow:false).frame(width:52,height:52);Text(copy("proficiency_thinking")).font(PiyaliBrand.productFont(16,700));FocusHeadlineDots().frame(width:23)}.frame(maxWidth:.infinity,minHeight:52).padding(.vertical,8)
            } else if !service.preparing,!service.preparationFailed,let run,let correct=run.correct {
                VStack(alignment:.leading,spacing:12) {
                    HStack(alignment:.top,spacing:12){if correct {BrandArtwork(name:"story-portrait-\(portrait).webp").frame(width:32,height:36).accessibilityHidden(true)}else{Text("✖").font(PiyaliBrand.productFont(16,700)).foregroundStyle(palette.questionError)};Text((run.question.kind == "flashcard" ? questionCopy(run,correct ? "correct":"try_again"):copy(correct ? "correct":"try_again"))+(run.earnedXP>0 ? " · +\(run.earnedXP) XP":"")).font(PiyaliBrand.productFont(16,700)).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("practiceVerdict");if !quiz,run.question.kind != "flashcard"{Button{createNote(run)}label:{if noteCreating{ProgressView()}else{PracticeIcon(name:"RiBookmarkLine")}}.frame(width:32,height:32).disabled(noteSaved || noteCreating).accessibilityIdentifier("createTypedStudyNote").accessibilityLabel(copy(noteSaved ? "vocab_note_saved":"vocab_create_note"))}}
                    if correct,let percent=lessonPercent {VStack(spacing:8){HStack{Text(copy("vocab_lesson_progress"));Spacer();Text("\(percent)%").fontWeight(.semibold).accessibilityIdentifier("activeLessonXP")}.font(PiyaliBrand.productFont(12)).foregroundStyle(palette.secondary);FocusWaveBar(percent:Double(lessonEarned)/Double(max(1,lesson?.xpReward ?? 1))*100,height:14,start:"4aa8ff",end:"75f8ff",background:PiyaliBrand.unitColor("7dd3fc").opacity(0.12),border:PiyaliBrand.unitColor("7dd3fc").opacity(0.24))}.padding(.top,12)}
                    if !correct,!quiz {if assistance.explanationText.isEmpty{Button{assistance.explain(app,run:run)}label:{HStack(spacing:8){if assistance.explanationBusy{ProgressView()}else{PracticeIcon(name:"FiHelpCircle",size:16)};Text(run.question.kind == "flashcard" ? questionCopy(run,"explain"):copy("flashcard_explain_answer")).font(PiyaliBrand.productFont(14,600))}.frame(maxWidth:.infinity,minHeight:40).background(palette.surface,in:RoundedRectangle(cornerRadius:18))}.buttonStyle(.plain).disabled(assistance.explanationBusy).accessibilityIdentifier("explainTypedAnswer")}else{PracticeFeedbackMarkdown(text:assistance.explanationText).accessibilityIdentifier("typedExplanation")}}
                }.padding(.horizontal,4).padding(.top,8).padding(.bottom,4)
            }
        },actions:{
            if service.preparationFailed {Button(copy("try_again")){startPreparation(fresh:true)}.buttonStyle(ActivityPrimaryButtonStyle()).accessibilityIdentifier("retryTypedPreparation")}
            else if service.preparing {ProgressView().frame(maxWidth:.infinity,minHeight:40)}
            else if assistance.assistantOpen {Button(copy("app_close")){assistance.closeAssistant()}.buttonStyle(ActivityPrimaryButtonStyle(tone:"assistant")).accessibilityIdentifier("closeTypedAssistantAction")}
            else if let run {
                if run.correct == true || quiz && run.correct != nil {Button{nextQuestion(run)}label:{HStack{Text((["fill","mc","ma","match","translate","repeat","speak"].contains(run.question.kind) ? copy("practice_next_question"):questionCopy(run,"nextQuestion",fallback:copy("grammar_next"))).replacingOccurrences(of:#"\s*→\s*$"#,with:"",options:.regularExpression));PracticeIcon(name:"FiArrowRight",size:16)}}.buttonStyle(ActivityPrimaryButtonStyle(tone:run.correct == true ? "success":"stop")).disabled(service.busy).accessibilityIdentifier("nextTypedQuestion")}
                else if run.question.kind == "speak" {if !quiz{Button(copy("practice_skip_question")){nextQuestion(run)}.font(PiyaliBrand.productFont(14,600)).foregroundStyle(palette.text).frame(minWidth:48,minHeight:40).accessibilityIdentifier("skipLessonActivity")};Button{toggleOral(run)}label:{LessonRecordingLabel(recorder:oral.recorder,label:copy("vocab_speak_record"),connecting:copy("vocab_connecting"),microphone:"stage")}.buttonStyle(ActivityPrimaryButtonStyle(tone:"speak")).disabled(service.busy || oral.recorder.connecting || oral.recorder.evaluating).accessibilityIdentifier("typedPracticeMicrophone").accessibilityLabel(copy(oral.recorder.recording ? "vocab_speak_stop":"vocab_speak_record"))}
                else if run.question.kind == "flashcard" {if !quiz{Button(questionCopy(run,"skip")){nextQuestion(run)}.font(PiyaliBrand.productFont(14,600)).foregroundStyle(palette.text).frame(minWidth:48,minHeight:40).accessibilityIdentifier("skipLessonActivity")};if run.correct == false{Button(questionCopy(run,"try_again")){retryLessonCard()}.buttonStyle(ActivityPrimaryButtonStyle()).accessibilityIdentifier("retryLessonFlashcard")}else{Button{submit(run)}label:{HStack(spacing:8){FlashcardIcon(name:"keyboard",size:16);Text(questionCopy(run,"submit"))}}.buttonStyle(ActivityPrimaryButtonStyle()).disabled(service.busy || !service.ready(run) || oral.recorder.connecting || oral.recorder.recording || oral.recorder.evaluating).accessibilityIdentifier("checkTypedAnswer")}}
                else {if run.question.kind == "fill",StandardPracticeQuestion.keyboard.supported(run.question.target){Button{answering=false;showStandardKeyboard.toggle()}label:{PracticeIcon(name:"MdKeyboard",size:18)}.frame(width:40,height:40).disabled(service.busy).accessibilityLabel(copy(showStandardKeyboard ? "history_keyboard_close":"history_keyboard_open")).accessibilityIdentifier("standardKeyboardToggle")};if !quiz{Button(PracticeCopy.text(variant:run.question.isDelight ? run.question.variant:"flashcard",language:app.learner.support,key:"skip")){nextQuestion(run)}.font(PiyaliBrand.productFont(14,600)).foregroundStyle(palette.text).disabled(service.busy).frame(minWidth:48,minHeight:40).accessibilityIdentifier("skipLessonActivity")};Button(WordBankPracticeQuestion.variants.contains(run.question.kind) ? copy("quiz_submit"):questionCopy(run,"submit",fallback:copy(module == .grammar ? "grammar_submit":"vocab_submit"))){submit(run)}.buttonStyle(ActivityPrimaryButtonStyle()).disabled(service.busy || !service.ready(run)).accessibilityIdentifier("checkTypedAnswer")}
            } else {ProgressView().frame(maxWidth:.infinity,minHeight:40)}
        }).foregroundStyle(palette.text)
    }
    private func submit(_ run:PracticeRun){if WordBankPracticeQuestion.variants.contains(run.question.kind) || StandardPracticeQuestion.variants.contains(run.question.kind){assistance.closeAssistant();assistance.responseChanged()};answering=false;writing.clear();oral.clear();speech.stop();Task{await service.check(app,run:run,confidence:speech.confidence,audio:speech.audioMetrics)}}
    private func nextQuestion(_ run:PracticeRun){oral.clear();writing.clear();speech.stopAll();assistance.cancel();noteSaved=false;if let onNext{onNext()}else{startPreparation(fresh:true)}}
    private func createNote(_ run:PracticeRun){guard !noteCreating,!noteSaved else{return};noteCreating=true;let capturedScope=scope;Task{defer{if scope == capturedScope,self.run?.question.id == run.question.id{noteCreating=false}};if (try? await app.createStudyNote(run:run,lesson:lesson)) == true,scope == capturedScope,self.run?.question.id == run.question.id{noteSaved=true}}}
    private func updateStandardResponse(_ response:JSONValue){
        guard var current=run,current.correct != true,(!quiz || current.correct == nil),!service.busy else{return}
        let previous=current.response,kind=current.question.kind,clear:Bool
        switch kind{
        case "fill":clear = !response["text"].string.isEmpty && response["text"] != previous["text"]
        case "mc","ma":clear = !response["indices"].array.isEmpty && response["indices"] != previous["indices"]
        default:clear = current.question.module == .vocabulary && !response["pairs"].object.isEmpty && response["pairs"] != previous["pairs"]
        }
        current.response=response;if clear{current.correct=nil};app.learner.savePractice(current);app.persist()
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
