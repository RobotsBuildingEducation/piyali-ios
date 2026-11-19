import SwiftUI
import SpriteKit

@MainActor final class RPGArt {
    static let shared=RPGArt()
    let data:JSONValue
    let environment:RPGEnvironmentLibrary?
    let exploration:JSONValue
    private var explorationGeometry:[(String,RPGWorld)]=[]
    private var images:[String:UIImage]=[:]
    private init(){data=(try? ContentLibrary.load(JSONValue.self,name:"rpg-art")) ?? .null;environment=try? ContentLibrary.load(RPGEnvironmentLibrary.self,name:"rpg-environment");exploration=(try? ContentLibrary.load(JSONValue.self,name:"exploration-art")) ?? .null
        explorationGeometry=exploration["geometry"].object.compactMap{key,value in guard let world=try? JSONDecoder().decode(RPGWorld.self,from:Data(value.json.utf8)) else{return nil};return (key,world)}
    }
    func world(_ key:String)->JSONValue { let value=data["worlds"][key];return value == .null ? exploration["worlds"][key]:value }
    func explorationKey(_ area:ExplorationMap)->String? { area.worldKey ?? explorationGeometry.first{$0.1 == area.world}?.0 }
    func searchCopy(_ key:String,lang:String,args:[String]=[])->String {var value=exploration["copy"][lang][key].string;if value.isEmpty{value=exploration["copy"]["en"][key].string};for (index,arg)in args.enumerated(){value=value.replacingOccurrences(of:"{{\(index)}}",with:arg)};return value}
    func itemImage(_ item:JSONValue)->String { let sprite=item["sprite"].string;return exploration["itemImages"][sprite].string.isEmpty ? exploration["itemImages"]["default"].string:exploration["itemImages"][sprite].string }

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
    private var mapKey="",pet="ghost",direction="down",playerTile:RPGPoint?,mapHeight=0,npcs:[SKSpriteNode]=[],frames:[String]=[],playerImage=""
    private var textureCache:[String:SKTexture]=[:],environmentNodes:[(node:SKSpriteNode,layer:RPGEnvironmentLayer)]=[]
    private var itemNodes:[SKSpriteNode]=[],itemMarkers:[RPGWorldMarker]=[]
    private var visualStart:TimeInterval?,lastFrameTime:TimeInterval?,previewTime:TimeInterval?,activeNPCIndex=0
    private var environmentElapsed:TimeInterval=0
    private var petClock=RPGPetAnimationClock()
    override init(size:CGSize){super.init(size:size);scaleMode = .resizeFill;backgroundColor = .clear;isUserInteractionEnabled=true;camera=lens;addChild(lens)}
    required init?(coder:NSCoder){fatalError("init(coder:) is unavailable")}
    private func texture(_ name:String)->SKTexture{if let cached=textureCache[name]{return cached};let texture=SKTexture(imageNamed:name);texture.filteringMode = .nearest;textureCache[name]=texture;return texture}
    func configure(_ run:RPGRun,pet:String,size:CGSize,environmentTime:TimeInterval?=nil,actorsVisible:Bool=true){
        previewTime=environmentTime;activeNPCIndex=run.step?.npcIdx ?? 0
        if self.size != size{self.size=size};let art=RPGArt.shared.data,world=RPGArt.shared.world(run.scenario.worldKey);guard world != .null,!art["npcs"].array.isEmpty else{return}
        if mapKey != run.scenario.worldKey+":"+run.scenario.id+":"+run.id.uuidString {
            removeAllChildren();lens.removeAllChildren();addChild(lens);camera=lens;npcs=[];itemNodes=[];itemMarkers=[];environmentNodes=[];textureCache=[:];playerImage="";playerTile=nil;mapKey=run.scenario.worldKey+":"+run.scenario.id+":"+run.id.uuidString;mapHeight=run.world.height
            let color=UInt32(world["ambient"].number);backgroundColor=RPGArt.shared.data["worlds"][run.scenario.worldKey] == .null ? .clear:UIColor(red:CGFloat((color>>16)&255)/255,green:CGFloat((color>>8)&255)/255,blue:CGFloat(color&255)/255,alpha:1)
            let floor=SKSpriteNode(texture:texture(world["ground"].string));floor.size=CGSize(width:CGFloat(run.world.width*32),height:CGFloat(run.world.height*32));floor.position=CGPoint(x:floor.size.width/2,y:floor.size.height/2);floor.zPosition=0;addChild(floor)
            if let plan=RPGArt.shared.environment?.plan(run.scenario){
                for layer in plan.layers{let node=SKSpriteNode(texture:texture(layer.image));node.texture?.filteringMode=layer.smooth ? .linear:.nearest;node.size=CGSize(width:layer.width,height:layer.height);node.zPosition=layer.z;node.blendMode=layer.blend == "add" ? .add:.alpha;apply(layer.frame(at:environmentTime ?? 0),to:node);addChild(node);environmentNodes.append((node,layer))}
            }else{for prop in world["props"].array{let node=SKSpriteNode(texture:texture(prop["image"].string));node.size=CGSize(width:prop["width"].number*32,height:prop["height"].number*32);node.position=CGPoint(x:prop["x"].number*32,y:prop["y"].number*32);node.zPosition=CGFloat(prop["z"].number);addChild(node)}}
            for(index,npc)in run.scenario.npcs.enumerated(){let variant=art["npcs"].array.first(where:{$0["image"].string == npc.appearance}) ?? art["npcs"].array[(index*5)%16],node=SKSpriteNode(texture:texture(variant["image"].string));let aspect=variant["aspect"].number;node.size=CGSize(width:32*0.9*max(0.45,min(1.4,aspect/(1.05/1.45)))*0.92,height:32*1.2*0.92);node.position=CGPoint(x:(Double(npc.tx)+0.5)*32,y:(Double(run.world.height-1-npc.ty)+0.62)*32);node.zPosition=CGFloat(1000+npc.ty*10+3);addChild(node);npcs.append(node)}
            player.size=CGSize(width:32*0.9,height:32*1.2);addChild(player)
            let grade=SKSpriteNode(texture:texture(RPGArt.shared.environment?.plan(run.scenario)?.grade ?? world["grade"].string));grade.texture?.filteringMode = .linear;grade.name="grade";grade.zPosition=20000;lens.addChild(grade)
            indicator.texture=texture(art["indicator"].string);indicator.size=CGSize(width:16,height:19.2);indicator.zPosition=10000;addChild(indicator)
        }
        if self.pet != pet || frames.isEmpty{self.pet=pet;petClock.changedCompanion();loadFrames()}
        if playerTile != run.position{let previous=playerTile;playerTile=run.position;if let previous{petClock.walk();direction=run.position.y<previous.y ? "up":run.position.y>previous.y ? "down":run.position.x<previous.x ? "left":"right";loadFrames()}
            let point=CGPoint(x:(Double(run.position.x)+0.5)*32,y:(Double(mapHeight-1-run.position.y)+0.62)*32)
            player.removeAction(forKey:"walk");lens.removeAction(forKey:"follow")
            if previous == nil{player.position=point;lens.position=point}else{player.run(.move(to:point,duration:0.14),withKey:"walk");lens.run(.move(to:point,duration:0.14),withKey:"follow")}
            player.zPosition=CGFloat(1000+run.position.y*10+4)
        }
        if let npc=run.npc{indicator.position=CGPoint(x:(Double(npc.tx)+0.5)*32,y:(Double(mapHeight-1-npc.ty)+1.15)*32);indicator.isHidden=run.completed || !actorsVisible}else{indicator.isHidden=true}
        player.isHidden = !actorsVisible;npcs.forEach{$0.isHidden = !actorsVisible};animateEnvironment(at:environmentTime ?? environmentElapsed)
        lens.setScale(320/max(1,size.height));(lens.childNode(withName:"grade") as? SKSpriteNode)?.size=CGSize(width:320*size.width/max(1,size.height),height:320)
    }
    func configureMarkers(_ markers:[RPGWorldMarker]) {
        guard markers != itemMarkers else{return};itemMarkers=markers;itemNodes.forEach{$0.removeFromParent()};itemNodes=[]
        for marker in markers{let node=SKSpriteNode(texture:texture(marker.image));node.size=CGSize(width:27.2,height:27.2);node.position=CGPoint(x:(Double(marker.point.x)+0.5)*32,y:(Double(mapHeight-1-marker.point.y)+0.5)*32);node.zPosition=CGFloat(1000+marker.point.y*10+2);addChild(node);itemNodes.append(node)}
    }
    private func loadFrames(){frames=RPGArt.shared.environment?.frames(pet:pet,direction:direction) ?? [];if frames.isEmpty{frames=RPGArt.shared.data["pets"][pet][direction].array.map(\.string)};applyPetFrame()}
    private func applyPetFrame(){guard !frames.isEmpty else{return};let image=frames[petClock.displayedFrame(pet:pet)%frames.count];if image != playerImage{player.texture=texture(image);playerImage=image}}
    private func apply(_ value:RPGEnvironmentTransform,to node:SKSpriteNode){node.position=CGPoint(x:value.x,y:value.y);node.xScale=value.scaleX;node.yScale=value.scaleY;node.zRotation=value.rotation;node.alpha=value.alpha}
    private func animateEnvironment(at time:TimeInterval){itemNodes.forEach{$0.setScale(1+sin(time*4)*0.15)};for entry in environmentNodes where entry.layer.motion != nil{apply(entry.layer.frame(at:time),to:entry.node)};indicator.setScale(RPGEnvironmentLayer.indicatorScale(time:time,npcIndex:activeNPCIndex))}
    override func update(_ currentTime:TimeInterval){guard !isPaused else{return};if visualStart == nil{visualStart=currentTime};let delta=max(0,currentTime-(lastFrameTime ?? currentTime));lastFrameTime=currentTime;environmentElapsed=max(0,currentTime-(visualStart ?? currentTime));petClock.advance(milliseconds:delta*1000,pet:pet);applyPetFrame();animateEnvironment(at:previewTime ?? environmentElapsed)}
    var environmentLayerCount:Int{environmentNodes.count}
    var movingEnvironmentLayerCount:Int{environmentNodes.filter{$0.layer.motion != nil}.count}
    var npcPositions:[CGPoint]{npcs.map(\.position)}
    var environmentPositions:[CGPoint]{environmentNodes.map(\.node.position)}
    var displayedPlayerImage:String{playerImage}
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){guard let touch=touches.first else{return};let p=touch.location(in:self);onTile?(RPGPoint(x:Int(floor(p.x/32)),y:mapHeight-1-Int(floor(p.y/32))))}
}

struct RPGWorldMarker:Equatable {let id:String,point:RPGPoint,image:String}

struct RPGWorldView:View {
    let run:RPGRun,pet:String
    var environmentTime:TimeInterval?=nil,actorsVisible=true
    var markers:[RPGWorldMarker]=[]
    let onTile:(RPGPoint)->Void
    @StateObject private var scene=RPGWorldScene(size:CGSize(width:402,height:874))
    @Environment(\.scenePhase) private var phase
    var body:some View{GeometryReader{g in SpriteView(scene:scene,isPaused:phase != .active,options:[.allowsTransparency]).onAppear{scene.isPaused=false;scene.onTile=onTile;scene.configure(run,pet:pet,size:g.size,environmentTime:environmentTime,actorsVisible:actorsVisible);scene.configureMarkers(markers)}.onDisappear{scene.onTile=nil;scene.isPaused=true}.onChange(of:run){_,value in scene.configure(value,pet:pet,size:g.size,environmentTime:environmentTime,actorsVisible:actorsVisible);scene.configureMarkers(markers)}.onChange(of:markers){_,value in scene.configureMarkers(value)}.onChange(of:pet){_,value in scene.configure(run,pet:value,size:g.size,environmentTime:environmentTime,actorsVisible:actorsVisible);scene.configureMarkers(markers)}.onChange(of:g.size){_,value in scene.configure(run,pet:pet,size:value,environmentTime:environmentTime,actorsVisible:actorsVisible);scene.configureMarkers(markers)}.onChange(of:environmentTime){_,_ in scene.configure(run,pet:pet,size:g.size,environmentTime:environmentTime,actorsVisible:actorsVisible);scene.configureMarkers(markers)}.accessibilityElement(children:.ignore).accessibilityLabel(RPGArt.shared.copy("touchMove",lang:run.support)).accessibilityValue("\(run.position.x),\(run.position.y)").accessibilityIdentifier("rpgWorld")}}
}

struct RPGPetPreview:View {
    let pet:String,size:CGFloat
    var animated=false
    var body:some View{TimelineView(.animation(minimumInterval:0.18,paused:!animated)){context in
        let frame=animated ? Int(context.date.timeIntervalSinceReferenceDate/0.18)%6:0
        RPGArt.shared.image("RPGPetPreview-\(pet)-\(frame)").interpolation(.none).resizable().scaledToFit().frame(width:size,height:size)
    }}
}
