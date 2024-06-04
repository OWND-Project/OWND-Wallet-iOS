//
//  ActionButton.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/12.
//

import SwiftUI

struct ActionButtonBlack: View {
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
            .frame(height: 56)  // 画面幅の90%に設定
            .background(Color("filledButtonBackgroundColor"))  // ボタンの背景色
            .foregroundColor(Color("filledButtonTextColor"))  // テキストの色
            .cornerRadius(8)  // 角丸の設定
        }
    }
}

#Preview {
    ActionButtonBlack(
        title: "provide_information",
        action: {
            print("Button tapped")
        })
}
