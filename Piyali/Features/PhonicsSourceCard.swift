import SwiftUI

struct PhonicsSourceCard:View {
    let app:AppModel,card:JSONValue,count:Int,stackCount:Int,dock:Bool,goal:JSONValue?,repair:RepairStep?
    let onReady:(PhonicsSessionController)->Void,onActivate:(PhonicsSessionController)->Void,onBack:()->Void,onCollect:(PhonicsSessionController)->Void
    @State private var session:PhonicsSessionController?
    @State private var error:String?
    var body:some View {
        Group{if let session{PhonicsCardFaces(session:session,app:app,stackCount:stackCount,dock:dock,onActivate:onActivate,onBack:onBack,onCollect:onCollect)}else if let error{Text(error)}else{ProgressView().frame(height:260)}}
            .task{if let session,session.matches(app){onReady(session);return};do{let next=try PhonicsSessionController(app:app,card:card,correctCount:count,collects:dock,goal:goal,repair:repair);session=next;onReady(next)}catch{self.error=error.localizedDescription}}
            .onDisappear{session?.cancel()}
    }
}
private struct PhonicsCardFaces:View {
    @ObservedObject var session:PhonicsSessionController
    let app:AppModel,stackCount:Int,dock:Bool
    let onActivate:(PhonicsSessionController)->Void,onBack:()->Void,onCollect:(PhonicsSessionController)->Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var wordScale:CGFloat=1000
    private var dark:Bool {scheme == .dark}
    private var brand:PiyaliBrand {.init(dark:dark)}
    private var layers:Int {min(max(stackCount-1,0),4)}
    private var metadata:JSONValue {(try? session.policy.run("ph_card",.object(["card":session.card,"language":.string(session.support)]))) ?? .null}
    var body:some View {
        VStack(spacing:8){
            ZStack{front.opacity(session.flipped ? 0:1);back.rotation3DEffect(.degrees(180),axis:(x:0,y:1,z:0)).opacity(session.flipped ? 1:0)}
                .rotation3DEffect(.degrees(session.flipped ? 180:0),axis:(x:0,y:1,z:0),perspective:0.001)
                .animation(reduceMotion ? nil:.easeInOut(duration:0.5),value:session.flipped)
                .background{GeometryReader{g in ZStack{if layers>0{ForEach(Array((1...layers).reversed()),id:\.self){depth in RoundedRectangle(cornerRadius:48).fill(FlashcardPaint(dark:dark).color("var(--app-surface-muted)")).overlay{RoundedRectangle(cornerRadius:48).stroke(FlashcardPaint(dark:dark).color("var(--app-border-strong)"))}.shadow(color:.black.opacity(0.06),radius:4,y:3).scaleEffect(x:1-Double(depth)*0.018,y:1,anchor:.bottom).offset(y:CGFloat(depth*6))}}}.frame(width:g.size.width,height:g.size.height)}}
                .padding(.bottom,CGFloat(layers*6))
            if let error=session.error {Text(error).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).accessibilityIdentifier("phonicsSaveError")}
            if session.recorder.error != nil {Text(session.text("speechUnsupportedDescription")).font(PiyaliBrand.productFont(14)).accessibilityIdentifier("phonicsSpeechError")}
            if session.playback.error != nil {Text(session.text("gradingErrorDescription")).font(PiyaliBrand.productFont(14)).accessibilityIdentifier("phonicsPlaybackError")}
        }.frame(maxWidth:400).frame(maxWidth:.infinity).accessibilityElement(children:.contain).accessibilityIdentifier("phonicsCard-"+session.card["id"].string)
    }
    private var front:some View {
        VStack(spacing:16){
            HStack{OnboardingText(text:(session.card["type"].string.isEmpty ? "sound":session.text(session.card["type"].string)).uppercased(),size:12,weight:.bold,lineHeight:18).padding(.horizontal,8).padding(.vertical,4).foregroundStyle(brand.surface).background(brand.text,in:RoundedRectangle(cornerRadius:6));Spacer();if !dock{Button{onActivate(session);session.practice(app)}label:{HStack(spacing:6){FlashcardIcon(name:"microphone",size:12);Text(session.text("practice"))}.font(PiyaliBrand.productFont(12,600)).padding(.horizontal,12).frame(height:32).background(.clear,in:Capsule()).overlay{Capsule().stroke(FlashcardPaint(dark:dark).color("var(--app-border-strong)"))}}.buttonStyle(FlashcardTileStyle()).accessibilityIdentifier("phonicsPractice-"+session.card["id"].string)}}
            VStack(spacing:12){
                HStack(spacing:12){VStack(spacing:4){OnboardingText(text:session.support == "ar" ? "\u{202B}"+session.card["letter"].string+"\u{202C}":session.card["letter"].string,size:24,weight:.bold,lineHeight:36);if !metadata["name"].string.isEmpty{OnboardingText(text:metadata["name"].string,size:18,weight:.semibold,lineHeight:27)}};Button{session.speak("letter",app:app)}label:{if session.playback.loading,session.playingKind == "letter"{ProgressView().scaleEffect(0.6).frame(width:34,height:34)}else{FlashcardIcon(name:"volume",size:16).frame(width:34,height:34).foregroundStyle(session.playback.playing && session.playingKind == "letter" ? PiyaliBrand.teal:brand.text)}}.buttonStyle(.plain).background(FlashcardPaint(dark:dark).color("var(--app-surface-muted)"),in:Circle()).overlay{Circle().stroke(brand.border)}.accessibilityLabel(session.text("playSound")).accessibilityIdentifier("phonicsListenLetter")}.frame(minHeight:48)
                if !metadata["sound"].string.isEmpty{OnboardingText(text:metadata["sound"].string,size:14,lineHeight:21)}
                if !metadata["tip"].string.isEmpty{OnboardingText(text:metadata["tip"].string,size:10,lineHeight:15).foregroundStyle(brand.secondary)}
            }.multilineTextAlignment(.center).frame(maxWidth:.infinity)
        }.padding(17).frame(maxWidth:.infinity,minHeight:260).background{RoundedRectangle(cornerRadius:48).fill(brand.surface).shadow(color:dark ? .black.opacity(0.28):Color(red:111/255,green:86/255,blue:54/255).opacity(0.08),radius:dark ? 15:9,y:dark ? 14:8)}.overlay{RoundedRectangle(cornerRadius:48).stroke(brand.border)}.overlay(alignment:session.support == "ar" ? .topTrailing:.topLeading){if session.correctCount>0{HStack(spacing:4){FlashcardIcon(name:"star-filled",size:14).foregroundStyle(PiyaliBrand.unitColor("00ffff"));Text(String(session.correctCount)).font(PiyaliBrand.productFont(12,700))}.padding(12)}}.accessibilityHidden(session.flipped)
    }
    private var back:some View {
        VStack(spacing:12){
            OnboardingText(text:session.text("sayThisWord"),size:12,weight:.medium,lineHeight:18).foregroundStyle(brand.secondary)
            HStack(spacing:8){highlightedWord;Button{session.speak("word",app:app)}label:{if session.playback.loading,session.playingKind == "word"{ProgressView().scaleEffect(0.6).frame(width:32,height:32)}else{FlashcardIcon(name:"volume",size:16).frame(width:32,height:32)}}.buttonStyle(.plain).foregroundStyle(session.playingKind == "word" && session.playback.playing ? PiyaliBrand.teal:brand.text).accessibilityLabel(session.text("playWord")).accessibilityIdentifier("phonicsListenWord")}
            if !metadata["meaning"].string.isEmpty{OnboardingText(text:"("+metadata["meaning"].string+")",size:14,lineHeight:21).foregroundStyle(brand.secondary)}
            if session.busy {VStack(spacing:8){VoiceOrbView(state:"thinking",callActive:false,dark:dark,reducedMotion:reduceMotion,showShadow:false).frame(width:52,height:52);OnboardingText(text:session.text("grading"),size:12,lineHeight:18).foregroundStyle(brand.secondary)}.padding(.vertical,8).accessibilityIdentifier("phonicsGrading")}
            else if let grade=session.grade {VStack(spacing:12){FlashcardIcon(name:grade.correct ? "check":"close",size:24).frame(width:40,height:40).background(PiyaliBrand.unitColor(grade.correct ? "38a169":"e53e3e"),in:Circle());Button{session.stopAudio();session.back();onBack()}label:{Text(session.text("back")).font(PiyaliBrand.productFont(12,600)).frame(height:24)}.buttonStyle(.plain)}.padding(.vertical,8).accessibilityElement(children:.contain).accessibilityIdentifier(grade.correct ? "phonicsCorrect":"phonicsIncorrect")}
            else{Color.clear.frame(height:16)}
        }.padding(17).frame(maxWidth:.infinity,minHeight:260).background{RoundedRectangle(cornerRadius:48).fill(brand.surface).shadow(color:dark ? .black.opacity(0.28):Color(red:111/255,green:86/255,blue:54/255).opacity(0.08),radius:dark ? 15:9,y:dark ? 14:8)}.overlay{RoundedRectangle(cornerRadius:48).stroke(FlashcardPaint(dark:dark).color("var(--app-border-strong)"))}
            .overlay(alignment:session.support == "ar" ? .topTrailing:.topLeading){HStack(spacing:4){FlashcardIcon(name:"star-filled",size:14);Text(String(session.correctCount)).font(PiyaliBrand.productFont(12,700))}.foregroundStyle(PiyaliBrand.unitColor("ecc94b")).padding(12)}
            .overlay(alignment:session.support == "ar" ? .topLeading:.topTrailing){Button{session.stopAudio();session.back();onBack()}label:{FlashcardIcon(name:"close",size:18).frame(width:24,height:24).foregroundStyle(brand.secondary).overlay{Capsule().stroke(FlashcardPaint(dark:dark).color("var(--app-border-strong)"))}}.buttonStyle(.plain).padding(8).accessibilityLabel(session.text("close")).accessibilityIdentifier("phonicsFlipBack")}
            .accessibilityHidden(!session.flipped)
    }
    private var highlightedWord:some View {
        let size=24*wordScale/1000,leading=max(0,36*wordScale/1000-UIFont.systemFont(ofSize:24*wordScale/1000).lineHeight)
        return metadata["parts"].array.reduce(Text("")){text,part in text+Text(part["text"].string).foregroundColor(part["highlight"].boolean ? PiyaliBrand.unitColor("38a169"):brand.text)}.font(.system(size:size,weight:.black)).lineSpacing(leading).padding(.vertical,leading/2).multilineTextAlignment(.center).accessibilityIdentifier("phonicsWord")
    }
}

struct PhonicsActionDock:View {
    @ObservedObject var session:PhonicsSessionController
    let app:AppModel
    let onCollect:(PhonicsSessionController)->Void,onBack:()->Void
    var body:some View {
        ActivityFooterSurface(hasFeedback:session.grade != nil || session.error != nil){
            if let error=session.error{Text(error).font(PiyaliBrand.productFont(14)).accessibilityIdentifier("phonicsFooterError")}
            else if let grade=session.grade{OnboardingText(text:(session.support == "ar" ? "\u{202B}":"")+(grade.correct ? "✓ ":"✖ ")+session.text(grade.correct ? "correct":"tryAgain")+(session.support == "ar" ? "\u{202C}":""),size:16,weight:.bold,lineHeight:24).padding(.vertical,8)}
        }actions:{
            if session.practicing{Button(session.text("back")){session.stopAudio();session.back();onBack()}.buttonStyle(PhonicsSecondaryButtonStyle()).accessibilityIdentifier("phonicsBack")}
            else if session.correctCount>0{Button(session.text("practice")){session.practice(app)}.buttonStyle(PhonicsSecondaryButtonStyle()).accessibilityIdentifier("phonicsPracticeAgain")}
            Button(action:primary){HStack(spacing:8){if session.busy || session.recorder.connecting || session.recorder.evaluating{ProgressView().tint(.white)}else if session.practicing,session.grade == nil{FlashcardIcon(name:"microphone",size:16)};if session.recorder.recording{LandingVoiceWave(level:session.recorder.audioLevel,color:.white).scaleEffect(0.55).frame(width:34,height:20)}else{Text(label)}}}.buttonStyle(ActivityPrimaryButtonStyle(tone:session.grade?.correct == true ? "success":session.practicing && session.grade == nil ? "speak":"primary")).disabled(session.busy || session.recorder.connecting || session.recorder.evaluating).accessibilityLabel(label).accessibilityIdentifier("phonicsPrimary")
        }
    }
    private var label:String {if session.needsSaveRetry{return session.text("tryAgain")};if !session.practicing{return session.text(session.correctCount>0 ? "next":"practice")};if let grade=session.grade{return grade.correct ? (session.collects ? session.text("next"):((try? session.policy.run("ph_copy",.object(["key":.string("progress"),"language":.string(session.support),"targetLang":.string(session.target)])))?["controls"]["repeat"].string ?? session.text("next"))):session.text("tryAgain")};return session.text(session.recorder.recording ? "record":"record")}
    private func primary(){if session.needsSaveRetry{session.retrySave(app)}else if !session.practicing{if session.correctCount>0{onCollect(session)}else{session.practice(app)}}else if let grade=session.grade{if grade.correct{onCollect(session)}else{session.retry()}}else{session.record(app)}}
}

struct PhonicsFooterPublisher:View {
    @ObservedObject var session:PhonicsSessionController
    let owner:UUID,app:AppModel
    let onCollect:(PhonicsSessionController)->Void,onBack:()->Void
    private var revision:String {"\(session.id):\(session.practicing):\(session.grade?.correct.description ?? "nil"):\(session.busy):\(session.recorder.connecting):\(session.recorder.recording):\(session.recorder.evaluating):\(session.correctCount):\(session.error ?? "")"}
    var body:some View {Color.clear.frame(width:0,height:0).activityFooter(owner:owner,revision:revision,access:app.subscription,correct:session.busy ? nil:session.grade?.correct){PhonicsActionDock(session:session,app:app,onCollect:onCollect,onBack:onBack)}}
}

private struct PhonicsSecondaryButtonStyle:ButtonStyle {func makeBody(configuration:Configuration)->some View {configuration.label.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,16).frame(minHeight:40).opacity(configuration.isPressed ? 0.7:1)}}
