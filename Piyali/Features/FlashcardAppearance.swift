import SwiftUI

struct FlashcardPaint {
    let dark:Bool
    var brand:PiyaliBrand {.init(dark:dark)}
    func color(_ value:String)->Color {
        if value.contains("var(") {
            if value.contains("glass-bg-soft"){return PiyaliBrand.unitColor(dark ? "0b1220":"fff9f2").opacity(dark ? 0.12:0.88)};if value.contains("glass-bg"){return PiyaliBrand.unitColor(dark ? "0b1220":"fffcf7").opacity(dark ? 0.66:0.94)}
            if value.contains("surface-elevated"){return brand.surface};if value.contains("surface-muted"){return PiyaliBrand.unitColor(dark ? "182031":"efe4d5")};if value.contains("surface-frame"){return PiyaliBrand.unitColor(dark ? "94a3b8":"604d38").opacity(dark ? 0.42:0.3)};if value.contains("surface"){return PiyaliBrand.unitColor(dark ? "0b1220":"fdf9f2")};if value.contains("border"){return brand.border};return brand.text
        }
        if value.hasPrefix("whiteAlpha."),let alpha=Double(value.dropFirst(11)){return .white.opacity(alpha/1000)}
        if value.hasPrefix("blackAlpha."),let alpha=Double(value.dropFirst(11)){return .black.opacity(alpha/1000)}
        if value == "white" {return .white};if value == "teal"{return PiyaliBrand.unitColor("319795")}
        if value.hasPrefix("#") {let hex=String(value.dropFirst());if hex.count==8 {return PiyaliBrand.unitColor(String(hex.prefix(6))).opacity(Double(Int(hex.suffix(2),radix:16) ?? 255)/255)};return PiyaliBrand.unitColor(hex)}
        let pattern="[0-9.]+",r=try? NSRegularExpression(pattern:pattern),range=NSRange(value.startIndex...,in:value),parts=r?.matches(in:value,range:range).compactMap{Range($0.range,in:value).flatMap{Double(value[$0])}} ?? []
        if value.hasPrefix("rgb"),parts.count>=3{return Color(red:parts[0]/255,green:parts[1]/255,blue:parts[2]/255).opacity(parts.count>3 ? parts[3]:1)}
        return brand.text
    }
    func colors(_ value:String)->[Color] {
        let pattern="rgba?\\([^)]*\\)|#[0-9a-fA-F]{6,8}",r=try? NSRegularExpression(pattern:pattern)
        return (r?.matches(in:value,range:NSRange(value.startIndex...,in:value)).compactMap{Range($0.range,in:value).map{color(String(value[$0]))}}) ?? []
    }
}
struct FlashcardShell:View {
    let theme:JSONValue
    var dark=false
    var body:some View {
        let paint=FlashcardPaint(dark:dark),colors=paint.colors(theme["background"].string),base=paint.color(theme["bg"].string)
        GeometryReader {g in ZStack {
            base
            if colors.count>=2 {LinearGradient(colors:Array(colors.suffix(2)),startPoint:.top,endPoint:.bottom)}
            if dark,colors.count>3 {RadialGradient(colors:[colors[0],.clear],center:.init(x:0.2,y:0.15),startRadius:0,endRadius:g.size.width*0.6);RadialGradient(colors:[colors[1],.clear],center:.init(x:0.82,y:0.22),startRadius:0,endRadius:g.size.width*0.6)}
            Path{p in for x in stride(from:0.0,through:g.size.width,by:28){p.move(to:.init(x:x,y:0));p.addLine(to:.init(x:x,y:g.size.height))};for y in stride(from:0.0,through:g.size.height,by:28){p.move(to:.init(x:0,y:y));p.addLine(to:.init(x:g.size.width,y:y))}}.stroke((dark ? Color.white:Color.brown).opacity(dark ? 0.025:0.008),lineWidth:1)
        }}.clipShape(EntryCornerShape(radius:64)).overlay{EntryCornerShape(radius:64).stroke(FlashcardPaint(dark:dark).color("var(--app-surface-frame)"),lineWidth:3).padding(1.5)}
    }
}
struct FlashcardActionStyle:ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    var color:Color,edge:Color = .clear,text:Color = .white,height:CGFloat=74
    func makeBody(configuration:Configuration)->some View {configuration.label.font(PiyaliBrand.productFont(18,600)).frame(maxWidth:.infinity,minHeight:height).foregroundStyle(text).background{Capsule().fill(color).shadow(color:enabled ? edge:.clear,radius:0,y:configuration.isPressed ? 0:4)}.opacity(enabled ? 1:0.6).offset(y:configuration.isPressed ? 3:0)}
}

struct FlashcardIcon:View {let name:String;var size:CGFloat=20;var body:some View {Image("Flashcard-"+name).renderingMode(.template).resizable().frame(width:size,height:size)}}

/// The source's ::before/::after layers, rendered with native paths and gradients.
struct FlashcardTileTexture:View {
    let visuals:JSONValue
    let dark,actionable:Bool
    var body:some View {
        let paint=FlashcardPaint(dark:dark),colors=paint.colors(visuals["sx"]["&::before"]["background"].string)
        GeometryReader{g in ZStack {
            if dark,actionable,colors.count>=4 {
                LinearGradient(colors:Array(colors.suffix(2)),startPoint:.top,endPoint:.bottom)
                RadialGradient(colors:[colors[0],.clear],center:.init(x:0.2,y:0.15),startRadius:0,endRadius:g.size.width*0.42)
                RadialGradient(colors:[colors[1],.clear],center:.init(x:0.82,y:0.25),startRadius:0,endRadius:g.size.width*0.4)
                if colors.count>=5 {RadialGradient(colors:[colors[2],.clear],center:.init(x:0.5,y:1),startRadius:0,endRadius:g.size.width*0.62)}
            }
            if !dark || actionable {Path{p in for x in stride(from:0.0,through:g.size.width,by:28){p.move(to:.init(x:x,y:0));p.addLine(to:.init(x:x,y:g.size.height))};for y in stride(from:0.0,through:g.size.height,by:28){p.move(to:.init(x:0,y:y));p.addLine(to:.init(x:g.size.width,y:y))}}.stroke(dark ? Color(red:148/255,green:163/255,blue:184/255).opacity(0.024):Color(red:96/255,green:77/255,blue:56/255).opacity(0.0126),lineWidth:1)}
            if !actionable {LinearGradient(colors:[Color.white.opacity(dark ? 0.12:0.28),.clear],startPoint:.top,endPoint:.bottom).frame(height:g.size.height/2).frame(maxHeight:.infinity,alignment:.top)}
        }}.allowsHitTesting(false)
    }
}
struct FlashcardTileStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {configuration.label.scaleEffect(configuration.isPressed ? 0.98:1)}
}
