//
//  JwtVpJsonGeneratorImpl.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/06/04.
//

import Foundation

class JwtVpJsonGeneratorImpl: JwtVpJsonGenerator {
    private let keyAlias: String

    init(keyAlias: String = Constants.Cryptography.KEY_PAIR_ALIAS_FOR_KEY_JWT_VP_JSON) {
        self.keyAlias = keyAlias
    }

    func generateJwt(
        vcJwt: String, headerOptions: HeaderOptions, payloadOptions: JwtVpJsonPayloadOptions
    ) -> String {
        let vpClaims: [String: Any] = [
            "@context": ["https://www.w3.org/2018/credentials/v1"],
            "type": ["VerifiablePresentation"],
            "verifiableCredential": [vcJwt],
        ]

        let currentTimeSeconds = Int64(Date().timeIntervalSince1970)
        let header: [String: Any] = [
            "alg": headerOptions.alg,
            "typ": headerOptions.typ,
            "jwk": getJwk(),
        ]

        let jwtPayload = VpJwtPayload(
            iss: payloadOptions.iss,
            jti: payloadOptions.jti,
            aud: payloadOptions.aud,
            nbf: payloadOptions.nbf ?? currentTimeSeconds,
            iat: payloadOptions.iat ?? currentTimeSeconds,
            exp: payloadOptions.exp ?? (currentTimeSeconds + 2 * 3600),
            nonce: payloadOptions.nonce,
            vp: vpClaims
        )

        let encoder = JSONEncoder()
        guard let vpTokenPayloadData = try? encoder.encode(jwtPayload),
            let vpTokenPayload = try? JSONSerialization.jsonObject(with: vpTokenPayloadData)
                as? [String: Any]
        else {
            fatalError("Failed to encode jwtPayload")
        }

        do {
            return try JWTUtil.sign(keyAlias: keyAlias, header: header, payload: vpTokenPayload)
        }
        catch {
            fatalError("Failed to sign JWT: \(error)")
        }
    }

    func getJwk() -> [String: String] {
        if !KeyPairUtil.isKeyPairExist(alias: self.keyAlias) {
            do {

                try KeyPairUtil.generateSignVerifyKeyPair(alias: self.keyAlias)
            }
            catch {
                fatalError("Failed to generate key pair: \(error)")
            }
        }
        guard let publicKey = KeyPairUtil.getPublicKey(alias: self.keyAlias) else {
            fatalError("Public key not found for alias: \(keyAlias)")
        }
        return KeyPairUtil.publicKeyToJwk(publicKey: publicKey)!
    }
}
