import Foundation

extension AppModel {
    func createStudyNote(run:PracticeRun,lesson:Lesson?)async throws->Bool {
        guard let policy=MemoryUI.policy else{throw PracticeRecipeFailure.unavailable}
        let account=identity.npub,target=learner.target,support=learner.support
        let input:JSONValue = .object(["concept":.string(run.question.questionText),"userAnswer":.string(run.answerText),"wasCorrect":.bool(run.correct == true),"target":.string(target),"language":.string(support),"cefrLevel":.string(run.question.level),"moduleType":.string(run.question.module.rawValue)])
        let note=try await policy.generate("note",input){[weak self] prompt in guard let self else{throw CancellationError()};if let value=MemoryDrawerFixture.response(prompt,language:support){return value};return try await self.ai.responsesText(prompt)}
        try Task.checkCancellation();guard identity.npub == account,learner.target == target,learner.support == support,learner.practiceRuns?[run.key]?.question.id == run.question.id else{return false}
        let meta=input.setting("targetLang",.string(target)).setting("supportLang",.string(support)).setting("lessonTitle",lesson?.title ?? .object(["en":.string(run.question.module.rawValue.capitalized)])).setting("example",note["example"]).setting("summary",note["summary"])
        learner.notes.insert(Note(title:run.question.questionText,body:note["example"].string+"\n\n"+note["summary"].string,study:meta,createdAt:Date()),at:0);persist();return true
    }
}
