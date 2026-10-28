import SwiftUI

/// The original introduction mounts each activity inline, in its authored order.
struct IntroTutorialView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private let initialLesson:Lesson
    init(lesson:Lesson) { initialLesson=lesson }
    private var lesson:Lesson { app.introLesson ?? initialLesson }
    private var scope:String { app.identity.npub+":"+app.learner.target+":"+app.learner.support+":"+app.learner.level }
    private var mode:String { app.learner.introSession.next ?? "game" }
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    @StateObject private var gamePreparation=GamePreparationController()
    @State private var gameFooterOwner=UUID()
    @State private var gamePresented=false
    @State private var finishGameOnDismiss=false
    @State private var finishing=false
    @State private var reviewing=false
    @State private var appeared=false
    @State private var descriptionMode:IntroDescription?
    var body:some View {
        let capturedScope=scope
        VStack(spacing:0) {
            if mode != "game" || !gamePresented { stepper.padding(.horizontal,12).padding(.vertical,16) }
            engine(scope:capturedScope).id(capturedScope+":"+mode)
        }.background(brand.background).navigationTitle(lesson.title.localized(app.learner.support)).navigationBarTitleDisplayMode(.inline)
            .disabled(app.loadingContent || app.introLibrary?.target != app.learner.target || finishing)
            .fullScreenCover(isPresented:$gamePresented,onDismiss:{if finishGameOnDismiss{finishGameOnDismiss=false;advance("game",scope:capturedScope)}else{dismiss()}}){NavigationStack{RPGView(lesson:lesson,episode:nil,onTutorialComplete:{finishGameOnDismiss=true;gamePresented=false})}}
            .onChange(of:mode){_,value in if value == "game",!finishing{gamePreparation.reveal()}}
            .onChange(of:gamePreparation.ready){_,ready in if ready,!gamePresented,mode == "game",scope == capturedScope,gamePreparation.commit(app){gamePresented=true}}
            .task(id:scope){gamePreparation.cancel();gamePreparation.start(app,lesson:lesson,deferReveal:true);if mode == "game"{gamePreparation.reveal()}}
            .onChange(of:app.subscription.hasAccess){_,allowed in if !allowed,!gamePresented{gamePreparation.cancel()}}
            .onAppear {
                app.lessonActivityActive=true
                guard !appeared else { return };appeared=true
                reviewing=app.learner.completed.contains(app.learner.completionKey(IntroTutorial.lessonID))
                if reviewing,app.learner.introSession.ready { app.learner.restartIntroReview();app.persist() }
                else if app.learner.introSession.ready { finish(scope:capturedScope) }
                else if mode == "game",!finishing{gamePreparation.reveal()}
            }
            .onDisappear { if !gamePresented{gamePreparation.cancel();app.lessonActivityActive=false} }
            .popover(item:$descriptionMode) { selected in let item=selected.id;VStack(alignment:.leading,spacing:12) { Text(LessonSessionCopy.module(item,language:app.learner.support)).font(.headline);Text(item == mode ? lesson.content[item]["tutorialDescription"].localized(app.learner.support) : LessonSessionCopy.module(item,language:app.learner.support,key:"description")) }.padding(24).presentationCompactAdaptation(.popover) }
    }
    private var stepper:some View {
        HStack(alignment:.top,spacing:0) {
            ForEach(Array(IntroTutorial.modes.enumerated()),id:\.element) { index,item in
                if index > 0 { Rectangle().fill(app.learner.introSession.visited.contains(IntroTutorial.modes[index-1]) ? color(item) : brand.border).frame(maxWidth:30,maxHeight:3).padding(.top,18) }
                VStack(spacing:7) {
                    let done=app.learner.introSession.visited.contains(item),current=mode == item
                    Button { descriptionMode=IntroDescription(id:item) } label:{ Image(systemName:done ? "checkmark" : LessonPreviewView.icon(item)).font(.system(size:16,weight:.semibold)).foregroundStyle(done ? .white : current ? color(item) : brand.muted).frame(width:36,height:36).background { Circle().fill(done ? color(item) : brand.surface).shadow(color:current ? color(item) : brand.border,radius:0,y:4) }.overlay { Circle().stroke(color(item)) }.scaleEffect(current ? 1.1 : 1) }.buttonStyle(.plain).accessibilityLabel("Tutorial step: "+LessonSessionCopy.module(item,language:app.learner.support)).accessibilityIdentifier("introStep-"+item).accessibilityValue(done ? "Completed" : current ? "Current" : "Upcoming")
                    Text(LessonSessionCopy.module(item,language:app.learner.support,key:"shortLabel")).font(PiyaliBrand.productFont(10,current ? 700 : 500)).foregroundStyle(done || current ? brand.text : brand.muted).lineLimit(1).minimumScaleFactor(0.6)
                }
            }
        }.accessibilityElement(children:.contain).accessibilityIdentifier("introProgress").accessibilityValue("\(app.learner.introSession.visited.count) / 6")
    }
    private func color(_ mode:String)->Color {
        let text=LessonSessionCopy.data["modules"][mode]["color"].string
        let value=UInt32(text.dropFirst(),radix:16) ?? 0x60a5fa
        return Color(red:Double((value>>16)&255)/255,green:Double((value>>8)&255)/255,blue:Double(value&255)/255)
    }
    @ViewBuilder private func engine(scope:String)->some View {
        switch mode {
        case "vocabulary","grammar":LessonPracticeView(module:mode == "vocabulary" ? .vocabulary : .grammar,lesson:lesson,onNext:{ advance(mode,scope:scope) },startsFresh:reviewing,embedded:true)
        case "reading":ReadingView(lesson:lesson,onComplete:{ advance("reading",scope:scope) },embedded:true)
        case "stories":StoryView(lesson:lesson,onComplete:{ advance("stories",scope:scope) },embedded:true)
        case "realtime":RealtimeLessonView(lesson:lesson,onNext:{ advance("realtime",scope:scope) },startsFresh:reviewing)
        case "game":GeometryReader{geometry in
            VStack(spacing:12){
                GamePreparationView(preparation:gamePreparation,support:app.learner.support,pet:app.learner.effectiveCompanionType,embedded:true,showsCancel:false,onCancel:{}).environmentObject(app).frame(height:max(300,min(UIScreen.main.bounds.height*0.62,geometry.size.height-70))).clipShape(RoundedRectangle(cornerRadius:12)).padding(.horizontal,12).accessibilityElement(children:.contain).accessibilityIdentifier("introGamePreparation")
                if let error=gamePreparation.error{Text(error).font(PiyaliBrand.productFont(13)).foregroundStyle(.red);Button(EntryCopy.ui(app.learner.support,"practice_retry")){gamePreparation.cancel();gamePreparation.start(app,lesson:lesson);gamePreparation.reveal()}.accessibilityIdentifier("retryIntroGamePreparation")}
                Spacer(minLength:0)
            }
        }.activityFooter(owner:gameFooterOwner,revision:scope+":"+String(gamePresented),access:app.subscription,enabled:!gamePresented){ActivityFooterSurface(hasFeedback:false,feedback:{EmptyView()},actions:{Button(EntryCopy.ui(app.learner.support,"ra_btn_skip")){gamePreparation.cancel();advance("game",scope:scope)}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,8).frame(height:40).buttonStyle(.plain).accessibilityIdentifier("skipIntroActivity");Spacer(minLength:0)})}
        default:EmptyView()
        }
    }
    private func skip(_ mode:String,scope:String)->some View { Button { advance(mode,scope:scope) } label:{ Text(EntryCopy.ui(app.learner.support,"ra_btn_skip")).frame(maxWidth:.infinity,minHeight:44).contentShape(Rectangle()) }.buttonStyle(.bordered).padding(12).padding(.bottom,78).background(brand.background).accessibilityIdentifier("skipIntroActivity") }
    private func advance(_ mode:String,scope:String) {
        guard scope == self.scope,!finishing else { return };guard app.learner.visitIntro(mode,expectedLevel:app.learner.level) else { return };app.persist()
        if app.learner.introSession.ready { finish(scope:scope) }
    }
    private func finish(scope:String) {
        guard scope == self.scope,!finishing else { return };finishing=true
        let rewarded=app.learner.completeIntro(lesson);app.persist()
        if rewarded { app.pendingLessonCompletion = .init(account:app.identity.npub,target:app.learner.target,lesson:lesson,reward:lesson.xpReward,languageXP:app.learner.xp);app.requestScholarship() }
        dismiss()
    }
}
private struct IntroDescription:Identifiable { let id:String }
