import SwiftUI

struct PracticeDeckView:View {
    @Environment(\.dismiss)private var dismiss
    @Environment(\.colorScheme)private var scheme
    let cards:[PracticeCollectedCard]
    let support:String,target:String
    @State private var index=0
    @State private var flipped=false
    init(cards:[PracticeCollectedCard],support:String,target:String,initialIndex:Int=0,initialFlipped:Bool=false){self.cards=cards;self.support=support;self.target=target;_index=State(initialValue:initialIndex);_flipped=State(initialValue:initialFlipped)}
    private var dark:Bool{scheme == .dark}
    private var brand:PiyaliBrand{.init(dark:dark)}
    private func copy(_ key:String)->String{PracticeCopy.text(variant:"flashcard",language:support,key:key)}
    var body:some View {
        GeometryReader{g in ZStack{
            Color.black.opacity(0.8).ignoresSafeArea().contentShape(Rectangle()).onTapGesture{dismiss()}
            if !cards.isEmpty{let card=cards[min(index,cards.count-1)]
                VStack(spacing:16){
                    HStack{Text(copy("deck_review").uppercased()).font(PiyaliBrand.productFont(16,700)).padding(.horizontal,4).frame(height:24).foregroundStyle(PiyaliBrand.unitColor("2a4365")).background(PiyaliBrand.unitColor("bee3f8"),in:RoundedRectangle(cornerRadius:2));Spacer();Text("\(index+1) / \(cards.count)").font(PiyaliBrand.productFont(14,700)).padding(.horizontal,4).frame(height:21).foregroundStyle(PiyaliBrand.unitColor(dark ? "111827":"f1e8dc")).background(PiyaliBrand.unitColor(dark ? "e5e7eb":"2f261d"),in:RoundedRectangle(cornerRadius:2))}
                    Button{withAnimation(.easeInOut(duration:0.5)){flipped.toggle()}}label:{VStack(spacing:8){Text(EntryCopy.ui(support,"language_"+(flipped ? target:support))).font(PiyaliBrand.productFont(12)).frame(minHeight:18).foregroundStyle(dark ? .white.opacity(0.7):brand.secondary);OnboardingText(text:flipped ? card.answer:card.concept,size:24,weight:.bold,lineHeight:36).multilineTextAlignment(.center).foregroundStyle(dark ? .white:brand.text).environment(\.layoutDirection,(flipped ? target:support) == "ar" ? .rightToLeft:.leftToRight);if !flipped{Text(copy("tap_to_flip")).font(PiyaliBrand.productFont(12)).frame(minHeight:18).foregroundStyle(dark ? .white.opacity(0.6):brand.muted).padding(.top,8)}}.padding(18).frame(maxWidth:.infinity,minHeight:180).background{if flipped{LinearGradient(colors:dark ? [PiyaliBrand.unitColor("065f46"),PiyaliBrand.unitColor("059669")]:[PiyaliBrand.unitColor("059669").opacity(0.18),PiyaliBrand.unitColor("10b981").opacity(0.1)],startPoint:.topLeading,endPoint:.bottomTrailing)}else{LessonFlashcardSurface(dark:dark)}}.clipShape(RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(dark ? PiyaliBrand.unitColor("3b82f6").opacity(0.2):brand.border,lineWidth:2)}}.buttonStyle(.plain).accessibilityIdentifier("reviewLessonFlashcard")
                    HStack(spacing:16){Button(copy("prev")){index=LessonCardRules.cycle(index:index,count:cards.count,forward:false);flipped=false}.accessibilityIdentifier("previousLessonFlashcard");Button(copy("next")){index=LessonCardRules.cycle(index:index,count:cards.count,forward:true);flipped=false}.accessibilityIdentifier("nextLessonFlashcard")}.font(PiyaliBrand.productFont(14,600)).buttonStyle(LessonDeckButtonStyle(dark:dark)).disabled(cards.count<=1)
                    Button(copy("close")){dismiss()}.font(PiyaliBrand.productFont(14,600)).padding(.horizontal,12).frame(height:32).foregroundStyle(PiyaliBrand.unitColor(dark ? "a3b4c9":"786654")).accessibilityIdentifier("closeLessonFlashcardDeck")
                }.padding(24).frame(width:min(420,g.size.width*0.9)).contentShape(Rectangle())
            }
        }.frame(maxWidth:.infinity,maxHeight:.infinity)}.environment(\.layoutDirection,support == "ar" ? .rightToLeft:.leftToRight)
    }
}

private struct LessonDeckButtonStyle:ButtonStyle {
    let dark:Bool
    @Environment(\.isEnabled)private var enabled
    func makeBody(configuration:Configuration)->some View{let brand=PiyaliBrand(dark:dark);configuration.label.padding(.horizontal,12).frame(height:32).foregroundStyle(brand.text).background(brand.surface,in:Capsule()).overlay{Capsule().stroke(brand.border)}.opacity(enabled ? 1:0.4)}
}
