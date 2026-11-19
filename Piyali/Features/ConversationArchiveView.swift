import SwiftUI
import UIKit

/// Word positions and cubic trajectories follow Conversations.jsx's archive stream.
struct ConversationArchive:Identifiable {
    struct Word:Identifiable {let id:Int,text:String,rect:CGRect,line:Int}
    struct Trajectory {let origin:CGPoint,control1:CGPoint,control2:CGPoint,destination:CGPoint,duration:Double,delay:Double,lengths:[CGFloat]}
    let id=UUID(),started:Date,source:CGRect,target:CGRect,words:[Word],height:CGFloat,trajectories:[Trajectory]
    static let hold=0.170,highlight=1.350,finish=1.212

    init?(text:String,source:CGRect,target:CGRect,started:Date=Date()) {
        guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,source.width>0,source.height>0,target.width>0,target.height>0 else{return nil}
        let paragraph=NSMutableParagraphStyle();paragraph.minimumLineHeight=25;paragraph.maximumLineHeight=25;paragraph.lineBreakMode = .byWordWrapping
        let attributed=NSAttributedString(string:text,attributes:[.font:UIFont.systemFont(ofSize:16),.paragraphStyle:paragraph,.kern:0.16])
        let storage=NSTextStorage(attributedString:attributed),layout=NSLayoutManager(),container=NSTextContainer(size:CGSize(width:max(72,source.width),height:100_000));container.lineFragmentPadding=0;container.maximumNumberOfLines=0;layout.addTextContainer(container);storage.addLayoutManager(layout);layout.ensureLayout(for:container)
        let pattern=try? NSRegularExpression(pattern:"\\S+"),ns=text as NSString
        var words:[Word]=[],lineIndex=0
        layout.enumerateLineFragments(forGlyphRange:NSRange(location:0,length:layout.numberOfGlyphs)) { _,_,_,glyphRange,_ in
            let lineRange=layout.characterRange(forGlyphRange:glyphRange,actualGlyphRange:nil)
            for match in pattern?.matches(in:text,range:lineRange) ?? [] {
                let range=layout.glyphRange(forCharacterRange:match.range,actualCharacterRange:nil),rect=layout.boundingRect(forGlyphRange:range,in:container);guard !rect.isEmpty else{continue}
                words.append(Word(id:words.count,text:ns.substring(with:match.range),rect:rect,line:lineIndex))
            }
            lineIndex += 1
        }
        guard !words.isEmpty else{return nil}
        let height=max(25,layout.usedRect(for:container).height),destination=CGPoint(x:target.midX,y:target.midY),center=CGPoint(x:source.midX,y:source.minY+height/2),dx=destination.x-center.x,dy=destination.y-center.y,length=max(1,hypot(dx,dy)),perpX = -dy/length,perpY=dx/length
        let maxDistance=max(1,words.map{hypot(destination.x-(source.minX+$0.rect.midX),destination.y-(source.minY+$0.rect.midY))}.max() ?? 1)
        let paths=words.map { word in
            let origin=CGPoint(x:source.minX+word.rect.midX,y:source.minY+word.rect.midY),distance=hypot(destination.x-origin.x,destination.y-origin.y),order=words.count>1 ? Double(word.id)/Double(words.count-1):0
            let a=Self.noise(Double(word.id+word.line*31+1)),b=Self.noise(Double(word.id)*1.37+17),ribbon=(order-0.5)*Double(min(source.width*0.16,34))+(a-0.5)*8
            let c1=CGPoint(x:center.x+dx*0.18+perpX*ribbon*0.55,y:center.y+dy*0.18+perpY*ribbon*0.22-8+(b-0.5)*4),c2=CGPoint(x:center.x+dx*0.66+perpX*ribbon*0.18,y:center.y+dy*0.66+perpY*ribbon*0.1-2)
            var lengths:[CGFloat]=[0],last=origin,total:CGFloat=0
            for index in 1...40 {let point=Self.point(origin,c1,c2,destination,CGFloat(index)/40);total+=hypot(point.x-last.x,point.y-last.y);lengths.append(total);last=point}
            return Trajectory(origin:origin,control1:c1,control2:c2,destination:destination,duration:Double(680+round(distance/maxDistance*150))/1000,delay:max(0,round(order*180+(a-0.5)*22))/1000,lengths:lengths)
        }
        self.started=started;self.source=source;self.target=target;self.words=words;self.height=height;self.trajectories=paths
    }
    private static func noise(_ seed:Double)->Double {let value=sin(seed*12.9898)*43758.5453123;return value-floor(value)}
    /// CSS cubic-bezier(0.12, 0.86, 0.24, 1), with x solved by bisection.
    static func eased(_ progress:Double)->Double {
        let x=max(0,min(1,progress));var low=0.0,high=1.0
        for _ in 0..<18 {let t=(low+high)/2,u=1-t,v=3*u*u*t*0.12+3*u*t*t*0.24+t*t*t;if v<x{low=t}else{high=t}}
        let t=(low+high)/2,u=1-t;return 3*u*u*t*0.86+3*u*t*t+t*t*t
    }
    struct Pose {let center:CGPoint,scaleX:CGFloat,scaleY:CGFloat,opacity:Double,blur:CGFloat}
    private static func point(_ a:CGPoint,_ b:CGPoint,_ c:CGPoint,_ d:CGPoint,_ t:CGFloat)->CGPoint {
        let u=1-t;return CGPoint(x:u*u*u*a.x+3*u*u*t*b.x+3*u*t*t*c.x+t*t*t*d.x,y:u*u*u*a.y+3*u*u*t*b.y+3*u*t*t*c.y+t*t*t*d.y)
    }
    func pose(_ word:Word,elapsed:Double)->Pose {
        let path=trajectories[word.id],progress=Self.eased((elapsed-path.delay)/path.duration),distance=CGFloat(progress)*(path.lengths.last ?? 0)
        var upper=path.lengths.firstIndex(where:{$0>=distance}) ?? 40;upper=max(1,upper)
        let before=path.lengths[upper-1],after=path.lengths[upper],fraction=after>before ? (distance-before)/(after-before):0,t=(CGFloat(upper-1)+fraction)/40
        // WebKit's offset-path anchors the span's center at its positioned top-left.
        let point=Self.point(path.origin,path.control1,path.control2,path.destination,t)
        return Pose(center:CGPoint(x:point.x-word.rect.width/2,y:point.y-(word.rect.midY-CGFloat(word.line)*25)),scaleX:1-0.88*progress,scaleY:1-0.78*progress,opacity:1-progress,blur:6*progress)
    }
}

struct ConversationArchiveView:View {
    let archive:ConversationArchive,dark:Bool
    var fixedElapsed:Double?=nil
    var body:some View {
        TimelineView(.animation(minimumInterval:1/60,paused:fixedElapsed != nil)) { time in
            let elapsed=fixedElapsed ?? time.date.timeIntervalSince(archive.started)
            Canvas { context,_ in
                let glowTime=max(0,min(1,elapsed/0.8)),glow=pow(1-glowTime,2),glowScale=0.52+0.46*glow
                if glow>0 {var layer=context;layer.opacity=0.35*glow;layer.addFilter(.blur(radius:16));let rect=CGRect(x:archive.source.minX,y:archive.source.minY,width:archive.source.width,height:archive.height);layer.translateBy(x:rect.midX,y:rect.midY);layer.scaleBy(x:glowScale,y:glowScale);layer.translateBy(x:-rect.midX,y:-rect.midY);layer.fill(Path(roundedRect:rect,cornerRadius:20),with:.linearGradient(Gradient(colors:[PiyaliBrand.unitColor("67e8f9").opacity(0.22),PiyaliBrand.unitColor("38bdf8").opacity(0.06)]),startPoint:rect.origin,endPoint:CGPoint(x:rect.maxX,y:rect.maxY)))}
                for word in archive.words {
                    let pose=archive.pose(word,elapsed:elapsed);guard pose.opacity>0 else{continue}
                    var layer=context;layer.opacity=pose.opacity;layer.translateBy(x:pose.center.x,y:pose.center.y);layer.scaleBy(x:pose.scaleX,y:pose.scaleY);layer.addFilter(.blur(radius:pose.blur))
                    let resolved=layer.resolve(Text(word.text).font(PiyaliBrand.productFont(16)).tracking(0.16).foregroundStyle(dark ? PiyaliBrand.unitColor("e5e7eb"):PiyaliBrand.unitColor("2f261d")))
                    layer.draw(resolved,at:.zero,anchor:.center)
                }
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}
