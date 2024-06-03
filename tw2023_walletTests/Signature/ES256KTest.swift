//
//  ES256KTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2023/12/27.
//

import Foundation
import XCTest

@testable import tw2023_wallet

//extension String {
//    func base64UrlDecoded() -> Data? {
//        var base64 = self
//            .replacingOccurrences(of: "-", with: "+")
//            .replacingOccurrences(of: "_", with: "/")
//
//        // Paddingが必要な場合、追加
//        let length = Double(base64.lengthOfBytes(using: .utf8))
//        let requiredLength = 4 * ceil(length / 4.0)
//        let paddingLength = requiredLength - length
//        if paddingLength > 0 {
//            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
//            base64 += padding
//        }
//
//        return Data(base64Encoded: base64)
//    }
//}

final class ES256KTests: XCTestCase {

    func testSignAndVerify() {

        let privateKey = ECPrivateJwk(
            kty: "EC", crv: "secp256k1",
            x: "QlaZ81aj1A3HeCZw3rLU__Dha5hKjG2OBcI5V_zqSRU",
            y: "EgtAoZrao5R5S4ANOhXeuGFZT0zbEU-R8sniQSMIZgQ",
            d: "M7yXCJjSzeJJ9NpBoMDg_fV1D9-cFeOm_IDHFvlcE_I")

        let (priv, pub) = try! SignatureUtil.generateECKeyPair(jwk: privateKey)

        let d = "data to be signed"
        if let dataFromString = d.data(using: .utf8) {
            do {
                let (serialized, raw) = try ES256K.sign(key: priv, data: dataFromString)
                XCTAssertTrue(try ES256K.verify(key: pub, data: dataFromString, signature: raw))
            }
            catch {
                XCTFail()
            }
        }
    }

    func testCreateJws() {

        let privateKey = ECPrivateJwk(
            kty: "EC", crv: "secp256k1",
            x: "QlaZ81aj1A3HeCZw3rLU__Dha5hKjG2OBcI5V_zqSRU",
            y: "EgtAoZrao5R5S4ANOhXeuGFZT0zbEU-R8sniQSMIZgQ",
            d: "M7yXCJjSzeJJ9NpBoMDg_fV1D9-cFeOm_IDHFvlcE_I")

        let (priv, pub) = try! SignatureUtil.generateECKeyPair(jwk: privateKey)
        let jws = try! ES256K.createJws(key: priv, payload: "{\"foo\":\"bar\"}")

        print(jws)

        // todo: verify jwt
        XCTAssertTrue(true)
    }
}
