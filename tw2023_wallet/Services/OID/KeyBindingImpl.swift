//
//  KeyBindingImpl.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/13.
//

import Foundation
import CommonCrypto

enum KeyBindingImplError: Error {
    case UnexpectedDisclosureValue
}

class KeyBindingImpl: KeyBinding {
    private let keyAlias: String
    
    init(keyAlias: String) {
        self.keyAlias = keyAlias
    }
    func generateJwt(sdJwt: String, selectedDisclosures: [Disclosure], aud: String, nonce: String) throws -> String {
        let parts = sdJwt.split(separator: "~").map(String.init)
        let issuerSignedJwt = parts[0]
        
        let hasNilValue = selectedDisclosures.contains { disclosure in
            disclosure.disclosure == nil
        }
        
        if (hasNilValue) {
            throw KeyBindingImplError.UnexpectedDisclosureValue
        }
        
        let sd = issuerSignedJwt + "~" + selectedDisclosures.map { $0.disclosure! }.joined(separator: "~") + "~"
        
        let sdHash = sd.data(using: String.Encoding.ascii)?.sha256ToBase64Url() ?? ""
        let header = ["typ": "kb+jwt", "alg": "ES256"]
        let payload: [String: Any] = [
            "aud": aud,
            "iat": Int(Date().timeIntervalSince1970),
            "_sd_hash": sdHash,
            "nonce": nonce
        ]
        return try JWTUtil.sign(keyAlias: keyAlias, header: header, payload: payload)
    }
}

extension Data {
    func sha256ToBase64Url() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash).base64URLEncodedString()
    }
}
