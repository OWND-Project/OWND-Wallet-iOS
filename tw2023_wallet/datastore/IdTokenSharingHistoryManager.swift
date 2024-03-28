//
//  IdTokenSharingHistoryManager.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/01/12.
//

import CoreData
import Foundation

extension IdTokenSharingHistoryEntity {
    func toDatastoreIdTokenSharingHistory() -> Datastore_IdTokenSharingHistory {
        var result = Datastore_IdTokenSharingHistory()
        result.rp = rp!
        result.accountIndex = accountIndex
        result.createdAt = createdAt!.toGoogleTimestamp()
        
        return result
    }
}

class IdTokenSharingHistoryManager {
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
    
    func save(history: Datastore_IdTokenSharingHistory) {
        let idTokenHistoryEntity = IdTokenSharingHistoryEntity(context: context)
        
        idTokenHistoryEntity.rp = history.rp
        idTokenHistoryEntity.accountIndex = Int32(history.accountIndex)
        idTokenHistoryEntity.createdAt = history.createdAt.date

        do {
            try context.save()
        } catch {
            print("Failed to save IdToken sharing history: \(error.localizedDescription)")
        }
    }
    
    func getAll() -> [Datastore_IdTokenSharingHistory] {
        let fetchRequest: NSFetchRequest<IdTokenSharingHistoryEntity> = IdTokenSharingHistoryEntity.fetchRequest()
        
        do {
            let historyEntities = try context.fetch(fetchRequest)
            
            let idTokenSharingHistories = historyEntities.map { historyEntity in
                historyEntity.toDatastoreIdTokenSharingHistory()
            }
            
            return idTokenSharingHistories
        } catch {
            print("Failed to fetch IdToken sharing histories: \(error.localizedDescription)")
            return []
        }
    }
}
