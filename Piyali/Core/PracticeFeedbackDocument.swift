import Foundation

/// Keep CommonMark block boundaries when Swift's inline-only parser would expose list markers.
public enum PracticeFeedbackDocument {
    public struct Block:Identifiable {
        public let id:Int
        public var text:AttributedString
        public let listID:Int?
        public let listDepth:Int
        public let code:Bool
        public let marker:String?
    }
    public struct Group:Identifiable {
        public let id:Int
        public let listID:Int?
        public let listDepth:Int
        public var blocks:[Block]
    }
    public static func groups(_ markdown:String)->[Group]{
        guard let parsed=try? AttributedString(markdown:markdown,options:.init(interpretedSyntax:.full))else{return [.init(id:0,listID:nil,listDepth:0,blocks:[.init(id:0,text:AttributedString(markdown),listID:nil,listDepth:0,code:false,marker:nil)])]}
        var blocks:[Block]=[]
        for run in parsed.runs{
            let components=run.presentationIntent?.components ?? [],id=components.first?.identity ?? 0,lists=components.filter{switch $0.kind{case .orderedList,.unorderedList:return true;default:return false}},code=components.contains{if case .codeBlock = $0.kind{return true};return false}
            let ordinal=components.compactMap{component->Int? in if case .listItem(let n)=component.kind{return n};return nil}.first ?? 1
            let marker:String?=lists.first.map{if case .orderedList = $0.kind{return "\(ordinal)."};return "•"}
            var segment=AttributedString(parsed[run.range]);segment.presentationIntent=nil
            if blocks.last?.id == id{blocks[blocks.count-1].text+=segment}else{blocks.append(.init(id:id,text:segment,listID:lists.first?.identity,listDepth:lists.count,code:code,marker:marker))}
        }
        var groups:[Group]=[]
        for block in blocks{if let list=block.listID,groups.last?.listID == list{groups[groups.count-1].blocks.append(block)}else{groups.append(.init(id:block.id,listID:block.listID,listDepth:block.listDepth,blocks:[block]))}}
        return groups
    }
}
