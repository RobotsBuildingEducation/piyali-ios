import SwiftUI

enum PaperPencilCopy {
    static let source=(try? ContentLibrary.load(JSONValue.self,name:"paper-pencil-ui")) ?? .null
    static func text(_ language:String,_ key:String)->String{let copy=source["copy"][language] == .null ? source["copy"]["en"]:source["copy"][language];return copy["paper_pencil_"+key].string}
}
struct PaperPencilView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let onClose:()->Void
    var animated=true
    @State private var headerHeight:CGFloat=140
    @State private var bodyHeight:CGFloat=460
    private var dark:Bool{scheme == .dark}
    private var brand:PiyaliBrand{PiyaliBrand(dark:dark)}
    private func t(_ key:String)->String{PaperPencilCopy.text(app.learner.support,key)}
    var body:some View {
        GeometryReader{g in
            VStack(spacing:0){
                header.onGeometryChange(for:CGFloat.self,of:{$0.size.height}){headerHeight=$0}
                ScrollView{
                    VStack(spacing:14){
                        PaperPencilIllustration(animated:animated)
                        OnboardingText(text:t("message"),size:12,weight:.medium,lineHeight:18.6).multilineTextAlignment(.center).padding(.horizontal,4).accessibilityIdentifier("paperPencilMessage")
                        OnboardingText(text:t("tip"),size:10,weight:.semibold,lineHeight:14.5).foregroundStyle(PiyaliBrand.unitColor(dark ? "b2f5ea":"0f766e")).multilineTextAlignment(.center).frame(maxWidth:.infinity).padding(.horizontal,12).padding(.vertical,10).background(dark ? PiyaliBrand.teal.opacity(0.12):PiyaliBrand.unitColor("f0fdfa"),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke((dark ? PiyaliBrand.unitColor("2dd4bf"):PiyaliBrand.teal).opacity(dark ? 0.25:0.28))}
                        Button(t("understood"),action:onClose).buttonStyle(PaperPencilActionStyle()).accessibilityIdentifier("paperPencilUnderstood")
                    }.padding(.horizontal,18).padding(.top,16).padding(.bottom,28).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){bodyHeight=$0}
                }.scrollBounceBehavior(.basedOnSize).accessibilityIdentifier("paperPencilScroll")
            }.frame(width:min(g.size.width*0.9,448),height:min(g.size.height-24,headerHeight+bodyHeight)).background(dark ? brand.background:brand.surface,in:RoundedRectangle(cornerRadius:24,style:.circular)).clipShape(RoundedRectangle(cornerRadius:24,style:.circular)).overlay{RoundedRectangle(cornerRadius:24,style:.circular).stroke(PiyaliBrand.unitColor(dark ? "94a3b8":"604d38").opacity(dark ? 0.42:0.3),lineWidth:3).padding(1.5).allowsHitTesting(false)}.compositingGroup().shadow(color:(dark ? Color.black:PiyaliBrand.unitColor("6f5636")).opacity(dark ? 0.35:0.08),radius:9,y:8).frame(maxWidth:.infinity,maxHeight:.infinity)
        }.foregroundStyle(dark ? PiyaliBrand.unitColor("f7fafc"):brand.text).accessibilityElement(children:.contain).accessibilityIdentifier("paperPencilDialog").accessibilityAction(.escape,onClose)
    }
    private var header:some View {
        VStack(spacing:6){Image("PaperPencil-header").resizable().frame(width:42,height:42).frame(width:54,height:54).background(.white.opacity(0.2),in:RoundedRectangle(cornerRadius:20)).overlay{RoundedRectangle(cornerRadius:20).strokeBorder(.white.opacity(0.42),lineWidth:1.5)}.compositingGroup().shadow(color:PiyaliBrand.unitColor("0d9488").opacity(0.28),radius:8,y:6).accessibilityHidden(true)
            OnboardingText(text:t("title"),size:16,weight:.bold,lineHeight:24).shadow(color:.black.opacity(0.16),radius:5,y:1).accessibilityAddTraits(.isHeader).accessibilityIdentifier("paperPencilTitle")
            OnboardingText(text:t("subtitle"),size:10,weight:.medium,lineHeight:13.5).foregroundStyle(.white.opacity(0.92)).frame(maxWidth:320)
        }.multilineTextAlignment(.center).foregroundStyle(.white).frame(maxWidth:.infinity).padding(.horizontal,16).padding(.vertical,14).background{LinearGradient(colors:[PiyaliBrand.unitColor("38b2ac"),PiyaliBrand.unitColor("319795")],startPoint:UnitPoint(x:0,y:0.5),endPoint:UnitPoint(x:1,y:0.5))}.overlay(alignment:.bottom){Rectangle().fill(PiyaliBrand.teal.opacity(dark ? 0:0.22)).frame(height:1)}
    }
}
struct PaperPencilIllustration:View {
    var animated=true
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @State private var began=Date()
    private var prefix:String{"PaperPencil-"+(scheme == .dark ? "dark":"light")+"-"}
    var body:some View {
        GeometryReader{g in
            let scale=g.size.width/340
            TimelineView(.animation(minimumInterval:1/30,paused:!animated || reduceMotion || phase != .active)){clock in
                let t=clock.date.timeIntervalSince(began),p=animated && !reduceMotion ? PaperPencilMotion.pulse(t,layer:0):0,l=animated && !reduceMotion ? PaperPencilMotion.pulse(t,layer:1):0,r=animated && !reduceMotion ? PaperPencilMotion.pulse(t,layer:2):0
                ZStack{layer("base");layer("pencil").rotationEffect(.degrees(-1.2*p),anchor:UnitPoint(x:210/340,y:92/196)).offset(x:-2*p*scale,y:-3.5*p*scale);layer("sparkle-left").scaleEffect(1-0.18*l,anchor:UnitPoint(x:68/340,y:42/196)).opacity(animated && !reduceMotion ? 0.92-0.47*l:1);layer("sparkle-right").scaleEffect(1-0.18*r,anchor:UnitPoint(x:282/340,y:68/196)).opacity(animated && !reduceMotion ? PaperPencilMotion.sparkleOpacity(t,layer:2):1);layer("tail")}
            }
        }.aspectRatio(340/196,contentMode:.fit).frame(maxWidth:320).frame(maxWidth:.infinity).padding(9.5).background{GeometryReader{g in
            // CSS 145deg: project the rectangle's corners onto the gradient direction.
            let dx=sin(145*Double.pi/180),dy = -cos(145*Double.pi/180),length=abs(g.size.width*dx)+abs(g.size.height*dy),halfX=dx*length/(2*g.size.width),halfY=dy*length/(2*g.size.height)
            LinearGradient(stops:scheme == .dark ? [.init(color:FocusCopy.color("rgba(19,42,46,0.95)"),location:0),.init(color:FocusCopy.color("rgba(30,32,48,0.95)"),location:0.55),.init(color:FocusCopy.color("rgba(46,29,44,0.92)"),location:1)]:[.init(color:PiyaliBrand.unitColor("f0fdfa"),location:0),.init(color:PiyaliBrand.unitColor("fffdf9"),location:0.52),.init(color:PiyaliBrand.unitColor("fff1f2"),location:1)],startPoint:UnitPoint(x:0.5-halfX,y:0.5-halfY),endPoint:UnitPoint(x:0.5+halfX,y:0.5+halfY))
        }.clipShape(RoundedRectangle(cornerRadius:22))}.overlay{RoundedRectangle(cornerRadius:22).strokeBorder((scheme == .dark ? PiyaliBrand.unitColor("2dd4bf"):PiyaliBrand.teal).opacity(scheme == .dark ? 0.28:0.26),lineWidth:1.5)}.compositingGroup().shadow(color:(scheme == .dark ? Color.black:PiyaliBrand.unitColor("0d9488")).opacity(scheme == .dark ? 0.35:0.10),radius:13,y:10).accessibilityElement(children:.ignore).accessibilityLabel("Cute anime illustration of a notebook and pencil")
    }
    private func layer(_ name:String)->some View{Image(prefix+name).resizable().aspectRatio(contentMode:.fit)}
}
enum PaperPencilMotion {
    static func sparkleOpacity(_ time:Double,layer:Int)->Double{time < PaperPencilCopy.source["animations"].array[layer]["delay"].number ? 1:0.92-0.47*pulse(time,layer:layer)}
    static func pulse(_ time:Double,layer:Int)->Double{let row=PaperPencilCopy.source["animations"].array[layer],duration=row["duration"].number,delay=row["delay"].number;guard duration>0,time>=delay else{return 0};let p=(time-delay).truncatingRemainder(dividingBy:duration)/duration,t=p<=0.5 ? p*2:2*(1-p);var low=0.0,high=1.0;for _ in 0..<20{let x=(low+high)/2,v=3*(1-x)*(1-x)*x*0.42+3*(1-x)*x*x*0.58+x*x*x;if v<t{low=x}else{high=x}};let x=(low+high)/2;return 3*(1-x)*x*x+x*x*x}
}
private struct PaperPencilActionStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View{configuration.label.font(PiyaliBrand.productFont(16,700)).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:44).background(RoundedRectangle(cornerRadius:8).fill(PiyaliBrand.unitColor(configuration.isPressed ? "38b2ac":"319795")).shadow(color:PiyaliBrand.unitColor("234e52"),radius:0,y:configuration.isPressed ? 0:4)).offset(y:configuration.isPressed ? 3:0)}
}
