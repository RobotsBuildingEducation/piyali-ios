import SwiftUI

struct SpokenPracticeQuestion:View {
    let question:PracticeQuestion,assistantOpen:Bool,assistantBusy:Bool,playing:Bool
    var synthesizing=false
    let help:()->Void,listen:()->Void
    @Environment(\.colorScheme)private var scheme
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private func copy(_ key:String)->String{EntryCopy.ui(question.support,key)}
    var body:some View {
        VStack(spacing:16){
            HStack(spacing:8){OnboardingText(text:copy("vocab_say_it_aloud"),size:20,weight:.bold,lineHeight:30).frame(maxWidth:.infinity,alignment:.leading)
                HStack(spacing:8){StandardQuestionTool(active:synthesizing,action:listen){PracticeSpeakerIcon(loading:synthesizing,size:18)}.accessibilityLabel(copy("vocab_listen_question")).accessibilityIdentifier("typedPracticeListen").accessibilityValue(synthesizing ? copy("generic_loading"):"")
                    if !question.options["isFinalQuiz"].boolean,(question.module == .grammar || ["translate","complete"].contains(question.payload["variant"].string)){StandardQuestionTool(active:assistantOpen,cornerRadius:12,action:help){PracticeIcon(name:"MdOutlineSupportAgent",size:18)}.disabled(assistantBusy).accessibilityLabel(copy("vocab_ask_assistant")).accessibilityIdentifier("typedPracticeHelp")}
                }
            }
            OnboardingText(text:question.payload["target"].string,size:30,weight:.bold,lineHeight:45).multilineTextAlignment(.center).frame(maxWidth:.infinity).padding(.vertical,8).environment(\.layoutDirection,question.target == "ar" ? .rightToLeft:.leftToRight)
        }.padding(25).foregroundStyle(brand.text).background(brand.surface,in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(brand.border)}.compositingGroup().shadow(color:.black.opacity(scheme == .dark ? 0.12:0.04),radius:9,y:8).accessibilityElement(children:.contain).accessibilityIdentifier("typedQuestionPrompt")
    }
}
struct LessonRecordingLabel:View {
    @ObservedObject var recorder:SpeechPracticeService
    let label:String,connecting:String
    var microphone="microphone"
    var body:some View{HStack(spacing:8){if recorder.connecting || recorder.evaluating{ProgressView().tint(.white)}else if !recorder.recording{if microphone == "stage"{Image("Practice-PiMicrophoneStageDuotone").renderingMode(.template).resizable().frame(width:18,height:18)}else{FlashcardIcon(name:"microphone",size:16)}};if recorder.connecting{Text(connecting)}else if recorder.recording{HStack(spacing:3){ForEach(0..<4){i in Capsule().frame(width:3,height:CGFloat([0.45,1.0,0.75,0.45][i]*(microphone == "stage" ? 22:20)*(0.8+min(1,recorder.audioLevel*4)*0.5)))}}.frame(height:22).accessibilityLabel("Listening")}else if !recorder.evaluating{Text(label)}}}
}
