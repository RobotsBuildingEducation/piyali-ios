import Foundation
import Combine
import CryptoKit

@MainActor protocol AchievementSyncJournal {
    func read(_ account:String)throws->[String:Bool]
    func write(_ flags:[String:Bool],account:String)throws
}
@MainActor final class FileAchievementSyncJournal:AchievementSyncJournal {
    private let root:URL
    init(root:URL?=nil){self.root=root ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Piyali/AchievementSync",isDirectory:true)}
    private func url(_ account:String)->URL{root.appendingPathComponent(SHA256.hash(data:Data(account.utf8)).map{String(format:"%02x",$0)}.joined()+".json")}
    func read(_ account:String)throws->[String:Bool]{let path=url(account);guard FileManager.default.fileExists(atPath:path.path)else{return [:]};return try JSONDecoder().decode([String:Bool].self,from:Data(contentsOf:path))}
    func write(_ flags:[String:Bool],account:String)throws{try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);try JSONEncoder().encode(flags).write(to:url(account),options:[.atomic,.completeFileProtection])}
}

/// Independent, account-scoped cloud/relay workers. Intent is durable; celebrations stay session-only.
@MainActor final class AchievementRetryController:ObservableObject {
    enum Channel:String,CaseIterable{case cloud,relay}
    typealias Operation = @MainActor (String)async throws->Void
    @Published private(set) var revision=0
    private(set) var account=""
    private let journal:any AchievementSyncJournal
    private let sleep:@Sendable(Int)async throws->Void
    private let timeoutMilliseconds:Int
    private var operations:[Channel:Operation]=[:]
    private struct Key:Hashable{let account:String;let channel:Channel}
    private final class Job {
        var state:AchievementRetry
        var timer:Task<Void,Never>?
        var task:Task<Void,Error>?
        init(pending:Bool){state=AchievementRetry(pending:pending)}
        deinit{timer?.cancel();task?.cancel()}
    }
    private var jobs:[Key:Job]=[:],loaded:Set<String>=[],storageErrors:Set<String>=[]
    init(journal:(any AchievementSyncJournal)?=nil,timeoutMilliseconds:Int=12000,sleep:@escaping @Sendable(Int)async throws->Void={try await Task.sleep(for:.milliseconds($0))}){self.journal=journal ?? FileAchievementSyncJournal();self.timeoutMilliseconds=timeoutMilliseconds;self.sleep=sleep}
    func configure(cloud:@escaping Operation,relay:@escaping Operation){operations=[.cloud:cloud,.relay:relay]}
    func setAccount(_ value:String){guard value != account else{return};pause();account=value;load(value);revision += 1}
    func pending(_ channel:Channel)->Bool{jobs[Key(account:account,channel:channel)]?.state.pending == true}
    var pending:Bool{Channel.allCases.contains{pending($0)}}
    var storageError:Bool{storageErrors.contains(account)}
    func resume(){guard !account.isEmpty else{return};for channel in Channel.allCases{let key=Key(account:account,channel:channel),job=job(key);let delay=job.state.resume();persist(key.account);arm(key,job:job,delay:delay)}}
    func pause(){for(key,job)in jobs where key.account==account{job.state.pause();job.timer?.cancel();job.timer=nil};revision += 1}
    func schedule(_ channel:Channel){guard !account.isEmpty else{return};let key=Key(account:account,channel:channel),job=job(key);let delay=job.state.schedule();persist(key.account);arm(key,job:job,delay:delay)}
    /// Explicit restore/publish and ordinary progress saves join a worker instead of racing its timer.
    func runNow(_ channel:Channel,operation:Operation?=nil)async throws{
        guard !account.isEmpty else{throw CancellationError()};let key=Key(account:account,channel:channel),job=job(key);_ = job.state.schedule();persist(key.account);job.timer?.cancel();job.timer=nil
        while let running=job.task{_ = try? await running.value;try Task.checkCancellation();guard account==key.account,job.state.active else{throw CancellationError()}}
        guard let task=start(key,job:job,operation:operation)else{throw CancellationError()};try await task.value
    }
    private func load(_ account:String){guard !account.isEmpty,loaded.insert(account).inserted else{return};do{let flags=try journal.read(account);for channel in Channel.allCases{jobs[Key(account:account,channel:channel)]=Job(pending:flags[channel.rawValue] == true)}}catch{storageErrors.insert(account);for channel in Channel.allCases{jobs[Key(account:account,channel:channel)]=Job(pending:true)}}}
    private func job(_ key:Key)->Job{load(key.account);if let existing=jobs[key]{return existing};let created=Job(pending:false);jobs[key]=created;return created}
    private func persist(_ account:String){let flags=Dictionary(uniqueKeysWithValues:Channel.allCases.map{($0.rawValue,jobs[Key(account:account,channel:$0)]?.state.pending == true)});do{try journal.write(flags,account:account);storageErrors.remove(account)}catch{storageErrors.insert(account)};revision += 1}
    private func arm(_ key:Key,job:Job,delay:Int?){guard let delay,job.state.active,!job.state.running else{return};job.timer?.cancel();let sleep=self.sleep;job.timer=Task{[weak self,weak job] in do{try await sleep(delay);try Task.checkCancellation();guard let self,let job,self.account==key.account else{return};job.timer=nil;_ = self.start(key,job:job)}catch{}}}
    @discardableResult private func start(_ key:Key,job:Job,operation:Operation?=nil)->Task<Void,Error>?{
        guard account==key.account,let action=operation ?? operations[key.channel],let sent=job.state.begin()else{return nil};revision += 1
        let task=Task{[weak self,weak job] in
            guard let self,let job else{throw CancellationError()}
            do{try await deadline{try await action(key.account)};finish(key,job:job,sent:sent,failed:false)}catch{finish(key,job:job,sent:sent,failed:true);throw error}
        };job.task=task;return task
    }
    private func finish(_ key:Key,job:Job,sent:Int,failed:Bool){job.task=nil;let delay=job.state.finish(sent:sent,failed:failed);persist(key.account);arm(key,job:job,delay:delay)}
    // An unstructured race is intentional: cancellation-unaware SDK continuations must not
    // prevent a deadline from releasing the worker. Late operations check cancellation before UI acknowledgment.
    private func deadline(_ operation:@escaping @MainActor()async throws->Void)async throws{
        final class Gate{var continuation:CheckedContinuation<Void,Error>?;var work:Task<Void,Never>?;var timer:Task<Void,Never>?;func finish(_ error:Error?){guard let continuation else{return};self.continuation=nil;timer?.cancel();work?.cancel();if let error{continuation.resume(throwing:error)}else{continuation.resume()}}}
        let gate=Gate(),timeout=timeoutMilliseconds
        try await withTaskCancellationHandler{try await withCheckedThrowingContinuation{continuation in
            gate.continuation=continuation
            gate.work=Task{do{try await operation();try Task.checkCancellation();gate.finish(nil)}catch{gate.finish(error)}}
            gate.timer=Task{do{try await Task.sleep(for:.milliseconds(timeout));try Task.checkCancellation();gate.finish(AppError.message("Achievement sync timed out"))}catch{}}
        }}onCancel:{Task{@MainActor in gate.finish(CancellationError())}}
    }
}
