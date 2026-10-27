import SwiftUI

struct WordBankPracticeQuestion:View {
    static let variants:Set<String>=["translate","repeat"]
    let run:PracticeRun,locked:Bool,assistantOpen:Bool,assistantBusy:Bool,playing:Bool
    let help:()->Void,listen:()->Void,change:(JSONValue)->Void
    @Environment(\.colorScheme)private var scheme
    @State private var target:Bool?
    private var q:PracticeQuestion{run.question}
    private var state:WordBankPracticeInteraction.State{WordBankPracticeInteraction.state(run)}
    private var repeatBody:Bool{q.kind == "repeat"}
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var base:Color{PiyaliBrand.unitColor(scheme == .dark ? "0b1220":"fdf9f2")}
    private func copy(_ key:String)->String{EntryCopy.ui(q.support,key)}
    var body:some View {
        VStack(alignment:.leading,spacing:16){
            VStack(alignment:.leading,spacing:repeatBody ? 20:16){
                HStack(spacing:8){OnboardingText(text:copy(repeatBody ? "repeat_hear_heading":"translate_sentence_heading"),size:20,weight:.bold,lineHeight:30).frame(maxWidth:.infinity,alignment:.leading)
                    if !q.options["isFinalQuiz"].boolean{StandardQuestionTool(active:assistantOpen,action:help){PracticeIcon(name:"MdOutlineSupportAgent",size:18)}.disabled(assistantBusy).accessibilityIdentifier("typedPracticeHelp").accessibilityLabel(copy("vocab_ask_assistant"))}
                }
                if repeatBody{HStack{Spacer();StandardQuestionTool(active:playing,size:48,action:listen){PracticeIcon(name:"PiSpeakerHighDuotone",size:24)}.accessibilityIdentifier("typedPracticeListen").accessibilityLabel(copy("vocab_listen_question"));Spacer()}.padding(.vertical,8);answerArea}
                else{HStack(alignment:.top,spacing:8){StandardQuestionTool(active:playing,action:listen){PracticeIcon(name:"PiSpeakerHighDuotone",size:18)}.accessibilityIdentifier("typedPracticeListen").accessibilityLabel(copy("vocab_listen_question"));OnboardingText(text:q.payload["sentence"].string,size:18,weight:.medium,lineHeight:29.25).frame(maxWidth:.infinity,alignment:.leading).environment(\.layoutDirection,q.sourceLanguage == "ar" ? .rightToLeft:.leftToRight)}.padding(17).background(base,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}}
            }.padding(21).background(brand.surface,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(brand.border)}.compositingGroup().shadow(color:.black.opacity(scheme == .dark ? 0.12:0.04),radius:9,y:8)
            if !repeatBody{answerArea}
            Rectangle().fill(brand.border).frame(height:1)
            ZStack { words(selected:false) }
                .padding(13.5).frame(maxWidth:.infinity,minHeight:60)
                .background(target == false ? brand.questionTool.opacity(0.08):.clear,in:RoundedRectangle(cornerRadius:8))
                .overlay{RoundedRectangle(cornerRadius:8).stroke(target == false ? PiyaliBrand.unitColor("b794f4"):.clear,lineWidth:1.5)}
                .contentShape(Rectangle()).accessibilityElement(children:.contain).accessibilityIdentifier("wordBankAvailable")
                .dropDestination(for:PracticeDragItem.self){items,_ in drop(items,selected:false)}isTargeted:{target=$0 ? false:nil}
        }.foregroundStyle(brand.text).accessibilityElement(children:.contain).accessibilityIdentifier("typedQuestionPrompt")
    }
    private var answerArea:some View {
        ZStack(alignment:.leading){if state.selected.isEmpty{Text(copy(repeatBody ? "repeat_hear_instruction":"translate_sentence_instruction")).font(PiyaliBrand.productFont(14).italic()).foregroundStyle(brand.muted).frame(maxWidth:.infinity).multilineTextAlignment(.center)}else{words(selected:true)}}
            .padding(18).frame(maxWidth:.infinity,minHeight:80,alignment:.leading)
            .background(target == true ? brand.questionTool.opacity(0.08):repeatBody ? base:brand.surface,in:RoundedRectangle(cornerRadius:8))
            .overlay{RoundedRectangle(cornerRadius:8).stroke(target == true ? PiyaliBrand.unitColor("b794f4"):run.correct == true ? PiyaliBrand.unitColor("48bb78"):run.correct == false ? PiyaliBrand.unitColor("f56565"):brand.border,lineWidth:2)}
            .compositingGroup().shadow(color:repeatBody ? .clear:.black.opacity(scheme == .dark ? 0.12:0.04),radius:9,y:8)
            .accessibilityElement(children:.contain).accessibilityIdentifier("wordBankAnswer")
            .dropDestination(for:PracticeDragItem.self){items,_ in drop(items,selected:true)}isTargeted:{target=$0 ? true:nil}
    }
    private func words(selected:Bool)->some View {
        let indices=selected ? state.selected:state.bank
        return DelightWrapLayout(spacing:selected ? 8:12,centered:!selected,rtl:q.answerLanguage == "ar",endAligned:selected && q.answerLanguage == "ar"){ForEach(Array(indices.enumerated()),id:\.element){position,index in
            Button{save(WordBankPracticeInteraction.tap(state,index:position,selected:selected,locked:locked))}label:{OnboardingText(text:run.bank[index],size:14,lineHeight:21).padding(.horizontal,selected ? 13:17).padding(.vertical,9).foregroundStyle(brand.text).background(brand.questionChipBackground,in:RoundedRectangle(cornerRadius:selected ? 6:8)).overlay{RoundedRectangle(cornerRadius:selected ? 6:8).stroke(brand.questionChip.opacity(scheme == .dark ? 0.4:0.26))}}
                .compositingGroup().shadow(color:PiyaliBrand.unitColor(scheme == .dark ? "020617":"6f5636").opacity(scheme == .dark ? 0.18:0.1),radius:scheme == .dark ? 20:13,y:scheme == .dark ? 18:10).buttonStyle(WordBankButtonStyle()).disabled(locked).modifier(PracticeScopedDrag(item:.init(questionID:q.id,index:index),enabled:!locked))
                .accessibilityIdentifier(selected ? "typedSelected-\(position)":"typedWord-\(index)")
                .dropDestination(for:PracticeDragItem.self){items,_ in drop(items,selected:selected,position:position)}
        }}.environment(\.layoutDirection,.leftToRight).frame(maxWidth:.infinity,alignment:.leading)
    }
    private func save(_ next:WordBankPracticeInteraction.State){guard !locked else{return};change(WordBankPracticeInteraction.response(run.response,state:next))}
    private func drop(_ items:[PracticeDragItem],selected:Bool,position:Int?=nil)->Bool {
        guard let item=PracticeDragItem.matchingIndex(items,questionID:q.id,count:run.bank.count,locked:locked)else{return false}
        let source=state.selected.contains(item),indices=source ? state.selected:state.bank
        guard let index=indices.firstIndex(of:item)else{return false}
        save(WordBankPracticeInteraction.drag(state,fromSelected:source,index:index,toSelected:selected,position:position ?? (selected ? state.selected.count:state.bank.count)));return true
    }
}
private struct WordBankButtonStyle:ButtonStyle{func makeBody(configuration:Configuration)->some View{configuration.label}}
