//
//  ZipUtilTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2023/12/26.
//

import XCTest
@testable import tw2023_wallet

class ZipUtilTests: XCTestCase {
    
    func testCompressionAndDecompression() {
        let inputString = "test string"
        
        guard let compressedString = ZipUtil.compressString(input: inputString) else {
            XCTFail("Compression failed")
            return
        }
        
        guard let decompressedString = ZipUtil.decompressString(compressed: compressedString) else {
            XCTFail("Decompression failed")
            return
        }
        
        XCTAssertEqual(decompressedString, inputString, "Decompressed string does not match original string")
    }
}
