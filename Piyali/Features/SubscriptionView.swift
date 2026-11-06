import SwiftUI
import StoreKit
import SafariServices

struct SubscriptionView:View {
 @EnvironmentObject var app:AppModel
 @ObservedObject var service:SubscriptionService
 @State private var nativeTools=false
 var body:some View{
  VStack(spacing:0){SubscriptionGatePanel(language:app.learner.support,awaiting:service.awaiting,migration:app.learner.legacySubscriptionPasscodeVerified == true && !service.authorized,replacement:service.replacementRequired,busy:service.busy,available:service.externalPaymentAllowed && service.statusPayload["configured"] != .bool(false),result:service.result,error:service.statusError,connect:{Task{await service.connect(language:app.learner.support)}},checkout:service.checkout,refresh:{Task{await service.checkMembership(language:app.learner.support)}},replace:{Task{await service.replaceLinkedKey()}},cancel:{Task{await service.cancelReplacement()}})
   Button("iPhone purchases and access"){nativeTools=true}.font(PiyaliBrand.productFont(12,600)).padding(8).accessibilityIdentifier("subscriptionNativeTools")
  }.background(SubscriptionPageBackground()).toolbar(.hidden,for:.navigationBar).subscriptionBrowser(service)
   .sheet(isPresented:$nativeTools){NavigationStack{SubscriptionNativeTools(service:service).toolbar{ToolbarItem(placement:.confirmationAction){Button("Close"){nativeTools=false}}}}}
 }
}
struct SettingsSubscriptionView:View {
 @EnvironmentObject var app:AppModel
 @State private var confirmingDisconnect=false
 var body:some View{SettingsSubscriptionContent(service:app.subscription,language:app.learner.support,confirmingDisconnect:$confirmingDisconnect)}
}
private struct SettingsSubscriptionContent:View {
 @ObservedObject var service:SubscriptionService
 let language:String
 @Binding var confirmingDisconnect:Bool
 @State private var nativeTools=false
 var body:some View{VStack(alignment:.leading,spacing:16){if service.appleAuthorized && !service.statusPayload["linked"].boolean{VStack(alignment:.leading,spacing:8){Text("App Store").font(PiyaliBrand.productFont(16,600));Text(SubscriptionCopy.text("settings",language,"active")).font(PiyaliBrand.productFont(16))}.padding(20).frame(maxWidth:.infinity,alignment:.leading).background(PiyaliBrand.unitColor("1a202c"),in:RoundedRectangle(cornerRadius:24)).foregroundStyle(.white)}else{SubscriptionMembershipPanel(language:language,status:service.statusPayload.setting("checkoutRequired",.bool(service.awaiting)),resolved:service.statusResolved,busy:service.busy,available:service.externalPaymentAllowed && service.statusPayload["configured"] != .bool(false),result:service.result,error:service.statusError,confirmingDisconnect:confirmingDisconnect,connect:{Task{await service.connect(language:language)}},checkout:service.checkout,refresh:{Task{await service.checkMembership(language:language)}},replace:{Task{await service.replaceLinkedKey()}},cancelReplacement:{Task{await service.cancelReplacement()}},askDisconnect:{confirmingDisconnect=true},cancelDisconnect:{confirmingDisconnect=false},disconnect:{Task{await service.disconnectWeb();if service.statusError.isEmpty{confirmingDisconnect=false}}})}
   Button(SubscriptionCopy.text("settings",language,"refresh")){Task{await service.refresh(forceWeb:true)}}.buttonStyle(SettingsActionStyle(color:"319795")).disabled(service.busy).accessibilityIdentifier("settingsSubscriptionRefresh")
   Button("iPhone purchases and access"){nativeTools=true}.font(PiyaliBrand.productFont(12,600)).accessibilityIdentifier("subscriptionNativeTools")
  }.subscriptionBrowser(service).sheet(isPresented:$nativeTools){NavigationStack{SubscriptionNativeTools(service:service).toolbar{ToolbarItem(placement:.confirmationAction){Button("Close"){nativeTools=false}}}}}.task{if !service.statusResolved{await service.refresh()}}}
}
struct SubscriptionNativeTools:View {
 @ObservedObject var service:SubscriptionService
 private let config=AppConfiguration()
 var body:some View{List{
  if service.appleAuthorized{Text("Verified Apple subscription")}
  Section("Subscribe on iPhone"){ForEach(service.products){product in Button("\(product.displayName) · \(product.displayPrice)"){Task{await service.buy(product)}}.disabled(service.busy)};if service.products.isEmpty{Text("App Store plans are not available yet.")};Button("Restore purchases and web access"){Task{await service.restore()}}.disabled(service.busy);Button("Refresh subscription"){Task{await service.refresh(forceWeb:true)}}.disabled(service.busy);Link("Manage Apple subscription",destination:URL(string:"https://apps.apple.com/account/subscriptions")!)}
  if service.externalPaymentAllowed{Section("Subscribe on the web"){Link("Open Piyali web subscriptions",destination:config.subscriptionURL).accessibilityIdentifier("subscriptionWebLink");Text("Return to Piyali after subscribing and refresh access.").font(.footnote)}}
  Section{NavigationLink("Subscription terms"){SubscriptionTermsView()};NavigationLink("Privacy"){PrivacyDisclosureView()}}
  if let error=service.error{Text(error).foregroundStyle(.red)}
 }.navigationTitle("Subscription")}
}
private struct SubscriptionSafariView:UIViewControllerRepresentable {
 let url:URL,onDone:()->Void
 func makeCoordinator()->Coordinator{Coordinator(onDone)}
 func makeUIViewController(context:Context)->SFSafariViewController{let vc=SFSafariViewController(url:url);vc.delegate=context.coordinator;return vc}
 func updateUIViewController(_ vc:SFSafariViewController,context:Context){}
 final class Coordinator:NSObject,SFSafariViewControllerDelegate{let done:()->Void;init(_ done:@escaping()->Void){self.done=done};func safariViewControllerDidFinish(_ controller:SFSafariViewController){done()}}
}
private struct SubscriptionBrowserModifier:ViewModifier {
 @ObservedObject var service:SubscriptionService
 func body(content:Content)->some View{content.sheet(item:$service.browser,onDismiss:service.browserClosed){request in SubscriptionSafariView(url:request.url,onDone:service.browserClosed).ignoresSafeArea()}}
}
extension View{func subscriptionBrowser(_ service:SubscriptionService)->some View{modifier(SubscriptionBrowserModifier(service:service))}}
