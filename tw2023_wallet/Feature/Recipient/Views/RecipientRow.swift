//
//  RecipientLow.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/30.
//

import SwiftUI

struct RecipientRow: View {
    var sharingHistory: SharingHistory

    var body: some View {
        HStack {
            Group {
                if let logoView = sharingHistory.logoImage {
                    logoView
                } else {
                    Color.clear
                }
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 0) {
                // オプショナルバインディングを使用して安全にアンラップ
                if let rpName = sharingHistory.rpName {
                    Text(rpName)
                        .modifier(BodyBlack())
                } else {
                    // rpNameがnilの場合に表示するデフォルトテキスト
                    Text("Unknown")
                        .modifier(BodyBlack())
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
