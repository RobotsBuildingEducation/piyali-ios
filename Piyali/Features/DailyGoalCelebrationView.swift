import SwiftUI

struct DailyGoalCelebrationView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let reward:DailyGoalReward
    let onContinue:()->Void
    @State private var height:CGFloat=550
    private static let copy=(try? ContentLibrary.load([String:JSONValue].self,name:"daily-goal-celebration-copy")) ?? [:]
    private func t(_ key:String)->String {(Self.copy[app.learner.support] ?? Self.copy["en"] ?? .null)[key].string}
    private var pet:JSONValue{FocusCopy.data(app.learner.support)["pet"]}
    private var stage:JSONValue{FocusCopy.appearance(reward.health,dark:scheme == .dark)}
    private var badge:(Color,Color){
        if scheme != .dark{return(FocusCopy.color(stage["badgeBg"].string),FocusCopy.color(stage["badgeColor"].string))}
        let colors=["green":["c6f6d5","22543d"],"teal":["b2f5ea","234e52"],"yellow":["fefcbf","744210"],"orange":["feebc8","7b341e"],"red":["fed7d7","822727"],"gray":["edf2f7","1a202c"]][stage["colorScheme"].string] ?? ["edf2f7","1a202c"]
        return(PiyaliBrand.unitColor(colors[0]),PiyaliBrand.unitColor(colors[1]))
    }
    private var panelText:Color{scheme == .dark ? .white:PiyaliBrand.unitColor("332b21")}
    var body:some View {
        GeometryReader{geometry in
            ZStack{
                (scheme == .dark ? PiyaliBrand.unitColor("020617").opacity(0.92):PiyaliBrand.unitColor("1c140c").opacity(0.82)).ignoresSafeArea().onTapGesture(perform:onContinue)
                ScrollView{
                    VStack(spacing:16){
                        VStack(spacing:8){OnboardingText(text:t("title"),size:24,weight:.bold,lineHeight:36);OnboardingText(text:t("subtitle"),size:16,lineHeight:24).opacity(0.9)}
                        VStack(spacing:12){VStack(spacing:4){OnboardingText(text:t("goal"),size:12,lineHeight:18).opacity(0.8);OnboardingText(text:app.learner.support == "ar" ? "\u{202B}\(reward.goal) XP\u{202C}":"\(reward.goal) XP",size:30,weight:.bold,lineHeight:45).foregroundStyle(PiyaliBrand.unitColor("faf089"))};OnboardingText(text:t("streak"),size:14,lineHeight:21).opacity(0.85)}.frame(maxWidth:.infinity).padding(.vertical,18).padding(.horizontal,22).background(.white.opacity(0.2),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.4),lineWidth:2)}
                        companion
                        Button(t("continue"),action:onContinue).font(PiyaliBrand.productFont(16,700)).frame(maxWidth:.infinity,minHeight:42).background{Capsule().fill(PiyaliBrand.unitColor("319795")).shadow(color:PiyaliBrand.unitColor("234e52"),radius:0,y:4)}.accessibilityIdentifier("dailyGoalRewardContinue")
                    }.multilineTextAlignment(.center).padding(28).frame(maxWidth:.infinity).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){height=$0}
                }.frame(width:min(448,geometry.size.width*0.9),height:min(height,geometry.size.height-48)).foregroundStyle(.white).background{SourceCelebrationGradient(colors:[PiyaliBrand.unitColor("0ea5e9"),PiyaliBrand.unitColor("22c55e")]).clipShape(RoundedRectangle(cornerRadius:48))}.overlay{RoundedRectangle(cornerRadius:48).strokeBorder(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).allowsHitTesting(false)}.shadow(color:.black.opacity(0.25),radius:24,y:25)
            }.frame(width:geometry.size.width,height:geometry.size.height)
        }.ignoresSafeArea(.container).buttonStyle(.plain).accessibilityElement(children:.contain).accessibilityIdentifier("dailyGoalReward")
    }
    private var companion:some View {
        HStack(alignment:.top,spacing:12){
            VStack(spacing:6){CompanionArtwork(type:app.learner.effectiveCompanionType,health:reward.health).frame(width:96,height:96).background(scheme == .dark ? .white.opacity(0.22):PiyaliBrand.unitColor("fffdf9").opacity(0.52),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(.white.opacity(0.38))};Text(pet[FocusCopy.stage(reward.health)].string.uppercased()).font(PiyaliBrand.productFont(9.92,700)).padding(.horizontal,8).padding(.vertical,1.4).background(badge.0,in:RoundedRectangle(cornerRadius:6)).foregroundStyle(badge.1)}
            VStack(alignment:.leading,spacing:8){OnboardingText(text:app.learner.companionName.isEmpty ? pet["title"].string:app.learner.companionName,size:14,weight:.bold,lineHeight:15.4);VStack(spacing:6){HStack(spacing:8){SessionIcon(name:"FiHeart",size:14).foregroundStyle(PiyaliBrand.unitColor("ce7a8c"));Text(pet["health"].string).font(PiyaliBrand.productFont(12,600));Spacer(minLength:0);Text("\(reward.health)%").font(PiyaliBrand.productFont(14,700))};FocusWaveBar(percent:Double(reward.health),height:14,background:.white.opacity(scheme == .dark ? 0.22:0.58),border:.white.opacity(0.14))}}
                .frame(maxWidth:.infinity,alignment:.leading)
        }.foregroundStyle(panelText).padding(11).background(scheme == .dark ? AnyShapeStyle(.white.opacity(0.18)):AnyShapeStyle(FocusCopy.background(stage["background"].string)),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.38))}
    }
}
