import SwiftUI

struct PracticeDeckView:View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var speech=SpeechService()
    let cards:[PracticeCollectedCard]
    let support:String
    @State private var index=0
    @State private var flipped=false
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    private func copy(_ key:String)->String { PracticeCopy.text(variant:"flashcard",language:support,key:key) }
    var body:some View {
        NavigationStack {
            VStack(spacing:24) {
                if cards.indices.contains(index) {
                    let card=cards[index]
                    Text("\(index+1) / \(cards.count)").font(PiyaliBrand.productFont(14,500)).foregroundStyle(brand.secondary)
                    Button { flipped.toggle();speech.stopAll() } label:{
                        VStack(alignment:.leading,spacing:18) {
                            Text(flipped ? copy("answer_label") : copy("translate_to").replacingOccurrences(of:"{language}",with:EntryCopy.ui(support,"language_"+card.target))).font(PiyaliBrand.productFont(13,500)).foregroundStyle(brand.secondary)
                            Text(flipped ? card.answer : card.concept).font(PiyaliBrand.productFont(26,800)).foregroundStyle(brand.text)
                            Text(copy(flipped ? "tap_to_flip" : "show_answer")).font(PiyaliBrand.productFont(13,600)).foregroundStyle(brand.questionTool)
                        }.frame(maxWidth:.infinity,minHeight:170,alignment:.leading).padding(24).background(brand.surface,in:RoundedRectangle(cornerRadius:24)).overlay { RoundedRectangle(cornerRadius:24).stroke(brand.border) }
                    }.buttonStyle(.plain).accessibilityIdentifier("reviewLessonFlashcard")
                    if flipped { Button { speech.speak(card.answer,language:card.target) } label:{ Label(copy("listen"),systemImage:"speaker.wave.2.fill") }.tint(brand.questionTool) }
                    HStack {
                        Button(copy("prev")) { speech.stopAll();index -= 1;flipped=false }.disabled(index == 0)
                        Spacer()
                        Button(copy("next")) { speech.stopAll();index += 1;flipped=false }.disabled(index >= cards.count-1)
                    }.font(PiyaliBrand.productFont(16,600)).tint(brand.questionChoice)
                } else { Text(copy("deck_label")+" (0)").foregroundStyle(brand.secondary) }
                Spacer()
            }.padding(24).background(brand.background).navigationTitle(copy("deck_review")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement:.topBarTrailing) { Button(copy("close")) { dismiss() } } }
        }.onDisappear { speech.stopAll() }.onChange(of:scenePhase) { _,phase in if phase != .active { speech.stopAll() } }
    }
}
