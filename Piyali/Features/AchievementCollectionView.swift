import SwiftUI

@MainActor enum AchievementUI {
    static let source=(try? AchievementTranscript()) ?? AchievementTranscript(data:.null)
    static let orbPolicy=try? AchievementOrbPolicy()
    static func text(_ key:String,_ language:String)->String{source.text(key,language:language)}
}

struct AchievementsView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    var onClose:(()->Void)?
    var body:some View{AchievementCollectionPanel(language:app.learner.support,records:NostrAchievementCollection.merging([.object(app.learner.achievementRecords ?? [:]),app.learner.nostrAchievementRecords ?? .object([:])]),syncPending:app.nostrAchievements.busy,storageWarning:app.localStorageUnavailable,onClose:{if let onClose{onClose()}else{dismiss()}}).task(id:app.identity.npub){
        #if DEBUG
        if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1"{return}
        #endif
        try? await app.syncNostrAchievements(publish:false)
    }}
}

struct AchievementCollectionPanel:View {
    let language:String
    let records:JSONValue
    var syncPending=false
    var storageWarning=false
    var initialTab="nosabos"
    var animatedCharacters=true
    let onClose:()->Void
    @Environment(\.colorScheme) private var scheme
    @State private var activeTab="nosabos"
    private var source:AchievementTranscript{AchievementUI.source}
    private var colors:JSONValue{source.data["theme"][scheme == .dark ? "dark":"light"]}
    private var sections:[JSONValue]{source.sections(language:language,host:activeTab,unlocked:records)}
    private var count:Int{Int(sections.first?["count"].number ?? 0)}
    private var total:Int{sections.reduce(0){$0+Int($1["count"].number)}}
    private var percent:Double{total>0 ? Double(count)/Double(total)*100:0}
    private func color(_ key:String)->Color{FocusCopy.color(colors[key].string)}
    private func t(_ key:String)->String{source.text(key,language:language)}
    var body:some View{
        GeometryReader{g in
            ZStack{
                Rectangle().fill(.ultraThinMaterial).overlay{color("modalOverlay")}.ignoresSafeArea().onTapGesture(perform:onClose)
                VStack(spacing:0){
                    HStack{Spacer();Button(action:onClose){Image(systemName:"xmark").font(.system(size:15,weight:.regular)).frame(width:32,height:32).contentShape(Rectangle())}.foregroundStyle(color("textSecondary")).accessibilityLabel(t("close")).accessibilityIdentifier("achievementCollectionClose")}.padding(.horizontal,20).padding(.top,20).frame(height:56,alignment:.top).environment(\.layoutDirection,.leftToRight)
                    ScrollView{
                        VStack(alignment:.leading,spacing:0){
                            VStack(alignment:.leading,spacing:4){OnboardingText(text:t("title"),size:22,weight:.bold,lineHeight:33).tracking(-0.66).accessibilityAddTraits(.isHeader);AchievementParagraph(text:t("subtitle"),language:language,size:14,lineHeight:21,color:color("textSecondary"))}.padding(.bottom,20)
                            HStack(spacing:12){tab("nosabos","Piyali");tab("robotsbuildingeducation","Robots Building Education")}.padding(.bottom,24)
                            ForEach(Array(sections.enumerated()),id:\.offset){_,section in sectionView(section)}
                        }.padding(.horizontal,28).padding(.top,8).padding(.bottom,20).frame(maxWidth:.infinity,alignment:.leading)
                    }.scrollIndicators(.hidden).accessibilityIdentifier("achievementCollectionScroll")
                    footer
                }.frame(width:g.size.width*0.95,height:g.size.height*0.9).background(color("modalBg"),in:RoundedRectangle(cornerRadius:48,style:.circular)).clipShape(RoundedRectangle(cornerRadius:48,style:.circular)).overlay{RoundedRectangle(cornerRadius:48,style:.circular).stroke(scheme == .dark ? PiyaliBrand.unitColor("94a3b8").opacity(0.42):PiyaliBrand.unitColor("604d38").opacity(0.3),lineWidth:3).padding(1.5)}.accessibilityElement(children:.contain).accessibilityIdentifier("achievementCollection")
            }.frame(width:g.size.width,height:g.size.height)
        }.ignoresSafeArea(.container).foregroundStyle(color("textPrimary")).buttonStyle(.plain).environment(\.layoutDirection,source.locale(language) == "ar" ? .rightToLeft:.leftToRight).onAppear{activeTab=initialTab}
    }
    private func tab(_ id:String,_ title:String)->some View{let active=activeTab == id;return Button{activeTab=id}label:{Text(title).font(PiyaliBrand.productFont(12,700)).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true).padding(.horizontal,16).padding(.vertical,12).frame(maxWidth:.infinity,minHeight:54).background(color(active ? "tabActiveBg":"tabInactiveBg"),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).strokeBorder(color(active ? "tabActiveBorder":"tabInactiveBorder"))}}.compositingGroup().shadow(color:active ? .black.opacity(scheme == .dark ? 0.3:0.12):.clear,radius:6,x:0,y:4).foregroundStyle(color(active ? "tabActiveText":"tabInactiveText")).accessibilityIdentifier("achievementTab-"+id).accessibilityAddTraits(active ? .isSelected:[])}
    private func sectionView(_ section:JSONValue)->some View{
        let unlocked=section["status"].string == "unlocked",items=section["items"].array,rows=stride(from:0,to:items.count,by:2).map{Array(items[$0..<min(items.count,$0+2)])}
        return VStack(alignment:.leading,spacing:0){
            HStack(spacing:8){OnboardingText(text:t(unlocked ? "completed":"locked"),size:20,weight:.bold,lineHeight:30).accessibilityAddTraits(.isHeader);Text(source.number(items.count,language:language)).font(PiyaliBrand.productFont(12,700)).padding(.horizontal,10).frame(minHeight:18).foregroundStyle(color(unlocked ? "badgeCompletedColor":"badgeUncompletedColor")).background(color(unlocked ? "badgeCompletedBg":"badgeUncompletedBg"),in:Capsule())}.padding(.bottom,16)
            if unlocked && items.isEmpty{OnboardingText(text:t("empty"),size:14,lineHeight:21).foregroundStyle(color("textSecondary")).padding(.bottom,16).accessibilityIdentifier("achievementCollectionEmpty")}
            LazyVStack(spacing:12){ForEach(Array(rows.enumerated()),id:\.offset){_,row in AchievementCardRow{ForEach(row,id:\.canonicalJSON){item in card(item,unlocked:unlocked)};if row.count == 1{Color.clear}}}}
        }.padding(.bottom,28)
    }
    private func card(_ item:JSONValue,unlocked:Bool)->some View{
        VStack(spacing:0){
            AchievementCharacter(orb:item["orb"],animated:animatedCharacters).frame(width:76,height:76).saturation(unlocked ? 1:0).contrast(unlocked ? 1:0.85).opacity(unlocked ? 1:0.45).padding(.vertical,4).accessibilityHidden(true)
            AchievementParagraph(text:item["title"].string,language:language,size:12,weight:.bold,lineHeight:15.6,color:color("textPrimary"),alignment:.center).padding(.top,8).padding(.bottom,4)
            AchievementParagraph(text:item["desc"].string,language:language,size:10,lineHeight:14,color:color("textSecondary"),alignment:.center)
            Spacer(minLength:0)
        }.multilineTextAlignment(.center).frame(maxWidth:.infinity).padding(14+(unlocked ? 2:1)).background(color(unlocked ? "cardBgCompleted":"cardBgUncompleted"),in:RoundedRectangle(cornerRadius:18)).overlay{RoundedRectangle(cornerRadius:18).strokeBorder(color(unlocked ? "cardBorderCompleted":"cardBorderUncompleted"),lineWidth:unlocked ? 2:1)}.compositingGroup().shadow(color:unlocked ? PiyaliBrand.unitColor("eab308").opacity(scheme == .dark ? 0.14:0.16):.clear,radius:7,x:0,y:4).accessibilityElement(children:.ignore).accessibilityLabel(item["title"].string+". "+item["desc"].string+" "+t(unlocked ? "completed":"locked")).accessibilityIdentifier("achievementCard-"+item["id"].string)
    }
    private var footer:some View{
        VStack(spacing:8){
            if syncPending || storageWarning{Text(t(storageWarning ? "storageWarning":"syncPending")).font(PiyaliBrand.productFont(12)).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("achievementSyncStatus")}
            HStack{OnboardingText(text:source.text("collectionLabel",language:language,values:["count":source.number(count,language:language),"total":source.number(total,language:language)]),size:12,weight:.semibold,lineHeight:18).accessibilityIdentifier("achievementCollectionCount");Spacer();OnboardingText(text:"\(Int(percent.rounded()))%",size:12,weight:.bold,lineHeight:18).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("38f9d7"):PiyaliBrand.unitColor("319795"))}
            FocusWaveBar(percent:percent,background:color("waveBg"),border:color("waveBorder"),gradientOpacity:0.95,waveOpacity:0.22)
        }.foregroundStyle(color("textSecondary")).padding(.horizontal,28).padding(.top,16).padding(.bottom,28).background{Rectangle().fill(color("footerBg"))}.overlay(alignment:.top){color("border").frame(height:1)}
    }
}

private struct AchievementCardRow:Layout {
    func sizeThatFits(proposal:ProposedViewSize,subviews:Subviews,cache:inout())->CGSize{let w=proposal.width ?? 348,cell=(w-12)/2;return CGSize(width:w,height:subviews.map{$0.sizeThatFits(.init(width:cell,height:nil)).height}.max() ?? 0)}
    func placeSubviews(in bounds:CGRect,proposal:ProposedViewSize,subviews:Subviews,cache:inout()){let cell=(bounds.width-12)/2;for(i,view)in subviews.enumerated(){view.place(at:CGPoint(x:bounds.minX+CGFloat(i)*(cell+12),y:bounds.minY),anchor:.topLeading,proposal:.init(width:cell,height:bounds.height))}}
}

private struct AchievementCharacter:View {
    let orb:JSONValue
    var animated=true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reaction:OrbDisplayReaction?
    var body:some View{VoiceOrbView(callActive:true,personality:.init(mood:orb["mood"].string,state:orb["state"].string,reaction:orb["reaction"].string),displayReaction:reaction,dark:true,reducedMotion:reduceMotion || !animated,achievement:orb).task(id:reduceMotion){guard !reduceMotion,animated else{return};while !Task.isCancelled{reaction = .init(kind:orb["reaction"].string);let duration=AchievementUI.source.data["visuals"]["durations"][orb["reaction"].string].number;do{try await Task.sleep(for:.seconds(duration+3.5))}catch{return}}}.allowsHitTesting(false)}
}

/// Web paragraphs use greedy wrapping and an explicit document direction.
private struct AchievementParagraph:UIViewRepresentable {
    let text:String,language:String
    var size:CGFloat
    var weight:UIFont.Weight = .regular
    var lineHeight:CGFloat
    var color:Color
    var alignment:NSTextAlignment = .natural
    @ScaledMetric private var scale:CGFloat=1000
    func makeUIView(context:Context)->UILabel{let label=UILabel();label.numberOfLines=0;label.setContentCompressionResistancePriority(.defaultLow,for:.horizontal);return label}
    func updateUIView(_ label:UILabel,context:Context){let paragraph=NSMutableParagraphStyle();paragraph.alignment=alignment == .natural ? (AchievementUI.source.locale(language) == "ar" ? .right:.left):alignment;paragraph.baseWritingDirection=AchievementUI.source.locale(language) == "ar" ? .rightToLeft:.leftToRight;paragraph.lineBreakMode = .byWordWrapping;paragraph.lineBreakStrategy=[];paragraph.minimumLineHeight=lineHeight*scale/1000;paragraph.maximumLineHeight=lineHeight*scale/1000;label.attributedText=NSAttributedString(string:text,attributes:[.font:UIFont.systemFont(ofSize:size*scale/1000,weight:weight),.foregroundColor:UIColor(color),.paragraphStyle:paragraph]);label.accessibilityLabel=text}
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UILabel,context:Context)->CGSize?{let width=proposal.width ?? 326;uiView.preferredMaxLayoutWidth=width;let size=uiView.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude));return CGSize(width:width,height:ceil(size.height))}
}
