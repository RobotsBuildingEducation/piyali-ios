import SwiftUI

enum LessonSessionCopy {
    static let data=(try? ContentLibrary.load(JSONValue.self,name:"lesson-session-copy")) ?? .null
    static func completion(_ text:String,language:String)->String { let values=data["completion"][text];return values[language].string.isEmpty ? values["en"].string : values[language].string }
    static func module(_ mode:String,language:String,key:String="label")->String { data["modules"][mode][key].localized(language) }
}
struct LessonCompletionView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.layoutDirection) private var direction
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var textScale:CGFloat=1
    @State private var cardVisible=false
    @State private var portraitVisible=false
    let completion:LessonCompletionPresentation
    let onContinue:()->Void
    private func copy(_ text:String)->String { LessonSessionCopy.completion(text,language:app.learner.support) }
    private var dark:Bool { scheme == .dark }
    private var xp:Int { max(completion.languageXP,app.learner.xpByLanguage[completion.target,default:0]) }
    private var frameColor:Color { PiyaliBrand.unitColor(dark ? "94a3b8":"604d38").opacity(dark ? 0.42:0.3) }

    var body:some View {
        GeometryReader { geometry in
            let size=geometry.size,roomy=size.width >= 400 && size.height >= 740
            ZStack {
                PiyaliBrand.unitColor(dark ? "020617":"1c140c").opacity(dark ? 0.92:0.82)
                    .opacity(cardVisible || reduceMotion ? 1:0)
                    .ignoresSafeArea().contentShape(Rectangle()).onTapGesture(perform:onContinue)
                ViewThatFits(in:.vertical) {
                    card(contents(roomy:roomy).fixedSize(horizontal:false,vertical:true))
                    card(ScrollView { contents(roomy:roomy) }.scrollIndicators(.hidden))
                }
                .frame(width:max(0,min(size.width-24,size.width >= 480 ? 448:size.width)))
                .frame(maxHeight:max(0,size.height-16))
                .opacity(cardVisible || reduceMotion ? 1:0)
                .offset(y:cardVisible || reduceMotion ? 0:10)
            }.frame(maxWidth:.infinity,maxHeight:.infinity)
        }.ignoresSafeArea(.container)
            .accessibilityElement(children:.contain).accessibilityAddTraits(.isModal)
            .accessibilityIdentifier("lessonCompletionDialog")
            .accessibilityAction(.escape) { onContinue() }
            .onAppear {
                withAnimation(reduceMotion ? nil:.timingCurve(0.22,1,0.36,1,duration:0.2)) { cardVisible=true }
                withAnimation(reduceMotion ? nil:.easeInOut(duration:0.3)) { portraitVisible=true }
            }
    }

    private func contents(roomy:Bool)->some View {
        let portraitSize:CGFloat=roomy ? 96:80
        return VStack(spacing:roomy ? 20:16) {
            BrandArtwork(name:"28.webp").frame(width:portraitSize,height:portraitSize)
                .opacity(portraitVisible || reduceMotion ? 1:0)
                .offset(y:portraitVisible || reduceMotion ? 0:25)
                .padding(roomy ? 14:10)
                .background(.white.opacity(0.2),in:Circle())
                .overlay { Circle().strokeBorder(.white.opacity(0.3),lineWidth:2) }
                .shadow(color:.black.opacity(0.18),radius:20,y:20)
                .accessibilityHidden(true)
            VStack(spacing:4) {
                OnboardingText(text:copy("Lesson Complete!"),size:roomy ? 30:24,weight:.bold,lineHeight:roomy ? 34.5:27.6)
                OnboardingText(text:completion.title.localized(app.learner.support),size:roomy ? 18:16,lineHeight:roomy ? 27:24).opacity(0.9)
            }
            award(roomy:roomy)
            Button(action:onContinue) {
                OnboardingText(text:copy("Continue"),size:roomy ? 18:16,weight:.bold)
                    .foregroundStyle(PiyaliBrand.unitColor("6b46c1"))
                    .padding(.horizontal,24).padding(.vertical,6)
                    .frame(maxWidth:.infinity,minHeight:roomy ? 58:50)
                    .background(.white,in:Capsule())
                    .contentShape(Capsule())
            }.buttonStyle(.plain).accessibilityIdentifier("continueLessonCompletion")
        }
        .multilineTextAlignment(.center).foregroundStyle(.white).padding(28)
    }

    private func award(roomy:Bool)->some View {
        let amountSize:CGFloat=(roomy ? 48:36)*textScale
        return VStack(spacing:4) {
            Text(copy("XP Earned").uppercased()).font(.system(size:14*textScale))
                .tracking(0.35).frame(minHeight:21*textScale).opacity(0.8)
            Text(direction == .rightToLeft ? "\(completion.reward)+" : "+\(completion.reward)")
                .font(.system(size:amountSize,weight:.bold))
                .frame(height:amountSize).foregroundStyle(PiyaliBrand.unitColor("faf089"))
                .environment(\.layoutDirection,.leftToRight)
                .accessibilityLabel("+\(completion.reward)")
                .accessibilityIdentifier("lessonCompletionBonus")
            OnboardingText(text:copy("Experience Points"),size:14,lineHeight:21).opacity(0.8)
            VStack(spacing:4) {
                HStack(spacing:8) {
                    OnboardingText(text:copy("Level")+" \(xp/100+1)",size:14,weight:.bold,lineHeight:16.8)
                        .accessibilityIdentifier("lessonCompletionLevel")
                    Spacer(minLength:0)
                    OnboardingText(text:"XP \(xp)",size:12,weight:.heavy,lineHeight:18)
                        .padding(.horizontal,11).padding(.vertical,5)
                        .foregroundStyle(PiyaliBrand.unitColor(dark ? "dbe6f3":"6f5a47"))
                        .background(PiyaliBrand.unitColor(dark ? "111827":"fffdf9").opacity(dark ? 0.92:0.96),in:EntryCornerShape(radius:6))
                        .overlay { EntryCornerShape(radius:6).stroke(PiyaliBrand.unitColor(dark ? "94a3b8":"604d38").opacity(0.16)) }
                        .shadow(color:PiyaliBrand.unitColor(dark ? "030814":"705839").opacity(dark ? 0.24:0.1),radius:dark ? 9:7,y:dark ? 8:6)
                        .accessibilityIdentifier("lessonCompletionXP")
                }
                FocusWaveBar(percent:Double(xp%100),height:15,background:.white.opacity(0.8),
                             border:PiyaliBrand.unitColor("ededed"),animateFill:true,insetBorder:true)
            }.padding(.top,8)
        }
        .padding(.horizontal,roomy ? 30:22).padding(.vertical,roomy ? 22:18)
        .frame(maxWidth:.infinity)
        .background(.white.opacity(0.2),in:RoundedRectangle(cornerRadius:12))
        .overlay { RoundedRectangle(cornerRadius:12).strokeBorder(.white.opacity(0.4),lineWidth:2) }
    }

    private func card<Content:View>(_ content:Content)->some View {
        let shape=EntryCornerShape(radius:48)
        return content
            .background { gradient }
            .overlay { shape.stroke(frameColor,lineWidth:6).allowsHitTesting(false) }
            .clipShape(shape)
            .contentShape(shape).onTapGesture { }
            .shadow(color:.black.opacity(0.25),radius:25,y:25)
    }

    private var gradient:some View {
        GeometryReader { geometry in
            let width=max(1,geometry.size.width),height=max(1,geometry.size.height)
            let travel=(width+height)/4
            LinearGradient(colors:[PiyaliBrand.unitColor("667eea"),PiyaliBrand.unitColor("764ba2")],
                           startPoint:UnitPoint(x:0.5-travel/width,y:0.5-travel/height),
                           endPoint:UnitPoint(x:0.5+travel/width,y:0.5+travel/height))
                .environment(\.layoutDirection,.leftToRight)
        }
    }
}
