//
//  BackupModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/19.
//

import Foundation

// Latest backup model
struct BackupData: Codable {
    let seed: String
    let idTokenSharingHistories: [IdTokenSharingHistory]
    let credentialSharingHistories: [CredentialSharingHistory]
}

// Old backup model
struct BackupDataV1: Codable {
    let seed: String
    let idTokenSharingHistories: [IdTokenSharingHistory]
    let credentialSharingHistories: [CredentialSharingHistoryV1]

    func convertToLatestVersion() -> BackupData {
        return BackupData(
            seed: seed,
            idTokenSharingHistories: idTokenSharingHistories,
            credentialSharingHistories: credentialSharingHistories.map {
                $0.convertToLatestVersion()
            }
        )
    }
}
