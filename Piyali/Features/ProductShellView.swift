import SwiftUI

enum ProductMode:String,CaseIterable {
    case focus,path,cards,phonics,conversation,tutor
    var menuIcon:String { "ProductMenu-"+rawValue }
    static func menuModes(target:String)->[Self] {
        let phonicsTargets:Set<String>=["ru","ja","en","es","pt","fr","it","nl","de","nah","el","pl","ga","yua"]
        return allCases.filter { $0 != .phonics || phonicsTargets.contains(target) }
    }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    @State private var focusedCourse:FocusedCourseRoute?
    @State private var boundPracticeContext:PracticeContext?
    @State private var launchTask:Task<Void,Never>?
    @State private var launchID:UUID?
    @State private var activityFooter:ActivityFooterPresentation?
    @State private var menuOpen=false
    @State private var modesOpen=false
    @GestureState private var menuDrag:CGFloat=0
    @State private var panel:ProductPanel?
    @State private var memoryInitialTab="repairs"
    @State private var revision=UUID()
    @State private var lessonScrollRequest:UUID?
    @StateObject private var practice:PlatePracticeController
    @State private var lessonCompletion:LessonCompletionPresentation?
    @State private var presentedLessonCompletionID:UUID?
    private var language:String { app.learner.support }
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    init(now:Date=Date(),practice:PlatePracticeController?=nil){self.now=now;_practice=StateObject(wrappedValue:practice ?? PlatePracticeController())}
    private var presentationKey:String { [String(app.journeyRecording != nil),String(panel != nil),String(menuOpen),String(goalOpen),String(timerOpen),String(timer.session.status == .finished),String(firstRun.step != nil),String(app.goalCheck != nil),String(app.flashcardSession != nil),String(lessonCompletion != nil),String(app.scholarship.visible != nil),String(app.scholarship.pending != nil),String(app.tutorPath != nil)].joined(separator:":") }
    private var firstRunScope:String {app.identity.npub+":"+app.learner.target}
    private struct PracticeContext:Equatable {
        let account,target,day:String
    }
    private struct FocusedCourseRoute {
        let kind:String
        let context:PracticeContext
    }
    private var practiceContext:PracticeContext {
        .init(account:app.identity.npub,target:app.learner.target,day:CalendarDay.key(now))
    }
    private var specialCourse:String? {
        get { focusedCourse?.context == practiceContext ? focusedCourse?.kind:nil }
        nonmutating set { focusedCourse=newValue.map { FocusedCourseRoute(kind:$0,context:practiceContext) } }
    }
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
            }.tint(PiyaliBrand.teal).blur(radius:menuOpen ? 8 : 0).allowsHitTesting(!menuOpen)
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
                    LessonCompletionView(completion:data,onContinue:closeLessonCompletion).id(data.id)
                }
            }
            .overlay {
                if let step=firstRun.step {
                    Group{if step == .paperPencil {PaperPencilDialog(onClose:closeFirstRun)}else{ZStack {
                        (scheme == .dark ? Color(red:2/255,green:6/255,blue:23/255).opacity(0.92) : Color(red:28/255,green:20/255,blue:12/255).opacity(0.82)).ignoresSafeArea()
                        if step == .gettingStarted {GettingStartedView(onClose:closeFirstRun)}
                        else {PlacementView(overlay:true,onClose:{firstRun.close()},dismissible:false)}
                    }}}.accessibilityElement(children:.contain).accessibilityIdentifier("firstRunDialog")
                }
            }
            .onChange(of:firstRunScope) {_,scope in
                firstRun.reconcile(scope:scope)
                if let p=app.journeyRecording,p.account+":"+p.target != scope{p.controller.close();app.journeyRecording=nil}
                if let completion=lessonCompletion,completion.account+":"+completion.target != scope{closeLessonCompletion()}
            }
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
            .overlay{if panel == .teams{TeamsDrawerView(app:app,onClose:{panel=nil})}}
            .overlay {if let reward=practice.dailyGoalVisible{DailyGoalCelebrationView(reward:reward,onContinue:{practice.closeDailyGoal(app)})}}
            .overlay {if let data=practice.visible {PlateCelebrationView(data:data,language:language,onContinue:{practice.continuePractice(app,ephemeralLesson:specialCourse != nil && mode == .path)},onNotes:{practice.continuePractice(app,viewNotes:true,ephemeralLesson:specialCourse != nil && mode == .path)}).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight)}}
    }
    private var memoryShell:some View {timedShell.overlay{if panel == .settings{SettingsDrawerView(onClose:{panel=nil},onPlacement:{panel = .placement})}}.overlay{if panel == .memory{MemoryDrawerView(onClose:{panel=nil},initialTab:memoryInitialTab).accessibilityHidden(app.journeyRecording != nil)}}.overlay{if let p=app.journeyRecording,p.account == app.identity.npub,p.target == app.learner.target{JourneyRecordingView(journey:p.controller,milestone:p.milestone,onClose:{app.journeyRecording=nil},onOpenJourney:{app.journeyRecording=nil;memoryInitialTab="journey";panel = .memory})}}}
    private var journeyCanPresent:Bool {app.tutorPath == nil && app.companionUnlock == nil && app.signedIn && app.learner.onboardingComplete && !app.loadingContent && panel == nil && !menuOpen && !goalOpen && !timerOpen && timer.session.status != .finished && firstRun.step == nil && app.journeyRecording == nil && app.goalCheck == nil && app.flashcardSession == nil && lessonCompletion == nil && app.pendingLessonCompletion == nil && practice.visible == nil && practice.pending == nil && practice.dailyGoalVisible == nil && app.dailyGoalReward == nil && !app.lessonActivityActive && !app.hasEarnedPractice(excluding:practice.owner) && launchID == nil && app.scholarship.visible == nil}
    private var sessionShell:some View {
        memoryShell
            .background{JourneyMilestoneGateView(subscription:app.subscription,canPresent:journeyCanPresent && app.scholarship.pending == nil){controller,n in app.journeyRecording = .init(controller:controller,milestone:n,account:app.identity.npub,target:app.learner.target)}}
            .task(id:practiceContext) {
                let context=practiceContext,refresh=Date()
                guard context.day == CalendarDay.key(refresh) else {return}
                if let previous=boundPracticeContext,previous != context {
                    cancelPracticeLaunch()
                    if focusedCourse != nil,specialCourse == nil {
                        focusedCourse=nil;mode = .focus;revision=UUID()
                    }
                }
                boundPracticeContext=context
                timer.load(account:context.account)
                if app.learner.dailyKey != context.day {app.learner.rollDay(now:refresh);app.persist()}
                app.prepareDailyPlate(now:refresh)
                configurePractice()
                practice.bind(app)
                restorePendingFocusedTutor()
                presentPendingLessonCompletion()
            }
    }
    private var goalCoordinatedShell:some View {
        sessionShell
            .onChange(of:app.flashcardSession?.id){_,id in if id == nil {presentPendingLessonCompletion();updatePracticePresentation()}}
            .onChange(of:app.goalCheck?.id){_,value in if value == nil {presentPendingLessonCompletion();updatePracticePresentation()}}
            .onChange(of:app.goalCourseScope,goalScopeChanged)
            .onChange(of:app.subscription.hasAccess){_,allowed in if !allowed{restorePendingFocusedTutor()}}
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
            .onChange(of:app.learner.target) { _,_ in switchMode(.focus) }
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
            if firstRun.acknowledgePaper(scope:firstRunScope,shown:app.learner.gettingStartedModalShown == true,hasPlacement:app.learner.hasFirstRunPlacement){app.acknowledgeFirstRun(.paperPencil)}
        } else if firstRun.step == .gettingStarted {
            if firstRun.acknowledge(scope:firstRunScope,hasPlacement:app.learner.hasFirstRunPlacement) {app.acknowledgeFirstRun(.gettingStarted)}
        } else {firstRun.close()}
    }
    private func menuButton(compact:Bool)->some View {
        TeamInviteMenuButton(startup:app.teamsStartup,capture:app.memoryCapture,scope:app.memoryCaptureScope,language:language,label:mode.title(language),glyphSize:compact ? (app.achievementUnlock.current == nil ? 18:22):22,size:compact ? (app.achievementUnlock.current == nil ? 40:44):66,radius:compact ? 14:40,background:brand.surface.opacity(compact && app.achievementUnlock.current != nil ? 0:0.92),border:brand.border.opacity(compact && app.achievementUnlock.current != nil ? 0:1),foreground:brand.text,dotBorder:compact ? brand.surface:brand.background,standalone:!compact,action:{modesOpen=false;menuOpen.toggle()}).accessibilityHidden(panel != nil).allowsHitTesting(panel == nil).disabled(panel != nil)
    }
    @ViewBuilder private var surface:some View {
        if specialCourse == "goal" {FocusedGoalCourseView(onSurface:{mode=$0})}
        else if specialCourse == "repair" { RepairPracticeView(onSurface:{mode=$0}) }
        else if focusedCourse != nil { focusHome }
        else { switch mode {
        case .focus: focusHome
        case .path: LessonPathView(scrollRequest:lessonScrollRequest)
        case .cards: FlashcardsView()
        case .phonics: PhonicsView()
        case .conversation: ConversationView()
        case .tutor: TutorLibraryView()
        } }
    }
    private var focusHome:some View {
        TodayFocusHomeView(now:now,sessionActive:practice.guided?.matches(account:practiceContext.account,target:practiceContext.target,day:practiceContext.day) == true,startingPractice:launchID != nil,onStart:startPractice,onPanel:{panel=$0},onCompanionContinue:{
            firstRun.request(scope:firstRunScope,shown:app.learner.gettingStartedModalShown == true,paperShown:app.learner.paperPencilModalShown == true,hasPlacement:app.learner.hasFirstRunPlacement)
        })
    }
    private var menu:some View {
        GeometryReader { geometry in
            ZStack(alignment:.bottom) {
                PiyaliBrand.unitColor(brand.dark ? "020617":"f7f1e7")
                    .opacity((brand.dark ? 0.55:0.45)*max(0.1,1-menuDrag/240))
                    .ignoresSafeArea().onTapGesture { dismissMenu() }.accessibilityHidden(true)
                VStack(spacing:8) {
                    menuHandle
                    ScrollView {
                        VStack(spacing:8) {
                            if modesOpen { menuModeTiles } else { menuActionTiles }
                            menuPageButton
                        }
                    }.scrollBounceBehavior(.basedOnSize)
                        .frame(height:min(modesOpen ? 394:284,max(0,geometry.size.height-170)))
                }
                .padding(.horizontal,12).padding(.top,8).padding(.bottom,10)
                .background(brand.surface,in:RoundedRectangle(cornerRadius:24))
                .overlay { RoundedRectangle(cornerRadius:24).strokeBorder(menuEdge,lineWidth:2) }
                .shadow(color:brand.dark ? .black.opacity(0.28):PiyaliBrand.unitColor("6f5636").opacity(0.08),radius:brand.dark ? 28:9,y:brand.dark ? 16:8)
                .frame(width:min(max(0,geometry.size.width-24),420))
                .padding(.bottom,82)
                .offset(y:menuDrag).opacity(max(0.15,1-menuDrag/320))
            }
        }.transition(.opacity)
    }
    private var menuBeige:Color { PiyaliBrand.unitColor("b4a490") }
    private var menuEdge:Color { brand.dark ? PiyaliBrand.unitColor("94a3b8").opacity(0.34):menuBeige.opacity(0.65) }
    private var menuTileFill:Color { brand.dark ? .white.opacity(0.04):PiyaliBrand.unitColor("ebe2d6").opacity(0.5) }
    private var menuTileBorder:Color { brand.dark ? brand.border:menuBeige.opacity(0.4) }
    private var menuColumns:[GridItem] { [GridItem(.flexible(),spacing:8),GridItem(.flexible())] }
    private var menuHandle:some View {
        Capsule().fill(brand.dark ? .white.opacity(0.24):menuBeige.opacity(0.55))
            .accessibilityHidden(true)
            .frame(width:48,height:5)
            .frame(maxWidth:.infinity,minHeight:32)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance:6)
                .updating($menuDrag) { value,offset,_ in
                    let distance=value.translation.height
                    guard distance > abs(value.translation.width) else { return }
                    offset=distance <= 150 ? distance:150+(distance-150)*0.55
                }
                .onEnded { value in
                    let distance=value.translation.height
                    guard distance > abs(value.translation.width) else { return }
                    if distance > 30 || value.predictedEndTranslation.height > 65 { dismissMenu() }
                })
            .overlay(alignment:.trailing) {
                Button(action:dismissMenu) {
                    Image(systemName:"xmark").font(.system(size:13,weight:.medium))
                        .foregroundStyle(brand.muted).frame(width:32,height:32).contentShape(Rectangle())
                }.buttonStyle(.plain).padding(.trailing,4)
                    .accessibilityLabel(ProductCopy.data(language)["menu"]["closeMenu"].string)
                    .accessibilityIdentifier("productMenuClose")
            }.environment(\.layoutDirection,.leftToRight)
            .padding(.top,6).padding(.bottom,14)
    }
    private func dismissMenu() {
        withAnimation(reduceMotion ? nil:.easeOut(duration:0.18)) { menuOpen=false }
    }
    private var menuModeTiles:some View {
        let modes=ProductMode.menuModes(target:app.learner.target)
        let extra=modes.count % 2
        return VStack(spacing:8) {
            LazyVGrid(columns:menuColumns,spacing:8) {
                ForEach(modes.dropLast(extra),id:\.self,content:menuModeTile)
            }
            if extra == 1,let last=modes.last { menuModeTile(last) }
        }
    }
    private func menuModeTile(_ item:ProductMode)->some View {
        menuTile(item.title(language),icon:item.menuIcon,selected:item == mode) { switchMode(item) }
            .accessibilityIdentifier("productMode-"+item.rawValue)
    }
    private var menuActionTiles:some View {
        LazyVGrid(columns:menuColumns,spacing:8) {
            ForEach([ProductPanel.settings,.teams,.assistant,.memory]) { item in
                MemoryCaptureMenuItem(capture:app.memoryCapture,scope:app.memoryCaptureScope) { captured in
                    let icons:[ProductPanel:String]=[.settings:"ProductMenu-settings",.teams:"Teams-menu",.assistant:"ProductMenu-help",.memory:"Practice-RiBookmarkLine"]
                    return menuTile(ProductCopy.data(language)["menu"][item.rawValue].string,icon:icons[item] ?? "",memoryCaptured:item == .memory && captured,teamInvite:item == .teams) {
                        menuOpen=false;memoryInitialTab="repairs";panel=item
                    }
                }.accessibilityIdentifier("productPanel-"+item.rawValue)
            }
        }
    }
    private var menuPageButton:some View {
        Button { modesOpen.toggle() } label:{
            HStack(spacing:10) {
                if modesOpen {
                    menuIconPlate { Image(systemName:"arrow.left").font(.system(size:14,weight:.semibold)) }
                } else {
                    menuIconPlate { menuArt(mode.menuIcon) }
                }
                Text(modesOpen ? ProductCopy.data(language)["menu"]["back"].string:mode.title(language))
                    .font(PiyaliBrand.productFont(13,600)).lineLimit(1)
                Spacer(minLength:0)
                if !modesOpen { Image(systemName:"chevron.right").font(.system(size:12,weight:.semibold)) }
            }.padding(.horizontal,14).padding(.vertical,12).frame(maxWidth:.infinity,minHeight:64)
                .background(menuTileFill,in:RoundedRectangle(cornerRadius:18))
                .overlay { RoundedRectangle(cornerRadius:18).strokeBorder(menuTileBorder) }
        }.buttonStyle(.plain).accessibilityIdentifier("productModeMenu")
    }
    private func menuArt(_ name:String)->some View {
        Image(name).resizable().renderingMode(.template).scaledToFit().frame(width:16,height:16)
    }
    private func menuIconPlate<Icon:View>(captured:Bool=false,@ViewBuilder icon:()->Icon)->some View {
        icon().foregroundStyle(captured ? .white:brand.text)
            .frame(width:30,height:30)
            .background(captured ? PiyaliBrand.unitColor("38b2ac") : brand.dark ? PiyaliBrand.unitColor("1a202c"):PiyaliBrand.unitColor("ebe2d6").opacity(0.9),in:RoundedRectangle(cornerRadius:10))
            .overlay { RoundedRectangle(cornerRadius:10).strokeBorder(brand.dark ? .white.opacity(0.12):menuBeige.opacity(0.5)) }
            .shadow(color:brand.dark ? PiyaliBrand.unitColor("313a4b"):menuBeige.opacity(0.9),radius:0,y:2)
            .frame(width:38,height:38)
    }
    private func menuTile(_ text:String,icon:String,selected:Bool=false,memoryCaptured:Bool=false,teamInvite:Bool=false,action:@escaping()->Void)->some View {
        Button(action:action) {
            VStack(alignment:.leading,spacing:4) {
                menuIconPlate(captured:memoryCaptured) {
                    menuArt(memoryCaptured ? "Memory-captured":icon)
                        .overlay(alignment:.topTrailing) {
                            if teamInvite { TeamInviteDot(startup:app.teamsStartup,border:brand.surface).offset(x:5,y:-4) }
                        }
                }
                Text(text).font(PiyaliBrand.productFont(13,selected ? 700:600)).lineLimit(2)
            }.foregroundStyle(brand.text).padding(14)
                .frame(maxWidth:.infinity,minHeight:102,alignment:.bottomLeading)
                .background(menuTileFill,in:RoundedRectangle(cornerRadius:18))
                .overlay { RoundedRectangle(cornerRadius:18).strokeBorder(selected ? PiyaliBrand.unitColor(brand.dark ? "38b2ac":"319795"):menuTileBorder,lineWidth:selected ? 2.5:1) }
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected:[])
            .modifier(TeamInviteAccessibility(startup:app.teamsStartup,language:language,enabled:teamInvite))
    }
    @ViewBuilder private func panelContent(_ panel:ProductPanel)->some View {
        switch panel {
        case .settings: AccountView()
        case .teams: TeamsView()
        case .assistant: EmptyView()
        case .memory: MemoryDrawerView(onClose:{self.panel=nil})
        case .achievements: AchievementsView()
        case .placement: PlacementView()
        case .goal: DailyGoalManagerView(onClose:{self.panel=nil})
        }
    }
    private func restorePendingFocusedTutor(){if specialCourse == nil,let course=app.pendingFocusedTutorCourse{specialCourse=course;mode = .tutor;revision=UUID()}}
    private func switchMode(_ value:ProductMode) {
        if value == .path,mode == .path,specialCourse == nil,!app.lessonActivityActive {
            menuOpen=false;lessonScrollRequest=UUID();return
        }
        cancelPracticeLaunch()
        practice.cancel(app)
        menuOpen=false
        // Choosing the current standalone Conversation keeps its live session mounted.
        if value == .conversation,mode == value,specialCourse == nil { return }
        specialCourse=nil;mode=value;lessonScrollRequest=nil;revision=UUID()
    }
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
        specialCourse=nil;lessonScrollRequest=nil
        switch kind {
        case "goal","repair": specialCourse=kind
        case "learn": mode = .path;lessonScrollRequest=UUID()
        case "review": mode = .cards
        case "phonics": mode = .phonics
        case "conversation": mode = .conversation
        default: mode = .tutor
        }
        revision=UUID()
    }
    private var canPresentPracticeModal:Bool {app.companionUnlock == nil && panel == nil && !menuOpen && !goalOpen && !timerOpen && timer.session.status != .finished && firstRun.step == nil && app.goalCheck == nil && app.flashcardSession == nil && lessonCompletion == nil && practice.visible == nil && practice.dailyGoalVisible == nil && (app.dailyGoalReward == nil || app.pendingLessonCompletion != nil) && app.scholarship.visible == nil}
    private func updatePracticePresentation(){practice.presentationBlocked(app.companionUnlock != nil || panel != nil || menuOpen || goalOpen || timerOpen || timer.session.status == .finished || firstRun.step != nil || lessonCompletion != nil || app.scholarship.visible != nil,app:app)}
    private func presentPendingLessonCompletion() {
        guard let pending=app.pendingLessonCompletion else { return }
        guard pending.account == app.identity.npub,pending.target == app.learner.target else { app.pendingLessonCompletion=nil;return }
        guard !app.lessonActivityActive,canPresentPracticeModal else { return }
        Task { @MainActor in
            try? await Task.sleep(for:.milliseconds(150))
            guard app.pendingLessonCompletion?.id == pending.id,pending.account == app.identity.npub,pending.target == app.learner.target,!app.lessonActivityActive,canPresentPracticeModal else { return }
            presentedLessonCompletionID=pending.id;lessonCompletion=pending
            // The bundled companion cue is the same source sparkle.
            let volume=app.learner.settingsSnapshot["soundVolume"]
            practiceSounds.play("companionUnlock",enabled:app.learner.soundEffectsEnabled,volume:volume == .null ? 100:volume.number)
        }
    }
    private func finishLessonCompletion() {
        if app.pendingLessonCompletion?.id == presentedLessonCompletionID { app.pendingLessonCompletion=nil }
        presentedLessonCompletionID=nil;presentPendingLessonCompletion();updatePracticePresentation()
    }
    private func closeLessonCompletion() { lessonCompletion=nil;finishLessonCompletion() }
}
