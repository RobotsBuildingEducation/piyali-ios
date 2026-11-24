import SwiftUI

/// Source crystal facets and vector bookmark; a native, finite animation.
enum MemoryCaptureDesign {static let data=(try? ContentLibrary.load(JSONValue.self,name:"memory-capture-design")) ?? .null}
private struct MemoryCrystalPolygon:Shape {
    let value:String
    func path(in rect:CGRect)->Path {
        let pairs=value.replacingOccurrences(of:"polygon(",with:"").replacingOccurrences(of:")",with:"").split(separator:",").compactMap{part->CGPoint? in let n=part.split(whereSeparator:{$0 == " "}).compactMap{Double($0.replacingOccurrences(of:"%",with:""))};return n.count == 2 ? CGPoint(x:rect.minX+rect.width*n[0]/100,y:rect.minY+rect.height*n[1]/100):nil}
        var path=Path();guard let first=pairs.first else{return path};path.move(to:first);pairs.dropFirst().forEach{path.addLine(to:$0)};path.closeSubpath();return path
    }
}
private enum CrystalPaint {
    static func matches(_ pattern:String,_ text:String)->[String] {guard let re=try? NSRegularExpression(pattern:pattern)else{return []};return re.matches(in:text,range:NSRange(text.startIndex...,in:text)).compactMap{Range($0.range,in:text).map{String(text[$0])}}}
    static func colors(_ raw:String)->[Color] {matches(#"rgba?\([^)]*\)|#[a-fA-F0-9]{6}|\bwhite\b"#,raw).map{token in
        if token == "white"{return .white};if token.hasPrefix("#"){return PiyaliBrand.unitColor(token)}
        let n=matches(#"[\d.]+"#,token).compactMap(Double.init);return n.count>=3 ? Color(.sRGB,red:n[0]/255,green:n[1]/255,blue:n[2]/255,opacity:n.count>3 ? n[3]:1):.clear
    }}
    static func number(_ text:String)->Double {Double(matches(#"-?[\d.]+"#,text).first ?? "") ?? 0}
}
private struct MemoryCrystalFacet:View,Equatable {
    let data:JSONValue,size:CGFloat
    var motion:MemoryCaptureMotion.State?=nil
    private func percent(_ key:String,_ fallback:Double)->Double {data[key] == .null ? fallback:CrystalPaint.number(data[key].string)/100}
    var body:some View {
        let inset=percent("inset",0),w=size*percent("width",1-2*inset),h=size*percent("height",1-2*inset),x=size*percent("left",data["right"] == .null ? inset:1-percent("right",0)-w/size),y=size*percent("top",data["bottom"] == .null ? inset:1-percent("bottom",0)-h/size)
        let raw=data["background"].string.isEmpty ? data["bg"].string:data["background"].string,colors=CrystalPaint.colors(raw),angle=CrystalPaint.number(raw)*Double.pi/180
        let gradient=LinearGradient(stops:colors.enumerated().map{i,c in .init(color:c,location:colors.count == 3 ? [0,0.42,1][i]:Double(i)/Double(max(1,colors.count-1)))},startPoint:UnitPoint(x:0.5-sin(angle)/2,y:0.5+cos(angle)/2),endPoint:UnitPoint(x:0.5+sin(angle)/2,y:0.5-cos(angle)/2))
        let shadow=data["filter"].string,blur=CrystalPaint.number(shadow.replacingOccurrences(of:"drop-shadow(0 0 ",with:"")),rotation=motion?.rotation ?? MemoryCaptureMotion.transform(data["transform"].string).rotation
        ZStack{if raw.hasPrefix("linear-gradient"){gradient}else{colors.first ?? .clear}}
            .frame(width:w,height:h).overlay(alignment:.topLeading){if data["_after"] != .null {let after=data["_after"];(CrystalPaint.colors(after["bg"].string).first ?? .clear).frame(width:w*CrystalPaint.number(after["width"].string)/100,height:h*CrystalPaint.number(after["height"].string)/100).clipShape(MemoryCrystalPolygon(value:after["clipPath"].string)).offset(x:w*CrystalPaint.number(after["left"].string)/100,y:h*CrystalPaint.number(after["top"].string)/100)}}
            .shadow(color:CrystalPaint.colors(shadow).first ?? .clear,radius:blur).clipShape(MemoryCrystalPolygon(value:data["clipPath"].string))
            .rotationEffect(.degrees(rotation)).scaleEffect(motion?.scale ?? 1).opacity(motion?.opacity ?? 1).position(x:x+w/2,y:y+h/2)
    }
}
struct MemoryCaptureCrystals:View {
    let elapsed:Double
    var reduceMotion=false
    var body:some View {
        GeometryReader{geometry in
            let design=MemoryCaptureDesign.data
            if !reduceMotion {
                ForEach(Array(design["shards"].array.enumerated()),id:\.offset){index,shard in
                    let state=MemoryCaptureMotion.shard(design,index:index,elapsed:elapsed),side=CrystalPaint.number(shard["width"].string)
                    ZStack(alignment:.topLeading){ForEach(Array(shard["facets"].array.enumerated()),id:\.offset){facetIndex,facet in MemoryCrystalFacet(data:facet,size:side,motion:facetIndex == 3 ? MemoryCaptureMotion.glint(design,index:index,elapsed:elapsed):nil).equatable()}}
                        .frame(width:side,height:side).rotationEffect(.degrees(state.rotation)).scaleEffect(state.scale).opacity(state.opacity).position(x:geometry.size.width/2+state.x,y:geometry.size.height/2+state.y)
                }
                let caught=MemoryCaptureMotion.crystal(design,elapsed:elapsed),side=CrystalPaint.number(design["catch"]["width"].string)
                ZStack(alignment:.topLeading){ForEach(Array(design["catch"]["facets"].array.enumerated()),id:\.offset){_,facet in MemoryCrystalFacet(data:facet,size:side).equatable()}}.frame(width:side,height:side).scaleEffect(caught.scale).opacity(caught.opacity).position(x:geometry.size.width/2,y:geometry.size.height/2)
            }
        }.environment(\.layoutDirection,.leftToRight).allowsHitTesting(false).accessibilityHidden(true)
    }
}
struct MemoryCaptureMenuButton:View {
    @ObservedObject var capture:MemoryCaptureController
    let scope:String,language:String,label:String
    let glyphSize:CGFloat,size:CGFloat,radius:CGFloat,background:Color,border:Color,foreground:Color
    let action:()->Void
    var frozenElapsed:Double?=nil
    var reducedMotionOverride:Bool?=nil
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private var reduceMotion:Bool {reducedMotionOverride ?? systemReduceMotion}
    var body:some View {
        let event=capture.current(in:scope),active=event != nil || frozenElapsed != nil
        // Keep the logical button and its hit frame stable as the effect ends.
        Button(action:action){TimelineView(.animation(minimumInterval:1/60,paused:event == nil || scenePhase != .active || reduceMotion)){timeline in visual(elapsed:frozenElapsed ?? event.map{timeline.date.timeIntervalSince($0.startedAt)})}.frame(width:size,height:size)}
            .buttonStyle(.plain).frame(width:size,height:size).contentShape(Rectangle())
            .accessibilityLabel(label).accessibilityValue(active ? EntryCopy.ui(language,"vocab_note_saved"):"").accessibilityIdentifier("productMenu")
    }
    private func visual(elapsed:Double?)->some View {
        let motion=elapsed.map{MemoryCaptureMotion.trigger(MemoryCaptureDesign.data,elapsed:$0)},active=elapsed != nil
        return Group{if active{Image("Memory-captured").resizable().renderingMode(.template).scaledToFit().frame(width:20,height:20)}else{SourceActivityMenuGlyph().frame(width:glyphSize,height:glyphSize)}}.foregroundStyle(active ? PiyaliBrand.unitColor("ecc94b"):foreground).frame(width:size,height:size).background(background,in:RoundedRectangle(cornerRadius:radius)).overlay{RoundedRectangle(cornerRadius:radius).stroke(border)}
            .scaleEffect(reduceMotion ? 1:motion?.scale ?? 1).offset(y:reduceMotion ? 0:motion?.y ?? 0)
            .overlay{if let elapsed{MemoryCaptureCrystals(elapsed:elapsed,reduceMotion:reduceMotion)}}
    }
}
struct MemoryCaptureMenuItem<Content:View>:View {
    @ObservedObject var capture:MemoryCaptureController
    let scope:String,content:(Bool)->Content
    var body:some View {content(capture.current(in:scope) != nil)}
}
