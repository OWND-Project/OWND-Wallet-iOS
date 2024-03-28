//
//  MockURLProtocol.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: (Data?, HTTPURLResponse?)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let url = request.url,
           let (data, response) = MockURLProtocol.mockResponses[url] {
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
    
    override func stopLoading() {
        // 何もしない
    }
}
