import SwiftUI

struct WalletTransactionsView:View {
    let language:String,onClose:()->Void
    @StateObject private var model=WalletPublicTransactions()
    @Environment(\.colorScheme) private var scheme
    private func c(_ light:String,_ dark:String)->Color{PiyaliBrand.unitColor(scheme == .dark ? dark:light)}
    private func t(_ key:String)->String{WalletCopy.transactions(language,key)}
    var body:some View {
        GeometryReader{g in ZStack(alignment:.trailing){c("4c3c28","000000").opacity(scheme == .dark ? 0.6:0.18).ignoresSafeArea().onTapGesture(perform:onClose)
            VStack(alignment:.leading,spacing:0){HStack(spacing:12){Text(t("title")).font(PiyaliBrand.productFont(18,600));Button{Task{await model.load()}}label:{Image(systemName:"arrow.clockwise").frame(width:24,height:24)}.accessibilityLabel(t("refresh")).disabled(model.loading);Spacer();Button(action:onClose){Image(systemName:"xmark").frame(width:32,height:32)}.accessibilityLabel(SettingsCopy.inline(language,"Close")).accessibilityIdentifier("walletTransactionsClose")}.padding(.horizontal,24).padding(.top,20).padding(.bottom,16)
                ScrollView{VStack(spacing:12){if model.loading{VStack(spacing:16){ProgressView();Text(t("loading"))}.padding(.vertical,64).frame(maxWidth:.infinity)}else if model.failed{VStack(spacing:12){Text(t("error"));Button(t("retry")){Task{await model.load()}}.buttonStyle(WalletOutlineStyle(paper:scheme != .dark,small:true))}.padding(.vertical,32)}else if model.rows.isEmpty{Text(t("empty")).padding(.vertical,48).frame(maxWidth:.infinity).accessibilityIdentifier("walletTransactionsEmpty")}else{ForEach(model.rows){row in card(row)}}}.font(PiyaliBrand.productFont(14)).padding(.horizontal,24).padding(.bottom,32)}
            }.environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).frame(width:g.size.width*0.9,height:g.size.height).background(c("fff9ed","0b1220"))
        }}.foregroundStyle(c("362311","f1f5f9")).buttonStyle(.plain).environment(\.layoutDirection,.leftToRight).task{await model.load()}.onDisappear{model.cancel()}.accessibilityElement(children:.contain).accessibilityIdentifier("walletTransactionsDrawer")
    }
    private func card(_ row:WalletPublicTransaction)->some View{VStack(alignment:.leading,spacing:12){HStack{Text("₿"+row.amount.formatted(.number.locale(Locale(identifier:language)))).font(PiyaliBrand.productFont(14,700)).foregroundStyle(c("0f766e","81e6d9"));Spacer();Text(Date(timeIntervalSince1970:Double(row.createdAt)),format:Date.FormatStyle(calendar:CalendarDay.gregorian()).locale(Locale(identifier:language)).month(.abbreviated).day().hour().minute()).font(PiyaliBrand.productFont(10)).foregroundStyle(c("806543","a0aec0"))}.padding(.bottom,4);person("from",row.sender);person("to",row.recipient);Text("“"+row.note+"”").font(PiyaliBrand.productFont(12)).padding(.horizontal,12).padding(.vertical,8).frame(maxWidth:.infinity,alignment:.leading).background(Color.white.opacity(scheme == .dark ? 0.1:0.45),in:RoundedRectangle(cornerRadius:10)).padding(.top,4)}.padding(16).background(c("f6ecda","151c29"),in:RoundedRectangle(cornerRadius:14)).overlay{RoundedRectangle(cornerRadius:14).stroke(c("dfc9a8","4a5568"))}}
    private func person(_ key:String,_ value:String)->some View{HStack(spacing:12){Text(t(key).uppercased()).font(PiyaliBrand.productFont(10,700)).tracking(0.8).frame(width:40,alignment:.leading).foregroundStyle(c("806543","a0aec0"));Text(model.name(value)).font(PiyaliBrand.productFont(14,600)).lineLimit(1);Spacer(minLength:0)}}
}
