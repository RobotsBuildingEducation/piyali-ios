import Foundation
import UIKit
import FirebaseAILogic

@MainActor final class PracticeAssistanceController:ObservableObject {
    typealias Writer=(_ prompt:String,_ update:@escaping @MainActor(String)->Void)async throws->String
    @Published private(set) var clipboardNotice=""
    private var noticeTask:Task<Void,Never>?
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
    func cancel(){dismissClipboardNotice();revision=UUID();explanationRevision=UUID();assistantTask?.cancel();explanationTask?.cancel();assistantTask=nil;explanationTask=nil;assistantBusy=false;explanationBusy=false}
    func clear(){cancel();scope="";assistantOpen=false;assistantText="";explanationText=""}
    func closeAssistant(){assistantOpen=false}
    func responseChanged(){explanationRevision=UUID();explanationTask?.cancel();explanationTask=nil;explanationBusy=false;explanationText=""}
    private func owned(_ app:AppModel,_ run:PracticeRun,_ token:UUID)->Bool {revision == token && scope == context(app,run) && app.learner.practiceRuns?[run.key]?.question.id == run.question.id && app.subscription.hasAccess}
    func ask(_ app:AppModel,run:PracticeRun){
        guard !run.question.options["isFinalQuiz"].boolean,app.subscription.hasAccess,app.learner.target == run.question.target,app.learner.support == run.question.support,app.learner.practiceRuns?[run.key]?.question.id == run.question.id else{return};bind(app,run:run)
        copyStandardBundle(app,run:run)
        if assistantOpen{assistantOpen=false;return};assistantOpen=true;guard !assistantBusy,assistantText.isEmpty else{return}
        let token=revision;assistantBusy=true;var fallback=""
        assistantTask=Task{defer{if owned(app,run,token){assistantBusy=false;assistantTask=nil}}
            do {let request=try prompt("assistant",run:run,level:app.learner.settingsSnapshot["progress"]["level"].string,showTranslations:app.learner.settingsSnapshot["progress"]["showTranslations"] != .bool(false));let prefix=request["prefix"].string;fallback=prefix.trimmingCharacters(in:.whitespacesAndNewlines)
                @MainActor func update(_ text:String){guard owned(app,run,token),!Task.isCancelled else{return};assistantText=prefix+text;if !assistantText.isEmpty,var current=app.learner.practiceRuns?[run.key]{if !current.assisted {current.assisted=true;app.learner.savePractice(current);app.persist()}}}
                update("");let output=try await write(app,request["prompt"].string,update:update);guard owned(app,run,token),!Task.isCancelled else{return};update(output.isEmpty ? EntryCopy.ui(run.question.support,"vocab_assistant_error"):output)
            }catch is CancellationError{}catch{guard owned(app,run,token),!Task.isCancelled else{return};assistantText=fallback.isEmpty ? EntryCopy.ui(run.question.support,"vocab_assistant_error"):fallback;if var current=app.learner.practiceRuns?[run.key]{if !current.assisted {current.assisted=true;app.learner.savePractice(current);app.persist()}}}
        }
    }
    func explain(_ app:AppModel,run:PracticeRun){
        guard !run.question.options["isFinalQuiz"].boolean,run.correct == false,!explanationBusy,explanationText.isEmpty,app.subscription.hasAccess,app.learner.target == run.question.target,app.learner.support == run.question.support,app.learner.practiceRuns?[run.key]?.question.id == run.question.id else{return};bind(app,run:run);let token=revision,request=UUID();explanationRevision=request;explanationBusy=true
        let response=run.response
        explanationTask=Task{defer{if owned(app,run,token),explanationRevision == request{explanationBusy=false;explanationTask=nil}}
            do{let draft=try prompt("explanation",run:run,level:app.learner.settingsSnapshot["progress"]["level"].string,showTranslations:app.learner.settingsSnapshot["progress"]["showTranslations"] != .bool(false)),text=try await write(app,draft["prompt"].string,update:{_ in});guard owned(app,run,token),explanationRevision == request,explanationResponseOwned(app,run:run,response:response),!Task.isCancelled else{return};explanationText=text.isEmpty ? EntryCopy.ui(run.question.support,"vocab_explanation_error"):text}
            catch is CancellationError{}catch{guard owned(app,run,token),explanationRevision == request,explanationResponseOwned(app,run:run,response:response),!Task.isCancelled else{return};explanationText=EntryCopy.ui(run.question.support,"vocab_explanation_error")}
        }
    }
    private func explanationResponseOwned(_ app:AppModel,run:PracticeRun,response:JSONValue)->Bool {
        guard let current=app.learner.practiceRuns?[run.key]else{return false}
        return current.response == response || (["fill","mc","ma","match","translate","repeat"].contains(run.question.kind) && run.lastMissedAnswer != nil && current.lastMissedAnswer == run.lastMissedAnswer && current.lastMissedResponse == run.lastMissedResponse && current.correct == false)
    }
    func dismissClipboardNotice(){noticeTask?.cancel();noticeTask=nil;clipboardNotice=""}
    private func copyStandardBundle(_ app:AppModel,run:PracticeRun){
        guard ["fill","mc","ma"].contains(run.question.kind),let request=try? prompt("assistant",run:run,level:app.learner.settingsSnapshot["progress"]["level"].string,showTranslations:app.learner.settingsSnapshot["progress"]["showTranslations"] != .bool(false)),!request["clipboard"].string.isEmpty else{return}
        UIPasteboard.general.string=request["clipboard"].string;dismissClipboardNotice();clipboardNotice=request["notice"].string
        let token=revision;noticeTask=Task{try? await Task.sleep(for:.milliseconds(1200));guard !Task.isCancelled,self.owned(app,run,token)else{return};self.clipboardNotice="";self.noticeTask=nil}
    }
    private var standardPolicy:StandardAssistancePolicy?
    private var oralPolicy:OralAssistancePolicy?
    private var wordBankPolicy:WordBankAssistancePolicy?
    private func prompt(_ operation:String,run:PracticeRun,level:String="beginner",showTranslations:Bool=true)throws->JSONValue {
        if ["fill","mc","ma","match"].contains(run.question.kind){if standardPolicy == nil{standardPolicy=try StandardAssistancePolicy()};return try standardPolicy!.build(operation,run:run,level:level,showTranslations:showTranslations)}
        if ["speak","flashcard"].contains(run.question.kind){if oralPolicy == nil{oralPolicy=try OralAssistancePolicy()};return try oralPolicy!.build(operation,run:run,level:level)}
        if ["translate","repeat"].contains(run.question.kind){if wordBankPolicy == nil{wordBankPolicy=try WordBankAssistancePolicy()};return try wordBankPolicy!.build(operation,run:run,level:level)}
        if run.question.isDelight {if policy == nil{policy=try PracticeAssistancePolicy()};return try policy!.build(operation,run:run)}
        throw PracticeQuestionFailure.malformed
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
