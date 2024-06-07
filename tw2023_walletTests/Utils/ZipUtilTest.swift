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

        XCTAssertEqual(
            decompressedString, inputString, "Decompressed string does not match original string")
    }

    func testCreateZip() {
        // テスト用のコンテンツを定義
        let content = "Hello, World!"

        // createZipメソッドを呼び出してZIPデータを生成
        guard let zipData = ZipUtil.createZip(with: content) else {
            XCTFail("ZIPデータの生成に失敗しました")
            return
        }

        // ZIPデータがnilでないことを確認
        XCTAssertNotNil(zipData, "ZIPデータはnilではありません")
    }

    func testUnzipAndReadContent() {
        // テスト用のコンテンツを定義
        let content = "Hello, World!"

        // createZipメソッドを呼び出してZIPデータを生成
        guard let zipData = ZipUtil.createZip(with: content) else {
            XCTFail("ZIPデータの生成に失敗しました")
            return
        }

        // unzipAndReadContentメソッドを呼び出して内容を確認
        do {
            let unzippedContent = try ZipUtil.unzipAndReadContent(from: zipData)
            XCTAssertEqual(unzippedContent, content, "解凍されたコンテンツが一致しません")
        }
        catch {
            XCTFail("解凍中にエラーが発生しました: \(error)")
        }
    }

}
