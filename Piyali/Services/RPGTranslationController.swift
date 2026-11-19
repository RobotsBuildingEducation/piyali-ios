import Foundation
import FirebaseAILogic

@MainActor struct RPGTranslationProvider {
    let stream:(String,@escaping @MainActor(String)->Void)async throws->Void
    static func native(_ ai:AIService)->Self{.init(stream:{try await ai.rpgTranslationStream($0,onChunk:$1)})}
}
@MainActor final class RPGTranslationController:ObservableObject {
    @Published private(set) var plan:RPGDialoguePolicy.Plan?
    @Published private(set) var presentation:RPGDialoguePolicy.Presentation?
    @Published private(set) var state:JSONValue = .null
    @Published private(set) var busy=false
    private let policy:RPGDialoguePolicy?
    private var key="",epoch=UUID(),work:Task<Void,Never>?,current:(()->Bool)?
    init(policy:RPGDialoguePolicy?=try? RPGDialoguePolicy()){self.policy=policy}
    var active:Bool{state != .null}
    var lines:[String]?{if case .array(let values)=state["lineTranslations"]{return values.map(\.string)};return nil}
    var choices:[String]?{if case .array(let values)=state["choiceTranslations"]{return values.map(\.string)};return nil}
    func configure(key:String,parameters:JSONValue,isCurrent:@escaping()->Bool){
        self.current=isCurrent;guard self.key != key else{return};reset();self.key=key;self.current=isCurrent
        guard let policy else{return};plan=try? policy.plan(parameters);presentation=try? policy.presentation(parameters)
    }
    func toggle(provider:RPGTranslationProvider){
        if active{clear();return};guard !busy,current?() == true,let policy,let plan,plan.count>0 else{return}
        let token=epoch;state=(try? policy.initial(plan)) ?? .null;guard active else{return};busy=true
        work=Task{[weak self] in
            guard let self else{return};defer{if epoch == token{busy=false;work=nil}}
            do{
                try await provider.stream(plan.prompt){[weak self] chunk in
                    guard let self,self.valid(token)else{return}
                    do{self.state=try policy.append(chunk,state:self.state,plan:plan)}catch{self.clear()}
                }
                guard valid(token)else{return};state=try policy.append("",state:state,plan:plan,final:true)
            }catch{if epoch == token{clear()}}
        }
    }
    private func valid(_ token:UUID)->Bool{guard epoch == token,!Task.isCancelled else{return false};guard current?() == true else{clear();return false};return true}
    func clear(){epoch=UUID();work?.cancel();work=nil;state = .null;busy=false}
    func reset(){clear();key="";current=nil;plan=nil;presentation=nil}
}

extension AIService {
    func rpgTranslationStream(_ prompt:String,onChunk:@escaping @MainActor(String)->Void)async throws{
        #if DEBUG
        if try await RPGTranslationFixture.stream(prompt,update:onChunk){return}
        #endif
        if FirebaseService.shared.configured{
            let model=FirebaseAI.firebaseAI(backend:configuration.geminiBackend()).generativeModel(modelName:configuration.string("GeminiModel"),generationConfig:GenerationConfig(maxOutputTokens:4096))
            for try await chunk in try model.generateContentStream(prompt){try Task.checkCancellation();let text=chunk.text ?? "";if !text.isEmpty{onChunk(text)}}
        }else{let text=try await responsesText(prompt);try Task.checkCancellation();onChunk(text)}
    }
}
