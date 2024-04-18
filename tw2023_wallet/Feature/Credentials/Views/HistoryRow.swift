//
//  HistoryRow.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/27.
//

import SwiftUI

struct HistoryRow: View {
    var history: History

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Text(DateFormatterUtil.formatDate(history.createdAt))
                    .modifier(BodyBlack())
                HStack {
                    switch history {
                    case let credential as CredentialSharingHistory:
                        let historyClaims = credential.claims
                        let displayClaims = historyClaims.map{
                            $0.claimKey
                        }
                        Text(localizedDisplayClaims(displayClaims, maxWidth: geometry.size.width))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                            .modifier(SubHeadLineGray())
                        Text(totalItemsLocalized(credential.claims.count))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.bottom, 2)
                            .modifier(SubHeadLineGray())
                    case let idToken as IdTokenSharingHistory:
                        Text("利用者ID")
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                            .modifier(SubHeadLineGray())
                        Text(totalItemsLocalized(1))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.bottom, 2)
                            .modifier(SubHeadLineGray())
                    default:
                        let _ = print("Unexpected history type")
                    }
                }
            }
        }
        .padding(.vertical, 12) // ここで上下のpaddingを追加
    }

    private func localizedDisplayClaims(_ claims: [String], maxWidth: CGFloat) -> String {
        let maxDisplayCount = 3
        var displayString = claims.prefix(maxDisplayCount).map { NSLocalizedString($0, comment: "") }.joined(separator: " | ")

        if claims.count > maxDisplayCount {
            displayString += " ..."
        }

        // 文字列のサイズを計算して、最大幅を超えないように調整
        let font = UIFont.systemFont(ofSize: UIFont.labelFontSize)
        var currentString = ""
        for word in displayString.split(separator: " ") {
            let testString = currentString + (currentString.isEmpty ? "" : " ") + word
            let size = testString.size(withAttributes: [.font: font])
            if size.width > maxWidth {
                break
            }
            currentString = testString
        }

        if currentString.count < displayString.count {
            currentString += " ..."
        }

        return currentString
    }

    private func totalItemsLocalized(_ count: Int) -> String {
        let formatKey = count == 1 ? "TotalItems" : "TotalItems_plural"
        return String.localizedStringWithFormat(NSLocalizedString(formatKey, comment: ""), count)
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadCredentialSharingHistories()
    return HistoryRow(history: modelData.credentialSharingHistories[0])
}

#Preview("multi row") {
    let modelData = ModelData()
    modelData.loadCredentialSharingHistories()
    return Group {
        HistoryRow(history: modelData.credentialSharingHistories[0])
        HistoryRow(history: modelData.credentialSharingHistories[1])
        HistoryRow(history: modelData.credentialSharingHistories[2])
    }
}
