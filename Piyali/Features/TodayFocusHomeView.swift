import SwiftUI

struct TodayFocusHomeView:View {
    var now=Date()
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let sessionActive:Bool
    let onStart:()->Void
    let onPanel:(ProductPanel)->Void
    let onCompanionContinue:()->Void
    @State private var bubbleDismissed=false
    @State private var showActivity=false
    @State private var immersionError:String?
    @State private var preparingImmersion=false
    private var language:String { app.learner.support }
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    private var courses:[PlateCourse] { app.plateCourses }
    private var cleared:Bool { !courses.isEmpty && courses.allSatisfy(\.done) }
    private var bubbleKey:String { "piyali.companionBubbleDismissed:"+app.identity.npub+":"+app.learner.target+":"+CalendarDay.key(now) }
    private var showBubble:Bool { !cleared && !bubbleDismissed }
    var body:some View {
        ScrollView {
            VStack(spacing:12) {
                VStack(spacing:3) {
                    Text(ProductCopy.text(language,"PLATE_TITLE_COPY")).font(PiyaliBrand.productFont(24,700)).accessibilityIdentifier("todayFocusTitle")
                    Text(now,format:Date.FormatStyle().weekday(.wide).month(.wide).day().locale(Locale(identifier:language))).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.muted)
                }.frame(maxWidth:.infinity).padding(.top,16)
                if cleared { Text(ProductCopy.text(language,"PLATE_CLEARED_COPY")).font(PiyaliBrand.productFont(20,700)).frame(maxWidth:.infinity).padding(20).background(Color.orange.opacity(0.14),in:RoundedRectangle(cornerRadius:20)) }
                else { Text(ProductCopy.text(language,"subtitle")).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).multilineTextAlignment(.center).padding(.vertical,12) }
                VStack(spacing:10) { ForEach(courses) { course in courseRow(course) } }.opacity(showBubble ? 0.4 : 1)
                if !cleared { Button(action:onStart) { Label(ProductCopy.text(language,sessionActive || courses.contains { $0.count > 0 } ? "continue" : "start"),systemImage:"play") }.buttonStyle(BrandButtonStyle()).disabled(showBubble || app.loadingContent).accessibilityIdentifier("startDailyPractice") }
                if showActivity { DailyActivityView(onBack:{ showActivity=false },onAchievements:{ onPanel(.achievements) }) }
                else { companion }
                scoreJourney
                immersion
            }.padding(.horizontal,12).padding(.bottom,24).frame(maxWidth:560).frame(maxWidth:.infinity)
        }.background(BrandBackground()).task(id:bubbleKey) { bubbleDismissed=UserDefaults.standard.bool(forKey:bubbleKey);app.prepareDailyPlate() }
            .task(id:app.immersionPreparationKey) { await prepareImmersion() }
    }
    private func courseRow(_ course:PlateCourse)->some View {
        let next=courses.first(where:{ !$0.done })?.kind == course.kind
        let symbol=["speak":"book.closed","learn":"point.topleft.down.to.point.bottomright.curvepath","review":"rectangle.stack","phonics":"character.book.closed","conversation":"bubble.left","goal":"sparkles","repair":"sparkles"][course.kind] ?? "book"
        return HStack(spacing:12) {
            Image(systemName:symbol).font(.system(size:18)).frame(width:38,height:38).background(PiyaliBrand.teal.opacity(course.done ? 0.22 : 0.04),in:Circle())
            VStack(spacing:8) {
                HStack(spacing:8) { Text(ProductCopy.course(language,course.kind)).font(PiyaliBrand.productFont(14,700));if next { Text(ProductCopy.text(language,"PLATE_NEXT_COPY")).font(PiyaliBrand.productFont(10,700)).padding(.horizontal,8).padding(.vertical,2).background(brand.border.opacity(0.25),in:Capsule()) };Spacer();Text(course.done ? "\(Int(Double(course.count)/Double(max(1,course.target))*100))%" : "\(course.count)/\(course.target)").font(PiyaliBrand.productFont(12,700)).foregroundStyle(brand.muted) }
                ProgressView(value:Double(min(course.count,course.target)),total:Double(max(1,course.target))).tint(PiyaliBrand.teal)
            }
            if course.done { Image(systemName:"checkmark.circle.fill").foregroundStyle(PiyaliBrand.teal) }
        }.padding(.horizontal,16).padding(.vertical,12).background(course.done ? PiyaliBrand.teal.opacity(0.16) : brand.surface.opacity(0.6),in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(course.done ? PiyaliBrand.teal : course.count > 0 ? .purple : brand.border) }.accessibilityElement(children:.combine).accessibilityIdentifier("focusCourse-"+course.kind)
    }
    private var companion:some View {
        VStack(spacing:16) {
            CompanionArtwork(type:app.learner.effectiveCompanionType).frame(width:112,height:112).padding(.top,12)
            if showBubble {
                VStack(spacing:14) { Text(bubble).font(PiyaliBrand.productFont(14)).lineSpacing(5);Button(ProductCopy.text(language,"PLATE_CONTINUE_COPY")) { bubbleDismissed=true;UserDefaults.standard.set(true,forKey:bubbleKey);onCompanionContinue() }.buttonStyle(BrandButtonStyle()).accessibilityIdentifier("companionContinue") }.padding(18).background(brand.surface,in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(brand.border) }
            }
            HStack { Text(app.learner.companionStatus.uppercased()).font(PiyaliBrand.productFont(10,700)).foregroundStyle(PiyaliBrand.teal).padding(6).background(PiyaliBrand.teal.opacity(0.12),in:Capsule());Spacer();Button { onPanel(.settings) } label:{ Image(systemName:"pencil").frame(width:36,height:36) }.accessibilityLabel("Customize companion").disabled(showBubble) }
            VStack(spacing:5) { Text(app.learner.companionName.isEmpty ? "Your companion" : app.learner.companionName).font(PiyaliBrand.productFont(18,700));Text("Level \(app.learner.companionLevel)").font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary);Text("Stay healthy by hitting your daily XP goal.").font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary) }
            meter("Health",symbol:"heart",value:app.learner.companionHealth,total:100)
            meter("Daily XP",symbol:"flame",value:app.learner.dailyXP,total:max(1,app.learner.dailyGoal))
            meter("Level \(app.learner.companionLevel)",symbol:"chart.line.uptrend.xyaxis",value:app.learner.xp%100,total:100,label:"XP \(app.learner.xp)")
            HStack(spacing:12) { Button("Activity") { showActivity=true };Button("Achievements") { onPanel(.achievements) } }.font(PiyaliBrand.productFont(13,600)).buttonStyle(.bordered).tint(PiyaliBrand.teal).padding(.top,6)
        }.padding(18).background(brand.surface.opacity(0.6),in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) }
    }
    private var bubble:String {
        let first=app.learner.introductoryQuest(day:CalendarDay.key(Date()))
        let kind=first ? app.learner.goal.isEmpty ? "welcome" : "welcomeGoal" : app.learner.activeMemories.isEmpty ? "fresh" : app.learner.activeMemories.count > 1 ? "repairMulti" : "repair"
        return ProductCopy.data(language)["bubbles"][kind].string.replacingOccurrences(of:"{goal}",with:app.learner.goal).replacingOccurrences(of:"{concept}",with:app.learner.activeMemories.first?.text("concept") ?? "").replacingOccurrences(of:"{taskList}",with:courses.map { ProductCopy.course(language,$0.kind) }.joined(separator:", "))
    }
    private func meter(_ title:String,symbol:String,value:Int,total:Int,label:String?=nil)->some View {
        VStack(spacing:7) { HStack { Label(title,systemImage:symbol);Spacer();Text(label ?? "\(Int(Double(value)/Double(total)*100)) %") }.font(PiyaliBrand.productFont(12,600));ProgressView(value:Double(min(value,total)),total:Double(total)).tint(PiyaliBrand.teal) }
    }
    private var scoreJourney:some View {
        let landmarks=(try? ContentLibrary.load([JSONValue].self,name:"score-milestones")) ?? []
        let active=landmarks.lastIndex { $0["score"].number <= Double(app.learner.score) } ?? 0
        return VStack(spacing:14) {
            HStack { Text((LearningLanguages.names[app.learner.target] ?? app.learner.target).uppercased()+" "+EntryCopy.text(language,"feature_score").uppercased()).font(PiyaliBrand.productFont(11,600));Spacer();Text("\(app.learner.score)").font(PiyaliBrand.productFont(24,700));Text(PerformanceScore.level(score:app.learner.score)).font(PiyaliBrand.productFont(12)) }
            ScrollViewReader { proxy in ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:16) { ForEach(Array(landmarks.enumerated()),id:\.offset) { index,item in VStack(spacing:8) { Text("\(Int(item["score"].number))").font(PiyaliBrand.productFont(16,700)).frame(width:44,height:44).background(index <= active ? PiyaliBrand.teal.opacity(0.18) : brand.border.opacity(0.12),in:Circle()).overlay { Circle().stroke(index == active ? PiyaliBrand.teal : brand.border,lineWidth:index == active ? 2 : 1) };Text(item.localized(language)).font(PiyaliBrand.productFont(10)).multilineTextAlignment(.center).frame(width:88,height:40) }.id(index) } } }.onAppear { proxy.scrollTo(active,anchor:.center) }.onChange(of:active) { _,value in withAnimation { proxy.scrollTo(value,anchor:.center) } } }
        }.padding(18).background(brand.surface.opacity(0.6),in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) }
    }
    private var immersion:some View {
        let state=app.learner.immersionState()
        return VStack(alignment:.leading,spacing:14) {
            Text("Today's immersion").font(PiyaliBrand.productFont(16,700));Text("Practice outside of the app").font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary)
            if app.learner.placements?[app.learner.target] == nil { Text("Set your proficiency level to create today's immersion tasks.").font(PiyaliBrand.productFont(14));Button("Choose your starting level") { onPanel(.placement) } }
            else { ForEach(Array(state["tasks"].array.enumerated()),id:\.offset) { index,task in Button { app.learner.toggleImmersion(index:index);app.persist() } label:{ HStack(alignment:.top) { Image(systemName:state["completed"].array[index].boolean ? "checkmark.circle.fill" : "circle");VStack(alignment:.leading,spacing:5) { Text(task["title"].string).font(PiyaliBrand.productFont(14,600));Text(task["description"].string).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.secondary) };Spacer() } }.buttonStyle(.plain).disabled(preparingImmersion || state["status"].string != "ready") }
                if preparingImmersion { ProgressView() }
                if let immersionError { Text(immersionError).font(PiyaliBrand.productFont(12)).foregroundStyle(.red) }
                if state["status"].string != "ready",!preparingImmersion { Button("Retry") { Task { await prepareImmersion() } } }
            }
        }.frame(maxWidth:.infinity,alignment:.leading).padding(18).background(brand.surface.opacity(0.6),in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) }
    }
    private func prepareImmersion() async { guard !preparingImmersion else { return };preparingImmersion=true;immersionError=nil;defer { preparingImmersion=false };do { try await app.prepareImmersion() } catch is CancellationError {} catch { immersionError=error.localizedDescription } }
}

struct DailyGoalSettingsView:View {
    @EnvironmentObject var app:AppModel
    var body:some View { Form { Section("Daily XP goal") { Stepper("\(app.learner.dailyGoal) XP",value:$app.learner.dailyGoal,in:10...300,step:10);ProgressView(value:Double(min(app.learner.dailyXP,app.learner.dailyGoal)),total:Double(app.learner.dailyGoal));Text("\(app.learner.dailyXP) / \(app.learner.dailyGoal) XP");Button("Save") { app.persist() } };Section { Text("\(app.learner.streak) day streak");Text("Health: \(app.learner.companionHealth)%") } }.navigationTitle("Daily goal") }
}
