import Foundation

/// Public entry rules from LandingPage; the fixed header intentionally permits
/// a nameless registration while the hero/footer require a display name.
public enum EntryPolicy {
    public struct Header:Equatable,Sendable {public let scrolled:Bool,actions:Bool}
    public static func header(scrollY:Double,heroBottom:Double?)->Header {.init(scrolled:scrollY>0,actions:heroBottom.map{$0<=96} ?? false)}
    public static func registrationName(_ input:String,instant:Bool=false,busy:Bool=false)->String? {
        guard !busy else{return nil};if instant{return ""}
        let name=input.trimmingCharacters(in:.whitespacesAndNewlines)
        guard name.utf16.count>=2,!name.lowercased().hasPrefix("nsec1") else{return nil};return name
    }
    public static func signInError(_ message:String)->String {
        let text=message.lowercased()
        if text.contains("extension"){return "signin_error_extension"}
        if ["invalid","secret","key","nsec","bech32"].contains(where:text.contains){return "signin_error_invalid_key"}
        return "signin_error_generic"
    }
}
