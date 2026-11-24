import SwiftUI

@MainActor enum ScholarshipCopy {
    static let data=(try? ContentLibrary.load(JSONValue.self,name:"scholarship-copy")) ?? .null
    static func text(_ lang:String,_ key:String)->String{let value=data["copy"][lang][key].string;return value.isEmpty ? data["copy"]["en"][key].string:value}
    static func inline(_ lang:String,_ en:String)->String{let value=data["inline"][en][lang].string;return value.isEmpty ? en:value}
}
struct ScholarshipSupportPanel<Wallet:View>:View {
    let language:String,selected:String,ready:Bool
    let onChoose:(String)->Void,onClose:()->Void
    var initialRecipientsOpen=false
    @ViewBuilder let wallet:()->Wallet
    @State private var recipientsOpen=false
    @Environment(\.colorScheme) private var scheme
    private func c(_ hex:String)->Color{PiyaliBrand.unitColor(hex)}
    private func t(_ key:String)->String{ScholarshipCopy.text(language,key)}
    private func s(_ english:String)->String{ScholarshipCopy.inline(language,english)}
    var body:some View {
        GeometryReader{g in ZStack{
            c(scheme == .dark ? "020617":"1c140c").opacity(scheme == .dark ? 0.92:0.82).ignoresSafeArea()
            VStack(spacing:0){
                VStack(spacing:12){BrandArtwork(name:"story-portrait-40.webp").frame(width:82,height:82).frame(height:100);OnboardingText(text:t("title"),size:20,weight:.bold,lineHeight:24).foregroundStyle(.white);OnboardingText(text:t("subtitle"),size:12,lineHeight:17.4).foregroundStyle(c("5a3510"))}.multilineTextAlignment(.center).frame(maxWidth:.infinity).padding(.horizontal,20).padding(.vertical,16).background(LinearGradient(colors:[c("f7931a"),c("ffb347")],startPoint:.leading,endPoint:.trailing)).overlay(alignment:.bottom){Rectangle().fill(.black.opacity(0.18)).frame(height:1)}
                ScrollView{VStack(alignment:.leading,spacing:16){wallet();VStack(alignment:.leading,spacing:0){
                    if ready{Button{recipientsOpen.toggle()}label:{HStack{VStack(alignment:.leading,spacing:4){OnboardingText(text:s("Choose a recipient"),size:14,lineHeight:21);if let recipient=WalletCopy.recipients.first(where:{$0["npub"].string == selected}){OnboardingText(text:recipient["label"].string,size:12,lineHeight:18).foregroundStyle(c("8d6d46"))}}.frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,.leftToRight);Image(systemName:recipientsOpen ? "chevron.up":"chevron.down").font(.system(size:14))}.padding(.vertical,8).contentShape(Rectangle())}.accessibilityIdentifier("scholarshipRecipientAccordion")}
                    else{OnboardingText(text:s("Choose a recipient"),size:14,lineHeight:21).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,.leftToRight).padding(.bottom,8)}
                    if !ready || recipientsOpen{recipientChoices.padding(.top,ready ? 8:0)}
                }.padding(.top,8)}.padding(16)}.scrollIndicators(.hidden).frame(maxWidth:.infinity,maxHeight:.infinity).background(c("f6ecdb"))
                VStack(spacing:8){HStack(spacing:12){Spacer();Button(t("skip"),action:onClose).font(PiyaliBrand.productFont(16,600)).padding(.horizontal,16).frame(minHeight:40).accessibilityIdentifier("scholarshipLater");Button(t("done"),action:onClose).font(PiyaliBrand.productFont(16,600)).foregroundStyle(.white).padding(.horizontal,16).frame(minHeight:40).background(c("319795"),in:Capsule()).background(Capsule().fill(c("1f6f68")).offset(y:4)).accessibilityIdentifier("scholarshipDone")};OnboardingText(text:t("footer"),size:12,lineHeight:18).foregroundStyle(c("715331")).multilineTextAlignment(.center).frame(maxWidth:.infinity)}.padding(.horizontal,16).padding(.vertical,12).background(c("f1e4ce")).overlay(alignment:.top){Rectangle().fill(c("d7b98d")).frame(height:1)}
            }.frame(width:min(g.size.width-32,g.size.width*0.92),height:min(g.size.height*0.8,720)).background(c("f8f0df")).clipShape(RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(c("d7b98d"))}.shadow(color:c("352412").opacity(0.28),radius:30,y:24).overlay(alignment:.topTrailing){Button(action:onClose){Image(systemName:"xmark").font(.system(size:12,weight:.semibold)).foregroundStyle(.white).frame(width:40,height:40).contentShape(Rectangle())}.accessibilityLabel(s("Close")).accessibilityIdentifier("scholarshipClose").padding(16)}
        }}.ignoresSafeArea(.container).foregroundStyle(c("352412")).buttonStyle(.plain).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).accessibilityElement(children:.contain).accessibilityIdentifier("scholarshipDialog").onAppear{recipientsOpen=initialRecipientsOpen}
    }
    private var recipientChoices:some View {VStack(alignment:.leading,spacing:8){ForEach(WalletCopy.recipients,id:\.canonicalJSON){recipient in HStack(spacing:8){Button{onChoose(recipient["npub"].string)}label:{HStack(spacing:8){ZStack{Circle().stroke(c(selected == recipient["npub"].string ? "dd6b20":"352412"),lineWidth:1.5);if selected == recipient["npub"].string{Circle().fill(c("dd6b20"));Circle().fill(.white).padding(4)}}.frame(width:12,height:12);Text(recipient["label"].string).font(PiyaliBrand.productFont(12)).lineLimit(1)}.frame(maxWidth:.infinity,alignment:.leading).contentShape(Rectangle())}.accessibilityIdentifier("scholarshipRecipient-"+recipient["label"].string).accessibilityAddTraits(selected == recipient["npub"].string ? .isSelected:[]);Link(s("View site"),destination:URL(string:recipient["identityUrl"].string)!).font(PiyaliBrand.productFont(12)).foregroundStyle(c("0f766e")).fixedSize()}.frame(minHeight:24).padding(.horizontal,12).padding(.vertical,10).background(c(selected == recipient["npub"].string ? "f5dfbe":"fff8eb"),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(c(selected == recipient["npub"].string ? "c67c1b":"dcc09a"))}};if selected.isEmpty{OnboardingText(text:s("Select an option to enable deposits."),size:12,lineHeight:18).foregroundStyle(c("996300")).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,.leftToRight)}}.accessibilityElement(children:.contain)}
}
