import Foundation

extension AppModel {
    func createStudyNote(run:PracticeRun,lesson:Lesson?,respond:(@MainActor (String)async throws->String)?=nil)async throws->Bool {
        guard let policy=MemoryUI.policy else{throw PracticeRecipeFailure.unavailable}
        let account=identity.npub,session=identity.sessionRevision,target=learner.target,support=learner.support
        guard signedIn,target == run.question.target,support == run.question.support,learner.practiceRuns?[run.key]?.question.id == run.question.id else{return false}
        let input=run.studyNoteContext,title=lesson?.title ?? PracticeRun.studyLessonTitle(run.question.module,delight:run.question.isDelight)
        let note=try await policy.generate("note",input){[weak self] prompt in guard let self else{throw CancellationError()};if let respond{return try await respond(prompt)};if let value=try await MemoryDrawerFixture.studyNoteResponse(prompt,language:support){return value};return try await self.ai.studyNoteText(prompt)}
        // Source requests retain their captured context after Next/unmount.
        try Task.checkCancellation();guard signedIn,identity.npub == account,identity.sessionRevision == session,learner.target == target,learner.support == support else{return false}
        let meta=input.setting("targetLang",.string(target)).setting("supportLang",.string(support)).setting("lessonTitle",title).setting("example",note["example"]).setting("summary",note["summary"])
        learner.notes.insert(Note(title:input["concept"].string,body:note["example"].string+"\n\n"+note["summary"].string,study:meta,createdAt:Date()),at:0);persist();showMemoryCapture();return true
    }
}
