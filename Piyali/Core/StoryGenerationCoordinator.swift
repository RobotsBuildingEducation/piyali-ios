import Foundation

/// The source coordinator keeps mandatory validation separate from advisory style.
@MainActor public enum StoryGenerationCoordinator {
    public static func generate(prompt:String,mode:StoryMode,
        generate:@escaping @MainActor (String,Bool) async throws->String,
        validate:@escaping @MainActor (String)throws->StoryRun,
        issues:@escaping @MainActor (StoryRun)throws->[String],
        review:@escaping @MainActor (StoryRun)async throws->[String],
        revision:@escaping @MainActor (String,String,String)throws->String,
        reviewTimeout:Double=5,rewriteTimeout:Double=10) async throws->StoryRun {
        var next=prompt,best:(run:StoryRun,score:Int)?,invalid=0
        for attempt in 1...3 {
            try Task.checkCancellation()
            let raw:String
            do {
                if best != nil { let request=next;raw=try await bounded(seconds:rewriteTimeout) { try await generate(request,true) } }
                else { raw=try await generate(next,false) }
            } catch {
                try Task.checkCancellation();if let best { return best.run };throw error
            }
            try Task.checkCancellation()
            let candidate:StoryRun
            do { candidate=try validate(raw) }
            catch {
                try Task.checkCancellation()
                if let best { return best.run };invalid += 1
                if attempt == 3 || invalid == (mode == .speaking ? 3 : 2) { throw error }
                next=try revision("validation",raw,error.localizedDescription);continue
            }
            let local=try issues(candidate)
            let advisory=(try? await bounded(seconds:reviewTimeout) { try await review(candidate) }) ?? []
            try Task.checkCancellation()
            let score=local.count*2+advisory.count,hadCandidate=best != nil
            if best == nil || score <= best!.score { best=(candidate,score) }
            if score == 0 || hadCandidate || attempt == 3 { return best!.run }
            next=try revision("quality",raw,"")
        }
        throw StoryFailure.invalid
    }
    /// Unstructured work allows a provider that ignores cancellation to finish late
    /// without holding up a usable activity or resuming the caller twice.
    public static func bounded<T:Sendable>(seconds:Double,operation:@escaping @MainActor ()async throws->T) async throws->T {
        let race=StoryGenerationRace<T>()
        return try await withTaskCancellationHandler(operation:{
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else { continuation.resume(throwing:CancellationError());return }
                race.continuation=continuation
                race.work=Task { @MainActor [weak race] in
                    do { let value=try await operation();race?.finish(.success(value)) }
                    catch { race?.finish(.failure(error)) }
                }
                race.timer=Task { @MainActor [weak race] in
                    do { try await Task.sleep(for:.seconds(max(0,seconds)));race?.finish(.failure(StoryGenerationTimeout())) } catch { }
                }
            }
        },onCancel:{ Task { @MainActor in race.finish(.failure(CancellationError())) } })
    }
}
private struct StoryGenerationTimeout:LocalizedError,Sendable { var errorDescription:String? { "Optional story review timed out." } }
@MainActor private final class StoryGenerationRace<T:Sendable> {
    var continuation:CheckedContinuation<T,Error>?
    var work:Task<Void,Never>?,timer:Task<Void,Never>?
    func finish(_ result:Result<T,Error>) {
        guard let continuation else { return };self.continuation=nil
        work?.cancel();timer?.cancel();work=nil;timer=nil;continuation.resume(with:result)
    }
}
