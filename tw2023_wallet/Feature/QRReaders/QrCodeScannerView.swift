//
//  QrCodeScannerView.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/16.
//

import AVFoundation
import SwiftUI

struct QrCodeScannerView: UIViewRepresentable {
    var supportedBarcodeTypes: [AVMetadataObject.ObjectType] = [.qr]
    typealias UIViewType = CameraPreview

    private let session = AVCaptureSession()
    private let delegate = QrCodeCameraDelegate()
    private let metadataOutput = AVCaptureMetadataOutput()

    func interval(delay: Double) -> QrCodeScannerView {
        delegate.scanInterval = delay
        return self
    }

    func found(r: @escaping (String) -> Void) -> QrCodeScannerView {
        print("found")
        delegate.onResult = r
        return self
    }

    func setupCamera(_ uiView: CameraPreview) {
        if let backCamera = AVCaptureDevice.default(for: AVMediaType.video) {
            if let input = try? AVCaptureDeviceInput(device: backCamera) {
                session.sessionPreset = .photo

                if session.canAddInput(input) {
                    session.addInput(input)
                }
                if session.canAddOutput(metadataOutput) {
                    session.addOutput(metadataOutput)

                    metadataOutput.metadataObjectTypes = supportedBarcodeTypes
                    metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                }
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)

                uiView.backgroundColor = UIColor.gray
                previewLayer.videoGravity = .resizeAspectFill
                uiView.layer.addSublayer(previewLayer)
                uiView.previewLayer = previewLayer

                print("startRunning")
                // startRunning をバックグラウンドスレッドで呼び出す
                DispatchQueue.global(qos: .userInitiated).async {
                    self.session.startRunning()
                }
            }
        }
    }

    func makeUIView(context: UIViewRepresentableContext<QrCodeScannerView>)
        -> QrCodeScannerView.UIViewType
    {
        print("makeUIView")
        let cameraView = CameraPreview(session: session)

        // ここで直接カメラをセットアップ
        setupCamera(cameraView)

        return cameraView
    }

    static func dismantleUIView(_ uiView: CameraPreview, coordinator: ()) {
        print("dismantleUIView")
        uiView.session.stopRunning()
    }

    func updateUIView(
        _ uiView: CameraPreview, context: UIViewRepresentableContext<QrCodeScannerView>
    ) {
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    func startSession() {
        print("startSession")
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    // カメラセッションを停止するメソッド
    func stopSession() {
        print("stopSession")
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }
}

enum CameraPermissionHandler {
    static func hasCameraPermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }
}
