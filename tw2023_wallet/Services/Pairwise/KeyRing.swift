//
//  KeyRing.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/27.
//

import CryptoKit
import Foundation
import Web3Core
import web3swift

class HDKeyRing {
    // private var keystore: BIP32Keystore
    private var mnemonic: String?
    private var rootNode: HDNode?

    init?(mnemonicWords: String? = nil, entropyLength: Int = 128) {
        // https://github.com/web3swift-team/web3swift/blob/develop/Sources/Web3Core/KeystoreManager/BIP32HDNode.swift
        // https://github.com/web3swift-team/web3swift/blob/develop/Sources/Web3Core/KeystoreManager/BIP39.swift
        // https://github.com/web3swift-team/web3swift/blob/develop/Tests/web3swiftTests/localTests/BIP39Tests.swift
        if let mnemonicWords = mnemonicWords {
            self.mnemonic = mnemonicWords
            guard
                let seed = BIP39.seedFromMmemonics(mnemonicWords, password: "", language: .english)
            else {
                return nil
            }
            guard let rootNode = HDNode(seed: seed)?.derive(path: "m", derivePrivateKey: true)
            else {
                return nil
            }
            self.rootNode = rootNode
        }
        else {
            let entropy = Data.randomBytes(length: entropyLength / 8)!
            let mnemonics = BIP39.generateMnemonicsFromEntropy(entropy: entropy)
            self.mnemonic = mnemonics
            guard let seed = BIP39.seedFromMmemonics(mnemonics!, password: "", language: .english)
            else {
                return nil
            }
            guard let rootNode = HDNode(seed: seed)?.derive(path: "m", derivePrivateKey: true)
            else {
                return nil
            }
            self.rootNode = rootNode
        }
    }

    func deriveNode(index: UInt32) -> HDNode {
        let rootNode = self.rootNode!

        let newNode = rootNode.derive(index: index, derivePrivateKey: true, hardened: true)!
        print("path \(newNode.path!), depth: \(newNode.depth)")
        return newNode
    }

    func getPrivateKey(index: UInt32) -> Data {
        let node = deriveNode(index: index)
        let privateKey = node.privateKey!
        return privateKey
    }

    func getPublicKey(index: UInt32) -> (Data, Data) {
        let node = deriveNode(index: index)
        let privateKey = node.privateKey!
        let publicKeyData = Utilities.privateToPublic(privateKey, compressed: false)!
        let xBytesBase64 = Data(publicKeyData[1..<33])
        let yBytesBase64 = Data(publicKeyData[33..<65])
        return (xBytesBase64, yBytesBase64)
    }

    func getMnemonicString() -> String? {
        return mnemonic
    }
}

extension String {
    func base64ToBase64url() -> String {
        return
            self
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
