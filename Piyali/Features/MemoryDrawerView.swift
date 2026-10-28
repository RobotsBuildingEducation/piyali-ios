import SwiftUI

struct MemoryDrawerView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    let onClose:()->Void
    var initialTab="repairs"
    @State private var tab="repairs"
    @State private var expandedLevel:String?
    @State private var expanded:Set<UUID>=[]
    @State private var editingLegacy:Note?
    @State private var drag:CGFloat=0
    @StateObject private var model=MemoryDrawerController()
    @StateObject private var narration=RealtimeNarrationService()
    @State private var playing:UUID?
    private var lang:String{app.learner.support}
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var copy:JSONValue{MemoryUI.copy(lang)}
    private var tabs:[String]{hasGoal ? ["repairs","goals","notes","journey"]:["repairs","notes","journey"]}
    private var hasGoal:Bool {!app.learner.goalBucket["activeGoal"]["id"].string.isEmpty && !app.learner.goalBucket["activeGoal"]["text"].string.isEmpty}
    private var notes:[Note]{app.learner.notes.filter{$0.study?["targetLang"].string == app.learner.target}}
    private var legacy:[Note]{app.learner.notes.filter{$0.study == nil}}
    private var scope:String{[app.identity.npub,app.learner.target,lang,CalendarDay.key(Date())].joined(separator:":")}
    private func t(_ key:String)->String {MemoryUI.journey(lang,key)}
    var body:some View {
        GeometryReader{g in ZStack(alignment:.bottom){
            Color.clear.contentShape(Rectangle()).onTapGesture(perform:onClose)
            VStack(spacing:0){
                Capsule().fill(scheme == .dark ? .white.opacity(0.24):PiyaliBrand.unitColor("604d38").opacity(0.3)).frame(width:52,height:5).padding(.top,12).padding(.bottom,8).frame(maxWidth:.infinity).contentShape(Rectangle()).gesture(DragGesture().onChanged{drag=max(0,$0.translation.height)}.onEnded{if $0.translation.height>90{onClose()}else{drag=0}})
                HStack{OnboardingText(text:copy["drawer"]["title"].string,size:20,weight:.semibold,lineHeight:30);Spacer();if tab == "notes",!notes.isEmpty{Button(copy["labels"]["clearAllLabel"].string){app.learner.notes.removeAll{$0.study?["targetLang"].string == app.learner.target};app.persist()}.font(PiyaliBrand.productFont(12,600)).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "e5e7eb":"b45309")).accessibilityIdentifier("memoryClearAll")}}.padding(.horizontal,32).padding(.vertical,28).overlay(alignment:.bottom){brand.border.frame(height:1)}
                VStack(spacing:0){
                    HStack(spacing:0){ForEach(tabs,id:\.self){key in Button{narration.stopAll();playing=nil;tab=key}label:{VStack(spacing:0){OnboardingText(text:t(key),size:14,weight:.semibold,lineHeight:21).fixedSize(horizontal:true,vertical:true).foregroundStyle(tab == key ? brand.text:brand.muted).padding(.top,4).padding(.bottom,12);Capsule().fill(LinearGradient(colors:[PiyaliBrand.unitColor("76e4f7"),PiyaliBrand.unitColor("38b2ac")],startPoint:.leading,endPoint:.trailing)).frame(height:3).opacity(tab == key ? 1:0)}}.buttonStyle(.plain).fixedSize(horizontal:true,vertical:true).accessibilityIdentifier("memoryTab-"+key).accessibilityAddTraits(tab == key ? .isSelected:[]) ;if key != tabs.last{Spacer(minLength:16)}}}.padding(.horizontal,16).padding(.top,12).padding(.bottom,8)
                    ScrollView{VStack(alignment:.leading,spacing:0){
                        switch tab{case "goals":goals;case "notes":savedNotes;case "journey":VoiceJourneyView(embedded:true);default:repairs}
                    }.frame(maxWidth:720,alignment:.leading).frame(maxWidth:.infinity).padding(.horizontal,16).padding(.top,6).padding(.bottom,32)}.scrollIndicators(.hidden)
                }.padding(.horizontal,28)
            }.frame(height:g.size.height*0.9).frame(maxWidth:.infinity).foregroundStyle(brand.text).background{MemoryDrawerShape(radius:48).fill(scheme == .dark ? PiyaliBrand.unitColor("0b1220"):PiyaliBrand.unitColor("fffdf9")).shadow(color:.black.opacity(scheme == .dark ? 0:0.12),radius:26,y:-8)}.overlay{MemoryDrawerShape(radius:48).stroke(PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.42:0.3),lineWidth:3).padding(1.5).padding(.bottom,-3).allowsHitTesting(false)}.overlay(alignment:.top){HStack{Spacer();Button{narration.stopAll();onClose()}label:{MemoryIcon(name:"close",size:20).frame(width:32,height:32)}.buttonStyle(.plain).padding(.top,16).padding(.trailing,24).accessibilityLabel(EntryCopy.text(lang,"close")).accessibilityIdentifier("productPanelClose")}.environment(\.layoutDirection,.leftToRight)}.offset(y:drag)
        }.frame(width:g.size.width,height:g.size.height)}.ignoresSafeArea(.container).environment(\.layoutDirection,lang == "ar" ? .rightToLeft:.leftToRight).buttonStyle(.plain).accessibilityElement(children:.contain).accessibilityIdentifier("memoryDrawer")
            .onAppear{tab=tabs.contains(initialTab) ? initialTab:"repairs"}
            .task(id:scope){model.refresh(app)}
            .onChange(of:app.learner.companionMemory){_,_ in model.refresh(app)}
            .onChange(of:hasGoal){_,value in if !value,tab == "goals"{tab="repairs"}}
            .sheet(item:$editingLegacy){note in NavigationStack{NoteEditor(note:note).toolbar{ToolbarItem(placement:.confirmationAction){Button("Done"){editingLegacy=nil}}}}}
            .onDisappear{model.cancel();narration.stopAll()}
    }
    private var repairs:some View {
        let all=MemoryUI.notes(app.learner),today=CalendarDay.key(Date()),yesterday=CalendarDay.shift(today,by:-1)
        return VStack(alignment:.leading,spacing:0){
            OnboardingText(text:copy["drawer"]["subtitle"].string,size:12,lineHeight:18).foregroundStyle(brand.secondary).padding(.bottom,12)
            if !model.summary.isEmpty{OnboardingText(text:model.summary,size:14,lineHeight:23.8).padding(.bottom,16).accessibilityIdentifier("memoryDigest")}
            if all.isEmpty{empty(copy["drawer"]["empty"].string,glass:true)}
            else{VStack(alignment:.leading,spacing:16){ForEach([today,yesterday],id:\.self){day in let group=all.filter{$0.text("createdDayKey") == day};if !group.isEmpty{VStack(alignment:.leading,spacing:6){Text(copy["drawer"][day == today ? "todayHeading":"yesterdayHeading"].string).font(PiyaliBrand.productFont(10,700)).tracking(0.8).textCase(.uppercase).foregroundStyle(brand.muted);VStack(spacing:8){ForEach(group){note in MemoryRepairCard(note:note,language:lang,yesterday:day == yesterday)}}}}}}
            }
        }.padding(.bottom,all.isEmpty ? 12:20)
    }
    private var goals:some View {
        let bucket=app.learner.goalBucket,goal=bucket["activeGoal"],summary=bucket["goalProgress"],bp=bucket["dailyGoal"]["blueprint"],today=bp["goalId"] == goal["id"] && bp["dayKey"].string == CalendarDay.key(Date()) ? bp:.null,sections=["demonstrated","openCapabilities","usefulLanguage"]
        return VStack(alignment:.leading,spacing:20){
            VStack(alignment:.leading,spacing:8){OnboardingText(text:t("currentGoal"),size:12,lineHeight:18).foregroundStyle(brand.muted);OnboardingText(text:goal["text"].string,size:18,weight:.semibold,lineHeight:27)}.memoryCard(padding:20,background:MemoryPaint.surface(scheme),border:brand.border)
            OnboardingText(text:t("goalIntro"),size:14,lineHeight:21).foregroundStyle(brand.secondary)
            if !sections.contains(where:{!summary[$0].array.isEmpty}){OnboardingText(text:t("goalEmpty"),size:14,lineHeight:21).foregroundStyle(brand.muted)}
            ForEach(sections,id:\.self){section in if !summary[section].array.isEmpty{VStack(alignment:.leading,spacing:8){OnboardingText(text:t(section),size:14,weight:.semibold,lineHeight:21);ForEach(Array(summary[section].array.enumerated()),id:\.offset){_,entry in VStack(alignment:.leading,spacing:4){OnboardingText(text:entry.string.isEmpty ? entry["target"].string:entry.string,size:14,lineHeight:21);if !entry["example"].string.isEmpty{OnboardingText(text:entry["example"].string,size:14,lineHeight:21).foregroundStyle(brand.secondary)}}.memoryCard(padding:12,background:.clear,border:brand.border,radius:12)}}}}
            if goal["status"].string == "active",today != .null || !summary["nextGoalGuidance"]["target"].string.isEmpty {VStack(alignment:.leading,spacing:8){OnboardingText(text:t(today == .null ? "nextPractice":"todayAction"),size:14,weight:.semibold,lineHeight:21);OnboardingText(text:today == .null ? summary["nextGoalGuidance"]["target"].string:today["objective"].string,size:14,lineHeight:21);if !today["rationale"].string.isEmpty{OnboardingText(text:today["rationale"].string,size:14,lineHeight:21).foregroundStyle(brand.secondary)}}.memoryCard(padding:16,background:MemoryPaint.surface(scheme),border:brand.border,radius:12)}
        }.accessibilityElement(children:.contain).accessibilityIdentifier("memoryGoals")
    }
    private var savedNotes:some View {
        VStack(alignment:.leading,spacing:0){
            if notes.isEmpty{empty(copy["labels"]["noNotesLabel"].string,glass:false)}else{ForEach(["A1","A2","B1","B2","C1","C2"],id:\.self){level in let group=notes.filter{note in let value=note.study?["cefrLevel"].string ?? "A1";return (["A1","A2","B1","B2","C1","C2"].contains(value) ? value:"A1") == level},open=expandedLevel == level
                VStack(spacing:0){Button{expandedLevel=open ? nil:level}label:{HStack(spacing:12){OnboardingText(text:level,size:14,weight:.bold,lineHeight:21).foregroundStyle(FocusCopy.color(copy["textColors"][level].string == "white" ? "#ffffff":copy["textColors"][level].string)).padding(.horizontal,12).padding(.vertical,4).background(FocusCopy.color(copy["colors"][level].string),in:RoundedRectangle(cornerRadius:6));Text(group.isEmpty ? copy["labels"]["noNotesLabel"].string:MemoryUI.copy(lang,count:group.count)["labels"]["count"].string).font(PiyaliBrand.productFont(14,500)).foregroundStyle(group.isEmpty ? brand.muted:brand.text);Spacer();if !group.isEmpty{Image(systemName:open ? "chevron.up":"chevron.down").font(.system(size:14)).foregroundStyle(brand.secondary)}}.padding(.horizontal,16).padding(.vertical,13).background(noteSection(open:open,empty:group.isEmpty),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(scheme == .dark ? .clear:brand.border)}}.buttonStyle(MemoryLevelButtonStyle()).disabled(group.isEmpty).opacity(group.isEmpty ? 0.4:1).accessibilityIdentifier("memoryLevel-"+level).accessibilityValue(open ? "Expanded":"Collapsed")
                    if open{VStack(spacing:8){ForEach(group){note in noteRow(note)}}.padding(.horizontal,8).padding(.top,8).padding(.bottom,16).background(scheme == .dark ? .white.opacity(0.04):PiyaliBrand.unitColor("f7f0e4"))}
                }.padding(.bottom,12)
            }}
            if !legacy.isEmpty{DisclosureGroup("Saved on this iPhone"){ForEach(legacy){note in Button{editingLegacy=note}label:{VStack(alignment:.leading,spacing:4){Text(note.title).font(PiyaliBrand.productFont(14,600));Text(note.body).font(PiyaliBrand.productFont(12)).lineLimit(3)}}}}.padding(.top,16)}
        }.accessibilityElement(children:.contain).accessibilityIdentifier("memoryNotes")
    }
    private func noteSection(open:Bool,empty:Bool)->Color {scheme == .dark ? .white.opacity(open ? 0.08:empty ? 0.04:0.06):PiyaliBrand.unitColor(open ? "ebe0d0":empty ? "f7f0e4":"fdf9f2")}
    private func noteRow(_ note:Note)->some View {
        let meta=note.study ?? .null,open=expanded.contains(note.id),date=note.createdAt ?? Date(timeIntervalSince1970:meta["createdAt"].number/1000),label=copy["modules"][meta["moduleType"].string].string,locale=Locale(identifier:lang)
        return VStack(alignment:.leading,spacing:0){
            Button{if open{expanded.remove(note.id)}else{expanded.insert(note.id)}}label:{HStack(spacing:8){VStack(alignment:.leading,spacing:4){Text("\""+meta["example"].string+"\"").font(PiyaliBrand.productFont(14,500)).italic().lineLimit(2).frame(maxWidth:.infinity,alignment:.leading);HStack(spacing:8){Text(label.isEmpty ? meta["moduleType"].string:label).font(PiyaliBrand.productFont(10,700)).padding(.horizontal,4).background(scheme == .dark ? .gray.opacity(0.18):PiyaliBrand.unitColor("433527"),in:RoundedRectangle(cornerRadius:2)).foregroundStyle(scheme == .dark ? brand.text:PiyaliBrand.unitColor("fff8ef"));Text(meta["wasCorrect"].boolean ? "✓":"✖").font(PiyaliBrand.productFont(9,700)).padding(.horizontal,6).foregroundStyle(.white).background(PiyaliBrand.unitColor(meta["wasCorrect"].boolean ? "38a169":"e53e3e"),in:RoundedRectangle(cornerRadius:2));Text(date.formatted(Date.FormatStyle(calendar:CalendarDay.gregorian()).month(.abbreviated).day().locale(locale))+" · "+date.formatted(Date.FormatStyle(calendar:CalendarDay.gregorian()).hour(.twoDigits(amPM:.omitted)).minute(.twoDigits).locale(locale))).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.muted)}};Image(systemName:open ? "chevron.up":"chevron.down").font(.system(size:14)).foregroundStyle(brand.secondary)}.padding(.horizontal,16).padding(.vertical,12)}.accessibilityIdentifier("memoryNote-"+note.id.uuidString)
            if open{VStack(alignment:.leading,spacing:8){OnboardingText(text:meta["summary"].string,size:14,lineHeight:22.75).foregroundStyle(brand.secondary);Text(copy["labels"]["lessonLabel"].string+": "+meta["lessonTitle"].localized(lang)).font(PiyaliBrand.productFont(12)).foregroundStyle(brand.muted);HStack{Button{if playing == note.id,narration.loading || narration.playing{narration.stopAll();playing=nil}else{playing=note.id;narration.play(meta["example"].string,language:meta["targetLang"].string,engine:app.companionQuestPolicy,onFinished:{playing=nil})}}label:{Image(systemName:playing == note.id && narration.playing ? "stop.fill":"speaker.wave.2").font(.system(size:16)).frame(width:32,height:32)}.foregroundStyle(.blue).disabled(playing == note.id && narration.loading).accessibilityLabel(copy["labels"]["listenLabel"].string).accessibilityIdentifier("memoryNoteListen");Spacer();Button{if playing == note.id{narration.stopAll();playing=nil};app.learner.notes.removeAll{$0.id == note.id};app.persist()}label:{Image(systemName:"trash").font(.system(size:16)).frame(width:32,height:32)}.foregroundStyle(.red).accessibilityLabel(copy["labels"]["deleteNoteLabel"].string).accessibilityIdentifier("memoryNoteDelete")}.padding(.top,4)}.padding(.horizontal,16).padding(.bottom,12).background(scheme == .dark ? .white.opacity(0.04):PiyaliBrand.unitColor("f7f0e4"))}
        }.background(scheme == .dark ? .white.opacity(0.04):PiyaliBrand.unitColor("f3ebdf"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(scheme == .dark ? .clear:brand.border.opacity(0.75))}
    }
    private func empty(_ text:String,glass:Bool)->some View {OnboardingText(text:text,size:14,lineHeight:21).foregroundStyle(brand.secondary).frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,12).padding(.vertical,16).background(glass ? brand.surface.opacity(0.4):.clear,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border,style:StrokeStyle(lineWidth:1,dash:[4,3]))}}
}
struct MemoryDrawerShape:Shape {var radius:CGFloat;func path(in rect:CGRect)->Path {Path(UIBezierPath(roundedRect:rect,byRoundingCorners:[.topLeft,.topRight],cornerRadii:CGSize(width:radius,height:radius)).cgPath)}}
private struct MemoryCardModifier:ViewModifier {let padding:CGFloat,background:Color,border:Color,radius:CGFloat;func body(content:Content)->some View {content.frame(maxWidth:.infinity,alignment:.leading).padding(padding+1).background(background,in:RoundedRectangle(cornerRadius:radius)).overlay{RoundedRectangle(cornerRadius:radius).stroke(border)}}}
extension View {func memoryCard(padding:CGFloat,background:Color,border:Color,radius:CGFloat=16)->some View {modifier(MemoryCardModifier(padding:padding,background:background,border:border,radius:radius))}}
private struct MemoryRepairCard:View {
    @Environment(\.colorScheme) private var scheme
    let note:MemoryNote,language:String,yesterday:Bool
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    var body:some View {
        let p:JSONValue = .object(["note":.object(note.fields),"language":.string(language),"yesterday":.bool(yesterday)]),status=MemoryUI.value("status",p).string,copy=MemoryUI.copy(language),accent=copy["accent"][status],fix=note.text("correction").isEmpty ? note.text("expectedAnswer"):note.text("correction"),tip=MemoryUI.value("localized",p).boolean ? [note.text("mistake"),note.text("tip")].filter{!$0.isEmpty}.joined(separator:" "):""
        return VStack(alignment:.leading,spacing:8){
            OnboardingText(text:MemoryUI.value("clean",.object(["text":.string(note.text("concept")),"language":.string(language)])).string,size:14,weight:.semibold,lineHeight:21).lineLimit(2)
            HStack(spacing:8){OnboardingText(text:copy["status"][status].string,size:10,weight:.bold,lineHeight:15).padding(.horizontal,8).padding(.vertical,1).background(FocusCopy.color(accent["bg"].string),in:Capsule()).foregroundStyle(FocusCopy.color(accent["fg"].string));OnboardingText(text:copy["source"][note.text("sourceMode")].string,size:9,weight:.bold,lineHeight:13.5).padding(.horizontal,4).overlay{RoundedRectangle(cornerRadius:2).stroke(brand.muted)}.foregroundStyle(brand.muted);if note.severity>1{Text("×\(note.severity)").font(PiyaliBrand.productFont(9)).foregroundStyle(brand.muted)}}
            VStack(alignment:.leading,spacing:6){VStack(alignment:.leading,spacing:6){field(copy["card"]["youSaid"].string,note.text("userAnswer").isEmpty ? copy["card"]["noAnswer"].string:note.text("userAnswer"),color:brand.muted);if !fix.isEmpty{field(copy["card"]["correct"].string,fix,color:PiyaliBrand.unitColor("0d9488"))}}.padding(.horizontal,10).padding(.vertical,8).frame(maxWidth:.infinity,alignment:.leading).background(PiyaliBrand.unitColor(scheme == .dark ? "182031":"efe4d5").opacity(0.55),in:RoundedRectangle(cornerRadius:8));if !tip.isEmpty{OnboardingText(text:tip,size:12,lineHeight:18).italic().lineLimit(3).foregroundStyle(brand.secondary)}}
        }.padding(.horizontal,12).padding(.vertical,10).frame(maxWidth:.infinity,alignment:.leading).background(MemoryPaint.glass(scheme),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}.accessibilityElement(children:.combine).accessibilityIdentifier("memoryRepair-"+note.id)
    }
    private func field(_ label:String,_ value:String,color:Color)->some View {HStack(alignment:.firstTextBaseline,spacing:6){OnboardingText(text:label,size:9,weight:.bold,lineHeight:13.5).tracking(0.36).textCase(.uppercase).foregroundStyle(color).fixedSize();OnboardingText(text:value,size:12,lineHeight:18).foregroundStyle(brand.text).lineLimit(2)}}
}

enum MemoryPaint {static func surface(_ scheme:ColorScheme)->Color {PiyaliBrand.unitColor(scheme == .dark ? "111827":"fdf9f2")};static func glass(_ scheme:ColorScheme)->Color {PiyaliBrand.unitColor(scheme == .dark ? "0b1220":"fff9f2").opacity(scheme == .dark ? 0.12:0.88)}}

struct MemoryIcon:View {let name:String;var size:CGFloat=16;var body:some View {Image("Memory-"+name).renderingMode(.template).resizable().scaledToFit().frame(width:size,height:size).accessibilityHidden(true)}}

private struct MemoryLevelButtonStyle:ButtonStyle {func makeBody(configuration:Configuration)->some View {configuration.label.environment(\.isEnabled,true)}}
