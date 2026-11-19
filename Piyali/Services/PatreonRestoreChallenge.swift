import Foundation

struct PatreonRestoreChallenge: Decodable {
    struct Event: Decodable {
        let kind: Int
        let created_at: Int64
        let tags: [[String]]
        let content: String
    }
    let challengeId: String
    let eventTemplate: Event
    func validate(now: Date = Date(), action: String = "restore") throws {
        let event = eventTemplate
        let expiryText = event.tags.last?.last ?? ""
        let parser = ISO8601DateFormatter(); parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expiry = parser.date(from:expiryText) ?? ISO8601DateFormatter().date(from:expiryText)
        guard ["link","restore","replace","disconnect"].contains(action),
              challengeId.range(of:"^[A-Za-z0-9_-]{32}$",options:.regularExpression) != nil,
              event.kind == 27235,
              event.tags == [["action",action],["challenge",challengeId],["expires",expiryText]],
              event.content.range(of:"^Authorize Piyali Patreon \(action): [A-Za-z0-9_-]{43}$",options:.regularExpression) != nil,
              let expiry, expiry > now, expiry.timeIntervalSince(now) <= 360,
              abs(Double(event.created_at) - now.timeIntervalSince1970) < 360 else {
            throw AppError.message("The subscription server returned an invalid restore challenge.")
        }
    }
}
