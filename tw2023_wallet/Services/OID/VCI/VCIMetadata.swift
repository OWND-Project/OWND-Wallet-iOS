//
//  Metadata.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/25.
//

import Foundation
import SwiftyJSON

struct ImageInfo: Codable {
    let url: String?
    let altText: String?
}

class Display: Codable {
    let name: String?
    let locale: String?
}

class CredentialsSupportedDisplay: Codable {
    let name: String?
    let locale: String?
    let logo: ImageInfo?
    let description: String?
    let backgroundColor: String?
    let backgroundImage: String?
    let textColor: String?
}

struct IssuerCredentialSubject: Codable {
    let mandatory: Bool?
    let valueType: String?
    let display: [Display]?
    
}

typealias IssuerCredentialSubjectMap = [String: IssuerCredentialSubject]


struct JwtVcJsonCredentialDefinition: Codable {
    let type: [String]
    let credentialSubject: IssuerCredentialSubjectMap?
}
struct VcSdJwtCredentialDefinition: Codable {
    let vct: String
    let claims: IssuerCredentialSubjectMap?
}

extension JwtVcJsonCredentialDefinition {
    func getClaimNames() -> [String] {
        guard let subject = self.credentialSubject else {
            return []
        }
        return Array(subject.keys)
    }
}

extension VcSdJwtCredentialDefinition {
    func getClaimNames() -> [String] {
        guard let claims = self.claims else {
            return []
        }
        return Array(claims.keys)
    }
}


typealias ICredentialContextType = [String: Any]

protocol CredentialSupported: Codable {
    var format: String { get }
    var cryptographicBindingMethodsSupported: [String]? { get }
    var cryptographicSuitesSupported: [String]? { get }
    var proofTypesSupported: [String]? { get }
    var display: [CredentialsSupportedDisplay]? { get }
    var order: [String]? { get }
}

struct CredentialSupportedVcSdJwt: CredentialSupported {
    let format: String
    let scope: String
    let cryptographicBindingMethodsSupported: [String]?
    let cryptographicSuitesSupported: [String]?
    let display: [CredentialsSupportedDisplay]?
    let credentialDefinition: VcSdJwtCredentialDefinition
    let proofTypesSupported: [String]?
    let order: [String]?
    
    enum CodingKeys: String, CodingKey {
        case format, scope, cryptographicBindingMethodsSupported, cryptographicSuitesSupported, display ,credentialDefinition, proofTypesSupported, order
    }
}

struct CredentialSupportedJwtVcJson: CredentialSupported {
    let format: String
    let scope: String
    let cryptographicBindingMethodsSupported: [String]?
    let cryptographicSuitesSupported: [String]?
    let display: [CredentialsSupportedDisplay]?
    let credentialDefinition: JwtVcJsonCredentialDefinition
    let proofTypesSupported: [String]?
    let order: [String]?
    
    enum CodingKeys: String, CodingKey {
        case format, scope, cryptographicBindingMethodsSupported, cryptographicSuitesSupported, display ,credentialDefinition, proofTypesSupported, order
    }
}

struct CredentialSupportedJwtVcJsonLdAndLdpVc: CredentialSupported {
    let format: String
    let cryptographicBindingMethodsSupported: [String]?
    let cryptographicSuitesSupported: [String]?
    let display: [CredentialsSupportedDisplay]?
    let proofTypesSupported: [String]?
    let types: [String]
    let context: [String] // todo オブジェクト形式に対応する
    let credentialSubject: IssuerCredentialSubjectMap?
    let order: [String]?
    
    enum CodingKeys: String, CodingKey {
        case format, cryptographicBindingMethodsSupported, cryptographicSuitesSupported, display, types, context = "@context", credentialSubject, proofTypesSupported, order
    }
}

struct CredentialSupportedFormat: Decodable {
    let format: String
}
func decodeCredentialSupported(from jsonData: Data) throws -> CredentialSupported {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    // 一時的なコンテナ構造体をデコードして、formatフィールドを読み取る
    let formatContainer = try decoder.decode(CredentialSupportedFormat.self, from: jsonData)
    let format = formatContainer.format

    switch format {
    case "vc+sd-jwt":
        return try decoder.decode(CredentialSupportedVcSdJwt.self, from: jsonData)
    case "jwt_vc_json":
        return try decoder.decode(CredentialSupportedJwtVcJson.self, from: jsonData)
    case "ldp_vc":
        return try decoder.decode(CredentialSupportedJwtVcJsonLdAndLdpVc.self, from: jsonData)
    default:
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid format value"))

    }
}

struct CredentialIssuerMetadata: Codable {
    let credentialIssuer: String
    let authorizationServers: [String]?
    let credentialEndpoint: String?
    var tokenEndpoint: String?
    let batchCredentialEndpoint: String?
    let deferredCredentialEndpoint: String?
    let credentialsSupported: [String: CredentialSupported]
    let display: [Display]?

    enum CodingKeys: String, CodingKey {
        case credentialIssuer = "credential_issuer"
        case authorizationServers = "authorization_servers"
        case credentialEndpoint = "credential_endpoint"
        case tokenEndpoint = "token_endpoint"
        case batchCredentialEndpoint = "batch_credential_endpoint"
        case deferredCredentialEndpoint = "deferred_credential_endpoint"
        case credentialsSupported = "credentials_supported"
        case display
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        credentialIssuer = try container.decode(String.self, forKey: .credentialIssuer)
        authorizationServers = try container.decodeIfPresent([String].self, forKey: .authorizationServers)
        credentialEndpoint = try container.decodeIfPresent(String.self, forKey: .credentialEndpoint)
        tokenEndpoint = try container.decodeIfPresent(String.self, forKey: .tokenEndpoint)
        batchCredentialEndpoint = try container.decodeIfPresent(String.self, forKey: .batchCredentialEndpoint)
        deferredCredentialEndpoint = try container.decodeIfPresent(String.self, forKey: .deferredCredentialEndpoint)
        
        display = try container.decodeIfPresent([Display].self, forKey: .display)

        var credentialsSupportedDict = [String: CredentialSupported]()
        let credentialsSupportedContainer = try container.nestedContainer(keyedBy: DynamicKey.self, forKey: .credentialsSupported)
        for key in credentialsSupportedContainer.allKeys {
            let credentialJSON = try credentialsSupportedContainer.decode(JSON.self, forKey: key)
            let credentialData = try JSONSerialization.data(withJSONObject: credentialJSON.object, options: [])
            let credentialSupported = try decodeCredentialSupported(from: credentialData)
            credentialsSupportedDict[key.stringValue] = credentialSupported
        }
        self.credentialsSupported = credentialsSupportedDict
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(credentialIssuer, forKey: .credentialIssuer)
        try container.encodeIfPresent(authorizationServers, forKey: .authorizationServers)
        try container.encodeIfPresent(credentialEndpoint, forKey: .credentialEndpoint)
        try container.encodeIfPresent(tokenEndpoint, forKey: .tokenEndpoint)
        try container.encodeIfPresent(batchCredentialEndpoint, forKey: .batchCredentialEndpoint)
        try container.encodeIfPresent(deferredCredentialEndpoint, forKey: .deferredCredentialEndpoint)

        // Encode credentialsSupported based on the actual type
        var credentialsSupportedContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .credentialsSupported)
        for (key, value) in credentialsSupported {
            let credentialEncoder = credentialsSupportedContainer.superEncoder(forKey: DynamicKey(stringValue: key)!)
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

struct GrantAuthorizationCode: Codable {
    let issuerState: String?
    
    enum CodingKeys: String, CodingKey {
        case issuerState = "issuer_state"
    }
}

struct GrantUrnIetf: Codable {
    let preAuthorizedCode: String
    let userPinRequired: BooleanLiteralType

    enum CodingKeys: String, CodingKey {
        case preAuthorizedCode = "pre-authorized_code"
        case userPinRequired = "user_pin_required"
    }
}

struct Grant: Codable {
    let authorizationCode: GrantAuthorizationCode?
    let urnIetfParams: GrantUrnIetf?

    enum CodingKeys: String, CodingKey {
        case authorizationCode = "authorization_code"
        case urnIetfParams = "urn:ietf:params:oauth:grant-type:pre-authorized_code"
    }
}

struct CredentialOffer: Codable {
    let credentialIssuer: String
    let credentials: [String]
    let grants: Grant?
    
    enum CodingKeys: String, CodingKey {
        case credentialIssuer = "credential_issuer", credentials, grants
    }
}

struct OAuthTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let cNonce: String?
    let cNonceExpiresIn: Int?
}
