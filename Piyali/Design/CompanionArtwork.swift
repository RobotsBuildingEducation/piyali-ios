import SwiftUI

/// Frames recorded directly from the reference's shared canvas pixel drawer.
struct CompanionArtwork:View {
    let type:String
    var health:Int?=nil
    var animated=true
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    private static let frames=(try? ContentLibrary.load([String:JSONValue].self,name:"companion-preview")) ?? [:]
    private static let stages=(try? ContentLibrary.load([String:JSONValue].self,name:"companion-stages")) ?? [:]
    private let intervals:[String:Double] = ["ghost":0.17,"alien":0.15,"robot":0.18,"slime":0.14,"dog":0.15,"axolotl":0.2]
    var body:some View {
        let interval=health == nil ? intervals[type] ?? 0.17 : 0.18
        TimelineView(.animation(minimumInterval:interval,paused:reducedMotion || !animated || health == 0)) { time in
            let frames=health.map { Self.stages[FocusCopy.stage($0)]?[type].array ?? [] } ?? Self.frames[type]?.array ?? []
            let index=reducedMotion || !animated || health == 0 ? 0 : Int(time.date.timeIntervalSinceReferenceDate / interval) % 12
            Canvas { context,size in
                guard frames.indices.contains(index) else { return }
                context.scaleBy(x:size.width/48,y:size.height/48)
                for rectangle in frames[index].array {
                    let r=rectangle.array
                    guard r.count == 6 else { continue }
                    context.fill(Path(CGRect(x:r[0].number,y:r[1].number,width:r[2].number,height:r[3].number)),with:.color(Self.color(r[4].string).opacity(r[5].number)),style:FillStyle(antialiased:false))
                }
            }
        }.accessibilityHidden(true)
    }
    private static func color(_ css:String) -> Color {
        if css.hasPrefix("#"),let n=UInt32(css.dropFirst(),radix:16) { return Color(red:Double((n>>16)&255)/255,green:Double((n>>8)&255)/255,blue:Double(n&255)/255) }
        let values=css.replacingOccurrences(of:"rgba(",with:"").replacingOccurrences(of:")",with:"").split(separator:",").compactMap { Double($0.trimmingCharacters(in:.whitespaces)) }
        guard values.count >= 3 else { return .clear }
        return Color(red:values[0]/255,green:values[1]/255,blue:values[2]/255,opacity:values.count > 3 ? values[3] : 1)
    }
}
