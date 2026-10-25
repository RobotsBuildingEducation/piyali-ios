import Foundation

/// Source XP-snapshot observer: hydration and settings changes never publish;
/// an opted-in, locally held identity can post a newly confirmed XP increase.
@MainActor final class AutomaticProgressController {
    typealias Publisher=(LearnerState,IdentityService,String,Int,String)async throws->Void
    private let publish:Publisher
    private let service:CommunityFeedService
    private var account="",previous:Int?,generation=UUID(),tasks:[UUID:Task<Void,Never>]=[:]
    init(publish:Publisher?=nil){
        let service=CommunityFeedService();self.service=service
        self.publish=publish ?? {state,identity,author,xp,label in
            #if DEBUG
            // Offline fixtures must explicitly inject a loopback publisher.
            if ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1"{return}
            #endif
            try await service.publish(state,identity:identity,expectedAuthor:author,totalXP:xp,languageLabel:label,refreshAfter:false)
        }
    }
    func observe(_ confirmed:LearnerState,identity:IdentityService,locallyAllowed:Bool){
        let npub=identity.npub,xp=confirmed.subscriptionXP
        if account != npub{reset();account=npub}
        guard !npub.isEmpty else{return}
        let last=previous;previous=xp
        guard let last,xp>last,confirmed.automaticPostsEnabled,locallyAllowed,!identity.isRemote else{return}
        let token=generation,id=UUID(),author=identity.hex,translated=EntryCopy.ui(confirmed.support,"language_"+confirmed.target),label=translated == "language_"+confirmed.target ? LearningLanguages.names[confirmed.target] ?? confirmed.target.uppercased():translated,publish=self.publish
        tasks[id]=Task{[weak self,weak identity] in
            defer{self?.tasks.removeValue(forKey:id)}
            guard let self,let identity,!Task.isCancelled,self.generation == token,identity.npub == npub else{return}
            do{try await publish(confirmed,identity,author,xp,label)}catch{}
        }
    }
    func cancelPending(){generation=UUID();for task in tasks.values{task.cancel()};tasks=[:];service.cancel(clear:true)}
    func reset(){cancelPending();account="";previous=nil}
    deinit{for task in tasks.values{task.cancel()}}
}
