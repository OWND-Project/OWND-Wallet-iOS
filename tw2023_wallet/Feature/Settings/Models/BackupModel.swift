//
//  BackupModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/19.
//

import Foundation

struct IdTokenSharingHistory: Codable {
    let rp: String
    let accountIndex: Int
    let createdAt: String
}

struct CredentialSharingHistory: Codable {
    let rp: String
    let accountIndex: Int
    let createdAt: String
    let credentialID: String
    var claims: [String]
    var rpName: String
    var privacyPolicyUrl: String
    var logoUrl: String
}

struct BackupData: Codable {
    let seed: String
    let idTokenSharingHistories: [IdTokenSharingHistory]
    let credentialSharingHistories: [CredentialSharingHistory]
}
