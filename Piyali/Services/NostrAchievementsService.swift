import Foundation

@MainActor final class NostrAchievementsService: ObservableObject {
    @Published private(set) var busy=false
    @Published private(set) var status=""
    @Published var error: String?
    let client: NostrRelayClient
    let catalog: [JSONValue]
    private var generation=0
    private var pending: Task<JSONValue,Error>?
    init(client: NostrRelayClient = NostrRelayClient()) { self.client=client;catalog=(try? ContentLibrary.load([JSONValue].self,name:"achievement-protocol")) ?? [] }
    func cancel() { generation += 1;pending?.cancel();pending=nil;busy=false;status="";error=nil }
    nonisolated static func parse(_ event: NostrEventPayload, author: String) -> JSONValue? {
        guard event.pubkey == author,event.kind == NostrAchievementCollection.kind,NostrAchievementCollection.identifiers.contains(event.tag("d")),IdentityService.verify(event),event.content.utf8.count <= 1_048_576 else { return nil }
        guard let data=try? JSONDecoder().decode(JSONValue.self,from:Data(event.content.utf8)) else { return .object([:]) }
        return NostrAchievementCollection.merging([data["unlocked"]])
    }
    private func authenticator(identity: IdentityService, author: String) -> NostrRelayClient.Authenticate {
        { relay,challenge in try await MainActor.run {
            guard identity.hex == author else { throw AppError.message("The Piyali account changed during relay authentication.") }
            return try identity.sign(kind:22242,tags:[["relay",relay],["challenge",challenge]],content:"")
        }}
    }
    func read(identity: IdentityService) async throws -> (records:JSONValue,events:[NostrEventPayload]) {
        let author=identity.hex
        guard !author.isEmpty else { throw AppError.message("Sign in first.") }
        let events=try await client.querySnapshots(filter:["kinds":[NostrAchievementCollection.kind],"#d":NostrAchievementCollection.identifiers,"authors":[author],"limit":3],authenticate:authenticator(identity:identity,author:author))
        try Task.checkCancellation();guard identity.hex == author else { throw AppError.message("The Piyali account changed during restoration.") }
        let valid=events.filter { Self.parse($0,author:author) != nil }
        return (NostrAchievementCollection.completed(NostrAchievementCollection.merging(valid.compactMap { Self.parse($0,author:author) }),catalog:catalog),valid)
    }
    /// Publication is explicit or follows the learner's saved sharing preference. Read before write preserves other host records.
    func synchronize(identity: IdentityService, publish: Bool, current: @escaping @MainActor ()->JSONValue, persist: @escaping @MainActor (JSONValue) async throws->Void) async throws -> JSONValue {
        let version=generation,author=identity.hex
        while let pending {
            _=try? await pending.value
            try Task.checkCancellation()
            guard generation == version,identity.hex == author else { throw CancellationError() }
        }
        try Task.checkCancellation()
        let task=Task { @MainActor [weak self] () throws -> JSONValue in
            guard let self else { throw CancellationError() }
            // Clear the completed operation before queued callers resume from its value.
            defer { if self.generation == version { self.pending=nil;self.busy=false } }
            let snapshot=try await self.read(identity:identity)
            try Task.checkCancellation();guard self.generation == version,identity.hex == author else { throw CancellationError() }
            var records=NostrAchievementCollection.completed(NostrAchievementCollection.merging([current(),snapshot.records]),catalog:self.catalog)
            try await persist(records)
            try Task.checkCancellation();guard self.generation == version,identity.hex == author else { throw CancellationError() }
            if publish {
                // Merge awards received while the relay read or Firebase import was waiting.
                records=NostrAchievementCollection.completed(NostrAchievementCollection.merging([records,current()]),catalog:self.catalog)
                let own=snapshot.events.filter { $0.tag("d") == "learning-achievements:nosabos" }
                let needs=own.isEmpty || own.contains { event in let remote=Self.parse(event,author:author) ?? .object([:]);return records.object.contains { remote[$0.key] != $0.value } }
                if needs && !records.object.isEmpty {
                    let latest=own.map(\.created_at).max() ?? 0
                    guard latest < Int64.max else { throw AppError.message("The stored collection timestamp is invalid.") }
                    let time=max(Int64(Date().timeIntervalSince1970),latest+1)
                    let content=NostrAchievementCollection.body(records,createdAt:time).json
                    guard content.utf8.count <= 1_048_576 else { throw AppError.message("The achievement collection is too large to publish.") }
                    let signed=try identity.sign(kind:30078,tags:[["d","learning-achievements:nosabos"],["t","learning-achievements"]],content:content,createdAt:time)
                    try await self.client.publish(signed,authenticate:self.authenticator(identity:identity,author:author))
                    try Task.checkCancellation();guard self.generation == version,identity.hex == author else { throw CancellationError() }
                }
                self.status="Public collection synced to Nostr."
            } else { self.status="Signed collection restored from Nostr." }
            return records
        }
        pending=task;busy=true;error=nil
        do { return try await task.value } catch { if generation == version,!busy,!(error is CancellationError) { self.error=error.localizedDescription };throw error }
    }
}
