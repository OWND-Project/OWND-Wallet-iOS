//
//  IdenticonView.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/10.
//

import IGIdenticon
import SwiftUI

struct IdenticonView: UIViewRepresentable {
    var hashString: String
    var size: CGSize

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = Identicon().icon(from: hashString, size: size)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Identiconを更新する必要がある場合はここで行う
    }
}

#Preview {
    IdenticonView(hashString: "b58996c504c5638798eb6b511e6f49af", size: CGSize(width: 100, height: 100))
}
