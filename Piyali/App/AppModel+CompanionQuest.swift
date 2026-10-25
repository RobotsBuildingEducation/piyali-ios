import Foundation

extension AppModel {
    var companionQuestPreparationKey:String {
        let day=CalendarDay.key(Date()),cleared = !plateCourses.isEmpty && plateCourses.allSatisfy(\.done)
        let loaded=learner.companionQuestDays?[CompanionQuestDay.key(learner.target,day)] != nil && learner.companionQuestDays?[CompanionQuestDay.key(learner.target,CalendarDay.shift(day,by:1))] != nil
        let notes=(learner.companionMemory?[learner.target] ?? []).map{$0.id+":"+String($0.severity)+":"+$0.text("status")+":"+String($0.createdAt.timeIntervalSince1970)}.joined(separator:"|")
        return [identity.npub,learner.target,learner.support,day,String(loaded),String(cleared),learner.goalBucket["activeGoal"]["id"].string,learner.goalBucket["activeGoal"]["text"].string,learner.goalBucket["activeGoal"]["status"].string,learner.goalBucket["activeGoal"]["updatedAt"].string,notes].joined(separator:"\u{1f}")
    }
    func companionBubble(now:Date = Date())->JSONValue {
        let day=CalendarDay.key(now),plan=learner.repairPlan(day:day),first=learner.introductoryQuest(day:day) && plan == nil
        let reusable=(try? companionQuestPolicy?.run("reusable",.object(["user":learner.companionQuestUser,"targetLang":.string(learner.target),"now":.number(now.timeIntervalSince1970*1000)])))?.array ?? []
        let items=plan?["items"].array ?? reusable,concept=items.first?["concept"].string ?? "",goal=GoalPractice.active(learner.goalBucket)?["text"].string ?? ""
        let lead=first ? goal.isEmpty ? "welcome":"welcomeGoal" : concept.isEmpty ? "fresh":items.count > 1 ? "repairMulti":"repair"
        let courses=learner.plateCourses(user:identity.npub,now:now),cleared = !courses.isEmpty && courses.allSatisfy(\.done)
        let source=(try? companionQuestPolicy?.run("bubble",.object(["lang":.string(learner.support),"leadKind":.string(lead),"goal":.string(goal),"concept":.string(concept),"taskList":.string(courses.map{ProductCopy.course(learner.support,$0.kind)}.joined(separator:", ")),"cleared":.bool(cleared && !first && !concept.isEmpty)]))) ?? .object([:])
        let bp=learner.questDay(day:day)["blueprint"],aiLong=bp["status"].string == "ready" ? bp["message"]["long"].string : ""
        let text = !cleared || (!first && !concept.isEmpty) ? !first && !aiLong.isEmpty ? aiLong:source["long"].string : ""
        return source.setting("display",.string(text)).setting("leadKind",.string(lead)).setting("concept",.string(concept))
    }
    func prepareCompanionQuest(now:Date = Date()) async {
        guard signedIn,learner.onboardingComplete,let policy=companionQuestPolicy else{return}
        let account=identity.npub,target=learner.target,support=learner.support,day=CalendarDay.key(now)
        #if DEBUG
        let offline=ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1"
        if offline {for key in [day,CalendarDay.shift(day,by:1)] where learner.companionQuestDays?[CompanionQuestDay.key(target,key)] == nil {learner.importQuestDay(.object([:]),target:target,day:key)}}
        #else
        let offline=false
        #endif
        guard offline || (learner.companionQuestDays?[CompanionQuestDay.key(target,day)] != nil && learner.companionQuestDays?[CompanionQuestDay.key(target,CalendarDay.shift(day,by:1))] != nil) else{return}
        let courses=learner.plateCourses(user:account,now:now),cleared = !courses.isEmpty && courses.allSatisfy(\.done)
        if !learner.introductoryQuest(day:day),!cleared,learner.questDay(day:day)["explanation"] == .null {
            let bubble=companionBubble(now:now),concept=bubble["concept"].string
            let summary=(try? policy.run("summary",.object(["lang":.string(support),"concept":.string(concept)]))).map{concept.isEmpty ? "":$0.string} ?? ""
            learner.storeQuestExplanation(.object(["questDayKey":.string(day),"targetLang":.string(target),"questKinds":.array(courses.map{.string($0.kind)}),"repairMemoryIds":learner.repairPlan(day:day)?["memoryIds"] ?? .array([]),"shortBubbleText":bubble["short"],"explanation":bubble["long"],"companionMood":.string(bubble["leadKind"].string == "fresh" ? "neutral":"focused"),"sourceMemorySummary":.string(summary),"createdAt":.number(now.timeIntervalSince1970*1000)]),target:target,day:day,now:now)
            persist()
        }
        guard cleared || !learner.introductoryQuest(day:day) else{return}
        let consumptionDay=cleared ? CalendarDay.shift(day,by:1):day
        let input:JSONValue = .object(["user":learner.companionQuestUser,"targetLang":.string(target),"dayKey":.string(consumptionDay),"now":.number(now.timeIntervalSince1970*1000)])
        guard (try? policy.run("stored",input))?["shouldRun"].boolean == true else{return}
        let notes=(try? policy.run(cleared ? "captured":"reusable",input))?.array ?? []
        guard !notes.isEmpty || GoalPractice.active(learner.goalBucket) != nil else{return}
        let scope=companionQuestPreparationKey,id=UUID().uuidString
        do {
            if !offline {
                let document=try await FirebaseService.shared.reserveCompanionQuest(npub:account,target:target,day:consumptionDay,id:id,now:now)
                try Task.checkCancellation();guard identity.npub == account,companionQuestPreparationKey == scope else{return}
                learner.importQuestDay(document,target:target,day:consumptionDay)
                guard document["blueprint"]["iosGenerationID"].string == id else{persist();return}
            }
            let args=input.setting("user",learner.companionQuestUser).setting("notes",.array(notes)).setting("appLanguage",.string(support)).setting("todayCleared",.bool(cleared || learner.questPlans?[target]?.yesterdayComplete != false)).setting("carryOverKinds",.array(cleared ? []:(learner.questPlans?[target]?.carry ?? []).map{.string($0)})).setting("cefrLevel",.string(learner.level))
            let prepared=try policy.run("prepare",args)
            var blueprint=prepared["fallback"]
            if !offline {
                do {
                    let raw=try await ai.responsesText(prepared["prompt"].string)
                    try Task.checkCancellation()
                    blueprint=try policy.run("assemble",args.setting("ranked",prepared["ranked"]).setting("fallback",blueprint).setting("raw",.string(raw)))
                }catch is CancellationError{throw CancellationError()}catch{} // Source fallback is deterministic when the provider cannot compose.
            }
            try Task.checkCancellation();guard identity.npub == account,companionQuestPreparationKey == scope else{return}
            learner.storeCompanionBlueprint(blueprint.setting("iosGenerationID",.string(id)),target:target,day:consumptionDay,now:now);persist()
        }catch is CancellationError{}catch{} // Hydration/network failures retry on the next foreground/sync; never publish an empty plan.
    }
}

extension AppModel {
    var currentRepairStep:RepairStep? {
        let day=CalendarDay.key(Date());guard let plan=learner.repairPlan(day:day),let policy=companionQuestPolicy,let value=try? policy.run("next",.object(["plan":plan,"completedCount":.number(Double(learner.plateCourses(user:identity.npub).first(where:{$0.kind == "repair"})?.count ?? 0))])),let step=try? JSONDecoder().decode(RepairStep.self,from:Data(value.json.utf8)),learner.repairStepIsCurrent(step) else{return nil};return step
    }
    func repairLesson(_ step:RepairStep)->Lesson? {
        guard learner.repairStepIsCurrent(step),let policy=companionQuestPolicy,let value=try? policy.run("lesson",.object(["user":learner.companionQuestUser,"plan":step.plan,"targetLang":.string(step.target),"cefrLevel":.string(learner.level),"dayKey":.string(step.day),"recommendedMode":.string(step.mode),"stepIndex":.number(Double(step.index))])) else{return nil}
        return try? JSONDecoder().decode(Lesson.self,from:Data(value.setting("agenda",.object([:])).json.utf8))
    }
    func authoredRepairPhonics(_ step:RepairStep)->[PhonicsCard] {
        let decks=phonicsLibrary.filter{$0.key.hasPrefix(learner.target+":"+learner.support+":")}
        guard let data=try? JSONEncoder().encode(decks),let snapshot=try? JSONDecoder().decode(JSONValue.self,from:data),let cards=try? companionQuestPolicy?.run("phonics",.object(["decks":snapshot,"focus":.object(["targetLang":.string(learner.target),"supportLang":.string(learner.support),"plan":step.plan])])) else{return []}
        return (try? JSONDecoder().decode([PhonicsCard].self,from:Data(cards.json.utf8))) ?? []
    }
    func repairPhonics(_ step:RepairStep)->[PhonicsCard] {
        let cards=learner.repairArtifact(step,mode:"phonics")["cards"].array
        let authored=LearningLanguages.levels.flatMap{phonicsLibrary[learner.target+":"+learner.support+":"+$0] ?? []}
        return cards.compactMap{saved in
            guard let source=authored.first(where:{$0.id == saved["authoredId"].string}),let data=try? JSONEncoder().encode(source),let value=try? JSONDecoder().decode(JSONValue.self,from:data) else{return nil}
            return try? JSONDecoder().decode(PhonicsCard.self,from:Data(value.setting("id",saved["id"]).setting("authoredId",saved["authoredId"]).setting("practiceRole",saved["practiceRole"]).json.utf8))
        }
    }
    func prepareRepairPhonics(_ step:RepairStep) async throws {
        guard learner.repairStepIsCurrent(step),learner.repairArtifact(step,mode:"phonics")["cards"].array.isEmpty else{return}
        let selected=authoredRepairPhonics(step),account=identity.npub,support=learner.support
        let cards=try selected.enumerated().map{index,card -> JSONValue in
            let value=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(card))
            return value.setting("authoredId",.string(card.id)).setting("id",.string("focused-"+CompanionQuestDay.artifactKey(step,mode:"phonics")+"-\(index)")).setting("practiceRole",.string(index == 0 ? "original":index == 2 ? "transfer":"contrast")).setting("isRepair",.bool(true))
        }
        guard !cards.isEmpty else{return}
        var artifact:JSONValue = .object(["version":.number(1),"ownerKey":.string(CompanionQuestDay.artifactKey(step,mode:"phonics")),"cards":.array(cards),"outcomes":.object([:])])
        #if DEBUG
        let offline=ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1"
        #else
        let offline=false
        #endif
        if !offline {artifact=try await FirebaseService.shared.reserveRepairArtifact(npub:account,step:step,mode:"phonics",candidate:artifact)}
        try Task.checkCancellation();guard identity.npub == account,learner.support == support,learner.repairStepIsCurrent(step) else{return}
        learner.storeRepairArtifact(artifact,step:step,mode:"phonics");persist()
    }
    func recordRepairOutcome(_ step:RepairStep,mode:String,cardID:String,success:Bool,item:String,deferCompletion:Bool = false) {
        guard learner.recordRepairOutcome(step,mode:mode,cardID:cardID,success:success,item:item,support:mode == "phonics" ? "modeled":"prompted") else{return}
        persist();if !deferCompletion {checkRepairPracticeCompletion(step,mode:mode)}
    }
    func checkRepairPracticeCompletion(_ step:RepairStep,mode:String) {
        let artifact=learner.repairArtifact(step,mode:mode),cards=artifact["cards"].array
        let required=mode == "phonics" ? cards.filter{["original","transfer"].contains($0["practiceRole"].string)}:cards
        guard !required.isEmpty,required.allSatisfy({artifact["outcomes"][$0["id"].string]["success"].boolean}) else{return}
        let observation=required.map{artifact["outcomes"][$0["id"].string]["item"].string}.joined(separator:"; ")
        finishRepair(step,observation:mode == "phonics" ? observation+" pronounced successfully after a model":"Correct recall of "+observation+"; recall only, not independent production.",support:mode == "phonics" ? "modeled":"prompted")
    }
    func finishRepair(_ step:RepairStep,observation:String,support:String = "prompted") {
        guard learner.repairStepIsCurrent(step),let policy=companionQuestPolicy else{return}
        let now=Date(),event=step.event.setting("success",.bool(true)).setting("support",.string(support)).setting("observation",.string(observation))
        guard let summary=try? policy.run("evidence",.object(["summary":learner.goalBucket["repairSummary"],"event":event,"now":.number(now.timeIntervalSince1970*1000)])) else{return}
        if learner.completeRepairStep(step,summary:summary,observation:observation,support:support,now:now){persist()}
    }
    func completeSourceTutorRepair(_ step:RepairStep,bonus:Int,evidence:JSONValue)->Bool {
        guard learner.repairStepIsCurrent(step),let policy=companionQuestPolicy else{return false}
        let event=step.event.setting("success",.bool(evidence["success"].boolean)).setting("support",.string("prompted")).setting("observation",evidence["observation"] == .null ? .string(""):evidence["observation"]),now=Date()
        guard let summary=try? policy.run("evidence",.object(["summary":learner.goalBucket["repairSummary"],"event":event,"now":.number(now.timeIntervalSince1970*1000)])) else{return false}
        guard learner.completeRepairStep(step,summary:summary,observation:event["observation"].string,support:"prompted",success:evidence["success"].boolean,bonusXP:bonus,now:now) else{return false}
        persist();return true
    }
    func prepareRepairDeck(_ step:RepairStep) async throws {
        guard learner.repairStepIsCurrent(step),learner.repairArtifact(step,mode:"flashcards")["cards"].array.isEmpty,let policy=companionQuestPolicy else{return}
        let account=identity.npub,support=learner.support,scope=learner,performance=try policy.run("performance",.object(["user":learner.companionQuestUser,"targetLang":.string(step.target)])),level=performance["suggestedQuestionLevel"].string
        let parameters:JSONValue = .object(["supportBase":.string(support),"targetBase":.string(step.target),"langKey":.string(step.target),"dayKey":.string(step.day),"stepIndex":.number(Double(step.index)),"level":.string(level)])
        let floor=try policy.run("deckCard",parameters.setting("support",step.item["concept"]).setting("target",step.item["originalAnswer"].string.isEmpty ? step.item["expectedAnswer"].string.isEmpty ? step.item["concept"]:step.item["expectedAnswer"]:step.item["originalAnswer"]).setting("cardIndex",.number(0)))
        var values=floor == .null ? []:[floor]
        #if DEBUG
        let offline=ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1"
        #else
        let offline=false
        #endif
        if !offline {
            do {
                let prompt=try policy.run("deckPrompt",.object(["item":step.item,"targetLang":.string(step.target),"supportLang":.string(support),"level":.string(level),"count":.number(3)])).string
                let raw=try await ai.responsesText(prompt),entries=try policy.run("deckEntries",.object(["raw":.string(raw)])).array
                for (index,entry) in entries.dropFirst().prefix(2).enumerated(){let card=try policy.run("deckCard",parameters.setting("support",entry["support"]).setting("target",entry["target"]).setting("cardIndex",.number(Double(index+1))));if card != .null{values.append(card)}}
            }catch is CancellationError{throw CancellationError()}catch{} // The source always supplies the original weak item's floor card.
        }
        try Task.checkCancellation();guard identity.npub == account,learner.support == scope.support,learner.repairStepIsCurrent(step) else{return}
        var artifact:JSONValue = .object(["version":.number(1),"ownerKey":.string(CompanionQuestDay.artifactKey(step,mode:"flashcards")),"cards":.array(values),"outcomes":.object([:])])
        if !offline {artifact=try await FirebaseService.shared.reserveRepairArtifact(npub:account,step:step,mode:"flashcards",candidate:artifact)}
        try Task.checkCancellation();guard identity.npub == account,learner.support == support,learner.repairStepIsCurrent(step) else{return}
        learner.storeRepairArtifact(artifact,step:step,mode:"flashcards");persist()
    }
    func checkRepair(_ step:RepairStep,response:String,context:String) async throws -> GoalVerdict {
        guard learner.repairStepIsCurrent(step),subscription.hasAccess else{throw AppError.message("Return to today's current repair task.")}
        let account=identity.npub,support=learner.support
        let prompt="REPAIR WATCH: The Daily Quest routed a repair for this material from a previous day (data): \(step.item.json). Set success true only if THIS attempt correctly produces or uses this phrase or concept, even approximately in the learner's own words. Exposure, echoing feedback, unrelated replies and asking for the answer are not success. Explain feedback in \(support). Return strict JSON {\"success\":true|false,\"support\":\"prompted\",\"feedback\":\"short kind feedback\",\"observation\":\"what the learner demonstrated\"}. Context data: \(JSONValue.string(String(context.suffix(6000))).json). Latest learner attempt data: \(JSONValue.string(String(response.prefix(1000))).json)."
        let verdict=try await ai.structured(GoalVerdict.self,prompt:prompt)
        try Task.checkCancellation();guard identity.npub == account,learner.support == support,learner.repairStepIsCurrent(step) else{throw CancellationError()}
        if verdict.success {finishRepair(step,observation:verdict.observation.isEmpty ? response:verdict.observation)}
        return verdict
    }
    func repairInstructions(_ step:RepairStep)->String {
        "REPAIR SESSION: The companion saved this \(LearningLanguages.names[step.target] ?? step.target) material for focused practice (data): \(step.item.json). Treat this as fresh practice in \(LearningLanguages.names[learner.support] ?? learner.support) framing — never say they got it wrong before or present it as a test. Model one phrase, ask the learner to repeat or produce it, then use it in one tiny realistic exchange. Stay on this material only; vary how it is practiced. Use CEFR \(step.item["cefrLevel"].string) scaffolding. Keep turns brief. The app owns completion; do not claim it from time or exposure."
    }
}
