import Foundation
import FirebaseCore
import FirebaseAuth
import NostrSDK

@MainActor protocol GeminiTutorSocket:AnyObject {
    func send(_ message:JSONValue)async throws
    func receive()async throws->JSONValue
    func close()
}

/// Firebase's Live websocket protocol, matching the pinned FirebaseAI SDK route
/// and headers. This small boundary retains input language hints, which the
/// Swift SDK's empty AudioTranscriptionConfig cannot currently encode.
@MainActor final class FirebaseGeminiTutorSocket:GeminiTutorSocket {
    private let task:URLSessionWebSocketTask,session:URLSession
    private var closed=false
    init(request:URLRequest) {
        let config=URLSessionConfiguration.ephemeral;config.httpCookieStorage=nil;config.urlCache=nil
        session=URLSession(configuration:config);task=session.webSocketTask(with:request);task.maximumMessageSize=4*1024*1024;task.resume()
    }
    static func connect(_ config:JSONValue,configuration:AppConfiguration=AppConfiguration())async throws->GeminiTutorSocket {
        guard FirebaseService.shared.configured,let app=FirebaseApp.app(),let project=app.options.projectID,
              project == "piyali-ios",let user=Auth.auth().currentUser else {throw AppError.message("Sync your account before starting Tutor.")}
        let uid=user.uid,token=try await user.getIDTokenResult(),hex=token.claims["nostr_pubkey"] as? String ?? ""
        guard uid == config["owner"].string,PublicKey(hex:hex)?.npub == uid,(token.claims["firebase"] as? [String:Any])?["sign_in_provider"] as? String == "custom",token.claims["piyali_public_demo"] as? Bool != true else{throw AppError.message("Sync your Nostr account before starting Tutor.")}
        let headers=try await FirebaseService.shared.appCheckHeaders()
        try Task.checkCancellation();guard Auth.auth().currentUser === user else{throw CancellationError()}
        let vertex=configuration.string("GeminiAPIProvider",default:"googleAI") != "googleAI",location=configuration.string("GeminiLiveLocation",default:"us-central1")
        guard location.range(of:"^[a-z]+-[a-z]+[0-9]+$",options:.regularExpression) != nil else{throw AppError.message("Tutor's voice region is invalid.")}
        let route=vertex ? "LlmBidiService/BidiGenerateContent/locations/"+location:"GenerativeService/BidiGenerateContent"
        var request=URLRequest(url:URL(string:"wss://firebasevertexai.googleapis.com/ws/google.firebase.vertexai.v1beta."+route)!);request.timeoutInterval=25
        request.setValue("application/json",forHTTPHeaderField:"Content-Type");request.setValue(app.options.apiKey,forHTTPHeaderField:"x-goog-api-key")
        request.setValue(Bundle.main.bundleIdentifier,forHTTPHeaderField:"x-ios-bundle-identifier");request.setValue("gl-swift/5 fire/12.19.2",forHTTPHeaderField:"x-goog-api-client")
        request.setValue("Firebase "+token.token,forHTTPHeaderField:"Authorization")
        for (name,value) in headers{request.setValue(value,forHTTPHeaderField:name)}
        if app.isDataCollectionDefaultEnabled{request.setValue(app.options.googleAppID,forHTTPHeaderField:"X-Firebase-AppId");request.setValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,forHTTPHeaderField:"X-Firebase-AppVersion")}
        let socket=FirebaseGeminiTutorSocket(request:request)
        let deadline=Task{try? await Task.sleep(for:.seconds(20));if !Task.isCancelled{socket.close()}}
        defer{deadline.cancel()}
        do {
            let model=vertex ? "gemini-live-2.5-flash-native-audio":"gemini-3.1-flash-live-preview"
            let resource=vertex ? "projects/\(project)/locations/\(location)/publishers/google/models/\(model)":"projects/\(project)/models/\(model)"
            try await socket.send(GeminiTutorWire.setup(config,modelResource:resource))
            let response=try await withTaskCancellationHandler{try await socket.receive()}onCancel:{Task{@MainActor in socket.close()}}
            guard response["setupComplete"] != .null else{throw AppError.message("Tutor's voice connection could not start.")}
            try Task.checkCancellation();guard Auth.auth().currentUser === user else{throw CancellationError()}
            return socket
        } catch{socket.close();throw error}
    }
    func send(_ message:JSONValue)async throws {
        guard !closed else{throw CancellationError()};try await task.send(.data(JSONEncoder().encode(message)))
    }
    func receive()async throws->JSONValue {
        guard !closed else{throw CancellationError()};let value=try await task.receive(),bytes:Data
        switch value{case .data(let data):bytes=data;case .string(let string):bytes=Data(string.utf8);@unknown default:throw AppError.message("Tutor sent an invalid voice message.")}
        guard bytes.count<=4*1024*1024 else{throw AppError.message("Tutor's voice message was too large.")}
        return try JSONDecoder().decode(JSONValue.self,from:bytes)
    }
    func close(){guard !closed else{return};closed=true;task.cancel(with:.goingAway,reason:nil);session.invalidateAndCancel()}
}
