import SwiftUI

struct LandingDemoBubble:UIViewRepresentable {
    let text:String,language:String,identifier:String
    let color:Color
    final class Coordinator {var text="";var color:UIColor?}
    func makeCoordinator()->Coordinator {Coordinator()}
    func makeUIView(context:Context)->UITextView {
        let view=UITextView();view.isEditable=false;view.isSelectable=false;view.showsVerticalScrollIndicator=true;view.textContainer.lineFragmentPadding=0;view.textContainerInset=UIEdgeInsets(top:11,left:17,bottom:11,right:17);view.semanticContentAttribute = .forceLeftToRight;view.backgroundColor = .clear;view.accessibilityIdentifier=identifier;view.setContentCompressionResistancePriority(.defaultLow,for:.horizontal);return view
    }
    func updateUIView(_ view:UITextView,context:Context) {
        let ink=UIColor(color).resolvedColor(with:view.traitCollection)
        guard context.coordinator.text != text || context.coordinator.color?.isEqual(ink) != true else {return}
        context.coordinator.text=text;context.coordinator.color=ink
        let paragraph=NSMutableParagraphStyle();paragraph.minimumLineHeight=18.72;paragraph.maximumLineHeight=18.72;paragraph.baseWritingDirection = .leftToRight
        view.attributedText=NSAttributedString(string:text,attributes:[.font:UIFont(name:"DMSans-Regular",size:12.48) ?? UIFont.systemFont(ofSize:12.48),.foregroundColor:ink,.paragraphStyle:paragraph]);view.accessibilityLabel=text;view.accessibilityLanguage=language
    }
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UITextView,context:Context)->CGSize? {
        let maxWidth=max(40,(proposal.width ?? 300)*0.92),rect=uiView.attributedText.boundingRect(with:CGSize(width:maxWidth-34,height:.greatestFiniteMagnitude),options:[.usesLineFragmentOrigin,.usesFontLeading],context:nil),height=ceil(rect.height)+22
        uiView.isScrollEnabled=height>100
        return CGSize(width:min(maxWidth,ceil(rect.width)+34),height:min(100,height))
    }
}
struct LandingVoiceWave:View {
    let level:Double
    let color:Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var levels=Array(repeating:0.0,count:9)
    var body:some View {
        TimelineView(.animation(minimumInterval:1/40,paused:reduceMotion)) {time in
            Canvas {context,size in
                for i in 0..<9 {
                    let base=[13.0,28,21,13][i%4],height=base*(0.28+levels[i]*1.05),rect=CGRect(x:Double(i)*7,y:(35-height)/2,width:4,height:height)
                    context.fill(Path(roundedRect:rect,cornerRadius:2),with:.color(color.opacity(0.65+levels[i]*0.35)))
                }
            }.onChange(of:time.date){_,_ in for i in 0..<9 {let target=min(1,max(0,level)*[0.85,1.25,1.05,0.75][i%4]);levels[i]=target>levels[i] ? levels[i]+(target-levels[i])*0.7 : levels[i]*0.8}}
        }.frame(width:60,height:35).accessibilityHidden(true)
    }
}
