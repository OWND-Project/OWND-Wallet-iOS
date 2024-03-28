//
//  QRCodeGenerator.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/17.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

enum QRCodeGenerator {
    static func generate(from string: String, scale: CGFloat = 5.0) -> Image? {
        let data = Data(string.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")

        if let qrImage = filter.outputImage {
            // スケールアップするためのトランスフォームを適用
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            let scaledQRImage = qrImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledQRImage, from: scaledQRImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                return Image(uiImage: uiImage)
            }
        }
        return nil
    }
}
