import Foundation

/// Native form of the source LandingTutorDemoSession policy. No learner state,
/// rewards, account creation or connected-session countdown belongs to this demo.
public struct LandingDemoLesson:Equatable,Sendable {
    public private(set) var status="idle",tutorText="",learnerText="",error=""
    public private(set) var turn=1,responses=0
    private var waiting=true,finished:Set<String>=[]
    public var active:Bool { ["connecting","thinking","speaking","listening"].contains(status) }
    public enum Action:Equatable,Sendable { case request(turn:Int,attempt:String),microphone(Bool),close }
    public init() {}
    public mutating func begin() { self=Self();status="connecting" }
    public mutating func opened()->[Action] { guard status == "connecting" else {return []};status="thinking";return [.request(turn:1,attempt:"")] }
    public mutating func stop(reset:Bool=false) { if reset {self=Self()} else if active {status=responses > 0 ? "ended" : "idle"} }
    public mutating func fail(_ code:String) {status="error";error=code}
    public mutating func receive(_ event:JSONValue)->[Action] {
        guard active else {return []}
        let type=event["type"].string
        if type == "error" || type == "session.closed" || (type == "response.canceled" && NostrAchievementCollection.truthy(event["error"])) {fail("unavailable");return [.close]}
        if type == "response.created" {status="speaking";tutorText=""}
        else if ["response.audio_transcript.delta","response.text.delta"].contains(type) {status="speaking";tutorText=String((tutorText+event["delta"].string).prefix(1600))}
        else if type == "conversation.item.input_audio_transcription.completed" {
            let text=String(event["transcript"].string.trimmingCharacters(in:.whitespacesAndNewlines).prefix(1600))
            guard !text.isEmpty,!waiting else {return []};waiting=true;turn += 1;status="thinking";learnerText=text
            return [.microphone(false),.request(turn:turn,attempt:text)]
        } else if type == "response.done" {
            let id=event["response_id"].string.isEmpty ? event["response"]["id"].string : event["response_id"].string
            guard waiting,!id.isEmpty,finished.insert(id).inserted else {return []};responses += 1
            if turn > 5 {status="ended";return [.close]}
            if turn == 2 {turn=3;status="thinking";return [.request(turn:3,attempt:"")]}
            waiting=false;status="listening";return [.microphone(true)]
        }
        return []
    }
}
