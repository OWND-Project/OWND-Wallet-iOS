//
//  CredentialOfferViewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import Foundation
import SwiftUI

enum CredentialOfferViewModelError: Error {
    case LoadDataDidNotFinishuccessfully
    case CredentialOfferConfigurationIsEmpty
    case ProofGenerationFailed

    case TransactionIdIsRequired
    case DeferredIssuanceIsNotSupported
    case CredentialToBeConvertedDoesNotExist

    case FailedToConvertToInternalFormat

    // credential offer format
    case CredentialOfferQueryItemsNotFound
    case CredentialOfferParameterNotFound
    case InvalidCredentialOffer
}

class CredentialOfferViewModel: ObservableObject {
    var dataModel: CredentialOfferModel = .init()

    var credentialFormat: String? = nil
    var credentialType: String? = nil

    private let credentialDataManager = CredentialDataManager(container: nil)

    func sendRequest(txCode: String?) async throws {
        guard let offer = dataModel.credentialOffer,
            let metadata = dataModel.metaData,
            let credFormat = credentialFormat,
            let credType = credentialType
        else {
            throw CredentialOfferViewModelError.LoadDataDidNotFinishuccessfully
        }

        let vciClient = try await VCIClient(credentialOffer: offer, metaData: metadata)

        let token = try await vciClient.issueToken(txCode: txCode)
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
        var proofObject: Proofable? = nil
        if proofRequired {
            if let nonce = cNonce {
                let credentialIssuer = offer.credentialIssuer
                let proofJwt = try KeyPairUtil.createProofJwt(
                    keyAlias: Constants.Cryptography.KEY_BINDING, audience: credentialIssuer,
                    nonce: nonce)
                switch credFormat {
                    case "vc+sd-jwt", "jwt_vc_json":
                        proofObject = JwtProof(proofType: "jwt", jwt: proofJwt)
                    default:
                        throw CredentialOfferViewModelError.ProofGenerationFailed
                }
            }
        }

        // Credential Request Generation
        let credentialRequest = try createCredentialRequest(
            formatValue: credFormat, credentialType: credType, proofable: proofObject)

        // Issue credential
        let credentialResponse = try await vciClient.issueCredential(
            payload: credentialRequest, accessToken: accessToken)

        if credentialResponse.credential == nil {
            if credentialResponse.transactionId == nil {
                throw CredentialOfferViewModelError.TransactionIdIsRequired
            }

            // todo: implement deferred issuance
            throw CredentialOfferViewModelError.DeferredIssuanceIsNotSupported
        }
        else {
            // save credential
            let protoBuf = try convertToProtoBuf(
                accessToken: accessToken, credentialResponse: credentialResponse)
            try credentialDataManager.saveCredentialData(credentialData: protoBuf)
        }
    }

    func loadData(_ credentialOffer: CredentialOffer) async throws {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !dataModel.hasLoadedData else { return }

        dataModel.isLoading = true
        print("load data..")

        dataModel.credentialOffer = credentialOffer

        dataModel.metaData = try await retrieveAllMetadata(issuer: credentialOffer.credentialIssuer)

        try interpretMetadataAndCredentialOffer()

        dataModel.isLoading = false
        dataModel.hasLoadedData = true
        print("done")
    }

    private func interpretMetadataAndCredentialOffer() throws {
        guard let offer = dataModel.credentialOffer,
            let metadata = dataModel.metaData
        else {
            throw CredentialOfferViewModelError.LoadDataDidNotFinishuccessfully
        }

        let offerIds = offer.credentialConfigurationIds

        // todo: support multiple credential offer
        guard let firstOfferCredential = offerIds.first else {
            throw CredentialOfferViewModelError.CredentialOfferConfigurationIsEmpty
        }

        dataModel.targetCredentialId = firstOfferCredential

        for (_, supportedInMetadata) in metadata.credentialIssuerMetadata
            .credentialConfigurationsSupported
        {
            switch supportedInMetadata {
                case let credentialSupported as CredentialSupportedJwtVcJson:
                    if credentialSupported.credentialDefinition.type.contains(firstOfferCredential)
                    {
                        credentialFormat = "jwt_vc_json"
                        credentialType = firstOfferCredential
                    }

                case let credentialSupported as CredentialSupportedVcSdJwt:
                    if credentialSupported.vct == firstOfferCredential {
                        credentialFormat = "vc+sd-jwt"
                        credentialType = firstOfferCredential
                    }
                default:
                    break
            }
        }
    }

    private func convertToProtoBuf(accessToken: String, credentialResponse: CredentialResponse)
        throws -> Datastore_CredentialData
    {
        guard let credentialToSave = credentialResponse.credential else {
            throw CredentialOfferViewModelError.CredentialToBeConvertedDoesNotExist
        }

        let basicInfo: [String: Any] =
            credentialFormat == "vc+sd-jwt"
            ? extractSDJwtInfo(
                credential: credentialToSave, format: credentialFormat!)
            : extractInfoFromJwt(jwt: credentialToSave, format: credentialFormat!)

        let encoder = JSONEncoder()

        do {
            let encodedMetadata = try encoder.encode(
                self.dataModel.metaData?.credentialIssuerMetadata)
            let jsonString = String(data: encodedMetadata, encoding: .utf8)
            let expiresIn =
                credentialResponse.cNonceExpiresIn == nil
                ? Int32(0) : Int32(credentialResponse.cNonceExpiresIn!)
            var credentialData = Datastore_CredentialData()
            credentialData.id = UUID().uuidString

            credentialData.format = credentialFormat!
            credentialData.credential = credentialToSave
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
        catch {
            throw CredentialOfferViewModelError.FailedToConvertToInternalFormat
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
