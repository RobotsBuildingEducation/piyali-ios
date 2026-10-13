import Foundation

public struct BunkerConnection:Equatable,Sendable {
    public let signer:String
    public let relays:[String]
    public let secret:String?
    public init(_ token:String,allowLoopback:Bool = false) throws {
        guard token.utf8.count <= 8192,let url=URLComponents(string:token.trimmingCharacters(in:.whitespacesAndNewlines)),url.scheme == "bunker",let signer=url.host,Self.validKey(signer),url.user == nil,url.password == nil,url.port == nil,url.fragment == nil,["","/"].contains(url.path) else { throw Failure.invalidConnection }
        let items=url.queryItems ?? [],secrets=items.filter { $0.name == "secret" }
        guard secrets.count <= 1,(secrets.first?.value?.utf8.count ?? 0) <= 512 else { throw Failure.invalidConnection }
        let relays=items.filter { $0.name == "relay" }.compactMap(\.value)
        guard !relays.isEmpty,relays.count <= 8 else { throw Failure.invalidConnection }
        var seen=Set<String>();self.relays=try relays.map { try Self.relay($0,allowLoopback:allowLoopback) }.filter { seen.insert($0).inserted }
        self.signer=signer;self.secret=secrets.first?.value.flatMap { $0.isEmpty ? nil : $0 }
    }
    public static func validKey(_ value:String) -> Bool { value.range(of:"^[0-9a-f]{64}$",options:.regularExpression) != nil }
    public static func relay(_ value:String,allowLoopback:Bool = false) throws -> String {
        guard value.utf8.count <= 2048,let url=URLComponents(string:value),let host=url.host,!host.isEmpty,url.user == nil,url.password == nil,url.fragment == nil,url.scheme == "wss" || allowLoopback && url.scheme == "ws" && ["127.0.0.1","localhost","::1"].contains(host),let normalized=url.url?.absoluteString else { throw Failure.invalidRelay };return normalized
    }
    public enum Failure:LocalizedError {
        case invalidConnection,invalidRelay,invalidResponse
        public var errorDescription:String? { switch self { case .invalidConnection:return "Enter a valid bunker connection URL from your signer.";case .invalidRelay:return "Use a secure signer relay URL.";case .invalidResponse:return "The signer returned an invalid response." } }
    }
}
/// Only the client session key is local; this is never the learner's private key.
struct RemoteSignerRecord:Codable,Equatable,Sendable {
    let signer:String
    let user:String
    var relays:[String]
    let clientNsec:String
}
