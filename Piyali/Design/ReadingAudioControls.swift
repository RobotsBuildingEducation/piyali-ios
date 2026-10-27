import SwiftUI

struct ReadingAudioControls:View {
    let support:String,loading:Bool,stopActive:Bool
    var enabled=true
    let read:()->Void,stop:()->Void
    @Environment(\.colorScheme)private var scheme
    private static let values=(try? ContentLibrary.load(JSONValue.self,name:"reading-audio-ui")) ?? .null
    private var brand:PiyaliBrand{.init(dark:scheme == .dark)}
    private var stopColors:[Color]{Self.values["stopBackground"].string.components(separatedBy:"#").dropFirst().map{PiyaliBrand.unitColor(String($0.prefix(6)))}}
    private func t(_ key:String)->String{EntryCopy.ui(support,key)}
    var body:some View{
        HStack(spacing:16){
            VStack(spacing:2){Button(action:read){Group{if loading{PracticeAudioSpinner().foregroundStyle(PiyaliBrand.unitColor("38b2ac"))}else{PracticeIcon(name:"PiLightningDuotone",size:20)}}.frame(width:32,height:32).contentShape(Rectangle())}.buttonStyle(.plain).disabled(!enabled).accessibilityLabel(t("history_read_all")).accessibilityIdentifier("readingListen").accessibilityValue(loading ? t("generic_loading"):"")
                OnboardingText(text:t("history_read_all"),size:12,lineHeight:18).opacity(0.6)
            }
            VStack(spacing:2){Button(action:stop){PracticeIcon(name:"PiStopDuotone",size:20).frame(width:32,height:32).contentShape(Rectangle()).foregroundStyle(stopActive ? .white:brand.text).background{if stopActive{LinearGradient(colors:stopColors,startPoint:.topLeading,endPoint:.bottomTrailing).clipShape(Circle())}}}.buttonStyle(ReadingStopStyle(edge:PiyaliBrand.unitColor(Self.values["stopEdge"].string),active:stopActive)).disabled(!stopActive).opacity(stopActive ? 1:0.4).accessibilityLabel(t("history_stop")).accessibilityIdentifier("readingStop")
                OnboardingText(text:t("history_stop"),size:12,lineHeight:18).opacity(0.6)
            }
        }.foregroundStyle(brand.text).frame(maxWidth:.infinity)
    }
}
private struct ReadingStopStyle:ButtonStyle{
    let edge:Color,active:Bool
    func makeBody(configuration:Configuration)->some View{configuration.label.offset(y:active && configuration.isPressed ? 2:0).shadow(color:active && !configuration.isPressed ? edge:.clear,radius:0,y:4)}
}
