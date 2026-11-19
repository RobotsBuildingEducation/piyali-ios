import Foundation

/// Source CSS keyframe interpolation, with independent transform/opacity tracks.
public enum MemoryCaptureMotion {
    public struct State:Equatable,Sendable {public var x=0.0,y=0.0,scale=1.0,rotation=0.0,opacity=1.0}
    private static func numbers(_ pattern:String,_ text:String)->[Double] {
        guard let re=try? NSRegularExpression(pattern:pattern),let m=re.firstMatch(in:text,range:NSRange(text.startIndex...,in:text)) else{return []}
        return (1..<m.numberOfRanges).compactMap{Range(m.range(at:$0),in:text).flatMap{Double(text[$0])}}
    }
    public static func transform(_ raw:String)->State {
        var value=State();let xy=numbers(#"translate3d\(\s*([-\d.]+)(?:px)?,\s*([-\d.]+)"#,raw)
        value.x=xy.first ?? 0;value.y=xy.last ?? numbers(#"translateY\(([-\d.]+)(?:px)?\)"#,raw).first ?? 0
        value.scale=numbers(#"scale\(([-\d.]+)\)"#,raw).first ?? 1;value.rotation=numbers(#"rotate\(([-\d.]+)deg\)"#,raw).first ?? 0;return value
    }
    private static func ease(_ x:Double,_ kind:String)->Double {
        guard kind != "linear" else{return x};let a=kind == "ease-out" ? 0.0:0.42,b=0.58
        func bezier(_ t:Double,_ p:Double,_ q:Double)->Double {3*(1-t)*(1-t)*t*p+3*(1-t)*t*t*q+t*t*t}
        var low=0.0,high=1.0
        for _ in 0..<28 {let middle=(low+high)/2;if bezier(middle,a,b)<x{low=middle}else{high=middle}}
        return bezier((low+high)/2,0,1)
    }
    public static func sample(_ frames:JSONValue,progress:Double,timing:String,variables:JSONValue = .object([:]))->State {
        var result=State();let progress=max(0,min(1,progress))
        for property in ["opacity","transform"] {
            var track:[(Double,JSONValue)]=[]
            for(key,value)in frames.object where value[property] != .null {for part in key.split(separator:","){if let at=Double(part.trimmingCharacters(in:.whitespaces).replacingOccurrences(of:"%",with:"")){track.append((at/100,value[property]))}}}
            track.sort{$0.0<$1.0};guard let first=track.first,let last=track.last else{continue}
            let left=track.last{$0.0<=progress} ?? first,right=track.first{$0.0>=progress} ?? last
            let amount=left.0 == right.0 ? 0:ease((progress-left.0)/(right.0-left.0),timing)
            func mix(_ a:Double,_ b:Double)->Double {a+(b-a)*amount}
            if property == "opacity" {result.opacity=mix(left.1.number,right.1.number)}
            else {
                func resolve(_ value:JSONValue)->State {var raw=value.string;for(key,value)in variables.object{raw=raw.replacingOccurrences(of:"var(\(key))",with:value.string)};return transform(raw)}
                let a=resolve(left.1),b=resolve(right.1);result.x=mix(a.x,b.x);result.y=mix(a.y,b.y);result.scale=mix(a.scale,b.scale);result.rotation=mix(a.rotation,b.rotation)
            }
        }
        return result
    }
    public static func shard(_ design:JSONValue,index:Int,elapsed:Double)->State {
        let shard=design["shards"].array[index]
        return sample(design["keyframes"]["@keyframes memoryCrystalGather"],progress:(elapsed*1000-shard["delay"].number)/2550,timing:"ease-in-out",variables:shard["style"])
    }
    public static func crystal(_ design:JSONValue,elapsed:Double)->State {sample(design["keyframes"]["@keyframes memoryCrystalCatch"],progress:elapsed/2.740,timing:"ease-out")}
    public static func trigger(_ design:JSONValue,elapsed:Double)->State {sample(design["trigger"]["sx"]["@keyframes activityMenuMemoryCatch"],progress:elapsed/2.760,timing:"linear")}
    public static func glint(_ design:JSONValue,index:Int,elapsed:Double)->State {
        let facet=design["shards"].array[index]["facets"].array.last ?? .null,delay=Double(facet["animationDelay"].string.replacingOccurrences(of:"ms",with:"")) ?? 0,time=max(0,elapsed*1000-delay),progress=time>=1800 ? 1:time.truncatingRemainder(dividingBy:900)/900
        return sample(design["keyframes"]["@keyframes crystalShardGlint"],progress:progress,timing:"ease-in-out")
    }
}
