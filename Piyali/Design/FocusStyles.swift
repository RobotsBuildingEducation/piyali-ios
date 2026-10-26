import SwiftUI

struct FocusHeadlineDots:View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body:some View {
        TimelineView(.animation(minimumInterval:1/20,paused:reduceMotion)) {clock in
            Canvas {context,size in
                for index in 0..<3 {
                    let phase=reduceMotion ? 0.4 : (clock.date.timeIntervalSinceReferenceDate-Double(index)*0.2).truncatingRemainder(dividingBy:1.4)/1.4
                    let strength=max(0,min(1,phase < 0.4 ? phase/0.4 : phase < 0.8 ? (0.8-phase)/0.4 : 0)),diameter=5*(0.6+strength*0.6)
                    context.opacity=0.7*(0.25+strength*0.75)
                    context.fill(Path(ellipseIn:CGRect(x:CGFloat(index)*9+2.5-diameter/2,y:(size.height-diameter)/2,width:diameter,height:diameter)),with:.foreground)
                }
            }.frame(width:23,height:21)
        }.frame(maxWidth:.infinity,minHeight:21)
    }
}

enum FocusCopy {
    static let source=(try? ContentLibrary.load(JSONValue.self,name:"focus-ui")) ?? .null
    static func data(_ language:String)->JSONValue { let value=source["copy"][language];return value == .null ? source["copy"]["en"] : value }
    static func stage(_ health:Int)->String { switch health {case ...0:return "dead";case ...24:return "unhealthy";case ...49:return "stressed";case ...74:return "unhappy";case ...99:return "healthy";default:return "happy"} }
    static func appearance(_ health:Int,dark:Bool)->JSONValue {source["stages"][stage(health)][dark ? "dark" : "light"]}
    static func color(_ css:String)->Color {
        if css.hasPrefix("#") {return PiyaliBrand.unitColor(String(css.dropFirst()))}
        let parts=css.replacingOccurrences(of:"rgba(",with:"").replacingOccurrences(of:"rgb(",with:"").replacingOccurrences(of:")",with:"").split(separator:",").compactMap{Double($0.trimmingCharacters(in:.whitespaces))}
        guard parts.count >= 3 else{return .clear}
        return Color(red:parts[0]/255,green:parts[1]/255,blue:parts[2]/255,opacity:parts.count > 3 ? parts[3] : 1)
    }
    static func background(_ css:String)->LinearGradient {
        let expression=try? NSRegularExpression(pattern:"rgba?\\([^)]*\\)|#[a-fA-F0-9]{6}"),range=NSRange(css.startIndex...,in:css)
        let colors=(expression?.matches(in:css,range:range) ?? []).compactMap {Range($0.range,in:css).map{color(String(css[$0]))}}
        return LinearGradient(colors:colors.isEmpty ? [.clear] : colors,startPoint:.top,endPoint:.bottom)
    }
}

/// The source's clipped gradient and slow white wave. Its fill is physically
/// left anchored in both document directions, and only its width is capped.
struct FocusWaveBar:View {
    var percent:Double
    var height:CGFloat=14
    var start="43e97b",end="38f9d7"
    var background:Color = .white.opacity(0.05)
    var border:Color = .white.opacity(0.1)
    var gradientOpacity=0.9,waveOpacity=0.18
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body:some View {
        GeometryReader {geometry in
            let width=geometry.size.width*max(0,min(100,percent))/100
            ZStack(alignment:.leading) {
                background
                TimelineView(.animation(minimumInterval:1/15,paused:reduceMotion || width == 0)) {time in
                    ZStack {
                        LinearGradient(colors:[PiyaliBrand.unitColor(start),PiyaliBrand.unitColor(end)],startPoint:.leading,endPoint:.trailing).opacity(gradientOpacity)
                        Canvas {context,size in
                            let phase=reduceMotion ? 0 : (1-cos(time.date.timeIntervalSinceReferenceDate*Double.pi/5))*5
                            context.scaleBy(x:size.width/120,y:size.height/30);context.translateBy(x:-phase,y:0)
                            var p=Path();p.move(to:CGPoint(x:0,y:18))
                            p.addCurve(to:CGPoint(x:30,y:18),control1:CGPoint(x:10,y:14),control2:CGPoint(x:20,y:22))
                            p.addCurve(to:CGPoint(x:60,y:18),control1:CGPoint(x:40,y:14),control2:CGPoint(x:50,y:14))
                            p.addCurve(to:CGPoint(x:90,y:18),control1:CGPoint(x:70,y:22),control2:CGPoint(x:80,y:22))
                            p.addCurve(to:CGPoint(x:120,y:18),control1:CGPoint(x:100,y:14),control2:CGPoint(x:110,y:14))
                            p.addLine(to:CGPoint(x:120,y:30));p.addLine(to:CGPoint(x:0,y:30));p.closeSubpath();context.fill(p,with:.color(.white.opacity(waveOpacity)))
                        }
                    }.frame(width:width)
                }
            }.clipShape(Capsule()).overlay{Capsule().strokeBorder(border,lineWidth:1)}
        }.frame(height:height).environment(\.layoutDirection,.leftToRight).accessibilityHidden(true)
    }
}

/// Port of CompanionQuestBubble's seeded, single-outline manga balloon.
struct FocusBalloon:Shape {
    let text:String
    func path(in rect:CGRect)->Path {
        var hash:Int32=0;for unit in text.utf16 {hash=hash &* 31 &+ Int32(unit)}
        var seed=Int64(hash).magnitude % 2147483647;if seed == 0 {seed=1}
        func j(_ amount:CGFloat)->CGFloat {seed=(seed*48271)%2147483647;return (CGFloat(seed)/2147483647*2-1)*amount}
        let w=rect.width,h=rect.height,r=max(18,min(h/2,w/2,64)),tl=r+j(4),tr=r+j(4),br=r+j(4),bl=r+j(4)
        func bow(_ length:CGFloat)->CGFloat {max(2,min(7,length*0.04))+j(1.2)}
        let top=bow(w),right=bow(h),left=bow(h),bottom=bow(w)*0.5,baseR=min(max(w-r-4,r+22),r+30),baseL=baseR-12,tipX=baseL-8+j(1.2),tipY=h+16+j(1.2)
        var p=Path();p.move(to:CGPoint(x:tl,y:0))
        p.addQuadCurve(to:CGPoint(x:w-tr,y:0),control:CGPoint(x:w/2+j(4),y:-top));p.addQuadCurve(to:CGPoint(x:w,y:tr),control:CGPoint(x:w,y:0))
        p.addQuadCurve(to:CGPoint(x:w,y:h-br),control:CGPoint(x:w+right,y:h/2+j(4)));p.addQuadCurve(to:CGPoint(x:w-br,y:h),control:CGPoint(x:w,y:h))
        p.addQuadCurve(to:CGPoint(x:baseR,y:h),control:CGPoint(x:(w-br+baseR)/2,y:h+bottom));p.addQuadCurve(to:CGPoint(x:tipX,y:tipY),control:CGPoint(x:baseR-4+j(1.5),y:h+8))
        p.addQuadCurve(to:CGPoint(x:baseL,y:h),control:CGPoint(x:tipX+9+j(1.5),y:h+5.12));p.addLine(to:CGPoint(x:bl,y:h))
        p.addQuadCurve(to:CGPoint(x:0,y:h-bl),control:CGPoint(x:0,y:h));p.addQuadCurve(to:CGPoint(x:0,y:tl),control:CGPoint(x:-left,y:h/2+j(4)))
        p.addQuadCurve(to:CGPoint(x:tl,y:0),control:CGPoint(x:0,y:0));p.closeSubpath();return p
    }
}

struct FocusQuestBubble:View {
    let text:String
    var introductory:Bool
    var tailOnRight=false
    let onContinue:()->Void
    @Environment(\.colorScheme) private var scheme
    var body:some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        VStack(spacing:12) {
            Text(text).font(PiyaliBrand.font(introductory ? 14 : 12,700)).lineSpacing(2).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            // The source balloon deliberately uses literal English Continue.
            Button("Continue",action:onContinue).font(PiyaliBrand.font(14,700)).frame(maxWidth:.infinity,minHeight:32).overlay{Capsule().stroke(brand.text,lineWidth:2)}.buttonStyle(.plain).accessibilityIdentifier("companionContinue")
        }.padding(.horizontal,24).padding(.vertical,16).frame(width:220).background{FocusBalloon(text:text).fill(brand.surface).scaleEffect(x:tailOnRight ? -1 : 1,y:1)}.overlay{FocusBalloon(text:text).stroke(brand.text,style:StrokeStyle(lineWidth:2.8,lineCap:.round,lineJoin:.round)).scaleEffect(x:tailOnRight ? -1 : 1,y:1)}.foregroundStyle(brand.text)
            .environment(\.layoutDirection,.leftToRight)
    }
}

struct FocusPrimaryButtonStyle:ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(PiyaliBrand.productFont(18,600)).frame(maxWidth:.infinity,minHeight:48).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("1a202c") : .white).background(PiyaliBrand.unitColor(scheme == .dark ? "81e6d9" : "319795"),in:EntryCornerShape()).shadow(color:PiyaliBrand.unitColor("214f54"),radius:0,y:enabled && !configuration.isPressed ? 4 : 0).offset(y:enabled && configuration.isPressed ? 4 : 0).opacity(enabled ? configuration.isPressed ? 0.8 : 1 : 0.6)
    }
}
