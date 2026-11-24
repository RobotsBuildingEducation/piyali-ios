import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor protocol VoiceJourneyStoring {
    func watch(account:String,target:String,onData:@escaping(JSONValue)->Void,onError:@escaping()->Void)throws->AnyCancellable
    func load(account:String,target:String,milestone:Int)async throws->JourneyEnvelope
    func save(_ envelope:JourneyEnvelope,account:String,target:String,milestone:Int)async throws
    func delete(account:String,target:String,milestone:Int)async throws
    func acknowledge(account:String,target:String,milestone:Int)async throws
}
@MainActor final class VoiceJourneyStore:VoiceJourneyStoring {
    private let injected:Firestore?
    init(database:Firestore?=nil){injected=database}
    private func database(_ account:String)throws->Firestore {
        if let injected{return injected}
        guard FirebaseService.shared.configured,Auth.auth().currentUser?.uid == account else{throw AppError.message("Sync your account to open Journey.")};return Firestore.firestore()
    }
    func watch(account:String,target:String,onData:@escaping(JSONValue)->Void,onError:@escaping()->Void)throws->AnyCancellable {
        let registration=try database(account).collection("users").document(account).collection("voiceJourney").document(target).addSnapshotListener{snapshot,error in
            Task{@MainActor in if error != nil{onError()}else{onData(PhonicsProgress.document(FirebaseService.normalized(snapshot?.data() ?? [:])))}}
        };return AnyCancellable{registration.remove()}
    }
    func load(account:String,target:String,milestone:Int)async throws->JourneyEnvelope {
        let data=try await database(account).collection("users").document(account).collection("voiceJourney").document(target).collection("recordings").document(String(milestone)).getDocument().data()
        guard let data,let version=data["version"] as? Int,let wrapped=data["wrappedKey"] as? String,let iv=data["iv"] as? Data,let ciphertext=data["ciphertext"] as? Data else{throw AppError.message("Recording no longer available.")}
        return JourneyEnvelope(version:version,wrappedKey:wrapped,iv:iv,ciphertext:ciphertext)
    }
    func save(_ envelope:JourneyEnvelope,account:String,target:String,milestone:Int)async throws {
        guard envelope.version == 1,envelope.iv.count == 12,!envelope.wrappedKey.isEmpty,envelope.ciphertext.count<1_000_000 else{throw AppError.message("Invalid recording.")}
        let db=try database(account),ref=db.collection("users").document(account).collection("voiceJourney").document(target)
        _=try await db.runTransaction{tx,error in do {
            let current=PhonicsProgress.document(FirebaseService.normalized(try tx.getDocument(ref).data() ?? [:]))
            guard VoiceJourneyModel.canRecord(current,milestone) else{throw AppError.message("Milestone is locked or already recorded.")}
            let metadata:[String:Any]=["createdAt":WebProgressContract.iso(Date()),"capturedSession":VoiceJourneyModel.count(current)]
            tx.setData(["version":envelope.version,"wrappedKey":envelope.wrappedKey,"iv":envelope.iv,"ciphertext":envelope.ciphertext],forDocument:ref.collection("recordings").document(String(milestone)))
            tx.updateData(["recordings.\(milestone)":metadata,"lastPromptedMilestone":max(milestone,Int(current["lastPromptedMilestone"].number))],forDocument:ref);return true
        }catch let failure{error?.pointee=failure as NSError;return nil}}
    }
    func acknowledge(account:String,target:String,milestone:Int)async throws {
        let db=try database(account),ref=db.collection("users").document(account).collection("voiceJourney").document(target)
        _=try await db.runTransaction{tx,error in do {
            let current=PhonicsProgress.document(FirebaseService.normalized(try tx.getDocument(ref).data() ?? [:]))
            guard VoiceJourneyModel.canRecord(current,milestone) else{return false}
            tx.updateData(["lastPromptedMilestone":max(milestone,Int(current["lastPromptedMilestone"].number))],forDocument:ref);return true
        }catch let failure{error?.pointee=failure as NSError;return nil}}
    }
    func delete(account:String,target:String,milestone:Int)async throws {
        let db=try database(account),ref=db.collection("users").document(account).collection("voiceJourney").document(target)
        _=try await db.runTransaction{tx,error in do {
            var recordings=(try tx.getDocument(ref).data()?["recordings"] as? [String:Any]) ?? [:];recordings.removeValue(forKey:String(milestone))
            tx.deleteDocument(ref.collection("recordings").document(String(milestone)));tx.updateData(["recordings":recordings],forDocument:ref);return true
        }catch let failure{error?.pointee=failure as NSError;return nil}}
    }
}
