import Foundation
import Combine
import CryptoKit

/// Explicit saved state and external I/O for isolated simulator journeys.
/// The product's policy, buttons, encryption and mutations remain unchanged.
@MainActor enum MemoryDrawerFixture {
    static var enabled:Bool {
        #if DEBUG
        let e=ProcessInfo.processInfo.environment;return e["PIYALI_OFFLINE_TESTS"] == "1" && e["PIYALI_MEMORY_FIXTURE"] == "1" && UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil
        #else
        return false
        #endif
    }
    static func summary(_ lang:String)->String {lang == "ar" ? "التحيات فيها حرف h صامت. اتصلحت تحية المساء ولسه تحية الصباح محتاجة مراجعة.":"Greetings kept a silent h. The evening greeting was repaired; the morning greeting remains open."}
    static func response(_ prompt:String,language:String)->String? {
        guard enabled else{return nil}
        if prompt.contains("study note"){return JSONValue.object(["example":.string("Hola, mamá."),"summary":.string(language == "ar" ? "استخدم hola لتحية العيلة.":"Use hola to greet a family member.")]).canonicalJSON}
        if prompt.contains("digest"){return summary(language)}
        return JSONValue.object(["did":.string(language == "ar" ? "نسيت حرف h الصامت.":"The silent h was missing."),"fix":.string("hola"),"tip":.string(language == "ar" ? "افتكر حرف h في التحية.":"Keep the h in the greeting.")]).canonicalJSON
    }
    static func repairNotes(_ lang:String)->[MemoryNote] {
        let today=CalendarDay.key(Date()),yesterday=CalendarDay.shift(today,by:-1)
        return [("today",today,"captured","hola","ola",2),("yesterday",yesterday,"reinforced","buenas noches","buenos noches",1),("open",yesterday,"used_in_quest","buenos días","buenas días",1)].map{id,day,status,concept,answer,severity in
            MemoryNote(fields:["id":.string(id),"createdDayKey":.string(day),"createdAt":.number(Date().timeIntervalSince1970*1000),"status":.string(status),"concept":.string(concept),"userAnswer":.string(answer),"expectedAnswer":.string(concept),"correction":.string(concept),"sourceMode":.string("grammar"),"severity":.number(Double(severity)),"supportLang":.string(lang),"targetLang":.string("es"),"mistake":.string(lang == "ar" ? "راجع شكل التحية.":"Check the greeting form."),"tip":.string(lang == "ar" ? "افتكر التحية كاملة.":"Remember the whole greeting."),"enriched":.bool(true),"expiresAfterDayKey":.string(CalendarDay.shift(day,by:1))])
        }
    }
    static func studyNotes(_ lang:String)->[Note] {
        [("00000000-0000-0000-0000-000000000001","es","Hola, mamá.","A1","grammar",false),("00000000-0000-0000-0000-000000000002","es","Me gusta leer.","B1","vocabulary",true),("00000000-0000-0000-0000-000000000003","fr","Bonjour, maman.","A1","flashcard",true)].map{id,target,example,level,module,correct in
            let summary=lang == "ar" ? "استخدم التحية في مكالمة مع العيلة.":"Use this greeting during a family call."
            var note=Note(title:example,body:example+"\n\n"+summary,study:.object(["targetLang":.string(target),"supportLang":.string(lang),"example":.string(example),"summary":.string(summary),"cefrLevel":.string(level),"moduleType":.string(module),"wasCorrect":.bool(correct),"lessonTitle":.object(["en":.string("Family greetings"),"ar":.string("تحيات العيلة")])]),createdAt:Date(timeIntervalSince1970:1792918800));note.id=UUID(uuidString:id)!;return note
        }
    }
    static func seed(_ app:AppModel){
        guard enabled else{return};let key="piyali.memory.fixture.seed."+app.identity.npub;guard !UserDefaults.standard.bool(forKey:key) else{return}
        app.learner.notes=studyNotes(app.learner.support);app.learner.companionMemory=["es":repairNotes(app.learner.support)];app.learner.gettingStartedModalShown=true;app.learner.xpByLanguage=[app.learner.target:20]
        app.learner.editGoal("Talk with family");let bucket=app.learner.goalBucket,goal=bucket["activeGoal"]
        app.learner.goalIntelligence?[app.learner.target]=bucket.setting("goalProgress",.object(["demonstrated":.array([.string("Greet a family member")]),"openCapabilities":.array([.object(["target":.string("Ask a follow-up"),"example":.string("¿Cómo estás?")])]),"usefulLanguage":.array([.string("Hola")])])).setting("dailyGoal",.object(["blueprint":.object(["goalId":goal["id"],"dayKey":.string(CalendarDay.key(Date())),"objective":.string("Greet a relative"),"rationale":.string("A short family call")])]))
        app.learner.pendingGoalChanges=[];UserDefaults.standard.set(true,forKey:key);UserDefaults.standard.set(true,forKey:"piyali.companionBubbleDismissed:"+app.identity.npub+":"+app.learner.target+":"+CalendarDay.key(Date()))
    }
    static func audio()->Data {let rate=16000,count=24000;var output=Data();func ascii(_ s:String){output.append(Data(s.utf8))};func u16(_ n:UInt16){var v=n.littleEndian;withUnsafeBytes(of:&v){output.append(contentsOf:$0)}};func u32(_ n:UInt32){var v=n.littleEndian;withUnsafeBytes(of:&v){output.append(contentsOf:$0)}};ascii("RIFF");u32(UInt32(36+count*2));ascii("WAVEfmt ");u32(16);u16(1);u16(1);u32(UInt32(rate));u32(UInt32(rate*2));u16(2);u16(16);ascii("data");u32(UInt32(count*2));for i in 0..<count{let sample=Int16(sin(Double(i)*2*Double.pi*220/Double(rate))*1800);u16(UInt16(bitPattern:sample))};return output}
    static func journeyStore()->(any VoiceJourneyStoring)? {enabled ? MemoryJourneyFixtureStore():nil}
}
@MainActor private final class MemoryJourneyFixtureStore:VoiceJourneyStoring {
    private var receive:((JSONValue)->Void)?,account="",target=""
    private var key:String{"piyali.memory.fixture.journey."+account+":"+target}
    private var data:JSONValue {
        get{UserDefaults.standard.data(forKey:key).flatMap{try? JSONDecoder().decode(JSONValue.self,from:$0)} ?? .object(["completedQuests":.number(5),"lastPromptedMilestone":.number(ProcessInfo.processInfo.environment["PIYALI_JOURNEY_PROMPT_FIXTURE"] == "1" ? 0:5),"recordings":.object(["1":.object(["createdAt":.string("2026-10-20T12:00:00Z"),"capturedSession":.number(1)])])])}
        set{UserDefaults.standard.set(try? JSONEncoder().encode(newValue),forKey:key);receive?(newValue)}
    }
    func watch(account:String,target:String,onData:@escaping(JSONValue)->Void,onError:@escaping()->Void)throws->AnyCancellable {self.account=account;self.target=target;receive=onData;onData(data);return AnyCancellable{}}
    func load(account:String,target:String,milestone:Int)async throws->JourneyEnvelope {
        if let raw=UserDefaults.standard.dictionary(forKey:key+".\(milestone)"),let wrapped=raw["wrappedKey"] as? String,let iv=raw["iv"] as? Data,let cipher=raw["ciphertext"] as? Data{return .init(wrappedKey:wrapped,iv:iv,ciphertext:cipher)}
        let identity=IdentityService();guard identity.npub == account,VoiceJourneyModel.saved(data,milestone) else{throw CancellationError()}
        let payload:JSONValue = .object(["audio":.string(MemoryDrawerFixture.audio().base64EncodedString()),"mimeType":.string("audio/wav"),"duration":.number(1.5),"prompt":.string("Introduce yourself."),"support":.string("independent")]),key=SymmetricKey(size:.bits256).withUnsafeBytes{Data($0)},nonce=AES.GCM.Nonce().withUnsafeBytes{Data($0)},cipher=try JourneyCryptography.seal(payload,key:key,nonce:nonce,account:account,target:target,milestone:milestone)
        return .init(wrappedKey:try await identity.encryptWallet(JourneyCryptography.hex(key),expectedAuthor:identity.hex),iv:nonce,ciphertext:cipher)
    }
    func save(_ envelope:JourneyEnvelope,account:String,target:String,milestone:Int)async throws {guard VoiceJourneyModel.canRecord(data,milestone) else{throw CancellationError()};UserDefaults.standard.set(["wrappedKey":envelope.wrappedKey,"iv":envelope.iv,"ciphertext":envelope.ciphertext],forKey:key+".\(milestone)");data=data.setting("recordings",data["recordings"].setting(String(milestone),.object(["createdAt":.string(WebProgressContract.iso(Date())),"capturedSession":.number(Double(VoiceJourneyModel.count(data)))])))}
    func acknowledge(account:String,target:String,milestone:Int)async throws {guard VoiceJourneyModel.canRecord(data,milestone) else{return};data=data.setting("lastPromptedMilestone",.number(Double(milestone)))}
    func delete(account:String,target:String,milestone:Int)async throws {var records=data["recordings"].object;records.removeValue(forKey:String(milestone));data=data.setting("recordings",.object(records));UserDefaults.standard.removeObject(forKey:key+".\(milestone)")}
}
