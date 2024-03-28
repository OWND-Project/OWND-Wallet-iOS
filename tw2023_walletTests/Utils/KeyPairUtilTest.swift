//
//  KeyPairUtilTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/01/05.
//

import XCTest
@testable import tw2023_wallet

final class KeyPairUitlTests: XCTestCase {
    
    func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let randomString = String((0..<length).map { _ in letters.randomElement()! })
        return randomString
    }
    
    func testGeneration() {
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: "abc"))
    }
    
    func testCheckKeyExistence() {
        let tag = generateRandomString(length: 5)
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        XCTAssertTrue(KeyPairUtil.isKeyPairExist(alias: tag))
    }
    
    func testGetPrivateKey(){
        let tag = generateRandomString(length: 5)
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        XCTAssertNotNil(KeyPairUtil.getPrivateKey(alias: tag))
    }
    
    func testGetPublicKey(){
        let tag = generateRandomString(length: 5)
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        XCTAssertNotNil(KeyPairUtil.getPublicKey(alias: tag))
    }
    
    func testGetKeyPair(){
        let tag = generateRandomString(length: 5)
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        XCTAssertNotNil(KeyPairUtil.getKeyPair(alias: tag))
    }
    
    func testPublicKeyToJwk() {
        let tag = generateRandomString(length: 5)
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        let keyPair = KeyPairUtil.getKeyPair(alias: tag)
        
        XCTAssertNotNil(keyPair)
        let (prv, pub) = keyPair!
        let jwk = KeyPairUtil.publicKeyToJwk(publicKey: pub)
        XCTAssertNotNil(jwk)
    }
    
    func testCreateProofJwtAndVerify(){
        let tag = generateRandomString(length: 5)
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        let keyPair = KeyPairUtil.getKeyPair(alias: tag)
        guard let publicKey = KeyPairUtil.getPublicKey(alias: tag) else {
            XCTFail()
            return
        }
        guard let jwk = KeyPairUtil.publicKeyToJwk(publicKey: publicKey) else {
            XCTFail()
            return
        }
        
        let proofJwt = try! KeyPairUtil.createProofJwt(keyAlias: tag, audience: "audience", nonce: "nonce")
        
        XCTAssertTrue(KeyPairUtil.verifyJwt(jwkJson: jwk, jwt: proofJwt))
        
    }
    
    func testCreatePublicKey() {
        let tag = generateRandomString(length: 5)
        XCTAssertNoThrow(try! KeyPairUtil.generateSignVerifyKeyPair(alias: tag))
        let publicKey = KeyPairUtil.getPublicKey(alias: tag)
        let jwk = KeyPairUtil.publicKeyToJwk(publicKey: publicKey!)
        let convertedPublicKey = try! KeyPairUtil.createPublicKey(jwk: jwk!)
        
        var error: Unmanaged<CFError>?
        
        let original = SecKeyCopyExternalRepresentation(publicKey!, &error) as Data?
        let originalBytes = [UInt8](original!)
        let originalX = Data(originalBytes[1...32])
        let originalY = Data(originalBytes[33...64])
        
        let converted = SecKeyCopyExternalRepresentation(convertedPublicKey, &error) as Data?
        let convertedBytes = [UInt8](converted!)
        let convertedX = Data(convertedBytes[1...32])
        let convertedY = Data(convertedBytes[33...64])
        
        XCTAssertEqual(originalX, convertedX)
        XCTAssertEqual(originalY, convertedY)
    }
}
