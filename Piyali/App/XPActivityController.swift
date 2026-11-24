import Foundation
import Combine

/// Mirrors the source legacy/monthly merge, with account/year-scoped offline restoration.
@MainActor final class XPActivityController:ObservableObject {
    @Published private(set) var history:JSONValue = .object([:])
    private var request=UUID()
    private let defaults:UserDefaults
    init(defaults:UserDefaults = .standard){self.defaults=defaults}
    func load(account:String,year:Int,legacy:JSONValue,fetch:(String,Int)async throws->JSONValue)async{
        let token=UUID();request=token;let key="piyali.xpHistory."+account+".\(year)"
        let cached=defaults.data(forKey:key).flatMap{try? JSONDecoder().decode(JSONValue.self,from:$0)} ?? .object([:]);history=XPActivityPlan.merge(legacy,cached)
        guard !account.isEmpty else{return}
        do{let loaded=try await fetch(account,year);try Task.checkCancellation();guard request==token else{return};history=XPActivityPlan.merge(legacy,loaded);if let data=try? JSONEncoder().encode(loaded){defaults.set(data,forKey:key)}}catch{}
    }
}
