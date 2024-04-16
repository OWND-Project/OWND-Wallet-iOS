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

    var sharingHistory: CredentialSharingHistory

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())

            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Group {
                            if let logoView = sharingHistory.logoImage {
                                logoView
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: 70, height: 70)
                        if (sharingHistory.rpName != "") {
                            Text(sharingHistory.rpName)
                                .modifier(BodyBlack())
                        } else {
                            Text("Unknown")
                                .modifier(BodyBlack())
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
                            Text(sharingHistory.privacyPolicyUrl)
                                .modifier(BodyBlack())
                                .underline()
                                .sheet(isPresented: $showPrivacyPolicy, content: {
                                    SafariView(url: URL(string: sharingHistory.privacyPolicyUrl)!)
                                })
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
