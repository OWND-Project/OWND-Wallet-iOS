//
//  KeyBindingTests.swift
//  tw2023_walletTests
//
//  Created by 若葉良介 on 2024/01/15.
//

import XCTest

final class KeyBindingTests: XCTestCase {

    var keyAlias = "testKeyAlias"
    var publicKey: SecKey?
    var privateKey: SecKey?
    
    override func setUpWithError() throws {
        super.setUp()
        // キーペアの生成
        let keys = try KeyPairUtil.generateSignVerifyKeyPair(alias: keyAlias)
        privateKey = keys.0
        publicKey = keys.1
    }

    override func tearDownWithError() throws {
        publicKey = nil
        privateKey = nil
        super.tearDown()
    }

    func testGenerateJwtSignature() throws {
        // 必要なパラメータを設定
        let sdJwt = "sdJwtSample"
        let selectedDisclosures = [Disclosure(disclosure: "disclosureSample", key: "keySample", value: "valueSample")]
        let aud = "audSample"
        let nonce = "nonceSample"

        // JWTの生成
        let keyBinding = KeyBindingImpl(keyAlias: keyAlias)
        let jwt = try keyBinding.generateJwt(sdJwt: sdJwt, selectedDisclosures: selectedDisclosures, aud: aud, nonce: nonce)

        // JWTの検証
        let verificationResult = JWTUtil.verifyJwt(jwt: jwt, publicKey: publicKey!)
        switch verificationResult {
        case .success(_):
            XCTAssertTrue(true, "JWT verification succeeded")
        case .failure(let error):
            XCTFail("JWT verification failed: \(error)")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
