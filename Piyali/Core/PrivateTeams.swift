import Foundation

/// The Firestore-only team and invitation records used by the main web product.
public struct PrivateTeam:Identifiable,Equatable,Sendable {
    public let teamID:String
    public let creator:String
    public let data:JSONValue
    public var id:String { creator+":"+teamID }
    public var name:String { data["teamName"].string }
    public var members:[JSONValue] { data["members"].array }
    public init(id:String,creator:String,data:JSONValue) throws {
        let members=data["members"].array
        guard PrivateTeams.identifier(id),PrivateTeams.npub(creator),case .object=data,data["nostr"] == .null,!data["teamName"].string.isEmpty,data["teamName"].string.count <= 80,members.count <= 256,members.allSatisfy({ PrivateTeams.npub($0["npub"].string) && ["pending","accepted"].contains($0["status"].string) }),Set(members.map { $0["npub"].string }).count == members.count else { throw PrivateTeams.Failure.invalidRecord }
        self.teamID=id;self.creator=creator;self.data=data
    }
}
public struct PrivateTeamInvite:Identifiable,Equatable,Sendable {
    public let id:String
    public let data:JSONValue
    public var creator:String { data["creatorNpub"].string }
    public var teamID:String { data["teamId"].string }
    public var name:String { data["teamName"].string }
    public var status:String { data["status"].string }
    public init(id:String,data:JSONValue) throws {
        guard PrivateTeams.identifier(id),PrivateTeams.identifier(data["teamId"].string),PrivateTeams.npub(data["creatorNpub"].string),data["nostr"] == .null,["pending","accepted","rejected"].contains(data["status"].string) else { throw PrivateTeams.Failure.invalidRecord }
        self.id=id;self.data=data
    }
}
public enum PrivateTeams {
    public enum Failure:LocalizedError { case invalidRecord,invalidName,invalidMembers,missingMember,missingTeam,creatorOnly
        public var errorDescription:String? { switch self { case .invalidRecord:"This private team record could not be read.";case .invalidName:"Enter a team name of 1–80 characters.";case .invalidMembers:"Enter distinct teammate npubs. Add up to 16 at a time, excluding yourself and existing members.";case .missingMember:"Your invitation is no longer on this team's roster.";case .missingTeam:"This private team no longer exists.";case .creatorOnly:"Only the creator can change this team." } }
    }
    public static func identifier(_ value:String) -> Bool { !value.isEmpty && value.utf8.count <= 256 && value.range(of:"^[A-Za-z0-9_-]+$",options:.regularExpression) != nil }
    public static func npub(_ value:String) -> Bool { value.range(of:"^npub1[023456789acdefghjklmnpqrstuvwxyz]{58}$",options:.regularExpression) != nil }
    public static func name(_ value:String) throws -> String { let name=value.trimmingCharacters(in:.whitespacesAndNewlines);guard !name.isEmpty,name.count <= 80 else { throw Failure.invalidName };return name }
    public static func adding(_ members:[String],to data:JSONValue,creator:String,now:Date) throws -> (team:JSONValue,invites:[String:JSONValue]) {
        let existing=Set(data["members"].array.map { $0["npub"].string }+[creator])
        guard !members.isEmpty,members.count <= 16,Set(members).count == members.count,members.allSatisfy({ npub($0) && !existing.contains($0) }),data["members"].array.count+members.count <= 256 else { throw Failure.invalidMembers }
        let stamp=WebProgressContract.iso(now)
        let entries=members.map { JSONValue.object(["npub":.string($0),"status":.string("pending"),"addedAt":.string(stamp),"name":.string("")]) }
        let team=data.setting("members",.array(data["members"].array+entries))
        return (team,Dictionary(uniqueKeysWithValues:entries.map { ($0["npub"].string,$0) }))
    }
    /// Appends the accepted entry so rules can prove that only the caller's entry changed.
    public static func responding(_ data:JSONValue,member:String,accept:Bool) throws -> JSONValue {
        let entries=data["members"].array,owned=entries.filter { $0["npub"].string == member }
        guard owned.count == 1,let before=owned.first,["pending","accepted"].contains(before["status"].string) else { throw Failure.missingMember }
        let after=accept ? before.setting("status",.string("accepted")) : .null
        return data.setting("members",.array(entries.filter { $0 != before }+(accept ? [after] : []))).setting("_memberChange",.object(["before":before,"after":after]))
    }
}
