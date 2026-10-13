import Foundation
import zlib

public enum ContentError: LocalizedError {
    case missing(String), corrupt(String)
    public var errorDescription: String? { switch self { case .missing(let n): "Missing bundled content: \(n)"; case .corrupt(let n): "Cannot read bundled content: \(n)" } }
}
public enum ContentLibrary {
    public static func decode<T: Decodable>(_ type: T.Type, url: URL) throws -> T {
        guard let file = gzopen(url.path, "rb") else { throw ContentError.missing(url.lastPathComponent) }
        defer { gzclose(file) }
        var data = Data(), buffer = [UInt8](repeating: 0, count: 65536)
        while true {
            let n = gzread(file, &buffer, UInt32(buffer.count))
            if n < 0 { throw ContentError.corrupt(url.lastPathComponent) }
            if n == 0 { break }
            data.append(contentsOf: buffer.prefix(Int(n)))
            guard data.count < 64 * 1024 * 1024 else { throw ContentError.corrupt(url.lastPathComponent) }
        }
        return try JSONDecoder().decode(type, from: data)
    }
    public static func load<T: Decodable>(_ type: T.Type, name: String, bundle: Bundle = .main) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json.gz") else { throw ContentError.missing(name) }
        return try decode(type, url: url)
    }
}
public enum AnswerMatcher {
    public static func normalize(_ text: String) -> String {
        // Keep accents: they can change word meaning. Ignore case, outer punctuation and repeated whitespace.
        text.lowercased().split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }
    public static func matches(_ input: String, _ answer: String) -> Bool {
        !normalize(input).isEmpty && normalize(input) == normalize(answer)
    }
}
