//
//  PairwiseAccount.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/28.
//

import Foundation
import CryptoKit

class PairwiseAccount {
    private var keyRing: HDKeyRing
    var accounts: [Account]
    
    init?(mnemonicWords: String? = nil, accounts: [Account]? = nil) {
        guard let keyRing = HDKeyRing(mnemonicWords: mnemonicWords) else {
            return nil
        }
        self.keyRing = keyRing
        self.accounts = accounts ?? []
    }
    
    func indexToAccount(index: Int, rp: String? = nil) -> Account {
        let publicKey = keyRing.getPublicKey(index: UInt32(index))
        let publicKeyJwk = publicKeyToJwk(publicKey: publicKey)
        
        let privateKey = keyRing.getPrivateKey(index: UInt32(index))
        let privateKeyJwk = privateKeyToJwk(publicKey: publicKey, privateKey: privateKey)
        let thumbprint = generateJWKThumbprint(publicKeyJwk)
        
        var account = Account(
            index: index,
            publicJwk: publicKeyJwk,
            privateJwk: privateKeyJwk,
            thumbprint: thumbprint,
            hash: 0
        )
        if let rp = rp {
            account.rp = rp
        }
        return account
    }
    
    func nextAccount() -> Account {
        let latestIndex = accounts.last?.index ?? -1
        let nextIndex = latestIndex + 1
        return indexToAccount(index: nextIndex)
    }
    
    func getAccount(rp: String, index: Int = -1) -> Account? {
        // TODO: -1が指定されたらnilを返す。本来は新規アカウントの意味だがウワモノがインデックス選択のUIを持たない状態なので、暫定的に-1を既存のアカウントとして返す実装にしている(2024.2.20現在)
        let matchingAccounts: [Account] = index > -1 ?
            accounts.filter { $0.rp == rp && $0.index == index } :
            accounts.filter { $0.rp == rp }

        let sortedMatchingAccounts = matchingAccounts.sorted { $0.index > $1.index } // index指定無しの場合は新しいindexを対象とする
        guard let matchingAccount = sortedMatchingAccounts.first else { return nil }

        let index = matchingAccount.index
        return indexToAccount(index: index)
    }
    
    func getPrivateKey(index:Int) -> Data {
        return keyRing.getPrivateKey(index: UInt32(index))
    }
    
    func getPublicKey(index:Int) -> (Data, Data) {
        return keyRing.getPublicKey(index: UInt32(index))
    }
}

func publicKeyToJwk(publicKey: (Data, Data)) -> ECPublicJwk {
    let x = publicKey.0.base64EncodedString().base64ToBase64url()
    let y = publicKey.1.base64EncodedString().base64ToBase64url()
    return ECPublicJwk(kty: "EC", crv: "secp256k1", x: x, y: y)
}

func privateKeyToJwk(publicKey: (Data, Data), privateKey: Data) -> ECJwk {
    let dBytesBase64 = privateKey.base64EncodedString()
    let d = dBytesBase64.base64ToBase64url()
    let publicJwk = publicKeyToJwk(publicKey: publicKey)
    return ECJwk(kty: publicJwk.kty, crv: publicJwk.crv, x: publicJwk.x, y: publicJwk.y, d: d)
}

struct ECJwk: Codable {
    let kty: String
    let crv: String
    let x: String
    let y: String
    let d: String
}

struct ECPublicJwk: Codable {
    let kty: String
    let crv: String
    let x: String
    let y: String
}

struct Account {
    let index: Int
    let publicJwk: ECPublicJwk
    let privateJwk: ECJwk
    let thumbprint: String
    let hash: Int
    var rp: String? = nil
}


func generateJWKThumbprint(_ jwk: ECPublicJwk) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    let jsonData = try? encoder.encode(jwk)
    let jsonString = String(data: jsonData!, encoding: .utf8)!

    let data = jsonString.data(using: .utf8)!
    let hash = SHA256.hash(data: data)
    
    return Data(hash).base64EncodedString().replacingOccurrences(of: "=", with: "")
}
