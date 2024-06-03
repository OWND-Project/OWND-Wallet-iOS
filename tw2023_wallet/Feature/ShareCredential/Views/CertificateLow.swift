//
//  CertificateLow.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/11.
//

import SwiftUI

// certificateInfoの中身をループで表示するview
// 今回は使わない
struct CertificateLow: View {
    var certificateInfo: CertificateInfo

    var body: some View {
        let mirror = Mirror(reflecting: certificateInfo)
        ForEach(Array(mirror.children), id: \.label) { child in
            if let label = child.label, let value = child.value as? String, !value.isEmpty,
                label != "organization" && label != "issuer"
            {  // 特定のラベルを除外
                VStack(alignment: .leading, spacing: 0) {
                    Text(LocalizedStringKey(label))
                        .padding(.bottom, 2)
                        .modifier(SubHeadLineGray())

                    Text(value)
                        .padding(.bottom, 2)
                        .modifier(BodyBlack())
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadClientInfoList()
    let certificateInfo = modelData.clientInfoList.first?.certificateInfo
    return CertificateLow(certificateInfo: certificateInfo!)
}
