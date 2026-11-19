import SwiftUI

/// Original authored completion: one epilogue group, three outlined star slots,
/// score/wave group and the completion owner's action. Maps remain native.
struct RPGCompletionView:View {
    let run:RPGRun
    var tutor=false,automaticExit=false,completing=false
    var completionError:String?
    let onContinue:()->Void
    var onPlayAgain:()->Void = {},onNewWorld:()->Void = {}
    @Environment(\.colorScheme) private var scheme
    @State private var contentHeight:CGFloat=0
    private var light:Bool{scheme != .dark}
    private var ink:Color{light ? PiyaliBrand.unitColor("4b3726"):.white}
    private var paper:Color{light ? PiyaliBrand.unitColor("fffaf1").opacity(0.98):PiyaliBrand.unitColor("0b1220")}
    private var border:Color{PiyaliBrand.unitColor(light ? "e0b474":"ecc94b").opacity(light ? 0.92:1)}
    private var title:String{run.scenario.storyTitle.flatMap{$0.isEmpty ? nil:$0} ?? "Congratulations! You've completed the review."}
    var body:some View {GeometryReader{g in ZStack{
        (light ? PiyaliBrand.unitColor("4c3c28").opacity(0.24):Color.black.opacity(0.8)).ignoresSafeArea()
        ScrollView {contents.padding(32).padding(3).frame(maxWidth:.infinity).background{GeometryReader{geometry in Color.clear.preference(key:RPGCompletionHeight.self,value:geometry.size.height)}}}
            .frame(height:min(max(1,contentHeight),max(1,g.size.height-32))).scrollBounceBehavior(.basedOnSize).scrollIndicators(.hidden)
            .background(paper,in:RoundedRectangle(cornerRadius:12)).clipShape(RoundedRectangle(cornerRadius:12))
            .overlay{RoundedRectangle(cornerRadius:12).strokeBorder(border,lineWidth:3)}.compositingGroup()
            .shadow(color:light ? PiyaliBrand.unitColor("543e24").opacity(0.20):PiyaliBrand.unitColor("ffd700").opacity(0.3),radius:light ? 14:20,y:light ? 14:0)
            .frame(width:cardWidth(available:g.size.width)).padding(.horizontal,16).onPreferenceChange(RPGCompletionHeight.self){if abs(contentHeight-$0)>0.5{contentHeight=$0}}
    }}.accessibilityElement(children:.contain).accessibilityIdentifier("rpgCompletion")}
    private func cardWidth(available:CGFloat)->CGFloat {
        func width(_ text:String,_ size:CGFloat,_ weight:UIFont.Weight = .regular,italic:Bool=false)->CGFloat {
            let base=UIFont.systemFont(ofSize:size,weight:weight),font=italic ? UIFont(descriptor:base.fontDescriptor.withSymbolicTraits(.traitItalic) ?? base.fontDescriptor,size:size):base
            return (text as NSString).size(withAttributes:[.font:font]).width
        }
        if !tutor,run.lessonID == nil,run.tutorial != true{return min(400,max(1,available-32))}
        var widths=[width(title,20,.bold),width("★★★",30)+15,width("100%",18,.bold)]
        if let epilogue=run.scenario.storyEpilogue,!epilogue["target"].string.isEmpty{widths.append(width(epilogue["target"].string,14));widths.append(width(epilogue["support"].string,12,italic:true))}
        if !automaticExit{widths.append(width(RPGArt.shared.copy("continue",lang:run.support),16,.semibold)+34)}
        return min(min(400,max(1,available-32)),ceil(widths.max() ?? 0)+70)
    }
    private var contents:some View {VStack(spacing:16){
        RPGCompletionLabel(text:title,size:20,weight:700,color:light ? ink:PiyaliBrand.unitColor("f6e05e"),lineHeight:30,language:run.support).accessibilityIdentifier("rpgCompletionTitle")
        if let epilogue=run.scenario.storyEpilogue,!epilogue["target"].string.isEmpty {VStack(spacing:4){
            RPGCompletionLabel(text:epilogue["target"].string,size:14,color:ink,lineHeight:21,language:run.target).accessibilityIdentifier("rpgCompletionEpilogue")
            if !epilogue["support"].string.isEmpty{RPGCompletionLabel(text:epilogue["support"].string,size:12,color:light ? PiyaliBrand.unitColor("8a745c"):PiyaliBrand.unitColor("a3b4c9"),lineHeight:18,italic:true,language:run.support).accessibilityIdentifier("rpgCompletionSupport")}
        }}
        RPGCompletionStars(stars:run.stars).frame(height:45).accessibilityElement(children:.ignore).accessibilityLabel("\(run.stars) of 3 stars").accessibilityIdentifier("rpgCompletionStars")
        VStack(spacing:4){
            RPGCompletionLabel(text:"\(Int((Double(run.score)/800*100).rounded()))%",size:18,weight:700,color:ink,lineHeight:27,language:run.support).accessibilityIdentifier("rpgCompletionScore")
            FocusWaveBar(percent:Double(run.score)/8,height:12,background:.white.opacity(0.8),border:PiyaliBrand.unitColor("ededed"),animateFill:true,insetBorder:true).accessibilityIdentifier("rpgCompletionWave")
        }
        if let completionError{Text(completionError).font(PiyaliBrand.productFont(13)).foregroundStyle(.red).accessibilityIdentifier("rpgCompletionSaveError")}
        if !automaticExit {
            if tutor || run.tutorial == true || run.lessonID != nil {
                Button(RPGArt.shared.copy("continue",lang:run.support),action:onContinue).buttonStyle(RPGCompletionButtonStyle(ink:ink)).accessibilityIdentifier(tutor ? "tutorGameComplete":"rpgComplete").disabled(run.claimed || completing)
            }else{HStack(spacing:12){Button(RPGArt.shared.copy("playAgain",lang:run.support),action:onPlayAgain);Button(RPGArt.shared.copy("newWorld",lang:run.support),action:onNewWorld)}.buttonStyle(RPGCompletionButtonStyle(ink:ink))}
        }
    }.foregroundStyle(ink).multilineTextAlignment(.center).environment(\.layoutDirection,.leftToRight)}
}

private struct RPGCompletionHeight:PreferenceKey {static var defaultValue:CGFloat=0;static func reduce(value:inout CGFloat,nextValue:()->CGFloat){value=max(value,nextValue())}}
private struct RPGCompletionButtonStyle:ButtonStyle {
    let ink:Color
    func makeBody(configuration:Configuration)->some View {configuration.label.font(PiyaliBrand.productFont(16,600)).foregroundStyle(ink).padding(.horizontal,16).frame(minWidth:40,minHeight:40).background(configuration.isPressed ? ink.opacity(0.06):.clear,in:Capsule()).overlay{Capsule().strokeBorder(ink,lineWidth:1)}}
}
private struct RPGCompletionLabel:UIViewRepresentable {
    let text:String,size:CGFloat
    var weight=400
    let color:Color,lineHeight:CGFloat
    var italic=false
    let language:String
    func makeUIView(context:Context)->UILabel {let label=UILabel();label.numberOfLines=0;label.isAccessibilityElement=true;label.setContentCompressionResistancePriority(.required,for:.vertical);return label}
    func updateUIView(_ label:UILabel,context:Context){let base=UIFont.systemFont(ofSize:size,weight:weight>=700 ? .bold:weight>=600 ? .semibold:.regular),font=italic ? UIFont(descriptor:base.fontDescriptor.withSymbolicTraits(.traitItalic) ?? base.fontDescriptor.withMatrix(CGAffineTransform(a:1,b:0,c:0.2,d:1,tx:0,ty:0)),size:size):base,paragraph=NSMutableParagraphStyle();paragraph.alignment = .center;paragraph.baseWritingDirection = .natural;paragraph.minimumLineHeight=lineHeight;paragraph.maximumLineHeight=lineHeight
        let value=NSMutableAttributedString(string:text,attributes:[.font:font,.foregroundColor:UIColor(color),.paragraphStyle:paragraph]);if italic{text.enumerateSubstrings(in:text.startIndex...,options:.byComposedCharacterSequences){part,range,_,_ in if part?.unicodeScalars.contains(where:{(0x0600...0x06ff).contains($0.value)||(0x0750...0x077f).contains($0.value)||(0x08a0...0x08ff).contains($0.value)||(0xfb50...0xfdff).contains($0.value)||(0xfe70...0xfeff).contains($0.value)}) == true{value.addAttribute(.font,value:base,range:NSRange(range,in:text))}}};label.attributedText=value;label.accessibilityLabel=text;label.accessibilityLanguage=language;label.invalidateIntrinsicContentSize()}
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UILabel,context:Context)->CGSize?{let width=proposal.width ?? 300;return CGSize(width:width,height:uiView.sizeThatFits(.init(width:width,height:.greatestFiniteMagnitude)).height)}
}
private struct RPGCompletionStars:UIViewRepresentable {
    let stars:Int
    func makeUIView(context:Context)->UILabel {UILabel()}
    func updateUIView(_ label:UILabel,context:Context){let text=NSMutableAttributedString(string:""),paragraph=NSMutableParagraphStyle();paragraph.alignment = .center;paragraph.minimumLineHeight=45;paragraph.maximumLineHeight=45
        for index in 0..<3 {let filled=index<stars,shadow=NSShadow();shadow.shadowColor=UIColor(red:73/255,green:52/255,blue:26/255,alpha:filled ? 0.22:0.22*0.72);shadow.shadowOffset=CGSize(width:0,height:1)
            text.append(NSAttributedString(string:"★",attributes:[.font:UIFont.systemFont(ofSize:30),.foregroundColor:filled ? UIColor(red:246/255,green:224/255,blue:94/255,alpha:1):.clear,.strokeColor:UIColor(red:138/255,green:109/255,blue:59/255,alpha:filled ? 1:0.72),.strokeWidth:filled ? -100.0/30:100.0/30,.kern:5,.paragraphStyle:paragraph,.shadow:shadow]))
        };label.attributedText=text;label.isAccessibilityElement=false}
}
