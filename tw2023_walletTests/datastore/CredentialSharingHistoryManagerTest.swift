//
//  CredentialSharingHistoryManagerTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/01/12.
//

import Foundation
import XCTest
import CoreData
@testable import tw2023_wallet

class CredentialSharingHistoryManagerTests: XCTestCase {
    
    var persistentContainer: NSPersistentContainer!
    var manager: CredentialSharingHistoryManager!
    
    override func setUp() {
        super.setUp()
        
        persistentContainer = NSPersistentContainer(name: "DataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false // for testing
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
        }
        
        manager = CredentialSharingHistoryManager(container: persistentContainer)
    }
    
    override func tearDown() {
        super.tearDown()
        manager = nil
        persistentContainer = nil
    }
    
    func testSaveAndFetch() {
        let credentialSharingHistory = Datastore_CredentialSharingHistory.with {
            $0.rp = "example_rp"
            $0.accountIndex = 123
            $0.createdAt = Date().toGoogleTimestamp()
            $0.credentialID = "example_credentialID"
            $0.claims = ["claim1", "claim2"]
        }
        
        manager.save(history: credentialSharingHistory)
        
        let savedHistories = manager.getAll()
        XCTAssertEqual(savedHistories.count, 1)
        
        let fetchedHistory = savedHistories.first!
        XCTAssertEqual(fetchedHistory.rp, credentialSharingHistory.rp)
        XCTAssertEqual(fetchedHistory.accountIndex, credentialSharingHistory.accountIndex)
        XCTAssertEqual(fetchedHistory.createdAt, credentialSharingHistory.createdAt)
        XCTAssertEqual(fetchedHistory.credentialID, credentialSharingHistory.credentialID)
        
        let set1 = NSSet(array: credentialSharingHistory.claims)
        let set2 = NSSet(array: fetchedHistory.claims)

        // 順序を無視して比較
        XCTAssertEqual(set1, set2)
    }
    
    func testFindAllByCredentialId() {
        let credentialSharingHistory1 = Datastore_CredentialSharingHistory.with {
            $0.rp = "example_rp1"
            $0.accountIndex = 123
            $0.createdAt = Date().toGoogleTimestamp()
            $0.credentialID = "example_credentialID"
            $0.claims = ["claim1", "claim2"]
        }
        
        let credentialSharingHistory2 = Datastore_CredentialSharingHistory.with {
            $0.rp = "example_rp2"
            $0.accountIndex = 456
            $0.createdAt = Date().toGoogleTimestamp()
            $0.credentialID = "example_credentialID"
            $0.claims = ["claim3", "claim4"]
        }
        
        manager.save(history: credentialSharingHistory1)
        manager.save(history: credentialSharingHistory2)
        
        let histories = manager.findAllByCredentialId(credentialId: "example_credentialID")
        
        XCTAssertEqual(histories.count, 2)
        XCTAssertTrue(histories.contains { $0.rp == "example_rp1" })
        XCTAssertTrue(histories.contains { $0.rp == "example_rp2" })
    }
    
    func testDeleteAllHistories() {
        let credentialSharingHistory = Datastore_CredentialSharingHistory.with {
            $0.rp = "example_rp"
            $0.accountIndex = 123
            $0.createdAt = Date().toGoogleTimestamp()
            $0.credentialID = "example_credentialID"
            $0.claims = ["claim1", "claim2"]
        }
        
        manager.save(history: credentialSharingHistory)
        
        var savedHistories = manager.getAll()
        XCTAssertEqual(savedHistories.count, 1)
        
        manager.deleteAllHistories()
        
        savedHistories = manager.getAll()
        XCTAssertEqual(savedHistories.count, 0)
    }
}
