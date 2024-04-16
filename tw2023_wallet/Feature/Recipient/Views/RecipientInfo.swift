//
//  RecipientInfo.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/11.
//

import SwiftUI

struct RecipientInfo: View {
    @State private var showPrivacyPolicy = false
    @StateObject private var viewModel = RecipientInfoViewModel()

    var sharingHistory: History

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())

            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Group {
                            switch sharingHistory {
                            case let credential as CredentialSharingHistory:
                                if let logoView = credential.logoImage {
                                    logoView
                                } else {
                                    Color.clear
                                }
                            case let idToken as IdTokenSharingHistory:
                                Color.clear // todo: add `logoUri` to IdTokenSharingHistory
                            default:
                                Color.clear
                            }
                        }
                        .frame(width: 70, height: 70)
                        let defaultText = Text("Unknown").modifier(BodyBlack())
                        switch sharingHistory {
                        case let credential as CredentialSharingHistory:
                            if (credential.rpName != "") {
                                Text(credential.rpName)
                                    .modifier(BodyBlack())
                            } else {
                                defaultText
                            }
                        case let idToken as IdTokenSharingHistory:
                            Text(idToken.rp) // todo: add `rpName` to IdTokenSharingHistory
                                .modifier(BodyBlack())
                        default:
                            defaultText
                        }
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading) // 左寄せ
                    VStack {
                        if let certificateInfo = viewModel.certificateInfo {
                            let address = certificateInfo.getFullAddress()
                            VStack(alignment: .leading, spacing: 0) {
                                Text("cert_location")
                                    .modifier(SubHeadLineGray())
                                Text(address)
                                    .modifier(BodyBlack())
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("privacy_policy")
                            .modifier(SubHeadLineGray())
                        Button(action: {
                            self.showPrivacyPolicy = true
                        }) {
                            switch sharingHistory {
                            case let credential as CredentialSharingHistory:
                            Text(credential.privacyPolicyUrl)
                                .modifier(BodyBlack())
                                .underline()
                                .sheet(isPresented: $showPrivacyPolicy, content: {
                                    SafariView(url: URL(string: credential.privacyPolicyUrl)!)
                                })
                            case let idToken as IdTokenSharingHistory:
                                Text("")
                            default:
                                Text("")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // 左寄せ
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .onAppear {
            viewModel.loadCertificateInfo(for: sharingHistory.rp)
        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadSharingHistories()
    return RecipientInfo(
        sharingHistory: modelData.sharingHistories[0])
}
