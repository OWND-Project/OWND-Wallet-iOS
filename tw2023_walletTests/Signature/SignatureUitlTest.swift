//
//  SignatureUitlTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2023/12/28.
//

import Crypto
import CryptoKit  // for P-256 not secp256k1
import Foundation
import SwiftASN1
import X509
import XCTest

@testable import tw2023_wallet

protocol URLSessionProtocol {
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask
}

class MockURLSessionDataTask: URLSessionDataTask {
    override func resume() {}
    // You can add additional mocking behavior if needed
}

class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        completionHandler(data, response, error)
        return MockURLSessionDataTask()
    }
}

let fullChain = """
    -----BEGIN CERTIFICATE-----
    MIIFUjCCBPegAwIBAgIRAO68a+XoD/PhST9Zr7Fq4b0wCgYIKoZIzj0EAwIwgZUx
    CzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNV
    BAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDE9MDsGA1UEAxM0
    U2VjdGlnbyBFQ0MgT3JnYW5pemF0aW9uIFZhbGlkYXRpb24gU2VjdXJlIFNlcnZl
    ciBDQTAeFw0yMzEyMDUwMDAwMDBaFw0yNTAxMDQyMzU5NTlaMFAxCzAJBgNVBAYT
    AkpQMQ4wDAYDVQQIEwVUb2t5bzEWMBQGA1UEChMNRGF0YVNpZ24gSW5jLjEZMBcG
    A1UEAxMQb3duZC1wcm9qZWN0LmNvbTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IA
    BFIprdRg9RgqfsmAAmY/QMQ3Czjds6QvvO3WJT4rP00KVBwHxlbH1ZfSKVgDAdZP
    fQAp7tWBED9nlck7Qk9M4nGjggNqMIIDZjAfBgNVHSMEGDAWgBRNSu/ERrMSrU9O
    mrFZ4lGrCBB4CDAdBgNVHQ4EFgQULd9BFtdtud+3yIiR9ZXHqd6S9WQwDgYDVR0P
    AQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsG
    AQUFBwMCMEoGA1UdIARDMEEwNQYMKwYBBAGyMQECAQMEMCUwIwYIKwYBBQUHAgEW
    F2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMAgGBmeBDAECAjBaBgNVHR8EUzBRME+g
    TaBLhklodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29FQ0NPcmdhbml6YXRp
    b25WYWxpZGF0aW9uU2VjdXJlU2VydmVyQ0EuY3JsMIGKBggrBgEFBQcBAQR+MHww
    VQYIKwYBBQUHMAKGSWh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb0VDQ09y
    Z2FuaXphdGlvblZhbGlkYXRpb25TZWN1cmVTZXJ2ZXJDQS5jcnQwIwYIKwYBBQUH
    MAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMDEGA1UdEQQqMCiCEG93bmQtcHJv
    amVjdC5jb22CFHd3dy5vd25kLXByb2plY3QuY29tMIIBfQYKKwYBBAHWeQIEAgSC
    AW0EggFpAWcAdQDPEVbu1S58r/OHW9lpLpvpGnFnSrAX7KwB0lt3zsw7CAAAAYw6
    NipUAAAEAwBGMEQCIBVcGQjOkfLxvpm1Admcetmn8D15G4Gt2AIdOXveZYrsAiBe
    q8jh8G4geumOHXIklSxvBzip9VK6sw9yq4AnTHnSPwB2AKLjCuRF772tm3447Udn
    d1PXgluElNcrXhssxLlQpEfnAAABjDo2KcoAAAQDAEcwRQIhAJP0UetSSFGF9/fa
    OHVzhkPFOg3etjXqWQShnxYI8a+GAiABzN4+sJAysZ88mtodttNYamXsnfw1T3qX
    YcJbB5GwJAB2AE51oydcmhDDOFts1N8/Uusd8OCOG41pwLH6ZLFimjnfAAABjDo2
    KhkAAAQDAEcwRQIgbpDfqifRz9PW+Tq83ivbXHA1GheQpGX88laI0XB910gCIQCK
    Rm2sRqqlgaXX7rO3EznDn7MwC4mbQwSyEIDjXddHMzAKBggqhkjOPQQDAgNJADBG
    AiEAzwi+A0/YY55h0f+Id0+eUPrRsVBdOKWIp19yQZ62jJICIQCvKk/avGDl5/eN
    IyN1eesa1sbs8QfbTbvzitYsVlRqXg==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIDrjCCAzOgAwIBAgIQNb50Y4yz6d4oBXC3l4CzZzAKBggqhkjOPQQDAzCBiDEL
    MAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNl
    eSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMT
    JVVTRVJUcnVzdCBFQ0MgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgxMTAy
    MDAwMDAwWhcNMzAxMjMxMjM1OTU5WjCBlTELMAkGA1UEBhMCR0IxGzAZBgNVBAgT
    EkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMP
    U2VjdGlnbyBMaW1pdGVkMT0wOwYDVQQDEzRTZWN0aWdvIEVDQyBPcmdhbml6YXRp
    b24gVmFsaWRhdGlvbiBTZWN1cmUgU2VydmVyIENBMFkwEwYHKoZIzj0CAQYIKoZI
    zj0DAQcDQgAEnI5cCmFvoVij0NXO+vxE+f+6Bh57FhpyH0LTCrJmzfsPSXIhTSex
    r92HOlz+aHqoGE0vSe/CSwLFoWcZ8W1jOaOCAW4wggFqMB8GA1UdIwQYMBaAFDrh
    CYbUzxnClnZ0SXbc4DXGY2OaMB0GA1UdDgQWBBRNSu/ERrMSrU9OmrFZ4lGrCBB4
    CDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHSUEFjAU
    BggrBgEFBQcDAQYIKwYBBQUHAwIwGwYDVR0gBBQwEjAGBgRVHSAAMAgGBmeBDAEC
    AjBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20vVVNF
    UlRydXN0RUNDQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwdgYIKwYBBQUHAQEE
    ajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVzdC5jb20vVVNFUlRy
    dXN0RUNDQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVz
    ZXJ0cnVzdC5jb20wCgYIKoZIzj0EAwMDaQAwZgIxAOk//uo7i/MoeKdcyeqvjOXs
    BJFGLI+1i0d+Tty7zEnn2w4DNS21TK8wmY3Kjm3EmQIxAPI1qHM/I+OS+hx0OZhG
    fDoNifTe/GxgWZ1gOYQKzn6lwP0yGKlrP+7vrVC8IczJ4A==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIID0zCCArugAwIBAgIQVmcdBOpPmUxvEIFHWdJ1lDANBgkqhkiG9w0BAQwFADB7
    MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
    VQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UE
    AwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTE5MDMxMjAwMDAwMFoXDTI4
    MTIzMTIzNTk1OVowgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5
    MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBO
    ZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgRUNDIENlcnRpZmljYXRpb24gQXV0
    aG9yaXR5MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEGqxUWqn5aCPnetUkb1PGWthL
    q8bVttHmc3Gu3ZzWDGH926CJA7gFFOxXzu5dP+Ihs8731Ip54KODfi2X0GHE8Znc
    JZFjq38wo7Rw4sehM5zzvy5cU7Ffs30yf4o043l5o4HyMIHvMB8GA1UdIwQYMBaA
    FKARCiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQ64QmG1M8ZwpZ2dEl23OA1
    xmNjmjAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zARBgNVHSAECjAI
    MAYGBFUdIAAwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5j
    b20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEEKDAmMCQG
    CCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZIhvcNAQEM
    BQADggEBABns652JLCALBIAdGN5CmXKZFjK9Dpx1WywV4ilAbe7/ctvbq5AfjJXy
    ij0IckKJUAfiORVsAYfZFhr1wHUrxeZWEQff2Ji8fJ8ZOd+LygBkc7xGEJuTI42+
    FsMuCIKchjN0djsoTI0DQoWz4rIjQtUfenVqGtF8qmchxDM6OW1TyaLtYiKou+JV
    bJlsQ2uRl9EMC5MCHdK8aXdJ5htN978UeAOwproLtOGFfy/cQjutdAFI3tZs4RmY
    CV4Ks2dH/hzg1cEo70qLRDEmBDeNiXQ2Lu+lIg+DdEmSx/cQwgwp+7e9un/jX9Wf
    8qn0dNW44bOwgeThpWOjzOoEeJBuv/c=
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIEMjCCAxqgAwIBAgIBATANBgkqhkiG9w0BAQUFADB7MQswCQYDVQQGEwJHQjEb
    MBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRow
    GAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmlj
    YXRlIFNlcnZpY2VzMB4XDTA0MDEwMTAwMDAwMFoXDTI4MTIzMTIzNTk1OVowezEL
    MAkGA1UEBhMCR0IxGzAZBgNVBAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
    BwwHU2FsZm9yZDEaMBgGA1UECgwRQ29tb2RvIENBIExpbWl0ZWQxITAfBgNVBAMM
    GEFBQSBDZXJ0aWZpY2F0ZSBTZXJ2aWNlczCCASIwDQYJKoZIhvcNAQEBBQADggEP
    ADCCAQoCggEBAL5AnfRu4ep2hxxNRUSOvkbIgwadwSr+GB+O5AL686tdUIoWMQua
    BtDFcCLNSS1UY8y2bmhGC1Pqy0wkwLxyTurxFa70VJoSCsN6sjNg4tqJVfMiWPPe
    3M/vg4aijJRPn2jymJBGhCfHdr/jzDUsi14HZGWCwEiwqJH5YZ92IFCokcdmtet4
    YgNW8IoaE+oxox6gmf049vYnMlhvB/VruPsUK6+3qszWY19zjNoFmag4qMsXeDZR
    rOme9Hg6jc8P2ULimAyrL58OAd7vn5lJ8S3frHRNG5i1R8XlKdH5kBjHYpy+g8cm
    ez6KJcfA3Z3mNWgQIJ2P2N7Sw4ScDV7oL8kCAwEAAaOBwDCBvTAdBgNVHQ4EFgQU
    oBEKIz6W8Qfs4q8p74Klf9AwpLQwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
    MAMBAf8wewYDVR0fBHQwcjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5jb20v
    QUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNqA0oDKGMGh0dHA6Ly9jcmwuY29t
    b2RvLm5ldC9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2VzLmNybDANBgkqhkiG9w0BAQUF
    AAOCAQEACFb8AvCb6P+k+tZ7xkSAzk/ExfYAWMymtrwUSWgEdujm7l3sAg9g1o1Q
    GE8mTgHj5rCl7r+8dFRBv/38ErjHT1r0iWAFf2C3BUrz9vHCv8S5dIa2LX1rzNLz
    Rt0vxuBqw8M0Ayx9lt1awg6nCpnBBYurDC/zXDrPbDdVCYfeU0BsWO/8tqtlbgT2
    G9w84FoVxp7Z8VlIMCFlA2zs6SFz7JsDoeA3raAVGI/6ugLOpyypEBMs1OUIJqsi
    l2D4kF501KKaU73yqWjgom7C12yxow+ev+to51byrvLjKzg6CYG1a4XXvi3tPxq3
    smPi9WIsgtRqAEFQ8TmDn5XpNpaYbg==
    -----END CERTIFICATE-----

    """

final class SignatureUitlTests: XCTestCase {

    func testToJwkThumbprint() {

        let expected = "cn-I_WNMClehiVp51i_0VpOENW1upEerA8sEam5hn-s"

        let jwk = ECPublicJwk(
            kty: "EC", crv: "P-256", x: "MKBCTNIcKUSDii11ySs3526iDZ8AiTo7Tu6KPAqv7D4",
            y: "4Etl6SRW2YiLUrN5vfvVHuhp7x8PxltmWWlbbM4IFyM")
        let thumbprint = SignatureUtil.toJwkThumbprint(jwk: jwk)

        XCTAssertTrue(expected == thumbprint)
    }

    func testGenerateEcKeyPair() {
        let expected = "M7yXCJjSzeJJ9NpBoMDg_fV1D9-cFeOm_IDHFvlcE_I"
        let jwk = ECPrivateJwk(
            kty: "EC", crv: "secp256k1", x: "QlaZ81aj1A3HeCZw3rLU__Dha5hKjG2OBcI5V_zqSRU",
            y: "EgtAoZrao5R5S4ANOhXeuGFZT0zbEU-R8sniQSMIZgQ",
            d: "M7yXCJjSzeJJ9NpBoMDg_fV1D9-cFeOm_IDHFvlcE_I")
        let (priv, _) = try! SignatureUtil.generateECKeyPair(jwk: jwk)
        XCTAssertTrue(priv.base64URLEncodedString() == expected)
    }

    func testGenerateCertificate() {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let cert = SignatureUtil.generateCertificate(
            subjectPublicKey: publicKey, issuerPrivateKey: privateKey, isCa: true)
        XCTAssertTrue(cert.publicKey == Certificate.PublicKey(publicKey))
        XCTAssertNoThrow(SignatureUtil.certificateToPem(certificate: cert))
    }

    func testConvertPemToX509Certificates() {
        let result = try! SignatureUtil.convertPemWithDelimitersToX509Certificates(
            pemChain: fullChain)
        XCTAssertTrue(result.count == 4)
    }

    func testGetX509CertificatesFromUrl_() {

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/certificates")!
        let mockData = fullChain.data(using: .utf8)
        let response = HTTPURLResponse(
            url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

        let url = "https://example.com/certificates"
        let expectedCertificatesNumber = 4

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        SignatureUtil.getX509CertificatesFromUrl_(url: url, session: mockSession) {
            certificates, error in
            defer {
                dispatchGroup.leave()
            }
            if let error = error {
                XCTFail()
            }
            else if let certificates = certificates {
                XCTAssertTrue(expectedCertificatesNumber == certificates.count)
            }
        }
        dispatchGroup.wait()
    }

    func testGetX509CertificatesFromUrl() {

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/certificates")!
        let mockData = fullChain.data(using: .utf8)
        let response = HTTPURLResponse(
            url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

        let url = "https://example.com/certificates"
        let expectedCertificatesNumber = 4
        let result = SignatureUtil.getX509CertificatesFromUrl(url: url, session: mockSession)
        XCTAssertNotNil(result)
        if result != nil {
            XCTAssertTrue(result?.count == expectedCertificatesNumber)
        }
    }

    func testValidateCertificateChain() {
        let pemChain = """
            -----BEGIN CERTIFICATE-----
            MIIFUjCCBPegAwIBAgIRAO68a+XoD/PhST9Zr7Fq4b0wCgYIKoZIzj0EAwIwgZUx
            CzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNV
            BAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDE9MDsGA1UEAxM0
            U2VjdGlnbyBFQ0MgT3JnYW5pemF0aW9uIFZhbGlkYXRpb24gU2VjdXJlIFNlcnZl
            ciBDQTAeFw0yMzEyMDUwMDAwMDBaFw0yNTAxMDQyMzU5NTlaMFAxCzAJBgNVBAYT
            AkpQMQ4wDAYDVQQIEwVUb2t5bzEWMBQGA1UEChMNRGF0YVNpZ24gSW5jLjEZMBcG
            A1UEAxMQb3duZC1wcm9qZWN0LmNvbTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IA
            BFIprdRg9RgqfsmAAmY/QMQ3Czjds6QvvO3WJT4rP00KVBwHxlbH1ZfSKVgDAdZP
            fQAp7tWBED9nlck7Qk9M4nGjggNqMIIDZjAfBgNVHSMEGDAWgBRNSu/ERrMSrU9O
            mrFZ4lGrCBB4CDAdBgNVHQ4EFgQULd9BFtdtud+3yIiR9ZXHqd6S9WQwDgYDVR0P
            AQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsG
            AQUFBwMCMEoGA1UdIARDMEEwNQYMKwYBBAGyMQECAQMEMCUwIwYIKwYBBQUHAgEW
            F2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMAgGBmeBDAECAjBaBgNVHR8EUzBRME+g
            TaBLhklodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29FQ0NPcmdhbml6YXRp
            b25WYWxpZGF0aW9uU2VjdXJlU2VydmVyQ0EuY3JsMIGKBggrBgEFBQcBAQR+MHww
            VQYIKwYBBQUHMAKGSWh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb0VDQ09y
            Z2FuaXphdGlvblZhbGlkYXRpb25TZWN1cmVTZXJ2ZXJDQS5jcnQwIwYIKwYBBQUH
            MAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMDEGA1UdEQQqMCiCEG93bmQtcHJv
            amVjdC5jb22CFHd3dy5vd25kLXByb2plY3QuY29tMIIBfQYKKwYBBAHWeQIEAgSC
            AW0EggFpAWcAdQDPEVbu1S58r/OHW9lpLpvpGnFnSrAX7KwB0lt3zsw7CAAAAYw6
            NipUAAAEAwBGMEQCIBVcGQjOkfLxvpm1Admcetmn8D15G4Gt2AIdOXveZYrsAiBe
            q8jh8G4geumOHXIklSxvBzip9VK6sw9yq4AnTHnSPwB2AKLjCuRF772tm3447Udn
            d1PXgluElNcrXhssxLlQpEfnAAABjDo2KcoAAAQDAEcwRQIhAJP0UetSSFGF9/fa
            OHVzhkPFOg3etjXqWQShnxYI8a+GAiABzN4+sJAysZ88mtodttNYamXsnfw1T3qX
            YcJbB5GwJAB2AE51oydcmhDDOFts1N8/Uusd8OCOG41pwLH6ZLFimjnfAAABjDo2
            KhkAAAQDAEcwRQIgbpDfqifRz9PW+Tq83ivbXHA1GheQpGX88laI0XB910gCIQCK
            Rm2sRqqlgaXX7rO3EznDn7MwC4mbQwSyEIDjXddHMzAKBggqhkjOPQQDAgNJADBG
            AiEAzwi+A0/YY55h0f+Id0+eUPrRsVBdOKWIp19yQZ62jJICIQCvKk/avGDl5/eN
            IyN1eesa1sbs8QfbTbvzitYsVlRqXg==
            -----END CERTIFICATE-----
            -----BEGIN CERTIFICATE-----
            MIIDrjCCAzOgAwIBAgIQNb50Y4yz6d4oBXC3l4CzZzAKBggqhkjOPQQDAzCBiDEL
            MAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNl
            eSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMT
            JVVTRVJUcnVzdCBFQ0MgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgxMTAy
            MDAwMDAwWhcNMzAxMjMxMjM1OTU5WjCBlTELMAkGA1UEBhMCR0IxGzAZBgNVBAgT
            EkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMP
            U2VjdGlnbyBMaW1pdGVkMT0wOwYDVQQDEzRTZWN0aWdvIEVDQyBPcmdhbml6YXRp
            b24gVmFsaWRhdGlvbiBTZWN1cmUgU2VydmVyIENBMFkwEwYHKoZIzj0CAQYIKoZI
            zj0DAQcDQgAEnI5cCmFvoVij0NXO+vxE+f+6Bh57FhpyH0LTCrJmzfsPSXIhTSex
            r92HOlz+aHqoGE0vSe/CSwLFoWcZ8W1jOaOCAW4wggFqMB8GA1UdIwQYMBaAFDrh
            CYbUzxnClnZ0SXbc4DXGY2OaMB0GA1UdDgQWBBRNSu/ERrMSrU9OmrFZ4lGrCBB4
            CDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHSUEFjAU
            BggrBgEFBQcDAQYIKwYBBQUHAwIwGwYDVR0gBBQwEjAGBgRVHSAAMAgGBmeBDAEC
            AjBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20vVVNF
            UlRydXN0RUNDQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwdgYIKwYBBQUHAQEE
            ajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVzdC5jb20vVVNFUlRy
            dXN0RUNDQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVz
            ZXJ0cnVzdC5jb20wCgYIKoZIzj0EAwMDaQAwZgIxAOk//uo7i/MoeKdcyeqvjOXs
            BJFGLI+1i0d+Tty7zEnn2w4DNS21TK8wmY3Kjm3EmQIxAPI1qHM/I+OS+hx0OZhG
            fDoNifTe/GxgWZ1gOYQKzn6lwP0yGKlrP+7vrVC8IczJ4A==
            -----END CERTIFICATE-----
            -----BEGIN CERTIFICATE-----
            MIID0zCCArugAwIBAgIQVmcdBOpPmUxvEIFHWdJ1lDANBgkqhkiG9w0BAQwFADB7
            MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
            VQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UE
            AwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTE5MDMxMjAwMDAwMFoXDTI4
            MTIzMTIzNTk1OVowgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5
            MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBO
            ZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgRUNDIENlcnRpZmljYXRpb24gQXV0
            aG9yaXR5MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEGqxUWqn5aCPnetUkb1PGWthL
            q8bVttHmc3Gu3ZzWDGH926CJA7gFFOxXzu5dP+Ihs8731Ip54KODfi2X0GHE8Znc
            JZFjq38wo7Rw4sehM5zzvy5cU7Ffs30yf4o043l5o4HyMIHvMB8GA1UdIwQYMBaA
            FKARCiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQ64QmG1M8ZwpZ2dEl23OA1
            xmNjmjAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zARBgNVHSAECjAI
            MAYGBFUdIAAwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5j
            b20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEEKDAmMCQG
            CCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZIhvcNAQEM
            BQADggEBABns652JLCALBIAdGN5CmXKZFjK9Dpx1WywV4ilAbe7/ctvbq5AfjJXy
            ij0IckKJUAfiORVsAYfZFhr1wHUrxeZWEQff2Ji8fJ8ZOd+LygBkc7xGEJuTI42+
            FsMuCIKchjN0djsoTI0DQoWz4rIjQtUfenVqGtF8qmchxDM6OW1TyaLtYiKou+JV
            bJlsQ2uRl9EMC5MCHdK8aXdJ5htN978UeAOwproLtOGFfy/cQjutdAFI3tZs4RmY
            CV4Ks2dH/hzg1cEo70qLRDEmBDeNiXQ2Lu+lIg+DdEmSx/cQwgwp+7e9un/jX9Wf
            8qn0dNW44bOwgeThpWOjzOoEeJBuv/c=
            -----END CERTIFICATE-----
            """
        let chain = try! SignatureUtil.convertPemWithDelimitersToX509Certificates(
            pemChain: pemChain)
        XCTAssertTrue(try! SignatureUtil.validateCertificateChain(certificates: chain))
    }
}
