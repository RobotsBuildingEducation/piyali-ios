import SwiftUI

struct PlateCelebrationView:View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduced
    let data:JSONValue
    let language:String
    let onContinue:()->Void
    let onNotes:()->Void
    @State private var detailsOpen=false
    @State private var sparkleStart=Date()
    @State private var height:CGFloat=540
    private static let detailsCopy=(try? ContentLibrary.load([String:JSONValue].self,name:"plate-completion-copy")) ?? [:]
    private var cleared:Bool {data["type"].string == "cleared"}
    private func t(_ key:String)->String {ProductCopy.text(language,key)}
    private func detail(_ key:String)->String {(Self.detailsCopy[language] ?? Self.detailsCopy["en"] ?? .null)[key].string}
    var body:some View {
        GeometryReader{geometry in
            ZStack {
                (scheme == .dark ? Color(red:2/255,green:6/255,blue:23/255).opacity(0.92):Color(red:28/255,green:20/255,blue:12/255).opacity(0.82)).ignoresSafeArea()
                ScrollView {
                    VStack(spacing:24){
                        portrait
                        VStack(spacing:8){OnboardingText(text:t(cleared ? "PLATE_CLEARED_COPY":"PLATE_EXERCISE_COMPLETE_COPY"),size:30,weight:.bold,lineHeight:45)
                            OnboardingText(text:cleared ? t("PLATE_BONUS_TOAST_COPY"):ProductCopy.course(language,data["completed"].string)+progress+" ✓",size:cleared ? 16:18,lineHeight:cleared ? 24:27).opacity(0.9)}
                        if !data["details"]["what"].string.isEmpty || !data["details"]["why"].string.isEmpty {details}
                        if cleared {VStack(spacing:4){OnboardingText(text:language == "ar" ? "\u{202B}+\(DailyPlate.bonus)\u{202C}":"+\(DailyPlate.bonus)",size:48,weight:.bold,lineHeight:72).foregroundStyle(PiyaliBrand.unitColor("faf089"));OnboardingText(text:"XP",size:14,lineHeight:21).tracking(0.7).opacity(0.85)}.frame(maxWidth:.infinity).padding(.vertical,26).padding(.horizontal,34).background(.white.opacity(0.2),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.4),lineWidth:2)}}
                        else if !data["next"].string.isEmpty {HStack(spacing:12){OnboardingText(text:t("PLATE_NEXT_COPY"),size:14,lineHeight:21).tracking(0.7).textCase(.uppercase).opacity(0.85);Image("Focus-course-"+data["next"].string).renderingMode(.template).resizable().frame(width:18,height:18);OnboardingText(text:ProductCopy.course(language,data["next"].string),size:16,weight:.bold,lineHeight:24)}.frame(maxWidth:.infinity).padding(.vertical,18).padding(.horizontal,26).background(.white.opacity(0.18),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.35),lineWidth:2)}}
                        Button(t(cleared ? "PLATE_CLOSE_COPY":"PLATE_CONTINUE_COPY"),action:onContinue).font(PiyaliBrand.productFont(18,700)).foregroundStyle(PiyaliBrand.unitColor(cleared ? "c05621":"2c7a7b")).frame(maxWidth:.infinity,minHeight:50).background{Capsule().fill(.white).shadow(color:PiyaliBrand.unitColor(cleared ? "9a3412":"2c7a7b").opacity(0.58),radius:0,y:4)}.accessibilityIdentifier("guidedContinue")
                        if cleared {Button(t("PLATE_VIEW_NOTES_COPY"),action:onNotes).font(PiyaliBrand.productFont(16,600)).frame(maxWidth:.infinity,minHeight:40).padding(.top,-8).accessibilityIdentifier("plateViewNotes")}
                    }.multilineTextAlignment(.center).padding(28).frame(maxWidth:.infinity).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){height=$0}
                }.frame(width:min(448,geometry.size.width*0.9),height:min(height,geometry.size.height-48)).foregroundStyle(.white).background{SourceCelebrationGradient(colors:cleared ? [PiyaliBrand.unitColor("f59e0b"),PiyaliBrand.unitColor("d97706")]:[PiyaliBrand.unitColor("10b981"),PiyaliBrand.unitColor("0d9488")]).clipShape(RoundedRectangle(cornerRadius:48))}.overlay{RoundedRectangle(cornerRadius:48).strokeBorder(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).allowsHitTesting(false)}.shadow(color:.black.opacity(0.25),radius:24,y:25)
            }.frame(width:geometry.size.width,height:geometry.size.height)
        }.ignoresSafeArea(.container).buttonStyle(.plain).accessibilityElement(children:.contain).accessibilityIdentifier("plateCelebration")
    }
    private var progress:String {data["progress"] == .null ? "":" \(Int(data["progress"]["count"].number))/\(Int(data["progress"]["target"].number))"}
    private var portrait:some View {
        ZStack {
            BrandArtwork(name:cleared ? "story-portrait-29.webp":"story-portrait-25.webp").frame(width:96,height:96).padding(20).background(.white.opacity(0.2),in:Circle()).overlay{Circle().stroke(.white.opacity(0.3),lineWidth:2)}.shadow(color:.black.opacity(0.18),radius:20,y:20)
            TimelineView(.animation(minimumInterval:1/30,paused:reduced)){clock in ZStack{
                ForEach(0..<6){index in let angle=Double(index)*Double.pi/3,time=clock.date.timeIntervalSince(sparkleStart)-Double(index)*0.45,phase=max(0,time).truncatingRemainder(dividingBy:2.4)/2.4,glow=reduced ? 0.65:time<0 ? 0:(1-cos(phase*2*Double.pi))/2
                    QuestSparkleShape().fill(.white).frame(width:CGFloat(20+4*(index%3)),height:CGFloat(20+4*(index%3))).shadow(color:.white.opacity(0.33),radius:2).opacity(glow*0.85).scaleEffect(0.4+glow*0.6).rotationEffect(.degrees(glow*45)).offset(x:CGFloat(cos(angle))*70,y:CGFloat(sin(angle))*70)
                }
            }}

        }.frame(width:136,height:136)
    }
    private var details:some View {
        VStack(spacing:0){Button{detailsOpen.toggle()}label:{HStack{OnboardingText(text:detail("title"),size:16,weight:.bold,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,.leftToRight);Image(systemName:detailsOpen ? "chevron.up":"chevron.down").font(.system(size:14))}.padding(.vertical,13).padding(.horizontal,16).contentShape(Rectangle())}.accessibilityIdentifier("platePracticeDetails").accessibilityValue(detailsOpen ? "Expanded":"Collapsed")
            if detailsOpen {VStack(alignment:.leading,spacing:12){if !data["details"]["what"].string.isEmpty {detailRow("what")};if !data["details"]["why"].string.isEmpty{detailRow("why")}}.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,16).padding(.bottom,16)}
        }.multilineTextAlignment(.leading).padding(1).background(.white.opacity(0.14),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.35)).allowsHitTesting(false)}
    }
    private func detailRow(_ key:String)->some View {VStack(alignment:.leading,spacing:4){Text(detail(key)).font(PiyaliBrand.productFont(12,700)).textCase(.uppercase).opacity(0.78);OnboardingText(text:data["details"][key].string,size:16,lineHeight:24)}}
}

private struct QuestSparkleShape:Shape {
    func path(in rect:CGRect)->Path {
        var p=Path();let x=rect.width/24,y=rect.height/24
        p.move(to:CGPoint(x:12*x,y:0));p.addQuadCurve(to:CGPoint(x:24*x,y:12*y),control:CGPoint(x:13.4*x,y:10.6*y));p.addQuadCurve(to:CGPoint(x:12*x,y:24*y),control:CGPoint(x:13.4*x,y:13.4*y));p.addQuadCurve(to:CGPoint(x:0,y:12*y),control:CGPoint(x:10.6*x,y:13.4*y));p.addQuadCurve(to:CGPoint(x:12*x,y:0),control:CGPoint(x:10.6*x,y:10.6*y));p.closeSubpath();return p
    }
}

/// UIKit draws the source's 135-degree sRGB gradient without SwiftUI's
/// perceptual-gradient dithering. The equal x/y projection matches CSS in a
/// tall modal; corner-to-corner endpoints would change the source colors.
struct SourceCelebrationGradient:UIViewRepresentable {
    let colors:[Color]
    func makeUIView(context:Context)->SourceGradientLayerView {SourceGradientLayerView()}
    func updateUIView(_ view:SourceGradientLayerView,context:Context){(view.layer as? CAGradientLayer)?.colors=colors.map{UIColor($0).cgColor}}
}
final class SourceGradientLayerView:UIView {
    override class var layerClass:AnyClass {CAGradientLayer.self}
    override func layoutSubviews(){super.layoutSubviews();guard let gradient=layer as? CAGradientLayer else{return};let span=(bounds.width+bounds.height)/4
        CATransaction.begin();CATransaction.setDisableActions(true)
        gradient.startPoint=CGPoint(x:0.5-span/max(1,bounds.width),y:0.5-span/max(1,bounds.height));gradient.endPoint=CGPoint(x:0.5+span/max(1,bounds.width),y:0.5+span/max(1,bounds.height));CATransaction.commit()
    }
}
