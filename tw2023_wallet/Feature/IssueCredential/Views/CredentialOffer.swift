//
//  CredentialOffer.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

/*

 Caution!

 `CredentialOfferView` will be significantly revised in PR17,
  which has been filed to make it ID1 compliant.
  This PR will be merged soon, but will not be included in the next release.

  With that in mind, the current content below contains a stopgap measure
  that was implemented to get through the next release.

*/

import SwiftUI

func getCredentialDisplayName(credentialSupported: CredentialSupported?) -> String {
    if let jwt = credentialSupported as? CredentialSupportedJwtVcJson {
        return jwt.display?.first?.name ?? ""
    }
    else if let sdJwt = credentialSupported as? CredentialSupportedVcSdJwt {
        return sdJwt.display?.first?.name ?? ""
    }
    else {
        return ""
    }
}

func getClaimNames(credentialSupported: CredentialSupported?) -> [String] {
    if let jwt = credentialSupported as? CredentialSupportedJwtVcJson {
        return jwt.credentialDefinition.getClaimNames()
    }
    else if let sdJwt = credentialSupported as? CredentialSupportedVcSdJwt {
        return sdJwt.credentialDefinition.getClaimNames()
    }
    else {
        return []
    }
}

struct CredentialOfferView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(CredentialOfferArgs.self) var args
    @StateObject var viewModel: CredentialOfferViewModel = .init()
    @State private var navigateToHome = false
    @State private var navigateToPinInput = false
    @State private var showErrorDialog = false

    private func contentWithMetaData(
        issuerDisplayName: String,
        credentialDisplayName: String,
        displayNames: [String]
    ) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    HStack {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        Spacer()
                    }

                    Text(
                        String(
                            format: NSLocalizedString(
                                "credentialOfferText", comment: ""), issuerDisplayName,
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
                    issuerMetadata: viewModel.dataModel.metaData, showTitle: false)
                ActionButtonBlack(
                    title: "issue_credential",
                    action: {
                        let pinRequired = viewModel.checkIfPinIsRequired()
                        if pinRequired {
                            self.navigateToPinInput = true
                        }
                        else {
                            Task {
                                try await viewModel.sendRequest(userPin: nil)
                                self.navigateToHome = true
                            }
                        }
                    }
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

    @ViewBuilder
    private var content: some View {

        if let issuerDisplayName = viewModel.dataModel.metaData?.display?.first?.name,
            let credentialSupported = viewModel.dataModel.metaData?.credentialsSupported
                .keys,
            let firstCredentialName = credentialSupported.first,
            let targetCredential = viewModel.dataModel.metaData?.credentialsSupported[
                firstCredentialName]
        {

            let credentialDisplayName = getCredentialDisplayName(
                credentialSupported: targetCredential)
            let displayNames: [String] = getClaimNames(
                credentialSupported: targetCredential)

            contentWithMetaData(
                issuerDisplayName: issuerDisplayName, credentialDisplayName: credentialDisplayName,
                displayNames: displayNames)
        }
        else {
            EmptyView()
                .onAppear {
                    showErrorDialog = true
                }
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
                do {
                    try viewModel.initialize(rawCredentialOfferString: args.credentialOffer!)
                    try await viewModel.loadData()
                }
                catch {
                    self.showErrorDialog = true
                    print("credential offerが正しくありません")
                    print(error)
                }
            }
        }
        .alert(isPresented: $showErrorDialog) {
            Alert(
                title: Text("error"),
                message: Text("failed_to_show_credential_offer"),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
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
