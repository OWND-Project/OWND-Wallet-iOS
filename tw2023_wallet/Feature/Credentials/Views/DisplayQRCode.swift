//
//  DisplayQRCode.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/17.
//

import SwiftUI

struct DisplayQRCode: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DisplayQRCodeViewModel

    init(credential: Credential) {
        self._viewModel = ObservedObject(
            initialValue: DisplayQRCodeViewModel(credential: credential))
    }

    var body: some View {
        VStack {
            Spacer()  // 上部にスペーサーを追加

            if viewModel.hasX5u {
                if let qrCodeImage = viewModel.qrCodeImage {
                    qrCodeImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .padding(.vertical, 64)
                }
                Text("qr_generate_description")
                    .modifier(BodyBlack())
            }
            else {
                Text("qr_generate_error_message")
                    .modifier(BodyBlack())
                    .padding(.vertical, 64)  // エラーメッセージのパディングを調整
            }

            Spacer()  // 下部にスペーサーを追加

            ActionButtonBlack(
                title: "close",
                action: {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }.padding(.horizontal, 16)
    }
}

#Preview("0") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return DisplayQRCode(
        credential: modelData.credentials[0]
    )
}

#Preview("1") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return DisplayQRCode(
        credential: modelData.credentials[1]
    )
}

#Preview("2") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return DisplayQRCode(
        credential: modelData.credentials[2]
    )
}
