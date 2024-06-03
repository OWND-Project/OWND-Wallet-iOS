//
//  CredentialList.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct CredentialList: View {
    var viewModel: CredentialListViewModel
    @State private var showingSheet = false
    @State private var navigateTo: String?
    @State private var navigateToMyNumberCard = false
    @State private var navigateToAddCertificates = false

    // full screenから開かれたDetailで必要なのでここでは空の配列を固定で持つ
    @State var dummyPath: [ScreensOnFullScreen] = []

    init(viewModel: CredentialListViewModel = CredentialListViewModel()) {
        self.viewModel = viewModel
        self.showingSheet = false
        self.navigateToMyNumberCard = false
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.dataModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                else if viewModel.dataModel.credentials.isEmpty {
                    GeometryReader { geometry in
                        HStack {
                            Spacer()  // 左側のスペース
                            VStack {
                                Text("no_certificate").modifier(LargeTitleBlack()).padding(
                                    .vertical, 64)
                                Image("tap_to_add")
                                    .resizable()
                                    .aspectRatio(1.6, contentMode: .fit)
                                    .frame(
                                        width: geometry.size.width * 0.85,
                                        height: geometry.size.width * 0.53125
                                    )
                                    .onTapGesture {
                                        navigateToAddCertificates = true  // 遷移をトリガー
                                    }
                            }
                            Spacer()  // 右側のスペース
                        }
                    }
                }
                else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.dataModel.credentials) { credential in
                                VStack(alignment: .leading) {
                                    Text(LocalizedStringKey(credential.credentialType))
                                        .font(.headline)
                                        .padding(.leading, 16)
                                    NavigationLink(
                                        destination: CredentialDetail(
                                            credential: credential,
                                            path: $dummyPath,
                                            deleteAction: {
                                                Task {
                                                    viewModel.deleteCredential(
                                                        credential: credential)
                                                }
                                            }
                                        )
                                    ) {
                                        CredentialRow(credential: credential)
                                            .aspectRatio(1.6, contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    // FloatingActionButtonを追加
                    .overlay(
                        FloatingActionButton(
                            onButtonTap: {
                                navigateToAddCertificates = true  // 遷移をトリガー
                            }
                        ),
                        alignment: .bottomTrailing
                    )
                }
            }
            .navigationBarTitle("Credential List", displayMode: .inline)
            // AddCertificatesへの遷移をトリガーするための条件
            //            .navigationDestination(isPresented: $navigateToAddCertificates) {
            //                AddCertificates()
            //            }
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $navigateToAddCertificates, onDismiss: onDismiss) {
                AddCertificates()
            }
        }
        .onAppear {
            print("onAppear@CredentialList")
            Task {
                viewModel.loadData()
            }
        }
    }

    func onDismiss() {
        // nop
    }
}

#Preview("Empty") {
    CredentialList()
}

#Preview("Not Empty") {
    CredentialList(viewModel: PreviewModel())
}
