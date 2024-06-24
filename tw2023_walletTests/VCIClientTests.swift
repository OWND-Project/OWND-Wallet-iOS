//
//  VCIClientTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2023/12/27.
//

import XCTest

let issuer = "https://datasign-demo-vci.tunnelto.dev"
let credentialOffer = CredentialOffer.fromString(
    "openid-credential-offer://?credential_offer=%7B%22credential_issuer%22%3A%22https%3A%2F%2Fdatasign-demo-vci.tunnelto.dev%22%2C%22credential_configuration_ids%22%3A%5B%22IdentityCredential%22%5D%2C%22grants%22%3A%7B%22urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Apre-authorized_code%22%3A%7B%22pre-authorized_code%22%3A%22SplxlOBeZQQYbYS6WxSbIA%22%2C%22tx_code%22%3A%7B%7D%7D%7D%7D"
)

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
                let mockData = try? Data(contentsOf: url)
            else {
                XCTFail("Cannot read token_response.json")
                return
            }
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)
            do {
                let tokenRequest = OAuthTokenRequest(
                    grantType: "urn:ietf:params:oauth:grant-type:pre-authorized_code", code: nil,
                    redirectUri: nil, clientId: nil, preAuthorizedCode: "SplxlOBeZQQYbYS6WxSbIA",
                    txCode: "493536"
                )
                let tokenResponse = try await postTokenRequest(
                    to: testURL, with: tokenRequest, using: mockSession)
                XCTAssertEqual(tokenResponse.accessToken, "example-access-token")
                XCTAssertEqual(tokenResponse.cNonce, "example-c-nonce")
            }
            catch {
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
            guard
                let url = Bundle.main.url(
                    forResource: "credential_response", withExtension: "json"),
                let mockData = try? Data(contentsOf: url)
            else {
                XCTFail("Cannot read credential_response.json")
                return
            }
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

            // CredentialRequestのインスタンスを作成
            let credentialRequest = CredentialRequestVcSdJwt(
                format: "vc+sd-jwt",
                proof: JwtProof(proofType: "jwt", jwt: "example-jwt"),
                credentialIdentifier: nil,
                credentialResponseEncryption: nil,
                vct: "IdentityCredential",
                claims: nil
            )

            // postCredentialRequest関数のテスト
            do {
                let credentialResponse = try await postCredentialRequest(
                    credentialRequest, to: testURL, accessToken: "example-access-token",
                    using: mockSession)
                XCTAssertEqual(credentialResponse.cNonce, "example-c-nonce")
            }
            catch {
                XCTFail("Request should not fail")
            }
        }
    }

    func testIssueToken() {
        runAsyncTest {
            // setup mock for `/token`
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)
            let tokenUrl = URL(string: "\(issuer)/token")!
            guard
                let resourceUrl = Bundle.main.url(
                    forResource: "token_response", withExtension: "json"),
                let mockData = try? Data(contentsOf: resourceUrl)
            else {
                XCTFail("Cannot read resource json")
                return
            }
            let response = HTTPURLResponse(
                url: tokenUrl, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[tokenUrl.absoluteString] = (mockData, response)

            // setup metadata
            let decoder = JSONDecoder()
            guard
                let issuerMetadataUrl = Bundle.main.url(
                    forResource: "credential_issuer_metadata_jwt_vc",
                    withExtension: "json"),
                let jsonIssuerMetaData = try? Data(contentsOf: issuerMetadataUrl),
                let authorizationServerMetadataUrl = Bundle.main.url(
                    forResource: "authorization_server",
                    withExtension: "json"),
                let jsonAuthorizationServerData = try? Data(
                    contentsOf: authorizationServerMetadataUrl)

            else {
                XCTFail("Cannot read resource json")
                return

            }
            let credentialIssuerMetadata = try decoder.decode(
                CredentialIssuerMetadata.self, from: jsonIssuerMetaData)
            let authorizationServerMetadata = try decoder.decode(
                AuthorizationServerMetadata.self, from: jsonAuthorizationServerData)
            let metadata = Metadata(
                credentialIssuerMetadata: credentialIssuerMetadata,
                authorizationServerMetadata: authorizationServerMetadata)

            // create credential offer
            guard let offer = credentialOffer else {
                XCTFail("credential offer is not initialized properly")
                return
            }

            do {
                // TokenIssuerのインスタンス生成とissueTokenのテスト
                let vciClient = try await VCIClient(
                    credentialOffer: offer, metaData: metadata)
                let token = try await vciClient.issueToken(txCode: "493536", using: mockSession)
                XCTAssertEqual(token.accessToken, "example-access-token")
                XCTAssertEqual(token.cNonce, "example-c-nonce")
            }
            catch {
                XCTFail("Request should not fail: \(error)")
            }
        }
    }

    func testIssueCredential() {
        runAsyncTest {
            // setup mock for `/credentials`
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)

            let issuer = "https://datasign-demo-vci.tunnelto.dev"
            let credentialUrl = URL(string: "\(issuer)/credentials")!
            guard
                let resourceUrl = Bundle.main.url(
                    forResource: "credential_response", withExtension: "json"),
                let mockData = try? Data(contentsOf: resourceUrl)
            else {
                XCTFail("Cannot read resource json")
                return
            }
            let response = HTTPURLResponse(
                url: credentialUrl, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[credentialUrl.absoluteString] = (mockData, response)

            // setup metadata
            let decoder = JSONDecoder()
            guard
                let issuerMetadataUrl = Bundle.main.url(
                    forResource: "credential_issuer_metadata_sd_jwt",
                    withExtension: "json"),
                let jsonIssuerMetaData = try? Data(contentsOf: issuerMetadataUrl),
                let authorizationServerMetadataUrl = Bundle.main.url(
                    forResource: "authorization_server",
                    withExtension: "json"),
                let jsonAuthorizationServerData = try? Data(
                    contentsOf: authorizationServerMetadataUrl)

            else {
                XCTFail("Cannot read resource json")
                return
            }
            let credentialIssuerMetadata = try decoder.decode(
                CredentialIssuerMetadata.self, from: jsonIssuerMetaData)
            let authorizationServerMetadata = try decoder.decode(
                AuthorizationServerMetadata.self, from: jsonAuthorizationServerData)
            let metadata = Metadata(
                credentialIssuerMetadata: credentialIssuerMetadata,
                authorizationServerMetadata: authorizationServerMetadata)

            // payload generation
            let proof = JwtProof(proofType: "jwt", jwt: "dummy-proof")
            let payload = try createCredentialRequest(
                formatValue: "vc+sd-jwt", credentialType: "UniversityDegreeCredential",
                proofable: proof)

            do {
                guard let offer = credentialOffer else {
                    XCTFail("credential offer is not initialized properly")
                    return
                }

                let vciClient = try await VCIClient(
                    credentialOffer: offer, metaData: metadata)
                let credentialResponse = try await vciClient.issueCredential(
                    payload: payload, accessToken: "dummy-token", using: mockSession)
                XCTAssertEqual(credentialResponse.credential, "example-credential")
                XCTAssertEqual(credentialResponse.cNonce, "example-c-nonce")
                XCTAssertEqual(credentialResponse.cNonceExpiresIn, 86400)
            }
            catch {
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
