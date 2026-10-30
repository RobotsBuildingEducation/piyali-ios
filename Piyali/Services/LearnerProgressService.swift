import Foundation

@MainActor protocol LearnerProgressService {
    func importAchievements(_ records:JSONValue,npub:String)async throws->[String:JSONValue]?
    func load(npub:String,local:LearnerState?) async throws -> LearnerState?
    /// Independent companion write; the same receipt remains in the durable outbox.
    func saveCompanionCustomization(_ change:SettingsChange,npub:String) async throws -> Bool
    func save(_ state:LearnerState,npub:String) async throws -> LearnerState?
    func saveFirstRunAcknowledgment(_ acknowledgment:FirstRunAcknowledgment,npub:String)async throws
}
extension LearnerProgressService {
    func importAchievements(_ records:JSONValue,npub:String)async throws->[String:JSONValue]?{throw AppError.message("Achievement cloud import is pending.")}
    func saveFirstRunAcknowledgment(_ acknowledgment:FirstRunAcknowledgment,npub:String)async throws{throw AppError.message("Cloud acknowledgment is pending.")}
    func load(npub:String) async throws -> LearnerState? {try await load(npub:npub,local:nil)}
}
