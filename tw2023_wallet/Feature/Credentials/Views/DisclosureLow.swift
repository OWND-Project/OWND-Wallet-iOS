//
//  DisclosureLow.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/26.
//

import SwiftUI

struct DisclosureLow: View {
    var disclosure: (key: String, value: String)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(disclosure.key))
                .padding(.bottom, 2)
                .modifier(SubHeadLineGray())

            Text(disclosure.value)
                .padding(.bottom, 2)
                .modifier(BodyBlack())
        }
        .padding(.vertical, 6) // 上下のpaddingに対応
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadCredentials()
    let disclosure = modelData.credentials.first?.disclosure?.first
    return DisclosureLow(disclosure: disclosure!)
}
