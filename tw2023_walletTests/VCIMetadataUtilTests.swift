//
//  VCIMetadataUtilTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2024/01/05.
//

import XCTest

final class VCIMetadataUtilTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFindMatchingCredentialsJwtVc() {
        let issuer = "https://datasign-demo-vci.tunnelto.dev"
        guard
            let url = Bundle.main.url(
                forResource: "credential_issuer_metadata_jwt_vc", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read credential_issuer_metadata.json")
            return
        }
        do {
            let decoder = JSONDecoder()
            let metadata = try decoder.decode(CredentialIssuerMetadata.self, from: data)
            XCTAssertEqual(metadata.credentialIssuer, issuer)
            let types = ["IdentityCredential"]
            let credentialSupported = VCIMetadataUtil.findMatchingCredentials(
                format: "jwt_vc_json", types: types, metadata: metadata)
            XCTAssertNotNil(credentialSupported)
        }
        catch {
            XCTFail("Request should not fail")
        }
    }

    func testFindMatchingCredentialsSdJwt() {
        let issuer = "https://datasign-demo-vci.tunnelto.dev"
        guard
            let url = Bundle.main.url(
                forResource: "credential_issuer_metadata_sd_jwt", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read credential_issuer_metadata.json")
            return
        }
        do {
            let decoder = JSONDecoder()
            let metadata = try decoder.decode(CredentialIssuerMetadata.self, from: data)
            XCTAssertEqual(metadata.credentialIssuer, issuer)
            let types = ["EmployeeCredential"]
            let credentialSupported = VCIMetadataUtil.findMatchingCredentials(
                format: "vc+sd-jwt", types: types, metadata: metadata)
            XCTAssertNotNil(credentialSupported)
        }
        catch {
            XCTFail("Request should not fail")
        }
    }

    func testExtractDisplayByClaim() {
        let issuer = "https://datasign-demo-vci.tunnelto.dev"
        guard
            let url = Bundle.main.url(
                forResource: "credential_issuer_metadata_sd_jwt", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read credential_issuer_metadata.json")
            return
        }
        do {
            let decoder = JSONDecoder()
            let metadata = try decoder.decode(CredentialIssuerMetadata.self, from: data)
            XCTAssertEqual(metadata.credentialIssuer, issuer)
            let types = ["EmployeeCredential"]
            let credentialSupported = VCIMetadataUtil.findMatchingCredentials(
                format: "vc+sd-jwt", types: types, metadata: metadata)
            if let credentialSupported = credentialSupported {
                let displayMap = VCIMetadataUtil.extractDisplayByClaim(
                    credentialsSupported: credentialSupported)

                print(displayMap)

                XCTAssertNotNil(displayMap)
                XCTAssertEqual(displayMap.count, 6)

                if let display1 = displayMap["company_name"] {
                    XCTAssertEqual(display1.count, 2)
                    XCTAssertEqual(display1[0].name, "Company Name")
                    XCTAssertEqual(display1[1].name, "会社名")
                }
                else {
                    XCTFail("Display for 'company_name' should exist")
                }

                if let display1 = displayMap["employee_no"] {
                    XCTAssertEqual(display1.count, 2)
                    XCTAssertEqual(display1[0].name, "Employee No")
                    XCTAssertEqual(display1[1].name, "社員番号")
                }
                else {
                    XCTFail("Display for 'employee_no' should exist")
                }
                if let display2 = displayMap["given_name"] {
                    XCTAssertEqual(display2.count, 2)
                    XCTAssertEqual(display2[0].name, "Given Name")
                    XCTAssertEqual(display2[1].name, "名")
                }
                else {
                    XCTFail("Display for 'given_name' should exist")
                }
                if let display3 = displayMap["family_name"] {
                    XCTAssertEqual(display3.count, 2)
                    XCTAssertEqual(display3[0].name, "Family Name")
                    XCTAssertEqual(display3[1].name, "姓")
                }
                else {
                    XCTFail("Display for 'family_name' should exist")
                }
                if let display4 = displayMap["gender"] {
                    XCTAssertEqual(display4.count, 2)
                    XCTAssertEqual(display4[0].name, "Gender")
                    XCTAssertEqual(display4[1].name, "性別")
                }
                else {
                    XCTFail("Display for 'gender' should exist")
                }
                if let display5 = displayMap["division"] {
                    XCTAssertEqual(display5.count, 2)
                    XCTAssertEqual(display5[0].name, "Division")
                    XCTAssertEqual(display5[1].name, "部署")
                }
                else {
                    XCTFail("Display for 'division' should exist")
                }
            }
            else {
                XCTFail("ExtractDisplayByClaim should not fail")
            }
        }
        catch {
            XCTFail("Decode should not fail")
        }
    }

    func testSerializationAndDeserialization() {
        let issuer = "https://datasign-demo-vci.tunnelto.dev"
        guard
            let url = Bundle.main.url(
                forResource: "credential_issuer_metadata_sd_jwt", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read credential_issuer_metadata.json")
            return
        }
        do {
            let decoder = JSONDecoder()
            let metadata = try decoder.decode(CredentialIssuerMetadata.self, from: data)
            XCTAssertEqual(metadata.credentialIssuer, issuer)
            let types = ["EmployeeCredential"]
            guard
                let credentialSupported = VCIMetadataUtil.findMatchingCredentials(
                    format: "vc+sd-jwt", types: types, metadata: metadata)
            else {
                XCTFail("ExtractDisplayByClaim should not fail")
                return
            }

            let displayMap = VCIMetadataUtil.extractDisplayByClaim(
                credentialsSupported: credentialSupported)

            // 一度シリアライズ
            let serialized = VCIMetadataUtil.serializeDisplayByClaimMap(displayMap: displayMap)
            // デシリアライズ
            let deserialized = VCIMetadataUtil.deserializeDisplayByClaimMap(
                displayMapString: serialized)

            XCTAssertNotNil(deserialized)
            XCTAssertEqual(deserialized.count, 6)

            if let display1 = deserialized["given_name"] {
                XCTAssertEqual(display1.count, 2)
                XCTAssertEqual(display1[0].name, "Given Name")
                XCTAssertEqual(display1[1].name, "名")
            }
            else {
                XCTFail("Display for 'given_name' should exist")
            }

            if let display2 = deserialized["family_name"] {
                XCTAssertEqual(display2.count, 2)
                XCTAssertEqual(display2[0].name, "Family Name")
                XCTAssertEqual(display2[1].name, "姓")
            }
            else {
                XCTFail("Display for 'last_name' should exist")
            }

            // あとは割愛
        }
        catch {
            XCTFail("Decode should not fail")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
