import SwiftUI

enum PracticeQuestionAppearance {
    static let data:JSONValue = {guard let url=Bundle.main.url(forResource:"practice-feedback-ui",withExtension:"json"),let bytes=try? Data(contentsOf:url),let value=try? JSONDecoder().decode(JSONValue.self,from:bytes)else{return .null};return value}()
    static var portrait:Int {data["positivePortraits"].array.compactMap{Int($0.string)}.randomElement() ?? 7}
}

struct PracticeIcon:View {
    let name:String
    var size:CGFloat=18
    var body:some View{Image("Practice-"+name).renderingMode(.template).resizable().scaledToFit().frame(width:size,height:size).accessibilityHidden(true)}
}
struct PracticeToolButton<Label:View>:View {
    var active=false
    var size:CGFloat=32
    let action:()->Void
    @ViewBuilder let label:()->Label
    @Environment(\.colorScheme) private var scheme
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    var body:some View{Button(action:action){label().frame(width:size,height:size).foregroundStyle(brand.questionTool).background(active ? brand.questionTool.opacity(0.08):brand.surface,in:EntryCornerShape(radius:12)).overlay{EntryCornerShape(radius:12).stroke(brand.questionTool.opacity(active ? 0.7:0.22)).padding(0.5)}.shadow(color:scheme == .dark ? .black.opacity(0.25):PiyaliBrand.unitColor("503a24").opacity(0.08),radius:6,y:4)}.buttonStyle(.plain)}
}
struct NaturalOrWeirdQuestion:View {
    let sentence:String,title:String,instruction:String,weird:String,natural:String,audioLabel:String,helpLabel:String
    let selected:Bool?,locked:Bool,assistantOpen:Bool,assistantBusy:Bool
    let help:()->Void,listen:()->Void,select:(Bool)->Void
    var showHelp=true
    @Environment(\.colorScheme) private var scheme
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    var body:some View {
        VStack(alignment:.leading,spacing:20) {
            VStack(alignment:.leading,spacing:4){HStack(spacing:8){OnboardingText(text:title,size:20,weight:.heavy,lineHeight:30);Spacer(minLength:8);if showHelp{PracticeToolButton(active:assistantOpen,action:help){PracticeIcon(name:"MdOutlineSupportAgent")}.disabled(assistantBusy).accessibilityLabel(helpLabel).accessibilityIdentifier("typedPracticeHelp")}};OnboardingText(text:instruction,size:14,lineHeight:21).foregroundStyle(brand.secondary)}
            HStack(spacing:12) {OnboardingText(text:"“"+sentence+"”",size:18,weight:.bold,lineHeight:27).environment(\.layoutDirection,.leftToRight).frame(maxWidth:.infinity,alignment:.leading);PracticeToolButton(size:40,action:listen){PracticeIcon(name:"FiVolume2",size:16)}.disabled(locked).accessibilityLabel(audioLabel).accessibilityIdentifier("typedPracticeListen")}.padding(21).background(PiyaliBrand.unitColor(scheme == .dark ? "182031":"efe4d5"),in:EntryCornerShape(radius:16)).overlay{EntryCornerShape(radius:16).stroke(brand.border).padding(0.5)}
            VStack(spacing:12){choice(weird,value:false);choice(natural,value:true)}
        }.padding(17).frame(maxWidth:.infinity,alignment:.leading).background(brand.surface,in:EntryCornerShape(radius:16)).overlay{EntryCornerShape(radius:16).stroke(brand.border).padding(0.5)}.shadow(color:.black.opacity(scheme == .dark ? 0.12:0.04),radius:9,y:8).foregroundStyle(brand.text).accessibilityElement(children:.contain).accessibilityIdentifier("typedQuestionPrompt")
    }
    private func choice(_ title:String,value:Bool)->some View {
        let checked=selected == value
        return Button{select(value)}label:{HStack(alignment:.top,spacing:12){ZStack{Circle().fill(checked ? brand.questionChoice:.clear);Circle().strokeBorder(checked ? brand.questionChoice:brand.border.opacity(1.5),lineWidth:2);if checked{Text("✓").font(PiyaliBrand.productFont(12,800)).foregroundStyle(.white)}}.frame(width:24,height:24);OnboardingText(text:title,size:16,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading)}.padding(18).background(checked ? brand.questionChoiceBackground:brand.surface,in:EntryCornerShape(radius:12)).overlay{EntryCornerShape(radius:12).stroke(checked ? brand.questionChoice:brand.border,lineWidth:2).padding(1)}.opacity(locked && !checked ? 0.72:1)}.buttonStyle(PracticeChoicePressStyle()).disabled(locked).accessibilityIdentifier(value ? "typedChoice-1":"typedChoice-0").accessibilityValue(checked ? "Selected":"Not selected").accessibilityAddTraits(checked ? .isSelected:[])
    }
}
private struct PracticeChoicePressStyle:ButtonStyle {func makeBody(configuration:Configuration)->some View{configuration.label}}

/// Preserve the source assistant's emphasized answer color while retaining native text selection.
struct PracticeFeedbackMarkdown:View {
    let text:String
    var assistant=false
    var paragraphBottom:CGFloat=0
    var plainTextDirection=false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.layoutDirection)private var direction
    private func content(_ original:AttributedString)->AttributedString {
        var value=original
        if assistant {
            for run in value.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                value[run.range].foregroundColor=PiyaliBrand.unitColor(scheme == .dark ? "e0f2fe":"1e3a8a")
            }
        }
        return value
    }
    private func paragraphDirection(_ text:AttributedString)->LayoutDirection{guard plainTextDirection else{return direction};let scalar=String(text.characters).unicodeScalars.first{CharacterSet.letters.contains($0)};guard let scalar else{return .leftToRight};return (0x0590...0x08ff).contains(scalar.value) || (0xfb1d...0xfdff).contains(scalar.value) || (0xfe70...0xfefc).contains(scalar.value) ? .rightToLeft:.leftToRight}
    private var lineGap:CGFloat{max(0,22.4-UIFont.systemFont(ofSize:14).lineHeight)}
    private func row(_ block:PracticeFeedbackDocument.Block)->some View{Text(content(block.text)).font(block.code ? .system(size:14,design:.monospaced):PiyaliBrand.productFont(14)).lineSpacing(lineGap).padding(.vertical,lineGap/2).frame(maxWidth:.infinity,alignment:.leading).textSelection(.enabled).environment(\.layoutDirection,paragraphDirection(block.text)).overlay(alignment:.topLeading){if assistant,direction == .leftToRight,let marker=block.marker{Text(marker).font(PiyaliBrand.productFont(14)).padding(.vertical,lineGap/2).frame(width:16,alignment:.leading).offset(x:-16).accessibilityHidden(true)}}}
    var body:some View{let groups=PracticeFeedbackDocument.groups(text)
        VStack(alignment:.leading,spacing:assistant ? 8:0){ForEach(Array(groups.enumerated()),id:\.element.id){index,group in
            VStack(alignment:.leading,spacing:assistant && group.listID != nil ? 4:0){ForEach(group.blocks){row($0)}}.padding(direction == .rightToLeft ? .trailing:.leading,assistant ? CGFloat(group.listDepth)*16:0).padding(.bottom,assistant && group.listID != nil ? (index == groups.count-1 ? 12:4):(!assistant && group.listID == nil ? paragraphBottom:0))
        }}.accessibilityElement(children:.combine).accessibilityAddTraits(.isStaticText)
    }
}

struct PracticeSpeakerIcon:View {
    var loading=false
    var name="PiSpeakerHighDuotone"
    var size:CGFloat=18
    var body:some View{Group{if loading{PracticeAudioSpinner()}else{PracticeIcon(name:name,size:size)}}.frame(width:size,height:size)}
}

/// Original Chakra xs spinner: 12-point outer diameter, two-point half ring, 0.45-second turn.
struct PracticeAudioSpinner:View {
    var size:CGFloat=12
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotating=false
    var body:some View{Circle().trim(from:0,to:0.5).stroke(style:StrokeStyle(lineWidth:2,lineCap:.butt)).frame(width:size-2,height:size-2).rotationEffect(.degrees(rotating ? 360:0)).frame(width:size,height:size).animation(reduceMotion ? nil:.linear(duration:0.45).repeatForever(autoreverses:false),value:rotating).onAppear{rotating = !reduceMotion}.onChange(of:reduceMotion){_,reduced in rotating = !reduced}.accessibilityHidden(true)}
}
