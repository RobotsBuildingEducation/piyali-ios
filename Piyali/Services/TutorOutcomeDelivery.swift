import Foundation

/// Earned turns belong to the account, not the lifetime of a voice connection.
/// The private intent and two stable receipt IDs survive interruption and retry.
@MainActor final class TutorOutcomeDelivery {
    private struct Job {let scope:String;let token:UUID;let task:Task<Void,Never>}
    private var jobs:[UUID:Job]=[:]
    private func scope(_ app:AppModel)->String {app.identity.npub+":"+app.identity.sessionRevision.uuidString}
    func resume(_ app:AppModel) {
        guard app.signedIn,!app.identity.npub.isEmpty else{return}
        for outcome in app.learner.pendingTutorOutcomes ?? [] {start(outcome,app:app)}
    }
    func start(_ outcome:TutorOutcomeIntent,app:AppModel,quote:Task<JSONValue?,Never>?=nil) {
        let owner=scope(app)
        guard app.signedIn,!app.identity.npub.isEmpty,app.learner.pendingTutorOutcomes?.contains(where:{$0.id == outcome.id}) == true,jobs[outcome.id]?.scope != owner else{return}
        let token=UUID(),task=Task{[weak self,weak app] in
            defer{if self?.jobs[outcome.id]?.token == token{self?.jobs.removeValue(forKey:outcome.id)}}
            let value:JSONValue?
            if let quote {value=await quote.value}
            else if let app,let recipes=try? PracticeRecipes() {
                #if DEBUG
                if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1" {value=try? recipes.inspect("worth",parameters:outcome.worthParameters)}
                else {value=await self?.recover(outcome,app:app,owner:owner,recipes:recipes)}
                #else
                value=await self?.recover(outcome,app:app,owner:owner,recipes:recipes)
                #endif
            }
            else {value=nil}
            guard let self else{return}
            guard let app,app.signedIn,self.scope(app) == owner,!Task.isCancelled else{return}
            if app.learner.deliverTutorOutcome(outcome.id,worth:value){app.persist()}
        }
        jobs[outcome.id]=Job(scope:owner,token:token,task:task)
    }
    private func recover(_ outcome:TutorOutcomeIntent,app:AppModel,owner:String,recipes:PracticeRecipes)async->JSONValue? {
        do {
            try await FirebaseIdentityService.shared.ensure(app.identity)
            guard app.signedIn,scope(app) == owner,!Task.isCancelled else{return nil}
            return try await GeneratedQuestionWorth.assess(parameters:outcome.worthParameters,recipes:recipes,ai:app.ai)
        }catch {
            guard app.signedIn,scope(app) == owner,!Task.isCancelled else{return nil}
            return try? recipes.inspect("worth",parameters:outcome.worthParameters)
        }
    }
    func wait(_ ids:Set<UUID>,app:AppModel)async {
        resume(app)
        let owner=scope(app),tasks=ids.compactMap{id in jobs[id].flatMap{$0.scope == owner ? $0.task:nil}}
        for task in tasks {await task.value}
    }
}
