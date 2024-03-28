//
//  JWTTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/01/05.
//

import XCTest
@testable import tw2023_wallet

final class JWTUtilTest: XCTestCase {
    func testSigning(){
        let tag = "jwt_signing_key"
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        let (_, publicKey) = KeyPairUtil.getKeyPair(alias: tag)!
        
        let header = [
            "typ": "JWT",
            "alg": "ES256"
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
    
    func testDecodeJwt(){
       let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        
        let expectedHeader: [String: Any] = [
            "alg": "HS256",
            "typ": "JWT"
          ]
        
        let expectedPayload: [String : Any] = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": 1516239022
        ]
        
        let expectedSignature = "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        
        let (header, payload, signature) = try! JWTUtil.decodeJwt(jwt: jwt)
        XCTAssertTrue(NSDictionary(dictionary: header).isEqual(to: expectedHeader))
        XCTAssertTrue(NSDictionary(dictionary: payload).isEqual(to: expectedPayload))
        XCTAssertEqual(signature, expectedSignature)
        
    }
}
