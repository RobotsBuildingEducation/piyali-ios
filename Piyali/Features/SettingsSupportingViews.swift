import SwiftUI
import StoreKit

@MainActor enum SettingsCopy {
    static let data=(try? ContentLibrary.load(JSONValue.self,name:"settings-copy")) ?? .null
    static func inline(_ lang:String,_ english:String)->String {let value=data["inline"][english][lang].string;return value.isEmpty ? english:value}
    static func subscription(_ lang:String,_ key:String)->String {let value=data["subscription"][lang][key].string;return value.isEmpty ? data["subscription"]["en"][key].string:value}
}
struct SettingsThemeField:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @AppStorage("piyali.theme") private var theme="light"
    let onChange:(String)->Void
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private func t(_ key:String)->String{EntryCopy.ui(app.learner.support,key)}
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            VStack(alignment:.leading,spacing:4){
                OnboardingText(text:t("theme_mode_label"),size:14,weight:.semibold,lineHeight:21)
                OnboardingText(text:t("theme_mode_description"),size:12,lineHeight:18).foregroundStyle(brand.muted)
            }.frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,.leftToRight)
            ForEach(["dark","light"],id:\.self){value in
                let selected=theme == value
                Button{onChange(value)}label:{
                    VStack(alignment:.leading,spacing:12){
                        preview(value)
                        HStack(alignment:.top,spacing:12){
                            Image(systemName:value == "dark" ? "moon.fill":"sun.max")
                                .font(.system(size:18)).foregroundStyle(selected ? .white:brand.secondary)
                                .frame(width:36,height:36)
                                .background(selected ? PiyaliBrand.unitColor("38b2ac"):PiyaliBrand.unitColor(scheme == .dark ? "1f2937":"f1e8dc"),in:Circle())
                            OnboardingText(text:t(value == "dark" ? "theme_mode_dark":"theme_mode_light"),size:14,weight:.semibold,lineHeight:21)
                            Spacer(minLength:0)
                        }
                    }.padding(12).background(PiyaliBrand.unitColor(scheme == .dark ? (selected ? "1f2937":"111827"):(selected ? "fffdf9":"fbf7f0")),in:RoundedRectangle(cornerRadius:20))
                        .overlay{RoundedRectangle(cornerRadius:20).stroke(selected ? PiyaliBrand.unitColor("38b2ac"):brand.border)}
                        .overlay{if selected{RoundedRectangle(cornerRadius:20).stroke(PiyaliBrand.unitColor("38b2ac").opacity(0.2),lineWidth:3).padding(-1)}}
                }.accessibilityIdentifier("settingsTheme-"+value).accessibilityAddTraits(selected ? .isSelected:[])
            }
        }.settingsCard(PiyaliBrand.unitColor(scheme == .dark ? "111827":"f1e8dc"))
            .overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}
    }
    private func preview(_ value:String)->some View {
        GeometryReader{g in
            let dark=value == "dark",panelWidth=(g.size.width-26)*0.7
            ZStack(alignment:.topLeading){
                LinearGradient(colors:dark ? [PiyaliBrand.unitColor("10172a"),PiyaliBrand.unitColor("0b1220")]:[PiyaliBrand.unitColor("fffdf9"),PiyaliBrand.unitColor("f7f1e7")],startPoint:.top,endPoint:.bottom)
                VStack(alignment:.leading,spacing:8){
                    Capsule().fill(PiyaliBrand.unitColor("7ce3d8")).frame(width:(panelWidth-26)*0.42,height:9)
                    Capsule().fill(PiyaliBrand.unitColor(dark ? "e5e7eb":"38bed1")).frame(width:(panelWidth-26)*0.88,height:7).opacity(0.9)
                    Capsule().fill(PiyaliBrand.unitColor(dark ? "94a3b8":"8d7a67")).frame(width:(panelWidth-26)*0.64,height:7).opacity(0.8)
                    HStack(spacing:8){Capsule().fill(PiyaliBrand.unitColor(dark ? "e5e7eb":"38bed1").opacity(0.08));Capsule().fill(PiyaliBrand.unitColor("7ce3d8").opacity(0.5)).frame(width:(panelWidth-34)*0.8/1.8)}.frame(height:22).padding(.top,4)
                }.padding(12).frame(width:panelWidth,height:74,alignment:.topLeading)
                    .background(PiyaliBrand.unitColor(dark ? "111827":"fffdf9").opacity(dark ? 0.88:0.96),in:RoundedRectangle(cornerRadius:14))
                    .overlay{RoundedRectangle(cornerRadius:14).stroke(.white.opacity(0.06))}
                    .shadow(color:PiyaliBrand.unitColor("0f172a").opacity(0.16),radius:14,y:12).padding(12)
                Capsule().fill(LinearGradient(colors:[PiyaliBrand.unitColor("7ce3d8"),PiyaliBrand.unitColor("9de6ef")],startPoint:.topLeading,endPoint:.bottomTrailing)).frame(width:34,height:6).opacity(0.9).position(x:g.size.width-29,y:13)
            }
        }.frame(height:100).clipShape(RoundedRectangle(cornerRadius:16))
            .overlay{RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.08))}
    }
}
struct SettingsPostsInfoView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let onClose:()->Void
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private func t(_ key:String)->String {EntryCopy.ui(app.learner.support,key)}
    var body:some View {
        ZStack{
            Color.black.opacity(0.64).ignoresSafeArea().onTapGesture(perform:onClose)
            VStack(alignment:.leading,spacing:0){
                OnboardingText(text:t("allow_posts_info_title"),size:18,weight:.bold,lineHeight:27)
                    .padding(.horizontal,32).padding(.top,20)
                OnboardingText(text:t("allow_posts_info_desc"),size:14,lineHeight:22.75).opacity(0.88)
                    .padding(.horizontal,28).padding(.top,8)
                Link(destination:URL(string:"https://ditto.pub/"+app.identity.npub)!){
                    HStack(spacing:6){Text(t("allow_posts_info_view_ditto")).underline();Image(systemName:"arrow.up.right.square").font(.system(size:14))}
                        .font(PiyaliBrand.productFont(14,500)).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "76e4f7":"086f83"))
                }.padding(.horizontal,28).padding(.top,16).padding(.bottom,24)
            }.frame(maxWidth:370,alignment:.leading)
                .background(scheme == .dark ? PiyaliBrand.unitColor("111827"):.white,in:RoundedRectangle(cornerRadius:48))
                .overlay(alignment:.topTrailing){Button(action:onClose){MemoryIcon(name:"close",size:16).frame(width:32,height:32)}.padding(16).accessibilityLabel(t("close")).accessibilityIdentifier("settingsPostsInfoClose")}
                .overlay{RoundedRectangle(cornerRadius:48).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).padding(1.5).allowsHitTesting(false)}
                .shadow(color:.black.opacity(0.25),radius:25,y:16).padding(.horizontal,16)
        }.foregroundStyle(brand.text).accessibilityElement(children:.contain).accessibilityIdentifier("settingsPostsInfoDialog").accessibilityAddTraits(.isModal)
    }
}
struct SettingsSubscriptionView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private func t(_ key:String)->String {SettingsCopy.subscription(app.learner.support,key)}
    private var gate:JSONValue{SettingsCopy.data["gate"][app.learner.support] == .null ? SettingsCopy.data["gate"]["en"]:SettingsCopy.data["gate"][app.learner.support]}
    var body:some View {SettingsSubscriptionContent(service:app.subscription,lang:app.learner.support,gate:gate)}
}
private struct SettingsSubscriptionContent:View {
    @ObservedObject var service:SubscriptionService
    @Environment(\.colorScheme) private var scheme
    let lang:String,gate:JSONValue
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private func t(_ key:String)->String {SettingsCopy.subscription(lang,key)}
    var body:some View {
        VStack(alignment:.leading,spacing:16){
            if service.authorized{VStack(alignment:.leading,spacing:8){OnboardingText(text:t("title"),size:16,weight:.semibold,lineHeight:24);OnboardingText(text:t("active"),size:16,lineHeight:24)}.settingsCard(PiyaliBrand.unitColor(scheme == .dark ? "111827":"f1e8dc"))}
            else {
                VStack(alignment:.leading,spacing:12){
                    OnboardingText(text:gate["benefitsHeading"].string,size:14,weight:.bold,lineHeight:21)
                    VStack(alignment:.leading,spacing:8){ForEach(["benefitLanguageApps","benefitSubscriberContent","benefitScholarships"],id:\.self){key in HStack(alignment:.top,spacing:7){Text("•").font(PiyaliBrand.productFont(12)).frame(width:8);OnboardingText(text:gate[key].string,size:12,lineHeight:19.5)}}}.padding(.leading,5).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "e2e8f0":"6f5b46"))
                }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(scheme == .dark ? Color.white.opacity(0.06):PiyaliBrand.unitColor("f2eadc").opacity(0.82),in:RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).stroke(scheme == .dark ? Color.white.opacity(0.16):PiyaliBrand.unitColor("b99c76").opacity(0.32))}
                if service.externalPaymentAllowed{membership}
            }
            if !service.products.isEmpty {ForEach(service.products){product in Button{Task{await service.buy(product)}}label:{VStack(alignment:.leading,spacing:8){Text(product.displayName).font(PiyaliBrand.productFont(16,600));Text(product.displayPrice).font(PiyaliBrand.productFont(24,700))}.frame(maxWidth:.infinity,alignment:.leading).padding(20).background(PiyaliBrand.unitColor("805ad5"),in:RoundedRectangle(cornerRadius:24)).foregroundStyle(.white)}.disabled(service.busy)}}

            Button{Task{await service.refresh()}}label:{HStack{if service.busy{ProgressView()};Text(t("refresh"))}.frame(maxWidth:.infinity)}.buttonStyle(SettingsActionStyle(color:"319795")).disabled(service.busy).accessibilityIdentifier("settingsSubscriptionRefresh")
            Button{Task{await service.restore()}}label:{Text(EntryCopy.ui(lang,"restore_purchases").isEmpty || EntryCopy.ui(lang,"restore_purchases") == "restore_purchases" ? "Restore purchases and web access":EntryCopy.ui(lang,"restore_purchases"))}.font(PiyaliBrand.productFont(14,600)).disabled(service.busy)
            if service.appleAuthorized{Link("Manage Apple subscription",destination:URL(string:"https://apps.apple.com/account/subscriptions")!)}
            if service.webAuthorized{Link(t("manage"),destination:URL(string:"https://www.patreon.com/settings/memberships")!)}
            if let error=service.error{OnboardingText(text:error,size:14,lineHeight:21).foregroundStyle(.red)}
        }.foregroundStyle(brand.text)
    }
    private var flow:JSONValue{let value=SettingsCopy.data["flow"][lang];return value == .null ? SettingsCopy.data["flow"]["en"]:value}
    private var membership:some View {
        VStack(alignment:.leading,spacing:4){
            OnboardingText(text:flow["membershipTitle"].string,size:14,weight:.heavy,lineHeight:21).foregroundStyle(PiyaliBrand.unitColor("b794f4"))
            OnboardingText(text:(lang == "ar" ? "\u{200F}":"")+flow["membershipPrice"].string,size:24,weight:.heavy,lineHeight:36)
            OnboardingText(text:flow["annualValue"].string,size:14,lineHeight:21).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "cbd5e0":"7c6955"))
            OnboardingText(text:flow["refundFriendly"].string,size:14,lineHeight:21).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "cbd5e0":"7c6955"))
            Spacer(minLength:16)
            Link(destination:AppConfiguration().subscriptionURL){OnboardingText(text:flow["membershipCta"].string,size:16,weight:.semibold,lineHeight:24).frame(maxWidth:.infinity,minHeight:60).foregroundStyle(.white).background(PiyaliBrand.unitColor("b794f4"),in:Capsule()).background(Capsule().fill(PiyaliBrand.unitColor("6b46c1")).offset(y:4)).padding(.bottom,4)}.accessibilityIdentifier("settingsWebSubscription")
        }.padding(16).frame(maxWidth:.infinity,minHeight:230,alignment:.leading).overlay{RoundedRectangle(cornerRadius:28).stroke(PiyaliBrand.unitColor("b794f4"))}.overlay(alignment:.top){Text(flow["annualRecommended"].string).font(PiyaliBrand.productFont(12,900)).foregroundStyle(.white).padding(.horizontal,12).padding(.vertical,4).background(PiyaliBrand.unitColor("805ad5"),in:Capsule()).offset(y:-12)}
    }

}
