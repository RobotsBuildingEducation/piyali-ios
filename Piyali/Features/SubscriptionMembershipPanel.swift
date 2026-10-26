import SwiftUI

struct SubscriptionMembershipPanel:View {
 @Environment(\.colorScheme) private var scheme
 let language:String,status:JSONValue
 var resolved=true,busy=false,available=true,result="",error="",confirmingDisconnect=false
 let connect:()->Void,checkout:()->Void,refresh:()->Void,replace:()->Void,cancelReplacement:()->Void,askDisconnect:()->Void,cancelDisconnect:()->Void,disconnect:()->Void
 private var dark:Bool{scheme == .dark}
 private var primary:Color{c(dark ? "e5e7eb":"2f261d")}
 private func c(_ hex:String)->Color{PiyaliBrand.unitColor(hex)}
 private func t(_ key:String)->String{SubscriptionCopy.text("settings",language,key)}
 private var state:JSONValue{SubscriptionCopy.run("view",status)}
 private var statusText:String{let key=state["unavailable"].boolean || state["status"].string == "unknown" ? "unavailable":state["status"].string == "active" ? "active":state["status"].string == "payment_issue" ? "paymentIssue":["inactive","expired"].contains(state["status"].string) ? "inactive":"notLinked";return t(key)}
 var body:some View{
  VStack(spacing:0){
   if !resolved{ProgressView().controlSize(.large).tint(c("b794f4")).frame(maxWidth:.infinity,minHeight:280).accessibilityLabel(t("refreshing"))}
   else if !state["authorized"].boolean && (state["replacementRequired"].boolean || result == "replace_required"){gate(replacement:true)}
   else if !state["linked"].boolean || state["awaitingCheckout"].boolean{gate(awaiting:state["awaitingCheckout"].boolean || ["checkout_required","awaiting_subscription"].contains(result))}
   else{linked}
  }.buttonStyle(.plain).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).accessibilityElement(children:.contain).accessibilityIdentifier("subscriptionMembership")
 }
 private func gate(awaiting:Bool=false,replacement:Bool=false)->some View{SubscriptionGatePanel(language:language,awaiting:awaiting,replacement:replacement,embedded:true,busy:busy,available:available,result:result,error:error,connect:connect,checkout:checkout,refresh:refresh,replace:replace,cancel:cancelReplacement)}
 private var linked:some View{VStack(alignment:.leading,spacing:16){
  VStack(alignment:.leading,spacing:0){OnboardingText(text:t("title"),size:16,weight:.bold,lineHeight:19.2);OnboardingText(text:statusText,size:16,lineHeight:24).foregroundStyle(c(dark ? "cbd5e1":"5b4b3a")).padding(.top,8)
   if state["subscription"]["stale"].boolean{HStack(alignment:.top,spacing:12){Image(systemName:"exclamationmark.circle.fill").font(.system(size:20)).frame(width:20).foregroundStyle(c("dd6b20"));OnboardingText(text:t("stale"),size:14,lineHeight:21)}.padding(16).background(c("7b341e"),in:RoundedRectangle(cornerRadius:16)).padding(.top,16)}
   if state["subscription"]["lastVerifiedAtMs"].number > 0{OnboardingText(text:t("lastChecked")+": "+checkedAt,size:12,lineHeight:18).foregroundStyle(c(dark ? "94a3b8":"786654")).padding(.top,12)}
   if state["entitledAmountCents"].number > 0{OnboardingText(text:t("entitlement")+": "+SubscriptionCopy.run("currency",.object(["language":.string(language),"cents":state["entitledAmountCents"]])).string,size:14,lineHeight:21).foregroundStyle(c(dark ? "cbd5e1":"5b4b3a")).padding(.top,12)}
  }.padding(20).frame(maxWidth:.infinity,alignment:.leading).background(c(dark ? "111827":"f1e8dc"),in:RoundedRectangle(cornerRadius:24)).overlay{RoundedRectangle(cornerRadius:24).stroke(c(dark ? "1f2937":"e0d2bf"))}.foregroundStyle(primary)
  SubscriptionButtonFlow(){actions}
  if state["showDisconnect"].boolean && !confirmingDisconnect{Button(t("disconnect"),action:askDisconnect).font(PiyaliBrand.productFont(16,600)).foregroundStyle(primary).padding(.horizontal,16).frame(minHeight:40).accessibilityIdentifier("subscriptionAskDisconnect")}
  if state["linked"].boolean && confirmingDisconnect{disconnectConfirmation}
  if !error.isEmpty{OnboardingText(text:t("unavailable"),size:12,lineHeight:18).foregroundStyle(c("e53e3e")).accessibilityIdentifier("subscriptionFeedback")}
 }.padding(.bottom,56)}
 @ViewBuilder private var actions:some View{
  if state["showConnect"].boolean{Button(t("connect"),action:connect).buttonStyle(MembershipOutlineStyle(filled:true)).disabled(busy || !available).accessibilityIdentifier("subscriptionConnect")}
  if state["showReconnect"].boolean{Button(t("reconnect"),action:connect).buttonStyle(MembershipOutlineStyle()).disabled(busy || !available).accessibilityIdentifier("subscriptionReconnect")}
  if state["showManage"].boolean{Link(t("manage"),destination:URL(string:"https://www.patreon.com/settings/memberships")!).buttonStyle(MembershipOutlineStyle()).accessibilityIdentifier("subscriptionManage")}
  if state["showPayment"].boolean{Link(t("payment"),destination:URL(string:"https://www.patreon.com/settings/payments")!).buttonStyle(MembershipOutlineStyle()).accessibilityIdentifier("subscriptionPayment")}
 }
 private var disconnectConfirmation:some View{HStack(alignment:.top,spacing:12){Image(systemName:"exclamationmark.circle.fill").font(.system(size:20)).frame(width:20).foregroundStyle(c("dd6b20"));VStack(alignment:.leading,spacing:4){OnboardingText(text:t("disconnectTitle"),size:16,weight:.bold,lineHeight:24);OnboardingText(text:t("disconnectBody"),size:14,lineHeight:21).foregroundStyle(c(dark ? "cbd5e1":"5b4b3a"));HStack(spacing:8){Button(t("cancel"),action:cancelDisconnect).buttonStyle(MembershipOutlineStyle(small:true,ghost:true)).accessibilityIdentifier("subscriptionDisconnectCancel");Button(busy ? t("disconnecting"):t("confirm"),action:disconnect).buttonStyle(MembershipOutlineStyle(red:true,filled:true,small:true)).disabled(busy).accessibilityIdentifier("subscriptionDisconnectConfirm")}.padding(.top,12)}}.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(c(dark ? "111827":"f1e8dc"),in:RoundedRectangle(cornerRadius:20)).foregroundStyle(primary)}
 private var checkedAt:String{let f=DateFormatter();f.locale=Locale(identifier:language);f.dateStyle = .medium;f.timeStyle = .short;return f.string(from:Date(timeIntervalSince1970:state["subscription"]["lastVerifiedAtMs"].number/1000))}
}
private struct MembershipOutlineStyle:ButtonStyle {
 @Environment(\.colorScheme) private var scheme
 var red=false,filled=false,small=false,ghost=false
 func makeBody(configuration:Configuration)->some View{let dark=scheme == .dark;return configuration.label.font(PiyaliBrand.productFont(small ? 14:16,600)).padding(.horizontal,small ? 12:16).frame(minHeight:small ? 32:40).foregroundStyle(filled ? Color.white:PiyaliBrand.unitColor(dark ? "e5e7eb":"2f261d")).background(filled ? PiyaliBrand.unitColor(red ? "e53e3e":"319795"):ghost ? Color.clear:PiyaliBrand.unitColor(dark ? "111827":"fffdf9"),in:Capsule()).overlay{if !filled && !ghost{Capsule().stroke(PiyaliBrand.unitColor(dark ? "94a3b8":"604d38").opacity(dark ? 0.2:0.16))}}.background{if filled{Capsule().fill(PiyaliBrand.unitColor(red ? "63171b":"234e52")).offset(y:4)}}.opacity(configuration.isPressed ? 0.7:1)}
}
private struct SubscriptionButtonFlow:Layout {
 func sizeThatFits(proposal:ProposedViewSize,subviews:Subviews,cache:inout())->CGSize{let width=proposal.width ?? 346;return CGSize(width:width,height:positions(width,subviews).last?.maxY ?? 0)}
 func placeSubviews(in bounds:CGRect,proposal:ProposedViewSize,subviews:Subviews,cache:inout()){for(view,rect)in zip(subviews,positions(bounds.width,subviews)){view.place(at:CGPoint(x:bounds.minX+rect.minX,y:bounds.minY+rect.minY),proposal:ProposedViewSize(rect.size))}}
 private func positions(_ width:CGFloat,_ subviews:Subviews)->[CGRect]{var x:CGFloat=0,y:CGFloat=0,row:CGFloat=0;return subviews.map{view in let s=view.sizeThatFits(.unspecified);if x>0 && x+s.width>width{x=0;y+=row+8;row=0};let rect=CGRect(origin:CGPoint(x:x,y:y),size:s);x+=s.width+16;row=max(row,s.height);return rect}}
}
