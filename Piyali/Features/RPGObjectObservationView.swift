import SwiftUI

struct RPGObjectObservationView:View {
    let observation:RPGObjectController.Observation,target:String,support:String
    var lootText=""
    @Environment(\.colorScheme) private var scheme
    private var light:Bool{scheme != .dark}
    private var text:JSONValue{observation.fields}
    var body:some View {
        VStack(alignment:.leading,spacing:4){
            if !lootText.isEmpty{ObjectObservationText(text:lootText,size:12,lineHeight:16.2).foregroundStyle(PiyaliBrand.unitColor(light ? "9b5d2d":"c05621"))}
            if !text["name"].string.isEmpty || !text["supportName"].string.isEmpty{
                ObjectObservationText(text:text["name"].string+(text["supportName"].string.isEmpty ? "":" (\u{2068}"+text["supportName"].string+"\u{2069})"),size:14,weight:.semibold,lineHeight:18.9).accessibilityIdentifier("rpgObjectName")
            }
            if !text["text"].string.isEmpty{ObjectObservationText(text:text["text"].string,size:14,lineHeight:20.3).accessibilityIdentifier("rpgObjectText")}
            if !text["supportText"].string.isEmpty{ObjectObservationText(text:"("+text["supportText"].string+")",size:12,lineHeight:16.2,italic:true).frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(PiyaliBrand.unitColor(light ? "8a745c":"334155")).environment(\.layoutDirection,support == "ar" ? .rightToLeft:.leftToRight).accessibilityIdentifier("rpgObjectTranslation")}
            if observation.pending{HStack(spacing:8){VoiceOrbView(state:"listening",dark:!light).frame(width:16,height:16);Text("...").font(PiyaliBrand.productFont(14)).foregroundStyle(PiyaliBrand.unitColor(light ? "6b553f":"4a5568"))}.padding(.top,4).accessibilityElement(children:.ignore).accessibilityLabel("...").accessibilityIdentifier("rpgObjectPending")}
        }.frame(maxWidth:.infinity,alignment:.leading).fixedSize(horizontal:false,vertical:true).padding(.horizontal,16).padding(.vertical,12).padding(2)
            .foregroundStyle(PiyaliBrand.unitColor(light ? "4b3726":"111827"))
            .background(PiyaliBrand.unitColor(light ? "fffaf1":"faf4e8").opacity(light ? 0.98:0.96),in:RoundedRectangle(cornerRadius:12))
            .overlay{RoundedRectangle(cornerRadius:12).stroke(PiyaliBrand.unitColor(light ? "e0b474":"fbd38d").opacity(light ? 0.92:1),lineWidth:2)}
            .shadow(color:light ? PiyaliBrand.unitColor("543e24").opacity(0.2):.black.opacity(0.52),radius:light ? 14:19,y:light ? 14:18)
            .environment(\.layoutDirection,target == "ar" ? .rightToLeft:.leftToRight)
    }
}

private struct ObjectObservationText:View {
    let text:String,size:CGFloat
    var weight:Font.Weight = .regular
    let lineHeight:CGFloat
    var italic=false
    var body:some View{let leading=max(0,lineHeight-UIFont.systemFont(ofSize:size).lineHeight);Text(text).font(italic ? .system(size:size,weight:weight).italic():.system(size:size,weight:weight)).lineSpacing(leading).padding(.vertical,leading/2).fixedSize(horizontal:false,vertical:true)}
}
