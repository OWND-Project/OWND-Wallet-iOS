//
//  IssuerDetailViewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/16.
//

import Foundation

@Observable
class IssuerDetailViewModel {
    var isLoading = false
    var hasLoadedData = false
    var certInfo: CertificateInfo? = nil

    func loadData(credential: Credential?) async {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !hasLoadedData else { return }
        print("load data..")
        isLoading = true

        if let credential = credential {
            do {
                try await processX509Certificate(credential: credential)
            }
            catch {
                print("Unable to interpret x.509 certificate")
            }
        }

        isLoading = false
        hasLoadedData = true
        print("done")
    }

    func respectForHeader(header: [String: Any], credential: Credential) async throws {
        // X509証明書チェーンのURLを取得
        let x5cValue = header["x5c"] as? [String]
        let x5uValue = header["x5u"] as? String

        if x5cValue != nil {
            try await certificateFromX5c(credential: credential)
        }
        else if x5uValue != nil {
            certificateFromX5u(url: x5uValue!)
        }
        else {
            // todo: X509証明書以外の発行者認証の方式に対応する
        }
    }

    func processX509Certificate(credential: Credential) async throws {
        let jwt = credential.payload

        if credential.format == "vc+sd-jwt" {
            // SDJwtUtilを使用してJWTヘッダーをデコード
            guard let header = SDJwtUtil.getDecodedJwtHeader(jwt) else {
                return
            }
            try await respectForHeader(header: header, credential: credential)
        }
        else {
            // JWTUtilを使用してJWTヘッダーをデコード
            let (header, _, _) = try! JWTUtil.decodeJwt(jwt: jwt)
            try await respectForHeader(header: header, credential: credential)
        }
    }

    func certificateFromX5u(url: String) {
        let (certificate, _) = extractFirstCertSubject(url: url)
        if let certificate = certificate {
            certInfo = certificate
            // TODO: TLS通信の中から取得した証明書の検証
            /*
        DispatchQueue.global(qos: .background).async {
                guard let certificates = SignatureUtil.getX509CertificatesFromUrl(url: url) else {
                    return
                }

                // SignatureUtilを使用して証明書チェーンの検証
                do {
                    if try SignatureUtil.validateCertificateChain(certificates: certificates) {
                        self.certInfo = certificate2CertificateInfo(from: certificates[0])
                    }
                } catch {
                    // エラー処理
                }
            }
                  */

        }
    }

    func certificateFromX5c(credential: Credential) async throws {
        let jwt = credential.payload

        // SDJwtUtilを使用してJWTヘッダーをデコード
        guard let decodedJwtHeader = SDJwtUtil.getDecodedJwtHeader(jwt),
            let certificates = SDJwtUtil.getX509CertificatesFromJwt(decodedJwtHeader)
        else {
            return
        }
        // SignatureUtilを使用して証明書チェーンの検証
        let pemCertificate = certificates[0].0
        let derCertificates = certificates.map { $0.1 }
        if try SignatureUtil.validateCertificateChain(derCertificates: derCertificates) {
            let pemCertificateInData = pemCertificate.data(using: .ascii)
            certInfo =
                pemCertificateInData != nil
                ? x509Certificate2CertificateInfo(pemData: pemCertificateInData!) : nil
        }
        else {
            // TODO: 検証に失敗した場合の見せ方は要検討
        }
    }
}
