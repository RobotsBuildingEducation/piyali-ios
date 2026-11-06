import Foundation
import Combine

@MainActor final class SessionTimerController:ObservableObject {
    @Published private(set) var session=SessionTimer(account:"")
    @Published private(set) var pending:[String]=[]
    private let defaults:UserDefaults
    private var deadline:Task<Void,Never>?
    init(defaults:UserDefaults = .standard){self.defaults=defaults}
    deinit{deadline?.cancel()}
    private var key:String {"piyali.sessionTimer."+session.account}
    private var pendingKey:String {"piyali.sessionTimerAwards."+session.account}
    func load(account:String) {
        guard session.account != account else{refresh();return}
        deadline?.cancel()
        if let data=defaults.data(forKey:"piyali.sessionTimer."+account),let saved=try? JSONDecoder().decode(SessionTimer.self,from:data),saved.account == account{session=saved}else{session=SessionTimer(account:account)}
        pending=defaults.stringArray(forKey:pendingKey) ?? [];refresh();schedule()
    }
    func start(_ value:String){session.start(value);commit();schedule()}
    func saveDraft(_ value:String){session.draft=SessionToolPolicy.draft(value);commit()}
    func toggle(){session.toggle();recordFinished();commit();schedule()}
    func refresh(){if session.refresh(){recordFinished();commit()}}
    func clear(){deadline?.cancel();session.clear();commit()}
    func acknowledge(_ id:String,account:String){guard account == session.account else{return};pending.removeAll{$0==id};defaults.set(pending,forKey:pendingKey)}
    private func recordFinished(){if session.status == .finished,let id=session.id?.uuidString,!pending.contains(id){pending.append(id);defaults.set(pending,forKey:pendingKey)}}
    private func commit(){guard !session.account.isEmpty,let data=try? JSONEncoder().encode(session) else{return};defaults.set(data,forKey:key)}
    private func schedule(){
        deadline?.cancel();guard session.status == .running,let end=session.endsAt,let id=session.id else{return}
        let account=session.account
        deadline=Task{[weak self] in
            do{try await Task.sleep(for:.seconds(max(0,end.timeIntervalSinceNow)))}catch{return}
            guard let self,self.session.account == account,self.session.id == id else{return};self.refresh()
        }
    }
}
