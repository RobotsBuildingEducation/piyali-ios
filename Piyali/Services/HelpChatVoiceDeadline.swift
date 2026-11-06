import Foundation

/// Source Help uses separate idle, waiting-for-response and speaking deadlines.
@MainActor final class HelpChatVoiceDeadline:ObservableObject {
    private let policy:HelpChatPolicy?
    private let wait:(Int)async throws->Void
    private var work:Task<Void,Never>?,epoch=UUID(),onTimeout:(()->Void)?
    private(set) var milliseconds:Int?
    init(policy:HelpChatPolicy?=try? HelpChatPolicy(),wait:@escaping(Int)async throws->Void={try await Task.sleep(for:.milliseconds($0))}){self.policy=policy;self.wait=wait}
    func begin(onTimeout:@escaping()->Void){cancel();self.onTimeout=onTimeout;arm(15000)}
    func receive(_ event:JSONValue){guard onTimeout != nil,let result=try? policy?.run("voiceTimeout",.object(["event":event])),result["changed"].boolean else{return};arm(result["milliseconds"] == .null ? nil:Int(result["milliseconds"].number))}
    func cancel(){epoch=UUID();work?.cancel();work=nil;milliseconds=nil;onTimeout=nil}
    private func arm(_ value:Int?){epoch=UUID();work?.cancel();work=nil;milliseconds=value;guard let value else{return};let token=epoch;work=Task{[weak self] in guard let self else{return};do{try await wait(value)}catch{return};guard !Task.isCancelled,epoch == token else{return};let callback=onTimeout;cancel();callback?()}}
}
