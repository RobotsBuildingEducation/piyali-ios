import SwiftUI

struct FlashcardPracticeDialog:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var session:FlashcardSessionController
    @StateObject private var recorder=SpeechPracticeService()
    @StateObject private var playback=SpeechService()
    @State private var help=false
    @FocusState private var typing:Bool
    private var dark:Bool {scheme == .dark}
    private var brand:PiyaliBrand {.init(dark:dark)}
    private var paint:FlashcardPaint {.init(dark:dark)}
    private var theme:JSONValue {(try? session.policy.run("flashTheme",.object(["light":.bool(!dark),"correct":.bool(session.grade?.correct == true),"level":session.card["cefrLevel"],"card":session.card.setting("practiceStatus",.string(session.practiceStatus))]),language:session.scope.support)) ?? .object([:])}
    private var shell:JSONValue {let source=session.grade == nil ? theme["shell"]:theme["result"];return source.setting("bg",source["bg"] == .null ? source["shellBg"]:source["bg"]).setting("background",source["background"] == .null ? source["shellBackground"]:source["background"]).setting("borderColor",theme["trim"]["borderColor"])}
    private var answerText:String {session.answer.isEmpty ? session.recognized:session.answer}
    var body:some View {
        GeometryReader {geometry in
            let height=min(max(540,min(700,geometry.size.height*0.82)),geometry.size.height-32)
            ZStack {
                PiyaliBrand.unitColor(dark ? "020617":"1c140c").opacity(dark ? 0.92:0.82).ignoresSafeArea().onTapGesture{close()}
                ScrollView {
                    VStack(spacing:0){
                        if session.explanation.isEmpty {Spacer(minLength:0)}
                        content
                        if session.explanation.isEmpty {Spacer(minLength:0)}
                    }.frame(maxWidth:.infinity,minHeight:max(0,height-56)).padding(28)
                }.scrollDismissesKeyboard(.interactively).frame(width:min(576,geometry.size.width*0.95),height:height).background{FlashcardShell(theme:shell,dark:dark)}.clipShape(EntryCornerShape(radius:64))
            }.frame(width:geometry.size.width,height:geometry.size.height)
        }.ignoresSafeArea(.container).foregroundStyle(dark ? .white:brand.text).accessibilityElement(children:.contain)
            .onDisappear{recorder.cancel();playback.stopAll()}
            .onChange(of:scenePhase){_,phase in if phase == .background {recorder.cancel();playback.stopAll()}}
    }
    @ViewBuilder private var content:some View {
        VStack(spacing:24){
            if session.grade == nil,!session.grading {prompt}
            if let grade=session.grade {result(grade)}
            else if session.grading {ProgressView(session.copy("grading")).padding(.vertical,16).accessibilityIdentifier("flashcardGrading")}
            else {input}
            if let error=session.error {Text(error).font(PiyaliBrand.productFont(14)).foregroundStyle(dark ? Color.white:brand.text).accessibilityIdentifier("flashcardError")}
            if let error=recorder.error {Text(speechError(error)).font(PiyaliBrand.productFont(14)).accessibilityIdentifier("flashcardSpeechError")}
        }
    }
    private var prompt:some View {
        VStack(spacing:4){
            OnboardingText(text:session.flipped ? session.copy("answer_label"):session.copy("translate_to").replacingOccurrences(of:"{language}",with:EntryCopy.ui(session.scope.support,"language_"+session.scope.target)),size:12,weight:.medium,lineHeight:18).foregroundStyle(dark ? Color.white.opacity(0.8):brand.secondary)
            if session.revealing,session.revealed.isEmpty {ProgressView().tint(dark ? .white:brand.text)}
            else {OnboardingText(text:session.flipped ? session.revealed:session.concept,size:30,weight:.black,lineHeight:45).multilineTextAlignment(.center).environment(\.layoutDirection,(session.flipped ? session.scope.target:session.scope.support) == "ar" ? .rightToLeft:.leftToRight).accessibilityIdentifier("flashcardPrompt")}
        }.padding(16).frame(maxWidth:.infinity).frame(height:140).overlay(alignment:.topLeading){
            if !session.flipped {Button{session.flip(app)}label:{FlashcardIcon(name:"support",size:18).frame(width:32,height:32).foregroundStyle(dark ? Color.blue:PiyaliBrand.unitColor("5d6edc")).background(dark ? Color.white:paint.color("var(--app-surface)"),in:RoundedRectangle(cornerRadius:12))}.buttonStyle(.plain).padding(12).accessibilityLabel(session.copy("show_answer")).accessibilityIdentifier("flashcardReveal")}
        }.overlay(alignment:.bottomLeading){if session.flipped,!session.revealing,!session.revealed.isEmpty {Button{playback.speak(session.revealed,language:session.scope.target)}label:{FlashcardIcon(name:"listen",size:14).frame(width:32,height:32)}.buttonStyle(.plain).padding(12).accessibilityLabel(session.copy("listen")).accessibilityIdentifier("flashcardListen")}}
            .overlay(alignment:.bottomTrailing){if session.flipped {Button{session.flip(app)}label:{Text(session.copy("tap_to_flip")).font(PiyaliBrand.productFont(12))}.buttonStyle(.plain).padding(12).accessibilityIdentifier("flashcardFlipBack")}}
    }
    private var input:some View {
        VStack(spacing:16){
            Button{typing=false;playback.stopAll();if recorder.recording || recorder.evaluating{recorder.stop()}else{recorder.start(target:session.scope.target,policy:session.policy){text in session.submit(app,spoken:text)}}}label:{HStack(spacing:10){if recorder.connecting || recorder.evaluating {ProgressView().tint(.white)}else{FlashcardIcon(name:"microphone")};Text(recorder.connecting ? EntryCopy.ui(session.scope.support,"vocab_connecting"):recorder.recording ? session.copy("record_answer"):session.copy("record_answer"))}}
                .buttonStyle(FlashcardActionStyle(color:PiyaliBrand.unitColor(dark ? "319795":"56a89b"),edge:PiyaliBrand.unitColor("234e52"))).disabled(recorder.connecting || recorder.evaluating).accessibilityLabel(session.copy("record_answer")).accessibilityIdentifier("flashcardRecord")
            if !session.recognized.isEmpty {VStack(alignment:.leading,spacing:4){Text(session.copy("recognized")).font(PiyaliBrand.productFont(14));Text(session.recognized).font(PiyaliBrand.productFont(18)).foregroundStyle(PiyaliBrand.unitColor(dark ? "81e6d9":"447a70"))}.frame(maxWidth:.infinity,alignment:.leading).padding(16).background(paint.color("var(--app-surface)"),in:RoundedRectangle(cornerRadius:8))}
            VStack(spacing:12){
                TextField("",text:$session.answer,prompt:Text(session.copy("type_placeholder")).foregroundStyle(dark ? PiyaliBrand.unitColor("879bb4"):brand.muted)).font(PiyaliBrand.productFont(16)).multilineTextAlignment(.center).autocorrectionDisabled().textInputAutocapitalization(.never).focused($typing).frame(height:48).foregroundStyle(dark ? Color.black:brand.text).background(dark ? PiyaliBrand.unitColor("f4f5ff"):brand.surface,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(typing ? paint.color(theme["cefr"]["primary"].string):brand.border,lineWidth:2)}.onSubmit{typing=false;session.submit(app)}.accessibilityIdentifier("flashcardAnswer")
                Button{typing=false;recorder.cancel();session.submit(app)}label:{HStack(spacing:8){FlashcardIcon(name:"keyboard");Text(session.copy("submit"))}}.buttonStyle(FlashcardActionStyle(color:PiyaliBrand.unitColor(dark ? "5dade2":"6b8ecf"),edge:PiyaliBrand.unitColor("2f7cf7"))).disabled(session.answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityIdentifier("flashcardSubmit")
            }.padding(.top,24)
            Button(action:close){Text(session.copy("cancel")).font(PiyaliBrand.productFont(16,600)).frame(maxWidth:.infinity,minHeight:40)}.buttonStyle(.plain).foregroundStyle(dark ? .white:brand.secondary).accessibilityIdentifier("flashcardCancel")
        }
    }
    private func result(_ grade:FlashcardGrade)->some View {
        VStack(alignment:.leading,spacing:16){
            HStack(spacing:12){FlashcardIcon(name:grade.correct ? "check":"close",size:32).foregroundStyle(grade.correct ? Color.green:Color.red);OnboardingText(text:session.copy(grade.correct ? "correct":"incorrect"),size:24,weight:.bold,lineHeight:36);Spacer();Button{session.createNote(app)}label:{FlashcardIcon(name:"bookmark",size:18).frame(width:32,height:32)}.buttonStyle(.plain).disabled(session.creatingNote || session.noteSaved).accessibilityLabel(session.copy(session.noteSaved ? "note_saved":"create_note")).accessibilityIdentifier("flashcardCreateNote")}
            if grade.correct {HStack(spacing:8){FlashcardIcon(name:"star");OnboardingText(text:"+\(grade.xp) XP",size:18,weight:.bold,lineHeight:27)}.foregroundStyle(PiyaliBrand.unitColor("ecc94b")).accessibilityIdentifier("flashcardReward")}
            else {VStack(spacing:12){Button{recorder.cancel();session.retry()}label:{Text(session.copy("try_again"))}.buttonStyle(FlashcardActionStyle(color:PiyaliBrand.unitColor(dark ? "319795":"56a89b"),height:48)).disabled(session.saving).accessibilityIdentifier("flashcardRetry");Button{session.explain(app)}label:{HStack(spacing:8){FlashcardIcon(name:"help",size:18);Text(session.copy("explain_answer"))}}.buttonStyle(FlashcardActionStyle(color:PiyaliBrand.unitColor(dark ? "d45b88":"d8a4b6"),edge:PiyaliBrand.unitColor(dark ? "8f2950":"c08aa0"),text:dark ? .white:PiyaliBrand.unitColor("432b33"),height:48)).disabled(session.explaining || !session.explanation.isEmpty).accessibilityIdentifier("flashcardExplain")}.padding(.top,8)}
            ratingPanel
            if !session.explanation.isEmpty {VStack(alignment:.leading,spacing:8){Label(session.copy("explanation_heading"),systemImage:"eye").font(PiyaliBrand.productFont(14,600));Text(.init(session.explanation)).font(PiyaliBrand.productFont(14)).lineSpacing(5).textSelection(.enabled)}.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(Color.pink.opacity(0.08),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(Color.pink.opacity(0.24))}.accessibilityIdentifier("flashcardExplanation")}
            if grade.correct {VStack(spacing:12){OnboardingText(text:session.copy("xp_level").replacingOccurrences(of:"{level}",with:String((session.languageXP+grade.xp)/100+1))+" • "+session.copy("total_xp").replacingOccurrences(of:"{xp}",with:String(session.languageXP+grade.xp)),size:12,lineHeight:18).foregroundStyle(dark ? .white.opacity(0.8):brand.secondary);FocusWaveBar(percent:Double((session.languageXP+grade.xp)%100),height:15,background:.white.opacity(0.8),border:PiyaliBrand.unitColor("ededed"))}.padding(16)}
        }
    }
    private var ratingPanel:some View {
        VStack(spacing:12){
            HStack{Spacer();Button{help.toggle()}label:{FlashcardIcon(name:"help",size:16).frame(width:32,height:32)}.buttonStyle(.plain).accessibilityLabel(session.copy("rating_help_aria")).accessibilityIdentifier("flashcardRatingHelp").popover(isPresented:$help){VStack(alignment:.leading,spacing:12){Text(session.copy("rating_help_title")).font(PiyaliBrand.productFont(14,700));ForEach(ReviewRating.allCases,id:\.self){rating in VStack(alignment:.leading,spacing:4){Text(session.copy("button_"+rating.rawValue)).font(PiyaliBrand.productFont(14,600));Text(session.copy("button_"+rating.rawValue+"_help")).font(PiyaliBrand.productFont(12))}}}.padding(16).frame(width:280).presentationCompactAdaptation(.popover)}}.padding(.bottom,-4)
            VStack(spacing:12){ForEach(0..<2,id:\.self){row in HStack(spacing:12){ForEach(Array(session.ratings.dropFirst(row*2).prefix(2)),id:\.json){option in if let rating=ReviewRating(rawValue:option["rating"].string){ratingButton(rating,delay:option["delayLabel"].string)}}}}}
            let count=session.dailyCount(app),target=session.policy.dailyTarget(app)
            VStack(spacing:4){HStack{OnboardingText(text:session.copy("daily_target"),size:12,weight:.semibold,lineHeight:18);Spacer();OnboardingText(text:"\(count)/\(target)",size:12,weight:.semibold,lineHeight:18)};FocusWaveBar(percent:Double(count)/Double(max(1,target))*100,height:8,start:"f7d66c",end:"f0b429",background:.white.opacity(0.8),border:PiyaliBrand.unitColor("ededed"))}.padding(.top,4)
        }.padding(17).background(dark ? Color.white.opacity(0.06):paint.color("var(--app-surface)"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(brand.border)}
    }
    private func ratingButton(_ rating:ReviewRating,delay:String)->some View {
        let data=theme["ratings"][rating.rawValue]
        return Button{recorder.cancel();playback.stopAll();session.commit(rating,app:app)}label:{VStack(alignment:.leading,spacing:4){if session.saving{ProgressView()};Text(session.copy("button_"+rating.rawValue)).font(PiyaliBrand.productFont(14,600));Text(delay).font(PiyaliBrand.productFont(12,600)).foregroundStyle(paint.color(data["delayColor"].string))}.frame(maxWidth:.infinity,minHeight:60,alignment:.leading).padding(.horizontal,17).padding(.vertical,12).foregroundStyle(paint.color(data["textColor"].string)).background{Capsule().fill(paint.color(data["bg"].string)).shadow(color:paint.colors(data["shadow"].string).first ?? .clear,radius:0,y:dark ? 4:3)}.overlay{Capsule().stroke(session.grade?.suggested == rating ? (dark ? .white.opacity(0.78):Color(red:96/255,green:77/255,blue:56/255).opacity(0.24)):paint.color(data["borderColor"].string))}}.buttonStyle(.plain).disabled(!session.canRate(rating)).accessibilityIdentifier("flashcardRate-"+rating.rawValue)
    }
    private func close(){typing=false;recorder.cancel();playback.stopAll();session.close(app)}
    private func speechError(_ code:String)->String {let key=code == "mic-denied" ? "mic_denied_desc":code == "no-speech" ? "speech_unavailable_desc":"grading_error_desc";return session.copy(key)}
}
