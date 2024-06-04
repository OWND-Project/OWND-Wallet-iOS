//
//  MyNumberCard.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

//struct MyNumberCard: View {
//    var body: some View {
//        Text("Identity Credential")
//    }
//}
import SafariServices
import SwiftUI

struct MyNumberCard: View {
    @Environment(\.presentationMode) var presentationMode
    let urlString = "https://ownd-project.com:8443"

    var body: some View {
        EmptyView().onAppear {
            openURLInSafari(urlString: urlString)
        }
    }

    func openURLInSafari(urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            presentationMode.wrappedValue.dismiss()
        }
        else {
            // URLが不正またはSafariが利用できない場合の処理
        }
    }
}

#Preview {
    MyNumberCard()
}
