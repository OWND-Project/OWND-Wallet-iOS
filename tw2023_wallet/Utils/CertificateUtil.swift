//
//  CertificateUtil.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2023/12/26.
//

import ASN1Decoder
import Foundation
import Security
import X509

class CertificateHandler: NSObject, URLSessionDelegate {
    var certificateChainResult: [X509Certificate?] = [] // Property to store certificate chain
    var pemCertificateChainResult: [String?] = [] // PEM形式の証明書チェーン
    var derCertificateChainResult: [Data?] = [] // DER形式の証明書チェーン
    
    let semaphore = DispatchSemaphore(value: 0)

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("urlSession start")
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust
        {
            var certificateChain: [SecCertificate] = []

            if let certificateRefs = SecTrustCopyCertificateChain(serverTrust) {
                for i in 0 ..< CFArrayGetCount(certificateRefs) {
                    if let certificateRef = CFArrayGetValueAtIndex(certificateRefs, i) {
                        let unmanagedCertificate = Unmanaged<SecCertificate>.fromOpaque(certificateRef)
                        let certificate = unmanagedCertificate.takeUnretainedValue()
                        certificateChain.append(certificate)
                    }
                }
            }

            for certificate in certificateChain {
                // certificate der bytes
                var certificateDerData = Data()
                certificateDerData.append(SecCertificateCopyData(certificate) as Data)
                do{
                    certificateChainResult.append(try X509Certificate(data: certificateDerData))
                    // X509Certificateに変換できたデータだけと加える
                    derCertificateChainResult.append(certificateDerData)
                    let pemFormat = convertToPEM(derData: certificateDerData)
                    pemCertificateChainResult.append(pemFormat)
                }catch{
                    certificateChainResult.append(nil)
                    derCertificateChainResult.append(nil)
                    pemCertificateChainResult.append(nil)
                }
            }
        }
        semaphore.signal()
        completionHandler(.performDefaultHandling, nil)
        print("urlSession end")
    }
    
    private func convertToPEM(derData: Data) -> String {
        let base64String = derData.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
        return "-----BEGIN CERTIFICATE-----\n\(base64String)\n-----END CERTIFICATE-----\n"
    }
}

// struct CertificateInfo {
//    let domain: String?
//    let organization: String?
//    let locality: String?
//    let state: String?
//    let country: String?
//    let cert: CertificateInfo?
//
//    func getFullAddress() -> String {
//        let addressParts = [locality, state, country].compactMap { $0 }
//        return addressParts.joined(separator: ", ")
//    }
//}
class CertificateInfo: Codable {
    let domain: String?
    let organization: String?
    let locality: String?
    let state: String?
    let country: String?
    let street: String?
    let email: String?
    var issuer: CertificateInfo?

    init(domain: String?, organization: String?, locality: String?, state: String?, country: String?, street: String?, email: String?, issuer: CertificateInfo?) {
        self.domain = domain
        self.organization = organization
        self.locality = locality
        self.state = state
        self.country = country
        self.street = street
        self.email = email
        self.issuer = issuer
    }

    func getFullAddress() -> String {
        let addressParts = [locality, state, country].compactMap { $0 }
        return addressParts.joined(separator: ", ")
    }
}


func extractFirstCertSubject(url: String) -> (CertificateInfo?, [Data?]) {
    let (certificateChain, certificateDerChain) = extractCertificateChain(url: url)
    if (certificateChain.isEmpty) {
        return (nil, [])
    }

    guard let firstCertificate = certificateChain[0] else {
        return (nil, [])
    }
    let issuer = issuerCertificateInfo(certificate: firstCertificate)
    return (x509Certificate2CertificateInfo(firstCertificate: firstCertificate, issuer: issuer), certificateDerChain)
}

func x509Certificate2CertificateInfo(firstCertificate: X509Certificate, issuer: CertificateInfo? = nil) -> CertificateInfo {
    // TODO: Subject Alt Nameから取得する必要がある。
    // 2.5.4.3はdeprecated
    let domain = firstCertificate.subject(oidString: "2.5.4.3")?.joined(separator: " ")
    let organization = firstCertificate.subject(oidString: "2.5.4.10")?.joined(separator: " ")
    let locality = firstCertificate.subject(oidString: "2.5.4.7")?.joined(separator: " ")
    let state = firstCertificate.subject(oidString: "2.5.4.8")?.joined(separator: " ")
    let country = firstCertificate.subject(oidString: "2.5.4.6")?.joined(separator: " ")
    let street = firstCertificate.subject(oidString: "2.5.4.9")?.joined(separator: " ")
    let email = firstCertificate.subject(oidString: "1.2.840.113549.1.9.1")?.joined(separator: " ")

    return CertificateInfo(domain: domain, organization: organization, locality: locality, state: state, country: country, street: street, email: email, issuer: issuer)
}

func issuerCertificateInfo(certificate: X509Certificate) -> CertificateInfo? {
    guard certificate.issuerDistinguishedName != nil else {
        return nil
    }

    let domain = certificate.issuer(oidString: "2.5.4.3")
    let organization = certificate.issuer(oidString: "2.5.4.10")
    let locality = certificate.issuer(oidString: "2.5.4.7")
    let state = certificate.issuer(oidString: "2.5.4.8")
    let country = certificate.issuer(oidString: "2.5.4.6")
    let street = certificate.issuer(oidString: "2.5.4.9")
    let email = certificate.issuer(oidString: "1.2.840.113549.1.9.1")

    return CertificateInfo(domain: domain, organization: organization, locality: locality, state: state, country: country, street: street, email: email, issuer: nil)
}

func x509Certificate2CertificateInfo(pemData: Data) -> CertificateInfo {
    let certificate = try! X509Certificate(data: pemData)
    // 発行者（issuer）の情報を取得
    let issuerCertInfo = issuerCertificateInfo(certificate: certificate)
    // 被発行者（subject）の情報を取得
    let subjectCertInfo = x509Certificate2CertificateInfo(firstCertificate: certificate, issuer: issuerCertInfo)
    return subjectCertInfo
}

func extractCertificateInfo(from distinguishedName: String) -> CertificateInfo {
    var domain: String?
    var organization: String?
    var locality: String?
    var state: String?
    var country: String?
    var street: String?
    var email: String?

    let subjectParts = distinguishedName.split(separator: ",")

    for part in subjectParts {
        let trimmedPart = part.trimmingCharacters(in: .whitespaces)
        switch trimmedPart {
        case let value where value.hasPrefix("CN="):
            domain = String(value.dropFirst("CN=".count))
        case let value where value.hasPrefix("O="):
            organization = String(value.dropFirst("O=".count))
        case let value where value.hasPrefix("L="):
            locality = String(value.dropFirst("L=".count))
        case let value where value.hasPrefix("ST="):
            state = String(value.dropFirst("ST=".count))
        case let value where value.hasPrefix("C="):
            country = String(value.dropFirst("C=".count))
        case let value where value.hasPrefix("STREET="):
            street = String(value.dropFirst("STREET=".count))
        case let value where value.hasPrefix("E="):
            email = String(value.dropFirst("E=".count))
        default:
            break
        }
    }

    return CertificateInfo(domain: domain, organization: organization, locality: locality, state: state, country: country, street: street, email: email, issuer: nil)
}

func extractIssuerAndSubject(from certificateDescription: String) -> (issuer: String, subject: String) {
    let issuerRegex = try! NSRegularExpression(pattern: "issuer: \"(.*?)\",", options: [])
    let subjectRegex = try! NSRegularExpression(pattern: "subject: \"(.*?)\",", options: [])

    let issuerMatch = issuerRegex.firstMatch(in: certificateDescription, range: NSRange(certificateDescription.startIndex..., in: certificateDescription))
    let subjectMatch = subjectRegex.firstMatch(in: certificateDescription, range: NSRange(certificateDescription.startIndex..., in: certificateDescription))

    let issuer = issuerMatch.map { String(certificateDescription[Range($0.range, in: certificateDescription)!]) } ?? ""
    let subject = subjectMatch.map { String(certificateDescription[Range($0.range, in: certificateDescription)!]) } ?? ""

    return (issuer, subject)
}

func certificate2CertificateInfo(from cert: Certificate) -> CertificateInfo {
    let certificateDescription = String(describing: cert)
    let (issuer, subject) = extractIssuerAndSubject(from: certificateDescription)
    let iss = extractCertificateInfo(from: issuer)
    let sub = extractCertificateInfo(from: subject)
    sub.issuer = iss
    return sub
}

func extractCertificateChain(url: String) -> ([X509Certificate?], [Data?]) {
    let timeout_in_second: Double = 3
    var extractedCertificates: [X509Certificate?] = []
    var extractedDerCertificates: [Data?] = []
    
    let targetURL = URL(string: url)!
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = timeout_in_second
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    let certificateHandler = CertificateHandler()
    let session = URLSession(configuration: configuration, delegate: certificateHandler, delegateQueue: nil)

    // This is an asynchronous operation
    let task = session.dataTask(with: targetURL) { _, _, _ in
        // After the completion of the URLSession task,
        // certificateHandler.certificateChainResult will contain the certificate chain

        // Fetch the certificate chain from the CertificateHandler instance
//        extractedCertificates = certificateHandler.certificateChainResult
//        extractedDerCertificates = certificateHandler.derCertificateChainResult
    }
    task.resume()
    certificateHandler.semaphore.wait()
    extractedCertificates = certificateHandler.certificateChainResult
    extractedDerCertificates = certificateHandler.derCertificateChainResult
       
    return (extractedCertificates, extractedDerCertificates)
}
