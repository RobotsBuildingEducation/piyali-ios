import Foundation

public enum OralQuestionRules {
    public static func normalize(_ payload:JSONValue,module:PracticeRecipeModule)->JSONValue {
        let target=payload["target"].string.trimmingCharacters(in:.whitespacesAndNewlines)
        var result=payload.setting("target",.string(target)).setting("display",.string(target.isEmpty && module == .vocabulary ? payload["display"].string.trimmingCharacters(in:.whitespacesAndNewlines):target))
        if module == .vocabulary{let variant=payload["variant"].string.lowercased();result=result.setting("variant",.string(["repeat","translate","complete"].contains(variant) ? variant:"repeat"))}
        return result
    }
}
