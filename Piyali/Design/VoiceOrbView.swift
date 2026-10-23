import SwiftUI
import SceneKit
import simd

struct OrbFeedback:Equatable { let id=UUID();let correct:Bool }
struct OrbDisplayReaction:Equatable {let id=UUID();let kind:String}

/// A native scene, using the reference sphere, pigment expression and eye paths.
struct VoiceOrbView:UIViewRepresentable {
    var state="idle"
    var callActive=false
    var feedback:OrbFeedback?
    var personality:OrbDisplayPersonality?
    var displayReaction:OrbDisplayReaction?
    var dragging=false
    var dragTurn=0.0
    var audioLevel=0.0
    var dark=false
    var reducedMotion=false
    var animating=true
    func makeUIView(context:Context)->VoiceOrbHost { VoiceOrbHost() }
    func updateUIView(_ view:VoiceOrbHost,context:Context) { view.configure(self) }
    static func dismantleUIView(_ view:VoiceOrbHost,coordinator:()) { view.stop() }
}

final class VoiceOrbHost:UIView {
    let sceneView=SCNView(frame:.zero)
    private let scene=SCNScene(),character=SCNNode(),bodyMaterial=SCNMaterial(),faceMaterial=SCNMaterial(),camera=SCNNode(),shadow=SCNNode()
    private var dots:[SCNNode]=[],sparks:[SCNNode]=[]
    private var link:CADisplayLink?,options=VoiceOrbView(),lastTime=0.0,time=0.0,phase=0.0,blinkAt=2.4,level=0.0,flowSpeed=0.16,tilt=0.0,pitch=0.0
    private var eyes=OrbVisuals.Eyes(mood:"sleepy"),previousBlink=0.0,mood="sleepy",defaultMood=["neutral","surprised"].randomElement()!,reactionMood:String?,reaction:String?,reactionStart=0.0,feedbackID:UUID?
    private var ripple=0.0,spiral=0.0,warp=0.0,turbulence=0.0,lastDark:Bool?
    private var reactionExpiry:Task<Void,Never>?
    private var observers:[NSObjectProtocol]=[]
    private var foreground=true,pointerTurn=0.0
    override init(frame:CGRect) {
        super.init(frame:frame);backgroundColor = .clear;isUserInteractionEnabled=false
        sceneView.backgroundColor = .clear;sceneView.isOpaque=false;sceneView.scene=scene;sceneView.antialiasingMode = .multisampling4X;sceneView.preferredFramesPerSecond=40;sceneView.isPlaying=false;sceneView.rendersContinuously=false
        addSubview(sceneView);buildScene()
        observers=[NotificationCenter.default.addObserver(forName:UIApplication.didEnterBackgroundNotification,object:nil,queue:.main){ [weak self] _ in self?.foreground=false;self?.updateRunning() },NotificationCenter.default.addObserver(forName:UIApplication.didBecomeActiveNotification,object:nil,queue:.main){ [weak self] _ in self?.foreground=true;self?.updateRunning() }]
        render(dt:0)
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() { super.layoutSubviews();sceneView.frame=bounds }
    override func didMoveToWindow() { super.didMoveToWindow();updateRunning() }
    func configure(_ options:VoiceOrbView) {
        self.options=options
        if options.dragging {pointerTurn=options.dragTurn}
        let signalID=options.displayReaction?.id ?? options.feedback?.id
        if feedbackID != signalID {
            reactionExpiry?.cancel();feedbackID=signalID;reactionStart=CACurrentMediaTime()
            if let display=options.displayReaction {reaction=display.kind;reactionMood=display.kind == "boop" ? "love" : nil}
            else if let feedback=options.feedback { reactionMood=(feedback.correct ? ["joy","love","excited"] : ["curious","sad"]).randomElement();reaction=feedback.correct ? ["wave","bounce","celebrate","spin"].randomElement() : nil }
            else { reaction=nil;reactionMood=nil }
            if let id=feedbackID {
                let duration=reaction.map {OrbVisuals.duration($0)+0.65} ?? 3.5
                reactionExpiry=Task { [weak self] in
                    do {try await Task.sleep(for:.seconds(duration))} catch {return}
                    guard let self,self.feedbackID == id else {return};self.reaction=nil;self.reactionMood=nil;self.render(dt:0)
                }
            }
        }
        render(dt:0);updateRunning()
    }
    private final class Tick:NSObject { weak var host:VoiceOrbHost?;init(_ host:VoiceOrbHost){self.host=host};@objc func run(_ link:CADisplayLink){host?.step(link.timestamp)} }
    private func updateRunning() {
        let running=window != nil && foreground && options.animating && !options.reducedMotion
        if running,link == nil { let timer=CADisplayLink(target:Tick(self),selector:#selector(Tick.run));timer.preferredFrameRateRange=CAFrameRateRange(minimum:20,maximum:40,preferred:40);timer.add(to:.main,forMode:.common);link=timer;lastTime=0 }
        else if !running { stop() }
    }
    func stop() { link?.invalidate();link=nil;lastTime=0 }
    private func step(_ timestamp:Double) { let dt=lastTime == 0 ? 0 : min(timestamp-lastTime,0.05);lastTime=timestamp;render(dt:dt) }
    private func buildScene() {
        camera.camera=SCNCamera();camera.camera?.fieldOfView=36;camera.camera?.zNear=0.1;camera.camera?.zFar=30;camera.position=SCNVector3(0,0,5);camera.look(at:SCNVector3(0,-0.18,0));scene.rootNode.addChildNode(camera);sceneView.pointOfView=camera
        camera.camera?.wantsHDR=false;camera.camera?.wantsExposureAdaptation=false;camera.camera?.exposureOffset=0.26;camera.camera?.bloomIntensity=0
        func light(_ color:UInt32,_ intensity:CGFloat,_ position:SCNVector3?,ambient:Bool=false) {
            let n=SCNNode();n.light=SCNLight();n.light?.type=ambient ? .ambient : .directional;n.light?.color=Self.color(color);n.light?.intensity=intensity
            if let position { n.position=position;n.look(at:SCNVector3Zero) };scene.rootNode.addChildNode(n)
        }
        if let room=Bundle.main.url(forResource:"orb-room",withExtension:"hdr") {scene.lightingEnvironment.contents=room;scene.lightingEnvironment.intensity=0.65}
        light(0xf8fffa,360,nil,ambient:true);light(0xfff6e5,1250,SCNVector3(-3,5,4));light(0xbdffee,700,SCNVector3(4,1,-2))
        bodyMaterial.lightingModel = .physicallyBased;bodyMaterial.diffuse.contents=UIColor.white;bodyMaterial.roughness.contents=0.28;bodyMaterial.metalness.contents=0.02;bodyMaterial.clearCoat.contents=0.72;bodyMaterial.clearCoatRoughness.contents=0.22
        if let url=Bundle.main.url(forResource:"orb-surface",withExtension:"shader"),let shader=try? String(contentsOf:url) {
            bodyMaterial.shaderModifiers=[.geometry:"#pragma varyings\nfloat3 orbPosition;\n#pragma body\nout.orbPosition = _geometry.position.xyz;",.surface:shader]
        }
        for key in ["orbTime","orbVoice","orbRipple","orbSpiral","orbWarp","orbTurbulence"] { bodyMaterial.setValue(NSNumber(value:0.0),forKey:key) }
        let body=SCNNode(geometry:Self.mesh(width:72,height:48,face:false));body.geometry?.materials=[bodyMaterial];character.addChildNode(body)
        let face=SCNNode(geometry:Self.mesh(width:40,height:30,face:true));faceMaterial.lightingModel = .constant;faceMaterial.isDoubleSided=false;faceMaterial.writesToDepthBuffer=false;faceMaterial.diffuse.contents=Self.faceImage(eyes.values,blink:0);face.geometry?.materials=[faceMaterial];face.renderingOrder=1;character.addChildNode(face);scene.rootNode.addChildNode(character)
        let plane=SCNPlane(width:3.5,height:1.45),mat=SCNMaterial();mat.lightingModel = .constant;mat.diffuse.contents=Self.shadowImage();mat.writesToDepthBuffer=false;plane.materials=[mat];shadow.geometry=plane;shadow.position=SCNVector3(0,-1.12,-0.2);shadow.eulerAngles.x = -.pi/2.7;shadow.scale=SCNVector3(0.72,0.72,0.72);scene.rootNode.addChildNode(shadow)
        for i in 0..<3 { let node=SCNNode(geometry:SCNSphere(radius:0.042));node.geometry?.firstMaterial?.diffuse.contents=Self.color(0x378e7b);node.position=SCNVector3(Double(i-1)*0.2+0.68,1.32,0);node.isHidden=true;scene.rootNode.addChildNode(node);dots.append(node) }
        let star=UIBezierPath();for i in 0..<8 { let a=Double(i)/8 * .pi*2,r=i%2 == 0 ? 1.0 : 0.25,p=CGPoint(x:cos(a)*r,y:sin(a)*r);if i == 0 {star.move(to:p)}else{star.addLine(to:p)} };star.close()
        for i in 0..<10 { let shape=SCNShape(path:star,extrusionDepth:0.08);shape.chamferRadius=0.03;let node=SCNNode(geometry:shape);node.geometry?.firstMaterial?.diffuse.contents=Self.color(i%2 == 0 ? 0x66cbae : 0xffc47e);node.isHidden=true;scene.rootNode.addChildNode(node);sparks.append(node) }
        if let url=Bundle.main.url(forResource:"orb-tone",withExtension:"shader"),let tone=try? String(contentsOf:url) {
            scene.rootNode.enumerateChildNodes { node,_ in
                for material in node.geometry?.materials ?? [] { var modifiers=material.shaderModifiers ?? [:];modifiers[.fragment]=tone+(material === self.faceMaterial ? "\n// Match the reference canvas ink after linear Metal alpha blending.\n_output.color.a = 1.0 - pow(1.0 - _output.color.a, 2.2);\n" : "");material.shaderModifiers=modifiers }
            }
        }
    }
    private func render(dt:Double) {
        let moving=options.animating && !options.reducedMotion
        let dt=moving ? dt : 0,amount=moving ? (options.personality == nil ? 0.7 : 1.5) : 0
        time += dt
        let elapsed=max(0,CACurrentMediaTime()-reactionStart),duration=reaction.map { OrbVisuals.duration($0) } ?? 0
        if elapsed >= (reaction == nil ? 3.5 : duration+0.65) { reactionMood=nil;reaction=nil }
        let currentMood=reactionMood ?? options.personality?.mood ?? (options.callActive ? defaultMood : "sleepy"),state=options.personality?.state ?? (options.callActive && ["idle","listening","thinking","speaking"].contains(options.state) ? options.state : "idle")
        if !options.dragging {pointerTurn *= exp(-dt*4.2)}
        let p=OrbVisuals.reaction(reaction ?? "",elapsed:elapsed,amount:amount)
        if time > blinkAt+0.18 { blinkAt=time+Double.random(in:2.8...5.5) }
        let blink=moving && time > blinkAt ? sin(OrbVisuals.clamp((time-blinkAt)/0.18) * .pi) : 0
        level += ((["speaking","listening"].contains(state) ? OrbVisuals.clamp(options.audioLevel) : 0)-level)*(1-exp(-dt*16))
        eyes.advance(mood:currentMood,state:state,time:time,dt:dt,immediate:!moving)
        if eyes.changed || previousBlink != blink || mood != currentMood { faceMaterial.diffuse.contents=Self.faceImage(eyes.values,blink:blink);mood=currentMood;previousBlink=blink }
        let sleepy=currentMood == "sleepy",a=moving ? 1-exp(-dt*5.5) : 1
        tilt += ((currentMood == "curious" ? -0.15 : sleepy ? 0.11 : 0)-tilt)*a
        pitch += ((sleepy ? 0.12 : state == "listening" ? -0.06 : 0)-pitch)*a
        let squash=p.squash+(options.dragging ? 0.075*amount : 0)
        let breath=sin(time*(sleepy ? 1.4 : 2.1))*0.018*amount,bounce=currentMood == "excited" ? abs(sin(time*4.7))*0.10*amount : 0,stretch=(state == "speaking" ? level*0.065 : level*0.018)*amount
        let blend=Float(moving ? 1-exp(-dt*12) : 1),position=SIMD3<Float>(Float(p.x),Float(min(0.14,0.04+sin(time*1.7)*0.045*amount+p.y+bounce)),0),scale=SIMD3<Float>(Float(1.04+squash*0.65-breath*0.4),Float(min(1.12,1-squash+breath+stretch)),Float(1+squash*0.35))
        character.simdPosition += (position-character.simdPosition)*blend;character.simdScale += (scale-character.simdScale)*blend
        let qx=simd_quatf(angle:Float(pitch+p.pitch),axis:SIMD3(1,0,0)),qy=simd_quatf(angle:Float(p.turn+pointerTurn*amount),axis:SIMD3(0,1,0)),qz=simd_quatf(angle:Float(tilt+p.roll+sin(time*1.15)*0.025*amount),axis:SIMD3(0,0,1));character.simdOrientation=simd_slerp(character.simdOrientation,qx*qy*qz,blend)
        let flow=OrbVisuals.data["flow"][state],f=moving ? 1-exp(-dt*3) : 1
        flowSpeed += (flow["speed"].number-flowSpeed)*f;phase += dt*flowSpeed
        ripple += (flow["listening"].number-ripple)*f;spiral += (flow["speaking"].number-spiral)*f;warp += (flow["thinking"].number-warp)*f;turbulence += (flow["listening"].number*0.4+flow["thinking"].number*0.65+flow["speaking"].number-turbulence)*f
        for (key,v) in [("orbTime",phase),("orbVoice",level),("orbRipple",ripple),("orbSpiral",spiral),("orbWarp",warp),("orbTurbulence",turbulence)] { bodyMaterial.setValue(NSNumber(value:v),forKey:key) }
        if lastDark != options.dark { lastDark=options.dark;let palette=OrbVisuals.data["palettes"].array.first{$0["id"].string == (options.dark ? "blue" : "mint")} ?? .null
            for (i,key) in ["orbDeep","orbMid","orbLight"].enumerated() { let hex=UInt32(palette["colors"].array[i].string.dropFirst(),radix:16) ?? 0;let channels=[(hex>>16)&255,(hex>>8)&255,hex&255].map { v->Float in let s=Double(v)/255;return Float(s <= 0.04045 ? s/12.92 : pow((s+0.055)/1.055,2.4)) };bodyMaterial.setValue(NSValue(scnVector3:SCNVector3(channels[0],channels[1],channels[2])),forKey:key) }
        }
        shadow.opacity=(options.dark ? 0.48 : 0.9)-p.y*0.4;let s=Float(0.72*(1+Double(character.position.y)*0.22));shadow.scale=SCNVector3(s,s,s)
        for (i,dot) in dots.enumerated() { dot.isHidden=state != "thinking";dot.position.y=Float(1.32+sin(time*4-Double(i)*0.7)*0.065*amount) }
        let celebration=reaction == "celebrate" && elapsed < duration,joyful=["excited","love"].contains(currentMood)
        for (i,spark) in sparks.enumerated() { spark.isHidden = !moving || !(celebration || (joyful && i < 3));if spark.isHidden {continue};let angle=Double(i)/10 * .pi*2+time*0.16,distance=celebration ? 1.15+elapsed*0.35 : 1.45;spark.position=SCNVector3(cos(angle)*distance,sin(angle)*distance*0.75+0.35,0.25+sin(Double(i)*2)*0.4);let s=Float((celebration ? 0.08 : 0.055)*(0.7+sin(time*3+Double(i))*0.3)*(celebration ? p.burst : 1));spark.scale=SCNVector3(s,s,s);spark.eulerAngles=SCNVector3(0,time*0.7+Double(i),sin(time+Double(i))*0.25);spark.opacity=celebration ? p.burst : 0.75 }
        sceneView.setNeedsDisplay()
        accessibilityLabel="Tutor orb, \(currentMood), \(state)";accessibilityValue=options.dark ? "Blue animated sphere" : "Mint animated sphere"
    }
    static func mesh(width:Int,height:Int,face:Bool)->SCNGeometry {
        var vertices:[SCNVector3]=[],uv:[CGPoint]=[],indices:[Int32]=[]
        for row in 0...height { for col in 0...width {
            let u=Double(col)/Double(width),v=Double(row)/Double(height)
            if face { let x=(u-0.5)*1.62,y=(0.5-v)*1.215+0.075,f=1-y*0.065,z=sqrt(max(0.01,1-pow(x/f,2)-y*y))*f;vertices.append(SCNVector3(x,y,z+0.012)) }
            else { let theta=v * .pi,phi=u * .pi*2,y=cos(theta),f=1-y*0.065;vertices.append(SCNVector3(-cos(phi)*sin(theta)*f,y,sin(phi)*sin(theta)*f)) }
            uv.append(CGPoint(x:u,y:v))
        } }
        for row in 0..<height { for col in 0..<width { let a=Int32(row*(width+1)+col),b=a+Int32(width+1);if face {indices += [a,b,a+1,b,b+1,a+1]}else{indices += [a,b,a+1,b,b+1,a+1]} } }
        var normals=Array(repeating:SIMD3<Float>(repeating:0),count:vertices.count)
        for i in stride(from:0,to:indices.count,by:3) {let a=Int(indices[i]),b=Int(indices[i+1]),c=Int(indices[i+2]);let p=vertices[a],q=vertices[b],r=vertices[c],n=simd_cross(SIMD3(q.x-p.x,q.y-p.y,q.z-p.z),SIMD3(r.x-p.x,r.y-p.y,r.z-p.z));normals[a] += n;normals[b] += n;normals[c] += n}
        let sources=[SCNGeometrySource(vertices:vertices),SCNGeometrySource(normals:normals.map{let n=simd_length_squared($0)>0 ? simd_normalize($0) : SIMD3<Float>(0,1,0);return SCNVector3(n.x,n.y,n.z)}),SCNGeometrySource(textureCoordinates:uv)]
        return SCNGeometry(sources:sources,elements:[SCNGeometryElement(indices:indices,primitiveType:.triangles)])
    }
    static func faceImage(_ values:[Double],blink:Double)->UIImage {
        let format=UIGraphicsImageRendererFormat();format.scale=1;format.opaque=false
        return UIGraphicsImageRenderer(size:CGSize(width:512,height:384),format:format).image { renderer in
            guard values.count == 263 else {return};let c=renderer.cgContext;c.saveGState();c.setAlpha(0.62);c.setFillColor(UIColor(red:OrbVisuals.clamp(values[256],0,255)/255,green:OrbVisuals.clamp(values[257],0,255)/255,blue:OrbVisuals.clamp(values[258],0,255)/255,alpha:1).cgColor);c.translateBy(x:256,y:144);c.scaleBy(x:1,y:max(0.065,1-blink));c.translateBy(x:-256,y:-144)
            for eye in 0..<2 { let offset=eye*128,last=offset+126;c.beginPath();c.move(to:CGPoint(x:(values[last]+values[offset])/2,y:(values[last+1]+values[offset+1])/2));for i in 0..<64 {let current=offset+i*2,next=offset+((i+1)%64)*2;c.addQuadCurve(to:CGPoint(x:(values[current]+values[next])/2,y:(values[current+1]+values[next+1])/2),control:CGPoint(x:values[current],y:values[current+1]))};c.closePath();c.fillPath() };c.restoreGState()
            if values[262]>0.001 {let cs=CGColorSpaceCreateDeviceRGB(),color=UIColor(red:values[259]/255,green:values[260]/255,blue:values[261]/255,alpha:OrbVisuals.clamp(values[262]));if let gradient=CGGradient(colorsSpace:cs,colors:[color.cgColor,color.withAlphaComponent(0).cgColor] as CFArray,locations:[0,1]) {for x in [140.0,372.0] {c.drawRadialGradient(gradient,startCenter:CGPoint(x:x,y:210),startRadius:1,endCenter:CGPoint(x:x,y:210),endRadius:29,options:[])}} }
        }
    }
    private static func shadowImage()->UIImage { let format=UIGraphicsImageRendererFormat();format.scale=1;return UIGraphicsImageRenderer(size:CGSize(width:128,height:128),format:format).image {r in let colors=[UIColor(red:25/255,green:56/255,blue:42/255,alpha:0.30).cgColor,UIColor(red:25/255,green:56/255,blue:42/255,alpha:0.16).cgColor,UIColor.clear.cgColor];if let g=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:colors as CFArray,locations:[0,0.4,1]){r.cgContext.drawRadialGradient(g,startCenter:CGPoint(x:64,y:64),startRadius:2,endCenter:CGPoint(x:64,y:64),endRadius:64,options:[])} } }
    private static func color(_ hex:UInt32)->UIColor { UIColor(red:Double((hex>>16)&255)/255,green:Double((hex>>8)&255)/255,blue:Double(hex&255)/255,alpha:1) }
    deinit { reactionExpiry?.cancel();link?.invalidate();observers.forEach(NotificationCenter.default.removeObserver) }
}
