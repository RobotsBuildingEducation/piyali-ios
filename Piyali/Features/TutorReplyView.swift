import SwiftUI

/// Source AlignedBubble: translated text, repeated phrase links and up to eight wrapping cards.
struct TutorReplyView:View {
    let primary:String,secondary:String,target:String,support:String,pairs:JSONValue
    var showSecondary=true,replaying=false
    var replayAvailable=true,showPairCards=true,conversationAppearance=false
    var primaryIdentifier="tutorLatestReply",secondaryIdentifier="tutorTranslation",translateIdentifier="conversationTranslate"
    var translating=false,onTranslate:(()->Void)?=nil
    var archiveHidden=false,onPrimaryFrame:((CGRect)->Void)?=nil
    let onReplay:()->Void
    @Environment(\.colorScheme) private var scheme
    @State private var activeRoot:String?
    @State private var policy=try? TutorReplyPolicy()
    private var dark:Bool{scheme == .dark}
    private var ink:Color{PiyaliBrand.unitColor(dark ? "e5e7eb":"2f261d")}
    private var muted:Color{dark ? .white.opacity(0.8):PiyaliBrand.unitColor("5b4b3a")}
    private var plan:JSONValue{(try? policy?.plan(primary:primary,secondary:secondary,pairs:pairs)) ?? .object(["primary":.array([.string(primary)]),"secondary":.array([.string(secondary)])])}
    private func rtl(_ language:String)->LayoutDirection{["ar","he","fa","ur"].contains(language) ? .rightToLeft:.leftToRight}
    var body:some View {let value=plan
        VStack(alignment:.leading,spacing:0){
            HStack(alignment:.top,spacing:8){
                if replayAvailable {Button(action:onReplay){Group{if replaying{ProgressView().controlSize(.mini)}else{Image(systemName:"speaker.wave.2").font(.system(size:14))}}.frame(width:24,height:24)}.buttonStyle(.plain).disabled(replaying).opacity(0.7).padding(.top,2).accessibilityLabel(EntryCopy.ui(support,"ra_btn_replay")).accessibilityIdentifier("tutorReplay")}
                Text(aligned(value["primary"].array,color:ink)).font(PiyaliBrand.productFont(16)).lineSpacing(max(0,25-UIFont.systemFont(ofSize:16).lineHeight)).padding(.vertical,max(0,25-UIFont.systemFont(ofSize:16).lineHeight)/2).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading).textSelection(.enabled).environment(\.layoutDirection,rtl(target)).accessibilityIdentifier(primaryIdentifier).accessibilityAddTraits(activeRoot != nil ? .isSelected:[]).onGeometryChange(for:CGRect.self,of:{$0.frame(in:.named("conversationArchive"))}){onPrimaryFrame?($0)}
            }
            if showSecondary,!secondary.isEmpty {Text(aligned(value["secondary"].array,color:muted)).font(PiyaliBrand.productFont(12)).lineSpacing(max(0,18-UIFont.systemFont(ofSize:12).lineHeight)).padding(.vertical,max(0,18-UIFont.systemFont(ofSize:12).lineHeight)/2).foregroundStyle(muted).padding(.top,4).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,rtl(support)).accessibilityIdentifier(secondaryIdentifier)}
            if showSecondary,let onTranslate {HStack {Spacer();Button(action:onTranslate){Group {if translating {ProgressView().controlSize(.mini)} else {Image("ConversationTranslate").resizable().renderingMode(.template).frame(width:12,height:12)}}.frame(width:24,height:24)}.buttonStyle(.plain).disabled(translating).accessibilityLabel(EntryCopy.ui(support,"ra_btn_translate")).accessibilityIdentifier(translateIdentifier)}.padding(.top,8)}
            if showSecondary,showPairCards,!value["pairs"].array.isEmpty {TutorPhraseFlow(spacing:12){ForEach(Array(value["pairs"].array.prefix(8).enumerated()),id:\.offset){index,pair in
                let color=PiyaliBrand.unitColor(value["colors"].array.indices.contains(index) ? value["colors"].array[index].string:"91e0ff")
                VStack(alignment:.leading,spacing:4){
                    OnboardingText(text:pair["lhs"].string,size:14,weight:.semibold,lineHeight:19).foregroundStyle(dark ? .white.opacity(0.92):ink).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,rtl(target))
                    OnboardingText(text:pair["rhs"].string,size:10,lineHeight:13).foregroundStyle(muted).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,rtl(support))
                }.padding(.horizontal,12).padding(.vertical,10).padding(1).background(dark ? PiyaliBrand.unitColor("0b1220"):PiyaliBrand.unitColor("fffaf3"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).strokeBorder(color.opacity(dark ? 0.6:0.34))}.shadow(color:dark ? color.opacity(0.12):PiyaliBrand.unitColor("785e3d").opacity(0.06),radius:dark ? 9:8,y:6).accessibilityElement(children:.combine).accessibilityIdentifier("tutorPhrase-\(index)")
            }}.environment(\.layoutDirection,rtl(target)).padding(.top,12)}
        }.opacity(archiveHidden ? 0:1).offset(y:archiveHidden ? 10:0).scaleEffect(archiveHidden ? 0.985:1).allowsHitTesting(!archiveHidden).animation(.easeOut(duration:0.18),value:archiveHidden).padding(12).padding(1).foregroundStyle(ink).frame(maxWidth:.infinity,alignment:.leading)
            .background{if conversationAppearance{ConversationReplySurface(light: !dark)}else if dark{TutorPaperPanel(radius:28,textured:true)}else{RoundedRectangle(cornerRadius:28).fill(PiyaliBrand.unitColor("f1e4d3").opacity(0.98))}}
            .clipShape(RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).strokeBorder(dark ? .white.opacity(0.06):PiyaliBrand.unitColor(conversationAppearance ? "604d38":"8e714f").opacity(conversationAppearance ? 0.16:0.26))}
            .shadow(color:dark ? .black.opacity(0.35):PiyaliBrand.unitColor(conversationAppearance ? "6f5636":"785e3d").opacity(conversationAppearance ? 0.08:0.13),radius:dark ? 14:(conversationAppearance ? 9:19),y:dark ? 14:(conversationAppearance ? 8:18))
            .environment(\.openURL,OpenURLAction{url in guard url.scheme == "tutorphrase" else{return .systemAction};activeRoot=activeRoot == url.host ? nil:url.host;return .handled})
            .onChange(of:primary){_,_ in activeRoot=nil}
    }
    private func aligned(_ chunks:[JSONValue],color:Color)->AttributedString {var result=AttributedString();for chunk in chunks{var part=AttributedString(chunk["token"].string.isEmpty ? chunk.string:chunk["text"].string);let root=chunk["root"].string;if !root.isEmpty{part.link=URL(string:"tutorphrase://"+root);part.foregroundColor=color;if activeRoot == root{part.underlineStyle = .single;part.underlineColor=UIColor(PiyaliBrand.unitColor("91e0ff"))}};result.append(part)};return result}
}

private struct TutorPhraseFlow:Layout {
    let spacing:CGFloat
    private func arrange(_ proposal:ProposedViewSize,_ views:Subviews)->([(CGPoint,CGSize)],CGSize){let width=proposal.width ?? 640;var positions:[(CGPoint,CGSize)]=[],x:CGFloat=0,y:CGFloat=0,row:CGFloat=0,used:CGFloat=0
        for view in views{let ideal=view.sizeThatFits(.unspecified),size=view.sizeThatFits(.init(width:min(min(260,width),ideal.width),height:nil));if x>0,x+size.width>width{used=max(used,x-spacing);x=0;y+=row+spacing;row=0};positions.append((CGPoint(x:x,y:y),size));x+=size.width+spacing;row=max(row,size.height)};used=max(used,max(0,x-spacing));return(positions,CGSize(width:proposal.width ?? used,height:y+row))}
    func sizeThatFits(proposal:ProposedViewSize,subviews:Subviews,cache:inout ())->CGSize{arrange(proposal,subviews).1}
    func placeSubviews(in bounds:CGRect,proposal:ProposedViewSize,subviews:Subviews,cache:inout ()){for(index,item)in arrange(.init(width:bounds.width,height:nil),subviews).0.enumerated(){subviews[index].place(at:CGPoint(x:bounds.minX+item.0.x,y:bounds.minY+item.0.y),proposal:.init(item.1))}}
}

/// Conversation's PAPER_PANEL_SX / MATRIX_PANEL_SX from the web AlignedBubble.
private struct ConversationReplySurface:View {
    let light:Bool
    var body:some View {
        GeometryReader { geometry in
            let extent=max(geometry.size.width,geometry.size.height)
            ZStack {
                LinearGradient(colors:light ? [PiyaliBrand.unitColor("fff9f2"),PiyaliBrand.unitColor("f8f1e8")] : [PiyaliBrand.unitColor("02060e"),PiyaliBrand.unitColor("01030a")],startPoint:.top,endPoint:.bottom)
                RadialGradient(colors:[PiyaliBrand.unitColor(light ? "ac8e6e":"1e40af").opacity(0.12),.clear],center:.init(x:light ? 0.18:0.2,y:0.15),startRadius:0,endRadius:extent*0.42)
                RadialGradient(colors:[PiyaliBrand.unitColor(light ? "d9c0a4":"065f46").opacity(light ? 0.12:0.1),.clear],center:.init(x:0.82,y:light ? 0.2:0.25),startRadius:0,endRadius:extent*0.4)
                if !light { RadialGradient(colors:[PiyaliBrand.unitColor("0f172a").opacity(0.52),.clear],center:.bottom,startRadius:0,endRadius:extent*0.62) }
                Canvas { context,size in
                    var grid=Path()
                    for x in stride(from:CGFloat(0),to:size.width,by:28) {grid.move(to:.init(x:x,y:0));grid.addLine(to:.init(x:x,y:size.height))}
                    for y in stride(from:CGFloat(0),to:size.height,by:28) {grid.move(to:.init(x:0,y:y));grid.addLine(to:.init(x:size.width,y:y))}
                    context.stroke(grid,with:.color(PiyaliBrand.unitColor(light ? "9b8770":"94a3b8").opacity(light ? 0.012:0.025)),lineWidth:1)
                }
            }
        }
    }
}
