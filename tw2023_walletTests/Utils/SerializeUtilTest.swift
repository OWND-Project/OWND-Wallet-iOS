//
//  SerializeUtilTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2023/12/26.
//

import XCTest

@testable import tw2023_wallet

enum TestEnum: String {
    case case1 = "Value1"
    case case2 = "Value2"
    case case3 = "Value3"
}

final class EnumDeserializerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDeserialization() {
        let deserializer = EnumDeserializer<TestEnum>(enumType: TestEnum.self)

        let stringValue = "Value2"
        let deserializedEnum = deserializer.deserialize(rawValue: stringValue)

        XCTAssertNotNil(deserializedEnum, "Enum deserialization failed")
        XCTAssertEqual(deserializedEnum, TestEnum.case2, "Incorrect enum case deserialized")
    }
}
