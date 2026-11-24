import Foundation

public extension PracticeRun {
    /// Original missed-answer capture inputs, distinct from study-note and grading inputs.
    /// Keep source omissions visible (several Delight formats still read legacy fields).
    var repairMemoryContext:JSONValue {
        let q=question,p=q.payload,r=response
        func first(_ values:String...)->String {values.first{!$0.isEmpty} ?? ""}
        func selected(_ values:[String],_ value:JSONValue)->String {guard value != .null else{return ""};let i=Int(value.number);return values.indices.contains(i) ? values[i]:""}
        let concept:String,answer:String,expected:String
        if q.isDelight {
            var itemConcept=""
            switch q.variant {
            case "sentence_detective":
                let word=selected(q.strings("tokens"),r["tokenIndex"])
                itemConcept=first(p["sentence"].string,p["wrongToken"].string,p["answer"].string)
                answer=word.isEmpty ? r["replacement"].string:word+" → "+r["replacement"].string
                expected=first(p["wrongToken"].string,selected(q.strings("tokens"),p["incorrectIndex"]))+" → "+p["answer"].string
            case "dialogue_fork":itemConcept=first(p["prompt"].string,p["targetRole"].string);answer=selected(q.strings("options"),r["selectedIndex"]);expected=selected(q.strings("options"),p["correctIndex"])
            case "sentence_shapeshifter":itemConcept=(p["source"].string+" ("+p["constraint"].string+")").trimmingCharacters(in:.whitespacesAndNewlines);answer=r["text"].string;expected=p["answer"].string
            case "word_neighborhoods":
                itemConcept=p["groups"].array.map{$0["label"].string+": "+$0["items"].array.map(\.string).joined(separator:", ")}.joined(separator:" | ")
                func json(_ value:JSONValue)->String {let encoder=JSONEncoder();encoder.outputFormatting=[.withoutEscapingSlashes];return String(data:(try? encoder.encode(value)) ?? Data(),encoding:.utf8) ?? "null"}
                answer="{"+studyOrderedAssignmentKeys.map{json(.string($0))+":"+json(r["assignments"][$0])}.joined(separator:",")+"}";expected=itemConcept
            case "morphology_forge":itemConcept=first(p["sentence"].string,p["root"].string,p["answer"].string);answer=r["assembled"].array.map(\.string).joined();expected=p["answer"].string
            case "three_clue_mystery":itemConcept=q.strings("clues").joined(separator:" • ");answer=r["guess"].string;expected=p["answer"].string
            case "listen_difference":
                itemConcept=first(p["sentence"].string,"Listening discrimination")
                let pairs=p["pairs"].array,i=Int(r["selectedIndex"].number)
                answer=r["selectedIndex"] != .null && pairs.indices.contains(i) ? pairs[i]["wordA"].string:""
                expected=first(pairs.first{$0["isCorrect"].boolean}?["wordA"].string ?? "",p["answer"].string)
            case "three_word_challenge":itemConcept=q.strings("cues").joined(separator:", ");answer=r["text"].string;expected=itemConcept
            case "natural_or_weird":itemConcept=p["sentence"].string;answer=r["choice"].boolean ? "Sounds natural":"Sounds weird";expected=p["isNatural"].boolean ? "Sounds natural":"Sounds weird"
            default:itemConcept=first(p["sentence"].string,p["prompt"].string,p["instruction"].string);answer=first(r["text"].string,r["replacement"].string,r["guess"].string);expected=p["answer"].string
            }
            concept=first(itemConcept,p["sentence"].string,p["prompt"].string,"Missed practice item")
        } else {
            let prompt:String
            switch q.kind {
            case "match":prompt=first(p["stem"].string,"Match the items:");expected=first(p["hint"].string,"Check the correct pairings")
            case "fill":prompt=p["question"].string;expected=p["hint"].string
            case "mc":prompt=p["question"].string;expected=first(p["answer"].string,p["hint"].string)
            case "ma":prompt=p["question"].string;expected=first(q.strings("answers").joined(separator:", "),p["hint"].string)
            case "speak":prompt=first(p["prompt"].string,p["stimulus"].string,p["target"].string);expected=p["target"].string
            case "translate","repeat":prompt=p["sentence"].string;expected=q.strings("correctWords").joined(separator:" ")
            case "flashcard":prompt=p["concept"].string;expected=p["answer"].string
            default:prompt=q.questionText;expected=self.expected
            }
            concept=first(prompt,expected)
            // These standard formats share the original snapshot serialization with Create note.
            answer=["ma","match"].contains(q.kind) ? studyNoteContext["userAnswer"].string:answerText
        }
        return .object(["concept":.string(concept),"userAnswer":.string(answer),"expectedAnswer":.string(expected),"sourceContext":.string(q.isDelight ? first(q.variant,q.module.rawValue,"delight_question"):q.module.rawValue),"cefrLevel":.string(q.level),"sourceMode":.string(q.module.rawValue)])
    }
    internal var studyOrderedAssignmentKeys:[String] {
        let assignments=response["assignments"].object
        let keys=(studyAssignmentOrder ?? assignments.keys.sorted()).filter{assignments[$0] != nil}
        let numeric=keys.compactMap{key->(String,UInt32)? in guard let value=UInt32(key),value<UInt32.max,String(value)==key else{return nil};return(key,value)}.sorted{$0.1<$1.1}.map(\.0)
        return numeric+keys.filter{!numeric.contains($0)}
    }
}
