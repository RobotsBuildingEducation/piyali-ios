import Foundation

@MainActor enum SettingsFixture {
    static var enabled:Bool {
        #if DEBUG
        let e=ProcessInfo.processInfo.environment;return e["PIYALI_OFFLINE_TESTS"] == "1" && e["PIYALI_SETTINGS_FIXTURE"] == "1" && UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil
        #else
        return false
        #endif
    }
    static func seed(_ app:AppModel){
        guard enabled else{return};let key="piyali.settings.fixture.seeded."+app.identity.npub
        guard !UserDefaults.standard.bool(forKey:key) else{return}
        app.learner.gettingStartedModalShown=true;app.learner.xpByLanguage=[app.learner.target:20];app.learner.editGoal("Talk with family");app.learner.pendingGoalChanges=[]
        app.learner.userSettings = .object(["allowPosts":.bool(false),"soundEnabled":.bool(true),"themeMode":.string(UserDefaults.standard.string(forKey:"piyali.theme") ?? "light"),"progress":.object(["tutorVoice":.string("marin"),"pauseMs":.number(1200)])])
        UserDefaults.standard.set(true,forKey:key);UserDefaults.standard.set(true,forKey:"piyali.companionBubbleDismissed:"+app.identity.npub+":"+app.learner.target+":"+CalendarDay.key(Date()))
    }
    static func publishProfile(name:String,identity:IdentityService,author:String)async throws {
        #if DEBUG
        if enabled{return}
        if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1"{throw CancellationError()}
        #endif
        try await CommunityFeedService().publishProfile(name:name,identity:identity,expectedAuthor:author)
    }
    static func preview()->RealtimeNarrationService {
        #if DEBUG
        if enabled{return RealtimeNarrationService(factory:{SettingsPreviewTransport()})}
        #endif
        return RealtimeNarrationService(factory:{if TutorRealtime.provider == "gemini"{return GeminiTutorTransport(capturesMicrophone:false)};return RealtimeRTCTransport(capturesMicrophone:false,purpose:.narration)})
    }
}
#if DEBUG
@MainActor private final class SettingsPreviewTransport:RealtimeVoiceTransport {
    var onOpen:(()->Void)?,onEvent:((JSONValue)->Void)?,onFailure:((String)->Void)?
    private var work:Task<Void,Never>?
    func connect(session:JSONValue)async throws {onOpen?()}
    func send(_ event:JSONValue)->Bool {if event["type"].string == "response.create"{work=Task{try? await Task.sleep(for:.milliseconds(100));guard !Task.isCancelled else{return};onEvent?(.object(["type":.string("output_audio_buffer.started")]));try? await Task.sleep(for:.milliseconds(150));guard !Task.isCancelled else{return};onEvent?(.object(["type":.string("response.done"),"response":.object(["status":.string("completed")])]));onEvent?(.object(["type":.string("output_audio_buffer.stopped")]))}};return true}
    func setMicrophoneEnabled(_ enabled:Bool){}
    func setRemoteAudioEnabled(_ enabled:Bool){}
    func close(){work?.cancel()}
}
#endif
