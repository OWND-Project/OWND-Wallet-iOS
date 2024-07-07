//
//  CredentialOfferViewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import Foundation
import SwiftUI

enum CredentialOfferParseError: Error {
    case ParameterNotFound
    case NoQueryItems
    case InvalidCredentialOffer
}

class CredentialOfferViewModel: ObservableObject {
    var dataModel: CredentialOfferModel = .init()
    var rawCredentialOfferString: String? = nil

    var credentialOffer: [String: Any]? = nil
    var credential_format: String? = nil
    var credential_vct: String? = nil

    private let credentialDataManager = CredentialDataManager(container: nil)

    func initialize(rawCredentialOfferString: String) throws {
        self.rawCredentialOfferString = rawCredentialOfferString

        let jsonStr = try parseCredentialOfferJsonString()
        let jsonData = jsonStr.data(using: .utf8)
        self.credentialOffer =
            try JSONSerialization.jsonObject(with: jsonData!, options: []) as? [String: Any]
    }

    func checkIfPinIsRequired() -> Bool {
        if let grants = credentialOffer!["grants"] as? [String: Any],
            let preAuthCodeInfo = grants["urn:ietf:params:oauth:grant-type:pre-authorized_code"]
                as? [String: Any],
            let userPinRequired = preAuthCodeInfo["user_pin_required"] as? Bool
        {
            return userPinRequired
        }
        else {
            return false
        }
    }

    func sendRequest(userPin: String?) async throws {
        do {
            interpretMetadataAndOffer()

            let vciClient = try await VCIClient(
                credentialOfferJson:
                    try parseCredentialOfferJsonString())

            let token = try await vciClient.issueToken(userPin: userPin)
            let accessToken = token.accessToken
            let cNonce = token.cNonce

            // binding key generation
            let proofRequired = cNonce != nil
            let isKeyPairExist = KeyPairUtil.isKeyPairExist(
                alias: Constants.Cryptography.KEY_BINDING)
            if !isKeyPairExist && proofRequired {
                try KeyPairUtil.generateSignVerifyKeyPair(alias: Constants.Cryptography.KEY_BINDING)
            }

            // proof generation
            var proofObject: Proof? = nil
            if proofRequired && cNonce != nil {
                let credentialIssuer = credentialOffer!["credential_issuer"] as! String
                let proofJwt = try KeyPairUtil.createProofJwt(
                    keyAlias: Constants.Cryptography.KEY_BINDING, audience: credentialIssuer,
                    nonce: cNonce!)
                proofObject = Proof(proofType: "jwt", jwt: proofJwt)
            }

            // Credential Request Generation
            let credentialRequest = createCredentialRequest(
                formatValue: credential_format!, vctValue: credential_vct!, proof: proofObject)

            // 発行
            let credentialResponse = try await vciClient.issueCredential(
                payload: credentialRequest, accessToken: accessToken)

            // 保存
            let protoBuf = convertToProtoBuf(
                accessToken: accessToken, credentialResponse: credentialResponse)
            try credentialDataManager.saveCredentialData(credentialData: protoBuf)
        }
        catch {
            print(error)
        }
    }

    func loadData() async throws {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !dataModel.hasLoadedData else { return }
        dataModel.isLoading = true
        print("load data..")

        let credentialIssuer = credentialOffer!["credential_issuer"] as! String
        self.dataModel.metaData = try await retrieveAllMetadata(issuer: credentialIssuer)

        dataModel.isLoading = false
        dataModel.hasLoadedData = true
        print("done")
    }

    private func convertToProtoBuf(accessToken: String, credentialResponse: CredentialResponse)
        -> Datastore_CredentialData
    {
        let basicInfo: [String: Any] =
            credential_format == "vc+sd-jwt"
            ? extractSDJwtInfo(
                credential: credentialResponse.credential, format: credential_format!)
            : extractInfoFromJwt(jwt: credentialResponse.credential, format: credential_format!)

        let encoder = JSONEncoder()
        let encodedMetadata = try! encoder.encode(self.dataModel.metaData)
        let jsonString = String(data: encodedMetadata, encoding: .utf8)
        let expiresIn =
            credentialResponse.cNonceExpiresIn == nil
            ? Int32(0) : Int32(credentialResponse.cNonceExpiresIn!)
        var credentialData = Datastore_CredentialData()
        credentialData.id = UUID().uuidString

        credentialData.format = credential_format!
        credentialData.credential = credentialResponse.credential
        credentialData.iss = basicInfo["iss"] as! String
        credentialData.iat = basicInfo["iat"] as! Int64
        credentialData.exp = basicInfo["exp"] as! Int64
        credentialData.type = basicInfo["typeOrVct"] as! String
        credentialData.cNonce = credentialResponse.cNonce ?? ""
        credentialData.cNonceExpiresIn = expiresIn
        credentialData.accessToken = accessToken
        credentialData.credentialIssuerMetadata = jsonString!

        return credentialData
    }

    private func parseCredentialOfferJsonString() throws -> String {
        guard let urlString = rawCredentialOfferString,
            let url = URL(string: urlString),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            throw CredentialOfferParseError.InvalidCredentialOffer
        }

        guard let queryItems = components.queryItems else {
            throw CredentialOfferParseError.NoQueryItems
        }

        guard
            let credentialOfferValue = queryItems.first(where: { $0.name == "credential_offer" })?
                .value
        else {
            throw CredentialOfferParseError.ParameterNotFound
        }

        return credentialOfferValue
    }

    private func interpretMetadataAndOffer() {
        // todo: メタデータとオファーの内容から、適切な値を設定する
        // self.credential_format = "jwt_vc_json"
        // self.credential_vct = "ParticipationCertificate"
        for (key, credentialSupported) in self.dataModel.metaData!.credentialsSupported {
            switch credentialSupported {
                case let credentialSupported as CredentialSupportedJwtVcJson:
                    print("Format: jwt_vc_json")
                    let credentials = self.credentialOffer!["credentials"] as! [String]
                    let firstCredential = credentials.first ?? ""
                    if credentialSupported.credentialDefinition.type.contains(firstCredential) {
                        // Handle the case for CredentialSupportedJwtVcJson
                        self.credential_format = "jwt_vc_json"
                        self.credential_vct = firstCredential
                    }

                case let credentialSupported as CredentialSupportedVcSdJwt:
                    print("Format: vc+sd-jwt")
                    let credentials = self.credentialOffer!["credentials"] as! [String]
                    let firstCredential = credentials.first ?? ""
                    if credentialSupported.credentialDefinition.vct == firstCredential {
                        // Handle the case for CredentialSupportedVcSdJwt
                        self.credential_format = "vc+sd-jwt"
                        self.credential_vct = firstCredential
                    }
                default:
                    // Handle other types if needed
                    break
            }
        }
    }

    private func extractSDJwtInfo(credential: String, format: String) -> [String: Any] {
        let issuerSignedJwt = credential.split(separator: "~")[0]
        return extractInfoFromJwt(jwt: String(issuerSignedJwt), format: format)
    }

    private func extractJwtVcJsonInfo(credential: String, format: String) -> [String: Any] {
        return extractInfoFromJwt(jwt: credential, format: format)
    }

    private func extractInfoFromJwt(jwt: String, format: String) -> [String: Any] {
        guard let decodedPayload = jwt.components(separatedBy: ".")[1].base64UrlDecoded(),
            let decodedString = String(data: decodedPayload, encoding: .utf8),
            let jsonData = decodedString.data(using: .utf8),
            let jwtDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: [])
                as? [String: Any]
        else {
            return [:]
        }

        let iss = jwtDictionary["iss"] as? String ?? ""
        let iat = jwtDictionary["iat"] as? Int64 ?? 0
        let exp = jwtDictionary["exp"] as? Int64 ?? 0
        let typeOrVct: String
        if format == "vc+sd-jwt" {
            typeOrVct = jwtDictionary["vct"] as? String ?? ""
        }
        else {
            typeOrVct = jwtDictionary["type"] as? String ?? ""
        }

        return ["iss": iss, "iat": iat, "exp": exp, "typeOrVct": typeOrVct]
    }

}
