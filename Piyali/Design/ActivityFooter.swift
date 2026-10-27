import SwiftUI

/// One native host mirrors the web action portal: feedback above a menu slot,
/// secondary actions and one primary action. A scoped owner fences late teardown.
struct ActivityFooterPresentation {
    let owner:UUID
    let content:AnyView
    var correct:Bool?=nil
    var tone:String?=nil
}
private struct ActivityFooterPublisher:ViewModifier {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var access:SubscriptionService
    let fixtureAllowed:Bool
    let correct:Bool?
    let tone:String?
    let owner:UUID
    let revision:String
    let footer:AnyView
    private var scope:String { app.identity.npub+":"+app.learner.target+":"+app.learner.support }
    func body(content:Content)->some View {
        content.task(id:scope+":"+revision+":"+(colorScheme == .dark ? "dark":"light")+":"+String(access.hasAccess || fixtureAllowed)) {
            guard !Task.isCancelled else { return }
            guard app.signedIn,access.hasAccess || fixtureAllowed else {
                if app.activityFooter?.owner == owner { app.activityFooter=nil };return
            }
            app.activityFooter = .init(owner:owner,content:footer,correct:correct,tone:tone)
        }.onDisappear { if app.activityFooter?.owner == owner { app.activityFooter=nil } }
    }
}
extension View {
    func activityFooter<Footer:View>(owner:UUID,revision:String,access:SubscriptionService,fixtureAllowed:Bool=false,correct:Bool?=nil,tone:String?=nil,@ViewBuilder footer:()->Footer)->some View {
        modifier(ActivityFooterPublisher(access:access,fixtureAllowed:fixtureAllowed,correct:correct,tone:tone,owner:owner,revision:revision,footer:AnyView(footer())))
    }
}
private struct FeedbackHeight:PreferenceKey {
    static var defaultValue:CGFloat=0
    static func reduce(value:inout CGFloat,nextValue:()->CGFloat) { value=max(value,nextValue()) }
}
struct ActivityFooterSurface<Feedback:View,Actions:View>:View {
    var feedbackLimit:CGFloat?=nil
    let hasFeedback:Bool
    @ViewBuilder let feedback:()->Feedback
    @ViewBuilder let actions:()->Actions
    @State private var feedbackHeight:CGFloat=0
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            if hasFeedback {
                ScrollView { feedback().frame(maxWidth:.infinity,alignment:.leading).background { GeometryReader { geometry in Color.clear.preference(key:FeedbackHeight.self,value:geometry.size.height) } } }
                    .frame(height:min(feedbackHeight,feedbackLimit ?? min(240,UIScreen.main.bounds.height*0.28)))
                    .onPreferenceChange(FeedbackHeight.self) { feedbackHeight=$0 }
                    .accessibilityIdentifier("activityFeedbackScroll")
            }
            HStack(spacing:8) { actions() }.padding(.leading,52).frame(minHeight:40)
        }
    }
}
struct ActivityPrimaryButtonStyle:ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    var tone="primary"
    private var colors:[Color] {
        switch tone {
        case "assistant":return [PiyaliBrand.unitColor("3182ce"),PiyaliBrand.unitColor("2b6cb0")]
        case "achievement":return [PiyaliBrand.unitColor("a97916"),PiyaliBrand.unitColor("785411")]
        case "success":return [.init(red:49/255,green:151/255,blue:149/255),.init(red:35/255,green:78/255,blue:82/255)]
        case "speak":return [.init(red:0,green:181/255,blue:216/255),.init(red:8/255,green:111/255,blue:131/255)]
        case "stop":return [.init(red:176/255,green:0,blue:91/255),.init(red:114/255,green:0,blue:59/255)]
        default:return [.init(red:128/255,green:90/255,blue:213/255),.init(red:68/255,green:51/255,blue:122/255)]
        }
    }
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(PiyaliBrand.productFont(14,700)).multilineTextAlignment(.center).foregroundStyle(.white).padding(.horizontal,12).frame(maxWidth:.infinity,minHeight:40,maxHeight:40).background { RoundedRectangle(cornerRadius:18).fill(tone == "achievement" && configuration.isPressed ? PiyaliBrand.unitColor("805810"):colors[0]).shadow(color:enabled ? colors[1] : .clear,radius:0,y:configuration.isPressed ? 0 : 4) }.offset(y:configuration.isPressed ? 4 : 0).opacity(enabled ? 1 : 0.55)
    }
}

/// Original WaveBar colors, proportions and fill timing, rendered natively.
struct ActivityProgressBar:View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value:Int
    let label:String
    @State private var displayed:CGFloat=0
    var body:some View {
        GeometryReader { geometry in
            ZStack(alignment:.leading) {
                Capsule().fill(Color(red:125/255,green:211/255,blue:252/255).opacity(0.12))
                Capsule().fill(LinearGradient(colors:[Color(red:74/255,green:168/255,blue:1),Color(red:117/255,green:248/255,blue:1)],startPoint:.leading,endPoint:.trailing)).opacity(0.9).frame(width:geometry.size.width*displayed)
            }.overlay { Capsule().stroke(Color(red:125/255,green:211/255,blue:252/255).opacity(0.24)) }
        }.frame(height:14).task(id:value) { withAnimation(reduceMotion ? nil : .timingCurve(0.22,1,0.36,1,duration:0.8)) { displayed=CGFloat(max(0,min(100,value)))/100 } }
            .accessibilityElement(children:.ignore).accessibilityLabel(label).accessibilityValue("\(value)%")
    }
}

/// QuestionActionArea's iPhone glass fallback, feedback colors and 40-point radius.
struct SourceActivityDockBackground:View {
    let correct:Bool?
    var achievement=false
    var tone:String?=nil
    @Environment(\.colorScheme) private var scheme
    private var dark:Bool {scheme == .dark}
    private var brand:PiyaliBrand {.init(dark:dark)}
    var body:some View {
        let accent=tone == "assistant" ? PiyaliBrand.unitColor(dark ? "7dd3fc":"2563eb"):achievement ? PiyaliBrand.unitColor(dark ? "fbbf24":"b7791f"):correct.map{$0 ? brand.questionSuccess:brand.questionError},base=correct == nil && !achievement && tone != "assistant" ? PiyaliBrand.unitColor(dark ? "0b1220":"fffcf7").opacity(dark ? 0.12:0.58):PiyaliBrand.unitColor(dark ? "0b1220":"fffcf7").opacity(dark ? 0.66:0.94)
        RoundedRectangle(cornerRadius:40).fill(base).overlay{if let accent{RoundedRectangle(cornerRadius:40).fill((achievement && !dark ? PiyaliBrand.unitColor("d99e23"):accent).opacity(dark ? 0.14:0.10))}}.overlay{RoundedRectangle(cornerRadius:40).stroke(accent ?? brand.border)}
            .shadow(color:correct == nil && !achievement && tone != "assistant" ? .clear:.black.opacity(0.16),radius:21,y:18)
            .shadow(color:accent?.opacity(dark ? 0.14:0.10) ?? .clear,radius:12)
    }
}

/// PiDotsNineBold's original 256-unit circle geometry, used by ActivityMenu.
struct SourceActivityMenuGlyph:Shape {
 func path(in rect:CGRect)->Path{var path=Path();for y in [60.0,128.0,196.0]{for x in [60.0,128.0,196.0]{path.addEllipse(in:CGRect(x:rect.minX+(x-16)/256*rect.width,y:rect.minY+(y-16)/256*rect.height,width:32/256*rect.width,height:32/256*rect.height))}};return path}
}
