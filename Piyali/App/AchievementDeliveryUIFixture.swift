import Foundation
#if DEBUG
import FirebaseCore
import FirebaseFirestore
import FirebaseAppCheck
#endif

/// A named demo SDK backend for an explicitly scoped UI journey. Release builds
/// and ordinary simulator launches keep the real Piyali service configuration.
@MainActor enum AchievementDeliveryUIFixture {
    static func retryServices()->(AchievementRetryController,NostrAchievementsService)?{
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"]=="1",e["PIYALI_ACHIEVEMENT_DELIVERY_UI"]=="1",e["PIYALI_ACHIEVEMENT_RETRY_UI"]=="1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,
              let relay=URL(string:e["PIYALI_ACHIEVEMENT_RETRY_RELAY"] ?? ""),relay.scheme=="ws",relay.host=="127.0.0.1",relay.port != nil,relay.user==nil,relay.password==nil,relay.fragment==nil,
              let gate=URL(string:e["PIYALI_ACHIEVEMENT_RETRY_GATE"] ?? ""),gate.scheme=="http",gate.host=="127.0.0.1",gate.port != nil,gate.path=="/status",gate.user==nil,gate.password==nil,gate.fragment==nil else{return nil}
        return (AchievementRetryController(),NostrAchievementsService(client:NostrRelayClient(relays:[relay.absoluteString],timeout:.seconds(2))))
        #else
        return nil
        #endif
    }
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
        let port=Int(ProcessInfo.processInfo.environment["PIYALI_FIRESTORE_EMULATOR_PORT"] ?? "8180") ?? 8180;guard (1024...65535).contains(port)else{throw CancellationError()}
        let name="PiyaliAchievementDeliveryEmulator"
        if FirebaseApp.app(name:name) == nil{
            AppCheck.setAppCheckProviderFactory(AchievementDemoCheckFactory());let options=FirebaseOptions(googleAppID:"1:123456789012:ios:0123456789abcdef012345",gcmSenderID:"123456789012");options.projectID="demo-piyali-ios";options.apiKey="emulator-only-not-a-production-key";FirebaseApp.configure(name:name,options:options)
            let database=Firestore.firestore(app:FirebaseApp.app(name:name)!);database.useEmulator(withHost:"127.0.0.1",port:port);let settings=database.settings;settings.cacheSettings=MemoryCacheSettings();settings.isSSLEnabled=false;database.settings=settings
        }
        let database=Firestore.firestore(app:FirebaseApp.app(name:name)!);guard database.app.options.projectID == "demo-piyali-ios",database.settings.host == "127.0.0.1:\(port)",database.settings.isSSLEnabled == false else{throw CancellationError()};db=database;service=FirebaseService(database:database)
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
    func saveFirstRunAcknowledgment(_ acknowledgment:FirstRunAcknowledgment,npub:String)async throws{try await service.saveFirstRunAcknowledgment(acknowledgment,npub:npub)}
    func importAchievements(_ records:JSONValue,npub:String)async throws->[String:JSONValue]?{try await service.importAchievements(records,npub:npub)}
    func load(npub:String,local:LearnerState?)async throws->LearnerState?{guard let local,local.onboardingComplete else{return nil};try await seed(local,npub:npub);return try await service.load(npub:npub,local:local)}
    func saveCompanionCustomization(_ change:SettingsChange,npub:String)async throws->Bool{try await service.saveCompanionCustomization(change,npub:npub)}
    func save(_ state:LearnerState,npub:String)async throws->LearnerState?{guard state.onboardingComplete else{return nil};try await seed(state,npub:npub);let saved=try await service.save(state,npub:npub)
        // Explicit loopback-only lost-response injection AFTER the real SDK commit.
        let e=ProcessInfo.processInfo.environment
        if e["PIYALI_ACHIEVEMENT_RETRY_UI"]=="1",!(state.pendingChanges ?? []).filter({$0.source == .review}).isEmpty{
            guard let url=URL(string:e["PIYALI_ACHIEVEMENT_RETRY_GATE"] ?? ""),url.scheme=="http",url.host=="127.0.0.1",url.port != nil,url.path=="/status",url.user==nil,url.password==nil else{throw CancellationError()}
            var request=URLRequest(url:url);request.timeoutInterval=2;let(data,_)=try await URLSession.shared.data(for:request)
            guard let result=try JSONSerialization.jsonObject(with:data)as?[String:Any],result["allow"]as?Bool==true else{throw URLError(.networkConnectionLost)}
        }
        return saved}
}
#endif
