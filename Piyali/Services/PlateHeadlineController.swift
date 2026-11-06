import Foundation
import Combine

struct PlateHeadlineScope:Equatable,Hashable {
    let account:String,target:String,support:String,day:String
}

@MainActor final class PlateHeadlineController:ObservableObject {
    @Published private(set) var scope:PlateHeadlineScope?
    @Published private(set) var text=""
    @Published private(set) var loading=false
    private var request:UUID?
    func cancel(){request=nil;loading=false}
    func load(scope:PlateHeadlineScope,cached:String?,cleared:Bool,policy:PlateHeadlinePolicy?,generate:@escaping (@escaping @MainActor (String)->Void) async throws->String,save:(PlateHeadline)->Void) async {
        let token=UUID();request=token;self.scope=scope;text=cached ?? "";loading=cached == nil && !cleared
        guard loading,let policy else{loading=false;return}
        defer{if request == token {loading=false}}
        do {
            let raw=try await generate { [weak self] accumulated in
                guard let self,self.request == token,self.scope == scope,!Task.isCancelled,let value=try? policy.clean(accumulated),!value.isEmpty else{return};self.text=value
            }
            try Task.checkCancellation();guard request == token,self.scope == scope else{return}
            let value=try policy.clean(raw);guard !value.isEmpty else{return}
            text=value;save(.init(dayKey:scope.day,appLanguage:PlateHeadline.supportKey(scope.support),text:value))
        }catch{/* Source keeps any partial sentence, then uses the subtitle if empty. */}
    }
}
