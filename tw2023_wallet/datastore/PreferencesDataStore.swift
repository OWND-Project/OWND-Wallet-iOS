//
//  PreferencesDataStore.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/24.
//

import Foundation
import LocalAuthentication

class PreferencesDataStore {
    static let shared = PreferencesDataStore()

    private let defaults = UserDefaults.standard
    private let seedKey = "seed"
    private let lastBackupAtKey = "last_backup_at_key"

    func saveLastBackupAtKey(_ value: String) {
        defaults.set(value, forKey: lastBackupAtKey)
    }

    func getLastBackupAtKey() -> String? {
        defaults.string(forKey: lastBackupAtKey)
    }

    func saveSeed(_ value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw IllegalArgumentException.badParams
        }
        let enctypted = EncryptionHelper().encryptWithSerialization(data: data)
        defaults.set(enctypted, forKey: seedKey)
    }

    func getSeed() async throws -> String? {
        try await BiometricAuthForPreference().authenticateUser()
        if let encrypted = defaults.string(forKey: seedKey) {
            let decrypted = EncryptionHelper().decryptWithDeserialization(data: encrypted)!
            return String(data: decrypted, encoding: .utf8)
        }
        return nil
    }
}

class BiometricAuthForPreference {
    func authenticateUser() async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw error ?? LAError(.biometryNotAvailable)
        }

        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthentication, localizedReason: "Access requires authentication")
        guard success else {
            throw LAError(.authenticationFailed)
        }
    }
}
