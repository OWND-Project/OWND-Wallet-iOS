//
//  ES256K.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2023/12/27.
//

import Foundation
import CryptoKit
import web3swift
import Web3Core
import SwiftASN1


import secp256k1

enum SigningError: Error {
    case SigningError
}


public extension Data {
    /// A property that returns an array of UInt8 bytes.
    @inlinable var bytes: [UInt8] {
        withUnsafeBytes { bytesPtr in Array(bytesPtr) }
    }
    
    /// Copies data to unsafe mutable bytes of a given value.
    /// - Parameter value: The inout value to copy the data to.
    func copyToUnsafeMutableBytes<T>(of value: inout T) {
        _ = Swift.withUnsafeMutableBytes(of: &value) { ptr in
            ptr.copyBytes(from: self.prefix(ptr.count))
        }
    }
}

extension Int32 {
    /// A property that returns a Bool representation of the Int32 value.
    var boolValue: Bool {
        Bool(truncating: NSNumber(value: self))
    }
}

extension SECP256K1 {
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    
    public static func verify(publicKey: Data, message: Data, signature: Data) -> Bool {
        let digest = Data(SHA256.hash(data: message))
        var ecdsaSignature = secp256k1_ecdsa_signature()
        
        var pubKey = secp256k1_pubkey()
        let pubKeyBytes = publicKey.bytes
        _ = secp256k1_ec_pubkey_parse(context!, &pubKey, pubKeyBytes, pubKeyBytes.count)
        
        signature.copyToUnsafeMutableBytes(of: &ecdsaSignature.data)
        
        return secp256k1_ecdsa_verify(context!, &ecdsaSignature, Array(digest), &pubKey).boolValue
    }
    
}


class ES256K {
    
    static func sign(key: Data, data: Data) throws -> (Data, Data) {
        let hashedData = Data(SHA256.hash(data: data))
        let (serialized, raw) = SECP256K1.signForRecovery(hash: hashedData, privateKey: key)
        
        if (serialized == nil) || (raw == nil) {
            throw SigningError.SigningError
        }
        
        return (serialized!, raw!)
    }

    static func verify(key: Data, data: Data, signature: Data) throws -> Bool {
        return SECP256K1.verify(publicKey: key, message: data, signature: signature)
     }

    static func createJws(key: Data, payload: String) throws -> String {
        let header: [String: Any] = [
            "alg": "ES256K",
            "typ": "JWT"
        ]

        // Encode header to Base64URL
        let encodedHeader = try Data(JSONSerialization.data(withJSONObject: header)).base64URLEncodedString()

        // Encode payload to Base64URL
        let encodedPayload = payload.data(using: .utf8)?.base64URLEncodedString() ?? ""

        // Sign
        let (serializedSignature, _) = try sign(
            key: key,
            data: "\(encodedHeader).\(encodedPayload)".data(using: .utf8) ?? Data())

        let serializedUnmarshal = SECP256K1.unmarshalSignature(signatureData: serializedSignature)
        let signature = (serializedUnmarshal!.r + serializedUnmarshal!.s).base64URLEncodedString()

        // Create JWS
        return "\(encodedHeader).\(encodedPayload).\(signature)"
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}





