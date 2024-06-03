//
//  QRCodeGeneratorTest.swift
//  tw2023_walletTests
//
//  Created by SadamuMatsuoka on 2024/01/17.
//

import SwiftUI
import XCTest

@testable import tw2023_wallet

final class QRCodeGeneratorTests: XCTestCase {
    func testQRCodeGeneration() {
        // 有効な文字列からQRコードを生成
        let testString = "Test QR Code Content"
        let qrCodeImage = QRCodeGenerator.generate(from: testString)

        // QRコードがnilでないことを確認
        XCTAssertNotNil(qrCodeImage, "QRコードの生成に失敗しました。")
    }
}
