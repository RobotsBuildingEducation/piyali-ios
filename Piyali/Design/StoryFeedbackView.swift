import SwiftUI

@MainActor final class StoryFeedbackPolicy {
    static let shared=try? StoryFeedbackPolicy()
    private let engine:PracticeAssistancePolicy
    init()throws{guard let url=Bundle.main.url(forResource:"story-feedback-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};engine=try PracticeAssistancePolicy(source:String(contentsOf:url,encoding:.utf8))}
    func tips(_ reasons:[String],language:String,targetLabel:String)throws->[String]{try engine.runPolicy("tips",.object(["reasons":.array(reasons.map(JSONValue.string)),"language":.string(language),"targetLabel":.string(targetLabel)])).array.map(\.string)}
}

/// Original compact FeedbackRail: verdict, progress, then incorrect-only Markdown.
struct StoryFeedbackView:View {
    let correct:Bool,label:String,subtext:String,explanation:String,progress:Int,progressLabel:String
    var xp=0
    var portrait=7
    var speaking=false
    @Environment(\.colorScheme) private var scheme
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    var body:some View{
        VStack(alignment:.leading,spacing:0){
            HStack(alignment:.top,spacing:12){
                if correct{BrandArtwork(name:"story-portrait-\(portrait).webp").frame(width:32,height:32).offset(y:-2).accessibilityHidden(true)}
                else{Text("✖").font(PiyaliBrand.productFont(16,700)).padding(.vertical,max(0,24-UIFont.systemFont(ofSize:16).lineHeight)/2).foregroundStyle(brand.questionError).accessibilityHidden(true)}
                VStack(alignment:.leading,spacing:0){
                    Text(label+(xp>0 ? " · +\(xp) XP":"")).font(PiyaliBrand.productFont(16,700)).padding(.vertical,max(0,24-UIFont.systemFont(ofSize:16).lineHeight)/2).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier(speaking ? "storySpeechFeedback":"storyFeedback").accessibilityValue(xp>0 ? "+\(xp) XP":"")
                    if !subtext.isEmpty{Text(subtext).font(PiyaliBrand.productFont(14)).padding(.vertical,max(0,21-UIFont.systemFont(ofSize:14).lineHeight)/2).foregroundStyle(brand.secondary).accessibilityIdentifier("storySpeechScore")}
                }
            }
            VStack(spacing:8){
                HStack{Text(progressLabel);Spacer();Text("\(progress)%").fontWeight(.semibold)}.font(PiyaliBrand.productFont(12)).padding(.vertical,max(0,18-UIFont.systemFont(ofSize:12).lineHeight)/2).foregroundStyle(brand.secondary)
                FocusWaveBar(percent:Double(progress),height:14,start:"4aa8ff",end:"75f8ff",background:PiyaliBrand.unitColor("7dd3fc").opacity(0.12),border:PiyaliBrand.unitColor("7dd3fc").opacity(0.24)).accessibilityHidden(false).accessibilityElement(children:.ignore).accessibilityLabel(progressLabel).accessibilityValue("\(progress)%").accessibilityIdentifier("storyFeedbackProgress")
            }.padding(.top,12)
            if !correct,!explanation.isEmpty{PracticeFeedbackMarkdown(text:explanation,paragraphBottom:8,plainTextDirection:true).padding(.top,8).accessibilityIdentifier("storyFeedbackExplanation")}
        }.padding(.horizontal,4).padding(.top,8).padding(.bottom,4).foregroundStyle(brand.text)
    }
}
