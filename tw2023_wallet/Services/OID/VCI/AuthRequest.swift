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
    var jwks: String? // todo jwksの配列型を指定する
    var jwksUri: String?
    var vpFormatsSupported: Format?
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
}

extension RequestObjectPayloadImpl {
    init(from dictionary: [String: Any]) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
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
}


extension AuthorizationRequestPayloadImpl {
    init(from dictionary: [String: Any]) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // カスタムデコーディングロジックをここに追加することができます。
        // 例: decoder.dateDecodingStrategy = .iso8601
        
        self = try decoder.decode(AuthorizationRequestPayloadImpl.self, from: jsonData)
    }
}

extension RPRegistrationMetadataPayload {
    init(from dictionary: [String: Any]) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self = try decoder.decode(RPRegistrationMetadataPayload.self, from: jsonData)
    }
}
