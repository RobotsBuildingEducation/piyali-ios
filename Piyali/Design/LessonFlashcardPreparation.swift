import SwiftUI

/// The source inserts deck access only after its loading card, or when no concept exists.
struct LessonFlashcardPreparation:View {
    let loading:Bool,deckCount:Int,support:String
    let openDeck:()->Void
    @Environment(\.colorScheme)private var scheme
    private var dark:Bool{scheme == .dark}
    private var brand:PiyaliBrand{.init(dark:dark)}
    private func copy(_ key:String)->String{PracticeCopy.text(variant:"flashcard",language:support,key:key)}
    var body:some View{
        VStack(spacing:12){
            if loading{LessonFlashcardGeneratingDots().foregroundStyle(dark ? .white:.black).frame(maxWidth:.infinity,minHeight:56).padding(22).background{LessonFlashcardSurface(dark:dark)}.clipShape(RoundedRectangle(cornerRadius:16)).overlay{RoundedRectangle(cornerRadius:16).stroke(dark ? PiyaliBrand.unitColor("3b82f6").opacity(0.2):brand.border,lineWidth:2)}.overlay{if dark{RoundedRectangle(cornerRadius:18).stroke(PiyaliBrand.unitColor("3b82f6").opacity(0.25),lineWidth:2).padding(-1)}}.shadow(color:.black.opacity(dark ? 0.5:0.04),radius:dark ? 30:9,y:dark ? 20:8).accessibilityLabel(copy("generating")).accessibilityIdentifier("lessonFlashcardGenerating")}
            if deckCount>0{Button(action:openDeck){HStack(spacing:8){HStack(spacing:8){Image("Practice-RiStackLine").renderingMode(.template).resizable().frame(width:16,height:16).foregroundStyle(PiyaliBrand.unitColor("93c5fd"));Text(copy("deck_label")).font(PiyaliBrand.productFont(14,500)).foregroundStyle(PiyaliBrand.unitColor("90cdf4"))};Spacer();HStack(spacing:4){ForEach(0..<min(8,deckCount),id:\.self){i in RoundedRectangle(cornerRadius:2).fill(PiyaliBrand.unitColor("4299e1").opacity(0.5+Double(i)/Double(min(8,deckCount))*0.5)).frame(width:6,height:8)};Text("\(deckCount)").font(PiyaliBrand.productFont(12)).foregroundStyle(brand.muted).padding(.leading,4)}}.frame(minHeight:21).padding(13).background(brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}.shadow(color:.black.opacity(0.04),radius:9,y:8)}.buttonStyle(.plain).accessibilityIdentifier("openLessonFlashcardDeck")}
        }.frame(maxWidth:400).frame(maxWidth:.infinity)
    }
}

private struct LessonFlashcardGeneratingDots:View {
    @Environment(\.accessibilityReduceMotion)private var reduceMotion
    var body:some View{TimelineView(.animation(minimumInterval:1/20,paused:reduceMotion)){clock in
        Canvas{context,size in for i in 0..<3{let phase=(clock.date.timeIntervalSinceReferenceDate-Double(i)*0.14).truncatingRemainder(dividingBy:0.9)/0.9,strength=reduceMotion ? 0.5:(1-cos(phase*2*Double.pi))/2;context.opacity=0.28+strength*0.72;context.fill(Path(ellipseIn:CGRect(x:Double(i)*12,y:9-strength*3,width:6,height:6)),with:.foreground)}}.frame(width:30,height:24)
    }}
}
