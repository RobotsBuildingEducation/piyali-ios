import SwiftUI
import UIKit

private struct EntryHeaderBounds:EnvironmentKey {static let defaultValue:CGRect = .zero}
extension EnvironmentValues {var entryHeaderBounds:CGRect {get{self[EntryHeaderBounds.self]}set{self[EntryHeaderBounds.self]=newValue}}}

/// CSS border-radius with corner-shape:superellipse(2), used by the source
/// entry controls. The exponent is four; long controls retain straight edges.
struct EntryCornerShape:Shape {
    var radius:CGFloat=100
    func path(in rect:CGRect)->Path {
        let r=min(radius,min(rect.width,rect.height)/2);var path=Path()
        let corners=[(rect.maxX-r,rect.minY+r,-Double.pi/2),(rect.maxX-r,rect.maxY-r,0),(rect.minX+r,rect.maxY-r,Double.pi/2),(rect.minX+r,rect.minY+r,Double.pi)]
        for (index,corner) in corners.enumerated() {for step in 0...24 {let angle=corner.2+Double(step)/24*Double.pi/2,c=cos(angle),s=sin(angle),p=CGPoint(x:corner.0+r*CGFloat(c.sign == .minus ? -sqrt(abs(c)) : sqrt(abs(c))),y:corner.1+r*CGFloat(s.sign == .minus ? -sqrt(abs(s)) : sqrt(abs(s))));if index == 0,step == 0 {path.move(to:p)} else {path.addLine(to:p)}}};path.closeSubpath();return path
    }
}
struct EntryButtonStyle:ButtonStyle {
    enum Variant {case primary,secondary,ghost}
    var variant:Variant = .primary
    var large=false,compact=false,fullWidth=true
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration:Configuration)->some View {
        let brand=PiyaliBrand(dark:scheme == .dark),size:CGFloat=compact ? 12.48 : large ? 18 : 16,v:CGFloat=compact ? 8 : large ? 18 : 14,h:CGFloat=compact ? 10 : large ? 40 : 32
        let font=UIFont(name:"DMSans-SemiBold",size:size) ?? UIFont.systemFont(ofSize:size),leading=max(0,size*1.6-font.lineHeight)
        configuration.label.font(PiyaliBrand.font(size,600)).lineSpacing(leading).lineLimit(compact ? 1 : nil).minimumScaleFactor(compact ? 0.75 : 1).padding(.horizontal,h).padding(.vertical,v+leading/2).frame(maxWidth:fullWidth ? .infinity : nil,minHeight:size*1.6+v*2+(variant == .secondary ? 2 : 0))
            .foregroundStyle(variant == .primary ? Color.white : variant == .ghost ? brand.secondary : brand.text)
            .background {if variant == .primary {EntryCornerShape().fill(LinearGradient(colors:[PiyaliBrand.teal,PiyaliBrand.unitColor("0d9488")],startPoint:UnitPoint(x:0,y:0),endPoint:UnitPoint(x:1,y:1)))}}
            .overlay {if variant == .secondary {EntryCornerShape().stroke(PiyaliBrand.teal.opacity(0.3),lineWidth:1)}}
            .contentShape(EntryCornerShape()).shadow(color:variant == .primary && !compact ? PiyaliBrand.teal.opacity(0.4) : .clear,radius:12,y:4).opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.5)
    }
}
struct EntryLineText:View {
    let text:String
    var size:CGFloat=16,weight=400
    var lineHeight:CGFloat?=nil
    @ScaledMetric(relativeTo:.body) private var typeScale:CGFloat=1000
    var body:some View {
        // Scale a unit first to retain fractional source sizes. Letting SwiftUI
        // round 11.2 points to 11 changes this subtitle from three lines to two.
        let actual=size*typeScale/1000,name=weight == 600 ? "DMSans-SemiBold" : "DMSans-Regular",font=UIFont(name:name,size:actual) ?? UIFont.systemFont(ofSize:actual),leading=max(0,(lineHeight ?? size*1.6)*typeScale/1000-font.lineHeight)
        Text(text).font(.custom(name,fixedSize:actual)).lineSpacing(leading).padding(.vertical,leading/2).fixedSize(horizontal:false,vertical:true)
    }
}
struct EntryHeroTitle:UIViewRepresentable {
    let title:String,accent:String,language:String
    let color:Color
    func makeUIView(context:Context)->UILabel {let label=UILabel();label.numberOfLines=0;label.setContentCompressionResistancePriority(.defaultLow,for:.horizontal);label.accessibilityTraits.insert(.header);label.accessibilityIdentifier="entryHeroTitle";return label}
    func updateUIView(_ label:UILabel,context:Context) {
        let text=title+"\n"+accent,p=NSMutableParagraphStyle();p.alignment = .center;p.minimumLineHeight=35.2;p.maximumLineHeight=35.2;p.baseWritingDirection=language == "ar" ? .rightToLeft : .leftToRight
        let result=NSMutableAttributedString(string:text,attributes:[.font:UIFont(name:"DMSans-SemiBold",size:32) ?? UIFont.systemFont(ofSize:32,weight:.semibold),.foregroundColor:UIColor(color),.paragraphStyle:p]);result.addAttribute(.foregroundColor,value:UIColor(PiyaliBrand.teal),range:NSRange(location:(title as NSString).length+1,length:(accent as NSString).length));label.attributedText=result;label.accessibilityLabel=title+" "+accent;label.accessibilityLanguage=language
    }
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UILabel,context:Context)->CGSize? {let width=proposal.width ?? 354,size=uiView.attributedText?.boundingRect(with:CGSize(width:width,height:.greatestFiniteMagnitude),options:[.usesLineFragmentOrigin,.usesFontLeading],context:nil).size ?? .zero;return CGSize(width:width,height:ceil(size.height))}
}
struct EntryThemeButton:View {
    @Binding var mode:String
    var compact=false
    var body:some View {
        let dark=mode == "dark",colors=dark ? [PiyaliBrand.unitColor("0f172a").opacity(0.96),PiyaliBrand.unitColor("1e293b").opacity(0.92)] : [PiyaliBrand.unitColor("fff9ed"),PiyaliBrand.unitColor("ffe8cf")]
        Button {mode=dark ? "light" : "dark"} label:{Image(systemName:dark ? "sun.max" : "moon.stars.fill").font(.system(size:compact ? 15 : 18,weight:.semibold)).foregroundStyle(PiyaliBrand.unitColor(dark ? "fffaf0" : "b45309")).frame(width:compact ? 34 : 40,height:compact ? 34 : 40).background(LinearGradient(colors:colors,startPoint:UnitPoint(x:0,y:0),endPoint:UnitPoint(x:1,y:1)),in:EntryCornerShape()).overlay {EntryCornerShape().stroke(PiyaliBrand.unitColor(dark ? "93c5fd" : "f59e0b").opacity(dark ? 0.32 : 0.36))}.shadow(color:dark ? PiyaliBrand.unitColor("0f172a").opacity(0.32) : PiyaliBrand.unitColor("f59e0b").opacity(0.18),radius:11,y:10)}.buttonStyle(.plain).accessibilityLabel(dark ? "Switch to light mode" : "Switch to dark mode").accessibilityIdentifier("entryTheme")
    }
}
struct EntryFloatingGreetings:View {
    static let words=(try? ContentLibrary.load(JSONValue.self,name:"entry-visuals"))?["greetings"].array ?? []
    var active=true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var origin=Date()
    var body:some View {
        TimelineView(.animation(minimumInterval:1/30,paused:!active || reduceMotion)) {time in
            Canvas {context,size in
                for (i,word) in Self.words.enumerated() {
                    let age=max(0,time.date.timeIntervalSince(origin)-word["delay"].number),phase=reduceMotion ? 0 : age.truncatingRemainder(dividingBy:Double(6+i))/Double(6+i),wave=pow(sin(phase*Double.pi),2),featured=word["featured"].boolean
                    func fraction(_ key:String)->Double {(Double(word[key].string.replacingOccurrences(of:"%",with:"")) ?? 0)/100}
                    var c=context;c.opacity=(featured ? 0.16 : 0.1)+wave*(featured ? 0.20 : 0.15);c.addFilter(.shadow(color:PiyaliBrand.teal.opacity(featured ? 0.5 : 1),radius:featured ? 18 : 40));if featured {c.addFilter(.shadow(color:PiyaliBrand.unitColor("0ea5e9").opacity(0.32),radius:42))}
                    c.draw(Text(word["text"].string).font(PiyaliBrand.font(min(40,max(24,size.width*0.03)),500)).foregroundColor(PiyaliBrand.teal),at:CGPoint(x:size.width*fraction("x"),y:size.height*fraction("y")-(reduceMotion ? 0 : wave*30)),anchor:.topLeading)
                }
            }
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}
struct EntryBackground:View {
    @Environment(\.colorScheme) private var scheme
    private func radial(_ context:GraphicsContext,center:CGPoint,radii:CGSize,color:Color,stop:Double=1,blur:Double=0) {
        var c=context;if blur>0 {c.addFilter(.blur(radius:blur))};c.translateBy(x:center.x,y:center.y);c.scaleBy(x:radii.width,y:radii.height)
        c.fill(Path(ellipseIn:CGRect(x:-1,y:-1,width:2,height:2)),with:.radialGradient(Gradient(stops:[.init(color:color,location:0),.init(color:.clear,location:stop),.init(color:.clear,location:1)]),center:.zero,startRadius:0,endRadius:1))
    }
    var body:some View {
        let light=scheme != .dark
        ZStack {
            Canvas {c,s in
                let colors=(light ? ["fffdf9","f8f2e8","f3ebdf"] : ["030712","0f172a","030712"]).map(PiyaliBrand.unitColor)
                c.fill(Path(CGRect(origin:.zero,size:s)),with:.linearGradient(Gradient(colors:colors),startPoint:.zero,endPoint:CGPoint(x:0,y:s.height)))
                if light {
                    radial(c,center:CGPoint(x:s.width*0.18,y:s.height*0.82),radii:CGSize(width:s.width*0.65,height:s.height*0.48),color:PiyaliBrand.unitColor("60a5fa").opacity(0.1),stop:0.44)
                    radial(c,center:CGPoint(x:s.width*0.85,y:s.height*0.12),radii:CGSize(width:s.width*0.62,height:s.height*0.46),color:PiyaliBrand.unitColor("f97316").opacity(0.1),stop:0.52)
                    radial(c,center:CGPoint(x:s.width*0.5,y:s.height * -0.1),radii:CGSize(width:s.width*0.85,height:s.height*0.58),color:PiyaliBrand.unitColor("fbbf24").opacity(0.18),stop:0.54)
                } else {
                    radial(c,center:CGPoint(x:s.width*0.1,y:s.height*0.8),radii:CGSize(width:s.width*0.5,height:s.height*0.3),color:PiyaliBrand.unitColor("a78bfa").opacity(0.08),stop:0.4)
                    radial(c,center:CGPoint(x:s.width*0.8,y:s.height),radii:CGSize(width:s.width*0.6,height:s.height*0.4),color:PiyaliBrand.unitColor("0ea5e9").opacity(0.1),stop:0.4)
                    radial(c,center:CGPoint(x:s.width*0.5,y:s.height * -0.2),radii:CGSize(width:s.width*0.8,height:s.height*0.5),color:PiyaliBrand.teal.opacity(0.15),stop:0.5)
                }
                radial(c,center:CGPoint(x:s.width*0.05+250,y:s.height*0.1+250),radii:CGSize(width:270,height:270),color:(light ? PiyaliBrand.unitColor("fb923c").opacity(0.18*0.28) : PiyaliBrand.teal.opacity(0.2*0.38)),stop:0.7,blur:30)
                radial(c,center:CGPoint(x:s.width*0.9-200,y:s.height*0.8-200),radii:CGSize(width:212,height:212),color:PiyaliBrand.unitColor(light ? "3b82f6" : "0ea5e9").opacity(light ? 0.14*0.22 : 0.15*0.3),stop:0.7,blur:24)
            }
            Canvas {c,s in var p=Path();for x in stride(from:CGFloat(0),through:s.width,by:60){p.move(to:CGPoint(x:x,y:0));p.addLine(to:CGPoint(x:x,y:s.height))};for y in stride(from:CGFloat(0),through:s.height,by:60){p.move(to:CGPoint(x:0,y:y));p.addLine(to:CGPoint(x:s.width,y:y))};c.stroke(p,with:.color(PiyaliBrand.unitColor(light ? "786043" : "14b8a6").opacity(light ? 0.045 : 0.03)),lineWidth:1)}
                .mask {Canvas {c,s in radial(c,center:CGPoint(x:s.width/2,y:s.height/2),radii:CGSize(width:s.width*0.8,height:s.height*0.5),color:.white)}}
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}
