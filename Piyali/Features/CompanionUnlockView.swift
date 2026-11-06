import SwiftUI

@MainActor enum CompanionUnlockUI {
    private static let data=(try? ContentLibrary.load(JSONValue.self,name:"companion-unlock-ui")) ?? .null
    static func copy(_ language:String)->JSONValue{data["copy"][language] == .null ? data["copy"]["en"]:data["copy"][language]}
}
struct CompanionUnlockView:View {
    let item:CompanionUnlock,language:String
    var animated=true
    let onEquip:()->Void,onKeep:()->Void
    @Environment(\.colorScheme) private var scheme
    @State private var height:CGFloat=450
    private var copy:JSONValue{CompanionUnlockUI.copy(language)}
    var body:some View {
        GeometryReader{geometry in
            ZStack{
                PiyaliBrand.unitColor(scheme == .dark ? "020617":"1c140c").opacity(scheme == .dark ? 0.92:0.82).ignoresSafeArea()
                ScrollView{
                    VStack(spacing:24){
                        VStack(spacing:8){CompanionUnlockParagraph(text:copy["title"].string.replacingOccurrences(of:"{companion}",with:item.name),size:24,weight:.bold,lineHeight:36).offset(y:-4);CompanionUnlockParagraph(text:copy["subtitle"].string.replacingOccurrences(of:"{level}",with:String(item.unlockLevel)),size:16,lineHeight:23,color:.white.opacity(0.9)).offset(y:-2)}
                        companion
                        VStack(spacing:16){Button(copy["equip"].string,action:onEquip).buttonStyle(CompanionUnlockAction(primary:true)).accessibilityIdentifier("companionUnlockEquip");Button(copy["keep"].string,action:onKeep).buttonStyle(CompanionUnlockAction(primary:false)).accessibilityIdentifier("companionUnlockKeep")}
                    }.multilineTextAlignment(.center).padding(28).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){height=$0}
                }.scrollBounceBehavior(.basedOnSize).frame(width:min(448,geometry.size.width*0.9),height:min(height,geometry.size.height-32)).background{SourceCelebrationGradient(colors:[PiyaliBrand.unitColor("0891b2"),PiyaliBrand.unitColor("06b6d4"),PiyaliBrand.unitColor("0e7490")],locations:[0,0.42,1]).clipShape(RoundedRectangle(cornerRadius:48))}.overlay{RoundedRectangle(cornerRadius:48).strokeBorder(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).allowsHitTesting(false)}.compositingGroup().shadow(color:PiyaliBrand.unitColor("0891b2").opacity(0.52),radius:40,y:28).accessibilityIdentifier("companionUnlockDialog")
            }.frame(width:geometry.size.width,height:geometry.size.height)
        }.ignoresSafeArea(.container).foregroundStyle(.white).environment(\.layoutDirection,.leftToRight).accessibilityElement(children:.contain)
    }
    private var companion:some View {
        HStack(alignment:.top,spacing:12){
            VStack(spacing:6){CompanionArtwork(type:item.type,health:100,animated:animated).frame(width:96,height:96).background(.white.opacity(0.74),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).strokeBorder(PiyaliBrand.unitColor("0ea5e9").opacity(0.18))};Text(copy["pet"]["happy"].string.uppercased()).font(PiyaliBrand.productFont(9.92,700)).padding(.horizontal,8).padding(.vertical,1.4).background(PiyaliBrand.unitColor("06b6d4").opacity(0.16),in:RoundedRectangle(cornerRadius:6)).foregroundStyle(PiyaliBrand.unitColor("0f766e"))}
            VStack(alignment:.leading,spacing:8){OnboardingText(text:item.name,size:14,weight:.bold,lineHeight:15.4).frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(PiyaliBrand.unitColor("1f2937"));VStack(spacing:6){HStack(spacing:8){SessionIcon(name:"FiHeart",size:14).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "fbd38d":"ce7a8c"));Text(copy["pet"]["health"].string).font(PiyaliBrand.productFont(12,600)).foregroundStyle(PiyaliBrand.unitColor("0f766e"));Spacer(minLength:0);Text("100%").font(PiyaliBrand.productFont(14,700)).foregroundStyle(PiyaliBrand.unitColor("1f2937"))};FocusWaveBar(percent:100,height:14,background:.white.opacity(scheme == .dark ? 0.22:0.58),border:scheme == .dark ? .white.opacity(0.14):PiyaliBrand.unitColor("5b4b3a").opacity(0.1))}}
        }.padding(11).background(LinearGradient(colors:[PiyaliBrand.unitColor("fcfeff").opacity(0.96),PiyaliBrand.unitColor("e8faff").opacity(0.92)],startPoint:.top,endPoint:.bottom),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).strokeBorder(PiyaliBrand.unitColor("cffafe").opacity(0.86))}.compositingGroup().shadow(color:PiyaliBrand.unitColor("0891b2").opacity(0.16),radius:19,y:18)
    }
}
private struct CompanionUnlockAction:ButtonStyle {
    let primary:Bool
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration:Configuration)->some View{configuration.label.font(PiyaliBrand.productFont(primary ? 18:16,primary ? 700:600)).frame(maxWidth:.infinity).frame(height:primary ? 50:40).foregroundStyle(primary ? PiyaliBrand.unitColor("0e7490"):.white).background{if primary{Capsule().fill(.white).shadow(color:configuration.isPressed ? .clear:PiyaliBrand.unitColor(scheme == .dark ? "3886f3":"2f7cf7"),radius:0,y:4)}}.contentShape(Capsule()).offset(y:configuration.isPressed ? 4:0)}
}
@MainActor struct CompanionUnlockGateView:View {
    @EnvironmentObject var app:AppModel
    let blocked:()->Bool,onShow:()->Void
    private func presented(_ controller:UIViewController)->Bool{controller.presentedViewController != nil || controller.children.contains{presented($0)}}
    private var hasModal:Bool{UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.flatMap(\.windows).filter{!$0.isHidden}.contains{$0.rootViewController.map{presented($0)} ?? false}}
    var body:some View{Color.clear.frame(width:0,height:0).task(id:app.companionUnlockRevision){
        guard app.companionUnlock == nil else{return}
        while !Task.isCancelled,!app.pendingCompanionUnlocks.isEmpty{
            let now=Date().timeIntervalSince1970*1000
            if app.pollCompanionUnlock(now:now,blocked:blocked() || hasModal) != nil{onShow();return}
            guard !app.pendingCompanionUnlocks.isEmpty else{return}
            do{try await Task.sleep(for:.milliseconds(Int(max(1,ceil(app.companionUnlockDelay(now:Date().timeIntervalSince1970*1000))))))}catch{return}
        }
    }}
}

/// The source portal keeps CSS direction:ltr even for Arabic paragraphs.
private struct CompanionUnlockParagraph:UIViewRepresentable {
 let text:String
 var size:CGFloat,weight:UIFont.Weight = .regular,lineHeight:CGFloat,color:Color = .white
 @ScaledMetric private var scale:CGFloat=1000
 func makeUIView(context:Context)->UILabel{let label=UILabel();label.numberOfLines=0;label.setContentCompressionResistancePriority(.defaultLow,for:.horizontal);return label}
 func updateUIView(_ label:UILabel,context:Context){let paragraph=NSMutableParagraphStyle();paragraph.alignment = .center;paragraph.baseWritingDirection = .leftToRight;paragraph.lineBreakMode = .byWordWrapping;paragraph.lineBreakStrategy=[];paragraph.minimumLineHeight=lineHeight*scale/1000;paragraph.maximumLineHeight=lineHeight*scale/1000;label.attributedText=NSAttributedString(string:text,attributes:[.font:UIFont.systemFont(ofSize:size*scale/1000,weight:weight),.foregroundColor:UIColor(color),.paragraphStyle:paragraph]);label.accessibilityLabel=text}
 func sizeThatFits(_ proposal:ProposedViewSize,uiView:UILabel,context:Context)->CGSize?{let width=proposal.width ?? 306;uiView.preferredMaxLayoutWidth=width;return CGSize(width:width,height:ceil(uiView.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude)).height))}
}
