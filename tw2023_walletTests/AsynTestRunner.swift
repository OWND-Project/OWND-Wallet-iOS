//
//  AsynTestRunner.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2023/12/27.
//

import XCTest

extension XCTestCase {
    func runAsyncTest(_ asyncTest: @escaping () async throws -> Void) {
        let expectation = self.expectation(description: "Async Test")
        Task {
            do {
                try await asyncTest()
            }
            catch {
                XCTFail("Async test failed with error: \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
