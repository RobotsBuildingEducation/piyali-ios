import SwiftUI
import CoreImage.CIFilterBuiltins

@MainActor enum WalletCopy {
    static let data=(try? ContentLibrary.load(JSONValue.self,name:"wallet-copy")) ?? .null
    static func text(_ lang:String,_ key:String)->String {let value=data["wallet"][lang][key].string;return value.isEmpty ? data["wallet"]["en"][key].string:value}
    static func transactions(_ lang:String,_ key:String)->String {let value=data["transactions"][lang][key].string;return value.isEmpty ? data["transactions"]["en"][key].string:value}
    static var recipients:[JSONValue]{data["recipients"].array}
    static let publicNote="Robots Building Education"
    static let cardName="Robots Building Education Wallet"
}

/// Source wallet section. Side effects live in WalletView; previews use inert callbacks.
struct WalletPanelView:View {
    let language:String
    let selected:String
    var ready=false
    var hydrating=false
    var busy=false
    var canCreate=false
    var balance=0
    var invoice=""
    var compact=false
    var showIntro=true
    var showRecipients=true
    var transparent=false
    var forcePaper=false
    let choose:(String)->Void
    let create:()->Void
    let deposit:()->Void
    let copy:()->Void
    let transactions:()->Void
    @Environment(\.colorScheme) private var scheme
    private var paper:Bool{forcePaper || scheme != .dark}
    private var text:Color{color("362311","f1f5f9")}
    private var muted:Color{color("6f5130","cbd5e1")}
    private var link:Color{color("0f766e","81e6d9")}
    private func color(_ light:String,_ dark:String)->Color{PiyaliBrand.unitColor(paper ? light:dark)}
    private func w(_ key:String)->String{WalletCopy.text(language,key)}
    private func t(_ english:String)->String{SettingsCopy.inline(language,english)}
    var body:some View {
        VStack(alignment:.leading,spacing:0){
            if showIntro{
            OnboardingText(text:t("Bitcoin wallet"),size:14,weight:.bold,lineHeight:21).padding(.bottom,8)
            Link(destination:URL(string:"https://robotsbuildingeducation.com")!){(Text(w("scholarshipNote")+" ")+Text("RobotsBuildingEducation.com").underline()).font(PiyaliBrand.productFont(12)).lineSpacing(18-UIFont.systemFont(ofSize:12).lineHeight).padding(.vertical,(18-UIFont.systemFont(ofSize:12).lineHeight)/2).fixedSize(horizontal:false,vertical:true)}.foregroundStyle(color("9b5f17","b2f5ea")).padding(.bottom,12)
            }
            if showRecipients{
            VStack(alignment:.leading,spacing:8){
                OnboardingText(text:t("Choose a recipient"),size:14,lineHeight:21).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,.leftToRight)
                ForEach(WalletCopy.recipients,id:\.canonicalJSON){recipient in
                    HStack(spacing:12){Button{choose(recipient["npub"].string)}label:{HStack(spacing:8){ZStack{Circle().stroke(selected == recipient["npub"].string ? color("dd6b20","805ad5"):color("362311","cbd5e1"),lineWidth:1.5).frame(width:12,height:12);if selected == recipient["npub"].string{Circle().fill(color("dd6b20","805ad5")).frame(width:12,height:12);Circle().fill(.white).frame(width:4,height:4)}};OnboardingText(text:recipient["label"].string,size:14,lineHeight:21)}}.accessibilityIdentifier("walletRecipient-"+recipient["label"].string).accessibilityAddTraits(selected == recipient["npub"].string ? .isSelected:[])
                        if selected == recipient["npub"].string,let url=URL(string:recipient["identityUrl"].string){Link(t("View site"),destination:url).font(PiyaliBrand.productFont(12)).foregroundStyle(link).fixedSize()}
                    }.frame(maxWidth:.infinity,alignment:.leading)
                }
                if selected.isEmpty{OnboardingText(text:t("Select an option to enable deposits."),size:12,lineHeight:18).foregroundStyle(color("9a6700","fbd38d")).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,.leftToRight).accessibilityIdentifier("walletRecipientRequired")}
            }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(color("fffdf9","1f2937"),in:RoundedRectangle(cornerRadius:6)).padding(.bottom,12)
            }
            if hydrating && !ready {HStack(spacing:12){ProgressView().controlSize(.small);Text(t("Loading wallet…")).font(PiyaliBrand.productFont(14))}.padding(.vertical,24).frame(maxWidth:.infinity)}
            else if !ready,canCreate {Button(action:create){HStack(spacing:8){if busy{ProgressView().controlSize(.small)};Text(w(busy ? "loadingWallet":"createWallet"))}.frame(minWidth:112)}.buttonStyle(WalletOutlineStyle(paper:paper)).disabled(busy).frame(maxWidth:.infinity).accessibilityIdentifier("walletCreate")}
            else if ready {
                if balance > 0 || invoice.isEmpty {
                    WalletIdentityCard(balance:balance,label:w("balanceLabel"),funded:balance>0,compact:compact).accessibilityElement(children:.contain).frame(maxWidth:.infinity).accessibilityIdentifier("walletCard")
                    if balance > 0{Button(w("verifyTransactions"),action:transactions).font(PiyaliBrand.productFont(14)).underline().foregroundStyle(link).frame(maxWidth:.infinity).padding(.top,8).accessibilityIdentifier("walletTransactions")}
                    else{Button(w(busy ? "loadingAddress":"deposit"),action:deposit).buttonStyle(WalletOutlineStyle(paper:paper,full:true)).disabled(selected.isEmpty || busy).frame(maxWidth:compact ? 256:nil).frame(maxWidth:.infinity).padding(.top,12).accessibilityIdentifier("walletDeposit")}
                } else {
                    VStack(spacing:12){
                        if let qr=Self.invoiceQR(invoice){Image(uiImage:qr).interpolation(.none).resizable().frame(width:compact ? 140:184,height:compact ? 140:184).accessibilityLabel("Lightning deposit invoice QR code").accessibilityIdentifier("walletInvoiceQR")}
                        HStack(spacing:12){Text(w("or")).font(PiyaliBrand.productFont(14));Button(action:copy){Label(w("copyAddress"),systemImage:"key").font(PiyaliBrand.productFont(14,600))}.buttonStyle(WalletOutlineStyle(paper:paper,small:true)).accessibilityIdentifier("walletCopyInvoice")}
                        VStack(spacing:0){OnboardingText(text:w("ps"),size:14,lineHeight:21).multilineTextAlignment(.center).foregroundStyle(muted.opacity(0.9));Link(destination:URL(string:"https://click.cash.app/ui6m/home2022")!){HStack(spacing:4){Image(systemName:"dollarsign.square.fill");Text("Cash App").underline()}.font(PiyaliBrand.productFont(14))}.foregroundStyle(link)}
                        Button(action:deposit){Label(w("generateNew"),systemImage:"qrcode")}.buttonStyle(WalletOutlineStyle(paper:paper)).disabled(selected.isEmpty || busy).padding(.top,8).accessibilityIdentifier("walletGenerateNew")
                    }.padding(.top,8).frame(maxWidth:.infinity)
                }
            }
        }.padding(transparent ? 0:12).background(transparent ? .clear:color("f6ecda","111827"),in:RoundedRectangle(cornerRadius:6)).foregroundStyle(text).buttonStyle(.plain).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).accessibilityElement(children:.contain).accessibilityIdentifier("walletPanel")
    }
    static func invoiceQR(_ invoice:String)->UIImage? {let filter=CIFilter.qrCodeGenerator();filter.message=Data(invoice.utf8);filter.correctionLevel="L";guard let output=filter.outputImage?.transformed(by:CGAffineTransform(scaleX:8,y:8)),let cg=CIContext().createCGImage(output,from:output.extent) else{return nil};return UIImage(cgImage:cg)}
}
struct WalletOutlineStyle:ButtonStyle {
    let paper:Bool
    var full=false
    var small=false
    func makeBody(configuration:Configuration)->some View{configuration.label.font(PiyaliBrand.productFont( small ? 14:16,600)).padding(.horizontal,small ? 12:24).frame(maxWidth:full ? .infinity:nil,minHeight:small ? 32:full ? 42:40).background(PiyaliBrand.unitColor(paper ? (configuration.isPressed ? "ecd5ac":"fff8ec"):"111827"),in:Capsule()).overlay{Capsule().stroke(paper ? PiyaliBrand.unitColor("d8bb91"):Color.white.opacity(0.24))}.opacity(configuration.isPressed ? 0.85:1)}
}
struct WalletIdentityCard:View {
    let balance:Int,label:String,funded:Bool
    var compact=false
    private var numberSize:CGFloat{compact ? 15.936:23.04}
    private var titleLeading:CGFloat{max(0,(compact ? 23.904:34.56)-(UIFont(name:funded ? "TimesNewRomanPSMT":"Avenir",size:numberSize)?.lineHeight ?? 27.5))}
    var body:some View {
        VStack(alignment:.leading,spacing:0){Text(compact ? WalletCopy.cardName.replacingOccurrences(of:" Wallet",with:"\nWallet"):WalletCopy.cardName).font(.custom(funded ? "TimesNewRomanPSMT":"Avenir",size:numberSize)).tracking(compact ? 1:2).lineSpacing(titleLeading).padding(.vertical,titleLeading/2).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading);Spacer();HStack(alignment:.bottom){Text(label+": ₿"+String(balance)).font(.custom("Avenir-Black",size:compact ? 11.52:15.36)).accessibilityIdentifier("walletBalance");Spacer();Text("BTC").font(.custom("Avenir-Black",size:compact ? 14.4:19.2)).foregroundStyle(funded ? .white:.black).padding(.horizontal,compact ? 14:24).frame(height:compact ? 28:48).background(PiyaliBrand.unitColor(funded ? "db80f4":"d0d0d0"),in:RoundedRectangle(cornerRadius:5))}}
            .padding(compact ? 12:20).frame(maxWidth:compact ? 256:400).frame(height:compact ? 168:250).foregroundStyle(funded ? .white:PiyaliBrand.unitColor("333333")).background{WalletCardGradient(funded:funded).allowsHitTesting(false)}.clipShape(RoundedRectangle(cornerRadius:16)).compositingGroup().shadow(color:.black.opacity(0.1),radius:4,y:4)
    }
}

private struct WalletCardGradient:View {
    let funded:Bool
    @State private var started=Date()
    var body:some View{GeometryReader{g in TimelineView(.animation(minimumInterval:1.0/30)){timeline in
        let phase=(1-cos(timeline.date.timeIntervalSince(started)*Double.pi/3))/2
        LinearGradient(colors:(funded ? ["ff6f91","d783ff","c471ed"]:["f0f0f0","d0d0d0","b0b0b0"]).map{PiyaliBrand.unitColor($0)},startPoint:.topLeading,endPoint:.bottomTrailing).frame(width:g.size.width*2,height:g.size.height*2).offset(x:-g.size.width*phase,y:-g.size.height/2)
    }}}
}
