//
//  QrCodeCameraDelegate.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/16.
//

import AVFoundation
import UIKit

class QrCodeCameraDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var scanInterval: Double = 0.5
    var lastTime = Date(timeIntervalSince1970: 0)

    var onResult: (String) -> Void = { _ in }
    var mockData: String?

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            foundBarcode(stringValue)
        }
    }

    @objc func onSimulateScanning() {
        foundBarcode(mockData ?? "Simulated QR-code result.")
    }

    func foundBarcode(_ stringValue: String) {
        let now = Date()
        if now.timeIntervalSince(lastTime) >= scanInterval {
            lastTime = now
            onResult(stringValue)

            // ハプティックフィードバックの生成
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}
