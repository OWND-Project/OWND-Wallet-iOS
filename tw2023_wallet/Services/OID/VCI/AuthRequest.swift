//
//  AuthRequest.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/29.
//

import Foundation

protocol JWTPayload: Codable {
    var iss: String? { get }
    var sub: String? { get }
    var aud: String? { get }
    var iat: Int64? { get }
    var nbf: Int64? { get }
    var type: String? { get }
    var exp: Int64? { get }
    var jti: String? { get }
}

protocol IDTokenPayload: JWTPayload {
    var nonce: String? { get }
    var authTime: Int64? { get }
    var acr: String? { get }
    var azp: String? { get }
    var subJwk: [String: String]? { get }
}

struct IDTokenPayloadImpl: IDTokenPayload {
    var iss: String?
    var sub: String?
    var aud: String?
    var iat: Int64?
    var nbf: Int64?
    var type: String?
    var exp: Int64?
    var jti: String?
    var nonce: String?
    var authTime: Int64?
    var acr: String?
    var azp: String?
    var subJwk: [String: String]?
}

protocol AuthorizationRequestCommonPayload {
    var scope: String? { get }
    var responseType: String? { get }
    var clientId: String? { get }
    var redirectUri: String? { get }
    var idTokenHint: String? { get }
    var nonce: String? { get }
    var state: String? { get }
    var responseMode: ResponseMode? { get }
    var maxAge: Int? { get }
    var clientMetadata: RPRegistrationMetadataPayload? { get }
    var clientMetadataUri: String? { get }
    var responseUri: String? { get }
    var presentationDefinition: PresentationDefinition? { get }
    var presentationDefinitionUri: String? { get }
    var clientIdScheme: String? { get }
}

struct RPRegistrationMetadataPayload: Codable {
    var scopesSupported: [Scope]?
    var subjectTypesSupported: [SubjectType]?
    var idTokenSigningAlgValuesSupported: [SigningAlgo]?
    var requestObjectSigningAlgValuesSupported: [SigningAlgo]?
    var subjectSyntaxTypesSupported: [String]?
    var requestObjectEncryptionAlgValuesSupported: [SigningAlgo]?
    var requestObjectEncryptionEncValuesSupported: [String]?
    var clientId: String?
    var clientName: String?
    var vpFormats: [String: [String: [String]]]?
    var logoUri: String?
    var policyUri: String?
    var tosUri: String?
    var clientPurpose: String?
    var jwks: String?  // todo jwksの配列型を指定する
    var jwksUri: String?
    var vpFormatsSupported: Format?
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientName = "client_name"
        case clientPurpose = "client_purpose"
        case idTokenSigningAlgValuesSupported = "id_token_signing_alg_values_supported"
        case jwks
        case jwksUri = "jwks_uri"
        case logoUri = "logo_uri"
        case policyUri = "policy_uri"
        case requestObjectEncryptionAlgValuesSupported = "request_object_encryption_alg_values_supported"
        case requestObjectEncryptionEncValuesSupported = "request_object_encryption_enc_values_supported"
        case requestObjectSigningAlgValuesSupported = "request_object_signing_alg_values_supported"
        case scopesSupported = "scopes_supported"
        case subjectSyntaxTypesSupported = "subject_syntax_types_supported"
        case subjectTypesSupported = "subject_types_supported"
        case tosUri = "tos_uri"
        case vpFormats = "vp_formats"
        case vpFormatsSupported = "vp_formats_supported"
    }
}

protocol RequestObjectPayload: AuthorizationRequestCommonPayload, JWTPayload {}

protocol AuthorizationRequestPayload: AuthorizationRequestCommonPayload {
    var request: String? { get }
    var requestUri: String? { get }
}

struct RequestObjectPayloadImpl: RequestObjectPayload {
    var iss: String?
    var sub: String?
    var aud: String?
    var iat: Int64?
    var nbf: Int64?
    var type: String?
    var exp: Int64?
    var jti: String?
    var scope: String?
    var responseType: String?
    var clientId: String?
    var redirectUri: String?
    var idTokenHint: String?
    var nonce: String?
    var state: String?
    var responseMode: ResponseMode?
    var maxAge: Int?
    var clientMetadata: RPRegistrationMetadataPayload?
    var clientMetadataUri: String?
    var responseUri: String?
    var presentationDefinition: PresentationDefinition?
    var presentationDefinitionUri: String?
    var clientIdScheme: String?
    
    enum CodingKeys: String, CodingKey {
        case iss, sub, aud, iat, nbf, type, exp, jti, scope, nonce, state
        case responseType = "response_type"
        case clientId = "client_id"
        case redirectUri = "redirect_uri"
        case idTokenHint = "id_token_hint"
        case responseMode = "response_mode"
        case maxAge = "max_age"
        case clientMetadata = "client_metadata"
        case clientMetadataUri = "client_metadata_uri"
        case responseUri = "response_uri"
        case presentationDefinition = "presentation_definition"
        case presentationDefinitionUri = "presentation_definition_uri"
        case clientIdScheme = "client_id_scheme"
    }
}

extension RequestObjectPayloadImpl {
    init(from dictionary: [String: Any]) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        // decoder.keyDecodingStrategy = .convertFromSnakeCase

        self = try decoder.decode(RequestObjectPayloadImpl.self, from: jsonData)
    }
}

struct AuthorizationRequestPayloadImpl: AuthorizationRequestPayload, Codable {
    var scope: String?
    var responseType: String?
    var clientId: String?
    var redirectUri: String?
    var idTokenHint: String?
    var nonce: String?
    var state: String?
    var responseMode: ResponseMode?
    var maxAge: Int?
    var clientMetadata: RPRegistrationMetadataPayload?
    var clientMetadataUri: String?
    var request: String?
    var requestUri: String?
    var responseUri: String?
    var presentationDefinition: PresentationDefinition?
    var presentationDefinitionUri: String?
    var clientIdScheme: String?
    enum CodingKeys: String, CodingKey {
        case scope, nonce, state, request
        case responseType = "response_type"
        case clientId = "client_id"
        case redirectUri = "redirect_uri"
        case idTokenHint = "id_token_hint"
        case responseMode = "response_mode"
        case maxAge = "max_age"
        case clientMetadata = "client_metadata"
        case clientMetadataUri = "client_metadata_uri"
        case requestUri = "request_uri"
        case responseUri = "response_uri"
        case presentationDefinition = "presentation_definition"
        case presentationDefinitionUri = "presentation_definition_uri"
        case clientIdScheme = "client_id_scheme"
    }
}

extension AuthorizationRequestPayloadImpl {
    init(from dictionary: [String: Any]) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        // decoder.keyDecodingStrategy = .convertFromSnakeCase
        // カスタムデコーディングロジックをここに追加することができます。
        // 例: decoder.dateDecodingStrategy = .iso8601

        self = try decoder.decode(AuthorizationRequestPayloadImpl.self, from: jsonData)
    }
}

extension RPRegistrationMetadataPayload {
    init(from dictionary: [String: Any]) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        // decoder.keyDecodingStrategy = .convertFromSnakeCase
        self = try decoder.decode(RPRegistrationMetadataPayload.self, from: jsonData)
    }
}
