import SwiftUI

struct AchievementFeedbackView:View {
    let unlock:AchievementUnlock
    let language:String
    var animated=true
    let onDismiss:()->Void
    @Environment(\.colorScheme) private var scheme
    private var item:JSONValue{AchievementUI.source.data["items"][AchievementUI.source.locale(language)].array.first{$0["id"].string == unlock.achievementID} ?? .null}
    private var color:Color{PiyaliBrand(dark:scheme == .dark).text}
    var body:some View {
        HStack(alignment:.center,spacing:12){
            AchievementCharacter(orb:item["orb"],animated:animated,energy:0.9).frame(width:84,height:84).accessibilityHidden(true)
            VStack(alignment:.leading,spacing:4){
                Text(AchievementUI.text(unlock.preview ? "testUnlock":unlock.test ? "testAward":"achievementUnlocked",language).uppercased()).font(PiyaliBrand.productFont(10,700)).tracking(0.8)
                AchievementParagraph(text:item["title"].string,language:language,size:16,weight:.heavy,lineHeight:20.8,color:color)
                AchievementParagraph(text:item["desc"].string,language:language,size:14,lineHeight:20.3,color:color)
            }.frame(maxWidth:.infinity,alignment:.leading)
            VStack{Button(action:onDismiss){Text("×").font(PiyaliBrand.productFont(12,600)).frame(width:24,height:24).contentShape(Rectangle())}.buttonStyle(.plain).accessibilityLabel(AchievementUI.text("close",language)).accessibilityIdentifier("achievementFeedbackClose");Spacer(minLength:0)}.frame(width:24)
        }.padding(.vertical,8).foregroundStyle(color).accessibilityElement(children:.contain).accessibilityIdentifier("achievementFeedback")
    }
}

struct AchievementActionContent:View {
    let unlock:AchievementUnlock
    let language:String
    var animated=true
    let onDismiss:()->Void
    var body:some View {ActivityFooterSurface(hasFeedback:true,feedback:{AchievementFeedbackView(unlock:unlock,language:language,animated:animated,onDismiss:onDismiss)},actions:{Button(AchievementUI.text("continue",language),action:onDismiss).buttonStyle(ActivityPrimaryButtonStyle(tone:"achievement")).accessibilityIdentifier("achievementContinue")}).environment(\.layoutDirection,AchievementUI.source.locale(language) == "ar" ? .rightToLeft:.leftToRight)}
}
