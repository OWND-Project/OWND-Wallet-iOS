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

    func testDeserializeFilledCredentialDisplay() throws {
        guard let url = Bundle.main.url(forResource: "filled_all_parameters", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read test data")
            return
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let display = try decoder.decode(CredentialDisplay.self, from: jsonData)
        
        XCTAssertEqual(display.name, "Credential Example")
        XCTAssertEqual(display.locale, "en-US")
        XCTAssertEqual(display.logo?.uri, "https://example.com/logo.png")
        XCTAssertEqual(display.logo?.altText, "Example Logo")
        XCTAssertEqual(display.description, "This is an example credential display.")
        XCTAssertEqual(display.backgroundColor, "#FFFFFF")
        XCTAssertEqual(display.backgroundImage?.uri, "https://example.com/background.png")
        XCTAssertEqual(display.textColor, "#000000")
    }
    
    func testDeserializeMinimumCredentialDisplay() throws {
        guard let url = Bundle.main.url(forResource: "minimum", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read test data")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let display = try decoder.decode(CredentialDisplay.self, from: jsonData)
        
        XCTAssertEqual(display.name, "Credential Example")
        XCTAssertNil(display.locale)
        XCTAssertNil(display.logo)
        XCTAssertNil(display.description)
        XCTAssertNil(display.backgroundColor)
        XCTAssertNil(display.backgroundImage)
        XCTAssertNil(display.textColor)
    }

    func testDeserializeJsonCredentialSubject() throws {
        guard let url = Bundle.main.url(forResource: "partial_optional", withExtension: "json"),
            let jsonData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read test data")
            return
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let claimMap = try decoder.decode(ClaimMap.self, from: jsonData)

        // 各プロパティに対するテストケース
        if let givenNameClaim = claimMap["given_name"] {
            XCTAssertEqual(givenNameClaim.mandatory, true)
            XCTAssertEqual(givenNameClaim.valueType, "String")
            XCTAssertEqual(givenNameClaim.display?.count, 1)
            XCTAssertEqual(givenNameClaim.display?.first?.name, "Given Name")
            XCTAssertEqual(givenNameClaim.display?.first?.locale, "en-US")
        } else {
            XCTFail("given_name claim is missing")
        }
        
        if let lastNameClaim = claimMap["last_name"] {
            XCTAssertNil(lastNameClaim.mandatory)
            XCTAssertNil(lastNameClaim.valueType)
            XCTAssertEqual(lastNameClaim.display?.count, 1)
            XCTAssertEqual(lastNameClaim.display?.first?.name, "Surname")
            XCTAssertEqual(lastNameClaim.display?.first?.locale, "en-US")
        } else {
            XCTFail("last_name claim is missing")
        }

        if let addressClaim = claimMap["address"] {
            XCTAssertEqual(addressClaim.mandatory, false)
            XCTAssertNil(addressClaim.valueType)
            XCTAssertEqual(addressClaim.display?.count, 1)
            XCTAssertEqual(addressClaim.display?.first?.name, "Address")
            XCTAssertEqual(addressClaim.display?.first?.locale, "en-US")
        } else {
            XCTFail("address claim is missing")
        }

        if let ageClaim = claimMap["age"] {
            XCTAssertNil(ageClaim.mandatory)
            XCTAssertEqual(ageClaim.valueType, "Integer")
            XCTAssertEqual(ageClaim.display?.count, 1)
            XCTAssertEqual(ageClaim.display?.first?.name, "Age")
            XCTAssertEqual(ageClaim.display?.first?.locale, "en-US")
        } else {
            XCTFail("age claim is missing")
        }

        if let gpaClaim = claimMap["gpa"] {
            XCTAssertNil(gpaClaim.mandatory)
            XCTAssertNil(gpaClaim.valueType)
            XCTAssertEqual(gpaClaim.display?.count, 1)
            XCTAssertEqual(gpaClaim.display?.first?.name, "GPA")
            XCTAssertNil(gpaClaim.display?.first?.locale)
        } else {
            XCTFail("gpa claim is missing")
        }

        if let degreeClaim = claimMap["degree"] {
            XCTAssertNil(degreeClaim.mandatory)
            XCTAssertNil(degreeClaim.valueType)
            XCTAssertNil(degreeClaim.display)
        } else {
            XCTFail("degree claim is missing")
        }
        
    }

    func testDecodeCredentialSupportedJwtVcJson() throws {
        // テスト用のJSONファイルを読み込む
        guard
            let url = Bundle.main.url(
                forResource: "credential_supported_jwt_vc",
                withExtension: "json"),
            let jsonData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read test data")
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
                    }
                    else {
                        XCTFail("Display data for 'given_name' is missing or empty")
                    }
                }
                else {
                    XCTFail("'given_name' key is missing in the decoded map")
                }
            }
            else {
                XCTFail("credentialSubjectis missing in the decoded map")
            }
        }
        else {
            XCTFail("Decoded type is not CredentialSupportedJwtVcJson")
        }
    }

    func testDecodeCredentialSupportedVcSdJwt() throws {
        // テスト用のJSONファイルを読み込む
        guard
            let url = Bundle.main.url(
                forResource: "credential_supported_vc_sd_jwt", withExtension: "json"),
            let jsonData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read test data")
            return
        }

        let credentialSupported = try decodeCredentialSupported(from: jsonData)
        if let credential = credentialSupported as? CredentialSupportedVcSdJwt {
            XCTAssertEqual(credential.scope, "EmployeeIdentification")
            if let credentialSubject = credential.claims {
                if let givenNameSubject = credentialSubject["given_name"] {
                    if let display = givenNameSubject.display, display.count > 0 {
                        XCTAssertEqual(display[0].name, "Given Name")
                        XCTAssertEqual(display[0].locale, "en-US")
                    }
                    else {
                        XCTFail("Display data for 'given_name' is missing or empty")
                    }
                }
                else {
                    XCTFail("'given_name' key is missing in the decoded map")
                }
            }
            else {
                XCTFail("claims missing in the decoded map")
            }
        }
        else {
            XCTFail("Decoded type is not CredentialSupportedVcSdJwt")
        }
    }

    func testDecodeCredentialSupportedLdpVc() throws {
        // テスト用のJSONファイルを読み込む
        guard
            let url = Bundle.main.url(
                forResource: "credential_supported_ldp_vc", withExtension: "json"),
            let jsonData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read credential_supported_ldp_vc.json")
            return
        }

        let credentialSupported = try decodeCredentialSupported(from: jsonData)
        if let credential = credentialSupported as? CredentialSupportedLdpVc {
            XCTAssertEqual(credential.credentialDefinition.type[1], "UniversityDegreeCredential")
            if let credentialSubject = credential.credentialDefinition.credentialSubject {
                if let givenNameSubject = credentialSubject["given_name"] {
                    if let display = givenNameSubject.display, display.count > 0 {
                        XCTAssertEqual(display[0].name, "Given Name")
                        XCTAssertEqual(display[0].locale, "en-US")
                    }
                    else {
                        XCTFail("Display data for 'given_name' is missing or empty")
                    }
                }
                else {
                    XCTFail("'given_name' key is missing in the decoded map")
                }
            }
            else {
                XCTFail("claims missing in the decoded map")
            }
        }
        else {
            XCTFail("Decoded type is not CredentialSupportedVcSdJwt")
        }
    }

    func testDecodeCredentialIssuerMetadata() throws {
        guard
            let url = Bundle.main.url(
                forResource: "credential_issuer_metadata_jwt_vc", withExtension: "json"),
            let jsonData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read credential_issuer_metadata.json")
            return
        }

        let metadata = try JSONDecoder().decode(CredentialIssuerMetadata.self, from: jsonData)

        // 結果の検証
        XCTAssertEqual(metadata.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        // 他のプロパティに関するアサーションも同様に行います。
    }

    // todo: move to another file.
    func testDeserializeJsonCredentialOffer() throws {
        guard let url = Bundle.main.url(forResource: "credential_offer", withExtension: "json"),
            let jsonData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read test data")
            return
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let credentialOffer = try decoder.decode(CredentialOffer.self, from: jsonData)

        XCTAssertEqual(credentialOffer.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        XCTAssertFalse(credentialOffer.credentialConfigurationIds.isEmpty)
        XCTAssertEqual(credentialOffer.credentialConfigurationIds[0], "IdentityCredential")

        let grants = credentialOffer.grants
        print("========================")
        print(grants)
        XCTAssertEqual(grants?.authorizationCode?.issuerState, "eyJhbGciOiJSU0Et...FYUaBy")
        XCTAssertEqual(grants?.preAuthorizedCode?.preAuthorizedCode, "adhjhdjajkdkhjhdj")
        XCTAssertTrue(credentialOffer.isTxCodeRequired())
        
        XCTAssertEqual(grants?.preAuthorizedCode?.txCode?.inputMode, "numeric")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
