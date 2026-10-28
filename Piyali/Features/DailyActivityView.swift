import SwiftUI

struct DailyActivityView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let onBack:()->Void
    let onAchievements:()->Void
    var now=Date()
    var historyOverride:JSONValue?
    @StateObject private var controller=XPActivityController()
    private var dark:Bool{scheme == .dark}
    private var language:String{app.learner.support}
    private var brand:PiyaliBrand{PiyaliBrand(dark:dark)}
    private var year:Int{Calendar.current.component(.year,from:now)}
    private var copy:JSONValue{XPActivityPlan.ui["copy"][language] == .null ? XPActivityPlan.ui["copy"]["en"]:XPActivityPlan.ui["copy"][language]}
    private var history:JSONValue{XPActivityPlan.effective(historyOverride ?? XPActivityPlan.merge(app.learner.activityLegacy,controller.history),dailyXP:app.learner.dailyKey==CalendarDay.key(now) ? app.learner.dailyXP:0,goal:app.learner.dailyGoal,now:now)}
    var body:some View {
        VStack(alignment:.leading,spacing:0){
            VStack(alignment:.leading,spacing:0){OnboardingText(text:copy["title"].string.uppercased(),size:12,weight:.bold,lineHeight:18).tracking(0.96).foregroundStyle(dark ? gray("300"):brand.secondary).accessibilityIdentifier("activityTitle");OnboardingText(text:copy["subtitle"].string,size:12,lineHeight:18).foregroundStyle(dark ? gray("500"):brand.muted)}.padding(.bottom,12)
            VStack(alignment:.leading,spacing:8){
                XPActivityGrid(plan:XPActivityPlan(history:history,language:language,dark:dark,now:now),language:language)
                SessionToolFlow(spacing:16){legend("empty");legend("some");legend("goal")}
            }.frame(maxHeight:.infinity,alignment:.center)
            HStack(spacing:12){Button(FocusCopy.data(language)["companion"].string,action:onBack).accessibilityIdentifier("activityCompanion");Button(FocusCopy.data(language)["achievements"].string,action:onAchievements).accessibilityIdentifier("activityAchievements")}.buttonStyle(XPActivityButtonStyle()).frame(maxWidth:.infinity)
        }.padding(13).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading).background(dark ? gray("800"):PiyaliBrand.unitColor("efe4d5"),in:RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).stroke(dark ? gray("700"):brand.border)}.accessibilityElement(children:.contain).accessibilityIdentifier("focusActivity")
            .task(id:app.identity.npub+":\(year)"){
                guard historyOverride == nil else{return}
                await controller.load(account:app.identity.npub,year:year,legacy:app.learner.activityLegacy){account,year in
                    if let fixture=XPActivityFixture.history(year:year){return fixture}
                    try await FirebaseIdentityService.shared.ensure(app.identity)
                    return try await FirebaseService.shared.activityHistory(npub:account,year:year)
                }
            }
    }
    private func gray(_ level:String)->Color{FocusCopy.color(XPActivityPlan.ui["palette"][level].string)}
    private func legend(_ level:String)->some View {
        HStack(spacing:8){XPActivityCell(style:XPActivityPlan.ui["styles"]["\(dark ? "dark":"light"):\(level):false:false"]).frame(width:10,height:10);OnboardingText(text:copy[level].string,size:12,lineHeight:18).foregroundStyle(dark ? gray("400"):brand.muted)}.accessibilityElement(children:.combine).accessibilityIdentifier("activityLegend-"+level)
    }
}
struct XPActivityGrid:View {
    let plan:XPActivityPlan
    var language="en"
    var body:some View {
        ScrollView(.horizontal,showsIndicators:false){
            HStack(alignment:.top,spacing:2){ForEach(plan.weeks){week in
                VStack(alignment:.leading,spacing:0){Text(week.month.uppercased()).font(PiyaliBrand.productFont(8)).foregroundStyle(PiyaliBrand.unitColor("6b7280")).fixedSize(horizontal:true,vertical:false).frame(width:11,height:12,alignment:.topLeading).environment(\.layoutDirection,.leftToRight).accessibilityHidden(week.month.isEmpty)
                    VStack(spacing:2){ForEach(week.days){day in
                        if day.blank{Color.clear.frame(width:11,height:11).accessibilityHidden(true)}else{XPActivityCell(style:day.style).frame(width:11,height:11).accessibilityLabel(day.title).accessibilityValue((XPActivityPlan.ui["copy"][language] == .null ? XPActivityPlan.ui["copy"]["en"]:XPActivityPlan.ui["copy"][language])[day.level].string).accessibilityIdentifier("activityDay-"+day.id)}
                    }}
                }
            }}.padding(.bottom,8)
        }.frame(height:109).accessibilityIdentifier("activityGrid")
    }
}
private struct XPActivityCell:View {
    let style:JSONValue
    private var fill:AnyShapeStyle{let value=style["background"].string;return value.hasPrefix("linear-gradient") ? AnyShapeStyle(LinearGradient(colors:value.contains("#6fd0b5") ? [PiyaliBrand.unitColor("6fd0b5"),PiyaliBrand.unitColor("8bc9de")]:[PiyaliBrand.unitColor("2dd4bf"),PiyaliBrand.unitColor("38bdf8")],startPoint:.topLeading,endPoint:.bottomTrailing)):AnyShapeStyle(FocusCopy.color(value))}
    var body:some View{RoundedRectangle(cornerRadius:3).fill(fill).overlay{RoundedRectangle(cornerRadius:3).strokeBorder(FocusCopy.color(style["borderColor"].string),lineWidth:1)}.opacity(style["opacity"] == .null ? 1:style["opacity"].number).scaleEffect(style["transform"].string.isEmpty ? 1:1.04)}
}
enum XPActivityFixture {
    static func history(year:Int)->JSONValue?{
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",env["PIYALI_XP_ACTIVITY_FIXTURE"] == "history",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil{return .object(["days":.object(["\(year)-01-01":.number(250),"\(year)-01-02":.number(15)]),"goalDays":.array([.string("\(year)-01-01"),.string("\(year)-01-03")])])}
        #endif
        return nil
    }
}

private struct XPActivityButtonStyle:ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration:Configuration)->some View{configuration.label.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,12).frame(height:32).foregroundStyle(scheme == .dark ? .white:.black).overlay{Capsule().strokeBorder(PiyaliBrand.unitColor(scheme == .dark ? "81e6d9":"2c7a7b"))}.contentShape(Capsule()).opacity(configuration.isPressed ? 0.7:1)}
}
