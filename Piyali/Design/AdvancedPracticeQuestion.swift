import SwiftUI
import UIKit
import CoreTransferable
import UniformTypeIdentifiers

/// Source exercise bodies; grading, saved response and rewards remain owned by the lesson.
struct AdvancedPracticeQuestion:View {
    static let variants:Set<String>=["sentence_detective","dialogue_fork","word_neighborhoods","morphology_forge","listen_difference"]
    let question:PracticeQuestion,response:JSONValue
    let locked:Bool,assistantOpen:Bool,assistantBusy:Bool
    let copy:(String)->String,help:()->Void,listen:()->Void,change:(JSONValue)->Void
    var showHelp=true
    var playing=false
    @Environment(\.colorScheme) private var scheme
    @State private var selectedWord=""
    @State private var dropTarget:String?
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var muted:Color{PiyaliBrand.unitColor(scheme == .dark ? "182031":"efe4d5")}
    private var borderStrong:Color{PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.34:0.24)}
    private var purple:Color{PiyaliBrand.unitColor("805ad5")}
    private var targetRTL:Bool{question.target == "ar"}
    private var targetDirection:LayoutDirection{targetRTL ? .rightToLeft:.leftToRight}
    private var payload:JSONValue{question.payload}
    private var found:Bool{response["tokenIndex"] == payload["incorrectIndex"] && response["tokenIndex"] != .null}
    private var words:[String]{DelightInteraction.wordOrder(payload["groups"].array.flatMap{$0["items"].array.map(\.string)})}
    private var chosen:[Int]{response["pieceIndices"].array.map{Int($0.number)}}
    private var pieces:[String]{question.strings("pieces")}
    private var forged:String{chosen.compactMap{pieces.indices.contains($0) ? pieces[$0]:nil}.joined()}
    var body:some View {
        VStack(alignment:.leading,spacing:20) {
            header
            switch question.variant {
            case "sentence_detective":detective
            case "dialogue_fork":
                HStack(spacing:12){audio(size:32);OnboardingText(text:payload["line"].string,size:20,weight:.semibold,lineHeight:30).frame(maxWidth:.infinity,alignment:.leading)}.padding(.vertical,4).environment(\.layoutDirection,targetDirection)
                options
            case "listen_difference":
                Button(action:listen){HStack(spacing:8){PracticeIcon(name:"FiVolume2",size:22);Text(copy(playing ? "playingAudio":"playAudio")).font(PiyaliBrand.productFont(16,600))}.frame(maxWidth:.infinity,minHeight:56).foregroundStyle(brand.questionTool).background(brand.surface,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(brand.questionTool.opacity(0.22))}}.buttonStyle(DelightButtonStyle()).accessibilityIdentifier("typedPracticeListen")
                options
            case "word_neighborhoods":neighborhoods
            case "morphology_forge":forge
            default:EmptyView()
            }
        }.padding(17).frame(maxWidth:.infinity,alignment:.leading).background(brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(brand.border).padding(0.5)}.shadow(color:.black.opacity(scheme == .dark ? 0.12:0.04),radius:9,y:8).foregroundStyle(brand.text).accessibilityElement(children:.contain).accessibilityIdentifier("typedQuestionPrompt")
    }
    private var header:some View {
        VStack(alignment:.leading,spacing:4){HStack(spacing:8){OnboardingText(text:copy("title"),size:20,weight:.heavy,lineHeight:30);Spacer(minLength:8);if showHelp{PracticeToolButton(active:assistantOpen,action:help){PracticeIcon(name:"MdOutlineSupportAgent")}.disabled(assistantBusy).accessibilityLabel(copy("askForHelp")).accessibilityIdentifier("typedPracticeHelp")}};if question.variant != "sentence_detective"{OnboardingText(text:copy("instruction"),size:14,lineHeight:21).foregroundStyle(brand.secondary)}}
    }
    private func audio(size:CGFloat)->some View {PracticeToolButton(active:playing,size:size,action:listen){PracticeIcon(name:"FiVolume2",size:16)}.disabled(locked).accessibilityLabel(copy("playAudio")).accessibilityIdentifier("typedPracticeListen")}
    private var options:some View {
        VStack(spacing:12){ForEach(Array(question.strings("options").enumerated()),id:\.offset){index,text in
            let selected=response["selectedIndex"] == .number(Double(index))
            Button{change(.object(["selectedIndex":.number(Double(index))]))}label:{HStack(alignment:.top,spacing:12){ZStack{Circle().fill(selected ? brand.questionChoice:.clear);Circle().strokeBorder(selected ? brand.questionChoice:borderStrong,lineWidth:2);if selected{Text("✓").font(PiyaliBrand.productFont(12,800)).foregroundStyle(.white)}}.frame(width:24,height:24);OnboardingText(text:text,size:16,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading)}.padding(18).background(selected ? brand.questionChoiceBackground:brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(selected ? brand.questionChoice:brand.border,lineWidth:2).padding(1)}.opacity(locked && !selected ? 0.72:1)}.buttonStyle(DelightButtonStyle()).disabled(locked).accessibilityIdentifier("typedChoice-\(index)").accessibilityValue(selected ? "Selected":"Not selected").accessibilityAddTraits(selected ? .isSelected:[])
        }}.environment(\.layoutDirection,targetDirection)
    }
    @ViewBuilder private var detective:some View {
        if !found {OnboardingText(text:copy("findTitle")+(["ja","zh"].contains(question.support) ? "":" ")+copy("findHelp"),size:14,lineHeight:21).foregroundStyle(brand.secondary)}
        DelightWrapLayout(spacing:8,centered:true,rtl:targetRTL){ForEach(Array(question.strings("tokens").enumerated()),id:\.offset){index,word in
            let rejected=response["rejectedTokenIndices"].array.contains(.number(Double(index))),confirmed=response["tokenIndex"] == .number(Double(index))
            Button{change(DelightInteraction.detective(question:payload,response:response,index:index,locked:locked))}label:{HStack(spacing:8){Text(word);if confirmed{Text("✓").accessibilityHidden(true)}}.font(PiyaliBrand.productFont(16,600)).padding(.horizontal,17).frame(minHeight:44).foregroundStyle(confirmed || rejected ? brand.text:.white).background(confirmed ? PiyaliBrand.unitColor("319795").opacity(0.14):rejected ? brand.questionError.opacity(scheme == .dark ? 0.14:0.1):purple,in:Capsule()).overlay{Capsule().stroke(confirmed ? PiyaliBrand.unitColor("319795"):rejected ? brand.questionError:purple)}}.buttonStyle(DelightButtonStyle()).disabled(locked || found || rejected).accessibilityIdentifier("detectiveToken-\(index)").accessibilityValue(confirmed ? "Confirmed":rejected ? "Rejected":"Available")
        }}.padding(.vertical,12).environment(\.layoutDirection,targetDirection)
        if found {
            VStack(alignment:.leading,spacing:12){OnboardingText(text:copy("chooseRepair"),size:14,lineHeight:21).foregroundStyle(brand.secondary)
                DelightWrapLayout(spacing:8,rtl:targetRTL){ForEach(Array(question.strings("replacements").enumerated()),id:\.offset){index,word in
                    let selected=response["replacement"].string == word
                    Button{change(DelightInteraction.repair(question:payload,response:response,word:word,locked:locked))}label:{Text(word).font(PiyaliBrand.productFont(16,600)).padding(.horizontal,17).frame(minHeight:44).foregroundStyle(.white).background(PiyaliBrand.unitColor(selected ? "2c7a7b":"319795"),in:Capsule()).overlay{Capsule().stroke(PiyaliBrand.unitColor(selected ? "285e61":"319795"))}}.buttonStyle(DelightButtonStyle()).disabled(locked).accessibilityIdentifier("detectiveRepair-\(index)").accessibilityValue(selected ? "Selected":"Not selected")
                }}.environment(\.layoutDirection,targetDirection)
                if !response["replacement"].string.isEmpty{OnboardingText(text:repairedSentence,size:18,weight:.bold,lineHeight:27).frame(maxWidth:.infinity,alignment:.leading).padding(13).background(brand.surface,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(brand.border)}.environment(\.layoutDirection,targetDirection).accessibilityIdentifier("detectivePreview").padding(.top,4)}
            }.padding(17).background(muted,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.questionChoice)}
        }
    }
    private var repairedSentence:String {var tokens=question.strings("tokens");let i=Int(payload["incorrectIndex"].number);if tokens.indices.contains(i){tokens[i]=response["replacement"].string};return tokens.joined(separator:payload["joiner"].string)}
    private var neighborhoods:some View {
        Group {
            DelightWrapLayout(spacing:10,rtl:targetRTL){ForEach(Array(words.enumerated()),id:\.offset){index,word in
                if response["assignments"][word] == .null {
                    Button{selectedWord=selectedWord == word ? "":word}label:{pieceLabel(word,selected:selectedWord == word,placed:false)}.buttonStyle(DelightButtonStyle()).disabled(locked).modifier(PracticeScopedDrag(item:dragItem(index),enabled:!locked)).accessibilityIdentifier("neighborhoodWord-\(index)").accessibilityValue(selectedWord == word ? "Selected":"Not selected")
                }
            }}.padding(18).frame(maxWidth:.infinity,minHeight:86,alignment:.topLeading).background(muted,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(dropTarget == "bank" ? PiyaliBrand.unitColor("b794f4"):selectedWord.isEmpty ? borderStrong:PiyaliBrand.unitColor("9f7aea"),style:StrokeStyle(lineWidth:2,dash:dropTarget == "bank" ? []:[5]))}.environment(\.layoutDirection,targetDirection).accessibilityElement(children:.contain).accessibilityIdentifier("neighborhoodBank").dropDestination(for:PracticeDragItem.self){tokens,_ in dropWord(tokens,group:nil)}isTargeted:{dropTarget=$0 ? "bank":nil}
            VStack(spacing:14){ForEach(Array(payload["groups"].array.enumerated()),id:\.offset){index,group in bucket(group,index:index)}}
        }
    }
    private func bucket(_ group:JSONValue,index:Int)->some View {
        ZStack(alignment:.topLeading){
            Button{assign(selectedWord,group:index)}label:{Color.clear.contentShape(Rectangle())}.buttonStyle(DelightButtonStyle()).disabled(locked || selectedWord.isEmpty).accessibilityHidden(true)
            VStack(alignment:.leading,spacing:12){Button{assign(selectedWord,group:index)}label:{OnboardingText(text:group["label"].string,size:16,weight:.heavy,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading)}.buttonStyle(DelightButtonStyle()).disabled(locked || selectedWord.isEmpty).accessibilityIdentifier("neighborhoodGroup-\(index)")
                DelightWrapLayout(spacing:8,rtl:targetRTL){
                    ForEach(Array(words.enumerated()),id:\.offset){wordIndex,word in
                        if response["assignments"][word] == .number(Double(index)) {Button{returnWord(word)}label:{OnboardingText(text:word,size:14,weight:.semibold,lineHeight:21).padding(.horizontal,13).padding(.vertical,7).background(muted,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(borderStrong)}}.buttonStyle(DelightButtonStyle()).disabled(locked).modifier(PracticeScopedDrag(item:dragItem(wordIndex),enabled:!locked)).accessibilityIdentifier("neighborhoodPlaced-\(wordIndex)").accessibilityHint(copy("tapToReturn"))}
                    }
                    if !words.contains(where:{response["assignments"][$0] == .number(Double(index))}) {Text(selectedWord.isEmpty ? copy("dropPlaceholder"):copy("tapToPlace").replacingOccurrences(of:"{word}",with:selectedWord)).font(PiyaliBrand.productFont(12).italic()).foregroundStyle(brand.secondary).padding(.vertical,8).allowsHitTesting(false)}
                }.frame(maxWidth:.infinity,minHeight:50,alignment:.topLeading).environment(\.layoutDirection,targetDirection)
            }.padding(18)
        }.frame(maxWidth:.infinity,minHeight:150,alignment:.topLeading).background(dropTarget == "group-\(index)" ? purple.opacity(0.08):brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(dropTarget == "group-\(index)" ? PiyaliBrand.unitColor("b794f4"):selectedWord.isEmpty ? brand.border:PiyaliBrand.unitColor("9f7aea"),lineWidth:2)}.dropDestination(for:PracticeDragItem.self){tokens,_ in dropWord(tokens,group:index)}isTargeted:{dropTarget=$0 ? "group-\(index)":nil}
    }
    private func pieceLabel(_ word:String,selected:Bool,placed:Bool)->some View{OnboardingText(text:word,size:16,weight:selected ? .bold:.semibold,lineHeight:24).padding(.horizontal,15.5).padding(.vertical,9.5).foregroundStyle(selected ? .white:brand.text).background(selected ? purple:placed ? muted:brand.surface,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(selected ? PiyaliBrand.unitColor("9f7aea"):brand.border,lineWidth:1.5)}.shadow(color:purple.opacity(selected ? 0.16:0.04),radius:selected ? 4:1,y:2)}
    private var forge:some View {
        Group {
            ForgeSentenceText(sentence:payload["sentence"].string,word:forged,dark:scheme == .dark,rtl:targetRTL).frame(maxWidth:.infinity).padding(21.5).background(brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border,lineWidth:1.5)}.environment(\.layoutDirection,targetDirection).accessibilityIdentifier("forgeSentence")
            DelightWrapLayout(spacing:8,centered:true,rtl:targetRTL){ForEach(Array(chosen.enumerated()),id:\.offset){position,index in
                if pieces.indices.contains(index){Button{change(DelightInteraction.forge(question:payload,response:response,piece:index,toForge:false,locked:locked))}label:{pieceLabel(pieces[index],selected:true,placed:true)}.buttonStyle(DelightButtonStyle()).disabled(locked).modifier(PracticeScopedDrag(item:dragItem(index),enabled:!locked)).accessibilityIdentifier("forgeChosen-\(position)").accessibilityHint(copy("tapToRemove"))}
            };if chosen.isEmpty {Text(copy("emptyForge")).font(PiyaliBrand.productFont(12).italic()).foregroundStyle(brand.secondary).padding(.vertical,8)}}.padding(18).frame(maxWidth:.infinity,minHeight:88).background(dropTarget == "forge" ? purple.opacity(0.08):muted,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(dropTarget == "forge" ? PiyaliBrand.unitColor("b794f4"):chosen.isEmpty ? borderStrong:PiyaliBrand.unitColor("9f7aea"),style:StrokeStyle(lineWidth:2,dash:dropTarget == "forge" ? []:[5]))}.environment(\.layoutDirection,targetDirection).accessibilityElement(children:.contain).accessibilityIdentifier("forgeTray").dropDestination(for:PracticeDragItem.self){tokens,_ in dropPiece(tokens,toForge:true)}isTargeted:{dropTarget=$0 ? "forge":nil}
            DelightWrapLayout(spacing:10,centered:true,rtl:targetRTL){ForEach(Array(pieces.enumerated()),id:\.offset){index,piece in
                if !chosen.contains(index){Button{change(DelightInteraction.forge(question:payload,response:response,piece:index,toForge:true,locked:locked))}label:{pieceLabel(piece,selected:false,placed:true)}.buttonStyle(DelightButtonStyle()).disabled(locked).modifier(PracticeScopedDrag(item:dragItem(index),enabled:!locked)).accessibilityIdentifier("forgePiece-\(index)")}
            };if chosen.count == pieces.count {Text(copy("allPiecesUsed")).font(PiyaliBrand.productFont(12).italic()).foregroundStyle(brand.secondary).padding(.vertical,8)}}.padding(17.5).frame(maxWidth:.infinity,minHeight:58).background(dropTarget == "bank" ? purple.opacity(0.08):brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(dropTarget == "bank" ? PiyaliBrand.unitColor("b794f4"):brand.border,lineWidth:1.5)}.environment(\.layoutDirection,targetDirection).accessibilityElement(children:.contain).accessibilityIdentifier("forgeBank").dropDestination(for:PracticeDragItem.self){tokens,_ in dropPiece(tokens,toForge:false)}isTargeted:{dropTarget=$0 ? "bank":nil}
        }
    }
    private func dragItem(_ index:Int)->PracticeDragItem{.init(questionID:question.id,index:index)}
    private func draggedIndex(_ items:[PracticeDragItem],count:Int)->Int?{PracticeDragItem.matchingIndex(items,questionID:question.id,count:count,locked:locked)}
    private func assign(_ word:String,group:Int){guard !word.isEmpty,!locked else{return};change(DelightInteraction.neighborhood(question:payload,response:response,word:word,group:group,locked:locked));if selectedWord == word{selectedWord=""}}
    private func returnWord(_ word:String){guard !locked else{return};change(DelightInteraction.neighborhood(question:payload,response:response,word:word,group:nil,locked:locked));if selectedWord == word{selectedWord=""}}
    private func dropWord(_ tokens:[PracticeDragItem],group:Int?)->Bool {guard let index=draggedIndex(tokens,count:words.count)else{return false};let word=words[index];if let group{if response["assignments"][word] == .number(Double(group)){return true};assign(word,group:group)}else{if response["assignments"][word] == .null{return true};returnWord(word)};return true}
    private func dropPiece(_ tokens:[PracticeDragItem],toForge:Bool)->Bool {guard let index=draggedIndex(tokens,count:pieces.count)else{return false};if chosen.contains(index) == toForge{return true};change(DelightInteraction.forge(question:payload,response:response,piece:index,toForge:toForge,locked:locked));return true}
}
struct PracticeDragItem:Codable,Transferable {
    let questionID:UUID,index:Int
    static var transferRepresentation:some TransferRepresentation{CodableRepresentation(contentType:UTType(importedAs:"app.piyali.practice-token",conformingTo:.data))}
    static func matchingIndex(_ items:[Self],questionID:UUID,count:Int,locked:Bool)->Int?{guard !locked,items.count == 1,items[0].questionID == questionID,(0..<count).contains(items[0].index)else{return nil};return items[0].index}
}
struct PracticeScopedDrag:ViewModifier {
    let item:PracticeDragItem,enabled:Bool
    @ViewBuilder func body(content:Content)->some View{if enabled{content.draggable(item)}else{content}}
}
struct DelightWrapLayout:Layout {
    var spacing:CGFloat=8,centered=false,rtl=false
    private func rows(_ subviews:Subviews,width:CGFloat)->[[Int]]{var rows:[[Int]]=[[]],used:CGFloat=0;for index in subviews.indices{let w=subviews[index].sizeThatFits(.unspecified).width;if !rows[rows.count-1].isEmpty,used+spacing+w>width{rows.append([]);used=0};if !rows[rows.count-1].isEmpty{used+=spacing};rows[rows.count-1].append(index);used+=w};return rows}
    func sizeThatFits(proposal:ProposedViewSize,subviews:Subviews,cache:inout())->CGSize{let width=proposal.width ?? 320,groups=rows(subviews,width:width),height=groups.map{$0.map{subviews[$0].sizeThatFits(.unspecified).height}.max() ?? 0}.reduce(0,+)+CGFloat(max(0,groups.count-1))*spacing;return CGSize(width:width,height:height)}
    func placeSubviews(in bounds:CGRect,proposal:ProposedViewSize,subviews:Subviews,cache:inout()){var y=bounds.minY;for row in rows(subviews,width:bounds.width){let sizes=row.map{subviews[$0].sizeThatFits(.unspecified)},width=sizes.map(\.width).reduce(0,+)+CGFloat(max(0,row.count-1))*spacing,height=sizes.map(\.height).max() ?? 0;var x=centered ? max(0,(bounds.width-width)/2):0;for(index,size)in zip(row,sizes){subviews[index].place(at:CGPoint(x:bounds.minX+(rtl ? bounds.width-x-size.width:x),y:y),proposal:ProposedViewSize(width:size.width,height:size.height));x+=size.width+spacing};y+=height+spacing}}
}

/// An inline attachment preserves the web's padded, underlined live word inside a wrapping sentence.
private struct ForgeSentenceText:UIViewRepresentable {
    let sentence:String,word:String,dark:Bool,rtl:Bool
    @ScaledMetric private var fontSize:CGFloat=18
    func makeUIView(context:Context)->UILabel{let label=UILabel();label.numberOfLines=0;label.lineBreakMode = .byWordWrapping;label.setContentCompressionResistancePriority(.defaultLow,for:.horizontal);label.isAccessibilityElement=true;return label}
    func updateUIView(_ label:UILabel,context:Context){
        let brand=PiyaliBrand(dark:dark),font=UIFont.systemFont(ofSize:fontSize,weight:.semibold),bold=UIFont.systemFont(ofSize:fontSize,weight:.bold),line=fontSize*1.625,scale=fontSize/18,text=word.isEmpty ? "___":word,textSize=(text as NSString).size(withAttributes:[.font:bold]),span=max(70*scale,textSize.width+20*scale),height=line+6.5*scale,width=span+12*scale
        let image=UIGraphicsImageRenderer(size:CGSize(width:width,height:height)).image{context in
            let rect=CGRect(x:6*scale,y:0,width:span,height:height)
            if !word.isEmpty{UIColor(PiyaliBrand.unitColor("805ad5").opacity(0.08)).setFill();UIBezierPath(roundedRect:rect,cornerRadius:6*scale).fill()}
            let c=context.cgContext;c.setStrokeColor(UIColor(PiyaliBrand.unitColor(word.isEmpty ? "b794f4":"9f7aea")).cgColor);c.setLineWidth(2.5*scale);c.setLineCap(.round);c.move(to:CGPoint(x:7.25*scale,y:height-1.25*scale));c.addLine(to:CGPoint(x:width-7.25*scale,y:height-1.25*scale));c.strokePath()
            (text as NSString).draw(at:CGPoint(x:6*scale+(span-textSize.width)/2,y:2*scale+(line-bold.lineHeight)/2),withAttributes:[.font:bold,.foregroundColor:UIColor(word.isEmpty ? brand.muted:PiyaliBrand.unitColor("6b46c1"))])
        }
        let paragraph=NSMutableParagraphStyle();paragraph.alignment = .center;paragraph.minimumLineHeight=line;paragraph.baseWritingDirection=rtl ? .rightToLeft:.leftToRight
        let parts=sentence.components(separatedBy:"___"),value=NSMutableAttributedString(string:parts.first ?? "",attributes:[.font:font,.foregroundColor:UIColor(brand.text),.paragraphStyle:paragraph]),attachment=NSTextAttachment();attachment.image=image;attachment.bounds=CGRect(x:0,y:-(abs(bold.descender)+4.5*scale),width:width,height:height)
        value.append(NSAttributedString(attachment:attachment));value.append(NSAttributedString(string:parts.dropFirst().joined(separator:"___"),attributes:[.font:font,.foregroundColor:UIColor(brand.text),.paragraphStyle:paragraph]));value.addAttribute(.paragraphStyle,value:paragraph,range:NSRange(location:0,length:value.length));label.attributedText=value;label.accessibilityLabel=(parts.first ?? "")+text+parts.dropFirst().joined(separator:"___")
    }
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UILabel,context:Context)->CGSize?{let width=proposal.width ?? 320;uiView.preferredMaxLayoutWidth=width;let size=uiView.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude));return CGSize(width:width,height:ceil(size.height))}
}

private struct DelightButtonStyle:ButtonStyle {func makeBody(configuration:Configuration)->some View{configuration.label}}
