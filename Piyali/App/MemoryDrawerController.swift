import Foundation
import Combine

@MainActor enum MemoryUI {
    static let policy=try? MemorySourcePolicy()
    static func value(_ operation:String,_ input:JSONValue = .object([:]))->JSONValue {(try? policy?.value(operation,input)) ?? .null}
    private static var copies:[String:JSONValue]=[:]
    static func copy(_ language:String,count:Int=0)->JSONValue {
        if count == 0,let saved=copies[language]{return saved};let result=value("copy",.object(["language":.string(language),"count":.number(Double(count))]));if count == 0{copies[language]=result};return result
    }
    static func journey(_ language:String,_ key:String,values:JSONValue = .object([:]))->String {value("journeyCopy",.object(["language":.string(language),"key":.string(key),"values":values])).string}
    static func notes(_ learner:LearnerState,now:Date = Date())->[MemoryNote] {let today=CalendarDay.key(now),yesterday=CalendarDay.shift(today,by:-1),all=learner.companionMemory?[learner.target] ?? [];return all.filter{$0.text("createdDayKey") == today}+all.filter{$0.text("createdDayKey") == yesterday}}
}

@MainActor final class MemoryDrawerController:ObservableObject {
    @Published private(set) var summary=""
    private var scope="",epoch=UUID(),task:Task<Void,Never>?,fingerprint=""
    private var pendingRefresh=false
    private let provider:((String)async throws->String)?
    init(provider:((String)async throws->String)?=nil){self.provider=provider}
    private func key(_ app:AppModel)->String {[app.identity.npub,app.learner.target,app.learner.support,CalendarDay.key(Date())].joined(separator:":")}
    private func input(_ app:AppModel)->JSONValue {.object(["language":.string(app.learner.support),"target":.string(app.learner.target),"notes":.array(MemoryUI.notes(app.learner).map{.object($0.fields)})])}
    func refresh(_ app:AppModel){
        let current=key(app)
        if current != scope {cancel();scope=current;fingerprint="";summary=UserDefaults.standard.string(forKey:"piyali.memory.summary."+scope) ?? ""}
        let p=input(app),next=p.canonicalJSON
        if task != nil{if next != fingerprint{pendingRefresh=true};return}
        guard next != fingerprint else{return}
        fingerprint=next;let token=epoch,account=app.identity.npub,target=app.learner.target,support=app.learner.support,provider=self.provider
        task=Task{[weak self,weak app] in guard let self,let app,let policy=MemoryUI.policy else{return}
            defer{if epoch == token{task=nil;let pending=pendingRefresh;pendingRefresh=false;if pending{fingerprint=""};if pending || input(app).canonicalJSON != fingerprint{refresh(app)}}}
            let respond:@MainActor (String)async throws->String={prompt in
                if let provider{return try await provider(prompt)}
                if let value=MemoryDrawerFixture.response(prompt,language:support){return value}
                return try await app.ai.responsesText(prompt)
            }
            @MainActor func valid()->Bool {epoch == token && !Task.isCancelled && app.identity.npub == account && app.learner.target == target && app.learner.support == support}
            for note in MemoryUI.notes(app.learner) {
                guard valid() else{return}
                let clean=(try? policy.value("clean",.object(["text":.string(note.text("concept")),"language":.string(support)])))?.string ?? note.text("concept")
                let localized=(try? policy.value("localized",.object(["note":.object(note.fields),"language":.string(support)])))?.boolean == true
                guard !localized || clean != note.text("concept") || note.text("iosMemoryEnrichedSupport") != support && note.text("tip").isEmpty else{continue}
                let fields=(try? await policy.generate("enrich",.object(["note":.object(note.fields),"target":.string(target),"language":.string(support)]),respond:respond)) ?? .null
                guard valid() else{return}
                let fallback=JSONValue.object(["mistake":.string(localized ? note.text("mistake"):""),"correction":.string(note.text("expectedAnswer").isEmpty ? note.text("correction"):note.text("expectedAnswer")),"tip":.string(localized ? note.text("tip"):"")])
                app.learner.localizeMemory(note,fields:(fields == .null ? fallback:fields).setting("concept",.string(clean)),support:support);app.persist()
            }
            guard valid() else{return};let current=input(app);fingerprint=current.canonicalJSON
            if current["notes"].array.isEmpty {summary="";return}
            let signature=(try? policy.value("signature",current))?.string ?? "",cache="piyali.memory.summary."+scope
            if UserDefaults.standard.string(forKey:cache+".signature") == signature{return}
            if let text=(try? await policy.generate("summary",current,respond:respond))?.string,valid(),!text.isEmpty {summary=text;UserDefaults.standard.set(text,forKey:cache);UserDefaults.standard.set(signature,forKey:cache+".signature")}
        }
    }
    func cancel(){task?.cancel();task=nil;pendingRefresh=false;epoch=UUID()}
}
