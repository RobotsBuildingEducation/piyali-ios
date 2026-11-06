import Foundation

/// Reading's continuous utterance/recovery policy. Audio and clocks stay native.
public struct ReadingSpeechCapture:Equatable,Sendable {
    public enum Phase:String,Sendable { case idle,listening,stopping }
    public enum Timer:String,Hashable,Sendable { case restart,finalize,limit }
    public enum Effect:Equatable,Sendable {
        case begin(Int),finish(Int),abort(Int)
        case schedule(Timer,token:Int,milliseconds:Int),cancel(Timer)
    }
    public private(set) var phase=Phase.idle
    public private(set) var transcript=""
    public private(set) var issue:String?
    public private(set) var session:Int?
    public private(set) var pending:[Timer:Int]=[:]
    private var wanted=false,sequence=0,timerSequence=0,emptyEnds=0,networkFailures=0
    private var completed:[String]=[],current=""
    public init() {}
    public static func boundedTranscript(_ text:String)->String {
        var bytes=Array(text.utf8.prefix(16_000))
        while let _=bytes.last { if let value=String(bytes:bytes,encoding:.utf8) { return value };bytes.removeLast() }
        return ""
    }
    public mutating func restore(_ text:String) { guard phase == .idle else { return };transcript=Self.boundedTranscript(text);issue=nil }
    public mutating func start()->[Effect] {
        var effects=cancel();completed=[];current="";transcript="";issue=nil;emptyEnds=0;networkFailures=0;wanted=true;phase = .listening
        effects += schedule(.limit,180_000);effects += begin();return effects
    }
    private mutating func begin()->[Effect] { guard wanted else { return [] };sequence += 1;session=sequence;current="";return [.begin(sequence)] }
    public mutating func result(session id:Int,text:String)->[Effect] {
        guard session == id else { return [] };current=Self.boundedTranscript(text.trimmingCharacters(in:.whitespacesAndNewlines))
        if !current.isEmpty { emptyEnds=0;networkFailures=0 };publish();return []
    }
    public mutating func ended(session id:Int)->[Effect] {
        guard session == id else { return [] };var effects=cancelTimer(.finalize)
        if !current.isEmpty { completed.append(current) } else { emptyEnds += 1 };let hadText = !current.isEmpty;current="";session=nil;publish()
        if !wanted { effects += cancelTimers();phase = .idle;return effects }
        if emptyEnds >= 3 { effects += fail("no-speech");return effects }
        effects += schedule(.restart,hadText ? 100 : 300);return effects
    }
    public mutating func failed(session id:Int,code:String)->[Effect] {
        guard session == id,wanted else { return [] }
        if code == "network" { networkFailures += 1 }
        if code == "no-speech" || code == "aborted" || code == "network" && networkFailures <= 2 { return schedule(.finalize,1500) }
        return fail(code == "network" ? "connection-failed" : ["mic-denied","not-allowed","service-not-allowed"].contains(code) ? "mic-denied" : "recording-failed")
    }
    public mutating func stop()->[Effect] {
        guard wanted else { return [] };wanted=false;var effects=cancelTimer(.restart)
        guard let session else { effects += cancelTimers();phase = .idle;return effects }
        phase = .stopping;effects += schedule(.finalize,1500);effects.append(.finish(session));return effects
    }
    public mutating func cancel()->[Effect] {
        wanted=false;var effects=cancelTimers();if let session { effects.append(.abort(session)) };session=nil;current="";phase = .idle;return effects
    }
    public mutating func fired(_ timer:Timer,token:Int)->[Effect] {
        guard pending[timer] == token else { return [] };pending.removeValue(forKey:timer)
        switch timer {
        case .restart:return begin()
        case .limit:return stop()
        case .finalize:guard let session else { return [] };return [.abort(session)]+ended(session:session)
        }
    }
    private mutating func fail(_ code:String)->[Effect] { let effects=cancel();issue=code;return effects }
    private mutating func publish() { transcript=Self.boundedTranscript((completed+[current]).filter { !$0.isEmpty }.joined(separator:" ")) }
    private mutating func schedule(_ timer:Timer,_ delay:Int)->[Effect] { var effects=cancelTimer(timer);timerSequence += 1;pending[timer]=timerSequence;effects.append(.schedule(timer,token:timerSequence,milliseconds:delay));return effects }
    private mutating func cancelTimer(_ timer:Timer)->[Effect] { guard pending.removeValue(forKey:timer) != nil else { return [] };return [.cancel(timer)] }
    private mutating func cancelTimers()->[Effect] { Timer.allCases.flatMap { cancelTimer($0) } }
    public static func feedback(_ code:String)->(title:String,description:String,status:String) {
        let kind=code == "no-speech" ? "no_speech" : code.hasPrefix("connection-") ? "connection" : code == "transcription-failed" ? "transcription" : "recording"
        return ("speech_\(kind)_error_title","speech_\(kind)_error_desc",kind == "no_speech" ? "warning" : "error")
    }
}
extension ReadingSpeechCapture.Timer:CaseIterable {}
