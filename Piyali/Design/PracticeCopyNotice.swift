import SwiftUI

/// Chakra's source top toast keeps physical control positions even in an RTL question.
struct PracticeCopyNotice:View {
    let text:String,closeLabel:String
    let dismiss:()->Void
    private var width:CGFloat{let measured=(text as NSString).size(withAttributes:[.font:UIFont.systemFont(ofSize:16,weight:.bold)]).width;return min(UIScreen.main.bounds.width-16,max(300,measured+80))}
    var body:some View{
        HStack(spacing:12){Image(systemName:"info.circle.fill").font(.system(size:20)).frame(width:20,height:20);OnboardingText(text:text,size:16,weight:.bold,lineHeight:24).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("practiceCopyNotice")}.padding(.leading,16).padding(.trailing,32).padding(.vertical,12).frame(width:width).foregroundStyle(.white).background(PiyaliBrand.unitColor("2b6cb0"),in:RoundedRectangle(cornerRadius:6)).overlay(alignment:.topTrailing){Button(action:dismiss){PracticeIcon(name:"FiX",size:12).frame(width:24,height:24).foregroundStyle(.white)}.padding(4).accessibilityLabel(closeLabel).accessibilityIdentifier("dismissPracticeCopyNotice")}.shadow(color:.black.opacity(0.18),radius:8,y:4).environment(\.layoutDirection,.leftToRight)
    }
}
