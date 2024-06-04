//
//  ActionButtonWhite.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/12.
//

import SwiftUI

struct ActionButtonWhite: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(LocalizedStringKey(title))
                    .font(.title2)
            }
            .padding(20)
            .frame(maxWidth: .infinity)  // 最小高さを設定
            .foregroundColor(Color("outlinedButtonTextColor"))
            .background(Color("outlinedButtonBackgroundColor"))  // ボタンの背景色
            .cornerRadius(8)  // 角丸の設定
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("outlinedButtonBorderColor"), lineWidth: 1)  // 黒い枠線
            )
        }
    }
}

#Preview {
    ActionButtonWhite(
        title: "select_a_certificate",
        action: {
            print("Button tapped")
        })
}
