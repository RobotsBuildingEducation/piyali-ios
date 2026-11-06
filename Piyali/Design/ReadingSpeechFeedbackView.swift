import SwiftUI

/// The original compact, scrollable Reading result and its six criterion cards.
struct ReadingSpeechFeedbackView:View {
    @Environment(\.colorScheme) private var scheme
    let feedback:ReadingSpeechFeedback
    let support:String
    let reward:Int
    var progress:Int?=nil
    @State private var portrait=([1]+Array(3...41)).randomElement() ?? 1
    private var light:Bool { scheme != .dark }
    private var brand:PiyaliBrand { .init(dark:!light) }
    private var text:Color { light ? PiyaliBrand.unitColor("4a3727") : brand.text }
    private var heading:Color { light ? PiyaliBrand.unitColor("5a4736") : brand.text }
    private var muted:Color { light ? PiyaliBrand.unitColor("7c6955") : brand.text.opacity(0.7) }
    private var noteColor:Color { light ? muted : brand.text.opacity(0.55) }
    private func t(_ key:String)->String { EntryCopy.ui(support,key) }
    private func accent(_ score:Double)->Color {
        let values=light ? ["green":"358f67","teal":"2f8f88","yellow":"a87318","purple":"8d63c7"] : ["green":"48bb78","teal":"38b2ac","yellow":"ecc94b","purple":"b794f4"]
        return PiyaliBrand.unitColor(values[ReadingSpeechFeedback.color(score)]!)
    }
    private func number(_ value:Double)->String { value.formatted(.number.precision(.fractionLength(0...1))) }
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            HStack(spacing:10) {
                Text("✓").font(PiyaliBrand.productFont(16,700)).frame(width:26,height:26).background(PiyaliBrand.unitColor("43a047").opacity(light ? 0.16 : 0.25),in:Circle()).foregroundStyle(light ? heading : accent(10))
                Text(t("history_speech_complete")).font(PiyaliBrand.productFont(16,700)).foregroundStyle(heading).accessibilityIdentifier("readingCompleted").accessibilityValue("\(reward) XP")
                Spacer(minLength:0)
                if let url=Bundle.main.url(forResource:StoryCharacterAvatar.appearance.portraitFile(String(portrait)),withExtension:nil),let image=UIImage(contentsOfFile:url.path) { Image(uiImage:image).resizable().interpolation(.none).scaledToFit().frame(width:32,height:36).accessibilityHidden(true) }
            }
            if !feedback.summary.isEmpty { Text(feedback.summary).font(PiyaliBrand.productFont(14)).lineSpacing(5).foregroundStyle(text.opacity(light ? 1 : 0.9)).accessibilityIdentifier("readingSpeechSummary") }
            if let progress { VStack(spacing:8) { HStack(spacing:12) { Text(t("vocab_lesson_progress"));Text("\(progress)%") }.font(PiyaliBrand.productFont(12,600)).foregroundStyle(muted);ActivityProgressBar(value:progress,label:t("vocab_lesson_progress")).containerRelativeFrame(.horizontal) { width,_ in width*0.6 } }.frame(maxWidth:.infinity) }
            if feedback.maximum > 0 {
                VStack(spacing:3) {
                    Text(t("history_speech_total_score").uppercased()).font(PiyaliBrand.productFont(12,600)).foregroundStyle(muted).tracking(0.5)
                    (Text(number(feedback.total)).font(PiyaliBrand.productFont(24,700)).foregroundColor(accent(feedback.total/Double(feedback.scores.count)))+Text("/\(feedback.maximum)").font(PiyaliBrand.productFont(14)).foregroundColor(muted)).accessibilityIdentifier("readingSpeechTotal")
                }.padding(.horizontal,16).padding(.vertical,10).frame(maxWidth:.infinity).background(light ? PiyaliBrand.unitColor("f2eadc") : .black.opacity(0.25),in:RoundedRectangle(cornerRadius:12)).overlay { RoundedRectangle(cornerRadius:12).stroke(accent(feedback.total/Double(feedback.scores.count))) }
                Text(t("history_speech_breakdown").uppercased()).font(PiyaliBrand.productFont(12,600)).tracking(0.5).foregroundStyle(muted)
                VStack(spacing:8) {
                    ForEach(Array(ReadingSpeechFeedback.criteria.enumerated()),id:\.offset) { _,criterion in
                        let key=criterion["key"].string
                        if let score=feedback.scores[key] {
                            VStack(alignment:.leading,spacing:4) {
                                HStack { Text(criterion.localized(support)).font(PiyaliBrand.productFont(12,600)).foregroundStyle(heading.opacity(light ? 1 : 0.85));Spacer();Text(number(score.score)).font(PiyaliBrand.productFont(18,700)).foregroundStyle(accent(score.score)) }
                                if !score.note.isEmpty { Text(score.note).font(PiyaliBrand.productFont(10)).foregroundStyle(noteColor).lineSpacing(3).lineLimit(3) }
                            }.padding(.horizontal,12).padding(.vertical,10).frame(maxWidth:.infinity,alignment:.leading).background(light ? PiyaliBrand.unitColor("f7f0e5") : .black.opacity(0.2),in:RoundedRectangle(cornerRadius:9)).overlay { RoundedRectangle(cornerRadius:9).stroke(light ? brand.border : .clear) }.overlay(alignment:.leading) { UnevenRoundedRectangle(topLeadingRadius:3,bottomLeadingRadius:3).fill(accent(score.score)).frame(width:3) }.accessibilityIdentifier("readingSpeechScore-"+key)
                        }
                    }
                }
            }
        }.padding(.horizontal,1).padding(.vertical,8).foregroundStyle(text).environment(\.layoutDirection,support == "ar" ? .rightToLeft : .leftToRight)
    }
}
