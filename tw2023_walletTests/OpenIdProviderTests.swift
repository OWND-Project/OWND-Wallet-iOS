//
//  OpenIdProviderTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2024/01/05.
//

import XCTest

final class OpenIdProviderTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // テスト用のモック関数
    func mockDecodeDisclosure(disclosures: [String]) -> [Disclosure] {
        return disclosures.map { Disclosure(disclosure: $0, key: "mockKey", value: "mockValue") }
    }
    func mockDecodeDisclosure0(disclosures: [String]) -> [Disclosure] {
        return []
    }
    func mockDecodeDisclosure2Records(disclosures: [String]) -> [Disclosure] {
        return [
            Disclosure(disclosure: "claim1-digest", key: "claim1", value: "foo"),
            Disclosure(disclosure: "claim2-digest", key: "claim2", value: "bar")
        ]
    }
    
    func testExample() throws {
        decodeDisclosureFunction = mockDecodeDisclosure
        
        let mockDecoded = decodeDisclosureFunction(["dummy"])
        XCTAssertEqual(mockDecoded[0].key, "mockKey")
    }
    
    let presentationDefinition1 = """
        {
          "id": "12345",
          "input_descriptors": [
            {
              "id": "input1",
              "format": {
                "vc+sd-jwt": {}
              },
              "constraints": {
                "limit_disclosure": "required",
                "fields": [
                  {
                    "path": ["$.claim1"],
                    "filter": {"type": "string"}
                  }
                ]
              }
            }
          ],
          "submission_requirements": []
        }
        """
    let presentationDefinition2 = """
        {
          "id": "12345",
          "input_descriptors": [
            {
              "id": "input1",
              "format": {
                "vc+sd-jwt": {}
              },
              "constraints": {
                "limit_disclosure": "required",
                "fields": [
                  {
                    "path": ["$.claim2"],
                    "filter": {"type": "string"}
                  }
                ]
              }
            }
          ],
          "submission_requirements": []
        }
        """
    
    func testSelectDisclosureNoSelected() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure0
        
        let sdJwt = "issuer-jwt~dummy-claim1~"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let presentationDefinition = try decoder.decode(PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)
        let selected = selectDisclosure(sdJwt: sdJwt, presentationDefinition: presentationDefinition)
        XCTAssertNil(selected)
    }
    
    func testSelectDisclosureSelectedFirst() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure2Records
        
        let sdJwt = "issuer-jwt~dummy-claim1~"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let presentationDefinition = try decoder.decode(PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)
        let selected = selectDisclosure(sdJwt: sdJwt, presentationDefinition: presentationDefinition)
        if let (inputDescriptor, disclosures) = selected  {
            XCTAssertEqual(inputDescriptor.id, "input1")
            XCTAssertEqual(disclosures.count, 1)
            XCTAssertEqual(disclosures[0].key, "claim1")
            XCTAssertEqual(disclosures[0].value, "foo")
        } else {
            XCTFail()
        }
    }
    
    func testSelectDisclosureSelectedSecond() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure2Records
        
        let sdJwt = "issuer-jwt~dummy-claim1~"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let presentationDefinition = try decoder.decode(PresentationDefinition.self, from: presentationDefinition2.data(using: .utf8)!)
        let selected = selectDisclosure(sdJwt: sdJwt, presentationDefinition: presentationDefinition)
        if let (inputDescriptor, disclosures) = selected  {
            XCTAssertEqual(inputDescriptor.id, "input1")
            XCTAssertEqual(disclosures.count, 1)
            XCTAssertEqual(disclosures[0].key, "claim2")
            XCTAssertEqual(disclosures[0].value, "bar")
        } else {
            XCTFail()
        }
    }
    
    func testCreatePresentationSubmissionSdJwtVc() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure2Records
        
        let sdJwt = "issuer-jwt~dummy-claim1~dummy-claim2~"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let presentationDefinition = try decoder.decode(PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)
        
        let credential = SubmissionCredential(id: "internal-id-1", format: "vc+sd-jwt", types: [], credential: sdJwt, inputDescriptor: presentationDefinition.inputDescriptors[0])
        let idProvider = OpenIdProvider(ProviderOption())
        let presentationSubmission = try idProvider.createPresentationSubmissionSdJwtVc(
            credential: credential,
            presentationDefinition: presentationDefinition,
            clientId: "https://rp.example.com",
            nonce: "dummy-nonce"
        )
        let (vpToken, descriptorMap, disclosedClaims, _) = presentationSubmission
        let parts = vpToken.split(separator: "~").map(String.init)
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0], "issuer-jwt")
        XCTAssertEqual(parts[1], "claim1-digest")
        XCTAssertEqual(descriptorMap.format, "vc+sd-jwt")
        XCTAssertEqual(descriptorMap.path, "$")
        XCTAssertEqual(disclosedClaims.count, 1)
        XCTAssertEqual(disclosedClaims[0].id, "internal-id-1")
        XCTAssertEqual(disclosedClaims[0].name, "claim1")
    }
    
    func testRespondVPResponse() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure2Records
        let requestObject = RequestObjectPayloadImpl(
            clientId: "https://rp.example.com",
            redirectUri: "https://rp.example.com/cb",
            nonce: "dummy-nonce",
            responseMode: ResponseMode.directPost
        )
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)
        
        let testURL = URL(string: "https://rp.example.com/cb")!
        let mockData = "dummy response".data(using: .utf8)
        let response = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL] = (mockData, response)
        
        
        let sdJwt = "issuer-jwt~dummy-claim1~dummy-claim2~"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let presentationDefinition = try decoder.decode(PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)
        
        let credential = SubmissionCredential(id: "internal-id-1", format: "vc+sd-jwt", types: [], credential: sdJwt, inputDescriptor: presentationDefinition.inputDescriptors[0])
        
        let authRequestProcessedData = ProcessedRequestData(
            authorizationRequest: AuthorizationRequestPayloadImpl(),
            requestObjectJwt: "dummy-jwt",
            requestObject: requestObject,
            clientMetadata: RPRegistrationMetadataPayload(),
            presentationDefinition: presentationDefinition, 
            requestIsSigned: false
        )
        
        runAsyncTest {
            let idProvider = OpenIdProvider(ProviderOption())
            idProvider.authRequestProcessedData = authRequestProcessedData
            do {
                let result = try await idProvider.respondVPResponse(credentials: [credential], using: mockSession)
                switch result {
                case .success(let data):
                    
                    let (postResult, arrayOfSharedContent, purposes) = data
                    
                    /*
                    let vpTokens = data.first
                    XCTAssertEqual(vpTokens.split(separator: "~").count, 3)
                     
                    let presentationSubmissoin = data.second
                    XCTAssertNotNil(presentationSubmissoin.id)
                    XCTAssertNotEqual(presentationSubmissoin.id, "")
                    XCTAssertEqual(presentationSubmissoin.definitionId, presentationDefinition.id)
                     */
                    
                    let sharedContents = arrayOfSharedContent
                    XCTAssertEqual(sharedContents.count, 1)
                    XCTAssertEqual(sharedContents[0].id, "internal-id-1")
                    XCTAssertEqual(sharedContents[0].sharedClaims.count, 1)
                    XCTAssertEqual(sharedContents[0].sharedClaims[0].name, "claim1")
                case .failure(let error):
                    XCTFail()
                }
            } catch {
                XCTFail()
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
