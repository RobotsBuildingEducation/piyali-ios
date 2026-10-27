import SwiftUI

@MainActor enum CoursePathSource {
    static let policy=try? CoursePathPolicy()
    static let appearance=(try? ContentLibrary.load(JSONValue.self,name:"lesson-appearance")) ?? .null
    static func unit(_ original:LearningUnit,target:String)->LearningUnit {var unit=original;let metadata=appearance["units"][target][unit.id];unit.color=metadata["color"].string.isEmpty ? original.color:metadata["color"].string;return unit}
    static func run(_ operation:String,_ input:JSONValue = .object([:]))->JSONValue {(try? policy?.run(operation,input)) ?? .null}
    static func text(_ value:JSONValue,_ language:String)->String {run("text",.object(["text":value,"language":.string(language)])).string}
    static func node(_ lesson:Lesson,unit:LearningUnit,status:LessonAccessStatus,percent:Double,language:String,dark:Bool)->JSONValue {
        let data=(try? JSONEncoder().encode(lesson)).flatMap{try? JSONDecoder().decode(JSONValue.self,from:$0)} ?? .null
        return run("node",.object(["lesson":data,"unit":.object(["id":.string(unit.id),"color":.string(unit.color ?? "#8B5CF6")]),"status":.string(status.rawValue),"percent":.number(percent),"language":.string(language),"dark":.bool(dark)]))
    }
    static func color(_ css:String)->Color {
        switch css {case "white":return .white;case "gray":return Color(white:128/255);case "gray.600":return PiyaliBrand.unitColor("4a5568");default:return FocusCopy.color(css)}
    }
    static func gradient(_ css:String)->[Color] {
        let expression=try? NSRegularExpression(pattern:"rgba?\\([^)]*\\)|#[a-fA-F0-9]{6}(?:[a-fA-F0-9]{2})?|gray\\.[0-9]+")
        return (expression?.matches(in:css,range:NSRange(css.startIndex...,in:css)) ?? []).compactMap{Range($0.range,in:css).map{range in
            let s=String(css[range]);if s == "gray.700" {return PiyaliBrand.unitColor("2d3748")};if s == "gray.800" {return PiyaliBrand.unitColor("1a202c")}
            if s.count == 9,s.first == "#",let a=Int(s.suffix(2),radix:16) {return color(String(s.prefix(7))).opacity(Double(a)/255)}
            return color(s)
        }}
    }
}

struct CoursePathIcon:View {
    let name:String
    var body:some View {if let url=Bundle.main.url(forResource:"course-"+name+"@3x",withExtension:"png"),let image=UIImage(contentsOfFile:url.path){Image(uiImage:image).renderingMode(.template).resizable().scaledToFit()}}
}

struct CoursePathNode:View {
    let style:JSONValue
    let status:LessonAccessStatus
    let action:()->Void
    @Environment(\.colorScheme) private var scheme
    var body:some View {
        Button(action:action) {
            VStack(spacing:8) {
                ZStack {
                    if status != .locked {Circle().fill((status == .completed ? PiyaliBrand.unitColor("FFD700"):CoursePathSource.color(style["lightNodeGlowColor"].string))).blur(radius:16).opacity(status == .completed ? 0.6 : scheme == .dark ? 0.4:0.24)}
                    Circle().fill(LinearGradient(colors:CoursePathSource.gradient(style["nodeBackground"].string),startPoint:.topLeading,endPoint:.bottomTrailing))
                        .overlay{Circle().strokeBorder(scheme == .light && status == .locked ? Color(red:168/255,green:146/255,blue:119/255).opacity(0.16):.clear,lineWidth:4)}
                        .shadow(color:groundColor,radius:0,y:8).opacity(style["nodeOpacity"].number)
                    CoursePathIcon(name:style["icon"].string).frame(width:36,height:36).foregroundStyle(CoursePathSource.color(style["iconColor"].string)).opacity(style["nodeOpacity"].number)
                    if status == .inProgress {
                        Circle().stroke(CoursePathSource.color(style["progressRingTrackColor"].string),lineWidth:10).frame(width:96,height:96)
                        Circle().trim(from:0,to:style["ringPercent"].number/100).stroke(CoursePathSource.color(style["progressRingStrokeColor"].string),style:StrokeStyle(lineWidth:10,lineCap:.round)).rotationEffect(.degrees(-90)).frame(width:96,height:96)
                    }
                    if status == .completed {CourseCompletionSparkles().allowsHitTesting(false)}
                }.frame(width:90,height:90)
                OnboardingText(text:style["title"].string,size:14,weight:.bold,lineHeight:16.1).foregroundStyle(CoursePathSource.color(style["titleColor"].string)).multilineTextAlignment(.center).frame(width:140)
            }.contentShape(Rectangle())
        }.buttonStyle(CoursePathPressStyle()).disabled(!status.canOpen).accessibilityLabel(style["title"].string).accessibilityValue(status.rawValue)
    }
    private var groundColor:Color {
        if status == .completed {return PiyaliBrand.unitColor("DAA520")}
        if status == .locked {return scheme == .light ? Color(red:168/255,green:146/255,blue:119/255).opacity(0.26):.black.opacity(0.4)}
        return CoursePathSource.color(style["lightNodeColorEnd"].string).opacity(scheme == .light ? 0.58:0.67)
    }
}
private struct CoursePathPressStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {configuration.label.scaleEffect(configuration.isPressed ? 0.97:1).offset(y:configuration.isPressed ? 2:0)}
}
private struct CourseCompletionSparkles:View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body:some View {TimelineView(.animation(minimumInterval:1/15,paused:reduceMotion)){clock in
        Canvas{context,size in
            for (i,p) in [CGPoint(x:12,y:8),CGPoint(x:80,y:30),CGPoint(x:65,y:80)].enumerated(){let duration=[2.4,2.7,2.2][i],delay=[0,1.2,0.6][i],phase=(clock.date.timeIntervalSinceReferenceDate+delay).truncatingRemainder(dividingBy:duration)/duration,opacity=reduceMotion ? 0.6:0.3+0.7*sin(phase * .pi);context.opacity=opacity;let d=CGFloat(i == 1 ? 4:6);context.fill(Path(ellipseIn:CGRect(x:p.x,y:p.y,width:d,height:d)),with:.color(.white))}
        }
    }}
}

struct CourseUnitPath:View {
    let unit:LearningUnit
    let language:String
    let statuses:[String:LessonAccessStatus]
    let percentages:[String:Double]
    let hasNext:Bool
    let onSelect:(Lesson)->Void
    @Environment(\.colorScheme) private var scheme
    private var color:Color {PiyaliBrand.unitColor(unit.color ?? "8B5CF6")}
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    var body:some View {
        VStack(spacing:16) {
            HStack(alignment:.center) {
                VStack(alignment:.leading,spacing:8) {
                    HStack(spacing:12) {Circle().fill(color).frame(width:8,height:8);OnboardingText(text:CoursePathSource.text(unit.title,language),size:16,weight:.bold,lineHeight:19.2)}
                    OnboardingText(text:CoursePathSource.text(unit.description,language),size:14,lineHeight:21).foregroundStyle(scheme == .dark ? PiyaliBrand.unitColor("cbd5e0"):brand.secondary).padding(.leading,32)
                }
                Spacer(minLength:8)
                Text("\(unit.lessons.filter{statuses[$0.id] == .completed}.count)/\(unit.lessons.count)").font(PiyaliBrand.productFont(14,700)).fixedSize()
            }.padding(.vertical,18).padding(.horizontal,26).frame(maxWidth:.infinity,alignment:.leading)
                .background(LinearGradient(colors:[color.opacity(21/255),color.opacity(8/255)],startPoint:.topLeading,endPoint:.bottomTrailing),in:EntryCornerShape(radius:16))
                .overlay{EntryCornerShape(radius:16).stroke(color.opacity(64/255),lineWidth:2)}
                .shadow(color:scheme == .dark ? color.opacity(0.125):.clear,radius:16,y:8)
            GeometryReader {geometry in
                let offset:CGFloat=geometry.size.width >= 968 ? 180:geometry.size.width >= 720 ? 140:geometry.size.width >= 448 ? 110:90
                ZStack(alignment:.topLeading) {
                    Canvas {context,size in
                        for (index,lesson) in unit.lessons.enumerated() where index < unit.lessons.count-1 || hasNext {
                            // Straight SVG end connectors have no visible stroke in the source WebKit output.
                            if index == unit.lessons.count-1 && index.isMultiple(of:2) {continue}
                            let last=index == unit.lessons.count-1,x=size.width/2+(index.isMultiple(of:2) ? 0:offset),endX=size.width/2+(last || !index.isMultiple(of:2) ? 0:offset),y=CGFloat(index)*140+45
                            var p=Path();p.move(to:CGPoint(x:x,y:y));p.addQuadCurve(to:CGPoint(x:endX,y:y+95),control:CGPoint(x:(x+endX)/2,y:y+70))
                            let complete=statuses[lesson.id] == .completed,c=last || complete ? color:scheme == .light ? PiyaliBrand.unitColor("d3c4b0"):PiyaliBrand.unitColor("374151"),a=last || complete ? 0.8:scheme == .light ? 0.7:0.5,b=last ? 0.3:complete ? 0.4:scheme == .light ? 0.42:0.3
                            context.stroke(p,with:.linearGradient(Gradient(colors:[c.opacity(a),c.opacity(b)]),startPoint:CGPoint(x:0,y:y),endPoint:CGPoint(x:0,y:y+95)),style:StrokeStyle(lineWidth:5,lineCap:.round))
                        }
                    }.allowsHitTesting(false)
                    ForEach(Array(unit.lessons.enumerated()),id:\.element.id) {index,lesson in
                        let status=statuses[lesson.id] ?? .locked
                        CoursePathNode(style:CoursePathSource.node(lesson,unit:unit,status:status,percent:percentages[lesson.id] ?? 0,language:language,dark:scheme == .dark),status:status){onSelect(lesson)}
                            .accessibilityIdentifier(lesson.id == IntroTutorial.lessonID ? "introLink":"lessonNode-"+lesson.id)
                            .frame(width:140,alignment:.top).offset(x:geometry.size.width/2-70+(index.isMultiple(of:2) ? 0:offset),y:CGFloat(index)*140).id(lesson.id)
                    }
                }
            }.frame(height:max(200,CGFloat(unit.lessons.count)*140+32))
        }.foregroundStyle(brand.text).background(alignment:.top){RadialGradient(colors:[color.opacity(21/255),.clear],center:.center,startRadius:0,endRadius:150).frame(width:300,height:300).blur(radius:60).opacity(0.6).allowsHitTesting(false)}
    }
}

struct CourseLevelNavigator:View {
    let navigation:JSONValue
    let language:String
    let complete:Bool
    let onSelect:(String)->Void
    @Environment(\.colorScheme) private var scheme
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    var body:some View {
        let info=navigation["info"],color=PiyaliBrand.unitColor(info["color"].string)
        VStack(spacing:16) {
            VStack(spacing:0) {
                OnboardingText(text:info["displayLabel"].string,size:16,weight:.black,lineHeight:24).padding(.horizontal,18).padding(.vertical,10).background(LinearGradient(colors:[color.opacity(32/255),color.opacity(16/255)],startPoint:.topLeading,endPoint:.bottomTrailing),in:EntryCornerShape(radius:16)).overlay{EntryCornerShape(radius:16).stroke(color.opacity(85/255),lineWidth:2)}.shadow(color:color.opacity(24/255),radius:5,y:3).accessibilityIdentifier("lessonCourseLevel")
                OnboardingText(text:info["name"].localized(language),size:16,weight:.bold,lineHeight:24).multilineTextAlignment(.center)
                OnboardingText(text:info["description"].localized(language),size:12,lineHeight:18).foregroundStyle(PiyaliBrand.unitColor(scheme == .dark ? "a0aec0":"786654")).multilineTextAlignment(.center)
            }
            HStack(spacing:8) {
                if !navigation["previousLevel"].string.isEmpty {levelButton(navigation["previousLevel"].string,previous:true,enabled:true)}
                if !navigation["nextLevel"].string.isEmpty {levelButton(navigation["nextLevel"].string,previous:false,enabled:navigation["isNextLevelUnlocked"].boolean)}
            }
            if complete {HStack(spacing:8){CoursePathIcon(name:"RiTrophyLine").frame(width:20,height:20);Text(EntryCopy.ui(language,"cefr_level_completed")).font(PiyaliBrand.productFont(14,700))}.foregroundStyle(.white).padding(12).background(LinearGradient(colors:[PiyaliBrand.unitColor("48bb78"),PiyaliBrand.unitColor("38a169")],startPoint:.leading,endPoint:.trailing),in:RoundedRectangle(cornerRadius:8))}
        }.foregroundStyle(brand.text).frame(maxWidth:.infinity).padding(.bottom,24)
    }
    private func levelButton(_ level:String,previous:Bool,enabled:Bool)->some View {
        Button{onSelect(level)}label:{HStack(spacing:8){if previous{CoursePathIcon(name:"RiArrowLeftLine").frame(width:16,height:16)};Text(level == "Pre-A1" ? "A0":level).font(PiyaliBrand.productFont(14,600));if !previous{CoursePathIcon(name:enabled ? "RiArrowRightLine":"RiLockLine").frame(width:16,height:16)}}.padding(.horizontal,16).frame(minWidth:50,minHeight:32).background(scheme == .dark ? brand.background.opacity(0.12):PiyaliBrand.unitColor("fff9f2").opacity(0.88),in:EntryCornerShape(radius:100)).overlay{EntryCornerShape(radius:100).stroke(PiyaliBrand.unitColor("90cdf4"),lineWidth:2)}}.buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1:0.6).accessibilityIdentifier(previous ? "lessonPreviousLevel":"lessonNextLevel")
    }
}

struct CoursePathProgressHeader:View {
    let xp:Int,level:String,percentage:Double,language:String
    @Environment(\.colorScheme) private var scheme
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var percent:String {percentage.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier:"en_US_POSIX")))}
    var body:some View {
        HStack(spacing:12) {
            VStack(alignment:.leading,spacing:0) {
                OnboardingText(text:"\(xp) XP",size:14,weight:.black,lineHeight:14)
                CoursePathProgressText(text:EntryCopy.ui(language,"skill_tree_next_level_progress").replacingOccurrences(of:"{percent}",with:String(xp%100)).replacingOccurrences(of:"{level}",with:String(xp/100+2)),color:PiyaliBrand.unitColor(scheme == .dark ? "a0aec0":"786654"))
            }.frame(maxWidth:.infinity,alignment:.leading)
            VStack(alignment:.trailing,spacing:4) {HStack(spacing:8){Text(level).font(PiyaliBrand.productFont(12,600));Text(percent+"%").font(PiyaliBrand.productFont(12,700)).foregroundStyle(PiyaliBrand.unitColor("90cdf4"))};FocusWaveBar(percent:percentage,height:12,start:"4aa8ff",end:"75f8ff")}.frame(maxWidth:200).frame(maxWidth:.infinity)
        }.padding(.horizontal,13).padding(.vertical,9).frame(maxWidth:600).background(scheme == .dark ? brand.background.opacity(0.12):PiyaliBrand.unitColor("fff9f2").opacity(0.88),in:EntryCornerShape(radius:8)).overlay{EntryCornerShape(radius:8).stroke(brand.border,lineWidth:1)}.shadow(color:.black.opacity(scheme == .dark ? 0.2:0.04),radius:8,y:3).foregroundStyle(brand.text).padding(.bottom,16).accessibilityIdentifier("lessonCourseProgress")
    }
}

// CourseProgressHeader inherits the source document's LTR paragraph direction,
// including its mixed Arabic/numeric XP subtitle.
private struct CoursePathProgressText:UIViewRepresentable {
    let text:String,color:Color
    @ScaledMetric private var scale:CGFloat=1000
    func makeUIView(context:Context)->UILabel {let label=UILabel();label.numberOfLines=0;label.setContentCompressionResistancePriority(.defaultLow,for:.horizontal);label.isAccessibilityElement=true;return label}
    func updateUIView(_ label:UILabel,context:Context) {
        let paragraph=NSMutableParagraphStyle();paragraph.baseWritingDirection = .leftToRight;paragraph.alignment = .left;paragraph.minimumLineHeight=18*scale/1000;paragraph.maximumLineHeight=18*scale/1000;paragraph.lineBreakMode = .byWordWrapping;paragraph.lineBreakStrategy=[]
        label.attributedText=NSAttributedString(string:text,attributes:[.font:UIFont.systemFont(ofSize:12*scale/1000,weight:.medium),.foregroundColor:UIColor(color),.paragraphStyle:paragraph]);label.accessibilityLabel=text
    }
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UILabel,context:Context)->CGSize? {let width=proposal.width ?? 180;return CGSize(width:width,height:ceil(uiView.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude)).height))}
}
