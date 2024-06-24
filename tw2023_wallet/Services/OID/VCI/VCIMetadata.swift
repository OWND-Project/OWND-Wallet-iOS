//
//  Metadata.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/25.
//

import Foundation
import SwiftyJSON

struct Logo: Codable {
    let uri: String
    let altText: String?
    enum CodingKeys: String, CodingKey {
        case uri
        case altText = "alt_text"
    }
}

struct BackgroundImage: Codable {
    let uri: String?
    enum CodingKeys: String, CodingKey {
        case uri
    }
}

protocol Displayable: Codable {
    var name: String? { get }
    var locale: String? { get }
}

class IssuerDisplay: Displayable {
    let name: String?
    let locale: String?
    let logo: Logo?
    enum CodingKeys: String, CodingKey {
        case name, locale, logo
    }
}

class ClaimDisplay: Displayable {
    let name: String?
    let locale: String?
    enum CodingKeys: String, CodingKey {
        case name, locale
    }
}

class CredentialDisplay: Codable {
    let name: String
    let locale: String?
    let logo: Logo?
    let description: String?
    let backgroundColor: String?
    let backgroundImage: BackgroundImage?
    let textColor: String?
    enum CodingKeys: String, CodingKey {
        case name, locale, logo, description
        case backgroundColor = "background_color"
        case backgroundImage = "background_image"
        case textColor = "text_color"
    }
}

struct Claim: Codable {
    let mandatory: Bool?
    let valueType: String?
    let display: [ClaimDisplay]?
    enum CodingKeys: String, CodingKey {
        case mandatory, display
        case valueType = "value_type"
    }
}

struct ClaimOnlyMandatory: Codable {
    var mandatory: Bool?
}

struct ProofSigningAlgValuesSupported: Codable {
    let proofSigningAlgValuesSupported: [String]
    enum CodingKeys: String, CodingKey {
        case proofSigningAlgValuesSupported = "proof_signing_alg_values_supported"
    }
}

struct CredentialResponseEncryption: Codable {
    let algValuesSupported: [String]
    let encValuesSupported: [String]
    let encryptionRequired: Bool
    enum CodingKeys: String, CodingKey {
        case algValuesSupported = "alg_values_supported"
        case encValuesSupported = "enc_values_supported"
        case encryptionRequired = "encryption_required"
    }
}

protocol CredentialConfiguration: Codable {
    var format: String { get }
    var scope: String? { get }
    var cryptographicBindingMethodsSupported: [String]? { get }
    var credentialSigningAlgValuesSupported: [String]? { get }
    var proofTypesSupported: [String: ProofSigningAlgValuesSupported]? { get }
    var display: [CredentialDisplay]? { get }

    func getCredentialDisplayName(locale: String) -> String
    func getClaimNames(locale: String) -> [String]
}

extension CredentialConfiguration {
    func getCredentialDisplayName(locale: String = "ja-JP") -> String {
        let defaultCredentialDisplay = "Unknown Credential"
        guard let credentialDisplays = self.display, credentialDisplays.count > 0 else {
            return defaultCredentialDisplay
        }
        for d in credentialDisplays {
            if let displayLocale = d.locale {
                if displayLocale == locale {
                    return d.name
                }
            }
        }
        if let firstDisplay = credentialDisplays.first {
            return firstDisplay.name
        }

        return defaultCredentialDisplay
    }

    func getClaimNames(locale: String = "ja-JP") -> [String] {
        return []
    }
}

typealias ClaimMap = [String: Claim]

struct CredentialSupportedVcSdJwt: CredentialConfiguration {
    let format: String
    let scope: String?
    let cryptographicBindingMethodsSupported: [String]?
    let credentialSigningAlgValuesSupported: [String]?
    let proofTypesSupported: [String: ProofSigningAlgValuesSupported]?
    let display: [CredentialDisplay]?

    let vct: String
    let claims: ClaimMap?
    let order: [String]?

    enum CodingKeys: String, CodingKey {
        case format, scope, display, order, vct, claims
        case cryptographicBindingMethodsSupported = "cryptographic_binding_methods_supported"
        case credentialSigningAlgValuesSupported = "credential_signing_alg_values_supported"
        case proofTypesSupported = "proof_types_supported"
    }

    func getClaimNames(locale: String = "ja-JP") -> [String] {
        guard let claims = self.claims else {
            return []
        }

        return getLocalizedClaimNames(claims: claims, locale: locale)
    }

}

struct JwtVcJsonCredentialDefinition: Codable {
    let type: [String]
    let credentialSubject: ClaimMap?

    enum CodingKeys: String, CodingKey {
        case type
        case credentialSubject = "credentialSubject"
    }

    func getClaimNames(locale: String) -> [String] {
        guard let subject = self.credentialSubject else {
            return []
        }
        return getLocalizedClaimNames(claims: subject, locale: locale)
    }

}

struct CredentialSupportedJwtVcJson: CredentialConfiguration {
    let format: String
    let scope: String?
    let cryptographicBindingMethodsSupported: [String]?
    let credentialSigningAlgValuesSupported: [String]?
    let proofTypesSupported: [String: ProofSigningAlgValuesSupported]?
    let display: [CredentialDisplay]?

    let credentialDefinition: JwtVcJsonCredentialDefinition
    let order: [String]?

    enum CodingKeys: String, CodingKey {
        case format, scope, display, order
        case cryptographicBindingMethodsSupported = "cryptographic_binding_methods_supported"
        case credentialSigningAlgValuesSupported = "credential_signing_alg_values_supported"
        case proofTypesSupported = "proof_types_supported"
        case credentialDefinition = "credential_definition"
    }

    func getClaimNames(locale: String = "ja-JP") -> [String] {
        return self.credentialDefinition.getClaimNames(locale: locale)
    }
}

struct LdpVcCredentialDefinition: Codable {
    let context: [String]  // todo オブジェクト形式に対応する
    let type: [String]
    let credentialSubject: ClaimMap?

    enum CodingKeys: String, CodingKey {
        case type, credentialSubject
        case context = "@context"
    }

}

struct CredentialSupportedLdpVc: CredentialConfiguration {
    let format: String
    let scope: String?
    let cryptographicBindingMethodsSupported: [String]?
    let credentialSigningAlgValuesSupported: [String]?
    let proofTypesSupported: [String: ProofSigningAlgValuesSupported]?
    let display: [CredentialDisplay]?

    let credentialDefinition: LdpVcCredentialDefinition
    let order: [String]?

    enum CodingKeys: String, CodingKey {
        case format, scope, display, order
        case cryptographicBindingMethodsSupported = "cryptographic_binding_methods_supported"
        case credentialSigningAlgValuesSupported = "credential_signing_alg_values_supported"
        case proofTypesSupported = "proof_type_supported"
        case credentialDefinition = "credential_definition"
    }

    func getClaimNames(locale: String = "ja-JP") -> [String] {
        // todo: implement
        return []
    }
}

typealias CredentialSupportedJwtVcJsonLd = CredentialSupportedLdpVc

struct CredentialSupportedFormat: Decodable {
    let format: String
}

func getLocalizedClaimNames(claims: ClaimMap, locale: String) -> [String] {
    var result: [String] = []
    for (claimKey, claimValue) in claims {
        if let displays = claimValue.display {
            if displays.isEmpty {
                result.append(claimKey)
            }
            else {
                // Priority is given to those matching LOCALE.
                let firstElmMatchingToLocale = displays.first(where: {
                    ($0.locale == locale) && ($0.name != nil)
                })
                if let elm = firstElmMatchingToLocale {
                    result.append(elm.name!)
                }
                else {
                    // If there is no match for Locale, use the first element.
                    // And, If `name` does not exist for the first element, `claimKey` is used.
                    let firstDisplay = displays.first!  // `displays` is not empty
                    if let firstDisplayName = firstDisplay.name {
                        result.append(firstDisplayName)
                    }
                    else {
                        result.append(claimKey)
                    }
                }
            }
        }
        else {
            result.append(claimKey)
        }
    }
    return result
}

func decodeCredentialSupported(from jsonData: Data) throws -> CredentialConfiguration {

    let decoder = JSONDecoder()
    // decoder.keyDecodingStrategy = .convertFromSnakeCase

    // 一時的なコンテナ構造体をデコードして、formatフィールドを読み取る
    let formatContainer = try decoder.decode(CredentialSupportedFormat.self, from: jsonData)

    print(formatContainer)

    switch formatContainer.format {
        case "vc+sd-jwt":
            return try decoder.decode(CredentialSupportedVcSdJwt.self, from: jsonData)
        case "jwt_vc_json":
            return try decoder.decode(CredentialSupportedJwtVcJson.self, from: jsonData)
        case "ldp_vc":
            return try decoder.decode(CredentialSupportedLdpVc.self, from: jsonData)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Invalid format value"))

    }
}

struct CredentialIssuerMetadata: Codable {
    let credentialIssuer: String
    let authorizationServers: [String]?
    let credentialEndpoint: String
    let batchCredentialEndpoint: String?
    let deferredCredentialEndpoint: String?
    let notificationEndpoint: String?
    let credentialResponseEncryption: CredentialResponseEncryption?
    let credentialIdentifiersSupported: Bool?
    let signedMetadata: String?
    let display: [IssuerDisplay]?
    let credentialConfigurationsSupported: [String: CredentialConfiguration]

    enum CodingKeys: String, CodingKey {
        case credentialIssuer = "credential_issuer"
        case authorizationServers = "authorization_servers"
        case credentialEndpoint = "credential_endpoint"
        case batchCredentialEndpoint = "batch_credential_endpoint"
        case deferredCredentialEndpoint = "deferred_credential_endpoint"
        case notificationEndpoint = "notification_endpoint"
        case credentialResponseEncryption = "credential_response_encryption"
        case credentialIdentifiersSupported = "credential_identifiers_supported"
        case credentialConfigurationsSupported = "credential_configurations_supported"
        case signedMetadata = "signed_metadata"
        case display
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        var credentialsSupportedDict = [String: CredentialConfiguration]()
        let credentialsSupportedContainer = try container.nestedContainer(
            keyedBy: DynamicKey.self, forKey: .credentialConfigurationsSupported)
        for key in credentialsSupportedContainer.allKeys {
            let credentialJSON = try credentialsSupportedContainer.decode(JSON.self, forKey: key)
            let credentialData = try JSONSerialization.data(
                withJSONObject: credentialJSON.object, options: [])
            let credentialSupported = try decodeCredentialSupported(from: credentialData)
            credentialsSupportedDict[key.stringValue] = credentialSupported
        }

        credentialIssuer = try container.decode(String.self, forKey: .credentialIssuer)
        authorizationServers = try container.decodeIfPresent(
            [String].self, forKey: .authorizationServers)
        credentialEndpoint = try container.decodeIfPresent(
            String.self, forKey: .credentialEndpoint)!
        batchCredentialEndpoint = try container.decodeIfPresent(
            String.self, forKey: .batchCredentialEndpoint)
        deferredCredentialEndpoint = try container.decodeIfPresent(
            String.self, forKey: .deferredCredentialEndpoint)
        notificationEndpoint = try container.decodeIfPresent(
            String.self, forKey: .notificationEndpoint)
        credentialResponseEncryption = try container.decodeIfPresent(
            CredentialResponseEncryption.self, forKey: .credentialResponseEncryption)
        credentialIdentifiersSupported = try container.decodeIfPresent(
            Bool.self, forKey: .credentialIdentifiersSupported)
        signedMetadata = try container.decodeIfPresent(
            String.self, forKey: .signedMetadata)
        display = try container.decodeIfPresent([IssuerDisplay].self, forKey: .display)
        credentialConfigurationsSupported = credentialsSupportedDict
    }

    func getCredentialIssuerDisplayName(locale: String = "ja-jp") -> String {
        let defaultIssuerDisplay = "Unknown Issuer"
        guard let issuerDisplays = self.display, issuerDisplays.count > 0 else {
            return defaultIssuerDisplay
        }
        for d in issuerDisplays {
            if let displayLocale = d.locale {
                if let name = d.name, displayLocale == locale {
                    return name
                }
            }
        }
        if let firstDisplay = issuerDisplays.first,
            let name = firstDisplay.name
        {
            return name
        }

        return defaultIssuerDisplay
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(credentialIssuer, forKey: .credentialIssuer)
        try container.encodeIfPresent(authorizationServers, forKey: .authorizationServers)
        try container.encodeIfPresent(credentialEndpoint, forKey: .credentialEndpoint)
        try container.encodeIfPresent(batchCredentialEndpoint, forKey: .batchCredentialEndpoint)
        try container.encodeIfPresent(
            deferredCredentialEndpoint, forKey: .deferredCredentialEndpoint)

        // Encode credentialsSupported based on the actual type
        var credentialsSupportedContainer = container.nestedContainer(
            keyedBy: DynamicKey.self, forKey: .credentialConfigurationsSupported)
        for (key, value) in credentialConfigurationsSupported {
            let credentialEncoder = credentialsSupportedContainer.superEncoder(
                forKey: DynamicKey(stringValue: key)!)
            try value.encode(to: credentialEncoder)
        }

        try container.encodeIfPresent(display, forKey: .display)
    }
}

// DynamicKeyを使って動的なキーを扱う
struct DynamicKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}
