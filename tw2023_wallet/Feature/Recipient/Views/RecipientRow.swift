//
//  RecipientLow.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/30.
//

import SwiftUI

struct RecipientRow: View {
    var sharingHistory: History

    var body: some View {
        HStack {
            Group {
                switch sharingHistory {
                case let credential as CredentialSharingHistory:
                    if let logoView = credential.logoImage {
                        logoView
                    } else {
                        Color.clear
                    }
                case let idToken as IdTokenSharingHistory:
                    Color.clear // todo: add `logoUri` to IdTokenSharingHistory
                default:
                    Color.clear
                }
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 0) {
                let defaultText = Text("Unknown").modifier(BodyBlack())
                switch sharingHistory {
                case let credential as CredentialSharingHistory:
                    if (credential.rpName != "") {
                        Text(credential.rpName)
                            .modifier(BodyBlack())
                    } else {
                        defaultText
                    }
                case let idToken as IdTokenSharingHistory:
                    Text(idToken.rp) // todo: add `rpName` to IdTokenSharingHistory
                        .modifier(BodyBlack())
                default:
                    defaultText
                }
                HStack {
                    (Text(LocalizedStringKey("date_of_last_information")) + Text(" :"))
                        .modifier(BodyGray())
                    Spacer()
                    Text(DateFormatterUtil.formatDate(sharingHistory.createdAt))
                        .modifier(BodyGray())
                    Image(systemName: "chevron.forward").modifier(Title3Gray())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // 左寄せ
            Spacer()
        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadSharingHistories()
    return RecipientRow(
        sharingHistory: modelData.sharingHistories[0]
    )
}

