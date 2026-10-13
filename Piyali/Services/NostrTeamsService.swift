import Foundation
import NostrSDK

struct LearningTeam: Identifiable {
    let id: String
    let creator: String
    let name: String
    let members: [String]
    let event: NostrEventPayload
}
actor NostrRelayClient {
    let relays = ["wss://relay.primal.net", "wss://relay.ditto.pub", "wss://nos.lol"]
    func exchange(url: String, message: [Any], subscription: String? = nil) async throws -> [NostrEventPayload] {
        let socket = URLSession.shared.webSocketTask(with: URL(string: url)!)
        socket.resume()
        let timeout = Task { try? await Task.sleep(for: .seconds(9)); if !Task.isCancelled { socket.cancel(with: .goingAway, reason: nil) } }
        defer { timeout.cancel(); socket.cancel(with: .normalClosure, reason: nil) }
        let bytes = try JSONSerialization.data(withJSONObject: message)
        try await socket.send(.string(String(decoding: bytes, as: UTF8.self)))
        var events: [NostrEventPayload] = []
        while true {
            let received = try await socket.receive()
            let data: Data
            switch received { case .string(let text): data = Data(text.utf8); case .data(let bytes): data = bytes; @unknown default: continue }
            guard let parts = try JSONSerialization.jsonObject(with: data) as? [Any], let type = parts.first as? String else { continue }
            if type == "OK", parts.count >= 3 {
                guard parts[2] as? Bool == true else { throw AppError.message(parts.last as? String ?? "Relay rejected update.") }; return []
            }
            if type == "EOSE", parts.count > 1, parts[1] as? String == subscription { return events }
            if type == "CLOSED" { throw AppError.message(parts.last as? String ?? "Relay closed subscription.") }
            if type == "EVENT", parts.count >= 3, parts[1] as? String == subscription {
                let encoded = try JSONSerialization.data(withJSONObject: parts[2])
                if let event = try? JSONDecoder().decode(NostrEventPayload.self, from: encoded), IdentityService.verify(event) { events.append(event) }
            }
        }
    }
    func query(filter: [String: Any]) async throws -> [NostrEventPayload] {
        let id = UUID().uuidString
        var events: [NostrEventPayload] = [], successes = 0
        await withTaskGroup(of: [NostrEventPayload]?.self) { group in
            for relay in relays { group.addTask { try? await self.exchange(url: relay, message: ["REQ",id,filter], subscription: id) } }
            for await result in group { if let result { successes += 1; events += result } }
        }
        guard successes > 0 else { throw AppError.message("No Nostr relay responded. Please try again.") }
        var addresses: [String: NostrEventPayload] = [:]
        for event in events {
            let address = "\(event.kind):\(event.pubkey):\(event.tag("d"))"
            if addresses[address].map({ $0.created_at < event.created_at || ($0.created_at == event.created_at && event.id < $0.id) }) ?? true { addresses[address] = event }
        }
        return Array(addresses.values)
    }
    func publish(_ event: NostrEventPayload) async throws {
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(event))
        var successes = 0
        await withTaskGroup(of: Bool.self) { group in
            for relay in relays { group.addTask { (try? await self.exchange(url: relay, message: ["EVENT",object])) != nil } }
            for await accepted in group { if accepted { successes += 1 } }
        }
        guard successes > 0 else { throw AppError.message("No relay accepted the update.") }
    }
}
@MainActor final class NostrTeamsService: ObservableObject {
    @Published var teams: [LearningTeam] = []
    @Published var progress: [String: JSONValue] = [:]
    @Published var error: String?
    @Published var busy = false
    let client = NostrRelayClient()
    func refresh(identity: IdentityService) async {
        busy = true; defer { busy = false }
        do {
            let owned = try await client.query(filter: ["kinds":[30078],"authors":[identity.hex],"#t":["learning-team"]])
            let joined = try await client.query(filter: ["kinds":[30078],"#p":[identity.hex],"#t":["learning-team"]])
            let leaves = try await client.query(filter: ["kinds":[30078],"authors":[identity.hex],"#t":["learning-team-left"]])
            var byID: [String: NostrEventPayload] = [:]
            for event in owned + joined {
                let key = event.pubkey + ":" + event.tag("d")
                if byID[key].map({ $0.created_at < event.created_at }) ?? true { byID[key] = event }
            }
            teams = byID.values.filter { event in
                event.tag("d").hasPrefix("learning-team:") && !event.tags.contains(where: { $0.first == "deleted" }) &&
                !leaves.contains(where: { $0.tag("d") == "learning-team-left:\(event.pubkey):\(event.tag("d").replacingOccurrences(of: "learning-team:", with: ""))" && $0.created_at >= event.created_at })
            }.map { event in
                LearningTeam(id: event.pubkey + ":" + event.tag("d"), creator: event.pubkey, name: event.tag("name"), members: event.tags.filter { $0.first == "p" && $0.count > 1 }.map { $0[1] }, event: event)
            }.sorted { $0.name < $1.name }
            let authors = Array(Set(teams.flatMap(\.members)))
            if !authors.isEmpty {
                let snapshots = try await client.query(filter: ["kinds":[30078],"authors":authors,"#d":["learning-progress"]])
                progress = Dictionary(uniqueKeysWithValues: snapshots.compactMap { event in
                    guard let value = try? JSONDecoder().decode(JSONValue.self, from: Data(event.content.utf8)) else { return nil }
                    return (event.pubkey, value)
                })
            }
        } catch { self.error = error.localizedDescription }
    }
    func create(name: String, members: String, identity: IdentityService) async throws {
        let npubs = members.split(whereSeparator: { $0.isWhitespace || $0 == "," }).map(String.init)
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, !npubs.isEmpty else { throw AppError.message("Enter a team name and at least one teammate npub.") }
        let hexes = try npubs.map { npub -> String in
            guard let key = PublicKey(npub: npub), key.dataRepresentation.count == 32 else { throw AppError.message("Invalid teammate npub.") }; return key.hex
        }
        let id = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let tags = [["d","learning-team:\(id)"],["t","learning-team"],["name",name]] + Array(Set(hexes + [identity.hex])).sorted().map { ["p",$0] }
        let content = String(decoding: try JSONSerialization.data(withJSONObject: ["schemaVersion":1,"name":name]), as: UTF8.self)
        try await client.publish(identity.sign(kind: 30078, tags: tags, content: content))
        await refresh(identity: identity)
    }
    func leave(_ team: LearningTeam, identity: IdentityService) async throws {
        if team.creator == identity.hex {
            let tags = team.event.tags.filter { $0.first != "deleted" } + [["deleted"]]
            try await client.publish(identity.sign(kind: 30078, tags: tags, content: team.event.content, createdAt: max(Int64(Date().timeIntervalSince1970), team.event.created_at + 1)))
        } else {
            let id = team.event.tag("d").replacingOccurrences(of: "learning-team:", with: "")
            try await client.publish(identity.sign(kind: 30078, tags: [["d","learning-team-left:\(team.creator):\(id)"],["t","learning-team-left"]], content: "{}"))
        }
        await refresh(identity: identity)
    }
    func publishProgress(_ state: LearnerState, identity: IdentityService) async throws {
        let data: [String: Any] = ["schemaVersion":2,"targetLang":state.target,"name":state.name,"xp":state.totalXP,"level":state.level,"score":state.score,"scoreScale":"0-100","scoreLevel":PerformanceScore.level(score:state.score),
            "goal":state.dailyGoal,"dailyGoalXp":state.dailyGoal,"dailyXp":state.dailyXP,"streak":state.streak,
            "progressPercent":min(100,state.dailyXP*100/max(1,state.dailyGoal)),
            "companion":["name":state.companionName,"type":state.effectiveCompanionType,"level":state.companionLevel,"health":state.companionHealth],"updatedAt":Int(Date().timeIntervalSince1970)]
        let content = String(decoding: try JSONSerialization.data(withJSONObject: data), as: UTF8.self)
        try await client.publish(identity.sign(kind: 30078, tags: [["d","learning-progress"],["t","learning-progress"]], content: content))
    }
}
