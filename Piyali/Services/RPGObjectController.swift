import Foundation

/// Ephemeral ambient observations, independent of lesson points and saved game turns.
@MainActor final class RPGObjectController:ObservableObject {
    struct Observation:Equatable {
        let id:UUID,key:String
        var fields:JSONValue
        var pending:Bool
    }
    @Published private(set) var observation:Observation?
    private let policy:RPGObjectPolicy?
    private let displayMilliseconds:Int
    private var scope="",parameters:JSONValue = .null,cache:[String:JSONValue]=[:],objects:[RPGObject]=[]
    private var epoch=UUID(),loading:Task<Void,Never>?,expiry:Task<Void,Never>?
    init(policy:RPGObjectPolicy?=try? RPGObjectPolicy(),displayMilliseconds:Int=3600){self.policy=policy;self.displayMilliseconds=displayMilliseconds}
    func configure(scope:String,parameters:JSONValue,objects:[RPGObject],generate:@escaping(String)async throws->String) {
        guard self.scope != scope else{return};cancel();self.scope=scope;self.parameters=parameters;self.objects=objects
        guard !objects.isEmpty,let policy else{return};let token=epoch
        loading=Task { [weak self] in
            guard let self,self.epoch == token,!Task.isCancelled else{return}
            let response:String
            do {response=try await generate(policy.run("prompt",parameters).string)}catch{response=""}
            guard self.epoch == token,!Task.isCancelled else{return}
            let normalized=(try? policy.run("resolve",parameters.setting("response",.string(response)))).map(\.object) ?? [:]
            cache=normalized;loading=nil
            if var current=observation{current.fields=cache[current.key] ?? current.fields;current.pending=false;observation=current;expire(current.id)}
        }
    }
    func examine(_ object:RPGObject) {
        guard objects.contains(object),let policy else{return}
        let p=parameters.setting("object",value(object)),key=(try? policy.run("key",p).string) ?? ""
        guard !key.isEmpty else{return};expiry?.cancel()
        let fields=cache[key] ?? (try? policy.run("fallback",p)) ?? .null
        let current=Observation(id:UUID(),key:key,fields:fields,pending:cache[key] == nil && loading != nil)
        observation=current;if !current.pending{expire(current.id)}
    }
    func hit(_ point:RPGPoint)->RPGObject?{objects.first{$0.tx == point.x && $0.ty == point.y}}
    private func expire(_ id:UUID){expiry?.cancel();expiry=Task{try? await Task.sleep(for:.milliseconds(displayMilliseconds));guard !Task.isCancelled,observation?.id == id else{return};observation=nil}}
    func cancel(){epoch=UUID();loading?.cancel();loading=nil;expiry?.cancel();expiry=nil;observation=nil;cache=[:];objects=[];parameters = .null;scope=""}
    private func value(_ object:RPGObject)->JSONValue{(try? JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(object))) ?? .null}
}

extension LearnerState {
    /// Only fields consumed by the source performance context; no identity or credentials.
    var rpgObjectUser:JSONValue {
        let prefix=target+":"
        let lessons=Dictionary(uniqueKeysWithValues:completed.filter{$0.hasPrefix(prefix) && !$0.hasPrefix(prefix+"tutor:")}.map{(String($0.dropFirst(prefix.count)),JSONValue.object(["status":.string("completed")]))})
        let cards=Dictionary(uniqueKeysWithValues:(cardReviews ?? [:]).filter{$0.key.hasPrefix(prefix) && $0.value.completed}.map{(String($0.key.dropFirst(prefix.count)),JSONValue.object(["completed":.bool(true)]))})
        var summary=courseSummaries?[target] ?? .object([:])
        for(mode,levels)in courseCompletion?[target] ?? [:]{for(level,count)in levels{let key=level.lowercased().replacingOccurrences(of:"-",with:"_");if summary[mode]["levels"][key]["completed"] == .null{summary=summary.setting(mode,summary[mode].setting("levels",summary[mode]["levels"].setting(key,.object(["completed":.number(Double(count))]))))}}}
        let progress=recipeUser["progress"].setting("level",.string(level)).setting("tutorUnlockedLevels",.object((tutorUnlockedLevels ?? [:]).mapValues(JSONValue.string))).setting("languageLessons",.object([target:.object(lessons)])).setting("languageFlashcards",.object([target:.object(cards)])).setting("courseSummary",summary)
        return recipeUser.setting("progress",progress).setting("proficiencyPlacements",.object((placements ?? [:]).mapValues{.string($0.level)}))
    }
}
