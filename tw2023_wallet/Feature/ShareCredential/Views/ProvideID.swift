//
//  ProvideID.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/12.
//

import SwiftUI

struct ProvideID: View {
    var clientInfo: ClientInfo

    var body: some View {
        HStack {
            let identiconText = clientInfo.jwkThumbprint
            IdenticonView(hashString: identiconText, size: CGSize(width: 80, height: 80))
                .frame(width: 80, height: 80)
            VStack(alignment: .leading, spacing: 0) {
                Text(
                    String(format: NSLocalizedString("user_id", comment: ""), self.clientInfo.name)
                )
                .modifier(BodyBlack())
                Text("#\(identiconText)")
                    .modifier(BodyBlack())
                    .padding(.bottom, 9)
                Text(
                    String(
                        format: NSLocalizedString("id_share_description", comment: ""),
                        self.clientInfo.name)
                ).modifier(SubHeadLineGray())
            }
            .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadClientInfoList()
    modelData.loadPresentationDefinitions()
    return ProvideID(clientInfo: modelData.clientInfoList[0])
}
