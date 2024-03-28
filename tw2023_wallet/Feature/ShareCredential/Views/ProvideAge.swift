//
//  ProvideAge.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/12.
//

import SwiftUI

struct ProvideAge: View {
    var clientInfo: ClientInfo
    var presentationDefinition: PresentationDefinition

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey(presentationDefinition.inputDescriptors[0].purpose!))
                    .modifier(BodyBlack())
                Text(String(format: NSLocalizedString("age_share_description", comment: ""), self.clientInfo.name))
                    .modifier(SubHeadLineGray())
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading) // 左寄せ
        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadClientInfoList()
    modelData.loadPresentationDefinitions()
    return ProvideAge(clientInfo: modelData.clientInfoList[0], presentationDefinition: modelData.presentationDefinitions[0])
}
