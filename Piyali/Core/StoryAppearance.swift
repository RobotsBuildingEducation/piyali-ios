import Foundation

/// Original story labels, character pools and exported companion drawing commands.
public struct StoryAppearance:Sendable {
    public let data:JSONValue
    public init(_ data:JSONValue) { self.data=data }
    public func text(_ key:String,language:String)->String {
        let value=data["translations"][language][key].string
        return value.isEmpty ? data["translations"]["en"][key].string : value
    }
    public static func isUser(_ name:String,learnerName:String="")->Bool {
        let value=name.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else { return false }
        return ["you","tú","toi","du","tu"].contains(value) || !learnerName.isEmpty && value == learnerName.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
    }
    public func portraitPool(_ name:String,learnerName:String="")->[String] {
        if name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { return ["35"] }
        if Self.isUser(name,learnerName:learnerName) { return data["pools"]["user"].array.map(\.string) }
        let value=name.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
        if let character=data["characters"].array.first(where:{ $0["name"].string.lowercased() == value || $0["id"].string.lowercased() == value }) {
            let pool=character["portraitPool"].array.map(\.string)
            return pool.isEmpty ? [character["portraitIndex"].string] : pool
        }
        // JS Array.from iterates code points; charCodeAt(0) takes the first UTF-16 unit.
        let hash=value.unicodeScalars.reduce(0) { sum,scalar in sum+Int(scalar.value > 0xffff ? ((scalar.value-0x10000)>>10)+0xd800 : scalar.value) }
        return [String(hash%40+1)]
    }
    public func portraitFile(_ id:String)->String {
        let file=data["portraitFiles"][id].string
        return file.isEmpty ? data["portraitFiles"]["35"].string : file
    }
}
