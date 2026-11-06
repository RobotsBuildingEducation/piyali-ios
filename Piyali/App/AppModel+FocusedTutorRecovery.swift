import Foundation

extension AppModel {
    func focusedTutorRun(_ focus:TutorFocus)->FocusedTutorRun? {
        learner.focusedTutorRuns?.values.first{$0.account == identity.npub && $0.target == learner.target && $0.support == learner.support && $0.focusKey == focus.key && focusedTutorContextMatches($0)}
    }
    private func focusedTutorContextMatches(_ run:FocusedTutorRun)->Bool {
        guard run.day == CalendarDay.key(Date()) else{return false}
        if let goal=run.goal {
            let bucket=learner.goalIntelligence?[run.target] ?? .null,blueprint=bucket["dailyGoal"]["blueprint"]
            return bucket["activeGoal"]["id"] == goal["goalId"] && blueprint.setting("mode",goal["mode"]) == goal
        }
        if let step=run.repair,let plan=learner.repairPlan(day:step.day) {return step.target == run.target && plan["items"].array.indices.contains(step.index) && plan["items"].array[step.index] == step.item}
        return false
    }
    private func focusedTutorWasCompleted(_ run:FocusedTutorRun)->Bool {
        if let goal=run.goal{return (learner.goalIntelligence?[run.target] ?? .null)["dailyGoal"]["modeProgress"][goal["mode"].string].number>=Double(GoalPractice.targets[goal["mode"].string] ?? 1)}
        if let step=run.repair{return learner.plateProgress["repairDailyActivity"][run.target][run.day].number>Double(step.index)}
        return false
    }
    var hasPendingFocusedTutorCompletion:Bool {(learner.focusedTutorRuns ?? [:]).values.contains{$0.ready && $0.account == identity.npub && $0.target == learner.target && $0.support == learner.support && focusedTutorContextMatches($0)}}
    var pendingFocusedTutorCourse:String? {
        guard let run=(learner.focusedTutorRuns ?? [:]).values.sorted(by:{$0.key<$1.key}).first(where:{$0.ready && $0.account == identity.npub && $0.target == learner.target && $0.support == learner.support && focusedTutorContextMatches($0)}) else{return nil}
        return run.goal == nil ? "repair":"goal"
    }
    func cancelFocusedTutorRecovery(){for job in focusedTutorFinishTasks.values{job.task.cancel()};focusedTutorFinishTasks=[:]}
    func resumeFocusedTutorFinishes()async {
        guard signedIn else{return}
        for run in (learner.focusedTutorRuns ?? [:]).values.sorted(by:{$0.key<$1.key}) where run.account == identity.npub && run.target == learner.target && run.support == learner.support && run.day == CalendarDay.key(Date()) {
            if !focusedTutorContextMatches(run) {if run.completionID == nil,learner.retireFocusedTutorRun(run){persistFocusedTutorRecovery()};continue}
            if run.ready || focusedTutorWasCompleted(run){_=await finishFocusedTutor(run.key)}
        }
    }
    @discardableResult func persistFocusedTutorRecovery()->Bool {do{try persistPrivateTutorRun();return true}catch{self.error="Could not save progress: \(error.localizedDescription)";return false}}
    func finishFocusedTutor(_ key:String)async->Bool {
        if let job=focusedTutorFinishTasks[key]{return await job.task.value}
        let id=UUID(),task=Task{await performFocusedTutorFinish(key)};focusedTutorFinishTasks[key]=(id,task)
        let result=await task.value;if focusedTutorFinishTasks[key]?.id == id{focusedTutorFinishTasks.removeValue(forKey:key)};return result
    }
    private func performFocusedTutorFinish(_ key:String)async->Bool {
        guard let original=learner.focusedTutorRuns?[key],original.ready || focusedTutorWasCompleted(original) else{return false}
        let account=identity.npub,session=identity.sessionRevision
        @MainActor func owned()->Bool {signedIn && identity.npub == account && identity.sessionRevision == session && !Task.isCancelled && learner.target == original.target && learner.support == original.support && learner.focusedTutorRuns?[key]?.id == original.id}
        guard owned(),original.account == account,focusedTutorContextMatches(original) else{return false}
        await tutorOutcomes.wait(original.outcomeIDs,app:self)
        guard owned(),focusedTutorContextMatches(original),var run=learner.focusedTutorRuns?[key] else{return false}
        if run.completionID == nil {
            if focusedTutorWasCompleted(run){if learner.retireFocusedTutorRun(run){persistFocusedTutorRecovery()};return true}
            guard run.ready else{return false}
            var next=learner
            if let goal=run.goal {
                guard goalIsCurrent(goal) else{return false}
                let payload:JSONValue = .object(["goalId":goal["goalId"],"dayKey":goal["dayKey"],"cefrLevel":goal["cefrLevel"],"mode":goal["mode"],"success":.bool(true),"support":.string("prompted"),"domain":.string("production"),"observation":.string("Completed \(run.required) XP of goal-specific Tutor practice with successful spoken turns."),"priorModeProgress":next.goalBucket["dailyGoal"]["modeProgress"][goal["mode"].string],"sourceEvidenceID":.string("tutor:"+goal["goalId"].string+":"+goal["dayKey"].string)])
                let change=GoalChange(action:.attempt,target:run.target,payload:payload);next.applyGoal(change);run.completionID=change.id
            } else if let step=run.repair,let policy=companionQuestPolicy {
                guard next.repairStepIsCurrent(step) else{return false}
                let now=Date(),event=step.event.setting("success",.bool(run.evidence["success"].boolean)).setting("support",.string("prompted")).setting("observation",run.evidence["observation"] == .null ? .string(""):run.evidence["observation"])
                guard let summary=try? policy.run("evidence",.object(["summary":next.goalBucket["repairSummary"],"event":event,"now":.number(now.timeIntervalSince1970*1000)])),next.completeRepairStep(step,summary:summary,observation:event["observation"].string,support:"prompted",success:run.evidence["success"].boolean,bonusXP:run.required,now:now) else{return false}
                run.completionID=next.pendingChanges?.last(where:{$0.source == .repair && $0.contentID == step.id})?.id
            } else{return false}
            next.storeFocusedTutorRun(run);learner=next
            guard persistFocusedTutorRecovery() else{return false};persist()
        }
        await syncProgress()
        guard owned(),let settled=learner.focusedTutorRuns?[key],focusedTutorContextMatches(settled) else{return false}
        let pending=settled.completionID.map{id in (learner.pendingGoalChanges ?? []).contains{$0.id == id} || (learner.pendingChanges ?? []).contains{$0.id == id}} ?? true
        guard !pending,focusedTutorWasCompleted(settled) else{return false}
        if learner.retireFocusedTutorRun(settled){persistFocusedTutorRecovery()};return true
    }
}
