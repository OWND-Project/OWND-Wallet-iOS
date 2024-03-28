//
//  CredentialDataManager.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/01/11.
//

import CoreData
import Foundation

func intToData<T: BinaryInteger>(n: T) -> Data {
    var data = Data()
    withUnsafeBytes(of: n) {
        data.append(contentsOf: $0)
    }
    return data
}

func dataToInt64(data: Data) -> Int64 {
    var result: Int64 = 0
    _ = withUnsafeMutableBytes(of: &result) { buffer in
        data.copyBytes(to: buffer)
    }
    return result
}

func dataToInt32(data: Data) -> Int32 {
    var result: Int32 = 0
    _ = withUnsafeMutableBytes(of: &result) { buffer in
        data.copyBytes(to: buffer)
    }
    return result
}

extension Datastore_CredentialData {
    func parsedMetaData() -> CredentialIssuerMetadata? {
        if let jsonData = self.credentialIssuerMetadata.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(CredentialIssuerMetadata.self, from: jsonData)
                return result
            } catch {
                print("Error converting JSON string to CredentialIssuerMetadata: \(error)")
            }
        }
        return nil
    }

    func generateQRDisplay() -> String {
        do {
            // credentialのフォーマットとペイロードからタイプを抽出
            let types = try VCIMetadataUtil.extractTypes(format: self.format, credential: self.credential)

            // メタデータをData型に変換
            guard let metadataData = self.credentialIssuerMetadata.data(using: .utf8) else {
                return "メタデータの変換に失敗しました。"
            }

            // メタデータをデコード
            let decoder = JSONDecoder()
            let metadata = try decoder.decode(CredentialIssuerMetadata.self, from: metadataData)

            // メタデータから対応するクレデンシャルを探す
            guard let credentialSupported = VCIMetadataUtil.findMatchingCredentials(
                format: self.format,
                types: types,
                metadata: metadata
            ) else {
                return "対応するクレデンシャルが見つかりませんでした。"
            }

            // クレデンシャルに基づいてディスプレイ情報を抽出し、シリアライズ
            let displayData = VCIMetadataUtil.serializeDisplayByClaimMap(
                displayMap: VCIMetadataUtil.extractDisplayByClaim(credentialsSupported: credentialSupported)
            )

            return displayData
        } catch {
            print("エラーが発生しました: \(error)")
            return "エラーが発生しました。"
        }
    }
    
    private func getDisclosure() -> [String : String]? {
        switch self.format {
        case "vc+sd-jwt":
            guard let decoded = try? SDJwtUtil.decodeSDJwt(self.credential) else {
                return nil
            }
            var disclousre = [String: String]()
            decoded.forEach{d in
                disclousre[d.key!] = d.value
            }
            return disclousre
        case "jwt_vc_json":
            guard let tmp = try? decodeJWTPayload(jwt: self.credential),
                  let vcDict = tmp["vc"] as? [String: Any],
                  let credentialSubject = vcDict["credentialSubject"] as? [String: Any] else {
                return nil
            }
            var disclousre = [String: String]()
            credentialSubject.forEach{ d in
                let value = (d.value as? String) ?? "Unknown"
                disclousre[d.key] = value
            }
            return disclousre
        default:
            return nil
        }
    }
    
    private func getBackgroundImage() -> String? {
        guard let metaData = self.parsedMetaData() else {
            return nil
        }
        guard let supportedName = metaData.credentialsSupported.keys.first, // todo: 1つめを前提としている
              let supported = metaData.credentialsSupported[supportedName],
              let displays = supported.display,
              let firstDisplay = displays.first, // todo: 1つめを前提としている
              let backgroundImageUrl = firstDisplay.backgroundImage else {
            return nil
        }
        
        return backgroundImageUrl
    }

    private func convertUnixTimestampToDate(unixTimestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTimestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate
    }

    func toCredential() -> Credential? {
        guard let metaData = self.parsedMetaData() else {
            return nil
        }
        let issuer = metaData.credentialIssuer
        let display = metaData.display?.first
        let issuerName = display?.name ?? "Unknown Issuer"
        let iat = self.convertUnixTimestampToDate(unixTimestamp: self.iat)
        
        guard let disclosure = getDisclosure() else {
            return nil
        }
        
        // 最低限のデータのみ詰めている。必要があれば追加する。
        let result = Credential(id: self.id,
                                format: self.format,
                                payload: self.credential,
                                issuer: issuer,
                                issuerDisplayName: issuerName,
                                issuedAt: iat,
                                backgroundImageUrl: getBackgroundImage(),
                                credentialType: CredentialType(rawValue: self.type)!,
                                disclosure: disclosure,
                                qrDisplay: self.generateQRDisplay(),
                                metaData: metaData
                                
        )
        return result
    }
}

extension CredentialDataEntity {
    func toCredentialData() -> Datastore_CredentialData {
        let helper = EncryptionHelper()
        var credentialData = Datastore_CredentialData()
        credentialData.id = self.id!

        credentialData.format = String(data: helper.decryptWithDeserialization(data: self.format!)!, encoding: .utf8)!
        credentialData.credential = String(data: helper.decryptWithDeserialization(data: self.credential!)!, encoding: .utf8)!
        credentialData.cNonce = String(data: helper.decryptWithDeserialization(data: self.cNonce!)!, encoding: .utf8)!
        credentialData.iss = String(data: helper.decryptWithDeserialization(data: self.iss!)!, encoding: .utf8)!
        credentialData.type = String(data: helper.decryptWithDeserialization(data: self.type!)!, encoding: .utf8)!
        credentialData.accessToken = String(data: helper.decryptWithDeserialization(data: self.accessToken!)!, encoding: .utf8)!
        credentialData.credentialIssuerMetadata = String(data: helper.decryptWithDeserialization(data: self.credentialIssuerMetadata!)!, encoding: .utf8)!

        credentialData.cNonceExpiresIn = dataToInt32(data: helper.decryptWithDeserialization(data: self.cNonceExpiresIn!)!)
        credentialData.iat = dataToInt64(data: helper.decryptWithDeserialization(data: self.iat!)!)
        credentialData.exp = dataToInt64(data: helper.decryptWithDeserialization(data: self.iat!)!)

        return credentialData
    }
}

enum CredentialDataManagerError: Error {
    case UnableToSaveData
}

class CredentialDataManager {
    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext

    init(container: NSPersistentContainer?) {
        if container != nil {
            self.persistentContainer = container!
            self.context = self.persistentContainer.viewContext
            return
        }
        self.persistentContainer = NSPersistentContainer(name: "DataModel") // モデルの名前に合わせて変更

        let description = self.persistentContainer.persistentStoreDescriptions.first
        description?.type = NSSQLiteStoreType

        self.persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to initialize Core Data: \(error)")
            }
        }
        self.context = self.persistentContainer.viewContext
    }

    func saveCredentialData(credentialData: Datastore_CredentialData) throws {
        guard let format = credentialData.format.data(using: .utf8),
              let credential = credentialData.credential.data(using: .utf8),
              let cNonce = credentialData.cNonce.data(using: .utf8),
              let iss = credentialData.iss.data(using: .utf8),
              let type = credentialData.type.data(using: .utf8),
              let accessToken = credentialData.accessToken.data(using: .utf8),
              let credentialIssuerMetadata = credentialData.credentialIssuerMetadata.data(using: .utf8)
        else {
            throw CredentialDataManagerError.UnableToSaveData
        }

        let helper = EncryptionHelper()
        let newCredential = CredentialDataEntity(context: context)
        newCredential.id = credentialData.id

        newCredential.format = helper.encryptWithSerialization(data: format)
        newCredential.credential = helper.encryptWithSerialization(data: credential)
        newCredential.cNonce = helper.encryptWithSerialization(data: cNonce)
        newCredential.iss = helper.encryptWithSerialization(data: iss)
        newCredential.type = helper.encryptWithSerialization(data: type)
        newCredential.accessToken = helper.encryptWithSerialization(data: accessToken)
        newCredential.credentialIssuerMetadata = helper.encryptWithSerialization(data: credentialIssuerMetadata)

        newCredential.iat = helper.encryptWithSerialization(data: intToData(n: credentialData.iat))
        newCredential.exp = helper.encryptWithSerialization(data: intToData(n: credentialData.exp))
        newCredential.cNonceExpiresIn = helper.encryptWithSerialization(data: intToData(n: credentialData.cNonceExpiresIn))
        do {
            try self.context.save()
        } catch {
            print("Error saving credential data: \(error)")
        }
    }

    func getAllCredentials() -> [Datastore_CredentialData] {
        var credentials = [Datastore_CredentialData]()

        do {
            let fetchRequest: NSFetchRequest<CredentialDataEntity> = CredentialDataEntity.fetchRequest()
            let credentialEntities = try context.fetch(fetchRequest)

            for credentialEntity in credentialEntities {
                let credentialData = credentialEntity.toCredentialData()
                credentials.append(credentialData)
            }
        } catch {
            print("Error fetching credential data: \(error)")
        }

        return credentials
    }

    func getCredentialById(id: String) -> Datastore_CredentialData? {
        do {
            let fetchRequest: NSFetchRequest<CredentialDataEntity> = CredentialDataEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)

            let credentialEntities = try context.fetch(fetchRequest)

            if let credentialEntity = credentialEntities.first {
                return credentialEntity.toCredentialData()
            } else {
                return nil
            }
        } catch {
            print("Error fetching credential data by ID: \(error)")
            return nil
        }
    }

    func deleteCredentialById(id: String) {
        do {
            let fetchRequest: NSFetchRequest<CredentialDataEntity> = CredentialDataEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)

            let credentialEntities = try context.fetch(fetchRequest)

            for credentialEntity in credentialEntities {
                self.context.delete(credentialEntity)
            }

            try self.context.save()
        } catch {
            print("Error deleting credential data: \(error)")
        }
    }

    func deleteAllCredentials() {
        do {
            let fetchRequest: NSFetchRequest<CredentialDataEntity> = CredentialDataEntity.fetchRequest()
            let credentialEntities = try context.fetch(fetchRequest)

            for credentialEntity in credentialEntities {
                self.context.delete(credentialEntity)
            }

            try self.context.save()
        } catch {
            print("Error deleting all credential data: \(error)")
        }
    }
}
