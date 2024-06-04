//
//  CredentialDataManagerTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2024/01/11.
//

import CoreData
import XCTest

@testable import tw2023_wallet

class CredentialDataManagerTests: XCTestCase {

    var inMemoryContainer: NSPersistentContainer!

    override func setUp() {
        super.setUp()

        inMemoryContainer = NSPersistentContainer(name: "DataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        inMemoryContainer.persistentStoreDescriptions = [description]

        inMemoryContainer.loadPersistentStores { (_, error) in
            XCTAssertNil(error, "Failed to load store: \(error!)")
        }
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSaveAndGetCredential() {
        let credentialDataManager = CredentialDataManager(container: inMemoryContainer)

        // Create test credential data
        // let testCredentialData = Datastore_CredentialData(id: "1", format: "Format1", credential: "Credential1", cNonce: "CNonce1", cNonceExpiresIn: 3600, iss: "Iss1", iat: 1638290000, exp: 1638293600, type: "Type1", accessToken: "AccessToken1", credentialIssuerMetadata: "Metadata1")

        var testCredentialData = Datastore_CredentialData()
        testCredentialData.id = "1"
        testCredentialData.format = "Format1"
        testCredentialData.credential = "Credential1"
        testCredentialData.cNonce = "CNonce1"
        testCredentialData.cNonceExpiresIn = 3600
        testCredentialData.iss = "Iss1"
        testCredentialData.iat = 1_638_290_000
        testCredentialData.exp = 1_638_293_600
        testCredentialData.type = "Type1"
        testCredentialData.accessToken = "AccessToken1"
        testCredentialData.credentialIssuerMetadata = "Metadata1"

        // Save credential data
        try! credentialDataManager.saveCredentialData(credentialData: testCredentialData)

        // Get all credentials
        let credentials = credentialDataManager.getAllCredentials()

        // Assert that the retrieved credential matches the saved credential
        XCTAssertEqual(credentials.count, 1)
        XCTAssertEqual(credentials.first?.id, testCredentialData.id)
        XCTAssertEqual(credentials.first?.format, testCredentialData.format)
        XCTAssertEqual(credentials.first?.credential, testCredentialData.credential)
        // ... add more assertions for other properties
    }

    func testDeleteCredential() {
        let context = inMemoryContainer.viewContext
        let credentialDataManager = CredentialDataManager(container: inMemoryContainer)

        var testCredentialData = Datastore_CredentialData()
        testCredentialData.id = "1"
        testCredentialData.format = "Format1"
        testCredentialData.credential = "Credential1"
        testCredentialData.cNonce = "CNonce1"
        testCredentialData.cNonceExpiresIn = 3600
        testCredentialData.iss = "Iss1"
        testCredentialData.iat = 1_638_290_000
        testCredentialData.exp = 1_638_293_600
        testCredentialData.type = "Type1"
        testCredentialData.accessToken = "AccessToken1"
        testCredentialData.credentialIssuerMetadata = "Metadata1"

        // Save credential data
        try! credentialDataManager.saveCredentialData(credentialData: testCredentialData)

        // Delete credential by ID
        credentialDataManager.deleteCredentialById(id: "1")

        // Get all credentials
        let credentials = credentialDataManager.getAllCredentials()

        // Assert that the credential is deleted
        XCTAssertEqual(credentials.count, 0)
    }

    func testDeleteAllCredentials() {
        let context = inMemoryContainer.viewContext
        let credentialDataManager = CredentialDataManager(container: inMemoryContainer)

        // Create test credential data
        // let testCredentialData = Datastore_CredentialData(id: "1", format: "Format1", credential: "Credential1", cNonce: "CNonce1", cNonceExpiresIn: 3600, iss: "Iss1", iat: 1638290000, exp: 1638293600, type: "Type1", accessToken: "AccessToken1", credentialIssuerMetadata: "Metadata1")

        var testCredentialData = Datastore_CredentialData()
        testCredentialData.id = "1"
        testCredentialData.format = "Format1"
        testCredentialData.credential = "Credential1"
        testCredentialData.cNonce = "CNonce1"
        testCredentialData.cNonceExpiresIn = 3600
        testCredentialData.iss = "Iss1"
        testCredentialData.iat = 1_638_290_000
        testCredentialData.exp = 1_638_293_600
        testCredentialData.type = "Type1"
        testCredentialData.accessToken = "AccessToken1"
        testCredentialData.credentialIssuerMetadata = "Metadata1"

        // Save credential data
        try! credentialDataManager.saveCredentialData(credentialData: testCredentialData)

        // Get all credentials
        let credentialsBefore = credentialDataManager.getAllCredentials()

        XCTAssertEqual(credentialsBefore.count, 1)

        // Delete all credentials
        credentialDataManager.deleteAllCredentials()

        // Get all credentials
        let credentialsAfter = credentialDataManager.getAllCredentials()

        // Assert that all credentials are deleted
        XCTAssertEqual(credentialsAfter.count, 0)
    }

    func testGetCredentialById() {
        let context = inMemoryContainer.viewContext
        let credentialDataManager = CredentialDataManager(container: inMemoryContainer)

        // Create test credential data
        // let testCredentialData = Datastore_CredentialData(id: "1", format: "Format1", credential: "Credential1", cNonce: "CNonce1", cNonceExpiresIn: 3600, iss: "Iss1", iat: 1638290000, exp: 1638293600, type: "Type1", accessToken: "AccessToken1", credentialIssuerMetadata: "Metadata1")

        var testCredentialData = Datastore_CredentialData()
        testCredentialData.id = "1"
        testCredentialData.format = "Format1"
        testCredentialData.credential = "Credential1"
        testCredentialData.cNonce = "CNonce1"
        testCredentialData.cNonceExpiresIn = 3600
        testCredentialData.iss = "Iss1"
        testCredentialData.iat = 1_638_290_000
        testCredentialData.exp = 1_638_293_600
        testCredentialData.type = "Type1"
        testCredentialData.accessToken = "AccessToken1"
        testCredentialData.credentialIssuerMetadata = "Metadata1"

        // Save credential data
        try! credentialDataManager.saveCredentialData(credentialData: testCredentialData)

        // Get credential by ID
        let retrievedCredential = credentialDataManager.getCredentialById(id: "1")

        // Assert that the retrieved credential matches the saved credential
        XCTAssertNotNil(retrievedCredential)
        XCTAssertEqual(retrievedCredential?.id, testCredentialData.id)
        XCTAssertEqual(retrievedCredential?.format, testCredentialData.format)
        XCTAssertEqual(retrievedCredential?.credential, testCredentialData.credential)
        // ... add more assertions for other properties
    }
}
