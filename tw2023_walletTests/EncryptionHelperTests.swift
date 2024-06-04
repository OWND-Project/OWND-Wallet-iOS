//
//  EncryptionHelperTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2024/01/08.
//

import XCTest

final class EncryptionHelperTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEncryptionDecryption() {
        let helper = EncryptionHelper()
        let originalString = "テストメッセージ"
        guard let originalData = originalString.data(using: .utf8) else {
            XCTFail("Failed to convert string to data")
            return
        }

        // データの暗号化
        guard let encrypted = helper.encrypt(data: originalData) else {
            XCTFail("Failed to encrypt data")
            return
        }

        // データの復号化
        guard
            let decryptedData = helper.decrypt(
                data: encrypted.encryptedData, iv: encrypted.iv, tag: encrypted.tag),
            let decryptedString = String(data: decryptedData, encoding: .utf8)
        else {
            XCTFail("Failed to decrypt data")
            return
        }

        // 元の文字列と復号化された文字列が一致することを確認
        XCTAssertEqual(originalString, decryptedString)
    }

    func testEncryptionDecryptionWithSerialization() {
        let helper = EncryptionHelper()
        let originalString = "テストメッセージ"
        guard let originalData = originalString.data(using: .utf8) else {
            XCTFail("Failed to convert string to data")
            return
        }

        guard let encrypted = helper.encryptWithSerialization(data: originalData) else {
            XCTFail("Failed to encrypt data")
            return
        }

        // データの復号化
        guard let decryptedData = helper.decryptWithDeserialization(data: encrypted),
            let decryptedString = String(data: decryptedData, encoding: .utf8)
        else {
            XCTFail("Failed to decrypt data")
            return
        }

        XCTAssertEqual(originalString, decryptedString)

    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
