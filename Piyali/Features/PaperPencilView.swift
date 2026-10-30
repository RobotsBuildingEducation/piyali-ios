import SwiftUI

enum PaperPencilCopy {
    static let source=(try? ContentLibrary.load(JSONValue.self,name:"paper-pencil-ui")) ?? .null
    static func text(_ language:String,_ key:String)->String{let copy=source["copy"][language] == .null ? source["copy"]["en"]:source["copy"][language];return copy["paper_pencil_"+key].string}
}
struct PaperPencilView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let onClose:()->Void
    var onPanelSize:((CGSize)->Void)?=nil
    @State private var headerHeight:CGFloat=75
    @State private var bodyHeight:CGFloat=350
    private var dark:Bool{scheme == .dark}
    private var brand:PiyaliBrand{.init(dark:dark)}
    private func t(_ key:String)->String{PaperPencilCopy.text(app.learner.support,key)}
    var body:some View {
        GeometryReader{g in
            let small=g.size.width<480,phone=g.size.width<768,radius:CGFloat=phone ? 24:72,width=min(small ? g.size.width*0.9:448,g.size.width-24),bodyPadding:CGFloat=phone ? 18:40
            let panelHeight=min(g.size.height-24,headerHeight+bodyHeight),panelBounds=CGRect(x:(g.size.width-width)/2,y:(g.size.height-panelHeight)/2,width:width,height:panelHeight)
            VStack(spacing:0){
                header(phone:phone).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){headerHeight=$0}
                ScrollView{
                    VStack(spacing:phone ? 14:16){
                        BrandArtwork(name:"paper-pencil-manga.webp").frame(maxWidth:.infinity).frame(height:min((width-bodyPadding*2)*448/960,small ? 172:196)).accessibilityHidden(true).accessibilityIdentifier("paperPencilArtwork")
                        OnboardingText(text:t("message"),size:small ? 12:14,weight:.medium,lineHeight:small ? 18:21).multilineTextAlignment(.center).padding(.horizontal,phone ? 4:8).accessibilityIdentifier("paperPencilMessage")
                        OnboardingText(text:t("tip"),size:small ? 10:12,weight:.semibold,lineHeight:small ? 14:17).foregroundStyle(PiyaliBrand.unitColor(dark ? "b2f5ea":"0f766e")).multilineTextAlignment(.center).frame(maxWidth:.infinity).padding(.horizontal,phone ? 13:17).padding(.vertical,phone ? 11:13).background(dark ? PiyaliBrand.teal.opacity(0.12):PiyaliBrand.unitColor("f0fdfa"),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).strokeBorder((dark ? PiyaliBrand.unitColor("2dd4bf"):PiyaliBrand.teal).opacity(dark ? 0.25:0.28))}
                        Button(t("understood"),action:onClose).buttonStyle(PaperPencilActionStyle(wide:!phone)).accessibilityIdentifier("paperPencilUnderstood")
                    }.padding(.horizontal,bodyPadding).padding(.top,phone ? 16:32).padding(.bottom,phone ? 28:40).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){bodyHeight=$0}
                }.scrollBounceBehavior(.basedOnSize).accessibilityIdentifier("paperPencilScroll")
            }.frame(width:width,height:panelHeight).background(dark ? brand.background:brand.surface,in:RoundedRectangle(cornerRadius:radius,style:.circular)).clipShape(RoundedRectangle(cornerRadius:radius,style:.circular)).overlay{RoundedRectangle(cornerRadius:radius,style:.circular).strokeBorder(PiyaliBrand.unitColor(dark ? "94a3b8":"604d38").opacity(dark ? 0.42:0.3),lineWidth:3).allowsHitTesting(false)}.contentShape(RoundedRectangle(cornerRadius:radius)).onTapGesture{}.compositingGroup().shadow(color:(dark ? Color.black:PiyaliBrand.unitColor("6f5636")).opacity(dark ? 0.35:0.08),radius:9,y:8).onGeometryChange(for:CGSize.self,of:{$0.size}){onPanelSize?($0)}.frame(maxWidth:.infinity,maxHeight:.infinity).contentShape(Rectangle()).simultaneousGesture(SpatialTapGesture().onEnded{tap in if !RoundedRectangle(cornerRadius:radius,style:.circular).path(in:panelBounds).contains(tap.location){onClose()}})
        }.foregroundStyle(dark ? PiyaliBrand.unitColor("f7fafc"):brand.text).accessibilityElement(children:.contain).accessibilityIdentifier("paperPencilDialog").accessibilityAddTraits(.isModal).accessibilityAction(.escape,onClose)
    }
    private func header(phone:Bool)->some View {
        VStack(spacing:phone ? 4:6){
            OnboardingText(text:t("title"),size:phone ? 16:18,weight:.bold,lineHeight:phone ? 24:27).shadow(color:.black.opacity(0.16),radius:5,y:1).accessibilityAddTraits(.isHeader).accessibilityIdentifier("paperPencilTitle")
            OnboardingText(text:t("subtitle"),size:phone ? 10:12,weight:.medium,lineHeight:phone ? 13:16).foregroundStyle(.white.opacity(0.92)).frame(maxWidth:320)
        }.multilineTextAlignment(.center).foregroundStyle(.white).frame(maxWidth:.infinity).padding(.horizontal,phone ? 16:48).padding(.vertical,phone ? 16:26).padding(.bottom,1).background{LinearGradient(colors:[PiyaliBrand.unitColor("38b2ac"),PiyaliBrand.unitColor("319795")],startPoint:UnitPoint(x:0,y:0.5),endPoint:UnitPoint(x:1,y:0.5))}.overlay(alignment:.bottom){Rectangle().fill(PiyaliBrand.teal.opacity(dark ? 0:0.22)).frame(height:1)}
    }
}
struct PaperPencilDialog:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var phase
    @State private var sounds=PracticeSoundPlayer()
    let onClose:()->Void
    var body:some View {ZStack{
        (scheme == .dark ? PiyaliBrand.unitColor("020617").opacity(0.92):PiyaliBrand.unitColor("1c140c").opacity(0.82)).ignoresSafeArea().onTapGesture(perform:close)
        PaperPencilView(onClose:close).ignoresSafeArea()
    }.environment(\.layoutDirection,app.learner.support == "ar" ? .rightToLeft:.leftToRight)}
    private func close(){onClose();let account=app.identity.npub;Task{try? await Task.sleep(for:.milliseconds(32));guard app.signedIn,app.identity.npub == account,phase == .active else{return};sounds.play("submitAction",enabled:app.learner.soundEffectsEnabled,volume:app.learner.settingsSnapshot["soundVolume"] == .null ? 100:app.learner.settingsSnapshot["soundVolume"].number)}}
}
private struct PaperPencilActionStyle:ButtonStyle {
    var wide=false
    func makeBody(configuration:Configuration)->some View{configuration.label.font(PiyaliBrand.productFont(16,700)).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:wide ? 66:44).background(RoundedRectangle(cornerRadius:8).fill(PiyaliBrand.unitColor(configuration.isPressed ? "38b2ac":"319795")).shadow(color:PiyaliBrand.unitColor("234e52"),radius:0,y:configuration.isPressed ? 0:4)).offset(y:configuration.isPressed ? 3:0)}
}
