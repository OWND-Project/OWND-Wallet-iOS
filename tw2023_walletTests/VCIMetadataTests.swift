//
//  VCIMetadataTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2023/12/25.
//

import XCTest

final class DecodingCredentialDisplayTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodeFilledCredentialDisplay() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_display_filled")
        let decoder = JSONDecoder()
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

    func testDecodeMinimumCredentialDisplay() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_display_minimum")
        let decoder = JSONDecoder()
        let display = try decoder.decode(CredentialDisplay.self, from: jsonData)

        XCTAssertEqual(display.name, "Credential Example")
        XCTAssertNil(display.locale)
        XCTAssertNil(display.logo)
        XCTAssertNil(display.description)
        XCTAssertNil(display.backgroundColor)
        XCTAssertNil(display.backgroundImage)
        XCTAssertNil(display.textColor)
    }
}

final class DecodingCredentialSupportedTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodeCredentialSupportedJwtVcJson() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_supported_jwt_vc")

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
        let jsonData = try loadJsonTestData(fileName: "credential_supported_vc_sd_jwt")
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
        let jsonData = try loadJsonTestData(fileName: "credential_supported_ldp_vc")
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
}

final class DecodingClaimMapTests: XCTestCase {

    func testDecodeEmptyClaimMap() throws {
        let jsonData = try loadJsonTestData(fileName: "claim_map_empty")
        let decoder = JSONDecoder()
        let claimMap = try decoder.decode(ClaimMap.self, from: jsonData)

        XCTAssertTrue(claimMap.isEmpty)
    }

    func testDecodeFilledClaimMap() throws {
        let jsonData = try loadJsonTestData(fileName: "claim_map_filled")
        let decoder = JSONDecoder()
        let claimMap = try decoder.decode(ClaimMap.self, from: jsonData)
        // 各プロパティに対するテストケース
        if let givenNameClaim = claimMap["given_name"] {
            XCTAssertEqual(givenNameClaim.mandatory, true)
            XCTAssertEqual(givenNameClaim.valueType, "string")
            XCTAssertEqual(givenNameClaim.display?.count, 2)

            XCTAssertEqual(givenNameClaim.display?.first?.name, "Given Name")
            XCTAssertEqual(givenNameClaim.display?.first?.locale, "en-US")

            XCTAssertEqual(givenNameClaim.display?[1].name, "名")
            XCTAssertEqual(givenNameClaim.display?[1].locale, "ja-JP")

        }
        else {
            XCTFail("given_name claim is missing")
        }

        if let lastNameClaim = claimMap["last_name"] {
            XCTAssertEqual(lastNameClaim.mandatory, false)
            XCTAssertEqual(lastNameClaim.valueType, "number")
            XCTAssertEqual(lastNameClaim.display?.count, 2)
            XCTAssertEqual(lastNameClaim.display?.first?.name, "Surname")
            XCTAssertEqual(lastNameClaim.display?.first?.locale, "en-US")

            XCTAssertEqual(lastNameClaim.display?[1].name, "姓")
            XCTAssertEqual(lastNameClaim.display?[1].locale, "ja-JP")
        }
        else {
            XCTFail("last_name claim is missing")
        }

    }

    func testDecodeMixMandatoryAndNonMandatoryClaimMap() throws {
        let jsonData = try loadJsonTestData(fileName: "claim_map_mixed")
        let decoder = JSONDecoder()
        let claimMap = try decoder.decode(ClaimMap.self, from: jsonData)

        // 各プロパティに対するテストケース
        if let givenNameClaim = claimMap["given_name"] {
            XCTAssertEqual(givenNameClaim.mandatory, true)
            XCTAssertEqual(givenNameClaim.valueType, "String")
            XCTAssertEqual(givenNameClaim.display?.count, 1)
            XCTAssertEqual(givenNameClaim.display?.first?.name, "Given Name")
            XCTAssertEqual(givenNameClaim.display?.first?.locale, "en-US")
        }
        else {
            XCTFail("given_name claim is missing")
        }

        if let lastNameClaim = claimMap["last_name"] {
            XCTAssertNil(lastNameClaim.mandatory)
            XCTAssertNil(lastNameClaim.valueType)
            XCTAssertEqual(lastNameClaim.display?.count, 1)
            XCTAssertEqual(lastNameClaim.display?.first?.name, "Surname")
            XCTAssertEqual(lastNameClaim.display?.first?.locale, "en-US")
        }
        else {
            XCTFail("last_name claim is missing")
        }

        if let addressClaim = claimMap["address"] {
            XCTAssertEqual(addressClaim.mandatory, false)
            XCTAssertNil(addressClaim.valueType)
            XCTAssertEqual(addressClaim.display?.count, 1)
            XCTAssertEqual(addressClaim.display?.first?.name, "Address")
            XCTAssertEqual(addressClaim.display?.first?.locale, "en-US")
        }
        else {
            XCTFail("address claim is missing")
        }

        if let ageClaim = claimMap["age"] {
            XCTAssertNil(ageClaim.mandatory)
            XCTAssertEqual(ageClaim.valueType, "Integer")
            XCTAssertEqual(ageClaim.display?.count, 1)
            XCTAssertEqual(ageClaim.display?.first?.name, "Age")
            XCTAssertEqual(ageClaim.display?.first?.locale, "en-US")
        }
        else {
            XCTFail("age claim is missing")
        }

        if let gpaClaim = claimMap["gpa"] {
            XCTAssertNil(gpaClaim.mandatory)
            XCTAssertNil(gpaClaim.valueType)
            XCTAssertEqual(gpaClaim.display?.count, 1)
            XCTAssertEqual(gpaClaim.display?.first?.name, "GPA")
            XCTAssertNil(gpaClaim.display?.first?.locale)
        }
        else {
            XCTFail("gpa claim is missing")
        }

        if let degreeClaim = claimMap["degree"] {
            XCTAssertNil(degreeClaim.mandatory)
            XCTAssertNil(degreeClaim.valueType)
            XCTAssertNil(degreeClaim.display)
        }
        else {
            XCTFail("degree claim is missing")
        }

    }

}

final class localizedClaimNamesTests: XCTestCase {
    func testGetLocalizedClaimNames() {
        let claimDisplayEN = ClaimDisplay(name: "Given Name", locale: "en-US")
        let claimDisplayJP = ClaimDisplay(name: "名", locale: "ja_JP")
        let claimGivenName = Claim(
            mandatory: true, valueType: nil, display: [claimDisplayEN, claimDisplayJP])

        let claims: ClaimMap = ["given_name": claimGivenName]

        let localizedNamesEN = getLocalizedClaimNames(claims: claims, locale: "en-US")
        XCTAssertEqual(localizedNamesEN, ["Given Name"])

        let localizedNamesJP = getLocalizedClaimNames(claims: claims, locale: "ja_JP")
        XCTAssertEqual(localizedNamesJP, ["名"])

        let localizedNamesDefault = getLocalizedClaimNames(claims: claims, locale: "fr-FR")
        XCTAssertEqual(localizedNamesDefault, ["Given Name"])
    }

    func testFirstLocaleSelected() {
        let claimDisplayEN = ClaimDisplay(name: "Given Name", locale: "en-US")
        let claimDisplayJP = ClaimDisplay(name: "名", locale: "ja_JP")
        let claimGivenName = Claim(
            mandatory: true, valueType: nil, display: [claimDisplayEN, claimDisplayJP])

        let claims: ClaimMap = ["given_name": claimGivenName]

        let localizedNamesDefault = getLocalizedClaimNames(claims: claims, locale: "fr-FR")
        XCTAssertEqual(localizedNamesDefault, ["Given Name"])
    }
}

final class DecodingVCIMetadataTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodeVcSdJwtMetadata() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_issuer_metadata_sd_jwt")
        let metadata = try JSONDecoder().decode(CredentialIssuerMetadata.self, from: jsonData)

        XCTAssertEqual(metadata.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        XCTAssertEqual(metadata.authorizationServers, ["https://datasign-demo-vci.tunnelto.dev"])
        XCTAssertEqual(
            metadata.credentialEndpoint, "https://datasign-demo-vci.tunnelto.dev/credentials")
        XCTAssertEqual(
            metadata.batchCredentialEndpoint,
            "https://datasign-demo-vci.tunnelto.dev/batch-credentials")
        XCTAssertEqual(
            metadata.deferredCredentialEndpoint,
            "https://datasign-demo-vci.tunnelto.dev/deferred_credential")

        XCTAssertEqual(metadata.display?.count, 2)
        XCTAssertEqual(metadata.display?[0].name, "DataSign Inc.")
        XCTAssertEqual(metadata.display?[0].locale, "en-US")
        XCTAssertEqual(metadata.display?[0].logo?.uri, "https://datasign.jp/public/logo.png")
        XCTAssertEqual(metadata.display?[0].logo?.altText, "a square logo of a company")

        XCTAssertEqual(metadata.display?[1].name, "株式会社DataSign")
        XCTAssertEqual(metadata.display?[1].locale, "ja-JP")
        XCTAssertEqual(metadata.display?[1].logo?.uri, "https://datasign.jp/public/logo.png")
        XCTAssertEqual(metadata.display?[1].logo?.altText, "a square logo of a company")

        let credentialConfig =
            metadata.credentialConfigurationsSupported["EmployeeIdentificationCredential"]
            as? CredentialSupportedVcSdJwt
        XCTAssertNotNil(credentialConfig)
        XCTAssertEqual(credentialConfig?.format, "vc+sd-jwt")
        XCTAssertEqual(credentialConfig?.scope, "EmployeeIdentification")
        XCTAssertEqual(credentialConfig?.cryptographicBindingMethodsSupported, ["did"])
        XCTAssertEqual(credentialConfig?.credentialSigningAlgValuesSupported, ["ES256K"])
        XCTAssertEqual(credentialConfig?.vct, "EmployeeCredential")

        let claims = credentialConfig?.claims
        XCTAssertNotNil(claims)
        XCTAssertEqual(claims?["company_name"]?.display?.first?.name, "Company Name")
        XCTAssertEqual(claims?["company_name"]?.display?.first?.locale, "en-US")
        XCTAssertEqual(claims?["company_name"]?.display?.last?.name, "会社名")
        XCTAssertEqual(claims?["company_name"]?.display?.last?.locale, "ja-JP")

        XCTAssertEqual(claims?["employee_no"]?.display?.first?.name, "Employee No")
        XCTAssertEqual(claims?["employee_no"]?.display?.first?.locale, "en-US")
        XCTAssertEqual(claims?["employee_no"]?.display?.last?.name, "社員番号")
        XCTAssertEqual(claims?["employee_no"]?.display?.last?.locale, "ja-JP")

        XCTAssertEqual(claims?["given_name"]?.display?.first?.name, "Given Name")
        XCTAssertEqual(claims?["given_name"]?.display?.first?.locale, "en-US")
        XCTAssertEqual(claims?["given_name"]?.display?.last?.name, "名")
        XCTAssertEqual(claims?["given_name"]?.display?.last?.locale, "ja-JP")

        XCTAssertEqual(claims?["family_name"]?.display?.first?.name, "Family Name")
        XCTAssertEqual(claims?["family_name"]?.display?.first?.locale, "en-US")
        XCTAssertEqual(claims?["family_name"]?.display?.last?.name, "姓")
        XCTAssertEqual(claims?["family_name"]?.display?.last?.locale, "ja-JP")

        XCTAssertEqual(claims?["gender"]?.display?.first?.name, "Gender")
        XCTAssertEqual(claims?["gender"]?.display?.first?.locale, "en-US")
        XCTAssertEqual(claims?["gender"]?.display?.last?.name, "性別")
        XCTAssertEqual(claims?["gender"]?.display?.last?.locale, "ja-JP")

        XCTAssertEqual(claims?["division"]?.display?.first?.name, "Division")
        XCTAssertEqual(claims?["division"]?.display?.first?.locale, "en-US")
        XCTAssertEqual(claims?["division"]?.display?.last?.name, "部署")
        XCTAssertEqual(claims?["division"]?.display?.last?.locale, "ja-JP")
    }

    func testDecodeJwtVcMetadata() throws {
        let jsonData = try loadJsonTestData(fileName: "credential_issuer_metadata_jwt_vc")
        let metadata = try JSONDecoder().decode(CredentialIssuerMetadata.self, from: jsonData)

        XCTAssertEqual(metadata.credentialIssuer, "https://datasign-demo-vci.tunnelto.dev")
        XCTAssertEqual(metadata.authorizationServers, ["https://datasign-demo-vci.tunnelto.dev"])
        XCTAssertEqual(
            metadata.credentialEndpoint, "https://datasign-demo-vci.tunnelto.dev/credentials")
        XCTAssertEqual(
            metadata.batchCredentialEndpoint,
            "https://datasign-demo-vci.tunnelto.dev/batch-credentials")
        XCTAssertEqual(
            metadata.deferredCredentialEndpoint,
            "https://datasign-demo-vci.tunnelto.dev/deferred_credential")

        XCTAssertEqual(metadata.display?.count, 2)
        XCTAssertEqual(metadata.display?[0].name, "OWND Project")
        XCTAssertEqual(metadata.display?[0].locale, "en-US")
        XCTAssertEqual(metadata.display?[1].name, "オウンドプロジェクト")
        XCTAssertEqual(metadata.display?[1].locale, "ja_JP")

        let credentialConfigurations =
            metadata.credentialConfigurationsSupported["UniversityDegreeCredential"]
            as? CredentialSupportedJwtVcJson
        XCTAssertNotNil(credentialConfigurations)
        XCTAssertEqual(credentialConfigurations?.format, "jwt_vc_json")
        XCTAssertEqual(credentialConfigurations?.scope, "UniversityDegree")
        XCTAssertEqual(credentialConfigurations?.cryptographicBindingMethodsSupported, ["did"])
        XCTAssertEqual(credentialConfigurations?.credentialSigningAlgValuesSupported, ["ES256K"])
        XCTAssertEqual(
            credentialConfigurations?.proofTypesSupported?["jwt"]?.proofSigningAlgValuesSupported,
            ["ES256"])

        XCTAssertEqual(credentialConfigurations?.display?.count, 2)
        XCTAssertEqual(credentialConfigurations?.display?[0].name, "IdentityCredential")
        XCTAssertEqual(credentialConfigurations?.display?[0].locale, "en-US")
        XCTAssertEqual(credentialConfigurations?.display?[1].name, "IdentityCredential")
        XCTAssertEqual(credentialConfigurations?.display?[1].locale, "ja_JP")

        let credentialDefinition = credentialConfigurations?.credentialDefinition
        XCTAssertEqual(credentialDefinition?.type, ["IdentityCredential", "VerifiableCredential"])

        let givenNameClaim = credentialDefinition?.credentialSubject?["given_name"]
        XCTAssertNotNil(givenNameClaim)
        XCTAssertEqual(givenNameClaim?.display?.count, 2)
        XCTAssertEqual(givenNameClaim?.display?[0].name, "Given Name")
        XCTAssertEqual(givenNameClaim?.display?[0].locale, "en-US")
        XCTAssertEqual(givenNameClaim?.display?[1].name, "名")
        XCTAssertEqual(givenNameClaim?.display?[1].locale, "ja_JP")

        let lastNameClaim = credentialDefinition?.credentialSubject?["last_name"]
        XCTAssertNotNil(lastNameClaim)
        XCTAssertEqual(lastNameClaim?.display?.count, 2)
        XCTAssertEqual(lastNameClaim?.display?[0].name, "Surname")
        XCTAssertEqual(lastNameClaim?.display?[0].locale, "en-US")
        XCTAssertEqual(lastNameClaim?.display?[1].name, "姓")
        XCTAssertEqual(lastNameClaim?.display?[1].locale, "ja_JP")

        let gpaClaim = credentialDefinition?.credentialSubject?["gpa"]
        XCTAssertNotNil(gpaClaim)
        XCTAssertEqual(gpaClaim?.display?.count, 1)
        XCTAssertEqual(gpaClaim?.display?[0].name, "GPA")
    }

}
