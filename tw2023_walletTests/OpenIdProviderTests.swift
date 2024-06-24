//
//  OpenIdProviderTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2024/01/05.
//

import XCTest

@testable import tw2023_wallet

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
            Disclosure(disclosure: "claim2-digest", key: "claim2", value: "bar"),
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
        let presentationDefinition = try decoder.decode(
            PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)
        let selected = selectDisclosure(
            sdJwt: sdJwt, presentationDefinition: presentationDefinition)
        XCTAssertNil(selected)
    }

    func testSelectDisclosureSelectedFirst() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure2Records

        let sdJwt = "issuer-jwt~dummy-claim1~"
        let decoder = JSONDecoder()
        let presentationDefinition = try decoder.decode(
            PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)
        let selected = selectDisclosure(
            sdJwt: sdJwt, presentationDefinition: presentationDefinition)
        if let (inputDescriptor, disclosures) = selected {
            XCTAssertEqual(inputDescriptor.id, "input1")
            XCTAssertEqual(disclosures.count, 1)
            XCTAssertEqual(disclosures[0].key, "claim1")
            XCTAssertEqual(disclosures[0].value, "foo")
        }
        else {
            XCTFail()
        }
    }

    func testSelectDisclosureSelectedSecond() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure2Records

        let sdJwt = "issuer-jwt~dummy-claim1~"
        let decoder = JSONDecoder()
        let presentationDefinition = try decoder.decode(
            PresentationDefinition.self, from: presentationDefinition2.data(using: .utf8)!)
        let selected = selectDisclosure(
            sdJwt: sdJwt, presentationDefinition: presentationDefinition)
        if let (inputDescriptor, disclosures) = selected {
            XCTAssertEqual(inputDescriptor.id, "input1")
            XCTAssertEqual(disclosures.count, 1)
            XCTAssertEqual(disclosures[0].key, "claim2")
            XCTAssertEqual(disclosures[0].value, "bar")
        }
        else {
            XCTFail()
        }
    }

    func testCreatePresentationSubmissionSdJwtVc() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure2Records

        let sdJwt = "issuer-jwt~dummy-claim1~dummy-claim2~"
        let decoder = JSONDecoder()
        let presentationDefinition = try decoder.decode(
            PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)

        let credential = SubmissionCredential(
            id: "internal-id-1", format: "vc+sd-jwt", types: [], credential: sdJwt,
            inputDescriptor: presentationDefinition.inputDescriptors[0])
        let idProvider = OpenIdProvider(ProviderOption())

        try KeyPairUtil.generateSignVerifyKeyPair(alias: Constants.Cryptography.KEY_BINDING)
        let keyBinding = KeyBindingImpl(keyAlias: Constants.Cryptography.KEY_BINDING)
        idProvider.setKeyBinding(keyBinding: keyBinding)

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

    func testCreatePresentationSubmissionJwtVpJson() throws {

        let tag = "jwt_signing_key"
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        let (_, publicKey) = KeyPairUtil.getKeyPair(alias: tag)!

        let header = [
            "typ": "JWT",
            "alg": "ES256",
        ]
        let credentialSubject: [String: String] = ["claim1": "foo"]
        let vc: [String: Any] = ["credentialSubject": credentialSubject]
        let payload: [String: Any] = ["vc": vc]

        let vcJwt = try! JWTUtil.sign(keyAlias: tag, header: header, payload: payload)
        let decoder = JSONDecoder()
        let presentationDefinition = try decoder.decode(
            PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)

        let credential = SubmissionCredential(
            id: "internal-id-1", format: "jwt_vp_json", types: [], credential: vcJwt,
            inputDescriptor: presentationDefinition.inputDescriptors[0])
        let idProvider = OpenIdProvider(ProviderOption())

        try KeyPairUtil.generateSignVerifyKeyPair(
            alias: Constants.Cryptography.KEY_PAIR_ALIAS_FOR_KEY_JWT_VP_JSON)
        let jwtVpJsonGenerator = JwtVpJsonGeneratorImpl(
            keyAlias: Constants.Cryptography.KEY_PAIR_ALIAS_FOR_KEY_JWT_VP_JSON)
        idProvider.setJwtVpJsonGenerator(jwtVpJsonGenerator: jwtVpJsonGenerator)

        let presentationSubmission = try idProvider.createPresentationSubmissionJwtVc(
            credential: credential,
            presentationDefinition: presentationDefinition,
            clientId: "https://rp.example.com",
            nonce: "dummy-nonce"
        )
        let (vpToken, descriptorMap, disclosedClaims, _) = presentationSubmission
        do {
            let decodedJwt = try JWTUtil.decodeJwt(jwt: vpToken)
            let jwk = decodedJwt.0["jwk"]
            //            let payload = decodedJwt.1
            let publicKey = try! KeyPairUtil.createPublicKey(jwk: jwk as! [String: String])
            let result = JWTUtil.verifyJwt(jwt: vpToken, publicKey: publicKey)
            switch result {
                case .success(let verifiedJwt):
                    let decodedPayload = verifiedJwt.body
                    let vp = decodedPayload["vp"]
                    XCTAssertNotNil(vp, "vp should not be nil")
                    if let vpObject = vp as? [String: Any] {
                        let verifiableCredential = vpObject["verifiableCredential"]
                        if let vpArray = verifiableCredential as? [String] {
                            // アサート: vpの件数が1件であること
                            XCTAssertEqual(
                                vpArray.count, 1, "vp array should contain exactly one element")
                            //
                            let jwtVc = vpArray[0]
                            let decodedJwtVc = try JWTUtil.decodeJwt(jwt: jwtVc)
                            print(decodedJwtVc.1)
                            let vc = decodedJwtVc.1["vc"] as? [String: Any]
                            let credentialSubject = vc!["credentialSubject"] as? [String: String]
                            XCTAssertEqual(credentialSubject!["claim1"], "foo")
                        }
                        else {
                            XCTFail("vp should be an array of dictionaries")
                        }
                    }
                    else {
                        XCTFail("vp should be an dictionaries")
                    }
                case .failure(let error):
                    print(error)
                    XCTFail("Error verify vp_token: \(error)")
            }
        }
        catch {
            XCTFail("Error generating JWT: \(error)")
        }
        XCTAssertEqual(descriptorMap.format, "jwt_vp_json")
        XCTAssertEqual(descriptorMap.path, "$")
        XCTAssertEqual(descriptorMap.pathNested?.format, "jwt_vc_json")
        XCTAssertEqual(descriptorMap.pathNested?.path, "$.vp.verifiableCredential[0]")
        XCTAssertEqual(disclosedClaims.count, 1)
        XCTAssertEqual(disclosedClaims[0].id, "internal-id-1")
        XCTAssertEqual(disclosedClaims[0].name, "claim1")
        XCTAssertEqual(disclosedClaims[0].value, "foo")
    }

    func testRespondVPResponseDirectPost() throws {
        // mock up
        decodeDisclosureFunction = mockDecodeDisclosure2Records
        let requestObject = RequestObjectPayloadImpl(
            clientId: "https://rp.example.com",
            redirectUri: "https://rp.example.com/cb",
            nonce: "dummy-nonce",
            responseMode: ResponseMode.directPost,
            responseUri: "https://rp.example.com/cb"
        )

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let urlString = "https://rp.example.com/cb"
        let testURL = URL(string: urlString)!
        let mockData = "dummy response".data(using: .utf8)
        let response = HTTPURLResponse(
            url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

        let sdJwt = "issuer-jwt~dummy-claim1~dummy-claim2~"
        let decoder = JSONDecoder()
        let presentationDefinition = try decoder.decode(
            PresentationDefinition.self, from: presentationDefinition1.data(using: .utf8)!)

        let credential = SubmissionCredential(
            id: "internal-id-1", format: "vc+sd-jwt", types: [], credential: sdJwt,
            inputDescriptor: presentationDefinition.inputDescriptors[0])

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

            let requestObj = authRequestProcessedData.requestObject
            let authRequest = authRequestProcessedData.authorizationRequest
            idProvider.clientId = requestObj.clientId ?? authRequest.clientId
            idProvider.responseMode = requestObj.responseMode ?? authRequest.responseMode
            idProvider.nonce = requestObj.nonce ?? authRequest.nonce
            idProvider.presentationDefinition = authRequestProcessedData.presentationDefinition

            try KeyPairUtil.generateSignVerifyKeyPair(alias: Constants.Cryptography.KEY_BINDING)
            let keyBinding = KeyBindingImpl(keyAlias: Constants.Cryptography.KEY_BINDING)
            idProvider.setKeyBinding(keyBinding: keyBinding)
            let result = await idProvider.respondVPResponse(
                credentials: [credential], using: mockSession)
            switch result {
                case .success(let data):
                    let (_, arrayOfSharedContent, _) = data
                    let sharedContents = arrayOfSharedContent
                    XCTAssertEqual(sharedContents.count, 1)
                    XCTAssertEqual(sharedContents[0].id, "internal-id-1")
                    XCTAssertEqual(sharedContents[0].sharedClaims.count, 1)
                    XCTAssertEqual(sharedContents[0].sharedClaims[0].name, "claim1")

                    if let lastRequest = MockURLProtocol.lastRequest {
                        XCTAssertEqual(lastRequest.httpMethod, "POST")
                        XCTAssertEqual(lastRequest.url, testURL)
                    }
                    else {
                        XCTFail("No request was made")
                    }
                case .failure(let error):
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
