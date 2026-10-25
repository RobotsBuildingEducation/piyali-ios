import Foundation
import CryptoKit

struct HelpChatMessage:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var role:String
    var text:String
    var done=true
    var sortOrder:Double=0
    var createdAt=Date().timeIntervalSince1970*1000
    var value:JSONValue{(try? JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(self))) ?? .null}
}
struct SavedHelpChat:Codable,Equatable,Identifiable {
    var id=UUID().uuidString
    var title:String
    var messages:[HelpChatMessage]
    var savedAt=Date().timeIntervalSince1970*1000
    var targetLang:String
}
@MainActor struct HelpChatProvider {
    var text:(String)async throws->String
    var stream:(String,@escaping @MainActor(String)->Void)async throws->String
    static func native(_ ai:AIService)->Self{
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,env["PIYALI_HELP_FIXTURE"] == "1" {
            return .init(text:{_ in #"{"translation":"sister","targetText":"hermana"}"#},stream:{prompt,chunk in
                if prompt.contains("FAIL_HELP"){throw URLError(.notConnectedToInternet)}
                let text=prompt.contains("Analyze the morphemes") ? "**hermana** = herman + a\n- herman: sibling\n- a: feminine\n→ sister":prompt.contains("Egyptian Arabic") ? "استخدم **hermana** للكلام عن أختك.\n// Mi hermana vive aquí.":"Use **hermana** to talk about your sister.\n// Mi hermana vive aquí."
                chunk(String(text.prefix(12)));try await Task.sleep(for:.milliseconds(prompt.contains("STOP_HELP") ? 3000:150));chunk(text);return text
            })
        }
        #endif
        return .init(text:{try await ai.text($0)},stream:{try await ai.flashcardTextStream($0,onChunk:$1)})
    }
}

/// Private Help conversations never enter learner progress, notes or reward sync.
@MainActor final class HelpChatController:ObservableObject {
    @Published private(set) var messages:[HelpChatMessage]=[]
    @Published private(set) var saved:[SavedHelpChat]=[]
    @Published private(set) var busy=false
    @Published private(set) var morphemes=false
    @Published var notice:String?
    @Published private(set) var noticeKind="info"
    let policy:HelpChatPolicy?
    private var account="",parameters:JSONValue = .object([:]),file:URL?,epoch=UUID(),work:Task<Void,Never>?
    private let directory:URL
    private var noticeTimer:Task<Void,Never>?
    private struct Archive:Codable{var chats:[SavedHelpChat];var morphemes:Bool}
    init(directory:URL?=nil,policy:HelpChatPolicy?=try? HelpChatPolicy()){
        self.directory=directory ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("PiyaliHelp",isDirectory:true);self.policy=policy
    }
    func configure(account:String,progress:JSONValue,appLanguage:String){
        let next:JSONValue = .object(["progress":progress,"appLanguage":.string(appLanguage)])
        guard self.account != account || parameters != next else{return};stop()
        parameters=next
        if self.account != account {
            self.account=account;messages=[];saved=[];morphemes=false;notice=nil
            file=account.isEmpty ? nil:directory.appendingPathComponent(SHA256.hash(data:Data(account.utf8)).map{String(format:"%02x",$0)}.joined()+".json")
            if let file,let data=try? Data(contentsOf:file),let archive=try? JSONDecoder().decode(Archive.self,from:data){saved=Array(archive.chats.prefix(20));morphemes=archive.morphemes}
        }
    }
    func copy(_ key:String)->String{(try? policy?.run("copy",parameters)[key].string) ?? ""}
    func run(_ operation:String,_ extra:JSONValue = .object([:]))throws->JSONValue{guard let policy else{throw PracticeRecipeFailure.unavailable};var input=parameters;for(key,value)in extra.object{input=input.setting(key,value)};return try policy.run(operation,input)}
    func send(_ raw:String,provider:HelpChatProvider){
        let question=raw.trimmingCharacters(in:.whitespacesAndNewlines);guard !busy,!account.isEmpty,!question.isEmpty else{return}
        stop();let token=epoch,history=messages.map(\.value),mode=morphemes,id=UUID().uuidString
        append(.init(role:"user",text:question));append(.init(id:id,role:"assistant",text:"",done:false));busy=true;notice=nil
        work=Task{[weak self] in guard let self else{return};defer{if epoch == token{busy=false;work=nil}}
            do {
                let text:String
                if mode {
                    let prompt=try run("planPrompt",.object(["question":.string(question)])).string,raw=try await provider.text(prompt)
                    guard valid(token) else{return};let plan=try run("parsePlan",.object(["text":.string(raw)]))
                    guard !plan["translation"].string.isEmpty,!plan["targetText"].string.isEmpty else{throw PracticeRecipeFailure.invalidRecipe}
                    let prefix="// "+plan["translation"].string;patch(id,text:prefix,done:false)
                    let breakdown=try run("breakdownPrompt",.object(["text":plan["targetText"]])).string
                    var result=try await provider.stream(breakdown){[weak self] chunk in guard let self,self.valid(token) else{return};self.patch(id,text:prefix+"\n\n"+chunk,done:false)}
                    guard valid(token) else{return}
                    if try !run("hasBreakdown",.object(["text":.string(result)])).boolean {
                        let fallback=try await provider.text(breakdown);guard valid(token) else{return};if !fallback.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty{result=fallback.trimmingCharacters(in:.whitespacesAndNewlines)}
                    }
                    text=result.isEmpty ? prefix:prefix+"\n\n"+result
                }else {
                    let prompt=try run("prompt",.object(["question":.string(question),"messages":.array(history)])).string
                    text=try await provider.stream(prompt){[weak self] chunk in guard let self,self.valid(token) else{return};self.patch(id,text:chunk,done:false)}
                }
                guard valid(token) else{return};patch(id,text:text,done:true)
            }catch is CancellationError{}catch{
                guard valid(token) else{return};if messages.first(where:{$0.id == id})?.text.isEmpty == true{patch(id,text:copy("requestFailed"),done:true)}else{finish(id)};notify(copy("chatErrorTitle")+": "+error.localizedDescription,kind:"error",milliseconds:5000)
            }
        }
    }
    func stop(){epoch=UUID();work?.cancel();work=nil;busy=false;for i in messages.indices where !messages[i].done{messages[i].done=true}}
    func newChat(){stop();messages=[];notice=nil}
    func save(){notice=nil;guard !messages.isEmpty else{notify(copy("noMessagesDesc"),kind:"warning");return};saved.insert(.init(title:String((messages.first(where:{$0.role == "user"})?.text ?? copy("savedChatTitle")).prefix(50)),messages:messages,targetLang:parameters["progress"]["targetLang"].string.isEmpty ? "es":parameters["progress"]["targetLang"].string),at:0);saved=Array(saved.prefix(20));persist();if notice == nil{notify(copy("chatSavedTitle"),kind:"success")}}
    func load(_ chat:SavedHelpChat){stop();messages=chat.messages;notice=nil}
    func delete(_ id:String){saved.removeAll{$0.id == id};notice=nil;persist();if notice == nil{notify(copy("chatDeletedTitle"),milliseconds:1000)}}
    func setMorphemes(_ value:Bool){morphemes=value;notice=nil;persist()}
    func voiceInput(_ input:RealtimeVoiceState.InputTurn){
        guard !messages.contains(where:{$0.id == input.id}) else{return}
        var item=HelpChatMessage(id:input.id,role:"user",text:input.text)
        if let response=input.responseID,let index=messages.firstIndex(where:{$0.id == response}){item.sortOrder=messages[index].sortOrder-0.5;messages.insert(item,at:index)}else{append(item)}
    }
    func voiceReply(_ id:String,text:String){if let index=messages.firstIndex(where:{$0.id == id}){messages[index].text=text;messages[index].done=true}else{append(.init(id:id,role:"assistant",text:text))}}
    private func append(_ message:HelpChatMessage){var item=message;item.sortOrder=(messages.map(\.sortOrder).max() ?? -1)+1;messages.append(item)}
    private func patch(_ id:String,text:String,done:Bool){guard let i=messages.firstIndex(where:{$0.id == id}) else{return};messages[i].text=text;messages[i].done=done}
    private func finish(_ id:String){if let i=messages.firstIndex(where:{$0.id == id}){messages[i].done=true}}
    private func valid(_ token:UUID)->Bool{epoch == token && !Task.isCancelled}
    private func notify(_ text:String,kind:String="info",milliseconds:Int=2000){noticeTimer?.cancel();notice=text;noticeKind=kind;noticeTimer=Task{try? await Task.sleep(for:.milliseconds(milliseconds));guard !Task.isCancelled,notice == text else{return};notice=nil}}
    private func persist(){guard let file else{return};do{try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(Archive(chats:saved,morphemes:morphemes)).write(to:file,options:[.atomic,.completeFileProtectionUntilFirstUserAuthentication])}catch{notify(error.localizedDescription,kind:"error",milliseconds:5000)}}
}
