import SwiftUI

@MainActor enum SubscriptionCopy {
 static let data=(try? ContentLibrary.load(JSONValue.self,name:"subscription-copy")) ?? .null
 static let policy=try? SubscriptionSourcePolicy(bundle:.main)
 static func text(_ group:String,_ lang:String,_ key:String)->String{let value=data[group][lang][key].string;return value.isEmpty ? data[group]["en"][key].string:value}
 static func run(_ operation:String,_ input:JSONValue)->JSONValue{(try? policy?.run(operation,input)) ?? .null}
}
struct SubscriptionActionStyle:ButtonStyle {
 @Environment(\.colorScheme) private var scheme
 @Environment(\.isEnabled) private var enabled
 var color="b794f4",shadow="6b46c1",height:CGFloat=61,outline=false
 func makeBody(configuration:Configuration)->some View{configuration.label.font(PiyaliBrand.productFont(16,600)).frame(maxWidth:.infinity,minHeight:height).padding(.horizontal,16).foregroundStyle(outline ? Color.primary:Color.white).background(Capsule().fill(outline ? PiyaliBrand.unitColor(scheme == .dark ? "111827":"fffdf9"):PiyaliBrand.unitColor(color))).overlay{if outline{Capsule().stroke(.primary.opacity(0.2))}}.background{if !outline && enabled{Capsule().fill(PiyaliBrand.unitColor(shadow)).offset(y:configuration.isPressed ? 0:4)}}.offset(y:configuration.isPressed ? 2:0).compositingGroup().opacity(enabled ? 1:0.6)}
}
struct SubscriptionGatePanel:View {
 let language:String
 var awaiting=false,migration=false,replacement=false,embedded=false,busy=false,available=true,result="",error=""
 let connect:()->Void,checkout:()->Void,refresh:()->Void,replace:()->Void,cancel:()->Void
 @Environment(\.colorScheme) private var scheme
 private var dark:Bool{scheme == .dark}
 private var border:Color{dark ? .white.opacity(0.08):c("b99c76").opacity(0.32)}
 private var soft:Color{dark ? .white.opacity(0.06):c("f2eadc").opacity(0.82)}
 private var muted:Color{c(dark ? "e2e8f0":"6f5b46")}
 private func c(_ hex:String)->Color{PiyaliBrand.unitColor(hex)}
 private func t(_ group:String,_ key:String)->String{SubscriptionCopy.text(group,language,key)}
 private var feedback:String{SubscriptionCopy.run(replacement ? "replacementError":"feedback",.object(["language":.string(language),"result":.string(result),"error":.string(error)])).string}
 var body:some View{
  VStack(spacing:0){if embedded{content}else{GeometryReader{g in ScrollView{content.fixedSize(horizontal:false,vertical:true).padding(replacement || migration ? 17:13).background(dark ? c("0b1220"):c("fffaf1").opacity(0.97),in:RoundedRectangle(cornerRadius:30)).overlay{RoundedRectangle(cornerRadius:30).stroke(border)}.compositingGroup().shadow(color:(dark ? Color.black:c("614a2f")).opacity(dark ? 0.42:0.16),radius:40,y:24).frame(maxWidth:replacement || migration ? 620:760).padding(.horizontal,replacement || migration ? 8:4).padding(.vertical,12).frame(maxWidth:.infinity,minHeight:g.size.height)}.scrollIndicators(.hidden).background{SubscriptionPageBackground(replacement:replacement)}}}}
  .foregroundStyle(c(dark ? "f7fafc":"2f241b")).buttonStyle(.plain).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).accessibilityElement(children:.contain).accessibilityIdentifier(replacement ? "subscriptionReplacement":"subscriptionGate")
 }
 @ViewBuilder private var content:some View {
  if replacement || migration{recoveryContent}
  else{VStack(alignment:.leading,spacing:16){if awaiting{awaitingContent}else{if !embedded{header};benefits;offer};if !feedback.isEmpty{errorText}}}
 }
 private var portrait:some View{BrandArtwork(name:"story-portrait-31.webp").frame(width:92,height:92).frame(height:100).padding(.horizontal,17).padding(.vertical,5).background(soft,in:RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).stroke(border)}}
 private var header:some View{VStack(spacing:12){portrait;VStack(spacing:8){OnboardingText(text:t("gate","title"),size:20,weight:.bold,lineHeight:24);OnboardingText(text:t("gate","subtitle"),size:12,lineHeight:18).foregroundStyle(muted)}}.multilineTextAlignment(.center).frame(maxWidth:.infinity)}
 private var benefits:some View{VStack(alignment:.leading,spacing:12){OnboardingText(text:t("gate","benefitsHeading"),size:14,weight:.bold,lineHeight:21);VStack(alignment:.leading,spacing:8){ForEach(["benefitLanguageApps","benefitSubscriberContent","benefitScholarships"],id:\.self){key in HStack(alignment:.top,spacing:5){Text("•").font(PiyaliBrand.productFont(12)).frame(width:10);OnboardingText(text:t("gate",key),size:12,lineHeight:19.5).frame(maxWidth:.infinity,alignment:.leading)}}}.foregroundStyle(muted).padding(.leading,5)}.padding(17).frame(maxWidth:.infinity,alignment:.leading).background(soft,in:RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).stroke(border)}}
 private var offer:some View{VStack(alignment:.leading,spacing:4){OnboardingText(text:t("flow","membershipTitle"),size:14,weight:.heavy,lineHeight:21).foregroundStyle(c("b794f4"));OnboardingText(text:t("flow","membershipPrice"),size:24,weight:.heavy,lineHeight:36);OnboardingText(text:t("flow","annualValue"),size:14,lineHeight:21).foregroundStyle(c(dark ? "cbd5e0":"7c6955"));OnboardingText(text:t("flow","refundFriendly"),size:14,lineHeight:21).foregroundStyle(c(dark ? "cbd5e0":"7c6955"));Spacer(minLength:16);Button(action:connect){actionLabel(t("flow","membershipCta"),loading:t("gate","checkingPatreon"))}.buttonStyle(SubscriptionActionStyle()).disabled(busy || !available).accessibilityIdentifier("subscriptionConnect")}.padding(17).frame(maxWidth:520,minHeight:230,alignment:.leading).overlay{RoundedRectangle(cornerRadius:28).stroke(c("b794f4"))}.overlay(alignment:.top){OnboardingText(text:t("flow","annualRecommended"),size:12,weight:.heavy,lineHeight:14.4).foregroundStyle(.white).padding(.horizontal,12).padding(.vertical,4).background(c("805ad5"),in:Capsule()).offset(y:-12)}.frame(maxWidth:.infinity)}
 private var awaitingContent:some View{HStack(alignment:.top,spacing:12){Image(systemName:"info.circle.fill").font(.system(size:20)).foregroundStyle(c("3182ce"));VStack(alignment:.leading,spacing:4){OnboardingText(text:t("flow","finishTitle"),size:16,weight:.bold,lineHeight:24);OnboardingText(text:t("flow","finishBody"),size:14,lineHeight:21);VStack(spacing:12){Button(t("flow","openCheckout"),action:checkout).buttonStyle(SubscriptionActionStyle(color:"805ad5",height:40)).accessibilityIdentifier("subscriptionCheckout");Button(action:refresh){actionLabel(t("flow","checkAgain"),loading:t("gate","checkingPatreon"))}.buttonStyle(SubscriptionActionStyle(height:40,outline:true)).disabled(busy).accessibilityIdentifier("subscriptionCheckAgain")}.padding(.top,12)}}.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(c("bee3f8"),in:RoundedRectangle(cornerRadius:20)).accessibilityElement(children:.contain).accessibilityIdentifier("subscriptionAwaiting")}
 private var recoveryContent:some View{let group=replacement ? "replacement":"migration";return VStack(spacing:20){VStack(spacing:0){portrait.padding(.bottom,16);OnboardingText(text:t(group,"eyebrow").uppercased(),size:12,weight:.heavy,lineHeight:18).foregroundStyle(c("9f7aea")).padding(.bottom,8);OnboardingText(text:t(group,"title"),size:20,weight:.bold,lineHeight:24)}.multilineTextAlignment(.center).frame(maxWidth:.infinity);VStack(alignment:.leading,spacing:16){OnboardingText(text:t(group,"body"),size:14,lineHeight:22.75).foregroundStyle(muted);OnboardingText(text:t(group,"reassurance"),size:14,weight:.bold,lineHeight:21)}.padding(20).frame(maxWidth:.infinity,alignment:.leading).background(soft,in:RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).stroke(border)};VStack(spacing:12){Button(action:replacement ? replace:connect){actionLabel(t(group,replacement ? "confirm":"connectAction"),loading:t(replacement ? "replacement":"gate",replacement ? "replacing":"checkingPatreon"))}.buttonStyle(SubscriptionActionStyle(color:"9f7aea")).disabled(busy || !available).accessibilityIdentifier(replacement ? "subscriptionReplace":"subscriptionConnect");if replacement{Button(t(group,"cancel"),action:cancel).font(PiyaliBrand.productFont(16,600)).frame(maxWidth:.infinity,minHeight:40).disabled(busy).accessibilityIdentifier("subscriptionReplacementCancel")}};if !feedback.isEmpty{errorText}}}
 private var errorText:some View{OnboardingText(text:feedback,size:12,lineHeight:18).foregroundStyle(c(dark ? "feb2b2":"9f2d36")).multilineTextAlignment(.center).frame(maxWidth:.infinity).accessibilityIdentifier("subscriptionFeedback")}
 private func actionLabel(_ text:String,loading:String)->some View{HStack(spacing:8){if busy{SubscriptionLoadingRing()};Text(busy ? loading:text)}}
}
struct SubscriptionPageBackground:View {
 var replacement=false
 @Environment(\.colorScheme) private var scheme
 var body:some View{GeometryReader{g in let dark=scheme == .dark;ZStack{PiyaliBrand.unitColor(dark ? "020617":"f8f1e7");RadialGradient(colors:[PiyaliBrand.unitColor(replacement ? "a855f7":"2dd4bf").opacity(dark ? 0.18:0.12),.clear],center:UnitPoint(x:0.18,y:0.18),startRadius:0,endRadius:g.size.width*0.65);RadialGradient(colors:[PiyaliBrand.unitColor(replacement ? "2dd4bf":dark ? "a855f7":"fb923c").opacity(dark ? 0.18:0.14),.clear],center:UnitPoint(x:0.84,y:0.1),startRadius:0,endRadius:g.size.width*0.56)}}.ignoresSafeArea().allowsHitTesting(false)}
}

private struct SubscriptionLoadingRing:View {
 @Environment(\.accessibilityReduceMotion) private var reduced
 var body:some View{TimelineView(.animation(minimumInterval:1.0/30,paused:reduced)){clock in Circle().trim(from:0.05,to:0.72).stroke(.white,lineWidth:2).rotationEffect(.degrees(reduced ? 0:clock.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy:0.45)/0.45*360)).frame(width:16,height:16)}.accessibilityHidden(true)}
}
