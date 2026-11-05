import Foundation
import Combine

@MainActor final class MemoryCaptureController:ObservableObject {
    struct Event {let id:UUID,scope:String,startedAt:Date}
    @Published private(set) var event:Event?
    private var scope="",expiry:Task<Void,Never>?
    private let sleep:@MainActor (Duration)async throws->Void
    init(sleep:@escaping @MainActor (Duration)async throws->Void={try await Task.sleep(for:$0)}){self.sleep=sleep}
    func bind(_ scope:String){guard self.scope != scope else{return};cancel();self.scope=scope}
    func capture(_ scope:String,now:Date = Date()) {
        bind(scope);guard !scope.isEmpty else{return};expiry?.cancel()
        let event=Event(id:UUID(),scope:scope,startedAt:now);self.event=event
        let sleep=self.sleep
        expiry=Task{[weak self] in do{try await sleep(.milliseconds(3070));try Task.checkCancellation();if self?.event?.id == event.id{self?.event=nil;self?.expiry=nil}}catch{}}
    }
    func current(in scope:String)->Event? {event?.scope == scope ? event:nil}
    func cancel(){expiry?.cancel();expiry=nil;event=nil}
}
