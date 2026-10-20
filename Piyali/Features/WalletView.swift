import SwiftUI
import CoreImage.CIFilterBuiltins

struct WalletView:View {
    @EnvironmentObject var app:AppModel
    @StateObject private var service=WalletService()
    @State private var amount="10"
    @State private var recipient=""
    @FocusState private var editingAmount:Bool
    @FocusState private var editingRecipient:Bool
    var body:some View {
        Form {
            Section("Wallet") {
                Text("\(service.balance) sats available").accessibilityIdentifier("walletBalance")
                Text(service.status).accessibilityIdentifier("walletStatus")
                if service.busy { ProgressView("Checking wallet…") }
                Button("Refresh wallet") { perform { try await service.refresh(identity:app.identity) } }.disabled(service.busy)
                if service.canRestore {
                    Text("Browser wallet records were found. Restore them to keep existing proofs and receiving keys. If no key backup exists, restoration creates a new receiving key for future payments.")
                    Button("Restore browser wallet") { perform { try await service.restoreBrowserWallet(identity:app.identity) } }.disabled(service.busy).accessibilityIdentifier("walletRestoreBrowser")
                }
                if service.canCreate { Text("This wallet holds ecash issued by Minibits. Paying a deposit invoice adds sats to that mint balance.");Link("About Minibits",destination:URL(string:"https://minibits.cash/")!);Button("Create wallet") { perform { try await service.create(identity:app.identity) } }.disabled(service.busy).accessibilityIdentifier("walletCreate") }
            }
            if service.ready {
                Section("Add sats with Lightning") {
                    if service.depositID.isEmpty,!service.pending {
                        TextField("Deposit amount in sats",text:$amount).keyboardType(.numberPad).focused($editingAmount).accessibilityIdentifier("walletDepositAmount")
                        Button("Create deposit invoice") { perform { try await service.deposit(amount:Int(amount) ?? 0,identity:app.identity) } }.disabled(service.busy || !(Int(amount).map { (1...1_000_000).contains($0) } ?? false)).accessibilityIdentifier("walletDeposit")
                    }
                    if !service.invoice.isEmpty {
                        if let qr=invoiceQR(service.invoice) { Image(uiImage:qr).interpolation(.none).resizable().scaledToFit().frame(maxWidth:240).accessibilityLabel("Lightning deposit invoice QR code") }
                        Text(service.invoice).font(.caption).textSelection(.enabled).accessibilityIdentifier("walletInvoice")
                        ShareLink("Share invoice",item:service.invoice)
                        if let url=URL(string:"lightning:"+service.invoice) { Link("Open in Lightning wallet",destination:url) }
                    }
                    if service.invoiceExpired,!service.pending { Button("Archive unpaid expired invoice") { perform { try await service.archiveInvoice(identity:app.identity) } }.disabled(service.busy) }
                    if service.archivedCount > 0 { Button("Check archived invoices (\(service.archivedCount))") { perform { try await service.checkArchived(identity:app.identity) } }.disabled(service.busy) }
                    if !service.depositID.isEmpty,service.invoice.isEmpty { Text("A saved deposit quote was found. Check payment status to recover paid tokens.") }
                    if service.pending { Text("A wallet operation is saved on this device. Recover it before starting another payment.") }
                    if !service.depositID.isEmpty || service.pending { Button(service.pending ? "Recover saved wallet operation" : "Check payment status") { perform { try await service.checkDeposit(identity:app.identity) } }.disabled(service.busy).accessibilityIdentifier("walletCheckDeposit") }
                }
                Section("Nutzaps") {
                    if service.needsReceivingInfo {
                        Text("Publish this wallet's receiving information so other apps can send nutzaps to its existing key.")
                        Button("Publish receiving information") { perform { try await service.publishReceivingInformation(identity:app.identity) } }.disabled(service.busy || service.pending).accessibilityIdentifier("walletPublishReceiving")
                    }
                    Button("Receive nutzaps") { perform { try await service.receiveNutzaps(identity:app.identity) } }.disabled(service.busy || service.pending).accessibilityIdentifier("walletReceive")
                    TextField("Recipient npub",text:$recipient,axis:.vertical).textInputAutocapitalization(.never).autocorrectionDisabled().focused($editingRecipient).accessibilityIdentifier("walletRecipient")
                    Button("Use Piyali recipient") { recipient=WalletContract.defaultRecipient }.disabled(service.busy)
                    Button("Check recipient and fee") { perform { try await service.previewTip(to:recipient,identity:app.identity) } }.disabled(service.busy || service.pending || recipient.isEmpty).accessibilityIdentifier("walletPreviewTip")
                    if let preview=service.tipPreview,preview.recipient == recipient {
                        Button(preview.label) { perform { try await service.sendOneSat(to:recipient,maximumFee:preview.fee,identity:app.identity) } }.disabled(service.busy || service.pending).accessibilityIdentifier("walletSendTip")
                    }
                }
                Section("Automatic tips") {
                    if service.automatic.enabled {
                        Text("1 sat for each new XP-earning activity while the wallet is funded. Approved mint fee: up to \(service.automatic.maximumFee) sat per tip.")
                        Text(service.automatic.recipient).font(.caption)
                        Text("\(service.automatic.queue.count) queued activities")
                        Button("Stop automatic tips") { perform { try service.configureAutomaticTips(enabled:false,recipient:service.automatic.recipient,maximumFee:service.automatic.maximumFee,identity:app.identity) } }.accessibilityIdentifier("walletStopAutomatic")
                    } else {
                        Text("Automatic tips are off. Check a recipient and fee above to enable them.").accessibilityIdentifier("walletAutomaticOff")
                        if let reason=service.automatic.pauseReason { Text(reason) }
                        if let preview=service.tipPreview,preview.recipient == recipient {
                            Button("Enable 1 sat tips when earning XP") { perform { try service.configureAutomaticTips(enabled:true,recipient:recipient,maximumFee:preview.fee,identity:app.identity) } }.disabled(service.busy || service.pending).accessibilityIdentifier("walletEnableAutomatic")
                        }
                    }
                    Text("Stopping cancels queued tips. A transfer already submitted to the mint keeps its recovery data.").font(.footnote)
                }
                Section("Recovery") { Text("Wallet proofs and pending payment data are kept in this iPhone's Keychain. Encrypted wallet records are synchronized through Nostr. Keep this device's data until any pending operation has finished.") }
            }
            if let error=service.error { Text(error).foregroundStyle(.red).accessibilityIdentifier("walletError") }
        }.navigationTitle("Wallet")
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { editingAmount=false;editingRecipient=false } } }
            .task(id:app.identity.hex) { service.cancel(clear:true);try? await service.refresh(identity:app.identity) }
            .task(id:service.depositID) {
                guard !service.depositID.isEmpty else { return };var failures=0
                while !Task.isCancelled,!service.depositID.isEmpty,!service.invoiceExpired,failures < 5 {
                    do { try await Task.sleep(for:.seconds(3));if !service.busy { try await service.checkDeposit(identity:app.identity);failures=0 } }
                    catch is CancellationError { return } catch { failures += 1 }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for:.walletAutomaticTipsChanged)) { change in
                if change.object as? String == app.identity.hex { try? service.refreshAutomaticPreferences(identity:app.identity) }
            }
            .onDisappear { service.cancel() }
    }
    private func invoiceQR(_ value:String) -> UIImage? {
        let filter=CIFilter.qrCodeGenerator();filter.message=Data(("lightning:"+value).utf8);filter.correctionLevel="M"
        guard let output=filter.outputImage?.transformed(by:CGAffineTransform(scaleX:6,y:6)),let image=CIContext().createCGImage(output,from:output.extent) else { return nil };return UIImage(cgImage:image)
    }
    private func perform(_ action:@escaping @MainActor () async throws -> Void) { Task { try? await action();app.scheduleAutomaticTips() } }
}
