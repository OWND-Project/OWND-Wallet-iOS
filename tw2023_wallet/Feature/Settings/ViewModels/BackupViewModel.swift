//
//  BackupViewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/16.
//

import Foundation

@Observable
class BackupViewModel {
    var isLoading = false
    var hasLoadedData = false
    var lastCreatedAt: String? = nil
    var seed: String? = nil
    
    func loadData() {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !hasLoadedData else { return }
        isLoading = true
        print("load data..")
        
        let dataStore = PreferencesDataStore.shared
        if let gmtString = dataStore.getLastBackupAtKey() {
            let gmtFormatter = DateFormatterFactory.gmtDateFormatter()
            let gmtDate = gmtFormatter.date(from: gmtString)!
            
            let localFormatter = DateFormatterFactory.localDateFormatter()
            lastCreatedAt = localFormatter.string(from: gmtDate)
        }
        
        isLoading = false
        hasLoadedData = true
        print("done")
    }
    
    func accessPairwiseAccountManager() async -> Bool {
        do {
            let dataStore = PreferencesDataStore.shared
            let seed = try await dataStore.getSeed()
            if (seed != nil && !seed!.isEmpty) {
                print("Accessed seed successfully")
                self.seed = seed
            } else {
                // 初回のシード生成
                guard let hdKeyRing = HDKeyRing() else {
                    // TODO: エラーの定義を適切な場所で共通化する
                    throw SharingRequestIllegalStateException.illegalKeyRingState
                }
                guard let newSeed = hdKeyRing.getMnemonicString() else {
                    throw SharingRequestIllegalStateException.illegalSeedState
                }
                try dataStore.saveSeed(newSeed)
                self.seed = newSeed
            }
            return true
        } catch {
            // 生体認証のエラー処理
            print("Biometric Error: \(error)")
            return false
        }
    }
    
    func generateBackupData() -> Data? {
        let encoder = JSONEncoder()
        
        let idTokenSharingHistories = IdTokenSharingHistoryManager(container: nil)
            .getAll()
            .map { it in
            return IdTokenSharingHistory(
                rp: it.rp,
                accountIndex: Int(it.accountIndex),
                createdAt: it.createdAt.toDate().toISO8601String()
            )
        }
        let credentialSharingHistories = CredentialSharingHistoryManager(container: nil)
            .getAll()
            .map { it in
            return CredentialSharingHistory(
                rp: it.rp,
                accountIndex: Int(it.accountIndex),
                createdAt: it.createdAt.toDate().toISO8601String(),
                credentialID: it.credentialID,
                
                // workaround.
                // todo: We need to be able to back up `ClaimInfo` types, not just strings.
                claims: it.claims.map{$0.claimKey},
                
                rpName: it.rpName,
                privacyPolicyUrl: it.privacyPolicyURL,
                logoUrl: it.logoURL
            )
        }
        guard let seed = seed else {
            print("seed is not set")
            return nil
        }
        let backupData = BackupData(
            seed: seed,
            idTokenSharingHistories: idTokenSharingHistories,
            credentialSharingHistories: credentialSharingHistories
        )
        do {
            let jsonData = try encoder.encode(backupData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                let compressed = ZipUtil.createZip(with: jsonString)
                return compressed
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func updateLastBackupDate() {
        let now = Date()
        let gmtFormatter = DateFormatterFactory.gmtDateFormatter()
        let gmtString = gmtFormatter.string(from: now)
        let dataStore = PreferencesDataStore.shared
        dataStore.saveLastBackupAtKey(gmtString)
        
        let gmtDate = gmtFormatter.date(from: gmtString)!
        let localFormatter = DateFormatterFactory.localDateFormatter()
        lastCreatedAt = localFormatter.string(from: gmtDate)
    }
}
