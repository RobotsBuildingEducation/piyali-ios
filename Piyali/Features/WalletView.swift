import SwiftUI
import CoreImage.CIFilterBuiltins

struct WalletView:View {
    @EnvironmentObject var app:AppModel
    @StateObject private var service=WalletService()
    @State private var amount="10"
    @FocusState private var editingAmount:Bool
    var body:some View {
        Form {
            Section("Wallet") {
                Text("\(service.balance) sats available").accessibilityIdentifier("walletBalance")
                Text(service.status).accessibilityIdentifier("walletStatus")
                if service.busy { ProgressView("Checking wallet…") }
                Button("Refresh wallet") { perform { try await service.refresh(identity:app.identity) } }.disabled(service.busy)
                if service.canCreate { Text("This wallet holds ecash issued by Minibits. Paying a deposit invoice adds sats to that mint balance.");Link("About Minibits",destination:URL(string:"https://minibits.cash/")!);Button("Create wallet") { perform { try await service.create(identity:app.identity) } }.disabled(service.busy).accessibilityIdentifier("walletCreate") }
            }
            if service.ready {
                Section("Add sats with Lightning") {
                    if service.invoice.isEmpty,!service.pending {
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
                    if service.pending { Text("A wallet operation is saved on this device. Recover it before starting another payment.") }
                    if !service.invoice.isEmpty || service.pending { Button(service.pending ? "Recover saved deposit" : "Check payment status") { perform { try await service.checkDeposit(identity:app.identity) } }.disabled(service.busy).accessibilityIdentifier("walletCheckDeposit") }
                }
                Section("Recovery") { Text("Wallet proofs and pending payment data are kept in this iPhone's Keychain. Encrypted wallet records are synchronized through Nostr. Keep this device's data until any pending operation has finished.") }
            }
            if let error=service.error { Text(error).foregroundStyle(.red).accessibilityIdentifier("walletError") }
        }.navigationTitle("Wallet")
            .toolbar { ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { editingAmount=false } } }
            .task(id:app.identity.hex) { service.cancel(clear:true);try? await service.refresh(identity:app.identity) }
            .task(id:service.invoice) {
                guard !service.invoice.isEmpty else { return };var failures=0
                while !Task.isCancelled,!service.invoice.isEmpty,!service.invoiceExpired,failures < 5 {
                    do { try await Task.sleep(for:.seconds(3));if !service.busy { try await service.checkDeposit(identity:app.identity);failures=0 } }
                    catch is CancellationError { return } catch { failures += 1 }
                }
            }
            .onDisappear { service.cancel() }
    }
    private func invoiceQR(_ value:String) -> UIImage? {
        let filter=CIFilter.qrCodeGenerator();filter.message=Data(("lightning:"+value).utf8);filter.correctionLevel="M"
        guard let output=filter.outputImage?.transformed(by:CGAffineTransform(scaleX:6,y:6)),let image=CIContext().createCGImage(output,from:output.extent) else { return nil };return UIImage(cgImage:image)
    }
    private func perform(_ action:@escaping @MainActor () async throws -> Void) { Task { try? await action() } }
}
