//
//  CredentialListForSharing.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/31.
//

import SwiftUI

struct CredentialListForSharing: View {
    @Environment(SharingRequestModel.self) var sharingRequestModel: SharingRequestModel?

    var viewModel: CredentialListViewModel

    init(
        viewModel: CredentialListViewModel = CredentialListViewModel()
    ) {
        print("init credential list")
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if viewModel.dataModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            else {
                ScrollView {
                    ForEach(viewModel.dataModel.credentials) { credential in
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(credential.credentialType.rawValue))
                                .font(.headline)
                                .padding(.leading, 16)
                            NavigationLink(value: ScreensOnFullScreen.credentialDetail(credential))
                            {
                                CredentialRow(credential: credential)
                                    .aspectRatio(1.6, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Credential List", displayMode: .inline)
        .onAppear {
            print("onAppear")
            Task {
                if let model = sharingRequestModel {
                    viewModel.loadData(presentationDefinition: model.presentationDefinition)
                }
                else {
                    viewModel.loadData()
                }
            }
        }
    }
}

#Preview {
    return NavigationStack {
        CredentialListForSharing()
    }
}
