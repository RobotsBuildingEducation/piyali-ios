import SwiftUI

/// Source AlignedBubble: translated text, repeated phrase links and up to eight wrapping cards.
struct TutorReplyView:View {
    let primary:String,secondary:String,target:String,support:String,pairs:JSONValue
    var showSecondary=true,replaying=false
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
                Button(action:onReplay){Group{if replaying{ProgressView().controlSize(.mini)}else{Image(systemName:"speaker.wave.2").font(.system(size:14))}}.frame(width:24,height:24)}.buttonStyle(.plain).disabled(replaying).opacity(0.7).padding(.top,2).accessibilityLabel(EntryCopy.ui(support,"ra_btn_replay")).accessibilityIdentifier("tutorReplay")
                Text(aligned(value["primary"].array)).font(PiyaliBrand.productFont(16)).lineSpacing(max(0,25-UIFont.systemFont(ofSize:16).lineHeight)).padding(.vertical,max(0,25-UIFont.systemFont(ofSize:16).lineHeight)/2).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading).textSelection(.enabled).environment(\.layoutDirection,rtl(target)).accessibilityIdentifier("tutorLatestReply").accessibilityAddTraits(activeRoot != nil ? .isSelected:[])
            }
            if showSecondary,!secondary.isEmpty {Text(aligned(value["secondary"].array)).font(PiyaliBrand.productFont(12)).lineSpacing(max(0,18-UIFont.systemFont(ofSize:12).lineHeight)).padding(.vertical,max(0,18-UIFont.systemFont(ofSize:12).lineHeight)/2).foregroundStyle(muted).padding(.top,4).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,rtl(support)).accessibilityIdentifier("tutorTranslation")}
            if showSecondary,!value["pairs"].array.isEmpty {TutorPhraseFlow(spacing:12){ForEach(Array(value["pairs"].array.prefix(8).enumerated()),id:\.offset){index,pair in
                let color=PiyaliBrand.unitColor(value["colors"].array.indices.contains(index) ? value["colors"].array[index].string:"91e0ff")
                VStack(alignment:.leading,spacing:4){
                    OnboardingText(text:pair["lhs"].string,size:14,weight:.semibold,lineHeight:19).foregroundStyle(dark ? .white.opacity(0.92):ink).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,rtl(target))
                    OnboardingText(text:pair["rhs"].string,size:10,lineHeight:13).foregroundStyle(muted).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,rtl(support))
                }.padding(.horizontal,12).padding(.vertical,10).padding(1).background(dark ? PiyaliBrand.unitColor("0b1220"):PiyaliBrand.unitColor("fffaf3"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).strokeBorder(color.opacity(dark ? 0.6:0.34))}.shadow(color:dark ? color.opacity(0.12):PiyaliBrand.unitColor("785e3d").opacity(0.06),radius:dark ? 9:8,y:6).accessibilityElement(children:.combine).accessibilityIdentifier("tutorPhrase-\(index)")
            }}.environment(\.layoutDirection,rtl(target)).padding(.top,12)}
        }.padding(12).padding(1).foregroundStyle(ink).frame(maxWidth:.infinity,alignment:.leading)
            .background{if dark{TutorPaperPanel(radius:28,textured:true)}else{RoundedRectangle(cornerRadius:28).fill(PiyaliBrand.unitColor("f1e4d3").opacity(0.98))}}
            .clipShape(RoundedRectangle(cornerRadius:28)).overlay{RoundedRectangle(cornerRadius:28).strokeBorder(dark ? .white.opacity(0.06):PiyaliBrand.unitColor("8e714f").opacity(0.26))}
            .shadow(color:dark ? .black.opacity(0.35):PiyaliBrand.unitColor("785e3d").opacity(0.13),radius:dark ? 14:19,y:dark ? 14:18)
            .environment(\.openURL,OpenURLAction{url in guard url.scheme == "tutorphrase" else{return .systemAction};activeRoot=activeRoot == url.host ? nil:url.host;return .handled})
            .onChange(of:primary){_,_ in activeRoot=nil}
    }
    private func aligned(_ chunks:[JSONValue])->AttributedString {var result=AttributedString();for chunk in chunks{var part=AttributedString(chunk["token"].string.isEmpty ? chunk.string:chunk["text"].string);let root=chunk["root"].string;if !root.isEmpty{part.link=URL(string:"tutorphrase://"+root);part.foregroundColor=ink;if activeRoot == root{part.underlineStyle = .single;part.underlineColor=UIColor(PiyaliBrand.unitColor("91e0ff"))}};result.append(part)};return result}
}

private struct TutorPhraseFlow:Layout {
    let spacing:CGFloat
    private func arrange(_ proposal:ProposedViewSize,_ views:Subviews)->([(CGPoint,CGSize)],CGSize){let width=proposal.width ?? 640;var positions:[(CGPoint,CGSize)]=[],x:CGFloat=0,y:CGFloat=0,row:CGFloat=0,used:CGFloat=0
        for view in views{let ideal=view.sizeThatFits(.unspecified),size=view.sizeThatFits(.init(width:min(min(260,width),ideal.width),height:nil));if x>0,x+size.width>width{used=max(used,x-spacing);x=0;y+=row+spacing;row=0};positions.append((CGPoint(x:x,y:y),size));x+=size.width+spacing;row=max(row,size.height)};used=max(used,max(0,x-spacing));return(positions,CGSize(width:proposal.width ?? used,height:y+row))}
    func sizeThatFits(proposal:ProposedViewSize,subviews:Subviews,cache:inout ())->CGSize{arrange(proposal,subviews).1}
    func placeSubviews(in bounds:CGRect,proposal:ProposedViewSize,subviews:Subviews,cache:inout ()){for(index,item)in arrange(.init(width:bounds.width,height:nil),subviews).0.enumerated(){subviews[index].place(at:CGPoint(x:bounds.minX+item.0.x,y:bounds.minY+item.0.y),proposal:.init(item.1))}}
}
