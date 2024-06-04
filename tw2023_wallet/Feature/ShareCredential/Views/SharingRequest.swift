//
//  SharingRequest.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import SwiftUI

enum SharingScreen {
    case sharingRequest
    case credentialList
    case credentialDetail
}

struct SharingRequest: View {
    @Environment(\.presentationMode) var presentationMode
    //    @Environment(SharingCredentialArgs.self) var args
    @Environment(SharingRequestModel.self) var sharingRequestModel
    @State var viewModel: SharingRequestViewModel = SharingRequestViewModel()
    var args: SharingCredentialArgs

    @State var authenticated = false
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""

    @State private var path: [ScreensOnFullScreen] = []
    @State var proofBy = ""

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { _ in
                Group {
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ProgressView().progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    else {
                        if let clientInfo = viewModel.clientInfo {
                            ScrollView {
                                VStack {
                                    HStack {
                                        Button("Cancel") {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                        .padding(.vertical, 16)
                                        Spacer()
                                    }
                                    // ------------ title section ------------
                                    let titleKey =
                                        viewModel.presentationDefinition != nil
                                        ? "provide_the_information_necessary_to_start_using"
                                        : "provide_the_information_required_to_register"
                                    Text(
                                        String(
                                            format: NSLocalizedString(titleKey, comment: ""),
                                            clientInfo.name)
                                    )
                                    .modifier(Title3Black())
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    // ------------ logo to logo section ------------
                                    HStack {
                                        Image("logo_ownd")
                                            .padding(.trailing, 8)
                                        Image(systemName: "arrow.forward")
                                            .modifier(TitleGray())
                                            .fontWeight(.black)
                                            .padding(.horizontal, 8)
                                        Group {
                                            if let logoView = clientInfo.logoImage {
                                                logoView
                                            }
                                            else {
                                                Color.clear
                                            }
                                        }
                                        .frame(width: 70, height: 70)
                                        .padding(.horizontal, 8)
                                    }
                                    .padding(.vertical, 16)

                                    // ------------ sharing data info section ------------
                                    Text(
                                        String(
                                            format: NSLocalizedString(
                                                "information_provided_to", comment: ""),
                                            clientInfo.name)
                                    )
                                    .modifier(BodyGray())
                                    .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                                    .padding(.top, 16)

                                    if let presentationDefinition = viewModel.presentationDefinition
                                    {
                                        ProvideAge(
                                            clientInfo: clientInfo,
                                            presentationDefinition: presentationDefinition)
                                        if viewModel.selectedCredential {
                                            // ------------ change link ------------
                                            StatusBox(displayText: $proofBy, status: .success)
                                            Text("change_credential")
                                                .modifier(BodyBlack())
                                                .underline()
                                                .padding(.vertical, 8)
                                                .onTapGesture {
                                                    viewModel.selectedCredential = false
                                                    sharingRequestModel.data = nil
                                                    path.append(ScreensOnFullScreen.credentialList)
                                                }
                                        }
                                        else {
                                            StatusBox(
                                                displayText: .constant("no_certificate_selected"),
                                                status: .warning)
                                            ActionButtonWhite(
                                                title: "select_a_certificate",
                                                action: {
                                                    path.append(ScreensOnFullScreen.credentialList)
                                                })
                                        }
                                    }
                                    else {
                                        ProvideID(clientInfo: clientInfo)
                                    }

                                    // ------------ recipient org info section ------------
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("recipient _organization_information")
                                            .modifier(BodyGray())
                                        RecipientOrgInfo(clientInfo: clientInfo)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                                    .padding(.vertical, 16)

                                    // ------------ sharing button section ------------
                                    if viewModel.presentationDefinition == nil
                                        || viewModel.selectedCredential
                                    {
                                        ActionButtonBlack(
                                            title: "provide_information",
                                            action: {
                                                Task {
                                                    if viewModel.presentationDefinition != nil,
                                                        viewModel.selectedCredential
                                                    {
                                                        let result = await viewModel.shareVpToken(
                                                            credentials: [sharingRequestModel.data!]
                                                        )
                                                        switch result {
                                                            case .success(let postResult):
                                                                print("VP Token sharing succeeded.")
                                                                if postResult.location != nil {
                                                                    sharingRequestModel.postResult =
                                                                        postResult
                                                                }
                                                                showAlert = true
                                                                alertTitle =
                                                                    "VP Token sharing succeeded."
                                                            case .failure(let error):
                                                                print(
                                                                    "VP Token sharing failed with error: \(error)"
                                                                )
                                                                showAlert = true
                                                        }
                                                    }
                                                    else {
                                                        let result = await viewModel.shareIdToken()
                                                        switch result {
                                                            case .success(let postResult):
                                                                print("ID Token sharing succeeded.")
                                                                if postResult.location != nil {
                                                                    sharingRequestModel.postResult =
                                                                        postResult
                                                                }
                                                                showAlert = true
                                                                alertTitle =
                                                                    "ID Token sharing succeeded."
                                                            case .failure(let error):
                                                                print(
                                                                    "ID Token sharing failed with error: \(error)"
                                                                )
                                                                showAlert = true
                                                        }
                                                    }
                                                }
                                            }
                                        )
                                        .padding(.vertical, 16)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .onChange(of: sharingRequestModel.data) {
                if sharingRequestModel.data != nil {
                    viewModel.selectedCredential = true
                    if let submission = sharingRequestModel.data,
                        let metadata = sharingRequestModel.metadata
                    {
                        if let credentialSupported = VCIMetadataUtil.findMatchingCredentials(
                            format: submission.format,
                            types: submission.types,
                            metadata: metadata
                        ) {
                            if let display = credentialSupported.display {
                                proofBy = String(
                                    format: NSLocalizedString("proof_by", comment: ""),
                                    display[0].name!)
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.clientInfo) {
                if let clientInfo = viewModel.clientInfo {
                    print("client info changed: \(clientInfo)")
                }
            }
            .navigationDestination(for: ScreensOnFullScreen.self) { screen in
                switch screen {
                    case .credentialList:
                        CredentialListForSharing()
                    case .credentialDetail(let credential):
                        CredentialDetail(credential: credential, path: $path)
                    default:
                        EmptyView()
                }
            }
            .onAppear {
                Task {
                    print("accessPairwiseAccountManager")
                    if !authenticated {
                        let b = await viewModel.accessPairwiseAccountManager()
                        if b {
                            authenticated = true
                            if let url = args.url {
                                await viewModel.loadData(url)
                                if viewModel.presentationDefinition != nil {
                                    sharingRequestModel.presentationDefinition =
                                        viewModel.presentationDefinition
                                }
                                showAlert = viewModel.showAlert
                                alertTitle = viewModel.alertTitle
                                alertMessage = viewModel.alertMessage
                            }
                        }
                        else {
                            print("showAuthenticationFailedAlert")
                            alertTitle = "Authentication Failed"
                            alertMessage = "Unable to authenticate. Please try again."
                            showAlert = true
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
}

#Preview("ID Token Sharing") {
    let args = SharingCredentialArgs()
    args.url = "openid://xxx"
    let viewModel = SharingRequestPreviewModel()
    return SharingRequest(viewModel: viewModel, args: args)
        .environment(SharingRequestModel())
    // return SharingRequest(viewModel: viewModel).environment(args)
}

#Preview("VP Sharing before credential is selected") {
    let args = SharingCredentialArgs()
    args.url = "openid://xxx"
    let viewModel = SharingRequestVPPreviewModel()
    return SharingRequest(viewModel: viewModel, args: args)
        .environment(SharingRequestModel())
    // return SharingRequest(viewModel: viewModel).environment(args)
}

#Preview("VP Sharing") {
    let args = SharingCredentialArgs()
    args.url = "openid://xxx"
    let viewModel = SharingRequestVPPreviewModel()
    viewModel.selectedCredential = true
    return SharingRequest(viewModel: viewModel, args: args)
        .environment(SharingRequestModel())
    // return SharingRequest(viewModel: viewModel).environment(args)
}

#Preview("Biometric Error") {
    let args = SharingCredentialArgs()
    args.url = "openid://xxx"
    let viewModel = SharingRequestBiometricErrorPreviewModel()
    return SharingRequest(viewModel: viewModel, args: args)
        .environment(SharingRequestModel())
    // return SharingRequest(viewModel: viewModel).environment(args)
}

#Preview("Sharing Error") {
    let args = SharingCredentialArgs()
    args.url = "openid://xxx"
    let viewModel = SharingRequestLoadDataErrorPreviewModel()
    return SharingRequest(viewModel: viewModel, args: args)
        .environment(SharingRequestModel())
}
