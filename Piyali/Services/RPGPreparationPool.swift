import Foundation

/// One optional story request per account/source cache key/support language.
/// Consumers own independent leases: cancelling a preview does not cancel a
/// still-authorized warm, and an abandoned response never writes the cache.
@MainActor final class RPGPreparationPool {
    private struct Job {let id:UUID,task:Task<JSONValue?,Never>;var consumers:Set<UUID>}
    private var jobs:[String:Job]=[:]
    let cache:RPGPreparationCache
    init(cache:RPGPreparationCache?=nil){self.cache=cache ?? RPGPreparationCache()}
    var pendingCount:Int{jobs.count}
    var consumerCount:Int{jobs.values.reduce(0){$0+$1.consumers.count}}
    func prepared(request:RPGPreparationPolicy.Request,policy:RPGPreparationPolicy,account:String,support:String,valid:@escaping()->Bool,produce:@escaping()async throws->String)async->RPGPreparationPolicy.Prepared? {
        guard !account.isEmpty,!Task.isCancelled,valid() else{return nil}
        if let value=cache.load(account:account,key:request.cacheKey,support:support),let prepared=try? policy.cached(value,request:request){return prepared}
        let key=JSONValue.array([.string(account),.string(request.cacheKey),.string(support)]).canonicalJSON,consumer=UUID(),job:Job
        if var existing=jobs[key]{existing.consumers.insert(consumer);jobs[key]=existing;job=existing}
        else {let id=UUID(),task=Task{@MainActor in
            do{try Task.checkCancellation();let response=try await produce();try Task.checkCancellation();return try policy.prepare(response:response,request:request)?.cacheValue}catch{return nil}
        };job=Job(id:id,task:task,consumers:[consumer]);jobs[key]=job}
        return await withTaskCancellationHandler {
            defer{release(key:key,job:job.id,consumer:consumer)}
            let value=await job.task.value
            guard !Task.isCancelled,valid(),let current=jobs[key],current.id == job.id,current.consumers.contains(consumer),let value,let result=try? policy.cached(value,request:request)else{return nil}
            cache.save(result.cacheValue,account:account,key:request.cacheKey,support:support);return result
        }onCancel:{Task{@MainActor [weak self] in self?.release(key:key,job:job.id,consumer:consumer)}}
    }
    private func release(key:String,job:UUID,consumer:UUID){guard var current=jobs[key],current.id == job else{return};current.consumers.remove(consumer);if current.consumers.isEmpty{jobs.removeValue(forKey:key);current.task.cancel()}else{jobs[key]=current}}
}
