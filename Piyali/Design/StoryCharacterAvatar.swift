import SwiftUI

struct StoryCharacterAvatar:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    static let appearance=StoryAppearance((try? ContentLibrary.load(JSONValue.self,name:"story-ui")) ?? .null)
    let name:String
    var portraitID:String?
    var size:CGFloat=42
    var speaking=false
    var accent=Color(red:56/255,green:178/255,blue:172/255)
    var indicator:String?
    private var user:Bool { StoryAppearance.isUser(name,learnerName:app.learner.name) }
    private var brand:PiyaliBrand { .init(dark:scheme == .dark) }
    var body:some View {
        ZStack(alignment:.bottomTrailing) {
            Group {
                if user { SourceCompanionSprite(type:app.learner.companionType,animated:speaking && !reduceMotion).padding(6).background(PiyaliBrand.teal.opacity(0.14)) }
                else if let url=Bundle.main.url(forResource:Self.appearance.portraitFile(portraitID ?? Self.appearance.portraitPool(name).first ?? "35"),withExtension:nil),let image=UIImage(contentsOfFile:url.path) { Image(uiImage:image).resizable().interpolation(.none).scaledToFill() }
                else { Text(String(name.prefix(1))).font(.headline).frame(maxWidth:.infinity,maxHeight:.infinity).background(brand.surface) }
            }.frame(width:size,height:size).clipShape(Circle()).overlay { Circle().stroke(speaking ? accent : brand.border,lineWidth:2.5) }.shadow(color:speaking ? accent.opacity(0.45) : Color.black.opacity(0.15),radius:speaking ? 7 : 2,y:speaking ? 0 : 2)
            if let indicator { Image(systemName:indicator).font(.system(size:9,weight:.semibold)).foregroundStyle(speaking ? .white : brand.secondary).frame(width:21,height:21).background(speaking ? accent : brand.background,in:Circle()).overlay { Circle().stroke(brand.background,lineWidth:2) }.offset(x:2,y:2) }
        }.overlay(alignment:.top) { if user { Text(Self.appearance.text("you",language:app.learner.support).uppercased()).font(.system(size:7,weight:.heavy)).padding(.horizontal,5).padding(.vertical,2).background(PiyaliBrand.teal,in:Capsule()).foregroundStyle(.white).offset(y:-5) } }.accessibilityLabel(user ? Self.appearance.text("you",language:app.learner.support) : name)
    }
}
struct SourceCompanionSprite:View {
    let type:String
    var animated=false
    var body:some View {
        TimelineView(.animation(minimumInterval:0.18,paused:!animated)) { time in
            let normalized=type.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
            let key=["ghost","alien","robot","slime","dog","axolotl"].contains(normalized) ? normalized : "ghost"
            let frames=StoryCharacterAvatar.appearance.data["pets"][key].array,index=animated ? Int(time.date.timeIntervalSinceReferenceDate/0.18)%12 : 0
            Canvas { context,size in
                guard frames.indices.contains(index) else { return }
                let frame=frames[index],bounds=frame["bounds"],w=bounds["w"].number,h=bounds["h"].number
                guard w > 0,h > 0 else { return }
                let scale=min((size.width-8)/w,(size.height-8)/h),left=(size.width-w*scale)/2,top=(size.height-h*scale)/2+1
                for command in frame["commands"].array {
                    let rect=CGRect(x:left+(command["x"].number-bounds["x"].number)*scale,y:top+(command["y"].number-bounds["y"].number)*scale,width:command["w"].number*scale,height:command["h"].number*scale)
                    context.fill(command["shape"].string == "ellipse" ? Path(ellipseIn:rect) : Path(rect),with:.color(cssColor(command["fill"].string)))
                }
            }
        }
    }
    private func cssColor(_ value:String)->Color {
        if value.hasPrefix("#"),let number=UInt32(value.dropFirst(),radix:16) { return Color(red:Double((number>>16)&255)/255,green:Double((number>>8)&255)/255,blue:Double(number&255)/255) }
        let numbers=value.replacingOccurrences(of:"rgba(",with:"").replacingOccurrences(of:")",with:"").split(separator:",").compactMap { Double($0.trimmingCharacters(in:.whitespaces)) }
        return numbers.count == 4 ? Color(red:numbers[0]/255,green:numbers[1]/255,blue:numbers[2]/255,opacity:numbers[3]) : .clear
    }
}
