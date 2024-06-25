//
//  CredentialIssuerMetadataTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2023/12/26.
//

import XCTest

final class CredentialIssuerMetadataTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFetchCredentialIssuerMetadata() {
        runAsyncTest {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)

            let testURL = URL(string: "https://example.com/api/endpoint")!
            guard
                let url = Bundle.main.url(
                    forResource: "credential_issuer_metadata_jwt_vc", withExtension: "json"),
                let mockData = try? Data(contentsOf: url)
            else {
                XCTFail("Cannot read credential_issuer_metadata.json")
                return
            }
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

            do {
                let metadata = try await fetchCredentialIssuerMetadata(
                    from: testURL, using: mockSession)
                XCTAssertEqual(metadata.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
            }
            catch {
                XCTFail("Request should not fail")
            }
        }
    }

    func testFetchAuthServerMetadata() {
        runAsyncTest {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)

            let testURL = URL(string: "https://example.com/api/endpoint")!
            guard
                let url = Bundle.main.url(
                    forResource: "authorization_server", withExtension: "json"),
                let mockData = try? Data(contentsOf: url)
            else {
                XCTFail("Cannot read authorization_server.json")
                return
            }
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)
            do {
                let metadata = try await fetchAuthServerMetadata(from: testURL, using: mockSession)
                XCTAssertEqual(
                    metadata.tokenEndpoint, "https://datasign-demo-vci.tunnelto.dev/token")
            }
            catch {
                XCTFail("Request should not fail")
            }
        }
    }

    func testRetrieveAllMetadata() {
        runAsyncTest {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)

            let issuer = "https://datasign-demo-vci.tunnelto.dev"
            let testURL1 = URL(string: "\(issuer)/.well-known/openid-credential-issuer")!
            guard
                let mockData1 = try? loadJsonTestData(fileName: "credential_issuer_metadata_jwt_vc")
            else {
                XCTFail("Cannot read credential_issuer_metadata.json")
                return
            }
            let testURL2 = URL(string: "\(issuer)/.well-known/oauth-authorization-server")!
            guard
                let mockData2 = try? loadJsonTestData(fileName: "authorization_server")
            else {
                XCTFail("Cannot read authorization_server.json")
                return
            }
            MockURLProtocol.mockResponses[testURL1.absoluteString] = (
                mockData1,
                HTTPURLResponse(
                    url: testURL1.absoluteURL,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil)
            )
            MockURLProtocol.mockResponses[testURL2.absoluteString] = (
                mockData2,
                HTTPURLResponse(
                    url: testURL2.absoluteURL,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil)
            )
            do {
                let metadata = try await retrieveAllMetadata(issuer: issuer, using: mockSession)
                XCTAssertEqual(metadata.credentialIssuerMetadata.credentialIssuer, issuer)
                XCTAssertEqual(
                    metadata.authorizationServerMetadata.tokenEndpoint, "\(issuer)/token")
            }
            catch {
                print(error)
                XCTFail("Request should not fail")
            }
        }
    }

    // todo とりあえずenum変換の方式を試すだけの仮コード(VCIの発行時点ではtokenEndpointだけあれば良いので全プロパティの変換は後回しにする)
    func testEnumDocode() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let jsonString = """
                {
                    "issuer": "https://example.com",
                    "response_mode": "fragment"
                }
                """
            guard let jsonData = jsonString.data(using: .utf8) else {
                print("Error: unable to convert JSON string to Data")
                return
            }

            let metadata = try decoder.decode(AuthorizationServerMetadata.self, from: jsonData)
            XCTAssertEqual("https://example.com", metadata.issuer)
            XCTAssertEqual(ResponseMode.fragment, metadata.responseMode)
        }
        catch {
            print("Error decoding JSON: \(error)")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
