import SwiftUI

struct StoryRecordLabel:View {
    @ObservedObject var recorder:SpeechPracticeService
    let speaking:Bool,record:String,connecting:String
    var body:some View{
        HStack(spacing:8){
            if recorder.connecting || recorder.evaluating{PracticeAudioSpinner(size:14);if recorder.connecting && !speaking{Text(connecting)}}
            else if recorder.recording{let size:Double=speaking ? 22:20
                HStack(spacing:speaking ? 3:2){ForEach(0..<4){i in Capsule().frame(width:3,height:CGFloat([0.45,1.0,0.75,0.45][i]*size*(0.8+min(1,recorder.audioLevel*4)*0.5)))}}.frame(height:size)
            }else{PracticeIcon(name:speaking ? "FaMicrophone":"FiMic",size:14);Text(record)}
        }
    }
}
