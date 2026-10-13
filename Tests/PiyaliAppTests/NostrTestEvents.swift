import Foundation
import CryptoKit
import NostrSDK
@testable import Piyali

func testNostrEvent(kind: Int = 30078, tags: [[String]] = [["d","learning-achievements:nosabos"],["t","learning-achievements"]], content: String = "{}", createdAt: Int64 = Int64(Date().timeIntervalSince1970), keyHex: String = String(repeating:"0",count:63)+"1") throws -> NostrEventPayload {
    let keys=Keypair(hex:keyHex)!
    let bytes=try JSONSerialization.data(withJSONObject:[0,keys.publicKey.hex,createdAt,kind,tags,content],options:[.withoutEscapingSlashes])
    let id=SHA256.hash(data:bytes).map { String(format:"%02x",$0) }.joined()
    return NostrEventPayload(id:id,pubkey:keys.publicKey.hex,created_at:createdAt,kind:kind,tags:tags,content:content,sig:try NostrCrypto().signatureForContent(id,privateKey:keys.privateKey.hex))
}
func wireEvent(_ event: NostrEventPayload) -> [String:Any] { try! JSONSerialization.jsonObject(with:JSONEncoder().encode(event)) as! [String:Any] }
