import SwiftUI

struct DailyActivityView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let onBack:()->Void
    let onAchievements:()->Void
    @State private var year=Calendar.current.component(.year,from:Date())
    @State private var history:JSONValue = .object([:])
    @State private var selected:String?
    @State private var error:String?
    private var brand:PiyaliBrand { PiyaliBrand(dark:scheme == .dark) }
    private var dates:[Date] {
        let calendar=Calendar.current
        guard let start=calendar.date(from:DateComponents(year:year,month:1,day:1)),let next=calendar.date(byAdding:.year,value:1,to:start) else { return [] }
        return (0..<calendar.dateComponents([.day],from:start,to:next).day!).compactMap { calendar.date(byAdding:.day,value:$0,to:start) }
    }
    private func amount(_ day:String)->Int { day == CalendarDay.key(Date()) ? max(Int(history["days"][day].number),app.learner.dailyXP) : Int(history["days"][day].number) }
    var body:some View {
        VStack(spacing:20) {
            HStack { Button { year-=1 } label:{ Image(systemName:"chevron.left").frame(width:44,height:44) };Spacer();Text(String(year)).font(PiyaliBrand.font(18,700));Spacer();Button { year+=1 } label:{ Image(systemName:"chevron.right").frame(width:44,height:44) }.disabled(year >= Calendar.current.component(.year,from:Date())) }
            ScrollView(.horizontal,showsIndicators:false) { LazyHGrid(rows:Array(repeating:GridItem(.fixed(8),spacing:3),count:7),spacing:3) { ForEach(dates,id:\.self) { date in let day=CalendarDay.key(date);Button { selected=day } label:{ RoundedRectangle(cornerRadius:2).fill(amount(day) >= app.learner.dailyGoal ? PiyaliBrand.teal : amount(day) > 0 ? PiyaliBrand.teal.opacity(0.35) : brand.border.opacity(date > Date() ? 0.15 : 0.4)).frame(width:8,height:8) }.accessibilityLabel(day+", \(amount(day)) XP") } }.padding(.vertical,4) }
            if let selected { Text(selected+": \(amount(selected)) XP").font(PiyaliBrand.font(12)).foregroundStyle(brand.secondary) }
            if let error { Text(error).font(PiyaliBrand.font(12)).foregroundStyle(brand.muted) }
            HStack(spacing:12) { Button("Companion",action:onBack);Button("Achievements",action:onAchievements) }.font(PiyaliBrand.font(13,600)).buttonStyle(.bordered).tint(PiyaliBrand.teal)
        }.padding(18).background(brand.surface.opacity(0.6),in:RoundedRectangle(cornerRadius:20)).overlay { RoundedRectangle(cornerRadius:20).stroke(brand.border) }.task(id:app.identity.npub+":"+String(year)) {
            let account=app.identity.npub;error=nil
            do { let loaded=try await FirebaseService.shared.activityHistory(npub:account,year:year);guard account == app.identity.npub else { return };history=loaded }
            catch { self.error="Saved history will be available when you reconnect." }
        }
    }
}
