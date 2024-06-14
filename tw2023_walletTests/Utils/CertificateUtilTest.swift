//
//  CertificateUtilTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2023/12/26.
//

import CryptoKit
import X509
import XCTest

@testable import tw2023_wallet

class CertificateUtilTests: XCTestCase {

    func testCertificateExtraction() {
        // todo: mock

        // let targetURL = "https://example.com/"
        // let result = extractFirstCertSubject(url: targetURL)

        // let expected = CertificateInfo(domain: "www.example.org", organization: "Internet Corporation for Assigned Names and Numbers", locality: "Los Angeles", state: "California", country: "US")

        // XCTAssertEqual(result?.domain, expected.domain)
        // XCTAssertEqual(result?.organization, expected.organization)
        // XCTAssertEqual(result?.locality, expected.locality)
        // XCTAssertEqual(result?.state, expected.state)
        // XCTAssertEqual(result?.country, expected.country)
    }

    func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let randomString = String((0..<length).map { _ in letters.randomElement()! })
        return randomString
    }

    func testGenerateCertificate() {
        let subjectKey = KeyPairUtil.generateRandomP256KeyPair()
        let publicKey = Certificate.PublicKey(subjectKey.publicKey)

        let issueKey = KeyPairUtil.generateRandomP256KeyPair()
        let privateKey = Certificate.PrivateKey(issueKey.privateKey)

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

            let cert = generateCertificate(
                subjectKey: publicKey, subjectDistinguishedName: subjectDistinguishedName,
                issuerKey: privateKey, issuerDistinguishedName: issuerDistinguishdName,
                notBefore: notBefore, notAfter: notAfter,
                isCa: false,
                subjectAlternativeName: ["www.example.com", "api.example.com"]
            )

            XCTAssertNotNil(cert, "Should not be nil")
        }
        catch {
            XCTFail()
        }
    }
}
