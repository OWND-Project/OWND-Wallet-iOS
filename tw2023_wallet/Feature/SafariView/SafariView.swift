//
//  SafariView.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/09.
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    SafariView(url: URL(string: "https://www.ownd-project.com/wallet/privacy/index.html")!)
}
