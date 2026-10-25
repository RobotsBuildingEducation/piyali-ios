import SwiftUI
import SpriteKit

@MainActor final class RPGArt {
    static let shared=RPGArt()
    let data:JSONValue
    private var images:[String:UIImage]=[:]
    private init(){data=(try? ContentLibrary.load(JSONValue.self,name:"rpg-art")) ?? .null}
    func image(_ name:String)->Image {if let value=images[name]{return Image(uiImage:value)};let url=Bundle.main.url(forResource:name,withExtension:"png"),value=url.flatMap{UIImage(contentsOfFile:$0.path)} ?? UIImage();images[name]=value;return Image(uiImage:value)}
    func map(_ scenario:RPGScenario)->JSONValue{let world=data["worlds"][scenario.worldKey],specific=world["maps"][scenario.id];return specific == .null ? world["map"]:specific}
    func copy(_ key:String,lang:String)->String{let value=data["ui"][lang][key].string;return value.isEmpty ? data["ui"]["en"][key].string:value}
    func quest(_ key:String,lang:String,_ args:[String]=[])->String{var text=data["questLog"][lang][key].string;if text.isEmpty{text=data["questLog"]["en"][key].string};for(i,value)in args.enumerated(){text=text.replacingOccurrences(of:"{{\(i)}}",with:value)};return text}
}

/// The source Three renderer consists of depth-sorted 2D planes viewed through
/// an orthographic camera. SpriteKit keeps that same coordinate/texture model.
@MainActor final class RPGWorldScene:SKScene,ObservableObject {
    var onTile:((RPGPoint)->Void)?
    private let lens=SKCameraNode(),player=SKSpriteNode(),indicator=SKSpriteNode()
    private var mapKey="",pet="ghost",direction="down",playerTile:RPGPoint?,mapHeight=0,npcs:[SKSpriteNode]=[],frames:[SKTexture]=[],frameIndex = -1
    override init(size:CGSize){super.init(size:size);scaleMode = .resizeFill;backgroundColor = .clear;isUserInteractionEnabled=true;camera=lens;addChild(lens)}
    required init?(coder:NSCoder){fatalError("init(coder:) is unavailable")}
    private func texture(_ name:String)->SKTexture{let texture=SKTexture(imageNamed:name);texture.filteringMode = .nearest;return texture}
    func configure(_ run:RPGRun,pet:String,size:CGSize){
        if self.size != size{self.size=size};let art=RPGArt.shared.data,world=art["worlds"][run.scenario.worldKey];guard world != .null,!art["npcs"].array.isEmpty else{return}
        if mapKey != run.scenario.worldKey+run.id.uuidString {
            removeAllChildren();lens.removeAllChildren();addChild(lens);camera=lens;npcs=[];playerTile=nil;mapKey=run.scenario.worldKey+run.id.uuidString;mapHeight=run.world.height
            let color=UInt32(world["ambient"].number);backgroundColor=UIColor(red:CGFloat((color>>16)&255)/255,green:CGFloat((color>>8)&255)/255,blue:CGFloat(color&255)/255,alpha:1)
            let floor=SKSpriteNode(texture:texture(world["ground"].string));floor.size=CGSize(width:CGFloat(run.world.width*32),height:CGFloat(run.world.height*32));floor.position=CGPoint(x:floor.size.width/2,y:floor.size.height/2);floor.zPosition=0;addChild(floor)
            for prop in world["props"].array{let node=SKSpriteNode(texture:texture(prop["image"].string));node.size=CGSize(width:prop["width"].number*32,height:prop["height"].number*32);node.position=CGPoint(x:prop["x"].number*32,y:prop["y"].number*32);node.zPosition=CGFloat(prop["z"].number);addChild(node)}
            for(index,npc)in run.scenario.npcs.enumerated(){let variant=art["npcs"].array.first(where:{$0["image"].string == npc.appearance}) ?? art["npcs"].array[(index*5)%16],node=SKSpriteNode(texture:texture(variant["image"].string));let aspect=variant["aspect"].number;node.size=CGSize(width:32*0.9*max(0.45,min(1.4,aspect/(1.05/1.45)))*0.92,height:32*1.2*0.92);node.position=CGPoint(x:(Double(npc.tx)+0.5)*32,y:(Double(run.world.height-1-npc.ty)+0.62)*32);node.zPosition=CGFloat(1000+npc.ty*10+3);addChild(node);npcs.append(node)}
            player.size=CGSize(width:32*0.9,height:32*1.2);addChild(player)
            let grade=SKSpriteNode(texture:texture(world["grade"].string));grade.texture?.filteringMode = .linear;grade.name="grade";grade.zPosition=20000;lens.addChild(grade)
            indicator.texture=texture(art["indicator"].string);indicator.size=CGSize(width:16,height:19.2);indicator.zPosition=10000;addChild(indicator)
        }
        if self.pet != pet || frames.isEmpty{self.pet=pet;loadFrames()}
        if playerTile != run.position{let previous=playerTile;playerTile=run.position;if let previous{direction=run.position.y<previous.y ? "up":run.position.y>previous.y ? "down":run.position.x<previous.x ? "left":"right";loadFrames()}
            let point=CGPoint(x:(Double(run.position.x)+0.5)*32,y:(Double(mapHeight-1-run.position.y)+0.62)*32)
            player.removeAction(forKey:"walk");lens.removeAction(forKey:"follow")
            if previous == nil{player.position=point;lens.position=point}else{player.run(.move(to:point,duration:0.14),withKey:"walk");lens.run(.move(to:point,duration:0.14),withKey:"follow")}
            player.zPosition=CGFloat(1000+run.position.y*10+4)
        }
        if let npc=run.npc{indicator.position=CGPoint(x:(Double(npc.tx)+0.5)*32,y:(Double(mapHeight-1-npc.ty)+1.15)*32);indicator.isHidden=run.completed}else{indicator.isHidden=true}
        lens.setScale(320/max(1,size.height));(lens.childNode(withName:"grade") as? SKSpriteNode)?.size=CGSize(width:320*size.width/max(1,size.height),height:320)
    }
    private func loadFrames(){frames=RPGArt.shared.data["pets"][pet][direction].array.map{texture($0.string)};frameIndex = -1}
    override func update(_ currentTime:TimeInterval){let frame=Int(currentTime*7)%max(1,frames.count);if frame != frameIndex,!frames.isEmpty{player.texture=frames[frame];frameIndex=frame}}
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){guard let touch=touches.first else{return};let p=touch.location(in:self);onTile?(RPGPoint(x:Int(floor(p.x/32)),y:mapHeight-1-Int(floor(p.y/32))))}
}

struct RPGWorldView:View {
    let run:RPGRun,pet:String
    let onTile:(RPGPoint)->Void
    @StateObject private var scene=RPGWorldScene(size:CGSize(width:402,height:874))
    var body:some View{GeometryReader{g in SpriteView(scene:scene,options:[.allowsTransparency]).onAppear{scene.onTile=onTile;scene.configure(run,pet:pet,size:g.size)}.onDisappear{scene.onTile=nil}.onChange(of:run){_,value in scene.configure(value,pet:pet,size:g.size)}.onChange(of:pet){_,value in scene.configure(run,pet:value,size:g.size)}.onChange(of:g.size){_,value in scene.configure(run,pet:pet,size:value)}.accessibilityElement(children:.ignore).accessibilityLabel(RPGArt.shared.copy("touchMove",lang:run.support)).accessibilityValue("\(run.position.x),\(run.position.y)").accessibilityIdentifier("rpgWorld")}}
}

struct RPGPetPreview:View {
    let pet:String,size:CGFloat
    var animated=false
    var body:some View{TimelineView(.animation(minimumInterval:0.18,paused:!animated)){context in
        let frame=animated ? Int(context.date.timeIntervalSinceReferenceDate/0.18)%6:0
        RPGArt.shared.image("RPGPetPreview-\(pet)-\(frame)").interpolation(.none).resizable().scaledToFit().frame(width:size,height:size)
    }}
}
