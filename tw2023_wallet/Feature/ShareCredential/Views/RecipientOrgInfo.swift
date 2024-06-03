//
//  RecipientOrgInfo.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/11.
//

import SwiftUI

struct RecipientOrgInfo: View {
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false

    var clientInfo: ClientInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Group {
                        if let logoView = clientInfo.logoImage {
                            logoView
                        }
                        else {
                            Color.clear
                        }
                    }
                    .frame(width: 70, height: 70)
                    Text(clientInfo.certificateInfo!.organization ?? clientInfo.name).modifier(
                        TitleBlack())
                }
                if let issuer = clientInfo.certificateInfo?.issuer {
                    if clientInfo.verified {
                        HStack {
                            Image("verifier_mark")
                            Text("verified by").modifier(SubHeadLineGray())
                            Text(issuer.organization!).modifier(SubHeadLineGray())
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ

            if let certificateInfo = clientInfo.certificateInfo {
                VStack(alignment: .leading, spacing: 0) {
                    Text("domain")
                        .modifier(SubHeadLineGray())
                    Text(certificateInfo.domain!)
                        .modifier(BodyBlack())
                }
                .padding(.vertical, 16)
                VStack(alignment: .leading, spacing: 0) {
                    Text("cert_location")
                        .modifier(SubHeadLineGray())
                    //                    Text(certificateInfo.domain!)
                    //                        .modifier(BodyBlack())
                    HStack {
                        Text(certificateInfo.state ?? "")
                        Text(certificateInfo.locality ?? "")
                    }
                }
                .padding(.vertical, 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text("cert_country")
                        .modifier(SubHeadLineGray())
                    Text(certificateInfo.country ?? "")
                        .modifier(BodyBlack())
                }
                .padding(.vertical, 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text("contact")
                        .modifier(SubHeadLineGray())
                    Text(certificateInfo.domain ?? "Unknown")
                        .modifier(BodyBlack())
                }
                .padding(.vertical, 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text("terms_of_use")
                        .modifier(SubHeadLineGray())
                    Button(action: {
                        self.showTermsOfUse = true
                    }) {
                        Text(clientInfo.tosUrl)
                            .modifier(BodyBlack())
                            .underline()
                            .sheet(
                                isPresented: $showTermsOfUse,
                                content: {
                                    SafariView(url: URL(string: clientInfo.tosUrl)!)
                                })
                    }
                }
                .padding(.vertical, 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text("privacy_policy")
                        .modifier(SubHeadLineGray())
                    Button(action: {
                        self.showPrivacyPolicy = true
                    }) {
                        Text(clientInfo.policyUrl)
                            .modifier(BodyBlack())
                            .underline()
                            .sheet(
                                isPresented: $showPrivacyPolicy,
                                content: {
                                    SafariView(url: URL(string: clientInfo.policyUrl)!)
                                })
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                }
                .padding(.vertical, 16)
            }
            else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("terms_of_use")
                        .modifier(SubHeadLineGray())
                    Button(action: {
                        self.showTermsOfUse = true
                    }) {
                        Text(clientInfo.tosUrl)
                            .modifier(BodyBlack())
                            .underline()
                            .sheet(
                                isPresented: $showTermsOfUse,
                                content: {
                                    SafariView(url: URL(string: clientInfo.tosUrl)!)
                                })
                    }
                }
                .padding(.vertical, 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text("privacy_policy")
                        .modifier(SubHeadLineGray())
                    Button(action: {
                        self.showPrivacyPolicy = true
                    }) {
                        Text(clientInfo.policyUrl)
                            .modifier(BodyBlack())
                            .underline()
                            .sheet(
                                isPresented: $showPrivacyPolicy,
                                content: {
                                    SafariView(url: URL(string: clientInfo.policyUrl)!)
                                })
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                }
                .padding(.vertical, 16)
            }
        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadClientInfoList()
    return RecipientOrgInfo(clientInfo: modelData.clientInfoList[0])
}
