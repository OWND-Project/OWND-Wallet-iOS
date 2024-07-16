//
//  RedirectViewTests.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/07/02.
//

import Foundation
import SwiftUI
import WebKit
import XCTest

@testable import tw2023_wallet

class WebViewTests: XCTestCase {

    var webView: WebView!
    var webViewController: WKWebView!
    var mockCoordinator: MockCoordinator!

    override func setUpWithError() throws {
        webView = WebView(urlString: "https://example.com", cookieStrings: [], onClose: {})
        webViewController = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        mockCoordinator = MockCoordinator(parent: webView, onClose: {})
        webViewController.navigationDelegate = mockCoordinator
    }

    func testWebViewLoadsCorrectURL() {
        let expectation = XCTestExpectation(description: "WebView loads correct URL")

        guard let url = URL(string: webView.urlString) else {
            XCTFail("Invalid URL")
            return
        }

        webViewController.load(URLRequest(url: url))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(self.webViewController.url?.absoluteString, "https://example.com/")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testWebViewSetsCookies() {
        let expectation = XCTestExpectation(description: "WebView sets cookies")

        let cookieString = "testCookie=testValue"
        webView = WebView(
            urlString: "https://example.com", cookieStrings: [cookieString], onClose: {})

        guard let url = URL(string: webView.urlString) else {
            XCTFail("Invalid URL")
            return
        }

        let cookies = webView.cookieStrings.compactMap { cookieString -> HTTPCookie? in
            let parts = cookieString.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }

            let properties: [HTTPCookiePropertyKey: Any] = [
                .name: parts[0],
                .value: parts[1],
                .path: "/",
                .domain: url.host ?? "",
            ]

            return HTTPCookie(properties: properties)
        }

        for cookie in cookies {
            webViewController.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }

        webViewController.load(URLRequest(url: url))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.webViewController.configuration.websiteDataStore.httpCookieStore.getAllCookies {
                cookies in
                XCTAssertTrue(
                    cookies.contains { $0.name == "testCookie" && $0.value == "testValue" })
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testHandleCustomScheme() {
        let expectation = XCTestExpectation(
            description: "WebView handles custom scheme and calls onClose")

        var onCloseCalled = false
        webView = WebView(
            urlString: "https://example.com", cookieStrings: [],
            onClose: {
                onCloseCalled = true
                expectation.fulfill()
            })

        let mockCoordinator = MockCoordinator(parent: webView, onClose: webView.onClose)
        webViewController.navigationDelegate = mockCoordinator

        let url = URL(string: "openid-credential-offer://example")!
        mockCoordinator.handleCustomSchemeInWKWebView(url: url)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertTrue(onCloseCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

}

class MockCoordinator: NSObject, WKNavigationDelegate {
    var parent: WebView
    var onClose: () -> Void

    init(parent: WebView, onClose: @escaping () -> Void) {
        self.parent = parent
        self.onClose = onClose
    }

    func webView(
        _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url, url.scheme == "openid-credential-offer" {
            handleCustomSchemeInWKWebView(url: url)
            decisionHandler(.cancel)
            return
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
