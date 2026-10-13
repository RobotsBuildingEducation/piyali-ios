import Foundation
import Network

/// Loopback WebSocket relay. Test events never leave this machine.
final class LocalNostrRelay: @unchecked Sendable {
    private let queue=DispatchQueue(label:"Piyali.local-relay."+UUID().uuidString)
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var received: [[Any]] = []
    private var frameHandler: (([Any],NWConnection)->Void)?
    private(set) var url=""
    func start(handler: @escaping ([Any],NWConnection)->Void) async throws {
        frameHandler=handler
        let options=NWProtocolWebSocket.Options();options.autoReplyPing=true
        options.setClientRequestHandler(queue) { _,_ in NWProtocolWebSocket.Response(status:.accept,subprotocol:nil) }
        let params=NWParameters.tcp;params.defaultProtocolStack.applicationProtocols.insert(options,at:0)
        params.requiredLocalEndpoint = .hostPort(host:"127.0.0.1",port:.any)
        let server=try NWListener(using:params);listener=server
        server.newConnectionHandler={ [weak self] connection in
            guard let self else { connection.cancel();return }
            self.connections.append(connection);connection.start(queue:self.queue);self.receive(connection)
        }
        try await withCheckedThrowingContinuation { (continuation:CheckedContinuation<Void,Error>) in
            var done=false
            server.stateUpdateHandler={ [weak self] state in
                guard !done else { return }
                switch state {
                case .ready:done=true;self?.url="ws://127.0.0.1:\(server.port!.rawValue)";continuation.resume()
                case .failed(let error):done=true;continuation.resume(throwing:error)
                default:break
                }
            }
            server.start(queue:queue)
        }
    }
    private func receive(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] data,_,_,error in
            guard let self,error == nil else { return }
            if let data,let frame=try? JSONSerialization.jsonObject(with:data) as? [Any] { self.received.append(frame);self.frameHandler?(frame,connection) }
            self.receive(connection)
        }
    }
    func send(_ frame: [Any], to connection: NWConnection) {
        guard let data=try? JSONSerialization.data(withJSONObject:frame,options:[.withoutEscapingSlashes]) else { return }
        let context=NWConnection.ContentContext(identifier:UUID().uuidString,metadata:[NWProtocolWebSocket.Metadata(opcode:.text)])
        connection.send(content:data,contentContext:context,isComplete:true,completion:.contentProcessed { _ in })
    }
    func frames() -> [[Any]] { queue.sync { received } }
    func stop() { queue.sync { for connection in connections { connection.cancel() };connections=[];listener?.cancel();listener=nil;frameHandler=nil } }
}
