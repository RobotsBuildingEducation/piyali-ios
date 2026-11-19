import SwiftUI
import QuartzCore

/// Full text reserves its layout while the original 18-ms character wave fades in.
struct RPGDialogueText:UIViewRepresentable {
    let text:String,language:String
    let color:Color
    var size:CGFloat=16,bold=true,animated=false,italic=false
    var lineHeight:CGFloat?=nil
    var weight:Int?=nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeUIView(context:Context)->RPGDialogueLabel{RPGDialogueLabel()}
    func updateUIView(_ view:RPGDialogueLabel,context:Context){view.configure(text:text,language:language,color:UIColor(color),size:size,bold:bold,animated:animated && !reduceMotion,italic:italic,lineHeight:lineHeight,weight:weight)}
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:RPGDialogueLabel,context:Context)->CGSize?{let width=proposal.width ?? 360;let fitted=uiView.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude));return CGSize(width:width,height:fitted.height)}
    static func dismantleUIView(_ view:RPGDialogueLabel,coordinator:()){view.stop()}
}
@MainActor final class RPGDialogueLabel:UILabel {
    private var link:CADisplayLink?,start=0.0,textValue="",ink=UIColor.label,attributes:[NSAttributedString.Key:Any]=[:],ranges:[NSRange]=[]
    private var baseText=NSAttributedString(string:"")
    private var animationEnabled=false,delay=18.0,fade=120.0
    var isAnimating:Bool{link != nil}
    override init(frame:CGRect){super.init(frame:frame);numberOfLines=0;isAccessibilityElement=true;accessibilityTraits = .staticText;setContentCompressionResistancePriority(.required,for:.vertical)}
    required init?(coder:NSCoder){fatalError("init(coder:) is unavailable")}
    func configure(text:String,language:String,color:UIColor,size:CGFloat,bold:Bool,animated:Bool,italic:Bool=false,lineHeight:CGFloat?=nil,weight:Int?=nil){
        let changed=textValue != text || animationEnabled != animated;textValue=text;ink=color;animationEnabled=animated
        let paragraph=NSMutableParagraphStyle();paragraph.minimumLineHeight=lineHeight ?? size*1.5;paragraph.maximumLineHeight=lineHeight ?? size*1.5;paragraph.baseWritingDirection = .natural;paragraph.alignment=language == "ar" ? .right:.left;paragraph.lineBreakMode = .byWordWrapping;paragraph.lineBreakStrategy=[]
        let fontName=weight == 600 ? "DMSans-SemiBold":bold ? "DMSans-Bold":"DMSans-Regular"
        let baseFont=UIFont(name:fontName,size:size) ?? UIFont.systemFont(ofSize:size,weight:bold ? .bold:.regular),font=italic ? UIFont(descriptor:baseFont.fontDescriptor.withSymbolicTraits(.traitItalic) ?? baseFont.fontDescriptor.withMatrix(CGAffineTransform(a:1,b:0,c:0.2,d:1,tx:0,ty:0)),size:size):baseFont
        attributes=[.font:font,.paragraphStyle:paragraph];accessibilityLabel=text;accessibilityLanguage=language
        let value=NSMutableAttributedString(string:text,attributes:attributes)
        ranges=[];text.enumerateSubstrings(in:text.startIndex...,options:.byComposedCharacterSequences){part,range,_,_ in
            let nsRange=NSRange(range,in:text);self.ranges.append(nsRange)
            // WebKit leaves Arabic fallback glyphs upright when synthesizing Latin italics.
            if italic,part?.unicodeScalars.contains(where:{(0x0600...0x06ff).contains($0.value)||(0x0750...0x077f).contains($0.value)||(0x08a0...0x08ff).contains($0.value)||(0xfb50...0xfdff).contains($0.value)||(0xfe70...0xfeff).contains($0.value)}) == true{value.addAttribute(.font,value:baseFont,range:nsRange)}
        };baseText=value
        if changed{stop();start=CACurrentMediaTime()};paint(elapsed:animated ? CACurrentMediaTime()-start:Double.infinity)
        if animated,changed,window != nil{begin()};invalidateIntrinsicContentSize()
    }
    override func didMoveToWindow(){super.didMoveToWindow();if window == nil{stop()}else if animationEnabled{begin()}}
    private func begin(){guard link == nil,!textValue.isEmpty else{return};let motion=(try? RPGDialoguePolicy().run("motion")) ?? .null;delay=motion["charDelayMs"].number>0 ? motion["charDelayMs"].number:18;fade=motion["fadeMilliseconds"].number>0 ? motion["fadeMilliseconds"].number:120;let value=CADisplayLink(target:WeakTick(self),selector:#selector(WeakTick.tick));value.add(to:.main,forMode:.common);link=value}
    fileprivate func tick(){let elapsed=CACurrentMediaTime()-start;paint(elapsed:elapsed);if elapsed>=Double(textValue.utf16.count)*delay/1000+fade/1000{stop()}}
    private func paint(elapsed:Double){let value=NSMutableAttributedString(attributedString:baseText);for r in ranges{let alpha=animationEnabled ? RPGCharacterReveal.opacity(unit:r.location+r.length-1,elapsed:elapsed,delayMilliseconds:delay,fadeMilliseconds:fade):1;value.addAttribute(.foregroundColor,value:ink.withAlphaComponent(alpha),range:r)};attributedText=value}
    func stop(){link?.invalidate();link=nil}
    @MainActor private final class WeakTick:NSObject{weak var owner:RPGDialogueLabel?;init(_ owner:RPGDialogueLabel){self.owner=owner};@objc func tick(){owner?.tick()}}
}
