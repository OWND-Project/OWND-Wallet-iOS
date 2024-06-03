//
//  SignatureUtil.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2023/12/28.
//

import ASN1Decoder
import CommonCrypto
import Crypto
import CryptoKit  // for P-256 not secp256k1
import Foundation
import SwiftASN1
import Web3Core
import X509

struct ECPrivateJwk {
    let kty: String
    let crv: String
    let x: String
    let y: String
    let d: String
}

extension String {
    func base64UrlDecoded() -> Data? {
        var base64 = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Paddingが必要な場合、追加
        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }

        return Data(base64Encoded: base64)
    }
}

enum SignatureUtilError: Error {
    case KeyConversionError
    case X509CertificateConversionError
}

let x509CertPreamble = "-----BEGIN CERTIFICATE-----\n"
let x509CertPostamble = "\n-----END CERTIFICATE-----"

enum SignatureUtil {
    static func addPrePostAmble(base64str: String) -> String {
        return x509CertPreamble + base64str + x509CertPostamble
    }

    static func toJwkThumbprint(jwk: ECPublicJwk) -> String? {
        let objectMapper = JSONEncoder()
        objectMapper.outputFormatting = .sortedKeys
        guard let jsonData = try? objectMapper.encode(jwk) else {
            return nil
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        guard let sortedData = jsonString.data(using: .utf8) else {
            return nil
        }

        var hashedBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        sortedData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hashedBytes)
        }

        let hashedData = Data(bytes: hashedBytes, count: Int(CC_SHA256_DIGEST_LENGTH))
        return hashedData.base64URLEncodedString()
    }

    static func generateECKeyPair(jwk: ECPrivateJwk) throws -> (Data, Data) {
        // ------------------------------------------------------
        // jwk は　crvがsecp256k1 であることを前提としている.
        // HD walletで生成されたid_token使用目的の鍵のみが入力される想定であるため
        // TODO: 別のcrvにも対応する
        assert(jwk.crv == "secp256k1")
        // -------------------------------------------------------

        guard let d = jwk.d.base64UrlDecoded(),
            let publicKey = SECP256K1.privateToPublic(privateKey: d)
        else {
            throw SignatureUtilError.KeyConversionError
        }
        return (d, publicKey)
    }

    static func certificateToPem(certificate: Certificate) -> String {
        var serializer = DER.Serializer()
        try! serializer.serialize(certificate)

        let certInBase64 = Data(serializer.serializedBytes).base64EncodedString()
        return addPrePostAmble(base64str: certInBase64)
    }

    static func generateCertificate(
        subjectPublicKey: P256.Signing.PublicKey, issuerPrivateKey: P256.Signing.PrivateKey,
        isCa: Bool
    ) -> Certificate {
        // subjectは VC のIssuerであることを想定している。
        // そのためHAIPに則り、P-256の鍵であることを想定する。
        // TODO: `CertificateUtil` に移動するのが適当
        // TODO: subject dn と　issuer dn を一致させるならば、鍵も一致していないとおかしい

        let publicKey = Certificate.PublicKey(subjectPublicKey)
        let privateKey = Certificate.PrivateKey(issuerPrivateKey)

        let subjectName = try! DistinguishedName {
            CommonName("Common Name")
            OrganizationName("Organization Name")
            LocalityName("Locality Name")
            StateOrProvinceName("State or Province Name")
            CountryName("JP")
        }
        let issuerName = subjectName
        let now = Date()

        let extensions = try! Certificate.Extensions {
            Critical(
                isCa
                    ? BasicConstraints.isCertificateAuthority(maxPathLength: nil)
                    : BasicConstraints.notCertificateAuthority
            )
            Critical(
                KeyUsage(keyCertSign: true)
            )
            SubjectAlternativeNames([.dnsName("localhost")])
        }

        let certificate = try! Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: publicKey,
            notValidBefore: now,
            notValidAfter: now.addingTimeInterval(60 * 60 * 24 * 365),
            issuer: issuerName,
            subject: subjectName,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: privateKey
        )

        return certificate
    }

    static func generateSelfSignedCertificate(issuerPrivateKey: P256.Signing.PrivateKey)
        -> Certificate
    {
        return generateCertificate(
            subjectPublicKey: issuerPrivateKey.publicKey, issuerPrivateKey: issuerPrivateKey,
            isCa: true)
    }

    static func base64strToPem(base64str: String) -> String? {
        guard let raw = Data(base64Encoded: base64str) else {
            return nil
        }
        let encoded = raw.base64EncodedString()

        var content = ""
        for (i, char) in encoded.enumerated() {
            if i % 64 == 0, i != 0 {
                content += "\n"
            }
            content.append(char)
        }

        let pem = addPrePostAmble(base64str: content)
        return pem
    }

    static func decodeBase64ToX509Certificate(base64str: String) throws -> Certificate {
        guard let pem = base64strToPem(base64str: base64str) else {
            throw SignatureUtilError.X509CertificateConversionError
        }
        return try Certificate(pemEncoded: pem)
    }

    static func convertPemToX509Certificates(pemChain: String) throws -> [Certificate] {
        let certWithGarbage =
            pemChain
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: x509CertPostamble, omittingEmptySubsequences: true)
            .filter {
                $0.trimmingCharacters(in: .whitespacesAndNewlines) != ""
            }

        let cleaned =
            certWithGarbage
            .map {
                $0.replacingOccurrences(of: x509CertPreamble, with: "")
                    .replacingOccurrences(
                        of: #"\s+"#,
                        with: "",
                        options: .regularExpression
                    )
            }

        return cleaned.map {
            try! decodeBase64ToX509Certificate(base64str: $0)
        }
    }

    static func getX509CertificatesFromUrl(url: String, session: URLSession = URLSession.shared)
        -> [Certificate]?
    {
        var result: [Certificate]?
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        SignatureUtil.getX509CertificatesFromUrl_(url: url, session: session) {
            certificates, error in
            defer {
                dispatchGroup.leave()
            }
            if let error = error {
                print(error)
            }
            else if let certificates = certificates {
                result = certificates
            }
        }
        dispatchGroup.wait()
        return result
    }

    static func getX509CertificatesFromUrl_(
        url: String, session: URLSession = URLSession.shared,
        completion: @escaping ([Certificate]?, Error?) -> Void
    ) {
        guard let requestURL = URL(string: url) else {
            completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }

        let task = session.dataTask(with: requestURL) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
            else {
                completion(nil, NSError(domain: "Failed to download file", code: 0, userInfo: nil))
                return
            }

            if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                do {
                    let certificates = try convertPemToX509Certificates(pemChain: responseBody)
                    completion(certificates, nil)
                }
                catch {
                    completion(nil, error)
                }
            }
            else {
                completion(nil, NSError(domain: "No data received", code: 0, userInfo: nil))
            }
        }

        task.resume()
    }

    // static func validateCertificateChain(certificates: [Certificate]) throws -> Bool {
    //    static func validateCertificateChain(certificates: [Data]) throws -> Bool {
    //
    //        let certs = certificates.map{
    ////            let pem = try! $0.serializeAsPEM()
    ////            return SecCertificateCreateWithData(nil, Data(pem.derBytes) as CFData)
    //            // $0 is DER format data
    //            return SecCertificateCreateWithData(nil, $0 as CFData)
    //        } as CFArray
    //
    //        // SecTrustを作成し、証明書をセット
    //        var trust: SecTrust?
    //        var policy: SecPolicy?
    //
    //        policy = SecPolicyCreateSSL(true, nil)
    //        SecTrustCreateWithCertificates(certs, policy, &trust)
    //
    //        if trust == nil {
    //            return false
    //        }
    //
    //        var error: CFError?
    //        var trustResult: SecTrustResultType = .invalid
    //        if SecTrustEvaluateWithError(trust!, &error) {
    //            if let error = error {
    //                return false
    //            }
    //            var result: OSStatus = SecTrustGetTrustResult(trust!, &trustResult)
    //            if result != errSecSuccess {
    //                return false
    //            }
    //        } else {
    //            return false
    //        }
    //
    //        if trustResult == .unspecified || trustResult == .proceed {
    //            return true
    //        } else {
    //            return false
    //        }
    //    }
    static func validateCertificateChain(derCertificates: [Data?]) throws -> Bool {
        // Check if any of the certificates in the array is nil
        if derCertificates.contains(where: { $0 == nil }) {
            return false
        }

        let certs =
            derCertificates.compactMap { $0 }.map {
                SecCertificateCreateWithData(nil, $0 as CFData)
            } as CFArray

        return try validateTrust(certs)
    }

    static func validateCertificateChain(certificates: [Certificate]) throws -> Bool {
        let certs =
            certificates.map {
                let pem = try! $0.serializeAsPEM()
                return SecCertificateCreateWithData(nil, Data(pem.derBytes) as CFData)
            } as CFArray

        return try validateTrust(certs)
    }

    private static func validateTrust(_ certs: CFArray) throws -> Bool {
        var trust: SecTrust?
        let policy = SecPolicyCreateSSL(true, nil)
        SecTrustCreateWithCertificates(certs, policy, &trust)

        guard let trust = trust else {
            return false
        }

        var error: CFError?
        if SecTrustEvaluateWithError(trust, &error) {
            guard error == nil else {
                return false
            }

            var trustResult: SecTrustResultType = .invalid
            let result = SecTrustGetTrustResult(trust, &trustResult)
            guard result == errSecSuccess else {
                return false
            }

            return trustResult == .unspecified || trustResult == .proceed
        }
        else {
            return false
        }
    }
}
