import SwiftUI

struct PhonicsView:View {
    var repairStep:RepairStep?
    var goalBlueprint:JSONValue?
    @EnvironmentObject private var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var course:PhonicsCourseController
    @State private var active:PhonicsSessionController?
    @State private var action:PhonicsSessionController?
    init(repairStep:RepairStep?=nil,goalBlueprint:JSONValue?=nil,controller:PhonicsCourseController?=nil){self.repairStep=repairStep;self.goalBlueprint=goalBlueprint;_course=StateObject(wrappedValue:controller ?? PhonicsCourseController(goal:goalBlueprint,repair:repairStep))}
    private var dark:Bool {scheme == .dark}
    private var brand:PiyaliBrand {.init(dark:dark)}
    private var scope:String {app.identity.npub+":"+app.learner.target+":"+app.learner.support+":"+(goalBlueprint?["goalId"].string ?? repairStep?.id ?? "ordinary")+":"+(app.lessonLevels.last ?? "Pre-A1")}
    var body:some View {
        ScrollView {
            VStack(spacing:16){
                if course.focused {VStack(spacing:0){OnboardingText(text:(try? app.companionQuestPolicy?.run("ph_copy",.object(["language":.string(app.learner.support),"targetLang":.string(app.learner.target),"key":.string("progress")])))?["headline"].string ?? "",size:20,weight:.bold,lineHeight:24);OnboardingText(text:course.control("subhead",app:app),size:14,lineHeight:21).foregroundStyle(brand.secondary)}}else{header}
                if !course.initialized {ProgressView().frame(height:148)}
                else if let card=course.deck.first {
                    VStack(spacing:16){if course.focused{VStack(spacing:4){HStack{OnboardingText(text:course.copy("progress",app:app),size:12,lineHeight:18);Spacer();OnboardingText(text:"\(course.collected.count) / \(course.total)",size:12,weight:.bold,lineHeight:18)};FocusWaveBar(percent:Double(course.completed)/Double(max(1,course.total))*100,height:10,start:"fbbf24",end:"f59e0b")}.frame(maxWidth:400)}
                        PhonicsSourceCard(app:app,card:card,count:Int(course.counts[card["id"].string].number),stackCount:course.deck.count,dock:true,goal:goalBlueprint,repair:repairStep,onReady:{session in active=session;course.currentSession=session;if action == nil || action?.matches(app) != true{action=session}},onActivate:{session in course.touch();action=session},onBack:{action=course.deck.isEmpty ? nil:active},onCollect:{session in session.stopAudio();course.collect(card,app:app);action=nil}).id(scope+":"+course.sessionGeneration.uuidString+":"+card["id"].string)
                    }
                }else if course.total>0 {
                    VStack(spacing:16){PhonicsCompletionPortrait();OnboardingText(text:course.control("complete",app:app),size:16,weight:.bold,lineHeight:24).foregroundStyle(PiyaliBrand.unitColor(dark ? "9ae6b4":"276749"))}.padding(24).frame(maxWidth:400).background(PiyaliBrand.unitColor(dark ? "1c4532":"f0fff4"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(PiyaliBrand.unitColor(dark ? "48bb78":"9ae6b4"))}
                    if course.complete,!course.focused {VStack(spacing:12){Button{Task{await course.newRound(app)}}label:{HStack{FlashcardIcon(name:"refresh",size:18);Text(course.copy("newRound",app:app))}.frame(maxWidth:.infinity,minHeight:48)}.buttonStyle(.bordered).disabled(course.generating).accessibilityIdentifier("phonicsNewRound");if course.activeLevel != "C2"{Button(course.control("next",app:app)){changeLevel(nextLevel)}.disabled(course.generating).accessibilityIdentifier("phonicsNextLevel")}}.frame(maxWidth:400)}
                }else{Text(course.copy("loadError",app:app)).padding(24)}
                if let error=course.error {VStack(spacing:8){Text(error).font(PiyaliBrand.productFont(14));Button(EntryCopy.ui(app.learner.support,"try_again")){Task{if course.initialized{await course.newRound(app)}else{await course.load(app)}}}}.accessibilityIdentifier("phonicsCourseError")}
                if !course.collected.isEmpty {VStack(spacing:16){ForEach(course.collected,id:\.phonicsCardID){card in PhonicsSourceCard(app:app,card:card,count:Int(course.counts[card["id"].string].number),stackCount:1,dock:false,goal:goalBlueprint,repair:repairStep,onReady:{_ in},onActivate:{session in course.touch();action=session},onBack:{action=course.deck.isEmpty ? nil:active},onCollect:{session in session.retry()}).id(scope+":"+course.sessionGeneration.uuidString+":collected:"+card["id"].string)}}.padding(.top,16)}
            }.padding(.horizontal,24).padding(.top,20).padding(.bottom,max(32,app.activityFooterHeight+24))
        }.background(BrandBackground()).foregroundStyle(brand.text)
            .task(id:scope){active?.cancel();action?.cancel();active=nil;action=nil;await course.load(app)}
            .onChange(of:app.learner.phonicsRecords){_,_ in course.refresh(app)}
            .onChange(of:scenePhase){_,phase in if phase == .background{active?.stopAudio();action?.stopAudio()}}
            .onDisappear{active?.cancel();action?.cancel()}
            .overlay{if let action{PhonicsFooterPublisher(session:action,owner:action.id,app:app,onCollect:{session in session.stopAudio();if course.deck.contains(where:{$0["id"] == session.card["id"]}){course.collect(session.card,app:app);self.action=nil}else{session.retry()}},onBack:{self.action?.stopAudio();self.action?.back();self.action=course.deck.isEmpty ? nil:active}).id(action.id)}}
    }
    private var nextLevel:String {let i=LearningLanguages.levels.firstIndex(of:course.activeLevel) ?? 0;return LearningLanguages.levels[min(i+1,6)]}
    private func changeLevel(_ level:String){active?.cancel();action?.cancel();active=nil;action=nil;course.select(level,app:app)}
    private var header:some View {
        let level=course.activeLevel,index=LearningLanguages.levels.firstIndex(of:level) ?? 0,details=(try? app.companionQuestPolicy?.run("flashLevels",.object([:])))?[level] ?? .null,accent=FlashcardPaint(dark:dark).color(details["color"].string)
        return VStack(spacing:0){
            VStack(spacing:16){VStack(spacing:0){OnboardingText(text:details["displayLabel"].string.isEmpty ? level:details["displayLabel"].string,size:16,weight:.black,lineHeight:24).padding(.horizontal,18).padding(.vertical,10).background(accent.opacity(0.1),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(accent.opacity(0.33),lineWidth:2)};OnboardingText(text:details["name"].localized(app.learner.support),size:16,weight:.bold,lineHeight:24);OnboardingText(text:details["description"].localized(app.learner.support),size:12,lineHeight:18).foregroundStyle(brand.muted)}.multilineTextAlignment(.center)
                HStack(spacing:8){if index>0{levelButton(LearningLanguages.levels[index-1],previous:true)};if index<6{levelButton(nextLevel,previous:false)}}
            }.padding(.bottom,24).frame(maxWidth:.infinity)
            HStack(spacing:12){VStack(alignment:.leading,spacing:0){Text(app.learner.support == "ar" ? "\u{202B}\(course.completed) / \(course.total)\u{202C}":"\(course.completed) / \(course.total)").font(PiyaliBrand.productFont(14,900)).frame(height:14);OnboardingText(text:course.copy("progress",app:app),size:12,weight:.medium,lineHeight:18).foregroundStyle(brand.muted)}.frame(maxWidth:.infinity,alignment:.leading);FocusWaveBar(percent:Double(course.completed)/Double(max(1,course.total))*100,height:12,start:"fbbf24",end:"f59e0b",background:.white.opacity(0.05),border:.white.opacity(0.1)).frame(maxWidth:.infinity)}.padding(.horizontal,13).padding(.vertical,9).background(FlashcardPaint(dark:dark).color("var(--app-glass-bg-soft)"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(brand.border)}.frame(maxWidth:600).padding(.bottom,16)
        }
    }
    private func levelButton(_ level:String,previous:Bool)->some View {
        let allowed=(LearningLanguages.levels.firstIndex(of:level) ?? 0)<=(LearningLanguages.levels.firstIndex(of:course.course["unlockedLevel"].string) ?? 0)
        return Button{changeLevel(level)}label:{HStack(spacing:8){if previous{FlashcardIcon(name:"previous",size:16)};Text(level == "Pre-A1" ? "A0":level);if !previous{FlashcardIcon(name:allowed ? "next":"lock",size:16)}}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,16).frame(minWidth:50,minHeight:32).background(brand.surface.opacity(0.5),in:Capsule()).overlay{Capsule().stroke(PiyaliBrand.unitColor("90cdf4"),lineWidth:2)}}.buttonStyle(FlashcardTileStyle()).disabled(!allowed).opacity(allowed ? 1:0.6).accessibilityIdentifier("phonicsLevel-"+level)
    }
}

private struct PhonicsCompletionPortrait:View {var body:some View {if let url=Bundle.main.url(forResource:StoryCharacterAvatar.appearance.portraitFile("30"),withExtension:nil),let image=UIImage(contentsOfFile:url.path){Image(uiImage:image).resizable().scaledToFit().frame(width:120,height:120)}}}

private extension JSONValue {var phonicsCardID:String {self["id"].string}}
