import SwiftUI

struct StandardPracticeQuestion:View {
    static let variants:Set<String>=["fill","mc","ma","match"]
    static let keyboard=(try? WritingKeyboard()) ?? WritingKeyboard(data:.null)
    let run:PracticeRun,locked:Bool,assistantOpen:Bool,assistantBusy:Bool,playing:Bool
    var synthesizing=false
    var synthesizingWord:Int?=nil
    let help:()->Void,listen:(String,Int?)->Void,change:(JSONValue)->Void
    @Binding var keyboardOpen:Bool
    var focus:FocusState<Bool>.Binding
    @Environment(\.colorScheme) private var scheme
    @State private var dropTarget:String?
    private var q:PracticeQuestion{run.question}
    private var state:StandardPracticeInteraction.State{StandardPracticeInteraction.state(run)}
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var muted:Color{PiyaliBrand.unitColor(scheme == .dark ? "182031":"efe4d5")}
    private var base:Color{PiyaliBrand.unitColor(scheme == .dark ? "0b1220":"fdf9f2")}
    private var strong:Color{PiyaliBrand.unitColor(scheme == .dark ? "94a3b8":"604d38").opacity(scheme == .dark ? 0.34:0.24)}
    private var slots:Bool{StandardPracticeInteraction.usesSlots(q)}
    private var targetDirection:LayoutDirection{q.target == "ar" ? .rightToLeft:.leftToRight}
    private func copy(_ key:String)->String{EntryCopy.ui(q.support,key)}
    var body:some View {
        Group{if q.kind == "match"{matching}else{
            VStack(alignment:.leading,spacing:q.kind == "fill" ? 16:12){
                header
                if q.kind == "fill" {
                    TextField(copy(q.module == .grammar ? "grammar_input_placeholder_answer":"vocab_input_placeholder_word"),text:Binding(get:{run.correct == true ? "":run.response["text"].string},set:{change(run.response.setting("text",.string($0)))}),prompt:Text(copy(q.module == .grammar ? "grammar_input_placeholder_answer":"vocab_input_placeholder_word")).foregroundStyle(brand.muted)).font(PiyaliBrand.productFont(16)).padding(.horizontal,17).frame(height:40).background(Color.clear,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(focus.wrappedValue ? PiyaliBrand.unitColor("9f7aea"):PiyaliBrand.unitColor(scheme == .dark ? "cbd5e1":"433528"),lineWidth:focus.wrappedValue ? 2:1)}.focused(focus).disabled(locked).opacity(locked && run.correct != true ? 0.4:1).autocorrectionDisabled().environment(\.layoutDirection,targetDirection).accessibilityIdentifier("typedPracticeAnswer")
                    if keyboardOpen,Self.keyboard.supported(q.target){WritingVirtualKeyboard(language:q.target,support:q.support,keyboard:Self.keyboard,onKey:{key in guard !locked else{return};change(run.response.setting("text",.string(WritingKeyboard.press(key,text:run.response["text"].string,disabled:false))))},onClose:{keyboardOpen=false})}
                }else if slots{choiceBank}else{choiceCards.padding(.top,16)}
            }
        }}.foregroundStyle(brand.text).accessibilityElement(children:.contain).accessibilityIdentifier("typedQuestionPrompt")
    }
    private var header:some View {
        VStack(alignment:.leading,spacing:12){title(copy(q.kind == "mc" ? "vocab_mc_instruction":q.kind == "ma" ? "vocab_ma_instruction":"vocab_btn_fill"))
            HStack(alignment:.top,spacing:12){StandardQuestionTool(active:synthesizing,action:{focus.wrappedValue=false;listen(q.audioText,nil)}){PracticeSpeakerIcon(loading:synthesizing,size:18)}.accessibilityLabel(copy("vocab_listen_question")).accessibilityIdentifier("typedPracticeListen").accessibilityValue(synthesizing ? copy("generic_loading"):"")
                if slots{StandardInlineSentence(sentence:q.questionText,values:state.slots.map{$0.flatMap{run.bank.indices.contains($0) ? run.bank[$0]:nil}},placeholder:copy("practice_drag_drop_slot_placeholder"),dark:scheme == .dark,rtl:q.target == "ar",slot:{AnyView(inlineSlot($0))}).frame(maxWidth:.infinity,alignment:.leading)}
                else{OnboardingText(text:q.questionText,size:18,weight:.medium,lineHeight:29.25).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,targetDirection)}
            }
        }.padding(21).background(brand.surface,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(brand.border)}.compositingGroup().shadow(color:.black.opacity(scheme == .dark ? 0.12:0.04),radius:9,y:8)
    }
    private func title(_ text:String)->some View{HStack(spacing:8){OnboardingText(text:text,size:20,weight:.bold,lineHeight:30).frame(maxWidth:.infinity,alignment:.leading);if !q.options["isFinalQuiz"].boolean{StandardQuestionTool(active:assistantOpen,action:{focus.wrappedValue=false;help()}){PracticeIcon(name:"MdOutlineSupportAgent",size:18)}.disabled(assistantBusy).accessibilityLabel(copy("vocab_ask_assistant")).accessibilityIdentifier("typedPracticeHelp")}}}
    private var choiceCards:some View {
        VStack(spacing:12){ForEach(Array(run.bank.enumerated()),id:\.offset){index,word in
            let selected=run.response["indices"].array.contains(.number(Double(index))),multi=q.kind == "ma",accent=multi ? PiyaliBrand.unitColor(scheme == .dark ? "5eead4":"0f766e"):brand.questionChoice,color=multi ? PiyaliBrand.unitColor(scheme == .dark ? "2dd4bf":"0f766e"):brand.questionChoice
            Button{guard !locked else{return};var values=run.response["indices"].array;if multi{values=selected ? values.filter{$0 != .number(Double(index))}:values+[.number(Double(index))]}else{values=[.number(Double(index))]};change(run.response.setting("indices",.array(values)))}label:{HStack(spacing:12){
                ZStack{if multi{RoundedRectangle(cornerRadius:6).fill(selected ? accent:.clear).overlay{RoundedRectangle(cornerRadius:6).stroke(selected ? accent:strong,lineWidth:2)}}else{Circle().fill(selected ? accent:.clear).overlay{Circle().stroke(selected ? accent:strong,lineWidth:2)}};if selected{if multi{Text("✓").font(PiyaliBrand.productFont(12,700)).foregroundStyle(.white)}else{Circle().fill(.white).frame(width:8,height:8)}}}.frame(width:20,height:20)
                OnboardingText(text:word,size:16,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,targetDirection)
            }.padding(.horizontal,18).padding(.vertical,14).frame(maxWidth:.infinity,alignment:.leading).background(selected ? color.opacity(scheme == .dark ? 0.18:0.1):brand.surface,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(selected ? accent:brand.border,lineWidth:2)}}.buttonStyle(StandardButtonStyle()).disabled(locked).accessibilityIdentifier("typedChoice-\(index)").accessibilityValue(selected ? "Selected":"Not selected").accessibilityAddTraits(selected ? .isSelected:[])
        }}
    }
    private var choiceBank:some View {
        DelightWrapLayout(spacing:12,rtl:q.support == "ar"){ForEach(state.bank,id:\.self){index in token(index,placed:false){save(StandardPracticeInteraction.tap(kind:q.kind,state:state,index:index,choices:run.bank))}.accessibilityIdentifier("typedWord-\(index)").dropDestination(for:PracticeDragItem.self){items,_ in drop(items,slot:nil,position:state.bank.firstIndex(of:index))}}}.environment(\.layoutDirection,.leftToRight).padding(11.5).frame(maxWidth:.infinity,minHeight:45,alignment:.topLeading).background(dropTarget == "bank" ? PiyaliBrand.unitColor("805ad5").opacity(0.08):.clear,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(dropTarget == "bank" ? PiyaliBrand.unitColor("b794f4"):.clear,lineWidth:1.5)}.accessibilityElement(children:.contain).accessibilityIdentifier("standardBank").dropDestination(for:PracticeDragItem.self){items,_ in drop(items,slot:nil)}isTargeted:{dropTarget=$0 ? "bank":nil}
    }
    private func inlineSlot(_ index:Int)->some View {
        let item=state.slots.indices.contains(index) ? state.slots[index]:nil
        return Group{if let item{token(item,placed:true){if q.module == .vocabulary{save(StandardPracticeInteraction.returnSlot(kind:q.kind,state:state,slot:index))}}.accessibilityIdentifier("typedSelected-\(index)").accessibilityAction(named:Text(copy("vocab_dnd_bank"))){returnByDrag(index)}}else{Text(copy("practice_drag_drop_slot_placeholder")).font(PiyaliBrand.productFont(14)).foregroundStyle(brand.text.opacity(0.7)).lineLimit(1)}}.padding(.horizontal,8).padding(.vertical,4).padding(.bottom,2).frame(minWidth:72,minHeight:32).background(dropTarget == "slot-\(index)" ? PiyaliBrand.unitColor("805ad5").opacity(0.18):muted,in:RoundedRectangle(cornerRadius:6)).overlay(alignment:.bottom){Rectangle().fill(dropTarget == "slot-\(index)" ? PiyaliBrand.unitColor("9f7aea"):strong).frame(height:2)}.accessibilityElement(children:.contain).accessibilityIdentifier("standardSlot-\(index)").dropDestination(for:PracticeDragItem.self){items,_ in drop(items,slot:index)}isTargeted:{dropTarget=$0 ? "slot-\(index)":nil}
    }
    private func token(_ index:Int,placed:Bool,action:@escaping()->Void)->some View {
        Button(action:action){OnboardingText(text:run.bank.indices.contains(index) ? run.bank[index]:q.strings("right")[index],size:14,lineHeight:21).multilineTextAlignment(.leading).padding(.horizontal,13).padding(.vertical,q.kind == "match" ? 7:9).foregroundStyle(placed && q.kind != "match" ? .white:brand.text).background(q.kind == "match" ? brand.questionChipBackground:placed ? PiyaliBrand.unitColor("6b46c1"):brand.surface,in:RoundedRectangle(cornerRadius:q.kind == "match" ? 8:6)).overlay{RoundedRectangle(cornerRadius:q.kind == "match" ? 8:6).stroke(q.kind == "match" ? brand.questionChip.opacity(scheme == .dark ? 0.4:0.26):brand.border)}}.buttonStyle(StandardButtonStyle()).disabled(locked).modifier(PracticeScopedDrag(item:.init(questionID:q.id,index:index),enabled:!locked))
    }
    private var matching:some View {
        VStack(alignment:.leading,spacing:0){title(copy("vocab_match_instruction")).padding(.bottom,8)
            VStack(spacing:12){ForEach(Array(q.strings("left").enumerated()),id:\.offset){index,word in
                HStack(spacing:12){HStack(alignment:.top,spacing:4){StandardQuestionTool(active:synthesizing && synthesizingWord == index,size:24,action:{listen(word,index)}){PracticeSpeakerIcon(loading:synthesizing && synthesizingWord == index,size:16)}.accessibilityLabel(copy("vocab_listen_word")).accessibilityIdentifier("standardWordAudio-\(index)").accessibilityValue(synthesizing && synthesizingWord == index ? copy("generic_loading"):"");OnboardingText(text:word,size:16,weight:.semibold,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading)}.frame(width:120,alignment:.leading)
                    Text("→").font(PiyaliBrand.productFont(18)).foregroundStyle(brand.muted)
                    matchSlot(index)
                }.padding(.horizontal,13).padding(.vertical,9).background(base,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}
            }}
            VStack(alignment:.leading,spacing:8){Text(copy("vocab_dnd_bank").uppercased()).font(PiyaliBrand.productFont(12,600)).tracking(1.2).padding(.vertical,2).foregroundStyle(brand.muted)
                DelightWrapLayout(spacing:8,rtl:q.support == "ar"){ForEach(state.bank,id:\.self){index in token(index,placed:false){save(StandardPracticeInteraction.tap(kind:"match",state:state,index:index,choices:q.strings("right")))}.accessibilityIdentifier("standardMatchBank-\(index)").dropDestination(for:PracticeDragItem.self){items,_ in drop(items,slot:nil,position:state.bank.firstIndex(of:index))}}}.environment(\.layoutDirection,.leftToRight).padding(9).frame(maxWidth:.infinity,minHeight:44,alignment:.topLeading).background(muted,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(dropTarget == "bank" ? PiyaliBrand.unitColor("b794f4"):strong,style:StrokeStyle(lineWidth:1,dash:[4]))}.accessibilityElement(children:.contain).accessibilityIdentifier("standardBank").dropDestination(for:PracticeDragItem.self){items,_ in drop(items,slot:nil)}isTargeted:{dropTarget=$0 ? "bank":nil}
            }.padding(13).background(base,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}.padding(.top,20)
        }.padding(17).background(brand.surface,in:RoundedRectangle(cornerRadius:16)).overlay(alignment:.top){LinearGradient(colors:[PiyaliBrand.unitColor("9f7aea"),PiyaliBrand.unitColor("4299e1")],startPoint:.leading,endPoint:.trailing).frame(height:3)}.clipShape(RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(brand.border)}.compositingGroup().shadow(color:.black.opacity(scheme == .dark ? 0.12:0.04),radius:9,y:8)
    }
    private func matchSlot(_ index:Int)->some View {
        let item=state.slots[index]
        return Group{if let item{token(item,placed:true){save(StandardPracticeInteraction.returnSlot(kind:"match",state:state,slot:index))}.accessibilityIdentifier("standardMatchPlaced-\(index)")}else{Text(copy("vocab_dnd_drop_here")).font(PiyaliBrand.productFont(14).italic()).foregroundStyle(brand.text.opacity(0.4))}}.padding(.horizontal,13).frame(maxWidth:.infinity,minHeight:42).background(item == nil ? muted:brand.questionChipBackground,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(dropTarget == "slot-\(index)" ? PiyaliBrand.unitColor("b794f4"):item == nil ? strong:brand.questionChip.opacity(scheme == .dark ? 0.4:0.26),style:StrokeStyle(lineWidth:1,dash:item == nil ? [4]:[]))}.accessibilityElement(children:.contain).accessibilityIdentifier("standardSlot-\(index)").dropDestination(for:PracticeDragItem.self){items,_ in drop(items,slot:index)}isTargeted:{dropTarget=$0 ? "slot-\(index)":nil}
    }
    private func save(_ next:StandardPracticeInteraction.State){guard !locked else{return};change(StandardPracticeInteraction.response(run.response,state:next,kind:q.kind,choices:q.kind == "match" ? q.strings("right"):run.bank))}
    private func returnByDrag(_ slot:Int){guard let index=state.slots[slot]else{return};_ = drop([.init(questionID:q.id,index:index)],slot:nil)}
    private func drop(_ items:[PracticeDragItem],slot:Int?,position:Int?=nil)->Bool {
        let match=q.kind == "match",count=match ? q.strings("right").count:run.bank.count
        guard let index=PracticeDragItem.matchingIndex(items,questionID:q.id,count:count,locked:locked)else{return false}
        let bankID=match ? "bank":q.kind+"-bank",slotID:(Int)->String={match ? "slot-\($0)":q.kind == "mc" ? "mc-slot":"ma-slot-\($0)"},source:String,sourcePosition:Int
        if let i=state.bank.firstIndex(of:index){source=bankID;sourcePosition=i}else if let i=state.slots.firstIndex(of:index){source=slotID(i);sourcePosition=0}else{return false}
        save(StandardPracticeInteraction.drag(kind:q.kind,state:state,choices:run.bank,source:source,sourceIndex:sourcePosition,destination:slot.map(slotID) ?? bankID,destinationIndex:slot == nil ? position ?? state.bank.count:0,item:index));return true
    }
}
struct StandardQuestionTool<Label:View>:View {
    var active=false,size:CGFloat=32,cornerRadius:CGFloat=100
    let action:()->Void
    @ViewBuilder let label:()->Label
    @Environment(\.colorScheme)private var scheme
    var body:some View{let brand=PiyaliBrand(dark:scheme == .dark);Button(action:action){label().foregroundStyle(brand.questionTool).frame(width:size,height:size).background(active ? brand.questionTool.opacity(0.08):brand.surface,in:RoundedRectangle(cornerRadius:cornerRadius)).overlay{RoundedRectangle(cornerRadius:cornerRadius).stroke(brand.questionTool.opacity(active ? 0.7:0.22))}.shadow(color:.black.opacity(0.06),radius:6,y:4)}.buttonStyle(.plain)}
}
private struct StandardButtonStyle:ButtonStyle{func makeBody(configuration:Configuration)->some View{configuration.label}}
