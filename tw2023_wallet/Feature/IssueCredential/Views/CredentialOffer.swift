//
//  CredentialOffer.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import SwiftUI


struct CredentialOfferView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(CredentialOfferArgs.self) var args
    var viewModel: CredentialOfferViewModel
    @State private var navigateToHome = false
    @State private var navigateToPinInput = false
    @State private var showErrorDialog = false

    init(viewModel: CredentialOfferViewModel = CredentialOfferViewModel()) {
        self.viewModel = viewModel
    }

    private func handleCredentialIssue() {
        if let offer = viewModel.dataModel.credentialOffer {
            if offer.isTxCodeRequired() {
                self.navigateToPinInput = true
            }
            else {
                Task {
                    do {
                        try await viewModel.sendRequest(txCode: nil)
                    }
                    catch {
                        showErrorDialog = true
                    }
                    navigateToHome = true
                }
            }
        }
        else {
            print("Credential offer is not set up correctly")
            showErrorDialog = true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.dataModel.isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
                else {
                    content
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
        .onAppear {
            Task {
                if let credentialOfferString = args.credentialOffer,
                    let credentialOffer = CredentialOffer.fromString(credentialOfferString)
                {
                    do {
                        try await viewModel.loadData(credentialOffer)
                    }
                    catch {
                        print("Failed to prepare data for issuing credential: \(error)")
                        showErrorDialog = true
                    }
                }
                else {
                    print("Invalid credential offer format")
                    showErrorDialog = true
                }
            }
        }
        .alert(isPresented: $showErrorDialog) {
            Alert(
                title: Text("error"),
                message: Text("failed_to_load_info_for_issuance"),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if let issuerMetaData = viewModel.dataModel.metaData?.credentialIssuerMetadata,
           let targetCredentialId = viewModel.dataModel.targetCredentialId,
           let targetCredential = issuerMetaData.credentialConfigurationsSupported[targetCredentialId] {
            contentWithMetaData(issuerMetaData, targetCredential)
        }
        else {
            EmptyView()
                .onAppear {
                    showErrorDialog = true
                }
        }
    }

    private func contentWithMetaData(_ issuerMetaData: CredentialIssuerMetadata, _ targetCredential: CredentialConfiguration) -> some View {
        let issuerDisplayName = issuerMetaData.getCredentialIssuerDisplayName()
        let credentialDisplayName = targetCredential.getCredentialDisplayName()
        let displayNames = targetCredential.getClaimNames()

        return VStack {
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                Spacer()
            }

            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "credentialOfferText", comment: ""),
                                issuerDisplayName,
                                credentialDisplayName)
                        )
                        .modifier(Title3Black())
                        Image("issue_confirmation")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.65)  // 横幅の65%に設定
                    }
                    Text("Items to be issued")
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                        .modifier(BodyGray())
                    ForEach(displayNames, id: \.self) { displayName in
                        CredentialSubjectLow(item: displayName)
                    }
                    Text("issuing_authority_information")
                        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                        .padding(.top, 32)
                        .modifier(BodyBlack())

                    IssuerDetail(
                        issuerMetadata: issuerMetaData, showTitle: false)
                    ActionButtonBlack(
                        title: "issue_credential",
                        action: handleCredentialIssue
                    )
                    .padding(.vertical, 16)
                    .navigationDestination(
                        isPresented: $navigateToHome,
                        destination: {
                            Home()
                        }
                    )
                    .navigationDestination(
                        isPresented: $navigateToPinInput,
                        destination: {
                            PinCodeInput(viewModel: self.viewModel)
                        }
                    )
                }
                .padding(.horizontal, 16)  // 左右に16dpのパディング
                .padding(.vertical, 16)
            }

        }
    }

}

#Preview {
    let args = CredentialOfferArgs()
    args.credentialOffer =
        "openid-credential-offer://?credential_offer=%7B%22credential_issuer%22%3A%22https%3A%2F%2Fissuer.privacybydesign.jp%3A8443%22%2C%22credentials%22%3A%5B%22ParticipationCertificate%22%5D%2C%22grants%22%3A%7B%22urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Apre-authorized_code%22%3A%7B%22pre-authorized_code%22%3A%22R2Wc1PlJN87DLttzKprnZvPiScDuRyv4%22%2C%22user_pin_required%22%3Afalse%7D%7D%7D"
    return CredentialOfferView(
        viewModel: CredentialOfferPreviewModel()
    ).environment(args)
}
