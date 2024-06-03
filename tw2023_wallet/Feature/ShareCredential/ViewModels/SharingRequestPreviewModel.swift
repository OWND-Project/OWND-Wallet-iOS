//
//  SharingRequestPreviewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/10.
//

import Foundation

// Preview1
class SharingRequestPreviewModel: SharingRequestViewModel {
    override func accessPairwiseAccountManager() async -> Bool {
        return true
    }

    override func loadData(_ url: String, index: Int = -1) async {
        // mock data for preview
        isLoading = true
        print("load dummy data..")
        let clientId = "https://ownd-project.com:8443"
        let keyRing = HDKeyRing()
        let seed = keyRing?.getMnemonicString()
        do {
            // 実コードが実行できる部分は利用する
            let account = try super.getAccount(seed: seed!, rp: clientId, index: index)

            let (cert, derCertificates) = extractFirstCertSubject(url: clientId)
            let b = try? SignatureUtil.validateCertificateChain(derCertificates: derCertificates)
            if let cert = cert {
                print("country:\(cert.country ?? "")")
                print("domain:\(cert.domain ?? "")")
                print("locality:\(cert.locality ?? "")")
                print("organization:\(cert.organization ?? "")")
                print("state:\(cert.state ?? "")")
                if let issOrg = cert.issuer?.organization {
                    print("issuer org:\(issOrg)")
                }
            }

            clientInfo = ClientInfo(
                name: "OWND Messenger",
                logoUrl: "https://www.ownd-project.com/img/logo_only.png",
                policyUrl: "https://www.ownd-project.com/wallet/privacy/index.html",
                tosUrl: "https://www.ownd-project.com/wallet/tos/index.html",
                jwkThumbprint: account.thumbprint,
                certificateInfo: cert,
                verified: b ?? false
            )
        }
        catch {
            print(error)
        }
        print("done")
        isLoading = false
    }

    override func getStoredAccounts() -> [Datastore_IdTokenSharingHistory] {
        print("load dummy stored accounts")
        var data = Datastore_IdTokenSharingHistory()
        data.accountIndex = 0
        data.rp = "dumy"
        return [data]
    }
}

// Preview2
class SharingRequestVPPreviewModel: SharingRequestViewModel {
    override func accessPairwiseAccountManager() async -> Bool {
        return true
    }

    override func loadData(_ url: String, index: Int = -1) async {
        // mock data for preview
        isLoading = true
        print("load dummy data..")
        let decoder = JSONDecoder()

        let clientInfoJsonData = clientInfoJson.data(using: .utf8)
        clientInfo = try! decoder.decode(ClientInfo.self, from: clientInfoJsonData!)

        let presentationJsonData = presentationJson.data(using: .utf8)
        presentationDefinition = try! decoder.decode(
            PresentationDefinition.self, from: presentationJsonData!)
        print("done")
        isLoading = false
    }

    override func getStoredAccounts() -> [Datastore_IdTokenSharingHistory] {
        print("load dummy stored accounts")
        var data = Datastore_IdTokenSharingHistory()
        data.accountIndex = 0
        data.rp = "dumy"
        return [data]
    }
}

// Preview3
class SharingRequestBiometricErrorPreviewModel: SharingRequestViewModel {
    override func accessPairwiseAccountManager() async -> Bool {
        return false
    }

    override func loadData(_ url: String, index: Int = -1) async {
        // mock data for preview
        isLoading = true
        print("load dummy data..")
        print("done")
        isLoading = false
    }
}

// Preview4
class SharingRequestLoadDataErrorPreviewModel: SharingRequestViewModel {
    override func accessPairwiseAccountManager() async -> Bool {
        return true
    }

    override func loadData(_ url: String, index: Int = -1) async {
        // mock data for preview
        isLoading = true
        print("load dummy data..")
        showAlert = true
        alertTitle = "Load Error"
        alertMessage = "Load Error Message"
        print("done")
        isLoading = false
    }
}

class CredentialListVpModePreviewModel: CredentialListViewModel {
    override func loadData(presentationDefinition: PresentationDefinition? = nil) {
        // mock data for preview
        dataModel.isLoading = true
        print("load dummy data..")
        // try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        let modelData = ModelData()
        modelData.loadCredentials()
        self.dataModel.credentials = modelData.credentials
        print("done")
        dataModel.isLoading = false
    }
}

let clientInfoJson = """
      {
        "name": "OWND Wallet",
        "url": "https://ownd-project.com:8443",
        "logoUrl": "https://www.ownd-project.com/img/logo_only.png",
        "policyUrl": "https://www.ownd-project.com/wallet/privacy/index.html",
        "tosUrl": "https://www.ownd-project.com/wallet/tos/index.html",
        "jwkThumbprint": "9nUymEcZg-1HB3WROpUqY5ydvBh5ujUyz86uu2MbCsQ",
        "verified": true,
        "certificateInfo": {
          "domain": "ownd-project.com",
          "organization": "DataSign Inc.",
          "locality": "",
          "state": "Tokyo",
          "country": "JP",
          "email": "support@ownd-project.com",
          "issuer": {
            "domain": "Sectigo ECC Organization Validation Secure Server CA",
            "organization": "Sectigo Limited",
            "locality": "Salford",
            "state": "Greater Manchester",
            "country": "GB"
          }
        }
      }
    """

let presentationJson = """
      {
        "id": "12345",
        "inputDescriptors": [
          {
            "id": "input1",
            "name": "First Input",
            "purpose": "For identification",
            "format": {
              "vc+sd-jwt": {}
            },
            "group": [
              "A"
            ],
            "constraints": {
              "limitDisclosure": "required",
              "fields": [
                {
                  "path": [
                    "$.is_older_than_13"
                  ],
                  "filter": {
                    "type": "boolean"
                  }
                }
              ]
            }
          }
        ],
        "submissionRequirements": [
          {
            "name": "Over13 Proof",
            "rule": "pick",
            "count": 1,
            "from": "A"
          }
        ]
      }
    """
