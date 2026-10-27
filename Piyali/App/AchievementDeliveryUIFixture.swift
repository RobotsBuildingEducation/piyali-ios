import Foundation
#if DEBUG
import FirebaseCore
import FirebaseFirestore
import FirebaseAppCheck
#endif

/// A named demo SDK backend for an explicitly scoped UI journey. Release builds
/// and ordinary simulator launches keep the real Piyali service configuration.
@MainActor enum AchievementDeliveryUIFixture {
    static func progressService()->(any LearnerProgressService)? {
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_ACHIEVEMENT_DELIVERY_UI"] == "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{return nil}
        return try? AchievementDeliveryDemoService()
        #else
        return nil
        #endif
    }
}
#if DEBUG
private final class AchievementDemoCheck:NSObject,AppCheckProvider {
    func getToken(completion:@escaping(AppCheckToken?,Error?)->Void){completion(AppCheckToken(token:"local-achievement-emulator",expirationDate:Date().addingTimeInterval(3600)),nil)}
}
private final class AchievementDemoCheckFactory:NSObject,AppCheckProviderFactory {
    func createProvider(with app:FirebaseApp)->AppCheckProvider?{AchievementDemoCheck()}
}
@MainActor private final class AchievementDeliveryDemoService:LearnerProgressService {
    private let db:Firestore,service:FirebaseService
    private var seeds:[String:Task<Void,Error>]=[:]
    init()throws{
        let name="PiyaliAchievementDeliveryEmulator"
        if FirebaseApp.app(name:name) == nil{
            AppCheck.setAppCheckProviderFactory(AchievementDemoCheckFactory());let options=FirebaseOptions(googleAppID:"1:123456789012:ios:0123456789abcdef012345",gcmSenderID:"123456789012");options.projectID="demo-piyali-ios";options.apiKey="emulator-only-not-a-production-key";FirebaseApp.configure(name:name,options:options)
            let database=Firestore.firestore(app:FirebaseApp.app(name:name)!);database.useEmulator(withHost:"127.0.0.1",port:8180);let settings=database.settings;settings.cacheSettings=MemoryCacheSettings();settings.isSSLEnabled=false;database.settings=settings
        }
        let database=Firestore.firestore(app:FirebaseApp.app(name:name)!);guard database.app.options.projectID == "demo-piyali-ios",database.settings.host == "127.0.0.1:8180",database.settings.isSSLEnabled == false else{throw CancellationError()};db=database;service=FirebaseService(database:database)
    }
    private func seed(_ state:LearnerState,npub:String)async throws{
        if let seed=seeds[npub]{try await seed.value;return}
        let db=db,task=Task{@MainActor in
            let user=db.collection("users").document(npub)
            if try await user.getDocument(source:.server).exists{return}
            let day=CalendarDay.key(Date())
            try await user.setData(["local_npub":npub,"displayName":state.name,"language":state.support,"dailyGoalXp":state.dailyGoal,"onboarding":["completed":true],"xp":state.totalXP,"dailyXp":state.dailyXP,"dailyXpRecent":[day:state.dailyXP],"progress":["targetLang":state.target,"supportLang":state.support,"cefrLevel":state.level,"languageXp":[state.target:state.totalXP],"totalXp":state.totalXP],"gettingStartedModalShown":true])
            try await user.collection("achievementMigrations").document("nosabos_v1").setData(["source":"nosabos","version":1,"complete":true])
            let metric="flashcards_completed:"+state.target
            for i in 2...5{let id="pre-a1-people-\(i)",key=try AchievementSyncService.documentID(metric:metric,id:id);try await user.collection("achievementProgress").document("nosabos").collection("events").document(key).setData(["source":"nosabos","metric":metric,"completionId":id,"amount":1])}
        };seeds[npub]=task;try await task.value
    }
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{guard let local,local.onboardingComplete else{return nil};try await seed(local,npub:npub);return try await service.load(npub:npub,local:local)}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{try await service.saveCompanionCustomization(change,npub:npub)}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{guard state.onboardingComplete else{return nil};try await seed(state,npub:npub);return try await service.save(state,npub:npub)}
}
#endif
