//
//  CredentialDetail.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct CredentialDetail: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(SharingRequestModel.self) var sharingRequestModel: SharingRequestModel?
    // @Environment(CredentialSharingModel.self) var credentialSharingModel: CredentialSharingModel?
    var credential: Credential
    var viewModel: CredentialDetailViewModel
    var deleteAction: (() -> Void)?

    @State var vpMode: Bool = false
    @State private var showingQRCodeModal: Bool = false
    @State private var navigateToIssuerDetail: Bool = false
    @Binding var path: [ScreensOnFullScreen]
    @State private var showAlert = false

    init(
        viewModel: CredentialDetailViewModel = CredentialDetailViewModel(),
        credential: Credential,
        path: Binding<[ScreensOnFullScreen]>,
        deleteAction: (() -> Void)? = nil
    ) {
        print("init")
        self.viewModel = viewModel
        self.credential = credential
        self._path = path
        self.deleteAction = deleteAction
    }

    var body: some View {
        Group {
            if viewModel.dataModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            else {
                ScrollView {
                    VStack {
                        // ------------------------- card section -------------------------
                        CredentialRow(credential: self.credential)
                            .aspectRatio(1.6, contentMode: .fit)
                            .frame(maxWidth: .infinity)

                        // ------------------------- issuer section -------------------------
                        let issuedByText = String(
                            format: NSLocalizedString("IssuedBy", comment: ""),
                            credential.issuerDisplayName)
                        Text(issuedByText)
                            .underline()
                            .modifier(BodyGray())
                            .onTapGesture {
                                self.navigateToIssuerDetail = true
                            }
                            .padding(.vertical, 8)

                        // ------------------------- QR code section -------------------------
                        if !vpMode {
                            // QR表示画面のリンク
                            if self.credential.format == "jwt_vc_json" {
                                Text("display_qr_code")
                                    .underline()
                                    .modifier(BodyGray())
                                    .padding(.vertical, 8)
                                    .onTapGesture {
                                        self.showingQRCodeModal = true
                                    }
                                    .padding(.vertical, 8)
                            }
                        }

                        // ------------------------- claims section -------------------------
                        if !vpMode {
                            Text("Contents of this certificate")
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                                .modifier(BodyGray())

                            if let disclosureDict = credential.disclosure {
                                ForEach(disclosureDict.sorted(by: { $0.key < $1.key }), id: \.key) {
                                    key, value in
                                    DisclosureLow(disclosure: (key: key, value: value))
                                }
                            }
                        }
                        else {
                            // sharing claims
                            Text("Sharing Contents of this certificate")
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .modifier(BodyGray())
                            ForEach(viewModel.claimsToDisclose, id: \.self.id) { it in
                                DisclosureLow(disclosure: (key: it.key!, value: it.value!))
                            }

                            // not sharing claims
                            Text("Not Sharing Contents of this certificate")
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .modifier(BodyGray())
                            ForEach(viewModel.claimsNotToDisclosed, id: \.self.id) { it in
                                DisclosureLow(disclosure: (key: it.key!, value: it.value!))
                            }

                        }

                        // ------------------------- history section -------------------------
                        if !vpMode {
                            Text("History of information provided")
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                                .modifier(BodyGray())
                            LazyVStack(spacing: 16) {
                                ForEach(self.viewModel.dataModel.sharingHistories, id: \.createdAt)
                                { history in
                                    HistoryRow(history: history)
                                        .padding(.vertical, 6)
                                }
                            }
                        }

                        // ------------------------- button section -------------------------
                        if vpMode {
                            ActionButtonBlack(
                                title: "Select This Credential",
                                action: {
                                    let submissionCredential = viewModel.getSubmissionCredential(
                                        credential: credential)
                                    sharingRequestModel?.setSelectedCredential(
                                        data: submissionCredential,
                                        metadata: credential.metaData
                                    )
                                    path.removeLast(2)
                                }
                            )
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 16)  // 左右に16dpのパディング
                    .padding(.vertical, 16)
                }
                .navigationTitle(LocalizedStringKey(self.credential.credentialType))
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $navigateToIssuerDetail) {
                    IssuerDetail(credential: credential)
                }
                .sheet(
                    isPresented: $showingQRCodeModal,
                    content: {
                        DisplayQRCode(credential: credential)
                    }
                )
                .toolbar {
                    if deleteAction != nil {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu(
                                content: {
                                    Button(action: {
                                        showAlert = true
                                    }) {
                                        Text("Delete")
                                    }
                                },
                                label: {
                                    Image(systemName: "ellipsis")
                                })
                        }
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Confirm To Delete"),
                        message: Text("Are you sure to delete this credential?"),
                        primaryButton: .destructive(Text("Delete")) {
                            if let action = deleteAction {
                                action()
                            }
                            presentationMode.wrappedValue.dismiss()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .onAppear {
            print("onAppear")
            Task {
                if let model = sharingRequestModel, let pd = model.presentationDefinition {
                    self.vpMode = true
                    await viewModel.loadData(credential: credential, presentationDefinition: pd)
                }
                else {
                    await viewModel.loadData(credential: credential)
                }
            }
        }
    }
}

#Preview("1. format: sd-jwt, card: image") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return CredentialDetail(
        viewModel: DetailPreviewModel(),
        credential: modelData.credentials[0],
        path: .constant([])
    )
}

#Preview("2. format: sd-jwt, card: bg-color") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return CredentialDetail(
        viewModel: DetailPreviewModel(),
        credential: modelData.credentials[1],
        path: .constant([])
    )
}

#Preview("3. format: jwt-vc-json") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return CredentialDetail(
        viewModel: DetailPreviewModel(),
        credential: modelData.credentials[2],
        path: .constant([])
    )
}

#Preview("4. mode: vp-sharing") {
    let modelData = ModelData()
    modelData.loadCredentials()
    let viewModel = DetailVPModePreviewModel()
    let pd = viewModel.dummyPresentationDefinition()
    return CredentialDetail(
        viewModel: viewModel,
        credential: modelData.credentials[2],
        path: .constant([])
    ).environment(SharingRequestModel(presentationDefinition: pd))
}
