import SwiftUI

struct WritingPracticeQuestion:View {
    static let variants:Set<String>=["sentence_shapeshifter","three_clue_mystery","three_word_challenge"]
    let question:PracticeQuestion
    @Binding var text:String
    let locked:Bool,canSubmit:Bool,assistantOpen:Bool,assistantBusy:Bool
    let revealedClues:Int
    @ObservedObject var recorder:SpeechPracticeService
    let copy:(String)->String,help:()->Void,listen:()->Void,toggleSpeech:()->Void,reveal:()->Void,submit:()->Void
    var showHelp=true,playing=false,allowsAutoFocus=true,keyboardInitiallyOpen=false
    @Environment(\.colorScheme) private var scheme
    var focus:FocusState<Bool>.Binding
    @State private var keyboardOpen=false
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var muted:Color{PiyaliBrand.unitColor(scheme == .dark ? "182031":"efe4d5")}
    private var purple:Color{PiyaliBrand.unitColor("805ad5")}
    private var inputDisabled:Bool{locked || recorder.connecting || recorder.recording}
    private static let keyboardLibrary=(try? WritingKeyboard()) ?? .init(data:.null)
    private var keyboard:WritingKeyboard{Self.keyboardLibrary}
    private var targetDirection:LayoutDirection{question.target == "ar" ? .rightToLeft:.leftToRight}
    private func ui(_ key:String)->String{EntryCopy.ui(question.support,key)}
    var body:some View {
        VStack(alignment:.leading,spacing:20){
            VStack(alignment:.leading,spacing:4){HStack(spacing:8){OnboardingText(text:copy("title"),size:20,weight:.heavy,lineHeight:30);Spacer(minLength:8);if showHelp{PracticeToolButton(active:assistantOpen,action:{focus.wrappedValue=false;help()}){PracticeIcon(name:"MdOutlineSupportAgent")}.disabled(assistantBusy).accessibilityLabel(copy("askForHelp")).accessibilityIdentifier("typedPracticeHelp")}};OnboardingText(text:copy("instruction"),size:14,lineHeight:21).foregroundStyle(brand.secondary)}
            switch question.variant {
            case "sentence_shapeshifter":
                HStack(spacing:12){PracticeToolButton(active:playing,action:{focus.wrappedValue=false;listen()}){PracticeIcon(name:"FiVolume2",size:16)}.disabled(recorder.recording || recorder.connecting).accessibilityLabel(copy("playAudio")).accessibilityIdentifier("typedPracticeListen");OnboardingText(text:question.payload["source"].string,size:18,weight:.semibold,lineHeight:27).frame(maxWidth:.infinity,alignment:.leading)}.padding(17).background(muted,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}.environment(\.layoutDirection,targetDirection)
                HStack(spacing:8){Text("↓").font(PiyaliBrand.productFont(16,700));Text(question.payload["constraint"].string).font(PiyaliBrand.productFont(14,500)).multilineTextAlignment(.center)}.foregroundStyle(brand.secondary).frame(maxWidth:.infinity).padding(.horizontal,8)
            case "three_clue_mystery":clues
            default:
                DelightWrapLayout(spacing:12,centered:true,rtl:question.target == "ar"){ForEach(Array(question.strings("cues").enumerated()),id:\.offset){index,cue in OnboardingText(text:cue,size:16,weight:.heavy,lineHeight:24).padding(.horizontal,17.5).padding(.vertical,11.5).background(purple.opacity(0.12),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(PiyaliBrand.unitColor("b794f4"),lineWidth:1.5)}.accessibilityIdentifier("writingCue-\(index)")}}.padding(.vertical,8).environment(\.layoutDirection,targetDirection)
            }
            VStack(spacing:8){
                HStack(alignment:.top,spacing:8){
                    Button{focus.wrappedValue=false;toggleSpeech()}label:{Group{if recorder.connecting || recorder.evaluating{ProgressView()}else if recorder.recording{HStack(spacing:2){ForEach(0..<5){i in Capsule().frame(width:2,height:CGFloat(6+Double((i+1)%3+1)*min(1,recorder.audioLevel*4)*6))}}.frame(width:18,height:18)}else{PracticeIcon(name:"FaMicrophone",size:18)}}.foregroundStyle(brand.questionTool).frame(width:54,height:54).background(recorder.recording ? brand.questionTool.opacity(0.08):brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.questionTool.opacity(0.22))}.opacity(locked || recorder.connecting || recorder.evaluating ? 0.4:1)}.buttonStyle(WritingButtonStyle()).disabled(locked || recorder.connecting || recorder.evaluating).accessibilityLabel(recorder.connecting ? ui("vocab_connecting"):recorder.recording ? "Listening…":ui("flashcard_record_answer")).accessibilityIdentifier("typedPracticeMicrophone")
                    TextField(copy(question.variant == "sentence_shapeshifter" ? "placeholder":"inputPlaceholder"),text:$text,prompt:Text(copy(question.variant == "sentence_shapeshifter" ? "placeholder":"inputPlaceholder")).foregroundStyle(brand.muted)).font(PiyaliBrand.productFont(question.variant == "sentence_shapeshifter" ? 18:16,question.variant == "sentence_shapeshifter" ? 400:600)).padding(.horizontal,17).frame(minHeight:54).background(brand.surface,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(PiyaliBrand.unitColor(focus.wrappedValue ? "9f7aea":scheme == .dark ? "94a3b8":"604d38").opacity(focus.wrappedValue ? 1:scheme == .dark ? 0.34:0.24),lineWidth:focus.wrappedValue ? 2:1)}.focused(focus).disabled(inputDisabled).opacity(inputDisabled ? 0.4:1).textInputAutocapitalization(.sentences).autocorrectionDisabled().submitLabel(.go).onSubmit{if canSubmit,!locked{focus.wrappedValue=false;submit()}}.environment(\.layoutDirection,targetDirection).multilineTextAlignment(question.target == "ar" ? .trailing:.leading).accessibilityIdentifier("typedPracticeAnswer")
                }.environment(\.layoutDirection,.leftToRight)
                if keyboard.supported(question.target){
                    if keyboardOpen {WritingVirtualKeyboard(language:question.target,support:question.support,keyboard:keyboard,onKey:{text=WritingKeyboard.press($0,text:text,disabled:locked)},onClose:{keyboardOpen=false})}
                    Button{focus.wrappedValue=false;keyboardOpen.toggle()}label:{HStack(spacing:8){PracticeIcon(name:"MdKeyboard",size:16);Text(ui(keyboardOpen ? "history_keyboard_close":"history_keyboard_open"))}.font(PiyaliBrand.productFont(16,600)).frame(minHeight:40).padding(.horizontal,16)}.buttonStyle(WritingButtonStyle()).frame(maxWidth:.infinity,alignment:.trailing).disabled(locked).opacity(locked ? 0.4:1).accessibilityIdentifier("writingKeyboardToggle")
                }
            }
            if let error=recorder.error {Text(speechError(error)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.questionError).accessibilityIdentifier("writingSpeechError")}
        }.padding(17).frame(maxWidth:.infinity,alignment:.leading).background(brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(brand.border)}.foregroundStyle(brand.text).compositingGroup().shadow(color:.black.opacity(scheme == .dark ? 0.12:0.04),radius:9,y:8).accessibilityElement(children:.contain).accessibilityIdentifier("typedQuestionPrompt").onChange(of:locked){_,value in if value{focus.wrappedValue=false}}.onAppear{keyboardOpen=keyboardInitiallyOpen;if allowsAutoFocus,question.variant == "sentence_shapeshifter",!locked{focus.wrappedValue=true}}
    }
    private var clues:some View {
        let state=WritingExerciseRules.clues(question.strings("clues"),revealed:revealedClues,locked:locked)
        return VStack(spacing:20){VStack(spacing:12){ForEach(Array(state.visibleClues.enumerated()),id:\.offset){index,clue in
            let latest=index == state.activeClueCount-1
            HStack(alignment:.top,spacing:12){Text(copy("clueBadge").replacingOccurrences(of:"{index}",with:String(index+1))).font(PiyaliBrand.productFont(12,700)).frame(minHeight:18).padding(.horizontal,10).padding(.vertical,2).foregroundStyle(latest ? .white:brand.surface).background(latest ? purple:brand.text,in:Capsule());OnboardingText(text:clue,size:14,weight:latest ? .medium:.regular,lineHeight:22.75).frame(maxWidth:.infinity,alignment:.leading)}.padding(17.5).background(latest ? brand.surface:muted,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(latest ? PiyaliBrand.unitColor("9f7aea"):brand.border,lineWidth:1.5)}.shadow(color:purple.opacity(latest ? 0.12:0),radius:5,y:2).accessibilityElement(children:.contain).accessibilityIdentifier("writingClue-\(index)")
        }}
            HStack(spacing:8){Text(copy("potentialXp").replacingOccurrences(of:"{xp}",with:String(state.potentialXp))).font(PiyaliBrand.productFont(12,600)).foregroundStyle(purple).padding(.horizontal,12).padding(.vertical,4).background(purple.opacity(0.08),in:Capsule()).accessibilityIdentifier("writingPotentialXP");Spacer(minLength:0);if state.hasMoreClues,!locked{Button(copy("revealNext"),action:reveal).font(PiyaliBrand.productFont(14,600)).foregroundStyle(purple).frame(minHeight:32).padding(.horizontal,12).buttonStyle(WritingButtonStyle()).accessibilityIdentifier("writingRevealClue")}}.padding(.horizontal,4)
        }
    }
    private func speechError(_ code:String)->String{if code == "mic-denied"{return ui("flashcard_mic_denied_title")+" "+ui("flashcard_mic_denied_desc")};let kind=code == "no-speech" ? "no_speech":code.hasPrefix("connection-") ? "connection":code == "transcription-failed" ? "transcription":"recording";return ui("speech_"+kind+"_error_title")+" "+ui("speech_"+kind+"_error_desc")}
}
private struct WritingButtonStyle:ButtonStyle{func makeBody(configuration:Configuration)->some View{configuration.label}}

struct WritingVirtualKeyboard:View {
    let language:String,support:String,keyboard:WritingKeyboard
    let onKey:(String)->Void,onClose:()->Void
    var initialMode:String?=nil
    @State private var japaneseMode="hiragana"
    @State private var upper=false
    @Environment(\.colorScheme) private var scheme
    private var mode:String{language == "ja" ? japaneseMode:upper ? "upper":"lower"}
    private var purple:Color{PiyaliBrand.unitColor("805ad5")}
    private func label(_ key:String)->String{keyboard.label(key,language:support)}
    var body:some View {
        VStack(spacing:12){
            HStack(spacing:8){
                if language == "ja" {modeButton("Hiragana",selected:japaneseMode == "hiragana"){japaneseMode="hiragana"};modeButton("Katakana",selected:japaneseMode == "katakana"){japaneseMode="katakana"}}
                else{modeButton(label(upper ? "uppercase":"lowercase"),selected:upper){upper.toggle()}}
                Spacer(minLength:0)
                Button(action:onClose){PracticeIcon(name:"MdClose",size:16).frame(width:32,height:32)}.buttonStyle(WritingButtonStyle()).accessibilityLabel(label("close")).accessibilityIdentifier("writingKeyboardClose")
            }
            VStack(spacing:4){ForEach(Array(keyboard.layout(language:language,mode:mode).enumerated()),id:\.offset){row,keys in
                DelightWrapLayout(spacing:4,centered:true,rtl:support == "ar"){ForEach(Array(keys.enumerated()),id:\.offset){index,key in
                    Button{onKey(key)}label:{Text(key).font(PiyaliBrand.productFont(language == "ja" ? 18:16,500)).frame(width:CGFloat(keyboard.keyWidth(key) ?? (language == "ja" ? 68:60)),height:50).background(PiyaliBrand(dark:scheme == .dark).surface,in:Capsule()).overlay{Capsule().stroke(.white.opacity(0.24))}}.buttonStyle(WritingButtonStyle()).accessibilityIdentifier("writingKey-\(row)-\(index)")
                }}.environment(\.layoutDirection,.leftToRight)
            }
                HStack(spacing:8){Button{onKey(" ")}label:{HStack(spacing:8){PracticeIcon(name:"MdSpaceBar",size:16);Text(label("space"))}.font(PiyaliBrand.productFont(14,600)).frame(minWidth:100,minHeight:36).background(PiyaliBrand(dark:scheme == .dark).surface,in:Capsule()).overlay{Capsule().stroke(.white.opacity(0.24))}}.buttonStyle(WritingButtonStyle()).accessibilityIdentifier("writingKeyboardSpace");Button{onKey("BACKSPACE")}label:{PracticeIcon(name:"MdBackspace",size:16).frame(width:60,height:36).background(PiyaliBrand(dark:scheme == .dark).surface,in:Capsule()).overlay{Capsule().stroke(.white.opacity(0.24))}}.buttonStyle(WritingButtonStyle()).accessibilityLabel(label("backspace")).accessibilityIdentifier("writingKeyboardBackspace")}.frame(maxWidth:.infinity).padding(.top,8)
            }
        }.padding(13).background(PiyaliBrand.unitColor("14141e").opacity(0.98),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(.white.opacity(0.16))}.foregroundStyle(PiyaliBrand(dark:scheme == .dark).text).padding(.top,12).accessibilityElement(children:.contain).accessibilityIdentifier("writingVirtualKeyboard").onAppear{if let initialMode{if language == "ja"{japaneseMode=initialMode}else{upper=initialMode == "upper"}}}
    }
    private func modeButton(_ text:String,selected:Bool,action:@escaping()->Void)->some View{Button(action:action){Text(text).font(PiyaliBrand.productFont(12,600)).padding(.horizontal,8).frame(minHeight:24).foregroundStyle(selected ? .white:PiyaliBrand(dark:scheme == .dark).text).background(selected ? purple:PiyaliBrand(dark:scheme == .dark).surface,in:Capsule()).overlay{Capsule().stroke(selected ? purple:.white.opacity(0.24))}}.buttonStyle(WritingButtonStyle()).accessibilityIdentifier(text == "Hiragana" ? "writingKeyboardHiragana":text == "Katakana" ? "writingKeyboardKatakana":"writingKeyboardCase")}
}
