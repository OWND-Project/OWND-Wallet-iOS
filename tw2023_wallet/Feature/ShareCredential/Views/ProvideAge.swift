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
        let id = presentationDefinition.inputDescriptors[0]
        if let name = id.name, let purpose = id.purpose {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(name).modifier(BodyBlack())
                    Text(purpose).modifier(SubHeadLineGray())
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
            }
        }
        else {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("").modifier(BodyBlack())
                    Text(
                        String(
                            format: NSLocalizedString("age_share_description", comment: ""),
                            self.clientInfo.name)
                    )
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
            }
        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadClientInfoList()
    modelData.loadPresentationDefinitions()
    return ProvideAge(
        clientInfo: modelData.clientInfoList[0],
        presentationDefinition: modelData.presentationDefinitions[0])
}
