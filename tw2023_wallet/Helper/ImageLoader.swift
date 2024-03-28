//
//  ImageLoader.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/30.
//

import SwiftUI

enum ImageLoader {
    static func loadImage(from urlString: String?) -> AnyView? {
        if let urlString = urlString, let url = URL(string: urlString) {
            return AnyView(AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                case .empty, .failure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            })
        } else {
            return nil
        }
    }
}
