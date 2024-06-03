//
//  RecipientDetail.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/02/02.
//

import SwiftUI

struct RecipientDetail: View {
    var sharingHistories: [History]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if let firstHistory = sharingHistories.first {
                        RecipientInfo(sharingHistory: firstHistory)
                    }
                    else {
                        Text("No history available")
                    }
                }
                VStack {
                    Text("information_provision_history")
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                        .modifier(BodyGray())

                    LazyVStack(spacing: 16) {
                        ForEach(sharingHistories, id: \.createdAt) { history in
                            NavigationLink(destination: RecipientClaims(sharingHistory: history)) {
                                HStack {
                                    HistoryRow(history: history)
                                        .padding(.vertical, 6)
                                    Image(systemName: "chevron.forward").modifier(Title3Gray())
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)  // 左右に16dpのパディング
            .navigationBarTitle("SharingTo", displayMode: .inline)
        }
    }
}

#Preview("1") {
    let modelData = ModelData()
    modelData.loadCredentialSharingHistories()
    return RecipientDetail(
        sharingHistories: modelData.credentialSharingHistories
    )
}
