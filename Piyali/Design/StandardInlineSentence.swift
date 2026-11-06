import SwiftUI
import UIKit

/// TextKit wraps real sentence text around live native drop slots, as the source's inline-flex spans do.
struct StandardInlineSentence:UIViewRepresentable {
    let sentence:String,values:[String?],placeholder:String,dark:Bool,rtl:Bool
    let slot:(Int)->AnyView
    func makeUIView(context:Context)->StandardInlineSentenceView{StandardInlineSentenceView()}
    func updateUIView(_ view:StandardInlineSentenceView,context:Context){view.configure(sentence:sentence,values:values,placeholder:placeholder,dark:dark,rtl:rtl,slot:slot)}
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:StandardInlineSentenceView,context:Context)->CGSize?{uiView.measure(width:proposal.width ?? 280)}
}
final class StandardInlineSentenceView:UIView {
    private let text=UITextView()
    private var slots:[UIHostingController<AnyView>]=[],ranges:[NSRange]=[],sizes:[CGSize]=[]
    override init(frame:CGRect){super.init(frame:frame);text.isEditable=false;text.isSelectable=false;text.isScrollEnabled=false;text.backgroundColor = .clear;text.textContainerInset = .zero;text.textContainer.lineFragmentPadding=0;text.isAccessibilityElement=true;addSubview(text)}
    required init?(coder:NSCoder){fatalError("Programmatic question content")}
    func configure(sentence:String,values:[String?],placeholder:String,dark:Bool,rtl:Bool,slot:(Int)->AnyView){
        let font=UIFont.systemFont(ofSize:18,weight:.medium),tokenFont=UIFont.systemFont(ofSize:14),paragraph=NSMutableParagraphStyle();paragraph.minimumLineHeight=29.25;paragraph.baseWritingDirection=rtl ? .rightToLeft:.leftToRight;paragraph.alignment=rtl ? .right:.left
        let attributes:[NSAttributedString.Key:Any]=[.font:font,.foregroundColor:UIColor(PiyaliBrand(dark:dark).text),.paragraphStyle:paragraph],result=NSMutableAttributedString(),segments=sentence.components(separatedBy:"___")
        ranges=[];sizes=[]
        for(index,segment)in segments.enumerated(){result.append(NSAttributedString(string:segment,attributes:attributes));guard index<segments.count-1 else{continue}
            if index>=values.count{result.append(NSAttributedString(string:"___",attributes:attributes));continue}
            let value=values[index],label=value ?? placeholder,tokenWidth=(label as NSString).size(withAttributes:[.font:tokenFont]).width,width=max(72,tokenWidth+(value == nil ? 16:42)),height:CGFloat=value == nil ? 32:49,attachment=NSTextAttachment();attachment.image=UIGraphicsImageRenderer(size:CGSize(width:1,height:1)).image{_ in};attachment.bounds=CGRect(x:0,y:(font.capHeight-height)/2-2,width:width+8,height:height)
            ranges.append(NSRange(location:result.length,length:1));sizes.append(CGSize(width:width,height:height));result.append(NSAttributedString(attachment:attachment))
        }
        if result.length>0{result.addAttribute(.paragraphStyle,value:paragraph,range:NSRange(location:0,length:result.length))};text.attributedText=result;text.accessibilityLabel=sentence
        while slots.count>values.count{slots.removeLast().view.removeFromSuperview()}
        for index in values.indices{let root=slot(index).environment(\.layoutDirection,.leftToRight).preferredColorScheme(dark ? .dark:.light);if index>=slots.count{let host=UIHostingController(rootView:AnyView(root));host.view.backgroundColor = .clear;slots.append(host);addSubview(host.view)}else{slots[index].rootView=AnyView(root)}}
        invalidateIntrinsicContentSize();setNeedsLayout()
    }
    func measure(width:CGFloat)->CGSize{let width=max(1,width);return CGSize(width:width,height:ceil(text.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude)).height))}
    override func layoutSubviews(){super.layoutSubviews();text.frame=bounds;text.layoutManager.ensureLayout(for:text.textContainer)
        for index in ranges.indices where slots.indices.contains(index){let glyph=text.layoutManager.glyphRange(forCharacterRange:ranges[index],actualCharacterRange:nil),rect=text.layoutManager.boundingRect(forGlyphRange:glyph,in:text.textContainer);slots[index].view.frame=CGRect(x:rect.minX+4,y:rect.maxY-sizes[index].height,width:sizes[index].width,height:sizes[index].height)}
    }
}
