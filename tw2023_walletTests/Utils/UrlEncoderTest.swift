//
//  UrlEncoderTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/06/20.
//

import Foundation
import XCTest

@testable import tw2023_wallet

func convertQueryToDictionary(query: String) -> [String: String] {
    var dict = [String: String]()
    let pairs = query.split(separator: "&")
    for pair in pairs {
        let components = pair.split(separator: "=")
        if components.count == 2 {
            let key = String(components[0])
            let value = String(components[1])
            dict[key] = value
        }
    }
    return dict
}

class URLEncodedFormEncoderTests: XCTestCase {
    func testURLEncodedFormEncoder() throws {
        let tokenRequest = OAuthTokenRequest(
            grantType: "authorization_code",
            code: "12345",
            redirectUri: "https://example.com/callback",
            clientId: "client_id",
            preAuthorizedCode: nil,
            txCode: nil
        )

        let encoder = URLEncodedFormEncoder()
        let encodedData = try encoder.encode(tokenRequest)
        guard let encodedString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("unable to convert to String")
            return
        }

        let expectedString =
            "grant_type=authorization_code&code=12345&redirect_uri=https://example.com/callback&client_id=client_id"

        XCTAssertEqual(
            convertQueryToDictionary(query: encodedString),
            convertQueryToDictionary(query: expectedString))
    }

    func testURLEncodedFormEncoderWithOptionalValues() throws {
        let tokenRequest = OAuthTokenRequest(
            grantType: "urn:ietf:params:oauth:grant-type:pre-authorized_code",
            code: nil,
            redirectUri: nil,
            clientId: nil,
            preAuthorizedCode: "1234",
            txCode: "9999"
        )

        let encoder = URLEncodedFormEncoder()
        let encodedData = try encoder.encode(tokenRequest)
        guard let encodedString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("unable to convert to String")
            return
        }

        let expectedString =
            "grant_type=urn:ietf:params:oauth:grant-type:pre-authorized_code&pre-authorized_code=1234&tx_code=9999"

        XCTAssertEqual(
            convertQueryToDictionary(query: encodedString),
            convertQueryToDictionary(query: expectedString))
    }
}
