import SwiftUI

struct DailyGoalManagerView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let onClose:()->Void
    @State private var draft="100"
    private var brand:PiyaliBrand{PiyaliBrand(dark:scheme == .dark)}
    private func text(_ key:String)->String{EntryCopy.ui(app.learner.support,"daily_goal_"+key)}
    var body:some View {
        SessionToolFrame(title:text("title"),icon:"FaCalendarAlt",coloredHeader:true,onClose:onClose){
            VStack(alignment:.leading,spacing:20){
                DailyGoalCompanionSetup()
                SessionToolFlow{ForEach(SessionToolPolicy.goalPresets,id:\.self){value in Button("\(value) XP"){draft=String(value)}.buttonStyle(SessionToolButtonStyle(selected:SessionToolPolicy.goal(draft)==value,small:true)).accessibilityIdentifier("goalPreset-\(value)")}}
                VStack(alignment:.leading,spacing:8){
                    OnboardingText(text:text("input_label"),size:16,weight:.medium,lineHeight:24)
                    TextField(text("input_label"),text:$draft).multilineTextAlignment(app.learner.support == "ar" ? .trailing:.leading).environment(\.layoutDirection,.leftToRight).keyboardType(.numberPad).font(PiyaliBrand.productFont(16)).padding(.horizontal,16).frame(width:180,height:40).background(brand.surface,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(scheme == .dark ? PiyaliBrand.unitColor("cbd5e1"):PiyaliBrand.unitColor("604d38").opacity(0.24))}.accessibilityIdentifier("dailyGoalDraft")
                    OnboardingText(text:text("level_explainer"),size:12,lineHeight:18).foregroundStyle(scheme == .dark ? brand.text.opacity(0.7):brand.muted)
                }
                DailyGoalYearHeatmap()
            }
        }footer:{HStack(spacing:12){Button(text("close"),action:onClose).buttonStyle(SessionToolButtonStyle(secondary:true)).accessibilityIdentifier("dailyGoalClose");Button(text("save")){app.learner.dailyGoal=SessionToolPolicy.goal(draft);app.persist();onClose()}.buttonStyle(SessionToolButtonStyle(primary:true)).accessibilityIdentifier("dailyGoalSave")}}
        .onAppear{draft=String(app.learner.dailyGoal)}
    }
}
private struct DailyGoalCompanionSetup:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @State private var customize=false
    private var brand:PiyaliBrand{PiyaliBrand(dark:scheme == .dark)}
    private var copy:JSONValue{FocusCopy.data(app.learner.support)["pet"]}
    private var stage:JSONValue{FocusCopy.appearance(app.learner.companionHealth,dark:scheme == .dark)}
    private var badgeColors:(Color,Color){
        if scheme != .dark{return (FocusCopy.color(stage["badgeBg"].string),FocusCopy.color(stage["badgeColor"].string))}
        let colors=["green":["c6f6d5","22543d"],"teal":["b2f5ea","234e52"],"yellow":["fefcbf","744210"],"orange":["feebc8","7b341e"],"red":["fed7d7","822727"],"gray":["edf2f7","1a202c"]][stage["colorScheme"].string] ?? ["edf2f7","1a202c"]
        return (PiyaliBrand.unitColor(colors[0]),PiyaliBrand.unitColor(colors[1]))
    }
    var body:some View {
        VStack(spacing:12){
            HStack(alignment:.top,spacing:12){
                VStack(spacing:6){CompanionArtwork(type:app.learner.effectiveCompanionType,health:app.learner.companionHealth).frame(width:96,height:96).background(FocusCopy.background(stage["background"].string),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(brand.border)};Text(copy[FocusCopy.stage(app.learner.companionHealth)].string.uppercased()).font(PiyaliBrand.productFont(10,700)).padding(.horizontal,8).padding(.vertical,2).background(badgeColors.0,in:RoundedRectangle(cornerRadius:6)).foregroundStyle(badgeColors.1)}
                VStack(alignment:.leading,spacing:8){
                    HStack(spacing:4){Button{customize=true}label:{CompanionEditorIcon(name:"TbEdit",size:14).frame(width:20,height:20).contentShape(RoundedRectangle(cornerRadius:6))}.accessibilityLabel(FocusCopy.data(app.learner.support)["customize"]["edit"].string).accessibilityIdentifier("goalCompanionEdit");Text(app.learner.companionName.isEmpty ? copy["title"].string:app.learner.companionName).font(PiyaliBrand.productFont(14,700))}.fixedSize(horizontal:false,vertical:true)
                    Text(copy["subtitle"].string).font(PiyaliBrand.productFont(10)).fixedSize(horizontal:false,vertical:true)
                    HStack{SessionIcon(name:"FiHeart",size:14).foregroundStyle(PiyaliBrand.unitColor("ce7a8c"));Text(copy["health"].string).font(PiyaliBrand.productFont(12,600));Spacer(minLength:0);Text("\(app.learner.companionHealth)%").font(PiyaliBrand.productFont(14,700))}
                    FocusWaveBar(percent:Double(app.learner.companionHealth),height:14,background:.white.opacity(0.12),border:brand.border)
                }.frame(maxWidth:.infinity,alignment:.leading)
            }
            HStack(spacing:8){preview("reward",icon:"FiTrendingUp",amount:"+15%",color:scheme == .dark ? "9ae6b4":"48765f");preview("penalty",icon:"FiTrendingDown",amount:"-10%",color:scheme == .dark ? "fbd38d":"a06a3b")}
        }.padding(12).background(FocusCopy.background(stage["background"].string),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(scheme == .dark ? .clear:brand.border)}
            .fullScreenCover(isPresented:$customize){FocusCompanionCustomizeView(host:.goal).presentationBackground(.clear)}
    }
    private func preview(_ key:String,icon:String,amount:String,color:String)->some View {VStack(spacing:4){HStack(alignment:.top,spacing:6){SessionIcon(name:icon,size:14).foregroundStyle(PiyaliBrand.unitColor(color));Text(copy[key].string).font(PiyaliBrand.productFont(12,600)).multilineTextAlignment(.center)};Text(amount).font(PiyaliBrand.productFont(24,700)).foregroundStyle(PiyaliBrand.unitColor(color))}.padding(10).frame(maxWidth:.infinity,maxHeight:.infinity).background(scheme == .dark ? .clear:brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(scheme == .dark ? .clear:brand.border)}}
}
struct DailyGoalYearHeatmap:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @State private var history:JSONValue = .object([:])
    private var brand:PiyaliBrand{PiyaliBrand(dark:scheme == .dark)}
    private var now:Date{Date()}
    private var year:Int{calendar.component(.year,from:now)}
    private var key:String{"piyali.xpHistory."+app.identity.npub+".\(year)"}
    private func text(_ key:String)->String{EntryCopy.ui(app.learner.support,"daily_goal_activity_"+key)}
    private var calendar:Calendar{var c=Calendar(identifier:.gregorian);c.timeZone = .current;return c}
    private var start:Date{calendar.date(from:DateComponents(year:year,month:1,day:1))!}
    private var padding:Int{calendar.component(.weekday,from:start)-1}
    private var days:Int{calendar.range(of:.day,in:.year,for:start)!.count}
    private var weeks:Int{Int(ceil(Double(padding+days)/7))}
    private var formatter:DateFormatter{let f=DateFormatter();f.locale=Locale(identifier:app.learner.support);f.setLocalizedDateFormatFromTemplate("MMM");return f}
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            HStack{OnboardingText(text:text("title").uppercased(),size:12,weight:.bold,lineHeight:18).tracking(0.96);Spacer();OnboardingText(text:text("subtitle"),size:12,lineHeight:18).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("879bb4"):brand.muted)}
            ScrollView(.horizontal,showsIndicators:false){HStack(alignment:.top,spacing:2){ForEach(0..<weeks,id:\.self){week in VStack(spacing:0){Text(month(week).uppercased()).fixedSize(horizontal:true,vertical:false).font(PiyaliBrand.productFont(8)).foregroundStyle(PiyaliBrand.unitColor("6b7280")).frame(width:11,height:12,alignment:.leading);ForEach(0..<7,id:\.self){day in cell(week*7+day-padding)}}}}.padding(.bottom,8)}
            SessionToolFlow(spacing:16){legend("empty",color:scheme == .dark ? .white.opacity(0.08):brand.secondary.opacity(0.075));legend("some",color:scheme == .dark ? PiyaliBrand.unitColor("2dd4bf").opacity(0.42):PiyaliBrand.unitColor("75c6a7").opacity(0.34));legend("goal",color:PiyaliBrand.unitColor(scheme == .dark ? "2dd4bf":"6fd0b5"))}
        }.padding(16).background(scheme == .dark ? PiyaliBrand.unitColor("111827"):PiyaliBrand.unitColor("efe4d5"),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}.task(id:key){
            let scope=key,account=app.identity.npub
            history=UserDefaults.standard.data(forKey:scope).flatMap{try? JSONDecoder().decode(JSONValue.self,from:$0)} ?? .object([:])
            do{let result=try await FirebaseService.shared.activityHistory(npub:account,year:year);try Task.checkCancellation();guard scope==key,account==app.identity.npub else{return};history=result;if let data=try? JSONEncoder().encode(result){UserDefaults.standard.set(data,forKey:scope)}}catch{}
        }.accessibilityIdentifier("dailyGoalHeatmap")
    }
    private func month(_ week:Int)->String{for i in 0..<7{let offset=week*7+i-padding;if (0..<days).contains(offset),let date=calendar.date(byAdding:.day,value:offset,to:start),calendar.component(.day,from:date)==1{return formatter.string(from:date)}};return ""}
    @ViewBuilder private func cell(_ offset:Int)->some View {
        if (0..<days).contains(offset),let date=calendar.date(byAdding:.day,value:offset,to:start){let day=CalendarDay.key(date,calendar:calendar),today=day==CalendarDay.key(now,calendar:calendar),xp=today ? max(app.learner.dailyXP,Int(history["days"][day].number)):Int(history["days"][day].number),goal=history["goalDays"].array.contains(.string(day)) || (today && app.learner.dailyXP>=app.learner.dailyGoal),future=date>now
            RoundedRectangle(cornerRadius:3).fill(goal ? AnyShapeStyle(LinearGradient(colors:[PiyaliBrand.unitColor(scheme == .dark ? "2dd4bf":"6fd0b5"),PiyaliBrand.unitColor(scheme == .dark ? "38bdf8":"8bc9de")],startPoint:.topLeading,endPoint:.bottomTrailing)):AnyShapeStyle(xp>0 ? PiyaliBrand.unitColor(scheme == .dark ? "2dd4bf":"75c6a7").opacity(scheme == .dark ? 0.42:0.34):scheme == .dark ? Color.white.opacity(future ? 0.03:0.08):brand.secondary.opacity(future ? 0.035:0.075))).overlay{RoundedRectangle(cornerRadius:3).stroke(cellBorder(goal:goal,xp:xp,today:today),lineWidth:1)}.frame(width:11,height:11).padding(.top,2).opacity(future ? scheme == .dark ? 0.28:0.48:1).scaleEffect(today ? 1.04:1).accessibilityLabel(day+" - \(xp) XP")
        }else{Color.clear.frame(width:11,height:13).accessibilityHidden(true)}
    }
    private func cellBorder(goal:Bool,xp:Int,today:Bool)->Color{
        if scheme == .dark{return goal ? PiyaliBrand.unitColor("a7f3d0").opacity(0.55):xp>0 ? PiyaliBrand.unitColor("5eead4").opacity(0.28):.white.opacity(today ? 0.45:0.08)}
        return PiyaliBrand.unitColor(goal || xp>0 ? "4f8b78":"5b4b3a").opacity(goal ? 0.28:xp>0 ? 0.18:today ? 0.22:0.08)
    }
    private func legend(_ key:String,color:Color)->some View{HStack(spacing:8){RoundedRectangle(cornerRadius:3).fill(color).frame(width:10,height:10);OnboardingText(text:text(key),size:12,lineHeight:18).foregroundStyle(brand.muted)}}
}
struct SessionTimeUpView:View {
    let minutes:Int,language:String,onClose:()->Void,onRestart:()->Void
    private func text(_ key:String)->String{EntryCopy.ui(language,"timer_times_up_"+key)}
    var body:some View {
        ZStack{Color.black.opacity(0.82).ignoresSafeArea().onTapGesture(perform:onClose)
            VStack(spacing:0){Text(text("title")).font(PiyaliBrand.productFont(24,700)).padding(28)
                VStack(spacing:20){BrandArtwork(name:"session-timer-character.webp").frame(width:112,height:112).padding(.horizontal,24).padding(.vertical,16).background(.white.opacity(0.18),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(.white.opacity(0.3))};VStack(spacing:8){Text(text("subtitle")).font(PiyaliBrand.productFont(18,600));Text(text("duration").replacingOccurrences(of:"{minutes}",with:String(minutes))).font(PiyaliBrand.productFont(16)).opacity(0.9)}}.multilineTextAlignment(.center).padding(.horizontal,28).padding(.vertical,32)
                HStack(spacing:12){Button(text("close"),action:onClose).buttonStyle(.plain).accessibilityIdentifier("timerTimeUpClose");Button(text("restart"),action:onRestart).padding(.horizontal,16).frame(minHeight:40).foregroundStyle(PiyaliBrand.unitColor("6b46c1")).background(.white,in:EntryCornerShape(radius:20)).accessibilityIdentifier("timerTimeUpRestart")}.font(PiyaliBrand.productFont(16,600)).padding(.horizontal,28).padding(.top,16).padding(.bottom,28)
            }.frame(maxWidth:400).foregroundStyle(.white).background(LinearGradient(colors:[PiyaliBrand.unitColor("c084fc"),PiyaliBrand.unitColor("22d3ee")],startPoint:.topLeading,endPoint:.bottomTrailing),in:EntryCornerShape(radius:48)).overlay(alignment:.topTrailing){Button(action:onClose){Image(systemName:"xmark").font(.system(size:12,weight:.bold)).foregroundStyle(.white).frame(width:32,height:32)}.padding(20).accessibilityLabel(text("close")).accessibilityIdentifier("timerTimeUpX")}.padding(.horizontal,20)
        }.ignoresSafeArea(.container).accessibilityElement(children:.contain)
    }
}
