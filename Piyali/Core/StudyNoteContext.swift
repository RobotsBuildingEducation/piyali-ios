import Foundation

public extension PracticeRun {
    /// The source note handlers use study context, which is distinct from the
    /// displayed prompt and from the assessor's response serialization.
    var studyNoteContext:JSONValue {
        let q=question,p=q.payload,r=response
        let concept:String,userAnswer:String
        func first(_ values:String...)->String {values.first{!$0.isEmpty} ?? ""}
        if q.isDelight {
            switch q.variant {
            case "three_clue_mystery":concept=first(p["answer"].string,"Mystery Word")+(p["example"].string.isEmpty ? "":" — "+p["example"].string)
            case "morphology_forge":concept=first(p["answerWord"].string,"Word")+": "+q.strings("answerPieces").joined(separator:" + ")
            case "word_neighborhoods":concept=p["groups"].array.map{$0["label"].string+": "+$0["items"].array.map(\.string).joined(separator:", ")}.joined(separator:" | ")
            case "sentence_shapeshifter":concept=first(p["source"].string,"Sentence")+" → "+first(p["constraint"].string,"Rule")
            default:concept=first(p["correctedSentence"].string,p["sentence"].string,p["speaker"].string.isEmpty || p["line"].string.isEmpty ? "":p["speaker"].string+": "+p["line"].string,p["source"].string,p["answer"].string,"Exercise")
            }
            switch q.variant {
            case "three_clue_mystery","sentence_shapeshifter":userAnswer=r["text"].string
            case "morphology_forge":userAnswer=r["pieceIndices"].array.compactMap{let i=Int($0.number);return q.strings("pieces").indices.contains(i) ? q.strings("pieces")[i]:nil}.joined()
            case "word_neighborhoods":
                let ordered=studyOrderedAssignmentKeys
                userAnswer=p["groups"].array.enumerated().map{index,group in group["label"].string+": "+ordered.filter{r["assignments"][$0] == .number(Double(index))}.joined(separator:", ")}.joined(separator:" | ")
            case "dialogue_fork":let value=r["selectedIndex"];let i=Int(value.number);userAnswer=value != .null && q.strings("options").indices.contains(i) ? q.strings("options")[i]:""
            default:userAnswer=first(r["replacement"].string,r["text"].string)
            }
        } else {
            switch q.kind {
            case "match":concept=first(p["stem"].string,"Match the items:")
            case "speak":concept=first(p["prompt"].string,p["stimulus"].string,p["target"].string)
            case "translate","repeat":concept=p["sentence"].string
            default:concept=first(p["question"].string,p["answer"].string,p["hint"].string,q.module == .grammar ? "Grammar practice":"Vocabulary practice")
            }
            if q.kind == "ma" {userAnswer=r["indices"].array.compactMap{let i=Int($0.number);return bank.indices.contains(i) ? bank[i]:nil}.joined(separator:", ")}
            else if q.kind == "match" {userAnswer=q.strings("left").enumerated().map{i,left in let value=r["pairs"][String(i)],index=Int(value.number);return left+" → "+(value != .null && q.strings("right").indices.contains(index) ? q.strings("right")[index]:"undefined")}.joined(separator:", ")}
            else{userAnswer=answerText}
        }
        return .object(["concept":.string(concept),"userAnswer":.string(userAnswer),"wasCorrect":correct.map(JSONValue.bool) ?? .null,"target":.string(q.target),"language":.string(q.support),"cefrLevel":.string(q.level),"moduleType":.string(q.module.rawValue)])
    }
    static func studyLessonTitle(_ module:PracticeRecipeModule,delight:Bool=false)->JSONValue {
        module == .grammar ? .object(delight ? ["en":.string("Grammar"),"es":.string("Gramática")]:["en":.string("Grammar"),"es":.string("Gramática"),"it":.string("Grammatica"),"fr":.string("Grammaire")]):.object(["en":.string("Vocabulary"),"es":.string("Vocabulario")])
    }
    mutating func recordStudyAssignmentOrder(next:JSONValue) {
        guard question.variant == "word_neighborhoods" else{return}
        let old=response["assignments"].object,new=next["assignments"].object
        var order=(studyAssignmentOrder ?? old.keys.sorted()).filter{new[$0] != nil}
        order += new.keys.filter{!order.contains($0)}.sorted();studyAssignmentOrder=order
    }
}
