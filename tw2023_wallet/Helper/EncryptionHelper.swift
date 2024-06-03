//
//  EncryptionHelper.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/08.
//

import CryptoKit
import Foundation
import Security

class KeychainHelper {

    static func storeKey(key: Data, for keyName: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyName,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecValueData as String: key,
        ]

        SecItemDelete(query as CFDictionary)  // 既存のアイテムがあれば削除
        return SecItemAdd(query as CFDictionary, nil)
    }
}

class EncryptionHelper {

    private let keychainTag = "com.owned-project.secretkey"
    private var key: SymmetricKey?

    init() {
        // キーをKeychainから取得または生成
        if let keyData = self.retrieveKey() {
            self.key = SymmetricKey(data: keyData)
        }
        else {
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            let result = KeychainHelper.storeKey(key: keyData, for: keychainTag)

            if result == noErr {
                self.key = newKey
            }
            else {
                print("Error storing key in Keychain: \(result)")
            }
        }
    }

    func encrypt(data: Data) -> (encryptedData: Data, iv: Data, tag: Data)? {
        guard let key = self.key else { return nil }
        let iv = AES.GCM.Nonce()
        guard let sealedBox = try? AES.GCM.seal(data, using: key, nonce: iv) else { return nil }

        let ivData = Data(iv)
        return (sealedBox.ciphertext, ivData, sealedBox.tag)
    }

    func decrypt(data: Data, iv: Data, tag: Data) -> Data? {
        guard let key = self.key, let nonce = try? AES.GCM.Nonce(data: iv) else { return nil }
        guard let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: data, tag: tag)
        else { return nil }
        return try? AES.GCM.open(sealedBox, using: key)
    }

    func encryptWithSerialization(data: Data) -> String? {
        guard let enc = encrypt(data: data) else {
            return nil
        }
        return serializeEncrypted(encryptedData: enc.encryptedData, iv: enc.iv, tag: enc.tag)
    }

    func decryptWithDeserialization(data: String) -> Data? {
        guard let deserialized = deserializeEncrypted(serializedEncrypted: data) else {
            return nil
        }
        return decrypt(data: deserialized.encryptedData, iv: deserialized.iv, tag: deserialized.tag)
    }

    func serializeEncrypted(encryptedData: Data, iv: Data, tag: Data) -> String {
        let b64encData = encryptedData.base64EncodedString()
        let b64ivData = iv.base64EncodedString()
        let b64tagData = tag.base64EncodedString()
        return b64encData + "." + b64ivData + "." + b64tagData
    }

    func deserializeEncrypted(serializedEncrypted: String) -> (
        encryptedData: Data, iv: Data, tag: Data
    )? {
        let parts = serializedEncrypted.components(separatedBy: ".")

        if parts.count != 3 {
            return nil
        }
        guard let encryptedData = Data(base64Encoded: parts[0]),
            let iv = Data(base64Encoded: parts[1]),
            let tag = Data(base64Encoded: parts[2])
        else {
            return nil
        }
        return (encryptedData, iv, tag)
    }

    private func retrieveKey() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == noErr {
            return (item as! Data)
        }
        else {
            return nil
        }
    }
    private func getKeyReference(for keyName: String) -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyName,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == noErr {
            return (item as! SecKey)
        }
        else {
            return nil
        }
    }
}
