//
//  RestoreHelper.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/06/07.
//

import Foundation

func loadFile(at url: URL) -> Data? {
    do {
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }  // 終了時にアクセス権を解放

            let data = try Data(contentsOf: url)
            return data
        }
        else {
            print("Security scoped resource could not be accessed.")
        }
    }
    catch {
        print("Unable to load the file: \(error)")
    }
    return nil
}

func decodeJsonAsBackupModel(jsonData: Data) -> BackupData? {
    let decoder = JSONDecoder()

    let decodeAttempts: [(Data) -> BackupData?] = [
        { try? decoder.decode(BackupData.self, from: $0) },
        { (try? decoder.decode(BackupDataV1.self, from: $0))?.convertToLatestVersion() },
        // add more attempts...
    ]

    for decodeAttempt in decodeAttempts {
        if let result = decodeAttempt(jsonData) {
            return result
        }
    }

    return nil
}
