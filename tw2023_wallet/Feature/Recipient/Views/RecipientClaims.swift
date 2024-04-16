//
//  RecipientClaims.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/02/18.
//

import SwiftUI


struct RecipientClaims: View {
    @StateObject var viewModel = RecipientClaimsViewModel()
    var sharingHistory: CredentialSharingHistory
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            LazyVStack(spacing: 16) {
                                Text(viewModel.rpName)
                                    .padding(.top, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                
                                ForEach(viewModel.claimsInfo, id: \.claimValue) { info in
                                    // workaround for `is_older_than_??`
                                    let testLocalization = NSLocalizedString(info.claimKey, comment: "")
                                    if (testLocalization != info.claimValue) {
                                        Text(testLocalization)
                                    }else{
                                        Text(info.claimValue)
                                    }
                                   if let value = info.purpose {
                                       if (value != ""){
                                         Text(value)
                                            .modifier(BodyGray())
                                       }
                                    }
                                    Spacer()
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 16)
                        .navigationBarTitle(viewModel.title, displayMode: .inline)
                    }
                }
            }.onAppear {
                viewModel.loadClaimsInfo(sharingHistory: sharingHistory)
            }
        } 
    }
}


#Preview {
    let modelData = ModelData()
    modelData.loadSharingHistories()
    return RecipientClaims(
        viewModel: RecipientClaimsPreviewModel(),
        sharingHistory: modelData.sharingHistories[0])
}
