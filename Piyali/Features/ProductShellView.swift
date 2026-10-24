import SwiftUI

enum ProductMode:String,CaseIterable {
    case focus,path,cards,phonics,conversation,tutor
    var symbol:String { switch self { case .focus:return "seal";case .path:return "point.topleft.down.to.point.bottomright.curvepath";case .cards:return "rectangle.stack";case .phonics:return "character.book.closed";case .conversation:return "bubble.left";case .tutor:return "book.closed" } }
    func title(_ language:String)->String {
        if self == .focus { return ProductCopy.text(language,"PLATE_TITLE_COPY") }
        return EntryCopy.ui(language,"app_mode_"+([.path:"path",.cards:"cards",.phonics:"phonics",.conversation:"conversation",.tutor:"tutor"][self] ?? "path"))
    }
}
enum ProductPanel:String,Identifiable { case settings,teams,assistant,memory,achievements,placement,goal;var id:String { rawValue } }
struct ProductCopy {
    static let entries=(try? ContentLibrary.load([String:JSONValue].self,name:"product-copy")) ?? [:]
    static func data(_ language:String)->JSONValue { entries[language] ?? entries["en"] ?? .object([:]) }
    static func text(_ language:String,_ key:String)->String { data(language)[key].string }
    static func course(_ language:String,_ kind:String)->String { data(language)["courses"][kind].string }
}

struct ProductShellView:View {
    var now=Date()
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var timer=SessionTimerController()
    @State private var goalOpen=false
    @State private var timerOpen=false
    @State private var timerAwardRevision=UUID()
    @AppStorage("piyali.theme") private var theme="light"
    @State private var firstRun=FirstRunFlow()
    @State private var mode:ProductMode = .focus
    @State private var specialCourse:String?
    @State private var menuOpen=false
    @State private var modesOpen=false
    @State private var panel:ProductPanel?
    @State private var revision=UUID()
    @State private var guided:GuidedPracticeSession?
    @State private var celebration=false
    @State private var waitingCelebration=false
    @State private var lessonCompletion:LessonCompletionPresentation?
    @State private var presentedLessonCompletionID:UUID?
    private var language:String { app.learner.support }
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    private var sessionKey:String { "piyali.guidedSession."+app.identity.npub }
    private var firstRunScope:String {app.identity.npub+":"+app.learner.target}
    private var contextKey:String { app.identity.npub+":"+app.learner.target+":"+CalendarDay.key(now) }
    private var timerAwardKey:String {timer.session.account+":"+(timer.pending.first ?? "")+":"+timerAwardRevision.uuidString}
    private var shell:some View {
        ZStack(alignment:.bottom) {
            BrandBackground()
            NavigationStack {
                surface.navigationBarTitleDisplayMode(.inline)
                    .toolbar(mode == .focus ? .hidden:.automatic,for:.navigationBar)
            }.id(revision).tint(PiyaliBrand.teal).blur(radius:menuOpen ? 6 : 0).allowsHitTesting(!menuOpen)
                .safeAreaInset(edge:.top,spacing:0){ProductTopBar(timer:timer,onGoal:{goalOpen=true},onTimer:{timer.load(account:app.identity.npub);timerOpen=true})}
                .safeAreaInset(edge:.bottom) { if app.activityFooter == nil { menuButton(compact:false).padding(.bottom,10) } }
                .overlay(alignment:.bottom) {
                    if let footer=app.activityFooter {
                        ZStack(alignment:.bottomLeading) {
                            footer.content.id(footer.owner).padding(12).background {
                                RoundedRectangle(cornerRadius:24).fill(.ultraThinMaterial)
                                if let correct=footer.correct { RoundedRectangle(cornerRadius:24).fill((correct ? brand.questionSuccess : brand.questionError).opacity(scheme == .dark ? 0.14 : 0.10)) }
                            }.overlay { RoundedRectangle(cornerRadius:24).stroke(footer.correct.map { $0 ? brand.questionSuccess : brand.questionError } ?? brand.border) }.padding(.horizontal,8).padding(.bottom,6)
                            menuButton(compact:true).padding(.leading,20).padding(.bottom,18)
                        }.onGeometryChange(for:CGFloat.self,of:{ $0.size.height }) { app.activityFooterHeight=$0 }
                    }
                }
            if menuOpen { menu }
        }.font(PiyaliBrand.productFont(16)).foregroundStyle(brand.text)
            .accessibilityElement(children:.contain).accessibilityHidden(lessonCompletion != nil || firstRun.step != nil || goalOpen || timerOpen || timer.session.status == .finished)
            .overlay {
                if let data=lessonCompletion {
                    ZStack {
                        (scheme == .dark ? Color(red:2/255,green:6/255,blue:23/255).opacity(0.92) : Color(red:28/255,green:20/255,blue:12/255).opacity(0.82)).ignoresSafeArea().onTapGesture { closeLessonCompletion() }
                        LessonCompletionView(completion:data,onContinue:closeLessonCompletion).fixedSize(horizontal:false,vertical:true).onTapGesture { }.padding(12)
                    }.accessibilityElement(children:.contain).accessibilityIdentifier("lessonCompletionDialog")
                }
            }
            .overlay {
                if let step=firstRun.step {
                    ZStack {
                        (scheme == .dark ? Color(red:2/255,green:6/255,blue:23/255).opacity(0.92) : Color(red:28/255,green:20/255,blue:12/255).opacity(0.82)).ignoresSafeArea().onTapGesture {closeFirstRun()}
                        if step == .gettingStarted {GettingStartedView(onClose:closeFirstRun)}
                        else {PlacementView(overlay:true,onClose:{firstRun.close()})}
                    }.accessibilityElement(children:.contain).accessibilityIdentifier("firstRunDialog")
                }
            }
            .onChange(of:firstRunScope) {_,scope in firstRun.reconcile(scope:scope)}
            .preferredColorScheme(theme == "dark" ? .dark : .light)
            .environment(\.layoutDirection,language == "ar" ? .rightToLeft : .leftToRight)
    }
    var body:some View {
        shell
            .overlay{if goalOpen{DailyGoalManagerView(onClose:{goalOpen=false}).accessibilityHidden(timerOpen || timer.session.status == .finished)}}
            .overlay{if timerOpen{SessionTimerView(timer:timer,language:language,onClose:{timerOpen=false}).accessibilityHidden(timer.session.status == .finished)}}
            .overlay{if timer.session.status == .finished,firstRun.step == nil,lessonCompletion == nil,panel == nil{SessionTimeUpView(minutes:timer.session.duration/60,language:language,onClose:timer.clear,onRestart:{timer.clear();timerOpen=true})}}
            .environment(\.layoutDirection,language == "ar" ? .rightToLeft : .leftToRight)
            .task(id:timerAwardKey){
                let account=timer.session.account
                guard account==app.identity.npub,let id=timer.pending.first else{return}
                do{try await FirebaseService.shared.recordSessionTimer(npub:account,id:id);try Task.checkCancellation();timer.acknowledge(id,account:account)}catch{}
            }
            .onChange(of:scenePhase){_,value in if value == .active{timer.refresh();timerAwardRevision=UUID()}}
            .onChange(of:app.syncStatus){_,value in if value == "Synced with Firebase"{timerAwardRevision=UUID()}}
            .onChange(of:app.identity.npub){_,_ in goalOpen=false;timerOpen=false;timer.load(account:app.identity.npub)}
            .onChange(of:timer.session.status){_,value in if value == .finished{UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to:nil,from:nil,for:nil)}}
            .sheet(item:$panel) { selected in NavigationStack { panelContent(selected).toolbar { ToolbarItem(placement:.confirmationAction) { Button(EntryCopy.text(language,"back_button")) { panel=nil }.accessibilityIdentifier("productPanelClose") } } }.tint(PiyaliBrand.teal) }
            .sheet(isPresented:$celebration) { completion }
            .task(id:contextKey) {
                timer.load(account:app.identity.npub)
                if app.learner.dailyKey != CalendarDay.key(now) { app.learner.rollDay(now:now);app.persist() }
                app.prepareDailyPlate()
                if let guided,!guided.matches(account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(now)) { celebration=false;waitingCelebration=false;specialCourse=nil }
                restoreSession()
                presentPendingLessonCompletion()
            }
            .onChange(of:app.activityFooter == nil) { _,absent in if absent { app.activityFooterHeight=0 } }
            .onChange(of:app.learner.target) { _,_ in revision=UUID() }
            .onChange(of:app.localPracticeRevision) { _,_ in checkCompletion() }
            .onChange(of:panel) { _,value in if value == nil { presentPendingLessonCompletion();checkCompletion() } }
            .onChange(of:menuOpen) { _,open in if !open { presentPendingLessonCompletion();checkCompletion() } }
            .onChange(of:app.pendingLessonCompletion?.id) { _,_ in presentPendingLessonCompletion() }
            .onChange(of:app.lessonActivityActive) { _,active in if !active { presentPendingLessonCompletion();checkCompletion() } }
    }
    private func closeFirstRun() {
        if firstRun.step == .gettingStarted {
            if firstRun.acknowledge(scope:firstRunScope,hasPlacement:app.learner.hasFirstRunPlacement) {app.learner.gettingStartedModalShown=true;app.persist()}
        } else {firstRun.close()}
    }
    private func menuButton(compact:Bool)->some View {
        Button { modesOpen=false;menuOpen.toggle() } label:{ Image(systemName:"square.grid.3x3.fill").font(.system(size:compact ? 18 : 20)).foregroundStyle(brand.text).frame(width:compact ? 40 : 58,height:compact ? 40 : 58).background(brand.surface.opacity(0.92),in:RoundedRectangle(cornerRadius:compact ? 14 : 20)).overlay { RoundedRectangle(cornerRadius:compact ? 14 : 20).stroke(brand.border) } }.accessibilityLabel(mode.title(language)).accessibilityIdentifier("productMenu")
    }
    @ViewBuilder private var surface:some View {
        if specialCourse == "goal" { FocusedGoalView() }
        else if specialCourse == "repair" { RepairPracticeView() }
        else { switch mode {
        case .focus: TodayFocusHomeView(now:now,sessionActive:guided != nil,onStart:startPractice,onPanel:{ panel=$0 },onCompanionContinue:{firstRun.request(scope:firstRunScope,shown:app.learner.gettingStartedModalShown == true,hasPlacement:app.learner.hasFirstRunPlacement)})
        case .path: LessonPathView()
        case .cards: FlashcardsView()
        case .phonics: PhonicsView()
        case .conversation: ConversationView()
        case .tutor: TutorLibraryView()
        } }
    }
    private var menu:some View {
        GeometryReader { geometry in
            ZStack(alignment:.bottom) {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { menuOpen=false }
                VStack(spacing:10) {
                    HStack { Spacer();Capsule().fill(brand.muted.opacity(0.6)).frame(width:48,height:5);Spacer();Button { menuOpen=false } label:{ Image(systemName:"xmark").frame(width:36,height:36) }.accessibilityLabel(ProductCopy.data(language)["menu"]["closeMenu"].string).accessibilityIdentifier("productMenuClose") }.padding(.bottom,12)
                    LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:9) {
                        if modesOpen { ForEach(ProductMode.allCases,id:\.self) { item in menuTile(item.title(language),symbol:item.symbol,selected:item == mode) { switchMode(item) }.accessibilityIdentifier("productMode-"+item.rawValue) } }
                        else { ForEach([ProductPanel.settings,.teams,.assistant,.memory]) { item in menuTile(ProductCopy.data(language)["menu"][item.rawValue].string,symbol:[.settings:"gearshape",.teams:"hands.sparkles",.assistant:"person.crop.circle",.memory:"bookmark"][item] ?? "gearshape") { menuOpen=false;panel=item }.accessibilityIdentifier("productPanel-"+item.rawValue) } }
                    }
                    Button { modesOpen.toggle() } label:{ HStack { Image(systemName:modesOpen ? "arrow.left" : mode.symbol);Text(modesOpen ? ProductCopy.data(language)["menu"]["back"].string : mode.title(language));Spacer();if !modesOpen { Image(systemName:"chevron.right") } }.font(PiyaliBrand.productFont(13,600)).padding(18).frame(maxWidth:.infinity,minHeight:64).background(brand.text.opacity(0.04),in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(brand.border) } }.accessibilityIdentifier("productModeMenu")
                }.padding(11).background(brand.surface,in:RoundedRectangle(cornerRadius:24)).overlay { RoundedRectangle(cornerRadius:24).stroke(brand.border) }.frame(width:min(geometry.size.width-24,560)).padding(.bottom,82)
            }
        }.transition(.opacity)
    }
    private func menuTile(_ text:String,symbol:String,selected:Bool=false,action:@escaping()->Void)->some View {
        Button(action:action) { VStack(alignment:.leading,spacing:10) { Image(systemName:symbol).font(.system(size:19)).frame(width:30,height:30).background(brand.surface,in:RoundedRectangle(cornerRadius:8));Text(text).font(PiyaliBrand.productFont(13,600)) }.frame(maxWidth:.infinity,minHeight:84,alignment:.leading).padding(12).background(brand.text.opacity(0.04),in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(selected ? PiyaliBrand.teal : brand.border,lineWidth:selected ? 2 : 1) } }.buttonStyle(.plain)
    }
    @ViewBuilder private func panelContent(_ panel:ProductPanel)->some View {
        switch panel {
        case .settings: AccountView()
        case .teams: TeamsView(service:app.teams)
        case .assistant: AssistantStudyView()
        case .memory: NotebookView()
        case .achievements: AchievementsView()
        case .placement: PlacementView()
        case .goal: DailyGoalManagerView(onClose:{self.panel=nil})
        }
    }
    private func switchMode(_ value:ProductMode) { guided=nil;waitingCelebration=false;celebration=false;saveSession();specialCourse=nil;mode=value;menuOpen=false;revision=UUID() }
    private func startPractice() {
        app.prepareDailyPlate()
        guided=GuidedPracticeSession(account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(Date()),courses:app.plateCourses)
        saveSession();openGuidedSurface()
    }
    private func openGuidedSurface() {
        specialCourse=nil
        switch guided?.current {
        case "goal","repair": specialCourse=guided?.current
        case "learn": mode = .path
        case "review": mode = .cards
        case "phonics": mode = .phonics
        case "conversation": mode = .conversation
        default: mode = .tutor
        }
        revision=UUID()
    }
    private func restoreSession() {
        guard let data=UserDefaults.standard.data(forKey:sessionKey),var saved=try? JSONDecoder().decode(GuidedPracticeSession.self,from:data),saved.matches(account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(now)) else { guided=nil;saveSession();return }
        if saved.taskCompleted(app.plateCourses),!saved.advance(app.plateCourses) { guided=nil;saveSession();return }
        guided=saved
        saveSession()
    }
    private func checkCompletion() {
        guard let guided,guided.matches(account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(Date())),guided.taskCompleted(app.plateCourses) else { return }
        if panel == nil,!menuOpen,!app.lessonActivityActive,app.pendingLessonCompletion == nil,lessonCompletion == nil { waitingCelebration=false;celebration=true } else { waitingCelebration=true }
    }
    private func presentPendingLessonCompletion() {
        guard let pending=app.pendingLessonCompletion else { return }
        guard pending.account == app.identity.npub,pending.target == app.learner.target else { app.pendingLessonCompletion=nil;return }
        guard !app.lessonActivityActive,panel == nil,!menuOpen,lessonCompletion == nil else { return }
        Task { @MainActor in
            try? await Task.sleep(for:.milliseconds(150))
            guard app.pendingLessonCompletion?.id == pending.id,pending.account == app.identity.npub,pending.target == app.learner.target,!app.lessonActivityActive,panel == nil,!menuOpen,lessonCompletion == nil else { return }
            presentedLessonCompletionID=pending.id;lessonCompletion=pending
        }
    }
    private func finishLessonCompletion() {
        if app.pendingLessonCompletion?.id == presentedLessonCompletionID { app.pendingLessonCompletion=nil }
        presentedLessonCompletionID=nil;presentPendingLessonCompletion();checkCompletion()
    }
    private func closeLessonCompletion() { lessonCompletion=nil;finishLessonCompletion() }
    private func saveSession() { if let guided,let data=try? JSONEncoder().encode(guided) { UserDefaults.standard.set(data,forKey:sessionKey) } else { UserDefaults.standard.removeObject(forKey:sessionKey) } }
    private var completion:some View {
        let cleared=app.plateCourses.allSatisfy(\.done)
        return VStack(spacing:24) {
            CompanionArtwork(type:app.learner.effectiveCompanionType).frame(width:96,height:96)
            Text(ProductCopy.text(language,cleared ? "PLATE_CLEARED_COPY" : "PLATE_EXERCISE_COMPLETE_COPY")).font(PiyaliBrand.productFont(28,700)).multilineTextAlignment(.center)
            if cleared { Text("+\(DailyPlate.bonus) XP").font(PiyaliBrand.productFont(40,700)) }
            else if let next=app.plateCourses.first(where:{ !$0.done }) { Text(ProductCopy.text(language,"PLATE_NEXT_COPY")+": "+ProductCopy.course(language,next.kind)) }
            Button(ProductCopy.text(language,"PLATE_CONTINUE_COPY")) {
                celebration=false
                if var next=guided,next.advance(app.plateCourses) { guided=next;saveSession();openGuidedSurface() }
                else { guided=nil;saveSession();specialCourse=nil;mode = .focus;revision=UUID() }
            }.buttonStyle(BrandButtonStyle()).accessibilityIdentifier("guidedContinue")
        }.padding(32).presentationDetents([.medium]).interactiveDismissDisabled()
    }
}
