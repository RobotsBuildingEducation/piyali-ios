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
    @State private var practiceSounds=PracticeSoundPlayer()
    @StateObject private var timer=SessionTimerController()
    @StateObject private var help=HelpChatController()
    @State private var goalOpen=false
    @State private var timerOpen=false
    @State private var timerAwardRevision=UUID()
    @State private var questRetryRevision=UUID()
    @AppStorage("piyali.theme") private var theme="light"
    @State private var firstRun=FirstRunFlow()
    @State private var mode:ProductMode = .focus
    @State private var specialCourse:String?
    @State private var launchTask:Task<Void,Never>?
    @State private var launchID:UUID?
    @State private var activityFooter:ActivityFooterPresentation?
    @State private var menuOpen=false
    @State private var modesOpen=false
    @State private var panel:ProductPanel?
    @State private var memoryInitialTab="repairs"
    @State private var revision=UUID()
    @StateObject private var practice:PlatePracticeController
    @State private var lessonCompletion:LessonCompletionPresentation?
    @State private var presentedLessonCompletionID:UUID?
    private var language:String { app.learner.support }
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    init(now:Date=Date(),practice:PlatePracticeController?=nil){self.now=now;_practice=StateObject(wrappedValue:practice ?? PlatePracticeController())}
    private var presentationKey:String { [String(app.journeyRecording != nil),String(panel != nil),String(menuOpen),String(goalOpen),String(timerOpen),String(timer.session.status == .finished),String(firstRun.step != nil),String(app.goalCheck != nil),String(app.flashcardSession != nil),String(lessonCompletion != nil),String(app.scholarship.visible != nil),String(app.scholarship.pending != nil),String(app.tutorPath != nil)].joined(separator:":") }
    private var firstRunScope:String {app.identity.npub+":"+app.learner.target}
    private var contextKey:String { app.identity.npub+":"+app.learner.target+":"+CalendarDay.key(now) }
    private var timerAwardKey:String {timer.session.account+":"+(timer.pending.first ?? "")+":"+timerAwardRevision.uuidString}
    private var shell:some View {
        ZStack(alignment:.bottom) {
            BrandBackground()
            VStack(spacing:0) {
                ProductTopBar(timer:timer,onGoal:{goalOpen=true},onTimer:{timer.load(account:app.identity.npub);timerOpen=true})
                NavigationStack {
                    surface.navigationBarTitleDisplayMode(.inline)
                        .toolbar(mode == .path || mode == .focus || mode == .cards || mode == .phonics || mode == .tutor ? .hidden:.automatic,for:.navigationBar)
                }.id(revision)
            }.tint(PiyaliBrand.teal).blur(radius:menuOpen ? 6 : 0).allowsHitTesting(!menuOpen)
                .safeAreaInset(edge:.bottom) { if activityFooter == nil,app.achievementUnlock.current == nil { menuButton(compact:false).padding(.bottom,10) } }
                .overlay(alignment:.bottom) {
                    if activityFooter != nil || app.achievementUnlock.current != nil {
                        ZStack(alignment:.bottomLeading) {
                            Group{if let unlock=app.achievementUnlock.current{AchievementActionContent(unlock:unlock,language:language,onDismiss:{app.dismissAchievement(unlock.id)})}else if let footer=activityFooter{footer.content.id(footer.owner)}}
                                .padding(12).background{SourceActivityDockBackground(correct:app.achievementUnlock.current == nil ? activityFooter?.correct:nil,achievement:app.achievementUnlock.current != nil,tone:app.achievementUnlock.current == nil ? activityFooter?.tone:nil)}.padding(.horizontal,8).padding(.bottom,12)
                            HStack{menuButton(compact:true);Spacer(minLength:0)}.frame(height:app.achievementUnlock.current == nil ? 40:44).padding(.leading,20).padding(.bottom,24).environment(\.layoutDirection,.leftToRight)
                        }.onGeometryChange(for:CGFloat.self,of:{ $0.size.height }) { app.activityFooterHeight=$0 }
                    }

                }
            if menuOpen { menu }
        }.font(PiyaliBrand.productFont(16)).foregroundStyle(brand.text)
            .accessibilityElement(children:.contain).accessibilityHidden(app.tutorPath != nil || panel == .memory || panel == .settings || panel == .assistant || panel == .teams || panel == .achievements || app.journeyRecording != nil || app.flashcardSession != nil || app.goalCheck != nil || lessonCompletion != nil || firstRun.step != nil || goalOpen || timerOpen || timer.session.status == .finished || practice.visible != nil || practice.dailyGoalVisible != nil || app.scholarship.visible != nil)
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
                        if step == .paperPencil {PaperPencilView(onClose:closeFirstRun)}
                        else if step == .gettingStarted {GettingStartedView(onClose:closeFirstRun)}
                        else {PlacementView(overlay:true,onClose:{firstRun.close()})}
                    }.accessibilityElement(children:.contain).accessibilityIdentifier("firstRunDialog")
                }
            }
            .onChange(of:firstRunScope) {_,scope in firstRun.reconcile(scope:scope);if let p=app.journeyRecording,p.account+":"+p.target != scope{p.controller.close();app.journeyRecording=nil}}
            .preferredColorScheme(theme == "dark" ? .dark : .light)
            .environment(\.layoutDirection,language == "ar" ? .rightToLeft : .leftToRight)
    }
    private var presentedShell:some View {
        shell
            .overlay{if let path=app.tutorPath,path.account == app.identity.npub,path.target == app.learner.target{TutorSourcePathView(tutor:path.tutor,onClose:{app.tutorPath=nil}).accessibilityHidden(practice.dailyGoalVisible != nil || practice.visible != nil || app.scholarship.visible != nil)}}
            .overlay{if let session=app.flashcardSession{FlashcardPracticeDialog(session:session)}}
            .overlay{if let goalCheck=app.goalCheck {GoalCheckDialog(presentation:goalCheck)}}
            .overlay{if goalOpen{DailyGoalManagerView(onClose:{goalOpen=false}).accessibilityHidden(timerOpen || timer.session.status == .finished)}}
            .overlay{if timerOpen{SessionTimerView(timer:timer,language:language,onClose:{timerOpen=false}).accessibilityHidden(timer.session.status == .finished)}}
            .overlay{if timer.session.status == .finished,practice.visible == nil,firstRun.step == nil,lessonCompletion == nil,panel == nil,app.goalCheck == nil{SessionTimeUpView(minutes:timer.session.duration/60,language:language,onClose:timer.clear,onRestart:{timer.clear();timerOpen=true})}}
            .environment(\.layoutDirection,language == "ar" ? .rightToLeft : .leftToRight)
    }
    private var timedShell:some View {
        presentedShell
            .task(id:app.companionQuestPreparationKey+questRetryRevision.uuidString){await app.prepareCompanionQuest()}
            .task(id:timerAwardKey){
                let account=timer.session.account
                guard account==app.identity.npub,let id=timer.pending.first else{return}
                do{try await FirebaseService.shared.recordSessionTimer(npub:account,id:id);try Task.checkCancellation();timer.acknowledge(id,account:account)}catch{}
            }
            .onChange(of:scenePhase){_,value in if value == .active{timer.refresh();timerAwardRevision=UUID();questRetryRevision=UUID()}}
            .onChange(of:app.syncStatus){_,value in if value == "Synced with Firebase"{timerAwardRevision=UUID()}}
            .onChange(of:app.identity.npub){_,_ in goalOpen=false;timerOpen=false;timer.load(account:app.identity.npub)}
            .onChange(of:timer.session.status){_,value in if value == .finished{UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to:nil,from:nil,for:nil)}}
            .sheet(item:Binding(get:{panel == .memory || panel == .settings || panel == .assistant || panel == .teams || panel == .achievements ? nil:panel},set:{panel=$0})) { selected in NavigationStack { panelContent(selected).toolbar { ToolbarItem(placement:.confirmationAction) { Button(EntryCopy.text(language,"back_button")) { panel=nil }.accessibilityIdentifier("productPanelClose") } } }.tint(PiyaliBrand.teal) }
            .fullScreenCover(item:Binding(get:{panel == .achievements ? panel:nil},set:{if $0 == nil,panel == .achievements{panel=nil}})){_ in AchievementsView(onClose:{panel=nil}).presentationBackground(.clear)}
            .overlay{if panel == .assistant{HelpChatView(controller:help,onClose:{panel=nil})}}
            .overlay{if panel == .teams{TeamsDrawerView(service:app.teams,onClose:{panel=nil})}}
            .overlay {if let reward=practice.dailyGoalVisible{DailyGoalCelebrationView(reward:reward,onContinue:{practice.closeDailyGoal(app)})}}
            .overlay {if let data=practice.visible {PlateCelebrationView(data:data,language:language,onContinue:{practice.continuePractice(app,ephemeralLesson:specialCourse != nil && mode == .path)},onNotes:{practice.continuePractice(app,viewNotes:true,ephemeralLesson:specialCourse != nil && mode == .path)}).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight)}}
    }
    private var memoryShell:some View {timedShell.overlay{if panel == .settings{SettingsDrawerView(onClose:{panel=nil},onPlacement:{panel = .placement})}}.overlay{if panel == .memory{MemoryDrawerView(onClose:{panel=nil},initialTab:memoryInitialTab).accessibilityHidden(app.journeyRecording != nil)}}.overlay{if let p=app.journeyRecording,p.account == app.identity.npub,p.target == app.learner.target{JourneyRecordingView(journey:p.controller,milestone:p.milestone,onClose:{app.journeyRecording=nil},onOpenJourney:{app.journeyRecording=nil;memoryInitialTab="journey";panel = .memory})}}}
    private var journeyCanPresent:Bool {app.tutorPath == nil && app.companionUnlock == nil && app.signedIn && app.learner.onboardingComplete && !app.loadingContent && panel == nil && !menuOpen && !goalOpen && !timerOpen && timer.session.status != .finished && firstRun.step == nil && app.journeyRecording == nil && app.goalCheck == nil && app.flashcardSession == nil && lessonCompletion == nil && app.pendingLessonCompletion == nil && practice.visible == nil && practice.pending == nil && practice.dailyGoalVisible == nil && app.dailyGoalReward == nil && !app.lessonActivityActive && !app.hasEarnedPractice(excluding:practice.owner) && launchID == nil && app.scholarship.visible == nil}
    private var sessionShell:some View {
        memoryShell
            .background{JourneyMilestoneGateView(canPresent:journeyCanPresent && app.scholarship.pending == nil){controller,n in app.journeyRecording = .init(controller:controller,milestone:n,account:app.identity.npub,target:app.learner.target)}}
            .task(id:contextKey) {
                timer.load(account:app.identity.npub)
                if app.learner.dailyKey != CalendarDay.key(now) { app.learner.rollDay(now:now);app.persist() }
                app.prepareDailyPlate()
                if let guided=practice.guided,!guided.matches(account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(now)){specialCourse=nil}
                configurePractice()
                practice.bind(app)
                presentPendingLessonCompletion()
            }
    }
    private var goalCoordinatedShell:some View {
        sessionShell
            .onChange(of:app.flashcardSession?.id){_,id in if id == nil {presentPendingLessonCompletion();updatePracticePresentation()}}
            .onChange(of:app.goalCheck?.id){_,value in if value == nil {presentPendingLessonCompletion();updatePracticePresentation()}}
            .onChange(of:app.goalCourseScope,goalScopeChanged)
            .onDisappear{cancelPracticeLaunch();practice.unbind();practiceSounds.stop()}
            .onChange(of:app.readyGoal?["modeProgress"]){_,_ in if let check=app.goalCheck,let daily=app.readyGoal,let next=GoalPractice.nextMode(daily),next != check.blueprint["mode"].string {app.goalCheck=nil}}
            .onChange(of:goalOpen){_,open in if !open {presentPendingLessonCompletion();updatePracticePresentation()}}
            .onChange(of:timerOpen){_,open in if !open {presentPendingLessonCompletion();updatePracticePresentation()}}
            .onChange(of:timer.session.status){_,status in if status != .finished {presentPendingLessonCompletion();updatePracticePresentation()}}
            .onChange(of:firstRun.step){_,step in if step == nil {presentPendingLessonCompletion();updatePracticePresentation()}}
    }
    private var scholarshipCanPresent:Bool{app.tutorPath == nil && app.companionUnlock == nil && app.signedIn && app.learner.onboardingComplete && panel == nil && !menuOpen && !goalOpen && !timerOpen && timer.session.status != .finished && firstRun.step == nil && app.journeyRecording == nil && app.goalCheck == nil && app.flashcardSession == nil && lessonCompletion == nil && app.pendingLessonCompletion == nil && practice.visible == nil && practice.dailyGoalVisible == nil && app.dailyGoalReward == nil && !app.lessonActivityActive && !app.hasEarnedPractice(excluding:practice.owner) && launchID == nil && app.scholarship.visible == nil}
    private var scholarshipGateKey:String{[firstRunScope,String(scholarshipCanPresent),String(app.scholarshipSeen),app.scholarship.pending?.account ?? "",app.scholarship.pending?.target ?? ""].joined(separator:":")}
    private var companionUnlockBlocked:Bool{app.tutorPath != nil || !app.signedIn || !app.learner.onboardingComplete || !app.subscription.hasAccess || panel != nil || menuOpen || goalOpen || timerOpen || timer.session.status == .finished || firstRun.step != nil || app.journeyRecording != nil || app.goalCheck != nil || app.flashcardSession != nil || lessonCompletion != nil || app.pendingLessonCompletion != nil || practice.visible != nil || practice.pending != nil || practice.dailyGoalVisible != nil || app.dailyGoalReward != nil || app.scholarship.visible != nil || app.scholarship.pending != nil}
    var body:some View {
        goalCoordinatedShell
            .overlay{if app.scholarship.visible != nil{WalletView(scholarship:true,onDismiss:app.dismissScholarship)}}
            .task(id:scholarshipGateKey){
                app.scholarship.reconcile(account:app.identity.npub,target:app.learner.target,seen:app.scholarshipSeen)
                guard app.scholarship.pending != nil,scholarshipCanPresent else{return}
                do{try await Task.sleep(for:.milliseconds(160));try Task.checkCancellation();app.scholarship.present(account:app.identity.npub,target:app.learner.target,seen:app.scholarshipSeen,blocked:!scholarshipCanPresent)}catch{}
            }
            .background{CompanionUnlockGateView(blocked:{companionUnlockBlocked},onShow:{practiceSounds.play("companionUnlock",enabled:app.learner.soundEffectsEnabled,volume:app.learner.settingsSnapshot["soundVolume"] == .null ? 100:app.learner.settingsSnapshot["soundVolume"].number)})}
            .accessibilityHidden(app.companionUnlock != nil).allowsHitTesting(app.companionUnlock == nil)
            .overlay{if let item=app.companionUnlock{CompanionUnlockView(item:item,language:language,onEquip:{app.finishCompanionUnlock(item,equip:true)},onKeep:{app.finishCompanionUnlock(item,equip:false)})}}
            // The value publisher replays a footer created while NavigationStack is mounting.
            .onReceive(app.$activityFooter) { footer in activityFooter=footer;if footer == nil,app.achievementUnlock.current == nil {app.activityFooterHeight=0} }
            .onChange(of:app.learner.target) { _,_ in revision=UUID() }
            .onChange(of:app.localPracticeRevision) { _,_ in updatePracticePresentation() }
            .onChange(of:app.companionUnlock?.id){_,value in updatePracticePresentation();if value == nil{presentPendingLessonCompletion()}}
            .onChange(of:panel) { _,value in if value == nil { memoryInitialTab="repairs";practice.closeNotes(app);presentPendingLessonCompletion();updatePracticePresentation() } }
            .onChange(of:menuOpen) { _,open in if !open { presentPendingLessonCompletion();updatePracticePresentation() } }
            .onChange(of:app.pendingLessonCompletion?.id) { _,_ in presentPendingLessonCompletion() }
            .onChange(of:practice.visible){_,value in if value == nil{presentPendingLessonCompletion()}}
            .onChange(of:practice.dailyGoalVisible?.id){_,value in if value == nil{presentPendingLessonCompletion()}}
            .onChange(of:presentationKey){_,_ in updatePracticePresentation()}
            .onChange(of:app.lessonActivityActive) { _,active in if !active { presentPendingLessonCompletion();updatePracticePresentation() } }
    }
    private func goalScopeChanged(_ old:GoalCourseScope,_ scope:GoalCourseScope) {
        if old != scope {cancelPracticeLaunch();app.scholarship.reconcile(account:scope.account,target:scope.target,seen:app.scholarshipSeen)}
        if let session=app.flashcardSession,!session.matches(app){session.close(app,abandoned:false)}
        if let check=app.goalCheck,check.scope != scope {app.goalCheck=nil}
        if specialCourse == "goal",old.account != scope.account || old.target != scope.target || old.goalID != scope.goalID || old.day != scope.day {
            specialCourse=nil;mode = .focus;practice.cancel(app);revision=UUID()
        }
    }
    private func closeFirstRun() {
        if firstRun.step == .paperPencil {
            if firstRun.acknowledgePaper(scope:firstRunScope,shown:app.learner.gettingStartedModalShown == true,hasPlacement:app.learner.hasFirstRunPlacement){app.acknowledgeFirstRun(.paperPencil);let account=app.identity.npub;Task{try? await Task.sleep(for:.milliseconds(32));guard app.signedIn,app.identity.npub == account,scenePhase == .active else{return};if app.learner.soundEffectsEnabled{UIImpactFeedbackGenerator(style:.light).impactOccurred()};practiceSounds.play("submitAction",enabled:app.learner.soundEffectsEnabled,volume:app.learner.settingsSnapshot["soundVolume"] == .null ? 100:app.learner.settingsSnapshot["soundVolume"].number)}}
        } else if firstRun.step == .gettingStarted {
            if firstRun.acknowledge(scope:firstRunScope,hasPlacement:app.learner.hasFirstRunPlacement) {app.acknowledgeFirstRun(.gettingStarted)}
        } else {firstRun.close()}
    }
    private func menuButton(compact:Bool)->some View {
        Button { modesOpen=false;menuOpen.toggle() } label:{ SourceActivityMenuGlyph().frame(width:compact ? (app.achievementUnlock.current == nil ? 18:22):20,height:compact ? (app.achievementUnlock.current == nil ? 18:22):20).foregroundStyle(brand.text).frame(width:compact ? (app.achievementUnlock.current == nil ? 40:44):58,height:compact ? (app.achievementUnlock.current == nil ? 40:44):58).background(brand.surface.opacity(compact && app.achievementUnlock.current != nil ? 0:0.92),in:RoundedRectangle(cornerRadius:compact ? 14 : 20)).overlay { RoundedRectangle(cornerRadius:compact ? 14 : 20).stroke(brand.border.opacity(compact && app.achievementUnlock.current != nil ? 0:1)) } }.accessibilityLabel(mode.title(language)).accessibilityIdentifier("productMenu").accessibilityHidden(panel != nil).allowsHitTesting(panel == nil).disabled(panel != nil)
    }
    @ViewBuilder private var surface:some View {
        if specialCourse == "goal" {FocusedGoalCourseView(onSurface:{mode=$0})}
        else if specialCourse == "repair" { RepairPracticeView(onSurface:{mode=$0}) }
        else { switch mode {
        case .focus: TodayFocusHomeView(now:now,sessionActive:practice.guided != nil,startingPractice:launchID != nil,onStart:startPractice,onPanel:{ panel=$0 },onCompanionContinue:{firstRun.request(scope:firstRunScope,shown:app.learner.gettingStartedModalShown == true,paperShown:app.learner.paperPencilModalShown == true,hasPlacement:app.learner.hasFirstRunPlacement)})
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
                        else { ForEach([ProductPanel.settings,.teams,.assistant,.memory]) { item in menuTile(ProductCopy.data(language)["menu"][item.rawValue].string,symbol:[.settings:"gearshape",.teams:"hands.sparkles",.assistant:"person.crop.circle",.memory:"bookmark"][item] ?? "gearshape") { menuOpen=false;memoryInitialTab="repairs";panel=item }.accessibilityIdentifier("productPanel-"+item.rawValue) } }
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
        case .assistant: EmptyView()
        case .memory: MemoryDrawerView(onClose:{self.panel=nil})
        case .achievements: AchievementsView()
        case .placement: PlacementView()
        case .goal: DailyGoalManagerView(onClose:{self.panel=nil})
        }
    }
    private func switchMode(_ value:ProductMode) { cancelPracticeLaunch();practice.cancel(app);specialCourse=nil;mode=value;menuOpen=false;revision=UUID() }
    private func configurePractice(){
                practice.onNavigate={openPlateCourse($0)}
                practice.onHome={specialCourse=nil;mode = .focus;revision=UUID()}
                practice.onNotes={panel = .memory}
                practice.onSound={practiceSounds.play($0,enabled:app.learner.soundEffectsEnabled)}
    }
    private func startPractice() {
        guard launchID == nil else{return}
        app.prepareDailyPlate();configurePractice()
        practice.start(app)
    }
    private func cancelPracticeLaunch(){launchTask?.cancel();launchTask=nil;launchID=nil}
    private func openPlateCourse(_ kind:String) {
        cancelPracticeLaunch()
        if kind == "goal",app.subscription.hasAccess {
            let id=UUID(),scope=app.goalCourseScope;launchID=id
            launchTask=Task { @MainActor in
                defer{if launchID == id {launchTask=nil;launchID=nil}}
                do {
                    try await app.prepareGoal();try Task.checkCancellation()
                    guard launchID == id,app.goalCourseScope == scope else{return}
                    specialCourse="goal";revision=UUID()
                }catch is CancellationError{}catch{if launchID == id {app.error=error.localizedDescription}}
            }
            return
        }
        specialCourse=nil
        switch kind {
        case "goal","repair": specialCourse=kind
        case "learn": mode = .path
        case "review": mode = .cards
        case "phonics": mode = .phonics
        case "conversation": mode = .conversation
        default: mode = .tutor
        }
        revision=UUID()
    }
    private var canPresentPracticeModal:Bool {app.companionUnlock == nil && panel == nil && !menuOpen && !goalOpen && !timerOpen && timer.session.status != .finished && firstRun.step == nil && app.goalCheck == nil && app.flashcardSession == nil && lessonCompletion == nil && practice.visible == nil && app.dailyGoalReward == nil && app.scholarship.visible == nil}
    private func updatePracticePresentation(){practice.presentationBlocked(app.companionUnlock != nil || panel != nil || menuOpen || goalOpen || timerOpen || timer.session.status == .finished || firstRun.step != nil || lessonCompletion != nil || app.scholarship.visible != nil,app:app)}
    private func presentPendingLessonCompletion() {
        guard let pending=app.pendingLessonCompletion else { return }
        guard pending.account == app.identity.npub,pending.target == app.learner.target else { app.pendingLessonCompletion=nil;return }
        guard !app.lessonActivityActive,canPresentPracticeModal else { return }
        Task { @MainActor in
            try? await Task.sleep(for:.milliseconds(150))
            guard app.pendingLessonCompletion?.id == pending.id,pending.account == app.identity.npub,pending.target == app.learner.target,!app.lessonActivityActive,canPresentPracticeModal else { return }
            presentedLessonCompletionID=pending.id;lessonCompletion=pending
        }
    }
    private func finishLessonCompletion() {
        if app.pendingLessonCompletion?.id == presentedLessonCompletionID { app.pendingLessonCompletion=nil }
        presentedLessonCompletionID=nil;presentPendingLessonCompletion();updatePracticePresentation()
    }
    private func closeLessonCompletion() { lessonCompletion=nil;finishLessonCompletion() }
}
