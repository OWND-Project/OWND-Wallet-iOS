//
//  TestUtilities.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/06/24.
//

import Foundation
import XCTest

enum TestUtilityError: Error{
    case FailedToLoadResourceJson(fileName: String)
}


func loadJsonTestData(fileName: String) throws -> Data {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
        let jsonData = try? Data(contentsOf: url)
    else {
        XCTFail("Cannot read test data: \(fileName)")
        throw TestUtilityError.FailedToLoadResourceJson(fileName: fileName)
    }
    return jsonData
}
