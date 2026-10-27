import Foundation
import FirebaseAILogic

@MainActor final class PracticeAssistanceController:ObservableObject {
    typealias Writer=(_ prompt:String,_ update:@escaping @MainActor(String)->Void)async throws->String
    @Published private(set) var assistantOpen=false
    @Published private(set) var assistantText=""
    @Published private(set) var assistantBusy=false
    @Published private(set) var explanationText=""
    @Published private(set) var explanationBusy=false
    private var assistantTask:Task<Void,Never>?,explanationTask:Task<Void,Never>?
    private var scope="",revision=UUID(),explanationRevision=UUID()
    private var policy:PracticeAssistancePolicy?
    private let writer:Writer?
    init(writer:Writer?=nil){self.writer=writer}
    private func context(_ app:AppModel,_ run:PracticeRun)->String {[app.identity.npub,app.learner.target,app.learner.support,run.question.id.uuidString].joined(separator:"|")}
    func bind(_ app:AppModel,run:PracticeRun){let next=context(app,run);guard scope != next else{return};cancel();scope=next;assistantOpen=false;assistantText="";explanationText=""}
    func cancel(){revision=UUID();explanationRevision=UUID();assistantTask?.cancel();explanationTask?.cancel();assistantTask=nil;explanationTask=nil;assistantBusy=false;explanationBusy=false}
    func clear(){cancel();scope="";assistantOpen=false;assistantText="";explanationText=""}
    func closeAssistant(){assistantOpen=false}
    func responseChanged(){explanationRevision=UUID();explanationTask?.cancel();explanationTask=nil;explanationBusy=false;explanationText=""}
    private func owned(_ app:AppModel,_ run:PracticeRun,_ token:UUID)->Bool {revision == token && scope == context(app,run) && app.learner.practiceRuns?[run.key]?.question.id == run.question.id && app.subscription.hasAccess}
    func ask(_ app:AppModel,run:PracticeRun){
        guard !run.question.options["isFinalQuiz"].boolean,app.subscription.hasAccess,app.learner.target == run.question.target,app.learner.support == run.question.support,app.learner.practiceRuns?[run.key]?.question.id == run.question.id else{return};bind(app,run:run)
        if assistantOpen{assistantOpen=false;return};assistantOpen=true;guard !assistantBusy,assistantText.isEmpty else{return}
        let token=revision;assistantBusy=true;var fallback=""
        assistantTask=Task{defer{if owned(app,run,token){assistantBusy=false;assistantTask=nil}}
            do {let request=try prompt("assistant",run:run,level:app.learner.settingsSnapshot["progress"]["level"].string);let prefix=request["prefix"].string;fallback=prefix.trimmingCharacters(in:.whitespacesAndNewlines)
                @MainActor func update(_ text:String){guard owned(app,run,token),!Task.isCancelled else{return};assistantText=prefix+text;if !assistantText.isEmpty,var current=app.learner.practiceRuns?[run.key]{if !current.assisted {current.assisted=true;app.learner.savePractice(current);app.persist()}}}
                update("");let output=try await write(app,request["prompt"].string,update:update);guard owned(app,run,token),!Task.isCancelled else{return};update(output.isEmpty ? EntryCopy.ui(run.question.support,"vocab_assistant_error"):output)
            }catch is CancellationError{}catch{guard owned(app,run,token),!Task.isCancelled else{return};assistantText=fallback.isEmpty ? EntryCopy.ui(run.question.support,"vocab_assistant_error"):fallback;if var current=app.learner.practiceRuns?[run.key]{if !current.assisted {current.assisted=true;app.learner.savePractice(current);app.persist()}}}
        }
    }
    func explain(_ app:AppModel,run:PracticeRun){
        guard !run.question.options["isFinalQuiz"].boolean,run.correct == false,!explanationBusy,explanationText.isEmpty,app.subscription.hasAccess,app.learner.target == run.question.target,app.learner.support == run.question.support,app.learner.practiceRuns?[run.key]?.question.id == run.question.id else{return};bind(app,run:run);let token=revision,request=UUID();explanationRevision=request;explanationBusy=true
        let response=run.response
        explanationTask=Task{defer{if owned(app,run,token),explanationRevision == request{explanationBusy=false;explanationTask=nil}}
            do{let draft=try prompt("explanation",run:run,level:app.learner.settingsSnapshot["progress"]["level"].string),text=try await write(app,draft["prompt"].string,update:{_ in});guard owned(app,run,token),explanationRevision == request,explanationResponseOwned(app,run:run,response:response),!Task.isCancelled else{return};explanationText=text.isEmpty ? EntryCopy.ui(run.question.support,"vocab_explanation_error"):text}
            catch is CancellationError{}catch{guard owned(app,run,token),explanationRevision == request,explanationResponseOwned(app,run:run,response:response),!Task.isCancelled else{return};explanationText=EntryCopy.ui(run.question.support,"vocab_explanation_error")}
        }
    }
    private func explanationResponseOwned(_ app:AppModel,run:PracticeRun,response:JSONValue)->Bool {
        guard let current=app.learner.practiceRuns?[run.key]else{return false}
        return current.response == response || (["translate","repeat"].contains(run.question.kind) && run.lastMissedAnswer != nil && current.lastMissedAnswer == run.lastMissedAnswer && current.correct == false)
    }
    private var oralPolicy:OralAssistancePolicy?
    private var wordBankPolicy:WordBankAssistancePolicy?
    private func prompt(_ operation:String,run:PracticeRun,level:String="beginner")throws->JSONValue {
        if ["speak","flashcard"].contains(run.question.kind){if oralPolicy == nil{oralPolicy=try OralAssistancePolicy()};return try oralPolicy!.build(operation,run:run,level:level)}
        if ["translate","repeat"].contains(run.question.kind){if wordBankPolicy == nil{wordBankPolicy=try WordBankAssistancePolicy()};return try wordBankPolicy!.build(operation,run:run,level:level)}
        if run.question.isDelight {if policy == nil{policy=try PracticeAssistancePolicy()};return try policy!.build(operation,run:run)}
        // Legacy formats retain their data context; direct help follows the source assistance contract.
        let q=run.question,target=EntryCopy.ui(q.support,"language_"+q.target),support=EntryCopy.names[q.support] ?? q.support,data:JSONValue = .object(["question":q.payload,"response":run.response,"bank":.array(run.bank.map(JSONValue.string)),"expected":.string(run.expected)])
        return .object(["prefix":.string(""),"prompt":.string(operation == "assistant" ? "The learner is practicing \(target). Write all guidance in \(support). Start with the exact answer and concrete selections or steps, then briefly explain why it works. Use only the offered exercise material. Do not withhold the answer or turn the request into a guessing question. Exercise data: "+data.json:"Explain this incorrect language exercise response in 2–3 encouraging sentences in \(support), teaching \(target). Explain why the answer does not fit, show the correct response and give a friendly tip. Exercise data: "+data.json)])
    }
    private func write(_ app:AppModel,_ prompt:String,update:@escaping @MainActor(String)->Void)async throws->String {if let writer{return try await writer(prompt,update)}
        #if DEBUG
        if let text=try await PracticeAssistanceFixture.write(prompt,update:update){return text}
        #endif
        return try await app.ai.practiceAssistanceText(prompt,onText:update)}
}
extension AIService {
    func practiceAssistanceText(_ prompt:String,onText:@escaping @MainActor(String)->Void)async throws->String {
        if configuration.string("AIProvider") == "gemini",FirebaseService.shared.configured {
            let model=FirebaseAI.firebaseAI(backend:configuration.geminiBackend()).generativeModel(modelName:configuration.string("GeminiModel"));var output=""
            for try await chunk in try model.generateContentStream(prompt){try Task.checkCancellation();output+=chunk.text ?? "";onText(output)}
            return output
        }
        let output=try await responsesText(prompt);try Task.checkCancellation();onText(output);return output
    }
}
