//
//  QRScannerView.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/16.
//

import SwiftUI

struct QRReaderView: View {
    @ObservedObject var viewModel: QRReaderViewModel
    @Binding var nextScreen: ScreensOnFullScreen
    
    @State private var hasCameraAccess: Bool = false
    @State private var qrCodeScannerView = QrCodeScannerView() // QrCodeScannerViewのインスタンス
    @State private var isRequestingPermission: Bool = false

    @Environment(\.dismiss) var dismiss
    @Environment(SharedArgs.self) var sharedArgs
    @Environment(SharingRequestModel.self) var sharingRequestModel

    init(
        viewModel: QRReaderViewModel = QRReaderViewModel(),
        nextScreen: Binding<ScreensOnFullScreen>
    ) {
        self.viewModel = viewModel
        self._nextScreen = nextScreen
    }

    var body: some View {
        ZStack {
            Group {
                if isRequestingPermission {
                    // ローディングインジケーターを表示
                    ProgressView()
                } else if self.hasCameraAccess {
                    // QRコード読み取りView
                    qrCodeScannerView
                        .found(r: self.viewModel.onFoundQrCode)
                        .interval(delay: self.viewModel.scanInterval)
                } else {
                    Text("camera_authorization_required")
                }
                
                VStack {
                    Spacer()
                    VStack {
                        Text("scan_the_qr_code")
                            .modifier(BodyWhite())
                            .padding(.vertical, 64)
                        
                        Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                            dismiss()
                            nextScreen = .root
                        }
                        .modifier(BodyWhite())
                    }
                    .cornerRadius(10) // 角丸設定
                    .padding()
                }
                .padding()
                .onReceive(viewModel.$scanResultType) { newScanResultType in
                    self.handleNavigation(scanResultType: newScanResultType)
                }
            }
            .onAppear(perform: self.checkCameraPermission)
        }
        .toolbar(.hidden, for: .tabBar)
    }

    private func handleNavigation(scanResultType: ScanResultType) {
        switch scanResultType {
        case .openIDCredentialOffer:
            sharedArgs.credentialOfferArgs = viewModel.credentialOfferArgs
            dismiss()
            nextScreen = ScreensOnFullScreen.credentialOffer
        case .openID4VP:
            sharedArgs.sharingCredentialArgs = viewModel.sharingCredentialArgs
            dismiss()
            nextScreen = ScreensOnFullScreen.sharingRequest
        case .compressedString:
            sharedArgs.verificationArgs = viewModel.verificationArgs
            dismiss()
            nextScreen = ScreensOnFullScreen.verification
        default:
            break
        }
    }

    private func checkCameraPermission() {
        print("checkCameraPermission")
        if CameraPermissionHandler.hasCameraPermission() {
            hasCameraAccess = true
        } else {
            isRequestingPermission = true // パーミッション要求開始
            CameraPermissionHandler.requestCameraPermission { granted in
                DispatchQueue.main.async {
                    isRequestingPermission = false // パーミッション要求終了
                    if granted {
                        self.hasCameraAccess = true
                        // パーミッションダイアログでカメラセッションが動かなくなるので一度セッションを停止
                        self.qrCodeScannerView.stopSession()
                    }
                }
            }
        }
    }
}

#Preview {
    QRReaderView(nextScreen: .constant(ScreensOnFullScreen.root))
}
