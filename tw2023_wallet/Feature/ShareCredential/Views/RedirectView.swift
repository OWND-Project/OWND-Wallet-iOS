//
//  RedirectView.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/05.
//

import SafariServices
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let urlString: String
    let cookieStrings: [String]
    var onClose: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        return webView
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
                .domain: url.host ?? "",
            ]

            // 必要に応じて`Secure`やその他の属性を設定
            return HTTPCookie(properties: properties)
        }

        // クッキーをWebViewのセッションに設定
        let dataStore = webView.configuration.websiteDataStore
        for cookie in cookies {
            dataStore.httpCookieStore.setCookie(cookie)
        }

        // リクエストを実行
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onClose: onClose)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var onClose: () -> Void

        init(_ parent: WebView, onClose: @escaping () -> Void) {
            self.parent = parent
            self.onClose = onClose
        }

        func webView(
            _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if let url = navigationAction.request.url {
                if url.scheme == "openid-credential-offer" {
                    handleCustomSchemeInWKWebView(url: url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func handleCustomSchemeInWKWebView(url: URL) {
            print("Handling custom scheme URL: \(url)")
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        DispatchQueue.main.async {
                            self.onClose()
                        }
                    }
                    else {
                        print("Failed to open URL: \(url)")
                    }
                }
            }
            else {
                print("Cannot open URL: \(url)")
            }
        }
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
        WebView(urlString: urlString, cookieStrings: cookieStrings) {
            self.presentationMode.wrappedValue.dismiss()
        }
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

    func openURLInSafari(urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            presentationMode.wrappedValue.dismiss()
        }
        else {
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
