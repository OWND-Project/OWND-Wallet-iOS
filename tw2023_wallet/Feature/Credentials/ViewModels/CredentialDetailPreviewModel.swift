//
//  CredentialDetailPreviewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/27.
//

import Foundation

class DetailPreviewModel: CredentialDetailViewModel {
    override func loadData(credential: Credential) async {
        // nop
    }
    override func loadData(credential: Credential, presentationDefinition: PresentationDefinition? = nil) async {
        // mock data for preview
        dataModel.isLoading = true
        print("load dummy data..")
        let modelData = ModelData()
        modelData.loadSharingHistories()
        self.dataModel.sharingHistories = modelData.sharingHistories
        print("done")
        dataModel.isLoading = false
    }
}

class DetailVPModePreviewModel: CredentialDetailViewModel {
    override func loadData(credential: Credential) async {
        // nop
    }
    override func loadData(credential: Credential, presentationDefinition: PresentationDefinition? = nil) async {
        // mock data for preview
        dataModel.isLoading = true
        print("load dummy data..")
        claimsToDisclose = [
            Disclosure(disclosure: "1", key: "last_name", value: "value1"),
            Disclosure(disclosure: "3", key: "age", value: "value3")
        ]
        claimsNotToDisclosed = [
            Disclosure(disclosure: "2", key: "first_name", value: "value2")
        ]
        print("done")
        dataModel.isLoading = false
    }
    
    func dummyPresentationDefinition() -> PresentationDefinition {
        let decoder = JSONDecoder()
        let presentationJsonData = presentationJson.data(using: .utf8)
        let presentationDefinition = try! decoder.decode(PresentationDefinition.self, from: presentationJsonData!)
        return presentationDefinition
    }
    
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
}

