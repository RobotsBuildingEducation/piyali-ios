import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck

/// A separate Firebase instance keeps public practice out of the learner's account.
/// The backend issues only the fixed demo identity, which has no Nostr permissions.
@MainActor enum LandingDemoIdentity {
    private static let appName="PiyaliPublicDemo"
    static func app() throws -> FirebaseApp {
        if let app=FirebaseApp.app(name:appName) { return app }
        guard let main=FirebaseApp.app() else { throw AppError.message("Live practice is unavailable.") }
        FirebaseApp.configure(name:appName,options:main.options)
        guard let app=FirebaseApp.app(name:appName) else { throw AppError.message("Live practice is unavailable.") }
        return app
    }
    static func connect() async throws -> FirebaseApp {
        let app=try app(),auth=Auth.auth(app:app)
        let config=AppConfiguration(),base=config.auth
        guard base.scheme == "https",base.user == nil,base.password == nil else { throw AppError.message("Live practice is unavailable.") }
        guard let appCheck=AppCheck.appCheck(app:app) else { throw AppError.message("Live practice is unavailable.") }
        let check=try await appCheck.token(forcingRefresh:false)
        var request=URLRequest(url:base.appendingPathComponent("auth/landing-demo"));request.httpMethod="POST";request.timeoutInterval=20
        request.setValue("application/json",forHTTPHeaderField:"Content-Type");request.setValue(check.token,forHTTPHeaderField:"X-Firebase-AppCheck");request.httpBody=Data("{}".utf8)
        let (bytes,response)=try await URLSession.shared.data(for:request)
        guard let response=response as? HTTPURLResponse,response.statusCode == 200 else { throw AppError.message("Live practice is unavailable.") }
        struct Result:Decodable { let uid:String;let token:String }
        let result=try JSONDecoder().decode(Result.self,from:bytes)
        guard result.uid == "piyali-landing-demo" else { throw AppError.message("Live practice is unavailable.") }
        let user=try await auth.signIn(withCustomToken:result.token).user
        guard user.uid == result.uid else { try? auth.signOut();throw AppError.message("Live practice is unavailable.") }
        return app
    }
    static func disconnect() { if let app=FirebaseApp.app(name:appName) { try? Auth.auth(app:app).signOut() } }
}
