//
//  VCIClientTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2023/12/27.
//

import XCTest

let issuer = "https://datasign-demo-vci.tunnelto.dev"

let credentialOfferJson = """
{
    "credential_issuer": "\(issuer)",
    "credentials": [
        "IdentityCredential"
    ],
    "grants": {
        "urn:ietf:params:oauth:grant-type:pre-authorized_code": {
            "pre-authorized_code": "SplxlOBeZQQYbYS6WxSbIA",
            "user_pin_required": true
        }
    }
}
"""

final class VCIClientTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }


    func testPostTokenRequest() {
        runAsyncTest {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)
            
            let testURL = URL(string: "https://example.com/token")!
            guard let url = Bundle.main.url(forResource: "token_response", withExtension: "json"),
                  let mockData = try? Data(contentsOf: url) else {
                XCTFail("Cannot read token_response.json")
                return
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)
            do {
                let parameters: [String: String] = [
                    "grant_type": "urn:ietf:params:oauth:grant-type:pre-authorized_code",
                    "pre-authorized_code": "SplxlOBeZQQYbYS6WxSbIA",
                    "user_pin": "493536"
                ]
                let tokenResponse = try await postTokenRequest(to: testURL, with: parameters, using: mockSession)
                XCTAssertEqual(tokenResponse.accessToken, "example-access-token")
                XCTAssertEqual(tokenResponse.cNonce, "example-c-nonce")
            } catch {
                XCTFail("Request should not fail")
            }
        }
    }
    
    func testPostCredentialRequest() {
        runAsyncTest {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)

            // テスト用URLとモックレスポンスデータの設定
            let testURL = URL(string: "https://example.com/credential")!
            guard let url = Bundle.main.url(forResource: "credential_response", withExtension: "json"),
                  let mockData = try? Data(contentsOf: url) else {
                XCTFail("Cannot read credential_response.json")
                return
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

            // CredentialRequestのインスタンスを作成
            let credentialRequest = CredentialRequestSdJwtVc(
                format: "vc+sd-jwt",
                proof: Proof(proofType: "jwt", jwt: "example-jwt"),
                credentialDefinition: ["vct": "IdentityCredential"]
            )

            // postCredentialRequest関数のテスト
            do {
                let credentialResponse = try await postCredentialRequest(credentialRequest, to: testURL, accessToken: "example-access-token", using: mockSession)
                XCTAssertEqual(credentialResponse.format, "jwt_vc_json")
                XCTAssertEqual(credentialResponse.cNonce, "example-c-nonce")
            } catch {
                XCTFail("Request should not fail")
            }
        }
    }
    
    func testIssueToken() {
        runAsyncTest {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)

            let testURL1 = URL(string: "\(issuer)/.well-known/openid-credential-issuer")!
            let testURL2 = URL(string: "\(issuer)/.well-known/oauth-authorization-server")!
            let testURL3 = URL(string: "\(issuer)/token")!
            guard let url = Bundle.main.url(forResource: "credential_issuer_metadata_jwt_vc", withExtension: "json"),
                  let mockData1 = try? Data(contentsOf: url),
                  let url2 = Bundle.main.url(forResource: "authorization_server", withExtension: "json"),
                  let mockData2 = try? Data(contentsOf: url2),
                  let url3 = Bundle.main.url(forResource: "token_response", withExtension: "json"),
                  let mockData3 = try? Data(contentsOf: url3) else {
                XCTFail("Cannot read resource json")
                return
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[testURL1.absoluteString] = (mockData1, response)
            MockURLProtocol.mockResponses[testURL2.absoluteString] = (mockData2, response)
            MockURLProtocol.mockResponses[testURL3.absoluteString] = (mockData3, response)

            do {
                // TokenIssuerのインスタンス生成とissueTokenのテスト
                let vciClient = try await VCIClient(credentialOfferJson: credentialOfferJson, using: mockSession)
                let token = try await vciClient.issueToken(userPin: "493536", using: mockSession)
                XCTAssertEqual(token.accessToken, "example-access-token")
                XCTAssertEqual(token.cNonce, "example-c-nonce")
            } catch {
                XCTFail("Request should not fail: \(error)")
            }
        }
    }
    
    func testIssueCredential() {
        runAsyncTest {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)

            let issuer = "https://datasign-demo-vci.tunnelto.dev"
            let testURL1 = URL(string: "\(issuer)/.well-known/openid-credential-issuer")!
            let testURL2 = URL(string: "\(issuer)/.well-known/oauth-authorization-server")!
            let testURL3 = URL(string: "\(issuer)/credentials")!
            guard let url = Bundle.main.url(forResource: "credential_issuer_metadata_jwt_vc", withExtension: "json"),
                  let mockData1 = try? Data(contentsOf: url),
                  let url2 = Bundle.main.url(forResource: "authorization_server", withExtension: "json"),
                  let mockData2 = try? Data(contentsOf: url2),
                  let url3 = Bundle.main.url(forResource: "credential_response", withExtension: "json"),
                  let mockData3 = try? Data(contentsOf: url3) else {
                XCTFail("Cannot read resource json")
                return
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[testURL1.absoluteString] = (mockData1, response)
            MockURLProtocol.mockResponses[testURL2.absoluteString] = (mockData2, response)
            MockURLProtocol.mockResponses[testURL3.absoluteString] = (mockData3, response)

            let proof = Proof(proofType: "jwt", jwt: "dummy-proof")
            let payload = createCredentialRequest(formatValue: "vc+sd-jwt", vctValue: "UniversityDegreeCredential", proof: proof)
            
            do {
                let vciClient = try await VCIClient(credentialOfferJson: credentialOfferJson, using: mockSession)
                let credentialResponse = try await vciClient.issueCredential(payload: payload, accessToken: "dummy-token", using: mockSession)
                XCTAssertEqual(credentialResponse.format, "jwt_vc_json")
                XCTAssertEqual(credentialResponse.credential, "example-credential")
                XCTAssertEqual(credentialResponse.cNonce, "example-c-nonce")
                XCTAssertEqual(credentialResponse.cNonceExpiresIn, 86400)
            } catch {
                XCTFail("Request should not fail: \(error)")
            }
        }
    }
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
