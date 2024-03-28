//
//  VCIMetadataTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2023/12/25.
//

import XCTest

final class VCIMetadataTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDeserializeJsonDisplay() throws {
        guard let url = Bundle.main.url(forResource: "display", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            XCTFail("Cannot read display.json")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let display = try decoder.decode(CredentialsSupportedDisplay.self, from: jsonData)
        
        XCTAssertEqual(display.name, "University Credential")
        XCTAssertEqual(display.locale, "en-US")
        XCTAssertEqual(display.logo?.url, "https://exampleuniversity.com/public/logo.png")
        XCTAssertEqual(display.logo?.altText, "a square logo of a university")
        XCTAssertEqual(display.backgroundColor, "#12107c")
        XCTAssertEqual(display.textColor, "#FFFFFF")
    }
    
    func testDeserializeJsonCredentialSubject() throws {
        guard let url = Bundle.main.url(forResource: "credential_subject", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            XCTFail("Cannot read credential_subject.json")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let issuerCredentialSubjectMap = try decoder.decode(IssuerCredentialSubjectMap.self, from: jsonData)
        
        if let givenNameSubject = issuerCredentialSubjectMap["given_name"] {
            XCTAssertEqual(givenNameSubject.mandatory, true)
            XCTAssertEqual(givenNameSubject.valueType, "String")
            
            // 'display'配列に対する検証
            if let display = givenNameSubject.display, display.count > 0 {
                XCTAssertEqual(display[0].name, "Given Name")
                XCTAssertEqual(display[0].locale, "en-US")
            } else {
                XCTFail("Display data for 'given_name' is missing or empty")
            }
        } else {
            XCTFail("'given_name' key is missing in the decoded map")
        }
    }
    
    func testDecodeCredentialSupportedJwtVcJson() throws {
        // テスト用のJSONファイルを読み込む
        guard let url = Bundle.main.url(forResource: "credential_supported_jwt_vc", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            XCTFail("Cannot read credential_supported.json")
            return
        }
        
        let credentialSupported = try decodeCredentialSupported(from: jsonData)
        if let credential = credentialSupported as? CredentialSupportedJwtVcJson {
            XCTAssertEqual(credential.scope, "UniversityDegree")
            if let credentialSubject = credential.credentialDefinition.credentialSubject {
                if let givenNameSubject = credentialSubject["given_name"] {
                    if let display = givenNameSubject.display, display.count > 0 {
                        XCTAssertEqual(display[0].name, "Given Name")
                        XCTAssertEqual(display[0].locale, "en-US")
                    } else {
                        XCTFail("Display data for 'given_name' is missing or empty")
                    }
                } else {
                    XCTFail("'given_name' key is missing in the decoded map")
                }
            } else {
                XCTFail("credentialSubjectis missing in the decoded map")
            }
        } else {
            XCTFail("Decoded type is not CredentialSupportedVcSdJwt")
        }
    }
    
    func testDecodeCredentialSupportedSdJwtVc() throws {
        // テスト用のJSONファイルを読み込む
        guard let url = Bundle.main.url(forResource: "credential_supported_sd_jwt_vc", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            XCTFail("Cannot read credential_supported_sd_jwt_vc.json")
            return
        }

        let credentialSupported = try decodeCredentialSupported(from: jsonData)
        if let credential = credentialSupported as? CredentialSupportedVcSdJwt {
            XCTAssertEqual(credential.scope, "EmployeeIdentification")
            if let credentialSubject = credential.credentialDefinition.claims {
                if let givenNameSubject = credentialSubject["given_name"] {
                    if let display = givenNameSubject.display, display.count > 0 {
                        XCTAssertEqual(display[0].name, "Given Name")
                        XCTAssertEqual(display[0].locale, "en-US")
                    } else {
                        XCTFail("Display data for 'given_name' is missing or empty")
                    }
                } else {
                    XCTFail("'given_name' key is missing in the decoded map")
                }
            } else {
                XCTFail("claims missing in the decoded map")
            }
        } else {
            XCTFail("Decoded type is not CredentialSupportedVcSdJwt")
        }
    }
    
    func testDecodeCredentialSupportedLdpVc() throws {
        // テスト用のJSONファイルを読み込む
        guard let url = Bundle.main.url(forResource: "credential_supported_ldp_vc", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            XCTFail("Cannot read credential_supported_ldp_vc.json")
            return
        }

        let credentialSupported = try decodeCredentialSupported(from: jsonData)
        if let credential = credentialSupported as? CredentialSupportedJwtVcJsonLdAndLdpVc {
            XCTAssertEqual(credential.types[1], "UniversityDegreeCredential")
            if let credentialSubject = credential.credentialSubject {
                if let givenNameSubject = credentialSubject["given_name"] {
                    if let display = givenNameSubject.display, display.count > 0 {
                        XCTAssertEqual(display[0].name, "Given Name")
                        XCTAssertEqual(display[0].locale, "en-US")
                    } else {
                        XCTFail("Display data for 'given_name' is missing or empty")
                    }
                } else {
                    XCTFail("'given_name' key is missing in the decoded map")
                }
            } else {
                XCTFail("claims missing in the decoded map")
            }
        } else {
            XCTFail("Decoded type is not CredentialSupportedVcSdJwt")
        }
    }
    
    func testDecodeCredentialIssuerMetadata() throws {
        guard let url = Bundle.main.url(forResource: "credential_issuer_metadata_jwt_vc", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            XCTFail("Cannot read credential_issuer_metadata.json")
            return
        }

        let metadata = try JSONDecoder().decode(CredentialIssuerMetadata.self, from: jsonData)

        // 結果の検証
        XCTAssertEqual(metadata.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        // 他のプロパティに関するアサーションも同様に行います。
    }

    func testDeserializeJsonCredentialOffer() throws {
        guard let url = Bundle.main.url(forResource: "credential_offer", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            XCTFail("Cannot read credential_offer.json")
            return
        }

        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let credentialOffer = try decoder.decode(CredentialOffer.self, from: jsonData)

        XCTAssertEqual(credentialOffer.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        XCTAssertTrue(!credentialOffer.credentials.isEmpty)
        XCTAssertEqual(credentialOffer.credentials[0], "IdentityCredential")

        let grants = credentialOffer.grants
        XCTAssertEqual(grants?.authorizationCode?.issuerState, "eyJhbGciOiJSU0Et...FYUaBy")
        XCTAssertEqual(grants?.urnIetfParams?.preAuthorizedCode, "adhjhdjajkdkhjhdj")
        XCTAssertEqual(grants?.urnIetfParams?.userPinRequired, true)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
