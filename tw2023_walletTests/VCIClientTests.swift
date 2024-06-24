//
//  VCIClientTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2023/12/27.
//

import XCTest

final class DecodingCredentialOfferTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodeFilledCredentialOffer() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_offer_filled")
        let decoder = JSONDecoder()
        let credentialOffer = try decoder.decode(CredentialOffer.self, from: jsonData)

        XCTAssertEqual(credentialOffer.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        XCTAssertFalse(credentialOffer.credentialConfigurationIds.isEmpty)
        XCTAssertEqual(credentialOffer.credentialConfigurationIds[0], "IdentityCredential")

        let grants = credentialOffer.grants
        XCTAssertEqual(grants?.authorizationCode?.issuerState, "eyJhbGciOiJSU0Et...FYUaBy")

        XCTAssertEqual(grants?.preAuthorizedCode?.preAuthorizedCode, "adhjhdjajkdkhjhdj")
        XCTAssertEqual(grants?.preAuthorizedCode?.txCode?.inputMode, "numeric")
        XCTAssertEqual(grants?.preAuthorizedCode?.txCode?.length, 4)
        XCTAssertEqual(grants?.preAuthorizedCode?.txCode?.description, "description")
        XCTAssertEqual(grants?.preAuthorizedCode?.interval, 10)
        XCTAssertEqual(
            grants?.preAuthorizedCode?.authorizationServer, "https://datasign-demo-vci.tunnelto.dev"
        )
    }

    func testDecodeMinimumCredentialOffer() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_offer_minimum")
        let decoder = JSONDecoder()
        let credentialOffer = try decoder.decode(CredentialOffer.self, from: jsonData)

        XCTAssertEqual(credentialOffer.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        XCTAssertFalse(credentialOffer.credentialConfigurationIds.isEmpty)
        XCTAssertEqual(credentialOffer.credentialConfigurationIds[0], "IdentityCredential")

        XCTAssertNil(credentialOffer.grants)
    }
    func testDecodeCredentialOfferWithTxCode() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_offer_tx_code_required")
        let decoder = JSONDecoder()
        let credentialOffer = try decoder.decode(CredentialOffer.self, from: jsonData)

        XCTAssertTrue(credentialOffer.isTxCodeRequired())
    }

    func testFromStringCredentialOfferFilled() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_offer_filled")
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            XCTFail("unable to convert json data to string")
            return
        }

        let allowedCharacters = NSCharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
        let url = URL(
            string: jsonString.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!)!
        let offerString = "openid-credential-offer://?credential_offer=\(url.absoluteString)"
        guard let credentialOffer = CredentialOffer.fromString(offerString) else {
            XCTFail("failed to `fromString`")
            return
        }

        XCTAssertEqual(credentialOffer.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        XCTAssertFalse(credentialOffer.credentialConfigurationIds.isEmpty)
        XCTAssertEqual(credentialOffer.credentialConfigurationIds[0], "IdentityCredential")

        let grants = credentialOffer.grants
        XCTAssertEqual(grants?.authorizationCode?.issuerState, "eyJhbGciOiJSU0Et...FYUaBy")

        XCTAssertEqual(grants?.preAuthorizedCode?.preAuthorizedCode, "adhjhdjajkdkhjhdj")
        XCTAssertEqual(grants?.preAuthorizedCode?.txCode?.inputMode, "numeric")
        XCTAssertEqual(grants?.preAuthorizedCode?.txCode?.length, 4)
        XCTAssertEqual(grants?.preAuthorizedCode?.txCode?.description, "description")
        XCTAssertEqual(grants?.preAuthorizedCode?.interval, 10)
        XCTAssertEqual(
            grants?.preAuthorizedCode?.authorizationServer, "https://datasign-demo-vci.tunnelto.dev"
        )
    }
}

final class VCIClientTests: XCTestCase {

    private var issuer = ""
    private var credentialOffer: CredentialOffer? = nil

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        issuer = "https://datasign-demo-vci.tunnelto.dev"
        credentialOffer = CredentialOffer.fromString(
            "openid-credential-offer://?credential_offer=%7B%22credential_issuer%22%3A%22https%3A%2F%2Fdatasign-demo-vci.tunnelto.dev%22%2C%22credential_configuration_ids%22%3A%5B%22IdentityCredential%22%5D%2C%22grants%22%3A%7B%22urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Apre-authorized_code%22%3A%7B%22pre-authorized_code%22%3A%22SplxlOBeZQQYbYS6WxSbIA%22%2C%22tx_code%22%3A%7B%7D%7D%7D%7D"
        )

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
            guard let mockData = try? loadJsonTestData(fileName: "token_response")
            else {
                XCTFail("Cannot read token_response.json")
                return
            }
            let response = HTTPURLResponse(
                url: testURL.absoluteURL, statusCode: 200, httpVersion: nil, headerFields: nil)
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
                let mockData = try? loadJsonTestData(fileName: "credential_response")
            else {
                XCTFail("Cannot read credential_response.json")
                return
            }
            let response = HTTPURLResponse(
                url: testURL.absoluteURL, statusCode: 200, httpVersion: nil, headerFields: nil)
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
            let tokenUrl = URL(string: "\(self.issuer)/token")!
            guard
                let mockData = try? loadJsonTestData(fileName: "token_response")
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
                let jsonIssuerMetaData = try? loadJsonTestData(fileName: "credential_issuer_metadata_jwt_vc"),
                let jsonAuthorizationServerData = try? loadJsonTestData(fileName: "authorization_server")
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
            guard let offer = self.credentialOffer else {
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
                let mockData = try? loadJsonTestData(fileName: "credential_response")
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
                let jsonIssuerMetaData = try? loadJsonTestData(fileName: "credential_issuer_metadata_sd_jwt"),
                let jsonAuthorizationServerData = try? loadJsonTestData(fileName: "authorization_server")
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
                guard let offer = self.credentialOffer else {
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

}
