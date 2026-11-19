import SwiftUI

enum SessionToolCopy {
    static let labels=(try? ContentLibrary.load(JSONValue.self,name:"session-tools-ui")) ?? .null
    static func header(_ english:String,_ language:String)->String {let values=labels[english];return values[language].string.isEmpty ? values["en"].string : values[language].string}
}
struct SessionIcon:View {
    let name:String
    var size:CGFloat=16
    var body:some View {Image("Session-"+name).renderingMode(.template).resizable().scaledToFit().frame(width:size,height:size).accessibilityHidden(true)}
}
struct ProductTopBar:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @ObservedObject var timer:SessionTimerController
    let onGoal:()->Void
    let onTimer:()->Void
    private var language:String{app.learner.support}
    private var dark:Bool{scheme == .dark}
    var body:some View {
        let percent=max(0,Int((Double(app.learner.dailyXP)/Double(max(1,app.learner.dailyGoal))*100).rounded()))
        let color=PiyaliBrand.unitColor(percent>=100 ? dark ? "2dd4bf":"39bfd1" : percent>50 ? dark ? "b794f4":"6d28d9" : dark ? "b3b3b3":"4b5563")
        HStack(spacing:12){
            HStack(spacing:4){
                control(app.learner.dailyXP>=app.learner.dailyGoal ? "FaCalendarCheck":"FaCalendarAlt",label:"Open daily goal",id:"openDailyGoal",action:onGoal)
                HStack(spacing:2){SessionIcon(name:"MdShowChart");Text(SessionToolCopy.header("Daily XP",language)).font(PiyaliBrand.productFont(12,700)).lineLimit(1).frame(maxWidth:92).fixedSize(horizontal:true,vertical:false).foregroundStyle(percent>=100 && !dark ? PiyaliBrand.unitColor("167f91") : color)
                    FocusWaveBar(percent:Double(percent),height:12,background:.white.opacity(dark ? 0.22:0.58),border:dark ? .white.opacity(0.14):PiyaliBrand.unitColor("5b4b3a").opacity(0.1)).frame(width:72)
                }.foregroundStyle(color).frame(height:34).accessibilityElement(children:.ignore).accessibilityLabel(SessionToolCopy.header("Daily XP",language)).accessibilityValue("\(percent)%").accessibilityIdentifier("dailyXPStatus")
            }
            Spacer(minLength:0)
            ZStack {
                if timer.session.hasTimer {TimelineView(.periodic(from:.now,by:1)){time in TimerProgressBadge(remaining:timer.session.remaining(at:time.date),duration:timer.session.duration,running:timer.session.status == .running,dark:dark)}.allowsHitTesting(false)}
                control("FiClock",label:"Open timer",id:"openSessionTimer",solid:timer.session.status == .running,action:onTimer)
            }.frame(width:32,height:32)
            if timer.session.hasTimer {control(timer.session.status == .paused ? "FiPlay":"FiPause",label:timer.session.status == .paused ? "Resume timer":"Pause timer",id:"toggleSessionTimer",outlined:timer.session.status == .paused,action:timer.toggle).disabled(timer.session.status == .finished)}
        }.padding(.horizontal,8).padding(.vertical,8).background(PiyaliBrand(dark:dark).surface.opacity(0.74)).background(.ultraThinMaterial).overlay(alignment:.bottom){if dark{Color(red:0,green:0,blue:38/255).frame(height:1)}}
    }
    private func control(_ icon:String,label:String,id:String,solid:Bool=false,outlined:Bool=true,action:@escaping()->Void)->some View {
        Button(action:action){SessionIcon(name:icon,size:14).frame(width:32,height:32).foregroundStyle(solid ? .white:PiyaliBrand(dark:dark).text).background(solid ? PiyaliBrand.unitColor(dark ? "319795":"3f9f9b"):outlined ? PiyaliBrand(dark:dark).surface:.clear,in:EntryCornerShape(radius:13)).overlay{if !solid && outlined{EntryCornerShape(radius:13).stroke(icon.hasPrefix("FaCalendar") ? PiyaliBrand.unitColor("2c7a7b"):PiyaliBrand(dark:dark).border).padding(0.5)}}}.buttonStyle(.plain).accessibilityLabel(SessionToolCopy.header(label,language)).accessibilityIdentifier(id)
    }
}
private struct TimerProgressShape:Shape {
    func path(in rect:CGRect)->Path {
        let r:CGFloat=min(18.5,rect.width/2,rect.height/2),w=rect.width,h=rect.height
        var p=Path();p.move(to:CGPoint(x:r,y:0));p.addLine(to:CGPoint(x:w-r,y:0))
        p.addArc(center:CGPoint(x:w-r,y:r),radius:r,startAngle:.degrees(-90),endAngle:.degrees(0),clockwise:false);p.addLine(to:CGPoint(x:w,y:h-r))
        p.addArc(center:CGPoint(x:w-r,y:h-r),radius:r,startAngle:.degrees(0),endAngle:.degrees(90),clockwise:false);p.addLine(to:CGPoint(x:r,y:h))
        p.addArc(center:CGPoint(x:r,y:h-r),radius:r,startAngle:.degrees(90),endAngle:.degrees(180),clockwise:false);p.addLine(to:CGPoint(x:0,y:r))
        p.addArc(center:CGPoint(x:r,y:r),radius:r,startAngle:.degrees(180),endAngle:.degrees(270),clockwise:false);p.closeSubpath();return p
    }
}
private struct TimerProgressBadge:View {
    let remaining:Int,duration:Int
    let running:Bool,dark:Bool
    var body:some View {let shape=TimerProgressShape();let fraction=max(0,min(1,Double(remaining)/Double(max(1,duration))))
        shape.stroke(dark ? .white.opacity(0.08):PiyaliBrand.unitColor("785e3d").opacity(0.18),lineWidth:3.5).overlay{shape.trim(from:0,to:fraction).stroke(LinearGradient(colors:[PiyaliBrand.unitColor("14b8a6"),PiyaliBrand.unitColor("06b6d4")],startPoint:.topLeading,endPoint:.bottomTrailing),style:StrokeStyle(lineWidth:3.5,lineCap:.round)).opacity(running ? 1:0.62)}.frame(width:42.5,height:42.5).frame(width:46,height:46).animation(.linear(duration:0.8),value:remaining).accessibilityHidden(true)
    }
}
struct SessionToolFrame<Content:View,Footer:View>:View {
    let title:String,icon:String
    var coloredHeader=false
    let onClose:()->Void
    @ViewBuilder var content:()->Content
    @ViewBuilder var footer:()->Footer
    @Environment(\.colorScheme) private var scheme
    @State private var contentHeight:CGFloat=500
    @State private var keyboardVisible=false
    private var statusInset:CGFloat{UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.flatMap(\.windows).first{$0.isKeyWindow}?.safeAreaInsets.top ?? 0}
    var body:some View {
        let brand=PiyaliBrand(dark:scheme == .dark)
        GeometryReader{geometry in
            let top=keyboardVisible ? statusInset:0,available=max(200,geometry.size.height-top)
            ZStack{
            (scheme == .dark ? Color(red:2/255,green:6/255,blue:23/255).opacity(0.92):Color(red:28/255,green:20/255,blue:12/255).opacity(0.82)).ignoresSafeArea().onTapGesture(perform:onClose)
            VStack(spacing:0){
                HStack(spacing:coloredHeader ? 12:8){SessionIcon(name:icon,size:coloredHeader ? 22:20);OnboardingText(text:title,size:coloredHeader ? 18:20,weight:coloredHeader ? .bold:.semibold,lineHeight:coloredHeader ? 21.6:30);Spacer(minLength:0)}.padding(.horizontal,32).padding(.top,28).padding(.bottom,coloredHeader ? 28:12).foregroundStyle(coloredHeader ? .white:brand.text).frame(maxWidth:.infinity,alignment:.leading).background{if coloredHeader{if scheme == .dark{PiyaliBrand.unitColor("319795")}else{LinearGradient(colors:[PiyaliBrand.unitColor("43a19d"),PiyaliBrand.unitColor("378b86")],startPoint:.topLeading,endPoint:.bottomTrailing)}}}
                ScrollView{content().padding(.horizontal,28).padding(.vertical,coloredHeader ? 20:8).frame(maxWidth:.infinity,alignment:.leading).onGeometryChange(for:CGFloat.self,of:{$0.size.height}){contentHeight=$0}}.frame(height:min(contentHeight,max(100,min(available*(coloredHeader ? 0.72:0.92),available-170)))).scrollBounceBehavior(.basedOnSize).scrollDismissesKeyboard(.interactively)
                footer().frame(maxWidth:.infinity,alignment:.trailing).padding(.horizontal,28).padding(.top,16).padding(.bottom,28).overlay(alignment:.top){Rectangle().fill(brand.border).frame(height:1)}
            }.background(scheme == .dark ? PiyaliBrand.unitColor("0b1220"):brand.surface,in:EntryCornerShape(radius:48)).clipShape(EntryCornerShape(radius:48)).overlay{EntryCornerShape(radius:48).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).padding(1.5)}.frame(width:min(512,geometry.size.width)).fixedSize(horizontal:false,vertical:true)
        }.frame(maxWidth:.infinity,maxHeight:.infinity).padding(.top,top)}.ignoresSafeArea(.container).foregroundStyle(brand.text).accessibilityElement(children:.contain).onReceive(NotificationCenter.default.publisher(for:UIResponder.keyboardWillShowNotification)){_ in keyboardVisible=true}.onReceive(NotificationCenter.default.publisher(for:UIResponder.keyboardWillHideNotification)){_ in keyboardVisible=false}
    }
}
struct SessionToolButtonStyle:ButtonStyle {
    var primary=false,selected=false,small=false,secondary=false
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration:Configuration)->some View {
        let dark=scheme == .dark,brand=PiyaliBrand(dark:dark),filled=primary || selected
        let fill=filled ? PiyaliBrand.unitColor(dark ? "319795":"3f9f9b"):small ? brand.surface:.clear
        let shadow=primary ? PiyaliBrand.unitColor("008080"):selected && !dark ? PiyaliBrand.unitColor("245b59").opacity(0.18):.clear
        return configuration.label.font(PiyaliBrand.productFont(small ? 14:16,600)).padding(.horizontal,small ? 12:16).frame(height:small ? 32:40).foregroundStyle(filled ? .white:secondary ? PiyaliBrand.unitColor(dark ? "b7c5d8":"5b4b3a"):brand.text)
            .background{EntryCornerShape(radius:small ? 16:20).fill(fill).shadow(color:shadow,radius:0,y:configuration.isPressed ? 0:primary ? 4:6)}
            .overlay{if small{EntryCornerShape(radius:16).stroke(filled ? .clear:dark ? brand.text:brand.border)}}.offset(y:configuration.isPressed && primary ? 4:0).opacity(configuration.isPressed ? 0.75:1)
    }
}
struct SessionToolFlow:Layout {
    var spacing:CGFloat=8
    func sizeThatFits(proposal:ProposedViewSize,subviews:Subviews,cache:inout())->CGSize {let positions=positions(proposal.width ?? 300,subviews);return CGSize(width:proposal.width ?? 300,height:positions.last.map{$0.maxY} ?? 0)}
    func placeSubviews(in bounds:CGRect,proposal:ProposedViewSize,subviews:Subviews,cache:inout()){for (view,rect) in zip(subviews,positions(bounds.width,subviews)){view.place(at:CGPoint(x:bounds.minX+rect.minX,y:bounds.minY+rect.minY),proposal:ProposedViewSize(rect.size))}}
    private func positions(_ width:CGFloat,_ subviews:Subviews)->[CGRect]{var x:CGFloat=0,y:CGFloat=0,row:CGFloat=0;return subviews.map{view in let s=view.sizeThatFits(.unspecified);if x>0 && x+s.width>width{x=0;y+=row+spacing;row=0};let rect=CGRect(origin:CGPoint(x:x,y:y),size:s);x+=s.width+spacing;row=max(row,s.height);return rect}}
}
struct SessionTimerView:View {
    @ObservedObject var timer:SessionTimerController
    let language:String,onClose:()->Void
    @State private var draft="20"
    @Environment(\.colorScheme) private var scheme
    private func text(_ key:String)->String{EntryCopy.ui(language,"timer_modal_"+key)}
    private func close(){timer.saveDraft(draft);onClose()}
    var body:some View {
        SessionToolFrame(title:text("title"),icon:"FiClock",onClose:close){
            VStack(alignment:.leading,spacing:16){
                OnboardingText(text:text("description"),size:16,lineHeight:24).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "a3b4c9":"5b4b3a"))
                VStack(spacing:8){SessionClock(minutes:$draft,language:language).frame(maxWidth:.infinity);OnboardingText(text:text("drag_hint"),size:12,lineHeight:18).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "879bb4":"8d7a67")).frame(maxWidth:.infinity).multilineTextAlignment(.center)}.padding(.vertical,16)
                VStack(alignment:.leading,spacing:8){OnboardingText(text:text("minutes_label"),size:16,weight:.medium,lineHeight:24);TextField(text("minutes_label"),text:$draft).multilineTextAlignment(language == "ar" ? .trailing:.leading).environment(\.layoutDirection,.leftToRight).keyboardType(.decimalPad).font(PiyaliBrand.productFont(16)).padding(.horizontal,16).frame(height:40).background(PiyaliBrand.unitColor(scheme == .dark ? "111827":"fdf9f2"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(scheme == .dark ? PiyaliBrand.unitColor("334155"):PiyaliBrand.unitColor("604d38").opacity(0.24))}.accessibilityIdentifier("timerMinutesDraft");OnboardingText(text:text("max_hint"),size:12,lineHeight:18).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "879bb4":"8d7a67"))}
                VStack(alignment:.leading,spacing:8){OnboardingText(text:text("quick_picks"),size:14,lineHeight:21).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "a3b4c9":"5b4b3a"));SessionToolFlow{ForEach(SessionToolPolicy.timerPresets,id:\.self){value in Button("\(value)m"){draft=String(value)}.buttonStyle(SessionToolButtonStyle(selected:Double(draft)==Double(value),small:true)).accessibilityIdentifier("timerPreset-\(value)")}}}
            }
        }footer:{HStack(spacing:12){Button(text("close"),action:close).buttonStyle(SessionToolButtonStyle()).accessibilityIdentifier("timerClose");Button(text(timer.session.status == .running ? "restart":"start")){timer.start(draft);onClose()}.buttonStyle(SessionToolButtonStyle(primary:true)).accessibilityIdentifier("timerStart")}}
        .onAppear{draft=timer.session.draft}.onChange(of:draft){_,value in if let n=Double(value),n>240{draft="240"}}
    }
}
struct SessionClock:View {
    @Binding var minutes:String
    var language="en"
    @Environment(\.colorScheme) private var scheme
    @State private var previousAngle:Double?
    @State private var accumulated:Double=0
    private var amount:Double {max(0,min(240,Double(minutes) ?? 0))}
    private var valueLabel:String {amount.rounded()==amount ? String(Int(amount)):String(amount)}
    var body:some View {
        let dark=scheme == .dark,accent=PiyaliBrand.unitColor(dark ? "38b2ac":"43a19d")
        ZStack(alignment:.bottom){
            Canvas{context,size in
                context.scaleBy(x:size.width/100,y:size.height/100)
                func wedge(_ count:Double,_ first:Color,_ second:Color,_ opacity:Double){guard count>0 else{return};var p=Path();p.move(to:CGPoint(x:50,y:50));p.addArc(center:CGPoint(x:50,y:50),radius:35,startAngle:.degrees(-90),endAngle:.degrees(-90+min(120,count)*3),clockwise:false);p.closeSubpath();context.opacity=opacity;context.fill(p,with:.linearGradient(Gradient(colors:[first,second]),startPoint:.zero,endPoint:CGPoint(x:100,y:100)));context.opacity=1}
                wedge(min(120,amount),(dark ? accent:PiyaliBrand.unitColor("5dc4b4")).opacity(dark ? 0.4:0.32),accent.opacity(dark ? 0.6:0.52),0.8);wedge(max(0,amount-120),PiyaliBrand.unitColor(dark ? "1535ff":"8992e4").opacity(dark ? 0.5:0.34),PiyaliBrand.unitColor(dark ? "0700c6":"6d74cb").opacity(dark ? 0.7:0.5),0.85)
                for i in 0..<12{let angle=Double(i)*Double.pi/6-Double.pi/2,r:Double=i%3==0 ? 38:41;var p=Path();p.move(to:CGPoint(x:50+r*cos(angle),y:50+r*sin(angle)));p.addLine(to:CGPoint(x:50+45*cos(angle),y:50+45*sin(angle)));context.stroke(p,with:.color(i%3==0 ? accent:PiyaliBrand.unitColor(dark ? "4a5568":"6d6457")),style:StrokeStyle(lineWidth:i%3==0 ? 2:1.25,lineCap:.round))}
                let angle=(amount.truncatingRemainder(dividingBy:120))*Double.pi/60-Double.pi/2,tip=CGPoint(x:50+32*cos(angle),y:50+32*sin(angle));var hand=Path();hand.move(to:CGPoint(x:50,y:50));hand.addLine(to:tip);context.stroke(hand,with:.color(accent),style:StrokeStyle(lineWidth:3,lineCap:.round));context.fill(Path(ellipseIn:CGRect(x:46,y:46,width:8,height:8)),with:.color(accent));context.fill(Path(ellipseIn:CGRect(x:tip.x-3,y:tip.y-3,width:6,height:6)),with:.color(PiyaliBrand.unitColor(dark ? "81e6d9":"6bd3cb")))
            }.padding(3)
            Text(valueLabel+"m").font(PiyaliBrand.productFont(18,700)).foregroundStyle(accent).padding(.bottom,25)
        }.frame(width:160,height:160).background(RadialGradient(colors:dark ? [PiyaliBrand.unitColor("111827")]:[PiyaliBrand.unitColor("fffcf7"),PiyaliBrand.unitColor("f4ece1"),PiyaliBrand.unitColor("e8dbcb")],center:UnitPoint(x:0.5,y:0.38),startRadius:0,endRadius:100),in:Circle()).overlay{Circle().stroke(dark ? PiyaliBrand.unitColor("1f2937"):PiyaliBrand(dark:dark).border,lineWidth:3)}.shadow(color:dark ? accent.opacity(0.3):.black.opacity(0.08),radius:dark ? 15:12,y:dark ? 0:10).gesture(DragGesture(minimumDistance:0).onChanged{value in let angle=SessionToolPolicy.angle(x:value.location.x-80,y:value.location.y-80);if let previousAngle{accumulated=SessionToolPolicy.drag(minutes:accumulated,from:previousAngle,to:angle);minutes=String(SessionToolPolicy.snapped(accumulated))}else{accumulated=amount};previousAngle=angle}.onEnded{_ in previousAngle=nil})
            .accessibilityElement(children:.ignore).accessibilityLabel(EntryCopy.ui(language,"timer_modal_minutes_label")).accessibilityValue(valueLabel+"m").accessibilityAdjustableAction{direction in minutes=String(Int(max(0,min(240,amount+(direction == .increment ? 5:-5)))))}.accessibilityIdentifier("sessionClock").environment(\.layoutDirection,.leftToRight)
    }
}
