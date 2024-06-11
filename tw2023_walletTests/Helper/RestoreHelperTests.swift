//
//  RestoreHelperTests.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/06/07.
//

import XCTest

@testable import tw2023_wallet

final class RestoreHelperTests: XCTestCase {

    func testDecodeJsonAsBackupModelWithLatest() {
        let json = """
            {
              "credentialSharingHistories": [
                {
                  "rp": "",
                  "logoUrl": "",
                  "accountIndex": 0,
                  "credentialID": "2D63C987-A3F0-410E-8E45-D74677DD4398",
                  "createdAt": "2024-02-14T04:32:00.998Z",
                  "claims": [
                    {"claimKey": "key", "claimValue": "value", "purpose": "purpose"}
                  ],
                  "rpName": "",
                  "privacyPolicyUrl": ""
                },
                {
                  "privacyPolicyUrl": "",
                  "rp": "",
                  "rpName": "",
                  "logoUrl": "",
                  "createdAt": "2024-02-14T04:32:23.574Z",
                  "accountIndex": 0,
                  "claims": [
                    {"claimKey": "key", "claimValue": "value", "purpose": "purpose"}
                  ],
                  "credentialID": "EE8FF11F-062C-4E18-8977-4C60DD11EAD6"
                }
              ],
              "seed": "seed",
              "idTokenSharingHistories": [
                {
                  "accountIndex": 0,
                  "createdAt": "2024-02-14T04:27:48.654Z",
                  "rp": "https://ownd-project.com:8008/"
                },
                {
                  "accountIndex": 0,
                  "createdAt": "2024-02-20T23:58:11.578Z",
                  "rp": "https://ownd-project.com:8008/"
                },
                {
                  "rp": "https://ownd-project.com:8008/",
                  "accountIndex": 0,
                  "createdAt": "2024-02-22T00:47:07.395Z"
                }
              ]
            }
            """

        let jsonData = json.data(using: .utf8)
        let parsed = decodeJsonAsBackupModel(jsonData: jsonData!)

        XCTAssertNotNil(parsed)

        for history in parsed!.credentialSharingHistories {
            for cl in history.claims {
                XCTAssertEqual(cl.claimValue, "value")
            }
        }
    }

    func testDecodeJsonAsBackupModelWithV1() {
        let json = """
            {
              "credentialSharingHistories": [
                {
                  "rp": "",
                  "logoUrl": "",
                  "accountIndex": 0,
                  "credentialID": "2D63C987-A3F0-410E-8E45-D74677DD4398",
                  "createdAt": "2024-02-14T04:32:00.998Z",
                  "claims": [
                    "key"
                  ],
                  "rpName": "",
                  "privacyPolicyUrl": ""
                },
                {
                  "privacyPolicyUrl": "",
                  "rp": "",
                  "rpName": "",
                  "logoUrl": "",
                  "createdAt": "2024-02-14T04:32:23.574Z",
                  "accountIndex": 0,
                  "claims": [
                    "key"
                  ],
                  "credentialID": "EE8FF11F-062C-4E18-8977-4C60DD11EAD6"
                }
              ],
              "seed": "seed",
              "idTokenSharingHistories": [
                {
                  "accountIndex": 0,
                  "createdAt": "2024-02-14T04:27:48.654Z",
                  "rp": "https://ownd-project.com:8008/"
                },
                {
                  "accountIndex": 0,
                  "createdAt": "2024-02-20T23:58:11.578Z",
                  "rp": "https://ownd-project.com:8008/"
                },
                {
                  "rp": "https://ownd-project.com:8008/",
                  "accountIndex": 0,
                  "createdAt": "2024-02-22T00:47:07.395Z"
                }
              ]
            }
            """

        let jsonData = json.data(using: .utf8)
        let parsed = decodeJsonAsBackupModel(jsonData: jsonData!)

        XCTAssertNotNil(parsed)

        for history in parsed!.credentialSharingHistories {
            for cl in history.claims {
                XCTAssertEqual(cl.claimKey, "key")
            }
        }
    }
}
