import SwiftUI

enum LessonSessionCopy {
    static let data=(try? ContentLibrary.load(JSONValue.self,name:"lesson-session-copy")) ?? .null
    static func completion(_ text:String,language:String)->String { let values=data["completion"][text];return values[language].string.isEmpty ? values["en"].string : values[language].string }
    static func module(_ mode:String,language:String,key:String="label")->String { data["modules"][mode][key].localized(language) }
}
struct LessonCompletionView:View {
    @EnvironmentObject var app:AppModel
    let completion:LessonCompletionPresentation
    let onContinue:()->Void
    private func copy(_ text:String)->String { LessonSessionCopy.completion(text,language:app.learner.support) }
    var body:some View {
        VStack(spacing:22) {
            BrandArtwork(name:"28.webp").frame(width:104,height:104).padding(14).background(Color.white.opacity(0.2),in:Circle()).overlay { Circle().stroke(Color.white.opacity(0.3),lineWidth:2) }
            VStack(spacing:6) { Text(copy("Lesson Complete!")).font(PiyaliBrand.productFont(30,700));Text(completion.title.localized(app.learner.support)).font(PiyaliBrand.productFont(18)).opacity(0.9) }
            VStack(spacing:10) {
                Text(copy("XP Earned").uppercased()).font(PiyaliBrand.productFont(14)).tracking(1).opacity(0.8)
                Text("+\(completion.reward)").font(PiyaliBrand.productFont(50,700)).foregroundStyle(PiyaliBrand.unitColor("#faf089")).accessibilityIdentifier("lessonCompletionBonus")
                Text(copy("Experience Points")).font(PiyaliBrand.productFont(14)).opacity(0.8)
                ProgressView(value:Double(completion.languageXP%100),total:100).tint(.yellow).padding(.top,12)
                HStack { Text(copy("Level")+" \(completion.languageXP/100+1)");Spacer();Text("\(completion.languageXP%100) / 100 XP") }.font(PiyaliBrand.productFont(13))
            }.padding(24).frame(maxWidth:.infinity).background(Color.white.opacity(0.12),in:RoundedRectangle(cornerRadius:18)).overlay { RoundedRectangle(cornerRadius:18).stroke(Color.white.opacity(0.4),lineWidth:2) }
            Button(action:onContinue) { Text(copy("Continue")).font(PiyaliBrand.productFont(18,700)).foregroundStyle(Color(red:0.40,green:0.49,blue:0.92)).frame(maxWidth:.infinity,minHeight:56).background(.white,in:RoundedRectangle(cornerRadius:16)) }.buttonStyle(.plain).accessibilityIdentifier("continueLessonCompletion")
        }.foregroundStyle(.white).padding(28).frame(maxWidth:480).background(LinearGradient(colors:[PiyaliBrand.unitColor("#667eea"),PiyaliBrand.unitColor("#764ba2")],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:24)).shadow(color:.black.opacity(0.3),radius:24,y:12)
    }
}
