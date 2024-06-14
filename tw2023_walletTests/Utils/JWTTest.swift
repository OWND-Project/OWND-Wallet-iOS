//
//  JWTTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/01/05.
//

import X509
import XCTest

@testable import tw2023_wallet

final class JWTUtilTest: XCTestCase {
    func testSigning() {
        let tag = "jwt_signing_key"
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        let (_, publicKey) = KeyPairUtil.getKeyPair(alias: tag)!

        let header = [
            "typ": "JWT",
            "alg": "ES256",
        ]
        let payload: [String: String] = [:]

        let jwt = try! JWTUtil.sign(keyAlias: tag, header: header, payload: payload)
        let signatureVerification = JWTUtil.verifyJwt(jwt: jwt, publicKey: publicKey)

        switch signatureVerification {
            case .success(let jwt):
                XCTAssertTrue(jwt.header["alg"] as! String == "ES256")
            case .failure(let error):
                XCTFail()
        }
    }

    func testDecodeJwt() {
        let jwt =
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

        let expectedHeader: [String: Any] = [
            "alg": "HS256",
            "typ": "JWT",
        ]

        let expectedPayload: [String: Any] = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": 1_516_239_022,
        ]

        let expectedSignature = "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

        let (header, payload, signature) = try! JWTUtil.decodeJwt(jwt: jwt)
        XCTAssertTrue(NSDictionary(dictionary: header).isEqual(to: expectedHeader))
        XCTAssertTrue(NSDictionary(dictionary: payload).isEqual(to: expectedPayload))
        XCTAssertEqual(signature, expectedSignature)

    }

    func testVerifyJwtByX5C() {
        let subjectKey = KeyPairUtil.generateRandomP256KeyPair()
        let issuerKey = KeyPairUtil.generateRandomP256KeyPair()

        do {
            let now = Date()
            let notBefore = now
            let notAfter = Calendar.current.date(byAdding: .year, value: 1, to: now)!

            let subjectDistinguishedName = try createDistinguishedName(
                commonName: "Example Subject",
                organizationName: "Example Company A",
                localityName: "City A",
                stateOrProvinceName: "State A",
                countryName: "Country A"
            )

            let issuerDistinguishdName = try createDistinguishedName(
                commonName: "Example CA",
                organizationName: "Example Company B",
                localityName: "City B",
                stateOrProvinceName: "State B",
                countryName: "Country B"
            )

            let cert0 = generateCertificate(
                subjectKey: Certificate.PublicKey(subjectKey.publicKey),
                subjectDistinguishedName: subjectDistinguishedName,
                issuerKey: Certificate.PrivateKey(issuerKey.privateKey),
                issuerDistinguishedName: issuerDistinguishdName,
                notBefore: notBefore, notAfter: notAfter,
                isCa: false,
                subjectAlternativeName: ["www.example.com", "api.example.com"]
            )!
            let pem0 = SignatureUtil.certificateToPem(certificate: cert0, withDelimiters: false)

            let cert1 = generateCertificate(
                subjectKey: Certificate.PublicKey(issuerKey.publicKey),
                subjectDistinguishedName: issuerDistinguishdName,
                issuerKey: Certificate.PrivateKey(issuerKey.privateKey),
                issuerDistinguishedName: issuerDistinguishdName,
                notBefore: notBefore, notAfter: notAfter,
                isCa: true
            )!

            let pem1 = SignatureUtil.certificateToPem(certificate: cert1, withDelimiters: false)

            let header: [String: Any] = [
                "typ": "JWT",
                "alg": "ES256",
                "x5c": [pem0, pem1],
            ]
            let headerData = try! JSONSerialization.data(withJSONObject: header, options: [])
            let headerBase64 = headerData.base64EncodedString()

            let payload: [String: String] = [:]
            let payloadData = try! JSONSerialization.data(withJSONObject: payload, options: [])
            let payloadBase64 = payloadData.base64EncodedString()

            let unsignedToken = "\(headerBase64).\(payloadBase64)"

            let signature = try! subjectKey.privateKey.signature(for: Data(unsignedToken.utf8))
            let signatureBase64 = signature.rawRepresentation.base64EncodedString()
            // let signatureBase64 = signature.derRepresentation.base64EncodedString()
            let jwt = "\(unsignedToken).\(signatureBase64)"

            let verifyResult = JWTUtil.verifyJwtByX5C(jwt: jwt, verifyCertChain: false)

            switch verifyResult {
                case .success(let verifedX5CJwt):
                    let (decoded, certificates) = verifedX5CJwt
                    XCTAssertTrue(decoded.header["alg"] as! String == "ES256")
                    if isDomainInSAN(certificate: certificates[0], domain: "www.example.com") {
                        print("verify san entry success")
                    }
                    else {
                        XCTFail("client_id is not in san entry")
                    }
                case .failure(let error):
                    XCTFail("\(error)")
            }
        }
        catch {
            XCTFail()
        }
    }
}
