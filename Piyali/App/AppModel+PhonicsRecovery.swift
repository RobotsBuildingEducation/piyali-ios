import Foundation

extension AppModel {
    func phonicsFinishIntent(goal:JSONValue?,repair:RepairStep?)->PhonicsFinishIntent? {
        let key=goal.map{GoalPractice.artifactKey(target:learner.target,day:$0["dayKey"].string,mode:"phonics",goalID:$0["goalId"].string)} ?? repair.map{CompanionQuestDay.artifactKey($0,mode:"phonics")} ?? ""
        return learner.pendingPhonicsFinishes?[key]
    }
    func cancelPhonicsRecovery(){phonicsRecoveryTask?.task.cancel();phonicsRecoveryTask=nil;for job in phonicsFinishTasks.values{job.task.cancel()};phonicsFinishTasks=[:]}
    /// Coalesce automatic recovery and an active card's explicit save retry.
    func finishPhonicsFocus(goal:JSONValue?,repair:RepairStep?,completionAllowed:Bool=true)async throws {
        let intent=phonicsFinishIntent(goal:goal,repair:repair),scope=goal?.json ?? repair?.item.json ?? "ordinary"
        let key=identity.sessionRevision.uuidString+":"+learner.target+":"+learner.support+":"+(intent?.id.uuidString ?? scope)+":"+String(completionAllowed)
        if let job=phonicsFinishTasks[key]{return try await job.task.value}
        let id=UUID(),task=Task{try await performPhonicsFinish(goal:goal,repair:repair,completionAllowed:completionAllowed)};phonicsFinishTasks[key]=(id,task)
        defer{if phonicsFinishTasks[key]?.id == id{phonicsFinishTasks.removeValue(forKey:key)}}
        try await task.value
    }
    func resumePendingPhonicsFinishes()async {
        if let job=phonicsRecoveryTask{await job.task.value;return}
        guard signedIn else{return}
        captureLegacyPhonicsFinishes()
        guard !(learner.pendingPhonicsFinishes ?? [:]).isEmpty else{return}
        let id=UUID(),task=Task{await performPendingPhonicsFinishes()};phonicsRecoveryTask=(id,task)
        await task.value
        if phonicsRecoveryTask?.id == id{phonicsRecoveryTask=nil}
    }
    private func performPendingPhonicsFinishes()async {
        let account=identity.npub,session=identity.sessionRevision
        if phonicsLibrary.isEmpty{await reloadContent()}
        for intent in (learner.pendingPhonicsFinishes ?? [:]).values.sorted(by:{$0.key < $1.key}) {
            guard !Task.isCancelled,signedIn,identity.npub == account,identity.sessionRevision == session else{return}
            guard intent.account == account,intent.target == learner.target else{continue}
            let current=intent.support == learner.support && intent.day == CalendarDay.key(Date()) && (intent.goal.map{goalIsCurrent($0)} ?? intent.repair.map{step in learner.repairPlan(day:step.day)?["items"].array.indices.contains(step.index) == true && learner.repairPlan(day:step.day)?["items"].array[step.index] == step.item} ?? false)
            if !current {
                if !learner.hasPendingPhonicsReceipt(intent),learner.retirePhonicsFinish(intent){persistPhonicsRecovery()}
                continue
            }
            do{try await finishPhonicsFocus(goal:intent.goal,repair:intent.repair)}catch is CancellationError{return}catch{} // Keep the same earned continuation for the next authorized sync.
        }
    }
    /// Older app versions did not persist a continuation. Only a still-queued successful
    /// pronunciation plus its matching saved outcome proves an interrupted finish.
    func captureLegacyPhonicsFinishes() {
        guard signedIn else{return}
        for event in learner.pendingChanges ?? [] where event.source == .phonicsAttempt && event.correct == true && event.amount>0 && event.target == learner.target && event.dayKey == CalendarDay.key(Date()) && event.phonicsData?["focused"].boolean == true {
            let cardID=event.contentID ?? ""
            if let bp=readyGoal?["blueprint"],(learner.goalArtifacts?[GoalPractice.artifactKey(target:learner.target,day:bp["dayKey"].string,mode:"phonics",goalID:bp["goalId"].string)] ?? .null)["outcomes"][cardID]["success"].boolean,(learner.pendingGoalChanges ?? []).contains(where:{$0.action == .outcome && $0.target == event.target && $0.payload["mode"].string == "phonics" && $0.payload["goalId"] == bp["goalId"] && $0.payload["cardID"].string == cardID && $0.payload["success"].boolean && $0.payload["externalReward"].boolean}),let intent=PhonicsFinishIntent(id:event.id,account:identity.npub,target:learner.target,support:learner.support,goal:bp,repair:nil),learner.pendingPhonicsFinishes?[intent.key] == nil{learner.queuePhonicsFinish(intent);persistPhonicsRecovery()}
            if let step=currentRepairStep,learner.repairArtifact(step,mode:"phonics")["outcomes"][cardID]["success"].boolean,learner.repairArtifact(step,mode:"phonics")["outcomes"][cardID]["iosAttemptID"].string == event.id.uuidString,let intent=PhonicsFinishIntent(id:event.id,account:identity.npub,target:learner.target,support:learner.support,goal:nil,repair:step),learner.pendingPhonicsFinishes?[intent.key] == nil{learner.queuePhonicsFinish(intent);persistPhonicsRecovery()}
        }
    }
}
