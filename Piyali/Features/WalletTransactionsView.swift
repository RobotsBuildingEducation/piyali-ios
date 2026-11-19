import SwiftUI

struct WalletTransactionsView:View {
    let language:String
    var forcePaper=false
    let onClose:()->Void
    @StateObject private var model=WalletPublicTransactions()
    @Environment(\.colorScheme) private var scheme

    private var paper:Bool {forcePaper || scheme != .dark}
    private var direction:LayoutDirection {language == "ar" ? .rightToLeft:.leftToRight}
    private var surface:Color {c("fff9ed","0b1220")}
    private var muted:Color {c("806543","a3b4c9")}
    private var amount:Color {c("0f766e","81e6d9")}
    private var border:Color {paper ? c("dfc9a8","dfc9a8"):.white.opacity(0.08)}
    private var refreshing:Bool {model.loading && !model.rows.isEmpty}
    private func c(_ light:String,_ dark:String)->Color {PiyaliBrand.unitColor(paper ? light:dark)}
    private func t(_ key:String)->String {WalletCopy.transactions(language,key)}

    var body:some View {
        GeometryReader{g in
            ZStack(alignment:.trailing){
                c("4c3c28","000000").opacity(paper ? 0.18:0.48).ignoresSafeArea()
                    .onTapGesture(perform:onClose).accessibilityHidden(true)
                ZStack(alignment:.topTrailing){
                    VStack(alignment:.leading,spacing:0){
                        header
                        ScrollView{
                            bodyContent
                                .frame(maxWidth:.infinity).padding(.horizontal,24).padding(.bottom,24)
                        }
                    }.environment(\.layoutDirection,direction)

                    Button(action:onClose){
                        Image(systemName:"xmark").font(.system(size:13,weight:.medium))
                            .frame(width:44,height:44).contentShape(Rectangle())
                    }.accessibilityLabel(SettingsCopy.inline(language,"Close"))
                        .accessibilityIdentifier("walletTransactionsClose")
                        .padding(.trailing,10).padding(.top,10)
                }
                .frame(width:g.size.width < 768 ? g.size.width*0.9:384,height:g.size.height)
                .background {
                    surface.overlay(alignment:.leading){Rectangle().fill(border).frame(width:1)}
                        .ignoresSafeArea(edges:.vertical)
                }
            }
        }
        .foregroundStyle(c("362311","e5e7eb")).buttonStyle(.plain).environment(\.layoutDirection,.leftToRight)
        .task{await model.load()}.onDisappear{model.cancel()}
        .accessibilityElement(children:.contain).accessibilityIdentifier("walletTransactionsDrawer")
        .accessibilityAction(.escape){onClose()}
    }
    private var header:some View {
        HStack(spacing:8){
            OnboardingText(text:t("title"),size:18,weight:.semibold,lineHeight:27)
                .accessibilityAddTraits(.isHeader)
            Button{
                reload()
            }label:{
                Group{
                    if refreshing{PracticeAudioSpinner()}
                    else{Image(systemName:"arrow.clockwise").font(.system(size:13,weight:.semibold))}
                }.frame(width:32,height:32).contentShape(Rectangle())
            }.disabled(refreshing).accessibilityLabel(t("refresh"))
                .accessibilityValue(refreshing ? t("loading"):"")
                .accessibilityIdentifier("walletTransactionsRefresh")
        }
        .frame(maxWidth:.infinity,alignment:.leading)
        .padding(direction == .rightToLeft ? .trailing:.leading,24)
        .padding(direction == .rightToLeft ? .leading:.trailing,96)
        .padding(.top,16).padding(.bottom,12)
    }
    @ViewBuilder private var bodyContent:some View {
        if model.loading && model.rows.isEmpty{
            VStack(spacing:16){
                PracticeAudioSpinner(size:32).foregroundStyle(amount)
                OnboardingText(text:t("loading"),size:14,lineHeight:21)
                    .accessibilityIdentifier("walletTransactionsLoading")
            }.padding(.vertical,64).foregroundStyle(muted)
        }else if model.failed{
            VStack(alignment:.leading,spacing:16){
                OnboardingText(text:t("error"),size:14,lineHeight:21)
                    .foregroundStyle(muted).accessibilityIdentifier("walletTransactionsError")
                Button(action:reload){
                    Text(t("retry")).font(PiyaliBrand.productFont(14,600))
                        .frame(maxWidth:.infinity,minHeight:32).contentShape(Rectangle())
                        .overlay{EntryCornerShape(radius:6).stroke(border,lineWidth:1)}
                }.accessibilityIdentifier("walletTransactionsRetry")
            }.padding(.vertical,32)
        }else if model.rows.isEmpty{
            OnboardingText(text:t("empty"),size:14,lineHeight:21).foregroundStyle(muted)
                .multilineTextAlignment(.center).padding(.vertical,48)
                .accessibilityIdentifier("walletTransactionsEmpty")
        }else{
            LazyVStack(spacing:12){ForEach(model.rows){row in card(row)}}
        }
    }
    private func reload(){Task{await model.load()}}
    private func card(_ row:WalletPublicTransaction)->some View {
        VStack(alignment:.leading,spacing:12){
            HStack(alignment:.firstTextBaseline,spacing:12){
                OnboardingText(text:"₿"+row.amount.formatted(.number.locale(Locale(identifier:language))),size:14,weight:.bold,lineHeight:21)
                    .foregroundStyle(amount)
                Spacer(minLength:0)
                Text(Date(timeIntervalSince1970:Double(row.createdAt)),format:Date.FormatStyle(calendar:CalendarDay.gregorian()).locale(Locale(identifier:language)).month(.abbreviated).day().hour().minute())
                    .font(PiyaliBrand.productFont(10)).foregroundStyle(muted).fixedSize()
            }.padding(.bottom,4)
            person("from",row.sender)
            person("to",row.recipient)
            OnboardingText(text:"“"+row.note+"”",size:12,lineHeight:18)
                .padding(.horizontal,12).padding(.vertical,8)
                .frame(maxWidth:.infinity,alignment:.leading)
                .background(.white.opacity(paper ? 0.45:0.1),in:RoundedRectangle(cornerRadius:10)).padding(.top,4)
        }.padding(17)
            .background(paper ? c("f6ecda","151c29"):.white.opacity(0.04),in:RoundedRectangle(cornerRadius:14))
            .overlay{RoundedRectangle(cornerRadius:14).strokeBorder(border,lineWidth:1)}
            .accessibilityElement(children:.contain).accessibilityIdentifier("walletPublicReceipt")
    }
    private func person(_ key:String,_ value:String)->some View {
        HStack(spacing:12){
            Text(t(key).uppercased(with:Locale(identifier:language))).font(PiyaliBrand.productFont(10,700))
                .tracking(0.8).frame(width:40,alignment:.leading).foregroundStyle(muted)
            Text(model.name(value)).font(PiyaliBrand.productFont(14,600)).lineLimit(1)
            Spacer(minLength:0)
        }
    }
}
