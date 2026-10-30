import SwiftUI

struct FocusScoreJourney:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    var now:Date
    var preparingImmersion:Bool
    var immersionError:String?
    let onRetry:()->Void
    @State private var rewardIndex=Int.random(in:0..<20)
    private static let landmarks=(try? ContentLibrary.load([JSONValue].self,name:"score-milestones")) ?? []
    private var brand:PiyaliBrand {PiyaliBrand(dark:scheme == .dark)}
    private var copy:JSONValue {FocusCopy.data(app.learner.support)}
    private var active:Int {Self.landmarks.lastIndex{$0["score"].number <= Double(app.learner.score)} ?? 0}
    var body:some View {
        VStack(alignment:.leading,spacing:0) {
            HStack(alignment:.top,spacing:12) {
                VStack(alignment:.leading,spacing:0) {
                    Text(((Locale(identifier:app.learner.support).localizedString(forLanguageCode:app.learner.target) ?? LearningLanguages.names[app.learner.target] ?? app.learner.target)+" "+copy["score"].string).uppercased()).font(PiyaliBrand.productFont(12,700)).tracking(0.96).foregroundStyle(brand.secondary)
                    Text(app.learner.score.formatted(.number.locale(Locale(identifier:app.learner.support)))).font(.system(size:56,weight:.black)).monospacedDigit().frame(height:56).accessibilityIdentifier("focusScore")
                }
                Spacer(minLength:12)
                Text(PerformanceScore.level(score:app.learner.score)).font(PiyaliBrand.productFont(14,700)).foregroundStyle(brand.secondary).padding(.top,4)
            }.padding(.horizontal,16)
            ScrollViewReader {proxy in
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(alignment:.top,spacing:12) {
                        ForEach(Array(Self.landmarks.enumerated()),id:\.offset) {index,item in
                            let reached=item["score"].number <= Double(app.learner.score),accent=PiyaliBrand.unitColor(scheme == .dark ? "a5f3fc" : "0e7490")
                            VStack(spacing:6) {
                                Image("Focus-score-"+item["icon"].string).renderingMode(.template).resizable().frame(width:19,height:19).foregroundStyle(reached ? accent : brand.muted).frame(width:42,height:42).background(reached ? PiyaliBrand.unitColor(scheme == .dark ? "164e63" : "d8f4f6") : mutedSurface,in:Circle()).overlay{Circle().stroke(reached ? PiyaliBrand.unitColor(scheme == .dark ? "67e8f9" : "0891b2") : strongBorder,lineWidth:2)}.background{if index == active {Circle().stroke(PiyaliBrand.unitColor("22d3ee").opacity(0.18),lineWidth:8)}}
                                Text(String(Int(item["score"].number))).font(.system(size:12,weight:.black)).foregroundStyle(reached ? accent : brand.muted)
                                Text(item.localized(app.learner.support)).font(PiyaliBrand.productFont(12,reached ? 700 : 500)).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true).frame(minHeight:45,alignment:.top).foregroundStyle(reached ? brand.text : brand.secondary)
                            }.frame(width:96).padding(.vertical,4).id(index).accessibilityElement(children:.combine).accessibilityIdentifier("focusMilestone-\(Int(item["score"].number))")
                        }
                    }.background(alignment:.top){Rectangle().fill(strongBorder).frame(height:4).padding(.horizontal,48).padding(.top,23)}.padding(.horizontal,16).padding(.vertical,8)
                }.onAppear{proxy.scrollTo(active,anchor:.center)}.onChange(of:active){_,value in withAnimation{proxy.scrollTo(value,anchor:.center)}}
            }.padding(.top,20).accessibilityIdentifier("focusScoreJourney")
            Rectangle().fill(brand.border).frame(height:1).padding(.top,20).padding(.horizontal,16)
            immersion.padding(.horizontal,16).padding(.top,20)
        }.onChange(of:CalendarDay.key(now)){_,_ in rewardIndex=Int.random(in:0..<20)}.padding(.vertical,16).background(FocusCopy.background(scheme == .dark ? "rgba(11,18,32,0.12)" : "rgba(255,249,242,0.88)"),in:EntryCornerShape(radius:28)).overlay{EntryCornerShape(radius:28).stroke(brand.border)}
    }
    private func encouragement(_ copy:JSONValue)->String {let values=copy["encouragements"].array;return values.isEmpty ? "" : values[rewardIndex%values.count].string}
    private var mutedSurface:Color {PiyaliBrand.unitColor(scheme == .dark ? "1e293b" : "efe4d5")}
    private var strongBorder:Color {PiyaliBrand.unitColor(scheme == .dark ? "94a3b8" : "604d38").opacity(scheme == .dark ? 0.34 : 0.24)}
    private var immersion:some View {
        let state=app.learner.immersionState(now:now),tasks=state["tasks"].array,completed=state["completed"].array,done = !tasks.isEmpty && completed.count == tasks.count && completed.allSatisfy(\.boolean),rewarded=state["rewarded"].boolean && done,copy=copy["immersion"]
        return VStack(alignment:.leading,spacing:12) {
            VStack(alignment:.leading,spacing:0) {OnboardingText(text:copy["title"].string,size:16,weight:.bold,lineHeight:24).accessibilityIdentifier("focusImmersionTitle");OnboardingText(text:copy["subtitle"].string,size:14,lineHeight:21).foregroundStyle(brand.secondary)}
            if app.learner.placements?[app.learner.target] == nil {
                HStack(alignment:.top,spacing:12){Image(systemName:"info.circle").font(.system(size:18)).foregroundStyle(PiyaliBrand.teal).padding(.top,2);Text(copy["placementNeeded"].string).font(PiyaliBrand.productFont(14)).lineSpacing(4).foregroundStyle(brand.secondary)}.frame(maxWidth:.infinity,alignment:.leading).padding(16).background(mutedSurface,in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(brand.border)}
            } else {
                ForEach(Array(tasks.enumerated()),id:\.offset){index,task in
                    let checked=index < completed.count && completed[index].boolean
                    Button {app.learner.toggleImmersion(index:index,now:now);app.persist()} label:{
                        HStack(alignment:.top,spacing:12) {
                            ZStack {RoundedRectangle(cornerRadius:7).fill(checked ? PiyaliBrand.unitColor("319795") : .clear);RoundedRectangle(cornerRadius:7).stroke(checked ? PiyaliBrand.unitColor("319795") : strongBorder,lineWidth:2);if checked {Image(systemName:"checkmark").font(.system(size:14,weight:.semibold)).foregroundStyle(.white)}}.frame(width:22,height:22)
                            VStack(alignment:.leading,spacing:2) {if index == 3 {Text(copy["goal"].string).font(PiyaliBrand.productFont(12,700)).foregroundStyle(PiyaliBrand.teal).padding(.bottom,2)};Text(task["title"].string).font(PiyaliBrand.productFont(14,700));if !task["description"].string.isEmpty {Text(task["description"].string).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary)}}.frame(maxWidth:.infinity,alignment:.leading)
                        }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(scheme == .dark ? mutedSurface : brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(brand.border)}
                    }.buttonStyle(.plain).disabled(preparingImmersion || state["status"].string != "ready" || rewarded).opacity(preparingImmersion ? 0.7 : 1).accessibilityValue(checked ? "1" : "0").accessibilityIdentifier("immersionTask-\(index)")
                }
                if rewarded {
                    VStack(spacing:6){CompanionArtwork(type:app.learner.effectiveCompanionType).frame(width:64,height:64);Text("+15 XP").font(PiyaliBrand.productFont(26,900)).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "99f6e4" : "0e7490"));Text(encouragement(copy)).font(PiyaliBrand.productFont(14,700))}.frame(maxWidth:.infinity).padding(.horizontal,16).padding(.vertical,20).background(LinearGradient(colors:(scheme == .dark ? ["103d3d","17324a","3d3422"] : ["e7fff9","f2fcff","fff8dd"]).map(PiyaliBrand.unitColor),startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:18)).overlay{RoundedRectangle(cornerRadius:18).stroke(PiyaliBrand.unitColor(scheme == .dark ? "2b8178" : "8ddfd2"))}.accessibilityElement(children:.combine).accessibilityLabel(encouragement(copy)+" "+copy["rewardXp"].string).accessibilityIdentifier("immersionReward")
                }
                if preparingImmersion {ProgressView().frame(maxWidth:.infinity).padding(.vertical,tasks.isEmpty ? 24 : 8).accessibilityLabel(copy["loading"].string)}
                if let immersionError {VStack(spacing:8){Text(immersionError).font(PiyaliBrand.productFont(14)).foregroundStyle(.red).multilineTextAlignment(.center);Button(copy["retry"].string,action:onRetry).buttonStyle(FocusOutlineButtonStyle())}.frame(maxWidth:.infinity).padding(.vertical,8)}
                else if tasks.isEmpty && !preparingImmersion {Text(copy["empty"].string).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).frame(maxWidth:.infinity).padding(.vertical,16)}
            }
        }
    }
}
