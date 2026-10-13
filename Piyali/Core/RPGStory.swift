import Foundation

public enum RPGDialogue {
    public static func split(_ raw:String) -> (spoken:String,scene:String) {
        var text=raw.trimmingCharacters(in:.whitespacesAndNewlines);guard !text.isEmpty else { return ("","") }
        if (text.hasPrefix("\"") && text.hasSuffix("\"") && text.filter({ $0 == "\"" }).count == 2) || (text.hasPrefix("'") && text.hasSuffix("'") && text.filter({ $0 == "'" }).count == 2) || (text.hasPrefix("“") && text.hasSuffix("”")) || (text.hasPrefix("‘") && text.hasSuffix("’")) { text=String(text.dropFirst().dropLast()).trimmingCharacters(in:.whitespacesAndNewlines) }
        func match(_ pattern:String,insensitive:Bool = false) -> [String]? {
            guard let regex=try? NSRegularExpression(pattern:pattern,options:insensitive ? [.caseInsensitive] : []),let m=regex.firstMatch(in:text,range:NSRange(text.startIndex...,in:text)) else { return nil }
            return (0..<m.numberOfRanges).map { Range(m.range(at:$0),in:text).map { String(text[$0]) } ?? "" }
        }
        func scene(_ s:String) -> String { s.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:"^[*_()\\[\\]]+|[*_()\\[\\]]+$",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines) }
        func spoken(_ s:String) -> String { var v=s.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:"^[\"'“‘]+|[\"'”’]+$",with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines);if v.hasSuffix(",") { v=String(v.dropLast()).trimmingCharacters(in:.whitespacesAndNewlines) };return v }
        if let m=match(#"^([*_]{1,2})([^*_]+)\1\s*(?:[:,-]\s*)?([\s\S]+)$"#) { return (spoken(m[3]),scene(m[2])) }
        if let m=match(#"^(\([^)]{2,120}\)|\[[^\]]{2,120}\])\s*(?:[:,-]\s*)?([\s\S]+)$"#) { return (spoken(m[2]),scene(m[1])) }
        if let m=match(#"^([^"“‘]+?)(?:,\s*|:\s*|\s+)(["'“‘])([\s\S]+?)\2(?:\s*\.?)*$"#),scene(m[1]).count > 1,!spoken(m[3]).isEmpty { return (spoken(m[3]),scene(m[1])) }
        if let m=match(#"^(["'“‘])([\s\S]+?)\1(?:,\s*|\s+)([^"“‘]{2,80})$"#) { return (spoken(m[2]),scene(m[3])) }
        if let m=match(#"^([^:\n]{2,60}?(?:says|said|dice|dijo|dit|sagt|smiles|looks|laughs|replies|exclaims|giggles|shouts|whispers))\s*:\s*([\s\S]+)$"#,insensitive:true) { return (spoken(m[2]),scene(m[1])) }
        if let m=match(#"^([\s\S]+?)\s*([*_]{1,2})([^*_]+)\2$"#) { return (spoken(m[1]),scene(m[3])) }
        if let m=match(#"^([\s\S]+?)\s*(\([^)\n]{2,80}\)|\[[^\]\n]{2,80}\])$"#) { return (spoken(m[1]),scene(m[2])) }
        return (text,"")
    }
}
public enum RPGStory {
    private static func clean(_ s:String,_ max:Int) -> String { String(s.trimmingCharacters(in:.whitespacesAndNewlines).prefix(max)) }
    public static func languageScript(_ lang:String,text:String) -> Bool {
        let patterns=["ja":"[぀-ヿ一-鿿]","zh":"[一-鿿]","ar":"[؀-ۿ]","hi":"[ऀ-ॿ]"]
        guard let pattern=patterns[lang],!text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return true };return text.range(of:pattern,options:.regularExpression) != nil
    }
    public static func preparing(_ scenario:RPGScenario,raw:JSONValue,target:String,support:String) -> RPGScenario? {
        guard raw["beats"].array.count == 7,!scenario.npcs.isEmpty else { return nil }
        var result=scenario,steps:[RPGStep]=[]
        for (index,beat) in raw["beats"].array.enumerated() {
            let speech=beat["mode"].string == "speech",line=RPGDialogue.split(clean(beat["npcLine"].string,260)),example=clean(beat["speechExample"].string.isEmpty ? beat["speechTarget"].string : beat["speechExample"].string,160)
            let options=beat["options"].array.map { clean($0.string,1000) }.filter { !$0.isEmpty }
            let correct:Double
            switch beat["correctIndex"] { case .number(let value):correct=value;case .string(let value):correct=Double(value.trimmingCharacters(in:.whitespacesAndNewlines)) ?? .nan;default:correct = .nan }
            guard !line.spoken.isEmpty,speech ? !example.isEmpty : options.count == 3 && correct.rounded(.towardZero) == correct && (0...2).contains(correct) && beat["correctIndex"] != .null else { return nil }
            let expected=clean(beat["expectedAnswer"].string.isEmpty ? speech ? example : options[Int(correct)] : beat["expectedAnswer"].string,160),concept=clean(beat["concept"].string.isEmpty ? expected : beat["concept"].string,160)
            let right=RPGDialogue.split(clean(beat["right"].string,200)),wrong=RPGDialogue.split(clean(beat["wrong"].string,200)),id=index == 6 ? "finale" : "b\(index+1)",weight=index == 6 ? 2 : 1
            let baseline=scenario.quest.steps.indices.contains(index) ? scenario.quest.steps[index].nodes.first?.choices ?? [] : []
            let choices=speech ? [] : options.enumerated().map { option -> RPGChoice in
                let isCorrect=option.offset == Int(correct),reply=isCorrect ? right.spoken : wrong.spoken,scene=isCorrect ? right.scene : wrong.scene
                return RPGChoice(text:option.element,correct:isCorrect,npcReply:reply.isEmpty ? baseline.first(where:{ $0.correct == isCorrect })?.npcReply : reply,sceneLine:scene.isEmpty ? nil : scene)
            }
            let node=RPGNode(id:id+"-check",responseMode:speech ? "speech" : "choice",npcLine:line.spoken,supportLine:clean(beat["coverage"].string,180),choices:choices,weight:weight,conceptLabel:concept,expectedAnswer:expected,primitive:speech ? "say-aloud" : "choice-check",sceneLine:clean(beat["sceneLine"].string.isEmpty ? line.scene.isEmpty && index == 0 ? raw["intro"]["support"].string : line.scene : beat["sceneLine"].string,220),speechTarget:example,speechExample:example,speechGoal:clean(beat["speechGoal"].string.isEmpty ? beat["coverage"].string : beat["speechGoal"].string,200),speechContinueReply:right.spoken,speechFallbackReply:wrong.spoken)
            steps.append(RPGStep(id:id,npcIdx:index%scenario.npcs.count,title:concept,weight:weight,conceptLabel:concept,expectedAnswer:expected,primitive:node.primitive,nodes:[node]))
        }
        let speech=steps.filter { $0.nodes.first?.responseMode == "speech" }.count;guard (2...3).contains(speech) else { return nil }
        let first=steps[0].nodes[0]
        let targetSample=first.npcLine+" "+first.choices.map(\.text).joined(separator:" ")+" "+raw["intro"]["target"].string
        let supportSample=(first.sceneLine ?? "")+" "+first.supportLine+" "+raw["intro"]["support"].string+" "+(raw["personas"].array.first?.string ?? "")
        guard languageScript(target,text:targetSample),languageScript(support,text:supportSample) else { return nil }
        result.quest.steps=steps;result.authoredEpisode.unitGrounded=true;result.storyTitle=clean(raw["title"].string,90)
        func bilingual(_ value:JSONValue) -> JSONValue? { let target=clean(value["target"].string,260),support=clean(value["support"].string,260);return target.isEmpty && support.isEmpty ? nil : .object(["target":.string(target),"support":.string(support)]) }
        result.storyIntro=bilingual(raw["intro"]);result.storyEpilogue=bilingual(raw["epilogue"]);if !raw["intro"]["target"].string.isEmpty { result.quest.storySeed += " "+clean(raw["intro"]["target"].string,260) }
        if !raw["intro"]["support"].string.isEmpty { result.quest.intro=clean(raw["intro"]["support"].string,260) }
        let personas=raw["personas"].array.map { clean($0.string.isEmpty ? $0["vibe"].string : $0.string,140) }.filter { !$0.isEmpty }.prefix(8)
        if !personas.isEmpty { for index in result.npcs.indices { result.npcs[index].personality=Array(personas)[index%personas.count] } }
        return result
    }
}
