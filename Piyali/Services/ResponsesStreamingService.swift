import Foundation
import FirebaseAuth

extension AIService {
    func responsesStream(_ prompt:String,onChunk:@escaping @MainActor(String)->Void) async throws->String {
        var request=URLRequest(url:configuration.worker.appendingPathComponent("proxyResponses"))
        request.httpMethod="POST";request.timeoutInterval=45
        request.setValue("application/json",forHTTPHeaderField:"Content-Type")
        request.setValue("text/event-stream",forHTTPHeaderField:"Accept")
        for (key,value) in try await FirebaseService.shared.appCheckHeaders(){request.setValue(value,forHTTPHeaderField:key)}
        guard let user=Auth.auth().currentUser else{throw AppError.message("Sync your account before using the tutor.")}
        request.setValue("Bearer "+(try await user.getIDToken()),forHTTPHeaderField:"Authorization")
        request.httpBody=try JSONSerialization.data(withJSONObject:["model":configuration.string("ResponsesModel"),"input":prompt,"stream":true,"text":["format":["type":"text"]]])
        let (bytes,response)=try await URLSession.shared.bytes(for:request)
        defer{bytes.task.cancel()}
        guard let http=response as? HTTPURLResponse else{throw ResponsesOutput.Failure.incomplete}
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 429{throw AppError.message("The tutor is busy. Try again shortly.")}
            if [401,403].contains(http.statusCode){throw AppError.message("Your online session expired. Sync your account, then try again.")}
            throw ResponsesOutput.Failure.incomplete
        }
        guard http.mimeType == "text/event-stream" else{throw ResponsesOutput.Failure.incomplete}
        var stream=ResponsesStream()
        for try await byte in bytes {
            try Task.checkCancellation()
            if let text=try stream.receive(byte:byte){onChunk(text)}
            if stream.completed{break}
        }
        try Task.checkCancellation()
        return try stream.finish()
    }
}
