import Foundation
import NostrSDK

@MainActor enum SettingsUI {
    static let policy=try? SettingsSourcePolicy()
    static let options=(try? ContentLibrary.load([String:JSONValue].self,name:"onboarding-options")) ?? [:]
    static func run(_ op:String,_ input:JSONValue)->JSONValue {(try? policy?.run(op,input)) ?? .null}
    static func user(_ learner:LearnerState)->JSONValue {
        learner.settingsSnapshot.setting("progress",learner.settingsSnapshot["progress"].setting("targetLang",.string(learner.target)).setting("supportLang",.string(learner.support)).setting("level",.string(learner.level)))
    }
    static func effective(_ learner:LearnerState)->JSONValue {run("normalize",.object(["user":user(learner),"provider":.string(TutorRealtime.provider),"theme":.string(UserDefaults.standard.string(forKey:"piyali.theme") ?? "light")]))}
}
extension AppModel {
    func settingsSwitchAccount(_ key:String)async->Bool {
        let clean=key.trimmingCharacters(in:.whitespacesAndNewlines)
        guard clean.hasPrefix("nsec1"),let keys=Keypair(nsec:clean) else{error=EntryCopy.ui(learner.support,"toast_invalid_key");return false}
        await signIn(nsec:clean);return identity.npub == keys.publicKey.npub
    }

    func settingsSaveDisplayName(_ value:String,publish:((String,IdentityService,String)async throws->Void)?=nil)async->Bool {
        let name=value.trimmingCharacters(in:.whitespacesAndNewlines),account=identity.npub,author=identity.hex
        guard !name.isEmpty,!account.isEmpty else{return false}
        do {
            if let publish{try await publish(name,identity,author)}
            else{try await SettingsFixture.publishProfile(name:name,identity:identity,author:author)}
            guard identity.npub == account,!Task.isCancelled else{return false}
            learner.name=name;persist();return true
        }catch{if identity.npub == account,!(error is CancellationError){self.error=error.localizedDescription};return false}
    }

    func updateSettings(_ partial:JSONValue) {
        var accepted:[String:JSONValue]=[:]
        if Set(partial.object.keys).isSubset(of:LearnerSettings.directKeys) {
            for(key,value)in partial.object {
                if ["soundEnabled","allowPosts","rpgMusicEnabled"].contains(key){accepted[key] = .bool(value.boolean)}
                else if key == "rpgMusicPreferenceVersion"{accepted[key] = .number(2)}
                else if key == "tutorVolume"{accepted[key] = .number(max(0,min(4,(value.number*10).rounded()/10)))}
                else if key == "soundVolume"{accepted[key] = .number(max(0,min(100,value.number.rounded())))}
            }
        }else {
            let result=SettingsUI.run("normalize",.object(["user":SettingsUI.user(learner),"provider":.string(TutorRealtime.provider),"partial":partial,"theme":.string(UserDefaults.standard.string(forKey:"piyali.theme") ?? "light")]))
            guard result != .null else{error="Settings could not be saved.";return}
            for(key,_)in partial.object {
                if LearnerSettings.progressKeys.contains(key){accepted[key]=result["progress"][key]}
                else if key == "themeMode"{accepted[key]=result[key]}
            }
        }
        for key in ["tutorialBitcoinModalShown","identity","createdWallet"] where partial[key] != .null{if ["tutorialBitcoinModalShown","createdWallet"].contains(key){accepted[key] = .bool(partial[key].boolean)}else if WalletCopy.recipients.contains(where:{$0["npub"].string == partial[key].string}){accepted[key]=partial[key]}}
        guard !accepted.isEmpty else{return};if accepted["allowPosts"] == .bool(false){automaticProgress.cancelPending()};learner.changeSettings(.object(accepted),provider:TutorRealtime.provider);syncSettingsAppearance();persist()
    }
    func settingsSupportLanguage(_ value:String) {
        guard LearningLanguages.support.contains(value),value != learner.support else{return}
        let persona=learner.settingsSnapshot["progress"]["tutorVoicePersona"],next=SettingsUI.run("persona",.object(["language":.string(value),"value":persona]))["localized"]
        learner.support=value
        if next != persona{updateSettings(.object(["tutorVoicePersona":next]))}else{persist()}
        UserDefaults.standard.set(value,forKey:"piyali.interfaceLanguage");Task{await reloadContent()}
    }
    func syncSettingsAppearance() {
        let theme=learner.settingsSnapshot["themeMode"].string
        if ["dark","light"].contains(theme){UserDefaults.standard.set(theme,forKey:"piyali.theme")}
    }
}
