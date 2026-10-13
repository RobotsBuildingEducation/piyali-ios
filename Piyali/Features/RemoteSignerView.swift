import SwiftUI

struct RemoteSignerView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var bunker=""
    @State private var busy=false
    @State private var established=false
    @State private var pending:Task<Void,Never>?
    var body:some View {
        Form {
            Text("Paste the bunker connection URL supplied by your Nostr signer. Approve the connection in that signer when prompted.")
            SecureField("bunker:// connection URL",text:$bunker).textInputAutocapitalization(.never).autocorrectionDisabled().privacySensitive().accessibilityIdentifier("bunkerURL")
            Button("Connect") {
                busy=true;established=false;app.error=nil
                pending=Task {
                    let success=await app.signInRemote(bunker,onConnected:{ established=true })
                    bunker="";busy=false;pending=nil
                    if success { dismiss() }
                }
            }.disabled(bunker.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || busy).accessibilityIdentifier("bunkerConnect")
            if busy { ProgressView("Waiting for your signer…");Button("Cancel") { pending?.cancel();app.identity.cancelSigning() } }
            if let error=app.error { Text(error).foregroundStyle(.red) }
            Text("This iPhone stores a separate connection key in Keychain. Your main private key remains in your signer; no private-key backup is available from Piyali for this account.").font(.footnote)
        }.navigationTitle("Remote signer").onDisappear { if !established { pending?.cancel() } }
    }
}
struct SignerAuthorizationPresenter:View {
    @ObservedObject var identity:IdentityService
    var body:some View {
        Color.clear.frame(width:0,height:0).sheet(item:$identity.authorization) { request in
            NavigationStack {
                Form {
                    Text("Your remote signer needs authorization before it can complete this request.")
                    Text(request.url.host ?? "Signer")
                    Link("Open signer authorization",destination:request.url)
                    Text("Return to Piyali after approving it. The pending request will continue automatically.")
                    Button("Cancel signing request") { identity.cancelSigning() }
                }.navigationTitle("Signer authorization")
            }
        }
    }
}
