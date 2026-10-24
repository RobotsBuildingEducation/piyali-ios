import SwiftUI

struct TodayFocusHomeView:View {
    var now=Date()
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let sessionActive:Bool
    var startingPractice=false
    let onStart:()->Void
    let onPanel:(ProductPanel)->Void
    let onCompanionContinue:()->Void
    @StateObject private var headline=PlateHeadlineController()
    @State private var bubbleDismissed=false
    @State private var showActivity=false
    @State private var immersionError:String?
    @State private var preparingImmersion=false
    @State private var immersionRequest:UUID?
    private var language:String {app.learner.support}
    private var brand:PiyaliBrand {PiyaliBrand(dark:scheme == .dark)}
    private var courses:[PlateCourse] {app.plateCourses}
    private var cleared:Bool {!courses.isEmpty && courses.allSatisfy(\.done)}
    private var bubbleKey:String {"piyali.companionBubbleDismissed:"+app.identity.npub+":"+app.learner.target+":"+CalendarDay.key(now)}
    private var showBubble:Bool {!bubble.isEmpty && !bubbleDismissed}
    private var headlineScope:PlateHeadlineScope {.init(account:app.identity.npub,target:app.learner.target,support:language,day:CalendarDay.key(now))}
    private var headlineCache:String? {app.learner.plateHeadline(day:CalendarDay.key(now))}
    private var headlineText:String {headline.scope == headlineScope ? headline.text : headlineCache ?? ""}
    private var headlineLoading:Bool {headline.scope == headlineScope ? headline.loading : headlineCache == nil && !cleared}
    private struct HeadlineLoad:Equatable {let scope:PlateHeadlineScope,cached:String?,cleared:Bool}
    var body:some View {
        ScrollView {
            VStack(spacing:12) {
                VStack(spacing:2) {
                    OnboardingText(text:ProductCopy.text(language,"PLATE_TITLE_COPY"),size:24,weight:.black,lineHeight:28.8).accessibilityIdentifier("todayFocusTitle")
                    OnboardingText(text:now.formatted(Date.FormatStyle().weekday(.wide).month(.wide).day().locale(Locale(identifier:language))),size:14,lineHeight:21).foregroundStyle(brand.muted)
                }.frame(maxWidth:.infinity)
                if cleared {
                    Text(ProductCopy.text(language,"PLATE_CLEARED_COPY")).font(PiyaliBrand.productFont(16,700)).frame(maxWidth:.infinity).padding(.horizontal,16).padding(.vertical,12).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "faf089" : "975a16")).background(PiyaliBrand.unitColor(scheme == .dark ? "facc15" : "b7791f").opacity(0.14),in:EntryCornerShape(radius:28)).overlay{EntryCornerShape(radius:28).stroke(PiyaliBrand.unitColor(scheme == .dark ? "facc15" : "b7791f").opacity(0.5))}
                } else if headlineText.isEmpty && headlineLoading {
                    FocusHeadlineDots().foregroundStyle(brand.muted).accessibilityElement(children:.ignore).accessibilityLabel(EntryCopy.ui(language,"generic_loading")).accessibilityIdentifier("focusHeadlineLoading")
                } else {
                    OnboardingText(text:headlineText.isEmpty ? ProductCopy.text(language,"subtitle") : headlineText,size:14,weight:.medium,lineHeight:19.6).foregroundStyle(brand.secondary).multilineTextAlignment(.center).padding(.horizontal,16).accessibilityIdentifier("focusHeadline")
                }
                VStack(spacing:10){ForEach(courses){courseRow($0)}}.opacity(showBubble ? 0.4 : 1)
                if !cleared {
                    Button(action:onStart){HStack(spacing:8){Image(systemName:"play");Text(ProductCopy.text(language,sessionActive || courses.contains{$0.count > 0} ? "continue" : "start"))}.opacity(startingPractice ? 0:1).overlay{if startingPractice{ProgressView().tint(.white)}}}.buttonStyle(FocusPrimaryButtonStyle()).disabled(showBubble || app.loadingContent || startingPractice).accessibilityIdentifier("startDailyPractice")
                }
                if showActivity {DailyActivityView(onBack:{showActivity=false},onAchievements:{onPanel(.achievements)}).zIndex(showBubble ? 30 : 0)}
                else {
                    FocusCompanionPanel(bubble:showBubble ? bubble : nil,introductory:app.learner.introductoryQuest(day:CalendarDay.key(now)),onContinue:{bubbleDismissed=true;UserDefaults.standard.set(true,forKey:bubbleKey);onCompanionContinue()},onActivity:{showActivity=true},onAchievements:{onPanel(.achievements)}).zIndex(showBubble ? 30 : 0)
                }
                FocusScoreJourney(now:now,preparingImmersion:preparingImmersion,immersionError:immersionError,onRetry:{Task{await prepareImmersion()}})
            }.padding(.horizontal,12).padding(.top,16).padding(.bottom,24).frame(maxWidth:584).frame(maxWidth:.infinity)
        }.background(BrandBackground()).task(id:bubbleKey){bubbleDismissed=UserDefaults.standard.bool(forKey:bubbleKey);app.prepareDailyPlate()}.task(id:app.immersionPreparationKey){await prepareImmersion()}
            .task(id:HeadlineLoad(scope:headlineScope,cached:headlineCache,cleared:cleared)) {
                let scope=headlineScope
                await headline.load(scope:scope,cached:headlineCache,cleared:cleared,policy:try? PlateHeadlinePolicy(),generate:{onChunk in
                    let prompt=try app.plateHeadlinePrompt(scope:scope)
                    return try await app.ai.plateHeadline(prompt,onChunk:onChunk)
                },save:{app.savePlateHeadline($0,scope:scope)})
            }.onDisappear{headline.cancel()}
    }
    private func courseRow(_ course:PlateCourse)->some View {
        let next=courses.first(where:{!$0.done})?.kind == course.kind,accent=PiyaliBrand.unitColor(scheme == .dark ? "81e6d9" : "285e61"),border=course.done ? PiyaliBrand.unitColor(scheme == .dark ? "81e6d9" : "319795") : course.count > 0 ? PiyaliBrand.unitColor("9f7aea") : brand.border
        return HStack(spacing:12) {
            Image("Focus-course-"+course.kind).renderingMode(.template).resizable().frame(width:18,height:18).foregroundStyle(course.done ? accent : brand.text).frame(width:38,height:38).background(course.done ? PiyaliBrand.unitColor(scheme == .dark ? "2dd4bf" : "319795").opacity(scheme == .dark ? 0.24 : 0.22) : .white.opacity(0.06),in:Circle())
            HStack(spacing:8) {
                Text(ProductCopy.course(language,course.kind)).font(PiyaliBrand.productFont(14,700)).lineLimit(1)
                if next {Text(ProductCopy.text(language,"PLATE_NEXT_COPY")).font(PiyaliBrand.productFont(10,700)).foregroundStyle(brand.secondary).padding(.horizontal,8).padding(.vertical,1).background(PiyaliBrand.unitColor(scheme == .dark ? "1e293b" : "efe4d5"),in:Capsule()).overlay{Capsule().stroke(brand.border)}}
                Spacer(minLength:0)
                Text(course.done ? "\(course.target > 0 ? Int((Double(course.count)/Double(course.target)*100).rounded()) : 100)%" : "\(course.count)/\(course.target)").font(PiyaliBrand.productFont(12,700)).foregroundStyle(course.done ? accent : brand.muted)
            }.frame(height:38).overlay(alignment:.bottom){FocusWaveBar(percent:Double(course.count)/Double(max(1,course.target))*100,height:8).offset(y:3)}
            if course.done {Image(systemName:"checkmark.circle.fill").font(.system(size:16)).foregroundStyle(accent)}
        }.padding(.horizontal,17).padding(.vertical,13).background(course.done ? PiyaliBrand.unitColor(scheme == .dark ? "2dd4bf" : "319795").opacity(scheme == .dark ? 0.18 : 0.16) : FocusCopy.color(scheme == .dark ? "rgba(11,18,32,0.12)" : "rgba(255,249,242,0.88)"),in:EntryCornerShape(radius:28)).overlay{EntryCornerShape(radius:28).stroke(border)}.accessibilityElement(children:.combine).accessibilityIdentifier("focusCourse-"+course.kind)
    }
    private var bubble:String {
        app.companionBubble(now:now)["display"].string
    }
    private func prepareImmersion() async {
        let request=UUID();immersionRequest=request;preparingImmersion=true;immersionError=nil
        defer {if immersionRequest == request {preparingImmersion=false}}
        do {try await app.prepareImmersion()}catch is CancellationError{}catch {if immersionRequest == request {immersionError=error.localizedDescription}}
    }
}
