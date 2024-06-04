//
//  SharingToRow.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/02/17.
//

import SwiftUI

struct SharingToRow: View {
    var sharingHistory: CredentialSharingHistory
    var body: some View {
        HStack {
            VStack {
                Text("logo")
            }
            Spacer().frame(width: 20)
            VStack(alignment: .leading) {
                Text("提供先組織名")
                HStack {
                    Text("最終情報提供日:")
                    Spacer()
                    Text("2024/02/17")
                }
            }
        }

    }
}
