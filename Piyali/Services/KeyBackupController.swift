import Foundation
import Combine
import LocalAuthentication
import UIKit

/// Explicit, device-authenticated copying. Secret material is never stored in
/// view state or diagnostics; clipboard contents stay local and expire.
@MainActor final class KeyBackupController:ObservableObject {
    enum State:Equatable {case idle,working,copied,failed}
    @Published private(set) var state:State = .idle
    private let authorizeOverride:((String) async throws->Bool)?
    private let write:(String,Date)->Void
    private var context:LAContext?
    private var generation=UUID()
    init(authorize:((String) async throws->Bool)?=nil,write:((String,Date)->Void)?=nil) {
        authorizeOverride=authorize
        self.write=write ?? {key,expiry in UIPasteboard.general.setItems([["public.utf8-plain-text":key]],options:[.localOnly:true,.expirationDate:expiry])}
    }
    func copy(identity:IdentityService,reason:String) async {
        guard state != .working,!identity.isRemote,!identity.npub.isEmpty else{return}
        let account=identity.npub,ticket=UUID();generation=ticket;state = .working
        do {
            let authorized:Bool
            if let authorizeOverride {authorized=try await authorizeOverride(reason)}
            else {let auth=LAContext();context=auth;authorized=try await auth.evaluatePolicy(.deviceOwnerAuthentication,localizedReason:reason)}
            guard generation == ticket else{return};context=nil
            try Task.checkCancellation()
            guard identity.npub == account,!identity.isRemote else{state = .idle;return}
            guard authorized else{state = .idle;return}
            let secret=identity.exportKey();guard !secret.isEmpty else{state = .failed;return}
            write(secret,Date().addingTimeInterval(120));state = .copied
            try? await Task.sleep(for:.seconds(2))
            if generation == ticket,state == .copied {state = .idle}
        } catch {
            guard generation == ticket else{return};context=nil
            let code=(error as NSError).code
            state = error is CancellationError || [LAError.userCancel.rawValue,LAError.appCancel.rawValue,LAError.systemCancel.rawValue].contains(code) ? .idle : .failed
        }
    }
    func cancel() {generation=UUID();context?.invalidate();context=nil;state = .idle}
}
