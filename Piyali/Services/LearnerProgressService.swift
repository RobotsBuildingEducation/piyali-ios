import Foundation

@MainActor protocol LearnerProgressService {
    func load(npub:String,local:LearnerState?) async throws -> LearnerState?
    func save(_ state:LearnerState,npub:String) async throws -> LearnerState?
}
extension LearnerProgressService {
    func load(npub:String) async throws -> LearnerState? {try await load(npub:npub,local:nil)}
}
