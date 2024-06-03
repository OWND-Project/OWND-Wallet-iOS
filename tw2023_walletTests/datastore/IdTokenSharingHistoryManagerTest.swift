//
//  IdTokenSharingHistoryManagerTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/01/12.
//

import CoreData
import Foundation
import XCTest

@testable import tw2023_wallet

class IdTokenSharingHistoryManagerTests: XCTestCase {

    var context: NSManagedObjectContext!
    var manager: IdTokenSharingHistoryManager!

    override func setUp() {
        super.setUp()

        // Core Dataのメモリ内ストアを使用してテスト用のNSManagedObjectContextを作成
        let container = NSPersistentContainer(name: "DataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        context = container.viewContext
        manager = IdTokenSharingHistoryManager(container: container)
    }

    override func tearDown() {
        super.tearDown()

        // テスト後にデータをクリア
        let fetchRequest: NSFetchRequest<IdTokenSharingHistoryEntity> =
            IdTokenSharingHistoryEntity.fetchRequest()

        do {
            let histories = try context.fetch(fetchRequest)
            for history in histories {
                context.delete(history)
            }
            try context.save()
        }
        catch {
            print("Failed to delete test data: \(error.localizedDescription)")
        }
    }

    func testSaveAndRetrieveIdTokenSharingHistory() {
        // テストデータ作成
        let historyData = Datastore_IdTokenSharingHistory.with {
            $0.rp = "example_rp"
            $0.accountIndex = 123
            $0.createdAt = Date().toGoogleTimestamp()
        }

        // 保存
        manager.save(history: historyData)

        // 取得
        let retrievedHistories = manager.getAll()

        // 検証
        XCTAssertEqual(retrievedHistories.count, 1)
        XCTAssertEqual(retrievedHistories[0].rp, "example_rp")
        XCTAssertEqual(retrievedHistories[0].accountIndex, 123)
        // その他の検証項目を追加
    }
}
