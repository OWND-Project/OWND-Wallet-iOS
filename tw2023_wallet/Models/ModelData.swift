//
//  ModelData.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import Foundation

@Observable
class ModelData {
    //    var credentials: [Credential] = load("credentialData.json")
    var credentials: [Credential] = []
    var credentialSharingHistories: [CredentialSharingHistory] = []  // 新しい配列
    var sharingHistories: [History] = []
    var issuerMetaDataList: [CredentialIssuerMetadata] = []  // IssureMetaDataを呼ぶため仮
    var authorizationMetaDataList: [AuthorizationServerMetadata] = []
    var clientInfoList: [ClientInfo] = []
    var presentationDefinitions: [PresentationDefinition] = []

    func loadCredentials() {
        self.credentials = load("credentialData.json")
    }

    func loadCredentialSharingHistories() {
        let credentialSharingHistories =
            load("sharingHistoryData.json") as [CredentialSharingHistory]
        self.credentialSharingHistories = credentialSharingHistories
    }

    func loadSharingHistories() {
        let credentialSharingHistories =
            load("sharingHistoryData.json") as [CredentialSharingHistory]
        let idTokenSharingHistories =
            load("idTokenSharingHistories.json") as [IdTokenSharingHistory]
        let histories = (credentialSharingHistories + idTokenSharingHistories) as [History]

        self.sharingHistories = histories
    }

    func loadAuthorizationMetaDataList() {
        self.authorizationMetaDataList = load("authorizationMetaDataList.json")
    }

    func loadIssuerMetaDataList() {
        self.issuerMetaDataList = load("tempIssureMetalData.json")
    }

    func loadClientInfoList() {
        self.clientInfoList = load("clientInfo.json")
    }

    func loadPresentationDefinitions() {
        self.presentationDefinitions = load("presentationDefinition.json")
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    }
    catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
