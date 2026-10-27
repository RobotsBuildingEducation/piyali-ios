import Foundation
#if DEBUG
import FirebaseCore
import FirebaseFirestore
import FirebaseAppCheck
#endif
@MainActor enum CompanionSaveUIFixture {
    static func progressService()->(any LearnerProgressService)? {
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        guard SettingsFixture.enabled,e["PIYALI_COMPANION_SAVE_FIXTURE"] == "failure",e["PIYALI_RULES_EMULATOR_TESTS"] == "1" else{return nil}
        return try? CompanionSaveFailureStore()
        #else
        return nil
        #endif
    }
}
#if DEBUG
private final class CompanionSaveDemoCheck:NSObject,AppCheckProvider {
    func getToken(completion:@escaping(AppCheckToken?,Error?)->Void){completion(AppCheckToken(token:"local-companion-save-emulator",expirationDate:Date().addingTimeInterval(3600)),nil)}
}
private final class CompanionSaveDemoFactory:NSObject,AppCheckProviderFactory {func createProvider(with app:FirebaseApp)->AppCheckProvider?{CompanionSaveDemoCheck()}}
@MainActor private final class CompanionSaveFailureStore:LearnerProgressService {
    private let service:FirebaseService
    init()throws{
        let name="PiyaliCompanionSaveDeniedEmulator"
        if FirebaseApp.app(name:name)==nil{let options=FirebaseOptions(googleAppID:"1:123456789012:ios:0123456789abcdef012345",gcmSenderID:"123456789012");options.projectID="demo-piyali-ios-auth";options.apiKey="emulator-only-not-a-production-key";AppCheck.setAppCheckProviderFactory(CompanionSaveDemoFactory());FirebaseApp.configure(name:name,options:options);let db=Firestore.firestore(app:FirebaseApp.app(name:name)!);db.useEmulator(withHost:"127.0.0.1",port:8280);let settings=db.settings;settings.cacheSettings=MemoryCacheSettings();settings.isSSLEnabled=false;db.settings=settings}
        let db=Firestore.firestore(app:FirebaseApp.app(name:name)!);guard db.app.options.projectID == "demo-piyali-ios-auth",db.settings.host == "127.0.0.1:8280",db.settings.isSSLEnabled == false else{throw CancellationError()};service=FirebaseService(database:db)
    }
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{nil}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{nil}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{try await service.saveCompanionCustomization(change,npub:npub)}
}
#endif
