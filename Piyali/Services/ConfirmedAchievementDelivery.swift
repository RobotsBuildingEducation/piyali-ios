import Foundation

/// Emitted from committed new award writes, never restoration or backfill.
struct ConfirmedAchievementDelivery:Sendable {
    let account:String
    let records:JSONValue
    let ids:[String]
}
