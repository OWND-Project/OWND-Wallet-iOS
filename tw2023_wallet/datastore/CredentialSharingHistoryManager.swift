//
//  CredentialSharingHistoryManager.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/01/11.
//

import CoreData
import Foundation
import SwiftProtobuf

extension CredentialSharingHistoryEntity {
    func toDatastoreCredentialSharingHistory() -> Datastore_CredentialSharingHistory {
        var result = Datastore_CredentialSharingHistory()
        result.rp = rp!
        result.accountIndex = accountIndex
        result.credentialID = credentialID!
        result.createdAt = createdAt!.toGoogleTimestamp()
        result.logoURL = logoURL ?? ""
        result.rpName = rpName ?? ""
        result.privacyPolicyURL = privacyPolicyURL ?? ""
        
        if let claimsSet = claims as? Set<ClaimEntity> {
            result.claims = claimsSet.map {
                var claimInfo = Datastore_ClaimInfo()
                claimInfo.claimKey = $0.claimName ?? ""
                claimInfo.claimValue = $0.claimValue ?? ""
                claimInfo.purpose = $0.purpose ?? ""
                return claimInfo
            }
        }
        
        return result
    }
}

extension Google_Protobuf_Timestamp {
    func toString() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // 必要に応じてフォーマットを変更
        return formatter.string(from: date)
    }
}

extension Datastore_ClaimInfo {
    func toClaimInfo() -> ClaimInfo {
        return ClaimInfo(claimKey: self.claimKey, claimValue: self.claimValue, purpose: self.purpose)
        
    }
}

extension Datastore_CredentialSharingHistory {
    func toSharingHistory() -> CredentialSharingHistory {
        let result = CredentialSharingHistory(
            rp: self.rp,
            accountIndex: Int(self.accountIndex),
            createdAt: self.createdAt.toString(),
            credentialID: self.credentialID,
            claims: self.claims.map{$0.toClaimInfo()},
            rpName: self.rpName,
            privacyPolicyUrl: self.privacyPolicyURL,
            logoUrl: self.logoURL
        )
        return result
    }
}


class CredentialSharingHistoryManager {
    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext

    init(container: NSPersistentContainer?) {
        if container != nil {
            persistentContainer = container!
            context = persistentContainer.viewContext
            return
        }
        persistentContainer = NSPersistentContainer(name: "DataModel") // モデルの名前に合わせて変更
        
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.type = NSSQLiteStoreType
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to initialize Core Data: \(error)")
            }
        }
        context = persistentContainer.viewContext
    }
    
    func save(history: Datastore_CredentialSharingHistory) {
        let credentialHistoryEntity = CredentialSharingHistoryEntity(context: context)
        
        credentialHistoryEntity.rp = history.rp
        credentialHistoryEntity.accountIndex = Int32(history.accountIndex)
        credentialHistoryEntity.createdAt = history.createdAt.date
        credentialHistoryEntity.credentialID = history.credentialID
        credentialHistoryEntity.rpName = history.rpName
        credentialHistoryEntity.logoURL = history.logoURL
        credentialHistoryEntity.privacyPolicyURL = history.privacyPolicyURL
        
        // Save claims
        let claimsEntities = history.claims.map { claim in
            let claimEntity = ClaimEntity(context: context)
            claimEntity.claimName = claim.claimKey
            claimEntity.claimValue = claim.claimValue
            claimEntity.purpose = claim.purpose
            return claimEntity
        }
        
        credentialHistoryEntity.addToClaims(NSSet(array: claimsEntities))
        
        do {
            try context.save()
        } catch {
            print("Failed to save credential sharing history: \(error.localizedDescription)")
        }
    }
    
    func getAllGroupByRp() -> [String : [CredentialSharingHistory]] {
        let allHistories = getAll().map{
            $0.toSharingHistory()
        }
        let grouped = Dictionary(grouping: allHistories, by: { $0.rp })
        return grouped
    }

    func getAll() -> [Datastore_CredentialSharingHistory] {
        let fetchRequest: NSFetchRequest<CredentialSharingHistoryEntity> = CredentialSharingHistoryEntity.fetchRequest()
        
        do {
            let historyEntities = try context.fetch(fetchRequest)
            
            let credentialSharingHistories = historyEntities.map { historyEntity in
                historyEntity.toDatastoreCredentialSharingHistory()
            }
            
            return credentialSharingHistories
        } catch {
            print("Failed to fetch credential sharing histories: \(error.localizedDescription)")
            return []
        }
    }
    
    func findAllByCredentialId(credentialId: String) -> [Datastore_CredentialSharingHistory] {
        let fetchRequest: NSFetchRequest<CredentialSharingHistoryEntity> = CredentialSharingHistoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "credentialID == %@", credentialId)
        
        do {
            let historyEntities = try context.fetch(fetchRequest)
            
            let credentialSharingHistories = historyEntities.map { historyEntity in
                historyEntity.toDatastoreCredentialSharingHistory()
            }
            
            return credentialSharingHistories
        } catch {
            print("Failed to fetch credential sharing histories: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteAllHistories() {
        let fetchRequest: NSFetchRequest<CredentialSharingHistoryEntity> = CredentialSharingHistoryEntity.fetchRequest()

        do {
            let histories = try context.fetch(fetchRequest)
            for history in histories {
                context.delete(history)
            }
            try context.save()
        } catch {
            print("Failed to delete all credential sharing histories: \(error.localizedDescription)")
        }
    }
}
