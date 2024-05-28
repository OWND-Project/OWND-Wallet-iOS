//
//  MockURLProtocol.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

class MockURLProtocol: URLProtocol {
    static var mockResponses: [String: (Data?, HTTPURLResponse?)] = [:]
    static var lastRequest: URLRequest?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let url = request.url,
           let (data, response) = matchMockResponse(for: url.absoluteString) {
            
            MockURLProtocol.lastRequest = request
            
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        } else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
        }
    }
    
    private func matchMockResponse(for urlString: String) -> (Data?, HTTPURLResponse?)? {
        for (pattern, response) in MockURLProtocol.mockResponses {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: urlString.utf16.count)
                if regex.firstMatch(in: urlString, options: [], range: range) != nil {
                    return response
                }
            }
        }
        return nil
    }
    
    override func stopLoading() {
        // 何もしない
    }
}
