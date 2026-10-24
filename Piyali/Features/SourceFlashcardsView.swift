import SwiftUI

struct FlashcardsView:View {
    var repairStep:RepairStep?=nil
    var goalBlueprint:JSONValue?=nil
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @State private var loading=false
    @State private var failure:String?
    @State private var revision=UUID()
    @State private var regularDeck:[JSONValue]=[]
    @State private var snapshots:[String:JSONValue]=[:]
    @State private var firstNewID:String?
    private var dark:Bool {scheme == .dark}
    private var brand:PiyaliBrand {.init(dark:dark)}
    private var policy:FlashcardPolicy? {try? FlashcardPolicy(engine:app.companionQuestPolicy)}
    private var scope:String {app.identity.npub+":"+app.learner.target+":"+app.learner.support+":"+(repairStep?.id ?? goalBlueprint?["goalId"].string ?? "regular")+":"+app.learner.flashcardLevel}
    private var focused:Bool {repairStep != nil || goalBlueprint != nil}
    private func copy(_ key:String)->String {EntryCopy.ui(app.learner.support,"flashcard_"+key)}
    private var cards:[JSONValue] {
        if let goalBlueprint{return app.goalArtifact(goalBlueprint,mode:"flashcards")["cards"].array}
        if let repairStep{return app.learner.repairArtifact(repairStep,mode:"flashcards")["cards"].array}
        return regularDeck
    }
    private func snapshot(_ card:JSONValue)->JSONValue {snapshots[card["id"].string] ?? .object([:])}
    private func status(_ card:JSONValue)->String {
        let snapshot=snapshot(card),review=snapshot["reviewState"].string
        if focused{return snapshot["completed"].boolean ? "scheduled":"active"}
        if review == "due" {return "due"}
        if snapshot["completed"].boolean {return review == "learning" ? "learning":"scheduled"}
        if LessonAccess.throughPlacement(app.learner.placements?[app.learner.target]?.level,level:card["cefrLevel"].string) || card["id"].string == firstNewID {return "active"}
        if let first=cards.firstIndex(where:{$0["id"].string == firstNewID}),let index=cards.firstIndex(where:{$0["id"] == card["id"]}),index>first{return "locked"}
        return "active"
    }
    private var due:[JSONValue] {sorted(cards.filter{snapshot($0)["reviewState"].string == "due"})}
    private var new:[JSONValue] {cards.filter{snapshot($0)["schedulerState"].string == "new"}}
    private var learning:[JSONValue] {sorted(cards.filter{snapshot($0)["reviewState"].string == "learning"})}
    private var weak:[JSONValue] {Array(cards.filter{let s=snapshot($0);return s["weak"].boolean}.sorted{weakness($0)>weakness($1)}.prefix(6))}
    private func weakness(_ c:JSONValue)->Double {snapshot(c)["weakness"].number}
    private var scheduled:[JSONValue] {let ids=Set(weak.map{$0["id"].string});return sorted(cards.filter{snapshot($0)["reviewState"].string == "scheduled" && !ids.contains($0["id"].string)})}
    private func sorted(_ values:[JSONValue])->[JSONValue] {values.sorted{snapshot($0)["nextReviewDate"].string<snapshot($1)["nextReviewDate"].string}}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:32){
                if let goalBlueprint {GoalFocusBanner(blueprint:goalBlueprint)}
                else if let repairStep {RepairFocusSummary(step:repairStep)}
                levelHeader
                dashboard
                if focused {rail(title:goalBlueprint != nil ? app.goalText("title"):ProductCopy.course(app.learner.support,"repair"),values:cards){status($0)}}
                else {
                    if !due.isEmpty {rail(title:copy("reviews_due"),values:due){_ in "due"}}
                    if !weak.isEmpty {rail(title:copy("weak_queue"),values:weak){_ in "weak"}}
                    if !new.isEmpty {rail(title:copy("new_queue"),values:new){status($0)}}
                    if !learning.isEmpty || !scheduled.isEmpty {FlashcardIcon(name:"down",size:30).foregroundStyle(brand.muted.opacity(0.32)).frame(maxWidth:.infinity);rail(title:copy("scheduled_queue"),values:Array((learning+scheduled).prefix(8))){snapshot($0)["reviewState"].string}}
                }
                if loading {ProgressView(copy("session_loading")).frame(maxWidth:.infinity).accessibilityIdentifier("flashcardDeckLoading")}
                if let failure {VStack(spacing:12){Text(failure);Button(EntryCopy.ui(app.learner.support,"try_again")){revision=UUID()}}}
                if cards.isEmpty,!loading {VStack(spacing:16){Image(systemName:"checkmark").font(.system(size:64)).foregroundStyle(.green);Text(copy("all_done")).font(PiyaliBrand.productFont(24,900));Text(copy("all_completed")).multilineTextAlignment(.center)}.padding(48).frame(maxWidth:.infinity).background(brand.surface,in:RoundedRectangle(cornerRadius:16))}
            }.padding(.horizontal,12).padding(.vertical,12).padding(.bottom,24)
        }.background(BrandBackground()).foregroundStyle(brand.text).navigationTitle(EntryCopy.ui(app.learner.support,"app_mode_cards"))
            .task(id:scope+revision.uuidString){await prepare()}
            .onChange(of:app.learner.cardReviews){_,_ in refresh()}
            .onChange(of:app.cards.map(\.id)){_,_ in refresh()}
            .onChange(of:focusedArtifact){_,_ in refresh()}
    }
    private var levelHeader:some View {
        let level=app.learner.flashcardLevel,index=LearningLanguages.levels.firstIndex(of:level) ?? 0,details=(try? policy?.run("flashLevels"))?[level] ?? .null,accent=FlashcardPaint(dark:dark).color(details["color"].string)
        let completed=cards.filter{snapshot($0)["completed"].boolean}.count,percentage=cards.isEmpty ? 0:Int((Double(completed)/Double(cards.count)*100).rounded()),xp=app.learner.xp
        let subtitle=EntryCopy.ui(app.learner.support,"skill_tree_next_level_progress").replacingOccurrences(of:"{percent}",with:String(xp%100)).replacingOccurrences(of:"{level}",with:String(xp/100+2))
        return VStack(spacing:0){
            VStack(spacing:16){VStack(spacing:0){
                OnboardingText(text:details["displayLabel"].string.isEmpty ? level:details["displayLabel"].string,size:16,weight:.black,lineHeight:24).padding(.horizontal,18).padding(.vertical,10).background{RoundedRectangle(cornerRadius:16).fill(FlashcardPaint(dark:dark).color("var(--app-glass-bg)")).overlay{LinearGradient(colors:[accent.opacity(0.125),accent.opacity(0.063)],startPoint:.topLeading,endPoint:.bottomTrailing).clipShape(RoundedRectangle(cornerRadius:16))}.shadow(color:accent.opacity(0.09),radius:5,y:3)}.overlay{RoundedRectangle(cornerRadius:16).stroke(accent.opacity(0.33),lineWidth:2)}
                OnboardingText(text:details["name"].localized(app.learner.support),size:16,weight:.bold,lineHeight:24)
                OnboardingText(text:details["description"].localized(app.learner.support),size:12,lineHeight:18).foregroundStyle(PiyaliBrand.unitColor(dark ? "a3b4c9":"786654"))
            }.multilineTextAlignment(.center)
                HStack(spacing:8){if index>0 {levelButton(LearningLanguages.levels[index-1],previous:true)};if index+1<LearningLanguages.levels.count{levelButton(LearningLanguages.levels[index+1],previous:false)}}
            }.padding(.bottom,24).frame(maxWidth:.infinity)
            HStack(spacing:12){VStack(alignment:.leading,spacing:0){OnboardingText(text:"\(xp) XP",size:14,weight:.black,lineHeight:14);OnboardingText(text:subtitle,size:12,weight:.medium,lineHeight:18).foregroundStyle(PiyaliBrand.unitColor(dark ? "a3b4c9":"786654"))}.frame(maxWidth:.infinity,alignment:.leading)
                VStack(alignment:.trailing,spacing:4){HStack(spacing:8){OnboardingText(text:level,size:12,weight:.semibold,lineHeight:18);OnboardingText(text:"\(percentage)%",size:12,weight:.bold,lineHeight:18).foregroundStyle(PiyaliBrand.unitColor("90cdf4"))};FocusWaveBar(percent:Double(percentage),height:12,start:"4aa8ff",end:"75f8ff")}.frame(maxWidth:200)
            }.padding(.horizontal,12).padding(.vertical,8).background(FlashcardPaint(dark:dark).color("var(--app-glass-bg-soft)"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(brand.border)}.frame(maxWidth:600).frame(maxWidth:.infinity).padding(.bottom,16)
        }.padding(.bottom,-32)
    }
    private func levelButton(_ level:String,previous:Bool)->some View {
        Button{app.setCardLevel(level)}label:{HStack(spacing:8){if previous{FlashcardIcon(name:"previous",size:16)};Text(level == "Pre-A1" ? "A0":level);if !previous{FlashcardIcon(name:app.cardLevels.contains(level) ? "next":"lock",size:16)}}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,16).frame(minWidth:50,minHeight:32).foregroundStyle(brand.text).background(brand.surface.opacity(0.5),in:Capsule()).overlay{Capsule().stroke(PiyaliBrand.unitColor("90cdf4"),lineWidth:2)}}.buttonStyle(FlashcardTileStyle()).disabled(!app.cardLevels.contains(level)).opacity(app.cardLevels.contains(level) ? 1:0.6).accessibilityIdentifier("flashcardLevel-"+level)
    }
    private var dashboard:some View {
        let count=policy?.dailyCount(app.learner) ?? 0,target=policy?.dailyTarget(app) ?? 5,progress=Double(count)/Double(max(1,target))*100
        return VStack(spacing:20){VStack(spacing:12){HStack(spacing:12){stat(copy("reviews_due"),due.count);stat(copy("new_queue"),new.count)};stat(copy("mastered_cards"),cards.filter{snapshot($0)["completed"].boolean}.count)}
            VStack(spacing:8){HStack{OnboardingText(text:copy("daily_target"),size:14,weight:.bold,lineHeight:21);Spacer();OnboardingText(text:"\(Int(progress.rounded()))%",size:14,lineHeight:21).foregroundStyle(brand.secondary)};FocusWaveBar(percent:progress,height:10,start:"f7d66c",end:"f0b429",background:FlashcardPaint(dark:dark).color("var(--app-surface-muted)"),border:Color(red:240/255,green:180/255,blue:41/255).opacity(0.3))}.padding(17).background(brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(brand.border)}
        }.padding(21).background{RoundedRectangle(cornerRadius:24).fill(paintSurface).overlay{LinearGradient(stops:[.init(color:Color(red:56/255,green:189/255,blue:248/255).opacity(0.12),location:0),.init(color:Color(red:14/255,green:165/255,blue:233/255).opacity(0.03),location:0.45),.init(color:Color(red:45/255,green:212/255,blue:191/255).opacity(0.12),location:1)],startPoint:.topLeading,endPoint:.bottomTrailing).clipShape(RoundedRectangle(cornerRadius:24))}.shadow(color:dark ? .black.opacity(0.28):Color(red:111/255,green:86/255,blue:54/255).opacity(0.08),radius:9,y:8)}.overlay{RoundedRectangle(cornerRadius:24).stroke(brand.border)}
    }
    private var paintSurface:Color {FlashcardPaint(dark:dark).color("var(--app-surface)")}
    private func stat(_ title:String,_ count:Int)->some View {VStack(alignment:.leading,spacing:4){OnboardingText(text:title.uppercased(),size:12,lineHeight:18).tracking(0.96).foregroundStyle(brand.muted);OnboardingText(text:String(count),size:24,weight:.black,lineHeight:36)}.frame(maxWidth:.infinity,alignment:.leading).padding(17).background(brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(brand.border)}}
    private func rail(title:String,values:[JSONValue],status:@escaping (JSONValue)->String)->some View {
        VStack(alignment:.leading,spacing:12){OnboardingText(text:title,size:18,weight:.black,lineHeight:27).padding(.horizontal,4)
            ScrollView(.horizontal,showsIndicators:false){HStack(spacing:24){ForEach(values,id:\.json){card in let state=status(card);VStack(spacing:8){cardTile(card,status:state);if ["scheduled","learning","weak"].contains(state),let review=app.learner.cardReviews?[app.learner.completionKey(card["id"].string)],let date=review.nextReviewAt {Text(copy("next_review_label")+"\n"+((try? policy?.run("flashDate",.object(["date":.string(WebProgressContract.iso(date))]),language:app.learner.support).string) ?? "")).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).multilineTextAlignment(.center).padding(.horizontal,8)}}.frame(width:220)}}.padding(24)}.padding(.bottom,16)
        }
    }
    private func cardTile(_ card:JSONValue,status:String)->some View {
        let data=(try? policy?.run("flashTheme",.object(["status":.string(status),"light":.bool(!dark),"level":card["cefrLevel"]]),language:app.learner.support)) ?? .null,decor=data["decor"],paint=FlashcardPaint(dark:dark),colors=paint.colors(decor["bgGradient"].string),locked=status == "locked",actionable=["active","due","weak"].contains(status)
        return Button{do{app.flashcardSession=try FlashcardSessionController(app:app,card:card,status:status,goal:goalBlueprint,repair:repairStep)}catch{failure=error.localizedDescription}}label:{ZStack{
            paint.color(decor["bg"].string)
            if colors.count>1 {LinearGradient(colors:colors,startPoint:.top,endPoint:.bottom)}
            FlashcardTileTexture(visuals:data["visuals"],dark:dark,actionable:actionable)
            if locked {FlashcardIcon(name:"lock",size:80).foregroundStyle(dark ? Color.white:Color(red:96/255,green:77/255,blue:56/255).opacity(0.54)).opacity(dark ? 0.5:0.3)}else if status != "active" {FlashcardIcon(name:"check",size:status == "due" ? 96:120).foregroundStyle(dark ? Color.white:Color(red:96/255,green:77/255,blue:56/255).opacity(0.32)).opacity(dark ? (status == "due" ? 0.16:0.28):0.14)}
            Text(card["concept"][app.learner.support].string.isEmpty ? card["concept"]["en"].string:card["concept"][app.learner.support].string).font(PiyaliBrand.productFont(30,900)).multilineTextAlignment(.center).padding(24).foregroundStyle(paint.color(data["visuals"]["cardTextColor"].string))
        }.frame(width:220,height:280).clipShape(RoundedRectangle(cornerRadius:48)).overlay{RoundedRectangle(cornerRadius:48).stroke(paint.color(decor["borderColor"].string),lineWidth:2)}.shadow(color:dark ? .black.opacity(0.28):Color(red:122/255,green:94/255,blue:61/255).opacity(actionable ? 0.1:0.08),radius:dark ? 12:7,y:dark ? 8:6).opacity(pow(decor["opacity"].number,2)).saturation(locked ? 0:1)}.buttonStyle(FlashcardTileStyle()).disabled(!actionable).accessibilityIdentifier("flashcardTile-"+card["id"].string)
    }
    private var focusedArtifact:JSONValue {if let goalBlueprint{return app.goalArtifact(goalBlueprint,mode:"flashcards")};if let repairStep{return app.learner.repairArtifact(repairStep,mode:"flashcards")};return .null}
    private func refresh(){
        if !focused {regularDeck=app.cards.compactMap{try? JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode($0))}}
        var values:[String:JSONValue]=[:]
        for card in cards {
            let id=card["id"].string
            if focused {let done=focusedArtifact["outcomes"][id]["success"].boolean;values[id] = .object(["completed":.bool(done),"schedulerState":.string(done ? "review":"new"),"reviewState":.string(done ? "scheduled":"new")])}
            else {var progress=app.learner.cardReviews?[app.learner.completionKey(id)] ?? FlashcardReview();if app.learner.cardReviews?[app.learner.completionKey(id)] == nil,app.learner.flashcardMastery.contains(app.learner.completionKey(id)){progress.completed=true;progress.schedulerState = .review;progress.intervalDays=1}
                let snapshot=policy?.snapshot(progress) ?? .null,weak=(try? policy?.run("flashWeak",.object(["snapshot":snapshot]))) ?? .null
                values[id]=snapshot.setting("weak",weak["weak"]).setting("weakness",weak["score"])
            }
        }
        snapshots=values;firstNewID=cards.first{values[$0["id"].string]?["schedulerState"].string == "new"}?["id"].string
    }
    private func prepare()async {
        let scope=self.scope;loading=true;failure=nil
        defer{if self.scope == scope {refresh();loading=false}}
        do {if let goalBlueprint {try await app.prepareGoalDeck(goalBlueprint,mode:"flashcards")}else if let repairStep {try await app.prepareRepairDeck(repairStep)}}catch is CancellationError{}catch{if self.scope == scope {failure=error.localizedDescription}}
    }
}
