import SwiftUI

struct LessonFlashcardQuestion:View {
    let run:PracticeRun,busy:Bool,deckCount:Int,playing:Bool
    @ObservedObject var recorder:SpeechPracticeService
    let change:(String)->Void,flip:()->Void,listen:()->Void,record:()->Void,deck:()->Void,submit:()->Void
    var focus:FocusState<Bool>.Binding
    var keyboardInitiallyOpen=false
    @Environment(\.colorScheme)private var scheme
    @Environment(\.accessibilityReduceMotion)private var reduceMotion
    @State private var keyboard=false
    @State private var keyboardInitialized=false
    private var dark:Bool{scheme == .dark}
    private var brand:PiyaliBrand{.init(dark:dark)}
    private var q:PracticeQuestion{run.question}
    private var flipped:Bool{run.showAnswer == true}
    private var base:Color{PiyaliBrand.unitColor(dark ? "0b1220":"fdf9f2")}
    private func copy(_ key:String)->String{PracticeCopy.text(variant:"flashcard",language:q.support,key:key)}
    private var input:String{run.response["typedText"] == .null ? (run.response["inputSource"].string == "speech" ? "":run.response["text"].string):run.response["typedText"].string}
    var body:some View {
        VStack(spacing:12){
            if deckCount>0{Button(action:deck){HStack(spacing:8){Image("Practice-RiStackLine").renderingMode(.template).resizable().frame(width:16,height:16);Text(copy("deck_label")).font(PiyaliBrand.productFont(14,500));Spacer();HStack(spacing:4){ForEach(0..<min(8,deckCount),id:\.self){i in RoundedRectangle(cornerRadius:2).fill(PiyaliBrand.unitColor("4299e1").opacity(0.5+Double(i)/Double(min(8,deckCount))*0.5)).frame(width:6,height:8)};Text("\(deckCount)").font(PiyaliBrand.productFont(12)).foregroundStyle(brand.muted).padding(.leading,4)}}.foregroundStyle(PiyaliBrand.unitColor("90cdf4")).padding(13).background(brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}}.buttonStyle(.plain).accessibilityIdentifier("openLessonFlashcardDeck")}
            VStack(spacing:8){
                ZStack{
                    VStack(spacing:4){Text(copy("translate_to").replacingOccurrences(of:"{language}",with:EntryCopy.ui(q.support,"language_"+q.target))).font(PiyaliBrand.productFont(12,500)).frame(minHeight:18).foregroundStyle(dark ? .white.opacity(0.8):brand.secondary);OnboardingText(text:q.payload["concept"].string,size:20,weight:.black,lineHeight:30).foregroundStyle(dark ? .white:brand.text).multilineTextAlignment(.center).environment(\.layoutDirection,q.support == "ar" ? .rightToLeft:.leftToRight)}.offset(y:2).frame(maxWidth:.infinity,maxHeight:.infinity).padding(.horizontal,12).opacity(flipped ? 0:1).accessibilityHidden(flipped)
                    VStack(spacing:4){Text(copy("answer_label")).font(PiyaliBrand.productFont(12,500)).frame(minHeight:18).foregroundStyle(dark ? .white:brand.secondary);OnboardingText(text:q.payload["answer"].string,size:20,weight:.black,lineHeight:30).foregroundStyle(dark ? .white:brand.text).multilineTextAlignment(.center).environment(\.layoutDirection,q.target == "ar" ? .rightToLeft:.leftToRight)}.frame(maxWidth:.infinity,maxHeight:.infinity).padding(12).opacity(flipped ? 1:0).accessibilityHidden(!flipped)
                }.frame(height:140).environment(\.layoutDirection,.leftToRight).contentShape(Rectangle()).onTapGesture{if flipped{withAnimation(reduceMotion ? nil:.easeInOut(duration:0.6)){flip()}}}.overlay(alignment:.topLeading){if !flipped{StandardQuestionTool(cornerRadius:12,action:{withAnimation(reduceMotion ? nil:.easeInOut(duration:0.6)){flip()}}){PracticeIcon(name:"MdOutlineSupportAgent",size:18)}.padding(8).accessibilityLabel(copy("show_answer")).accessibilityIdentifier("flipLessonFlashcard")}}.overlay(alignment:.bottomLeading){if flipped{StandardQuestionTool(active:playing,action:listen){FlashcardIcon(name:"listen",size:14)}.padding(8).accessibilityLabel(copy("listen")).accessibilityIdentifier("listenLessonFlashcard")}}.overlay(alignment:.bottomTrailing){if flipped{Button(copy("tap_to_flip"),action:flip).font(PiyaliBrand.productFont(12)).foregroundStyle(dark ? .white:brand.secondary).padding(8).accessibilityIdentifier("flipLessonFlashcard")}}.environment(\.layoutDirection,.leftToRight)
                if run.correct == nil{
                    if busy{FocusHeadlineDots().frame(maxWidth:.infinity,minHeight:140).padding(.top,8).accessibilityIdentifier("lessonFlashcardGrading")}
                    else{VStack(spacing:8){Button(action:record){LessonRecordingLabel(recorder:recorder,label:copy("record"),connecting:copy("connecting")).frame(maxWidth:.infinity,minHeight:40).font(PiyaliBrand.productFont(16,600)).foregroundStyle(.white).background{Capsule().fill(PiyaliBrand.unitColor(recorder.connecting ? "d69e2e":"319795")).shadow(color:PiyaliBrand.unitColor(recorder.connecting ? "975a16":"215154"),radius:0,y:4).shadow(color:PiyaliBrand.unitColor("319795").opacity(0.08),radius:8,y:7)}}.buttonStyle(.plain).disabled(recorder.connecting || recorder.evaluating).opacity(recorder.connecting || recorder.evaluating ? 0.4:1).accessibilityIdentifier("typedPracticeMicrophone").accessibilityLabel(recorder.recording ? copy("stop_recording"):copy("record"))
                            VStack(spacing:12){HStack(spacing:8){TextField(copy("type_placeholder"),text:Binding(get:{input},set:change),prompt:Text(copy("type_placeholder")).foregroundStyle(brand.muted)).font(PiyaliBrand.productFont(14)).multilineTextAlignment(.center).foregroundStyle(brand.text).padding(.horizontal,17).frame(height:40).background(base,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(brand.border)}.focused(focus).autocorrectionDisabled().textInputAutocapitalization(.sentences).submitLabel(.done).onSubmit{if !input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty{submit()}}.disabled(recorder.connecting || recorder.recording || recorder.evaluating).environment(\.layoutDirection,q.target == "ar" ? .rightToLeft:.leftToRight).accessibilityIdentifier("typedPracticeAnswer")
                                    if StandardPracticeQuestion.keyboard.supported(q.target){Button{focus.wrappedValue=false;keyboard.toggle()}label:{PracticeIcon(name:"MdKeyboard",size:20).frame(width:40,height:40).foregroundStyle(keyboard ? .white:brand.text).background(keyboard ? PiyaliBrand.unitColor("3182ce"):base,in:Circle()).overlay{Circle().stroke(brand.border)}}.accessibilityLabel(copy(keyboard ? "close_keyboard":"open_keyboard")).accessibilityIdentifier("lessonFlashcardKeyboardToggle")}}
                                if keyboard,StandardPracticeQuestion.keyboard.supported(q.target){WritingVirtualKeyboard(language:q.target,support:q.support,keyboard:StandardPracticeQuestion.keyboard,onKey:{change(WritingKeyboard.press($0,text:input,disabled:recorder.recording || recorder.connecting))},onClose:{keyboard=false})}
                            }.padding(.top,16)
                        }.padding(.top,8)}
                }
            }.padding(.horizontal,18).padding(.vertical,14).background{LessonFlashcardSurface(dark:dark)}.clipShape(RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(dark ? PiyaliBrand.unitColor("3b82f6").opacity(0.2):brand.border,lineWidth:2)}.overlay{if dark{RoundedRectangle(cornerRadius:18).stroke(PiyaliBrand.unitColor("3b82f6").opacity(0.25),lineWidth:2).padding(-1)}}.compositingGroup().shadow(color:.black.opacity(dark ? 0.5:0.04),radius:dark ? 30:9,y:dark ? 20:8)
        }.frame(maxWidth:400).frame(maxWidth:.infinity).accessibilityElement(children:.contain).accessibilityIdentifier("typedQuestionPrompt").onAppear{if !keyboardInitialized{keyboardInitialized=true;keyboard=keyboardInitiallyOpen}}
    }
}
struct LessonFlashcardSurface:View {
    let dark:Bool
    var body:some View{GeometryReader{g in ZStack{if dark{LinearGradient(colors:[PiyaliBrand.unitColor("08142b"),PiyaliBrand.unitColor("051024")],startPoint:.top,endPoint:.bottom);RadialGradient(colors:[PiyaliBrand.unitColor("38bdf8").opacity(0.14),.clear],center:.init(x:0.2,y:0.15),startRadius:0,endRadius:g.size.width*0.42);RadialGradient(colors:[PiyaliBrand.unitColor("2dd4bf").opacity(0.12),.clear],center:.init(x:0.82,y:0.25),startRadius:0,endRadius:g.size.width*0.4);RadialGradient(colors:[PiyaliBrand.unitColor("1e40af").opacity(0.28),.clear],center:.init(x:0.5,y:1),startRadius:0,endRadius:g.size.width*0.62);Path{p in for x in stride(from:0.0,through:g.size.width,by:28){p.move(to:.init(x:x,y:0));p.addLine(to:.init(x:x,y:g.size.height))};for y in stride(from:0.0,through:g.size.height,by:28){p.move(to:.init(x:0,y:y));p.addLine(to:.init(x:g.size.width,y:y))}}.stroke(PiyaliBrand.unitColor("94a3b8").opacity(0.025),lineWidth:1)}else{PiyaliBrand(dark:false).surface}}}.allowsHitTesting(false)}
}
