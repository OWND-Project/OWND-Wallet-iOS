//
//  KeyPairUtil.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/01/05.
//

import CryptoKit
import Foundation

enum KeyError: Error {
    case KeyNotFound
}

enum JwtError: Error {
    case JsonStringConversionError
    case Base64ConversionError
}

enum JwkError: Error {
    case UnableToConversionError
}

class KeyPairUtil {

    static func generateSignVerifyKeyPair(alias: String) throws {

        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            nil)!  // Ignore errors.

        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: alias,
                kSecAttrAccessControl: access,
            ],
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes, &error) else {
            throw error!.takeRetainedValue() as Error
        }

    }

    static func isKeyPairExist(alias: String) -> Bool {

        let getquery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: alias,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecReturnRef as String: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status == errSecSuccess else {
            return false
        }
        if item == nil {
            return false
        }
        // let key = item as! SecKey
        return true
    }

    static func getPrivateKey(alias: String) -> SecKey? {

        let getquery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: alias,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecReturnRef as String: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        if item == nil {
            return nil
        }
        let key = item as! SecKey
        return key
    }

    static func getPublicKey(alias: String) -> SecKey? {
        let privateKey: SecKey? = KeyPairUtil.getPrivateKey(alias: alias)
        if privateKey != nil {
            return SecKeyCopyPublicKey(privateKey!)
        }
        return nil
    }

    static func getKeyPair(alias: String) -> (SecKey, SecKey)? {
        let privateKey = KeyPairUtil.getPrivateKey(alias: alias)
        let publicKey = KeyPairUtil.getPublicKey(alias: alias)
        if privateKey != nil && publicKey != nil {
            return (privateKey!, publicKey!)
        }
        return nil
    }

    static func createProofJwt(keyAlias: String, audience: String, nonce: String) throws -> String {

        guard let publicKey = KeyPairUtil.getPublicKey(alias: keyAlias),
            let jwk = publicKeyToJwk(publicKey: publicKey)
        else {
            throw KeyError.KeyNotFound
        }

        let header: [String: Any] = [
            "typ": "openid4vci-proof+jwt",
            "alg": "ES256",
            "jwk": jwk,
        ]
        let payload: [String: Any] = [
            "aud": audience,
            "iat": Int(Date().timeIntervalSince1970),
            "nonce": nonce,
        ]

        let proofJwt = try JWTUtil.sign(keyAlias: keyAlias, header: header, payload: payload)
        return proofJwt
    }

    static func decodeJwt(jwt: String) throws -> ([String: Any], [String: Any], String) {
        return try JWTUtil.decodeJwt(jwt: jwt)
    }

    static func createPublicKey(jwk: [String: String]) throws -> SecKey {
        // Check if the necessary JWK components are present
        guard let xBase64Url = jwk["x"],
            let yBase64Url = jwk["y"],
            let xData = xBase64Url.base64UrlDecoded(),
            let yData = yBase64Url.base64UrlDecoded()
        else {
            throw JwkError.UnableToConversionError
        }

        // Construct the full public key data in DER format
        let publicKeyData = Data([UInt8(0x04)] + xData + yData)

        // Create the SecKey object from the public key data
        var error: Unmanaged<CFError>?
        guard
            let secKey = SecKeyCreateWithData(
                publicKeyData as CFData,
                [
                    kSecAttrKeyType: kSecAttrKeyTypeEC,
                    kSecAttrKeyClass: kSecAttrKeyClassPublic,
                    kSecAttrKeySizeInBits: 256,
                    kSecAttrIsPermanent: false,
                ] as CFDictionary, &error)
        else {
            if let error = error?.takeRetainedValue() {
                throw error as Error
            }
            else {
                throw NSError(
                    domain: "com.example", code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "公開鍵の作成に失敗しました"])
            }
        }

        return secKey
    }

    static func publicKeyToJwk(publicKey: SecKey) -> [String: String]? {
        guard let attributes = SecKeyCopyAttributes(publicKey) as? [String: Any] else {
            return nil
        }

        guard let keyType = attributes[kSecAttrKeyType as String] as? String,
            let keyClass = attributes[kSecAttrKeyClass as String] as? String,
            let _ = attributes[kSecValueData as String] as? Data
        else {
            return nil
        }

        if keyType == kSecAttrKeyTypeECSECPrimeRandom as String,
            keyClass == kSecAttrKeyClassPublic as String
        {

            let ecKey = SecKeyCopyPublicKey(publicKey)

            if let ecKey = ecKey {
                var error: Unmanaged<CFError>?
                guard let cfData = SecKeyCopyExternalRepresentation(ecKey, &error) as Data?,
                    error == nil
                else {
                    return nil
                }

                let bytes = [UInt8](cfData)
                // 04 || x || y
                // https://developer.apple.com/documentation/security/1643698-seckeycopyexternalrepresentation
                let xCoord = Data(bytes[1...32])
                let yCoord = Data(bytes[33...64])

                return [
                    "kty": "EC",
                    "alg": "ES256",
                    "crv": "P-256",
                    "x": xCoord.base64URLEncodedString(),
                    "y": yCoord.base64URLEncodedString(),
                ]
            }
        }

        return nil
    }

    static func verifyJwt(jwkJson: [String: String], jwt: String) -> Bool {
        let publicKey = try! KeyPairUtil.createPublicKey(jwk: jwkJson)
        let result = JWTUtil.verifyJwt(jwt: jwt, publicKey: publicKey)
        switch result {
            case .success:
                return true
            case .failure(let error):
                print(error)
                return false
        }
    }

    static func generateRandomP256KeyPair() -> (
        privateKey: P256.Signing.PrivateKey, publicKey: P256.Signing.PublicKey
    ) {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        return (privateKey, publicKey)
    }
}

class KeyStoreHelper {
    private let KEY_ALIAS = "datastore_encryption_key"

    private lazy var keyStore: KeychainWrapper = {
        return KeychainWrapper()
    }()

    // 鍵を生成、管理するのみ。
    // この鍵を用いた暗号化・複合処理は別途要実装
    func getSecretKey() throws -> Data {
        if let secretKeyData = try? keyStore.getData(forKey: KEY_ALIAS) {
            return secretKeyData
        }
        else {
            return try generateSecretKey()
        }
    }

    func generateSecretKey() throws -> Data {
        var keyData = Data(count: 32)  // 256-bit key for AES

        let result = keyData.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes.baseAddress!)
        }

        guard result == errSecSuccess else {
            throw NSError(
                domain: "com.example", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "暗号化キーの生成に失敗しました"])
        }

        try keyStore.setData(keyData, forKey: KEY_ALIAS)
        return keyData
    }
}

class KeychainWrapper {
    func getData(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return data
        }
        else {
            throw NSError(
                domain: "com.example", code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "キーチェーンからデータを取得できませんでした"])
        }
    }

    func setData(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: key,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(
                domain: "com.example", code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "キーチェーンにデータを保存できませんでした"])
        }
    }
}
