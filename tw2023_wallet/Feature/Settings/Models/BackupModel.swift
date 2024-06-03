//
//  BackupModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/19.
//

import Foundation

struct BackupData: Codable {
    let seed: String
    let idTokenSharingHistories: [IdTokenSharingHistory]
    let credentialSharingHistories: [CredentialSharingHistory]
}
