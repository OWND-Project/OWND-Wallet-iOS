//
//  RedirectView.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/05.
//

import SwiftUI
import SafariServices
import WebKit

struct WebView: UIViewRepresentable {
    let urlString: String
    let cookieStrings: [String]
    // let cookies: [HTTPCookie]

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        let cookies = cookieStrings.compactMap { cookieString -> HTTPCookie? in
            // シンプルな`key=value`形式を想定
            let parts = cookieString.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }

            let properties: [HTTPCookiePropertyKey: Any] = [
                .name: parts[0],
                .value: parts[1],
                .path: "/",
                .domain: url.host ?? ""
            ]

            // 必要に応じて`Secure`やその他の属性を設定
            return HTTPCookie(properties: properties)
        }
        
        // クッキーをWebViewのセッションに設定
        let dataStore = webView.configuration.websiteDataStore
        cookies.forEach { cookie in
            dataStore.httpCookieStore.setCookie(cookie)
        }

        // リクエストを実行
        webView.load(URLRequest(url: url))
    }
}

struct RedirectView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    var urlString: String
    // var cookies: [HTTPCookie] = []
    var cookieStrings: [String] = []
    
    var body: some View {
        WebView(urlString: urlString, cookieStrings: cookieStrings)
//        EmptyView().onAppear {
//            openURLInSafari(urlString: urlString)
//        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

//    func openURLWithCookies(urlString: String, cookieValue: String) {
//        guard let url = URL(string: urlString) else {
//            print("Invalid URL specified.")
//            return
//        }
//        
//        let webView = WKWebView(frame: .zero)
//        let cookie = HTTPCookie(properties: [
//            .domain: url.host!,
//            .path: "/",
//            .name: "username_mapping_session",
//            .value: cookieValue,
//            .secure: "FALSE",
//            .expires: NSDate(timeIntervalSinceNow: 3600)
//        ])!
//
//        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
//            DispatchQueue.main.async {
//                webView.load(URLRequest(url: url))
//                // WKWebViewを表示するためのUI処理をここに実装
//            }
//        }
//    }
    
    func openURLInSafari(urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            presentationMode.wrappedValue.dismiss()
        } else {
            print("invalid url is specified.")
            alertTitle = "URLが不正です"
            alertMessage = urlString
            showAlert = true
        }
    }
}

#Preview {
    RedirectView(urlString: "https://example.com")
}
