//
//  RestoreViewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/16.
//

import Foundation

@Observable
class RestoreViewModel {
    
    var importedDocumentUrl: URL? = nil
    func selectFile() -> Result<Void, Error> {
        guard let url = importedDocumentUrl else {
            return .failure(ApplicatoinError.illegalState(message: "url is not selected"))
        }
        guard let contents = try? Data(contentsOf: url) else {
            return .failure(RestoreError.invalidBackupFile)
        }
        
        guard let jsonString = try? ZipUtil.unzipAndReadContent(from: contents) else {
            return .failure(RestoreError.invalidBackupFile)
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            return .failure(RestoreError.invalidBackupFile)
        }
        
        let decoder = JSONDecoder()
        guard let decodedData = try? decoder.decode(BackupData.self, from: jsonData) else {
            return .failure(RestoreError.invalidBackupFile)
        }
        
        // restore seed
        let dataStore = PreferencesDataStore.shared
        do {
            try dataStore.saveSeed(decodedData.seed)
        } catch {
            return .failure(RestoreError.saveError)
        }
        
        // restore history of id_token sharing
        let storeManager1 = IdTokenSharingHistoryManager(container: nil)
        decodedData.idTokenSharingHistories.forEach { it in
            var history = Datastore_IdTokenSharingHistory()
            history.rp = it.rp
            history.accountIndex = Int32(it.accountIndex)
            history.createdAt = it.createdAt.toDateFromISO8601()!.toGoogleTimestamp()
            storeManager1.save(history: history)
        }
        
        // restore history of credential sharing
        let storeManager2 = CredentialSharingHistoryManager(container: nil)
        decodedData.credentialSharingHistories.forEach { it in
            var history = Datastore_CredentialSharingHistory()
            history.rp = it.rp
            history.accountIndex = Int32(it.accountIndex)
            history.createdAt = it.createdAt.toDateFromISO8601()!.toGoogleTimestamp()
            history.credentialID = it.credentialID
            history.rpName = it.rpName
            history.privacyPolicyURL = it.privacyPolicyUrl
            history.logoURL = it.logoUrl
            it.claims.forEach { claim in
                var tmp = Datastore_ClaimInfo()
                tmp.claimKey = claim.claimKey
                tmp.claimValue = claim.claimValue
                tmp.purpose = claim.purpose ?? ""
                history.claims.append(tmp)
            }
            storeManager2.save(history: history)
        }
        
        // 非初回起動フラグをオン
        UserDefaults.standard.set(true, forKey: "isNotFirstLaunch")
        return .success(())
    }
}

enum RestoreError: Error {
    case invalidBackupFile
    case saveError
}
