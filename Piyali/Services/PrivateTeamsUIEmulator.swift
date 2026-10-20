#if DEBUG
import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAppCheck

/// Only the explicit, isolated UI-test environment can select this demo database.
@MainActor enum PrivateTeamsUIEmulator {
    static func configured() -> Firestore? {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_PRIVATE_TEAMS_TEST_EMULATOR"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else { return nil }
        let name="PiyaliPrivateTeamUIEmulator"
        if FirebaseApp.app(name:name) == nil {
            let options=FirebaseOptions(googleAppID:"1:123456789012:ios:0123456789abcdef012345",gcmSenderID:"123456789012")
            options.apiKey="emulator-only-not-a-production-key";options.projectID="demo-piyali-ios"
            AppCheck.setAppCheckProviderFactory(PrivateTeamUIFactory());FirebaseApp.configure(name:name,options:options)
            let db=Firestore.firestore(app:FirebaseApp.app(name:name)!);db.useEmulator(withHost:"127.0.0.1",port:8180)
            let settings=db.settings;settings.cacheSettings=MemoryCacheSettings();settings.isSSLEnabled=false;db.settings=settings
        };return Firestore.firestore(app:FirebaseApp.app(name:name)!)
    }
}
private final class PrivateTeamUIProvider:NSObject,AppCheckProvider {
    func getToken(completion:@escaping(AppCheckToken?,Error?)->Void) { completion(AppCheckToken(token:"local-emulator-token",expirationDate:Date().addingTimeInterval(3600)),nil) }
}
private final class PrivateTeamUIFactory:NSObject,AppCheckProviderFactory {
    func createProvider(with app:FirebaseApp)->AppCheckProvider? { PrivateTeamUIProvider() }
}
#endif
