import Foundation

public struct RPGPoint: Codable, Equatable, Hashable, Sendable { public var x:Int;public var y:Int;public init(x:Int,y:Int) { self.x=x;self.y=y } }
public struct RPGObject: Codable, Equatable, Sendable { public let type:String;public let tx:Int;public let ty:Int }
public struct RPGWorld: Codable, Equatable, Sendable {
    public let width:Int;public let height:Int;public let start:RPGPoint;public let tiles:[Int];public let solidTiles:[Int];public let objects:[RPGObject]
    public func walkable(_ p:RPGPoint) -> Bool { p.x >= 0 && p.y >= 0 && p.x < width && p.y < height && tiles.count == width*height && !solidTiles.contains(tiles[p.y*width+p.x]) }
    public func path(from start:RPGPoint, to target:RPGPoint) -> [RPGPoint]? {
        guard walkable(start) else { return nil };var queue=[start],index=0,previous:[RPGPoint:RPGPoint]=[:],seen:Set<RPGPoint>=[start]
        while index < queue.count {
            let p=queue[index];index += 1
            if abs(p.x-target.x)+abs(p.y-target.y) <= 1 {
                var path=[p],current=p;while current != start,let prior=previous[current] { path.append(prior);current=prior };return path.reversed()
            }
            for next in [RPGPoint(x:p.x+1,y:p.y),RPGPoint(x:p.x-1,y:p.y),RPGPoint(x:p.x,y:p.y+1),RPGPoint(x:p.x,y:p.y-1)] where walkable(next) && seen.insert(next).inserted { previous[next]=p;queue.append(next) }
        }
        return nil
    }
}
public struct RPGNPC: Codable, Equatable, Sendable { public var name:String;public let role:String;public var personality:String;public let tx:Int;public let ty:Int }
public struct RPGChoice: Codable, Equatable, Sendable { public var text:String;public var correct:Bool;public var npcReply:String?;public var sceneLine:String? }
public struct RPGNode: Codable, Equatable, Sendable {
    public var id:String;public var responseMode:String;public var npcLine:String;public var supportLine:String;public var choices:[RPGChoice];public var weight:Int;public var conceptLabel:String;public var expectedAnswer:String;public var primitive:String
    public var sceneLine:String?;public var speechTarget:String?;public var speechExample:String?;public var speechGoal:String?;public var speechContinueReply:String?;public var speechFallbackReply:String?
}
public struct RPGStep: Codable, Equatable, Sendable { public var id:String;public var npcIdx:Int;public var title:String;public var weight:Int;public var conceptLabel:String;public var expectedAnswer:String;public var primitive:String;public var nodes:[RPGNode] }
public struct RPGQuest: Codable, Equatable, Sendable { public var title:String;public var intro:String;public var storySeed:String;public var steps:[RPGStep] }
public struct RPGEpisode: Codable, Equatable, Sendable { public let id:String;public let level:String;public let maxBaseScore:Int;public var unitGrounded:Bool }
public struct RPGScenario: Codable, Equatable, Sendable {
    public let id:String;public let name:JSONValue;public let emoji:String;public var npcs:[RPGNPC];public var quest:RPGQuest;public var authoredEpisode:RPGEpisode;public let worldKey:String
    public var storyTitle:String?;public var storyIntro:JSONValue?;public var storyEpilogue:JSONValue?
}
public struct RPGReview: Codable, Sendable { public let context:JSONValue;public let bySupport:[String:RPGScenario] }
public struct RPGLibrary: Codable, Sendable {
    public let catalog:[String:[String:[RPGScenario]]];public let reviews:[String:RPGReview];public let worlds:[String:RPGWorld]
    public func scenarios(level:String,support:String) -> [RPGScenario] { catalog[level]?[support] ?? catalog[level]?["en"] ?? [] }
}
public struct RPGMiss: Codable, Equatable, Sendable { public let beatID:String;public let concept:String;public let expected:String;public let answer:String }
public struct RPGSpeechTurn: Codable, Sendable { public let grade:String;public let reply:String;public let tip:String }
public struct RPGRun: Codable, Equatable, Identifiable, Sendable {
    public var id=UUID();public let target:String;public let support:String;public let lessonID:String?;public let xpReward:Int;public var scenario:RPGScenario;public let world:RPGWorld
    public var tutorial:Bool?
    public var tutor:Bool?
    public var position:RPGPoint;public var stepIndex=0;public var attempts=0;public var score=0;public var resolved=false;public var feedback="";public var tip="";public var misses:[RPGMiss]=[];public var dialogue:[String]=[];public var updatedAt=Date();public var claimed=false
    public init(target:String,support:String,lessonID:String?,xpReward:Int,scenario:RPGScenario,world:RPGWorld,tutorial:Bool = false,tutor:Bool = false) { self.tutor=tutor;self.tutorial=tutorial;self.target=target;self.support=support;self.lessonID=lessonID;self.xpReward=xpReward;self.scenario=scenario;self.world=world;self.position=world.start }
    public var completed:Bool { stepIndex >= scenario.quest.steps.count && scenario.quest.steps.count == 7 }
    public var step:RPGStep? { completed || !scenario.quest.steps.indices.contains(stepIndex) ? nil : scenario.quest.steps[stepIndex] }
    public var node:RPGNode? { step?.nodes.first }
    public var npc:RPGNPC? { guard let step,scenario.npcs.indices.contains(step.npcIdx) else { return nil };return scenario.npcs[step.npcIdx] }
    public var stars:Int { RPGScoring.stars(score) }
    public var reward:Int { completed && lessonID != nil && tutorial != true ? RPGScoring.xp(reward:xpReward,score:score) : 0 }
    public mutating func move(dx:Int,dy:Int) -> Bool { let next=RPGPoint(x:position.x+dx,y:position.y+dy);guard abs(dx)+abs(dy)==1,world.walkable(next) else { return false };position=next;updatedAt=Date();return true }
    public mutating func approachNPC() -> Bool { guard let npc,let path=world.path(from:position,to:RPGPoint(x:npc.tx,y:npc.ty)),let last=path.last else { return false };position=last;updatedAt=Date();return true }
    private mutating func miss(_ answer:String) { guard let step,let node else { return };misses.removeAll { $0.beatID == step.id };let expected=node.responseMode == "speech" ? [node.speechExample ?? "",node.speechTarget ?? "",node.expectedAnswer].first { !$0.isEmpty } ?? "" : node.expectedAnswer;misses.append(RPGMiss(beatID:step.id,concept:node.conceptLabel,expected:expected,answer:String(answer.prefix(1000)))) }
    private mutating func log(_ text:String) { dialogue.append(String(text.prefix(1200)));dialogue=Array(dialogue.suffix(14));updatedAt=Date() }
    public mutating func choose(_ index:Int) {
        guard !resolved,let node,node.responseMode == "choice",node.choices.indices.contains(index) else { return }
        let choice=node.choices[index]
        feedback=choice.npcReply ?? "";tip="";log("Player: "+choice.text)
        if choice.correct { score += [100,50,25][min(attempts,2)]*node.weight;attempts=0;resolved=true }
        else { attempts += 1;miss(choice.text);if attempts >= 3 { feedback += " "+node.expectedAnswer;resolved=true } }
        log((npc?.name ?? "NPC")+": "+feedback)
    }
    public mutating func speak(_ answer:String,turn:RPGSpeechTurn) {
        guard !resolved,let node,node.responseMode == "speech",!answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,["full","partial","miss"].contains(turn.grade) else { return }
        score += (turn.grade == "full" ? 100 : turn.grade == "partial" ? 50 : 25)*node.weight
        if turn.grade != "full" { miss(answer) };attempts=0;resolved=true;feedback=turn.reply;tip=turn.tip;log("Player: "+answer);log((npc?.name ?? "NPC")+": "+turn.reply)
    }
    public mutating func advance() { guard resolved,!completed else { return };stepIndex += 1;attempts=0;resolved=false;feedback="";tip="";updatedAt=Date() }
}
public enum RPGScoring {
    public static func stars(_ score:Int) -> Int { score >= 720 ? 3 : score >= 560 ? 2 : 1 }
    public static func xp(reward:Int,score:Int,flair:Int = 0) -> Int { let multiplier=stars(score)==3 ? 1.0 : stars(score)==2 ? 22.0/30 : 0.5;return Int(floor(Double(reward)*multiplier+0.5))+(flair >= 400 ? 5 : 0) }
    private static func normalized(_ text:String,lang:String) -> String {
        var value=text.lowercased().trimmingCharacters(in:.whitespacesAndNewlines)
        if ["es","en","pt","it","fr","de","nl"].contains(lang) { value=String(value.decomposedStringWithCanonicalMapping.unicodeScalars.filter { !(0x300...0x36f).contains($0.value) }) }
        value=value.replacingOccurrences(of:"[^\\p{L}\\p{N}\\s]",with:" ",options:.regularExpression)
        return value.split(whereSeparator:\.isWhitespace).joined(separator:" ")
    }
    private static func tokens(_ text:String,lang:String) -> [String] { ["ja","zh"].contains(lang) ? text.replacingOccurrences(of:" ",with:"").utf16.map { String($0) } : text.split(separator:" ").map(String.init) }
    public static func match(transcript:String,target:String,lang:String,level:String) -> (score:Double,pass:Bool) {
        let heard=normalized(transcript,lang:lang),goal=normalized(target,lang:lang);guard !heard.isEmpty,!goal.isEmpty else { return (0,false) }
        let a=tokens(goal,lang:lang),b=tokens(heard,lang:lang);var available:[String:Int]=[:];for token in b { available[token,default:0] += 1 };var hits=0
        for token in a where available[token,default:0] > 0 { hits += 1;available[token,default:0] -= 1 }
        var score=Double(hits)/Double(a.count)
        if ["es","en","pt","it","fr","de","nl"].contains(lang) {
            let a=Array(heard.replacingOccurrences(of:" ",with:"").utf16),b=Array(goal.replacingOccurrences(of:" ",with:"").utf16);var previous=Array(0...b.count)
            for (i,x) in a.enumerated() { var current=[i+1];for (j,y) in b.enumerated() { current.append(min(previous[j+1]+1,current[j]+1,previous[j]+(x == y ? 0 : 1))) };previous=current }
            score=max(score,1-Double(previous.last!)/Double(max(a.count,b.count)))
        }
        let thresholds=["Pre-A1":0.55,"A1":0.62,"A2":0.68,"B1":0.74,"B2":0.78,"C1":0.8,"C2":0.82]
        return (score,score >= thresholds[level,default:0.62])
    }
}
public extension LearnerState {
    mutating func saveRPG(_ run:RPGRun) { if rpgRuns == nil { rpgRuns=[:] };rpgRuns?[run.target]=run;for key in (rpgRuns ?? [:]).sorted(by:{ $0.value.updatedAt > $1.value.updatedAt }).dropFirst(3).map(\.key) { rpgRuns?.removeValue(forKey:key) } }
    @discardableResult mutating func completeRPG(_ run:RPGRun,now:Date = Date()) -> Int {
        guard run.tutor != true,run.completed,run.tutorial != true,!run.claimed,run.target == target,rpgRuns?[target]?.id == run.id,let lessonID=run.lessonID else { return 0 }
        var saved=run;saved.claimed=true;saveRPG(saved)
        let key=completionKey(lessonID);guard !completed.contains(key) else { return 0 };completed.insert(key)
        addXP(run.reward,now:now,calendar:.current)
        var change=PracticeChange(date:now,dayKey:dailyKey,target:target,level:run.scenario.authoredEpisode.level,amount:run.reward,source:.lesson,contentID:lessonID);change.id=run.id
        change.gameResult = .object(["episodeId":.string(run.scenario.authoredEpisode.id),"score":.number(Double(run.score)),"stars":.number(Double(run.stars)),"xp":.number(Double(run.reward))])
        enqueue(change);return run.reward
    }
}
