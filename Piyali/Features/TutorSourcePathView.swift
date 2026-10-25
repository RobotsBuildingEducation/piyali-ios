import SwiftUI

struct TutorSourcePathView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @ObservedObject var tutor:TutorSessionController
    let onClose:()->Void
    @State private var level=""
    @State private var statuses:JSONValue = .null
    @State private var preview:JSONValue?
    @State private var objectives=false
    @State private var starting=false
    @State private var game:Lesson?
    init(tutor:TutorSessionController,onClose:@escaping()->Void,initialPreview:JSONValue?=nil){self.tutor=tutor;self.onClose=onClose;_preview=State(initialValue:initialPreview)}
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var units:[JSONValue]{tutor.catalog[level].array}
    private var support:String{app.learner.support}
    private var levels:JSONValue{tutor.levels()}
    private var info:JSONValue{levels[level]}
    private var total:Int{units.reduce(0){$0+$1["lessons"].array.count}}
    private var completed:Int{statuses.object.values.filter{$0.string == "completed"}.count}
    private var progress:Int{total>0 ? Int((Double(completed)/Double(total)*100).rounded()):0}
    private var revision:String{level+":"+String(app.learner.pendingChanges?.count ?? 0)+":"+String(app.learner.completed.count)}
    var body:some View {
        ZStack{
            VStack(spacing:0){
                ScrollView{LazyVStack(spacing:24){levelHeader;xpCard;ForEach(Array(units.enumerated()),id:\.offset){_,unit in unitView(unit)}}.padding(.horizontal,28).padding(.top,28).padding(.bottom,24).frame(maxWidth:1024).frame(maxWidth:.infinity)}
                Button(tutor.pathCopy("close",support),action:onClose).font(PiyaliBrand.productFont(16,600)).frame(maxWidth:320,minHeight:48).background(brand.surface,in:Capsule()).overlay{Capsule().stroke(brand.border)}.padding(.vertical,12).frame(maxWidth:.infinity).background(brand.surface).overlay(alignment:.top){brand.border.frame(height:1)}.accessibilityIdentifier("tutorPathClose")
            }.allowsHitTesting(preview == nil).accessibilityHidden(preview != nil).background(scheme == .dark ? PiyaliBrand.unitColor("030712"):brand.surface).foregroundStyle(brand.text)
            if let preview{previewDialog(preview).zIndex(1)}
        }.task{level=app.learner.tutorLevel}.task(id:revision){guard !level.isEmpty else{return};statuses=tutor.path(app,level:level)["statuses"]}
            .fullScreenCover(item:$game){lesson in NavigationStack{RPGView(lesson:lesson,episode:nil,onTutorComplete:{Task{guard app.learner.rpgRuns?[app.learner.target]?.completed == true else{return};await tutor.complete(app,ready:true,gameCompleted:true);game=nil;onClose()}},tutor:true).toolbar{ToolbarItem(placement:.cancellationAction){Button(tutor.pathCopy("close",support)){game=nil}}}}}
            .accessibilityElement(children:.contain).accessibilityIdentifier("tutorPath")
    }
    private var levelHeader:some View {
        VStack(spacing:16){VStack(spacing:0){Text(info["label"].string).font(PiyaliBrand.productFont(16,900)).frame(minWidth:58,minHeight:44).background(scheme == .dark ? PiyaliBrand.unitColor(info["color"].string):brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(PiyaliBrand.unitColor(info["color"].string).opacity(0.6),lineWidth:2)};Text(info["name"].localized(support)).font(PiyaliBrand.productFont(16,700)).frame(minHeight:24);Text(info["description"].localized(support)).font(PiyaliBrand.productFont(12)).frame(minHeight:18).foregroundStyle(brand.secondary)}
            HStack(spacing:12){if let index=LearningLanguages.levels.firstIndex(of:level){if index>0{levelButton(LearningLanguages.levels[index-1],next:false)};if index<LearningLanguages.levels.count-1{levelButton(LearningLanguages.levels[index+1],next:true)}}}
        }
    }
    private func levelButton(_ nextLevel:String,next:Bool)->some View {let unlocked=app.tutorLevels.contains(nextLevel);return Button{if unlocked{level=nextLevel}}label:{HStack(spacing:8){if !next{Image(systemName:"arrow.left")};Text(levels[nextLevel]["label"].string);if next{Image(systemName:unlocked ? "arrow.right":"lock")}}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,12).frame(height:32).background(brand.surface.opacity(0.8),in:Capsule()).overlay{Capsule().stroke(PiyaliBrand.unitColor(info["color"].string).opacity(0.55),lineWidth:2)}}.buttonStyle(.plain).disabled(!unlocked).opacity(unlocked ? 1:0.48).accessibilityIdentifier("tutorPathLevel-"+nextLevel)}
    private var xpCard:some View {HStack(spacing:16){VStack(alignment:.leading,spacing:0){Text("\(app.learner.xp) XP").font(PiyaliBrand.productFont(14,900));Text(EntryCopy.ui(support,"skill_tree_next_level_progress").replacingOccurrences(of:"{percent}",with:String(app.learner.xp%100)).replacingOccurrences(of:"{level}",with:String(app.learner.companionLevel+1))).font(PiyaliBrand.productFont(12,500)).foregroundStyle(brand.secondary)};Spacer(minLength:0);VStack(alignment:.trailing,spacing:4){HStack(spacing:8){Text(level).font(PiyaliBrand.productFont(12,600));Text("\(progress)%").font(PiyaliBrand.productFont(12,700)).foregroundStyle(PiyaliBrand.unitColor("90cdf4"))};ActivityProgressBar(value:progress,label:level).frame(width:168)}}.padding(16).background(brand.background,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border).allowsHitTesting(false)}}
    private func unitView(_ unit:JSONValue)->some View {
        let color=PiyaliBrand.unitColor(unit["color"].string),lessons=unit["lessons"].array,count=lessons.filter{statuses[$0["id"].string].string == "completed"}.count
        return VStack(spacing:16){
            HStack(alignment:.top){VStack(alignment:.leading,spacing:8){HStack(spacing:12){Circle().fill(color).frame(width:8,height:8);Text(unit["title"].localized(support)).font(PiyaliBrand.productFont(16,700)).frame(minHeight:24)};Text(unit["description"].localized(support)).font(PiyaliBrand.productFont(14)).lineSpacing(4).foregroundStyle(brand.secondary).padding(.leading,32)};Spacer(minLength:8);Text("\(count)/\(lessons.count)").font(PiyaliBrand.productFont(14,700))}.padding(.horizontal,24).padding(.vertical,16).background(LinearGradient(colors:[color.opacity(0.08),color.opacity(0.03)],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(color.opacity(0.25),lineWidth:2)}
            ZStack(alignment:.top){
                ForEach(Array(lessons.enumerated()),id:\.offset){index,lesson in
                    let status=statuses[lesson["id"].string].string,offset:CGFloat=index%2 == 0 ? 0:90,nextOffset:CGFloat=index%2 == 0 ? 90:0
                    if index<lessons.count-1 {Path{p in p.move(to:CGPoint(x:120+offset,y:CGFloat(index)*140+45));p.addQuadCurve(to:CGPoint(x:120+nextOffset,y:CGFloat(index)*140+140),control:CGPoint(x:120+(offset+nextOffset)/2,y:CGFloat(index)*140+115))}.stroke(status == "completed" ? color.opacity(0.76):PiyaliBrand.unitColor(scheme == .dark ? "374151":"d3c4b0").opacity(0.42),style:StrokeStyle(lineWidth:5,lineCap:.round)).frame(width:240)}
                    TutorSourceNode(lesson:lesson,color:unit["color"].string,status:status,percent:Int(min(100,tutor.record(app,lesson["id"].string)["earnedXp"].number/Double(max(1,tutor.xpRequired(lesson)))*100)),support:support){objectives=false;preview = .object(["lesson":lesson,"unit":unit,"status":.string(status)])}.position(x:120+offset,y:CGFloat(index)*140+57)
                }
            }.frame(width:240,height:CGFloat(lessons.count)*140).offset(y:-16).frame(maxWidth:.infinity).padding(.vertical,16)
        }.padding(.bottom,8)
    }
    private func previewDialog(_ selected:JSONValue)->some View {
        let lesson=selected["lesson"],unit=selected["unit"],content=tutor.details(app,lesson:lesson,unit:unit),locked=selected["status"].string == "locked",color=PiyaliBrand.unitColor(unit["color"].string)
        return ZStack{Color.black.opacity(scheme == .dark ? 0.72:0.6).ignoresSafeArea().onTapGesture{if !starting{preview=nil}};VStack(spacing:0){
            HStack(alignment:.top){VStack(alignment:.leading,spacing:8){HStack(spacing:12){Circle().fill(color).frame(width:16,height:16);Text(content["title"].string).font(PiyaliBrand.productFont(20,700))};Text(unit["title"].localized(support)).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary).padding(.leading,28)};Spacer(minLength:4);Button{preview=nil}label:{Image(systemName:"xmark").font(.system(size:14)).frame(width:24,height:24)}.disabled(starting).accessibilityLabel(tutor.pathCopy("close",support)).accessibilityIdentifier("tutorPreviewClose")}.padding(.horizontal,28).padding(.top,24).padding(.bottom,16).overlay(alignment:.bottom){brand.border.frame(height:1)}
            ScrollView{VStack(alignment:.leading,spacing:20){
                Text(content["subtitle"].string).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.secondary)
                VStack(spacing:0){Button{objectives.toggle()}label:{HStack(spacing:12){Text(tutor.copy("Lesson objectives",support)).font(PiyaliBrand.productFont(14,700));Spacer();Text("\(content["preview"].array.count)").font(PiyaliBrand.productFont(12,700)).padding(.horizontal,8).padding(.vertical,2).background(brand.border,in:Capsule());Image(systemName:objectives ? "chevron.up":"chevron.down").foregroundStyle(color)}.padding(.horizontal,20).padding(.vertical,16).contentShape(Rectangle())}.buttonStyle(.plain).accessibilityIdentifier("tutorPreviewObjectives").accessibilityValue(objectives ? "Expanded":"Collapsed");if objectives{ScrollView{VStack(alignment:.leading,spacing:16){ForEach(Array(content["preview"].array.enumerated()),id:\.offset){_,item in HStack(alignment:.top,spacing:12){Image(systemName:"checkmark").font(.system(size:14,weight:.semibold)).foregroundStyle(.white).frame(width:22,height:22).background(color,in:Circle());Text(item["label"].string).font(PiyaliBrand.productFont(14)).lineSpacing(3).foregroundStyle(brand.secondary)}}}.padding(.horizontal,20).padding(.top,16).padding(.bottom,20)}.frame(height:220)}}.background(brand.surface.opacity(scheme == .dark ? 0.6:0.62),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border).allowsHitTesting(false)}
                if locked {HStack(alignment:.top,spacing:12){Image(systemName:"lock");Text(tutor.copy("This lesson is locked. You can preview it now, then complete the earlier lessons to unlock it.",support)).font(PiyaliBrand.productFont(14)).lineSpacing(4)}.padding(16).background(brand.muted.opacity(0.1),in:RoundedRectangle(cornerRadius:12)).accessibilityIdentifier("tutorPreviewLocked")}
                HStack(spacing:0){Image(systemName:lesson["isTutorial"].boolean ? "trophy":"chart.bar.xaxis").font(.system(size:18)).foregroundStyle(lesson["isTutorial"].boolean ? .white:Color.orange).frame(width:36,height:36).background(lesson["isTutorial"].boolean ? color:Color.orange.opacity(0.14),in:RoundedRectangle(cornerRadius:8)).padding(.trailing,12);Text(tutor.copy("XP required to complete",support)).font(PiyaliBrand.productFont(14,800));Spacer(minLength:12);Text("\(tutor.xpRequired(lesson)) XP").font(PiyaliBrand.productFont(16,900)).fixedSize()}.padding(16).background(brand.surface.opacity(0.72),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border).allowsHitTesting(false)}
            }.padding(.horizontal,25).padding(.vertical,20)}.fixedSize(horizontal:false,vertical:true)
            Button{launch(selected,content:content)}label:{HStack{if starting{ProgressView().tint(.white)};Text(tutor.copy(content["launch"].string == "rpg_game" ? "Start game":"Start lesson",support))}.font(PiyaliBrand.productFont(18,900)).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:48).background(locked ? brand.muted.opacity(0.4):color,in:RoundedRectangle(cornerRadius:12)).shadow(color:locked ? .clear:color.opacity(0.6),radius:0,y:4)}.buttonStyle(.plain).disabled(locked || starting).padding(.horizontal,25).padding(.top,8).padding(.bottom,24).accessibilityIdentifier("tutorPreviewStart")
        }.padding(3).background{TutorPaperPanel(radius:48)}.overlay{RoundedRectangle(cornerRadius:48).stroke(brand.border,lineWidth:3).allowsHitTesting(false)}.compositingGroup().shadow(color:.black.opacity(0.24),radius:30,y:24).padding(.horizontal,12).padding(.vertical,16).frame(maxWidth:512)}.accessibilityElement(children:.contain).accessibilityIdentifier("tutorPreviewDialog")
    }
    private func launch(_ selected:JSONValue,content:JSONValue){
        starting=true;Task{await tutor.stop(app);if app.learner.tutorLevel != level{app.setTutorLevel(level)};tutor.adoptLevel(app);tutor.select(app,lesson:selected["lesson"],unit:selected["unit"]);starting=false;preview=nil
            if content["launch"].string == "rpg_game"{game=tutor.typedLesson}else{onClose();await tutor.start(app)}
        }
    }
}
private struct TutorSourceNode:View {
    @Environment(\.colorScheme) private var scheme
    let lesson:JSONValue
    let color:String
    let status:String
    let percent:Int
    let support:String
    let onSelect:()->Void
    private var locked:Bool{status == "locked"}
    private var done:Bool{status == "completed"}
    private var tint:Color{PiyaliBrand.unitColor(color)}
    private var colors:[Color]{locked ? (scheme == .dark ? [PiyaliBrand.unitColor("374151"),PiyaliBrand.unitColor("1f2937")]:[PiyaliBrand.unitColor("f5efe6"),PiyaliBrand.unitColor("e0d4c2")]):done ? [PiyaliBrand.unitColor("ffd700"),PiyaliBrand.unitColor("ffa500"),PiyaliBrand.unitColor("ffd700")]:[tint,tint]}
    var body:some View {Button(action:onSelect){VStack(spacing:8){ZStack{Circle().fill(LinearGradient(colors:colors,startPoint:.topLeading,endPoint:.bottomTrailing)).overlay{if scheme != .dark && !locked && !done{Circle().fill(PiyaliBrand.unitColor("fffaf3").opacity(0.22))}}.frame(width:90,height:90).shadow(color:locked ? PiyaliBrand.unitColor("a89277").opacity(0.26):done ? PiyaliBrand.unitColor("daa520"):tint.opacity(0.58),radius:0,y:8);if status == "in_progress"{Circle().stroke(PiyaliBrand.unitColor("f7c74a").opacity(0.46),lineWidth:10).frame(width:96,height:96);Circle().trim(from:0,to:Double(percent)/100).stroke(PiyaliBrand.unitColor(scheme == .dark ? "e0aa2c":"f7c74a"),style:StrokeStyle(lineWidth:10,lineCap:.round)).rotationEffect(.degrees(-90)).frame(width:96,height:96)};Image(systemName:done ? "checkmark":locked ? "lock":"book").font(.system(size:36)).foregroundStyle(locked ? PiyaliBrand.unitColor("8b7a63"):.white)}.frame(width:90,height:90);Text(lesson["title"].localized(support)).font(PiyaliBrand.productFont(14,700)).foregroundStyle(locked ? PiyaliBrand.unitColor("c4b4a0"):scheme == .dark ? .white:PiyaliBrand.unitColor("746250")).multilineTextAlignment(.center).lineLimit(3).frame(width:140)}.opacity(locked && scheme == .dark ? 0.4:1)}.buttonStyle(.plain).accessibilityIdentifier("tutorNode-"+lesson["id"].string).accessibilityLabel(lesson["title"].localized(support)).accessibilityValue(status)}
}
