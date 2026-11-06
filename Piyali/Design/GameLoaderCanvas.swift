import SwiftUI
import QuartzCore

@MainActor final class GameLoaderModel:ObservableObject {
    let policy:GameLoaderPolicy?
    @Published var message:String?
    @Published var roomName:String?
    private(set) var error:String?
    var onSound:((String)->Void)?
    init(seed:Double=Date().timeIntervalSince1970*1000,support:String,pet:String,now:Double?=nil){
        policy=try? GameLoaderPolicy()
        do{let value=try policy?.run("create",.object(["seed":.number(seed),"now":.number(now ?? Date().timeIntervalSince1970*1000),"support":.string(support),"pet":.string(pet)]));update(value?.foundation ?? [:])}catch{self.error=error.localizedDescription}
    }
    func update(_ value:[String:Any]){
        for sound in value["sounds"] as? [String] ?? []{onSound?(sound)}
        let nextMessage=value["message"] as? String,nextRoom=value["roomName"] as? String
        if message != nextMessage{message=nextMessage};if roomName != nextRoom{roomName=nextRoom}
    }
}
struct GameLoaderCanvas:UIViewRepresentable {
    let model:GameLoaderModel
    var paused=false
    func makeUIView(context:Context)->GameLoaderCanvasView{let view=GameLoaderCanvasView();view.model=model;return view}
    func updateUIView(_ view:GameLoaderCanvasView,context:Context){view.paused=paused}
    static func dismantleUIView(_ view:GameLoaderCanvasView,coordinator:()){view.stop()}
}
@MainActor final class GameLoaderCanvasView:UIView{
    var model:GameLoaderModel?
    var paused=false{didSet{if paused{stop()}else if window != nil{begin()}}}
    private var link:CADisplayLink?,ops:[[Any]]=[],colors:[String:UIColor]=[:],touch:CGPoint?
    var isAnimating:Bool{link != nil}
    override init(frame:CGRect){super.init(frame:frame);backgroundColor=UIColor(red:8/255,green:20/255,blue:43/255,alpha:1);isOpaque=true;isAccessibilityElement=true;accessibilityIdentifier="gamePreparationWorld";accessibilityLabel="Explore while your game prepares";contentMode = .redraw}
    required init?(coder:NSCoder){fatalError("init(coder:) is unavailable")}
    override func didMoveToWindow(){super.didMoveToWindow();if window == nil{stop()}else if !paused{begin()}}
    private func begin(){guard link == nil else{return};let link=CADisplayLink(target:WeakTick(self),selector:#selector(WeakTick.tick));link.preferredFramesPerSecond=60;link.add(to:.main,forMode:.common);self.link=link}
    func stop(){link?.invalidate();link=nil;touch=nil}
    fileprivate func tick(){render(now:Date().timeIntervalSince1970*1000)}
    func render(now:Double){
        guard bounds.width>0,bounds.height>0,let policy=model?.policy else{return}
        do{let value=try policy.frame(width:bounds.width,height:bounds.height,now:now);ops=value["ops"] as? [[Any]] ?? [];model?.update(value);if let state=value["state"] as? [String:Any]{let position="\(state["currentRoom"] ?? ""),\(state["px"] ?? ""),\(state["py"] ?? "")";if accessibilityValue != position{accessibilityValue=position}};setNeedsDisplay()}catch{stop()}
    }
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?){touch=touches.first?.location(in:self)}
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){
        guard let start=touch,let end=touches.first?.location(in:self),let policy=model?.policy else{return};touch=nil
        let dx=end.x-start.x,dy=end.y-start.y,now=Date().timeIntervalSince1970*1000
        let operation:String,input:JSONValue
        if hypot(dx,dy)<15{operation="click";input = .object(["x":.number(end.x),"y":.number(end.y),"now":.number(now)])}
        else{operation="move";input = .object(["direction":.string(abs(dx)>abs(dy) ? dx>0 ? "right":"left":dy>0 ? "down":"up"),"now":.number(now)])}
        if let result=try? policy.run(operation,input){model?.update(result.foundation)}
    }
    override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?){touch=nil}
    override func draw(_ rect:CGRect){
        guard bounds.width>0,bounds.height>0,let ctx=UIGraphicsGetCurrentContext()else{return}
        let format=UIGraphicsImageRendererFormat();format.scale=1;format.opaque=true
        let image=UIGraphicsImageRenderer(size:bounds.size,format:format).image{paint($0.cgContext)}
        ctx.interpolationQuality = .none;image.draw(in:bounds)
    }
    private func paint(_ ctx:CGContext){
        ctx.interpolationQuality = .none
        for op in ops {
            guard let name=op.first as? String else{continue}
            func n(_ i:Int)->CGFloat{(op[i] as? NSNumber)?.doubleValue ?? 0}
            switch name{
            case "save":ctx.saveGState()
            case "restore":ctx.restoreGState()
            case "translate":ctx.translateBy(x:n(1),y:n(2))
            case "scale":ctx.scaleBy(x:n(1),y:n(2))
            case "rect":ctx.setFillColor(color(op[5] as? String ?? "#000").cgColor);ctx.setAlpha(n(6));ctx.fill(CGRect(x:n(1),y:n(2),width:n(3),height:n(4)))
            case "path":
                ctx.setFillColor(color(op[2] as? String ?? "#000").cgColor);ctx.setAlpha(n(3));ctx.beginPath()
                for part in op[1] as? [[Any]] ?? []{
                    func v(_ i:Int)->CGFloat{(part[i] as? NSNumber)?.doubleValue ?? 0}
                    if part[0] as? String == "arc"{ctx.addArc(center:CGPoint(x:v(1),y:v(2)),radius:v(3),startAngle:v(4),endAngle:v(5),clockwise:(part.count>6 ? part[6] as? Bool:false) ?? false)}
                    else{let path=CGPath(ellipseIn:CGRect(x:-v(3),y:-v(4),width:2*v(3),height:2*v(4)),transform:nil);var transform=CGAffineTransform(translationX:v(1),y:v(2)).rotated(by:v(5));ctx.addPath(path.copy(using:&transform) ?? path)}
                };ctx.fillPath()
            case "text":
                let text=op[1] as? String ?? "",fontSpec=op[4] as? String ?? "10px monospace",size=Double(fontSpec.components(separatedBy:CharacterSet.decimalDigits.inverted).filter{!$0.isEmpty}.first ?? "10") ?? 10,font=UIFont.monospacedSystemFont(ofSize:size,weight:fontSpec.contains("bold") ? .bold:.regular),attributes:[NSAttributedString.Key:Any]=[.font:font,.foregroundColor:color(op[6] as? String ?? "#000")],width=(text as NSString).size(withAttributes:attributes).width
                ctx.setAlpha(n(7));(text as NSString).draw(at:CGPoint(x:n(2)-(op[5] as? String == "center" ? width/2:0),y:n(3)-font.ascender),withAttributes:attributes)
            default:break
            }
        }
    }
    private func color(_ css:String)->UIColor{
        if let value=colors[css]{return value};let value:UIColor
        if css.hasPrefix("#"){var s=String(css.dropFirst());if s.count==3||s.count==4{s=s.map{String(repeating:String($0),count:2)}.joined()};if s.count==6{s+="ff"};let number=UInt64(s,radix:16) ?? 255;value=UIColor(red:Double((number>>24)&255)/255,green:Double((number>>16)&255)/255,blue:Double((number>>8)&255)/255,alpha:Double(number&255)/255)}
        else{let numbers=css.components(separatedBy:CharacterSet(charactersIn:"0123456789.-").inverted).compactMap(Double.init);value=numbers.count>=3 ? UIColor(red:numbers[0]/255,green:numbers[1]/255,blue:numbers[2]/255,alpha:numbers.count>3 ? numbers[3]:1):.black}
        colors[css]=value;return value
    }
    @MainActor private final class WeakTick:NSObject{weak var owner:GameLoaderCanvasView?;init(_ owner:GameLoaderCanvasView){self.owner=owner};@objc func tick(){owner?.tick()}}
}

/// The web mini-game uses Courier-style monospace and a left-to-right paragraph
/// even when a message contains Arabic; other product text has separate rules.
struct GameLoaderMonoText:UIViewRepresentable{
    let text:String
    var size:CGFloat=14,bold=false,fillWidth=true
    var color:Color = .primary
    func makeUIView(context:Context)->UILabel{let label=UILabel();label.isAccessibilityElement=true;label.accessibilityTraits = .staticText;label.setContentCompressionResistancePriority(.required,for:.vertical);return label}
    func updateUIView(_ label:UILabel,context:Context){
        let font=UIFont(name:bold ? "CourierNewPS-BoldMT":"CourierNewPSMT",size:size) ?? UIFont.monospacedSystemFont(ofSize:size,weight:bold ? .bold:.regular),paragraph=NSMutableParagraphStyle()
        paragraph.baseWritingDirection = .leftToRight;paragraph.alignment = .left;paragraph.minimumLineHeight=size*1.5;paragraph.maximumLineHeight=size*1.5
        label.numberOfLines=fillWidth ? 0:1;label.attributedText=NSAttributedString(string:text,attributes:[.font:font,.paragraphStyle:paragraph,.foregroundColor:UIColor(color)]);label.accessibilityLabel=text;label.invalidateIntrinsicContentSize()
    }
    func sizeThatFits(_ proposal:ProposedViewSize,uiView:UILabel,context:Context)->CGSize?{
        let width=fillWidth ? proposal.width ?? 360:10000,fit=uiView.sizeThatFits(CGSize(width:width,height:.greatestFiniteMagnitude));return CGSize(width:fillWidth ? width:fit.width,height:fit.height)
    }
}
